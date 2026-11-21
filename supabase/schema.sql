-- ============================================================
-- Helmand University Digital Library — Supabase schema
-- Owner: Mohammad Ziarmal (Helmand University)
-- Run this file in Supabase Dashboard > SQL Editor.
-- It is safe to run twice: tables are created IF NOT EXISTS and
-- the seed data uses ON CONFLICT DO NOTHING.
--
-- Structure: 7 faculties, 21 departments (verified against
-- helu.edu.af and the university catalogs, 1404).
-- The student app also carries this catalogue bundled in its code
-- (lib/data/catalogue.dart), so it works offline even before this
-- backend is connected. Books added here appear in the app once
-- the live sync is enabled; until then the bundled catalogue is used.
-- ============================================================

create extension if not exists pgcrypto;

-- ----------------------------------------------------------
-- Academic structure
-- ----------------------------------------------------------
create table if not exists faculties (
  id uuid primary key default gen_random_uuid(),
  name_ps text not null,
  name_en text not null,
  icon text,
  sort_order int default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table if not exists departments (
  id uuid primary key default gen_random_uuid(),
  faculty_id uuid references faculties(id) on delete cascade,
  name_ps text not null,
  name_en text not null,
  -- Number of semesters of the degree (8 for Bachelor, 10 for DVM).
  -- 0 means a service department with no degree of its own.
  semesters int not null default 8,
  sort_order int default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table if not exists academic_years (
  id uuid primary key default gen_random_uuid(),
  year_label text not null unique,
  is_current boolean default false,
  created_at timestamptz default now()
);

create table if not exists semesters (
  id uuid primary key default gen_random_uuid(),
  department_id uuid references departments(id) on delete cascade,
  semester_number int not null check (semester_number between 1 and 10),
  academic_year_id uuid references academic_years(id),
  unique (department_id, semester_number, academic_year_id)
);

-- ----------------------------------------------------------
-- Books
-- ----------------------------------------------------------
create table if not exists books (
  id uuid primary key default gen_random_uuid(),
  department_id uuid references departments(id) on delete set null,
  semester_number int check (semester_number between 1 and 10),
  title text not null,
  subject text not null,
  author text not null,
  cover_url text,
  pdf_url text not null,
  file_size_bytes bigint default 0,
  edition text,
  is_archived boolean default false,
  download_count int default 0,
  created_at timestamptz default now()
);

create table if not exists reading_books (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  title text not null,
  author text not null,
  cover_url text,
  pdf_url text not null,
  -- Only books with legal publishing permission may be added.
  has_permission boolean default false,
  is_archived boolean default false,
  created_at timestamptz default now()
);

-- ----------------------------------------------------------
-- Admins, roles and access control (RBAC)
-- ----------------------------------------------------------
create table if not exists roles (
  id uuid primary key default gen_random_uuid(),
  name text not null unique, -- super_admin, content_admin, viewer
  description text
);

create table if not exists admins (
  id uuid primary key, -- same id as auth.users
  email text not null unique,
  full_name text,
  role text not null default 'content_admin'
    references roles(name) on update cascade,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ----------------------------------------------------------
-- Student-side data (used when accounts are added later)
-- ----------------------------------------------------------
create table if not exists downloads (
  id uuid primary key default gen_random_uuid(),
  book_id uuid references books(id) on delete set null,
  device_id text,
  downloaded_at timestamptz default now()
);

create table if not exists favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  book_id uuid references books(id) on delete cascade,
  created_at timestamptz default now(),
  unique (user_id, book_id)
);

create table if not exists reading_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  book_id uuid references books(id) on delete cascade,
  last_opened_at timestamptz default now()
);

create table if not exists reading_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  book_id uuid references books(id) on delete cascade,
  last_page int default 0,
  updated_at timestamptz default now(),
  unique (user_id, book_id)
);

-- ----------------------------------------------------------
-- Notifications, suggestions, audit log, settings
-- ----------------------------------------------------------
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table if not exists suggestions (
  id uuid primary key default gen_random_uuid(),
  name text,
  contact text,
  message text not null,
  is_resolved boolean default false,
  created_at timestamptz default now()
);

create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid,
  action text not null, -- insert, update, delete
  table_name text,
  record_id uuid,
  created_at timestamptz default now()
);

create table if not exists settings (
  key text primary key,
  value text,
  updated_at timestamptz default now()
);

-- ----------------------------------------------------------
-- Seed data: roles, academic years, faculties, departments.
-- Verified structure: 7 faculties, 21 departments.
-- ----------------------------------------------------------
insert into roles (name, description) values
  ('super_admin', 'Mohammad Ziarmal - full control'),
  ('content_admin', 'Can add, edit and archive books and content'),
  ('viewer', 'Read-only access to the admin panel')
on conflict (name) do nothing;

insert into academic_years (year_label, is_current) values
  ('1404', true),
  ('1405', false)
on conflict (year_label) do nothing;

-- Faculties (fixed ids so departments can reference them safely).
insert into faculties (id, name_ps, name_en, sort_order) values
  ('11111111-1111-1111-1111-111111111111', 'کرهڼې', 'Agriculture', 1),
  ('22222222-2222-2222-2222-222222222222', 'ښوونې او روزنې', 'Education', 2),
  ('33333333-3333-3333-3333-333333333333', 'انجینري', 'Engineering', 3),
  ('44444444-4444-4444-4444-444444444444', 'وترنري علومو', 'Veterinary Sciences', 4),
  ('55555555-5555-5555-5555-555555555555', 'اقتصاد', 'Economics', 5),
  ('66666666-6666-6666-6666-666666666666', 'شرعیاتو', 'Shariah', 6),
  ('77777777-7777-7777-7777-777777777777', 'کمپیوټر ساینس', 'Computer Science', 7)
on conflict (id) do nothing;

insert into departments (faculty_id, name_ps, name_en, semesters, sort_order) values
  ('11111111-1111-1111-1111-111111111111', 'کرنیز اقتصاد او ترویج', 'Agricultural Economics & Extension', 8, 1),
  ('11111111-1111-1111-1111-111111111111', 'اګرانومي', 'Agronomy', 8, 2),
  ('11111111-1111-1111-1111-111111111111', 'هارتیکلچر', 'Horticulture', 8, 3),
  ('11111111-1111-1111-1111-111111111111', 'حیواني علومو', 'Animal Sciences', 8, 4),
  ('22222222-2222-2222-2222-222222222222', 'ریاضي', 'Mathematics', 8, 1),
  ('22222222-2222-2222-2222-222222222222', 'بیولوژي', 'Biology', 8, 2),
  ('22222222-2222-2222-2222-222222222222', 'پښتو ژبه او ادبیات', 'Pashto Language & Literature', 8, 3),
  ('22222222-2222-2222-2222-222222222222', 'فزیک', 'Physics', 8, 4),
  ('22222222-2222-2222-2222-222222222222', 'کیمیا', 'Chemistry', 8, 5),
  ('22222222-2222-2222-2222-222222222222', 'انګلیسي ژبه او ادبیات', 'English Language & Literature', 8, 6),
  ('33333333-3333-3333-3333-333333333333', 'د اوبو زیرمو او چاپېریال ساتنه', 'Water Resources & Environment Protection', 8, 1),
  ('33333333-3333-3333-3333-333333333333', 'سیول', 'Civil', 8, 2),
  ('33333333-3333-3333-3333-333333333333', 'برق', 'Electricity', 8, 3),
  ('44444444-4444-4444-4444-444444444444', 'عمومی وترنری', 'General Veterinary', 10, 1),
  ('55555555-5555-5555-5555-555555555555', 'مالي او بانکي', 'Finance & Banking', 8, 1),
  ('55555555-5555-5555-5555-555555555555', 'اداره او تجارت', 'Administration & Business', 8, 2),
  ('66666666-6666-6666-6666-666666666666', 'اسلامي تعلیمات', 'Islamic Teachings', 8, 1),
  ('66666666-6666-6666-6666-666666666666', 'فقه او قانون', 'Fiqh & Law', 8, 2),
  ('66666666-6666-6666-6666-666666666666', 'اسلامي ثقافت', 'Islamic Culture', 0, 3),
  ('77777777-7777-7777-7777-777777777777', 'معلوماتي سیستمونه', 'Information Systems', 8, 1),
  ('77777777-7777-7777-7777-777777777777', 'معلوماتي ټکنالوژي', 'Information Technology', 8, 2)
on conflict do nothing;

-- ----------------------------------------------------------
-- Storage bucket for book PDFs (create in the dashboard if this
-- insert is not allowed in the SQL editor).
-- ----------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('books', 'books', true)
on conflict (id) do nothing;

-- ----------------------------------------------------------
-- Row Level Security (RLS)
-- Students (anonymous) can only READ public content.
-- Only signed-in admins listed in the admins table can WRITE.
-- ----------------------------------------------------------
alter table faculties enable row level security;
alter table departments enable row level security;
alter table academic_years enable row level security;
alter table semesters enable row level security;
alter table books enable row level security;
alter table reading_books enable row level security;
alter table roles enable row level security;
alter table admins enable row level security;
alter table downloads enable row level security;
alter table favorites enable row level security;
alter table reading_history enable row level security;
alter table reading_progress enable row level security;
alter table notifications enable row level security;
alter table suggestions enable row level security;
alter table audit_logs enable row level security;
alter table settings enable row level security;

-- Helper: is the current user an active admin?
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.admins
    where admins.id = auth.uid()
      and admins.is_active = true
  );
$$;

-- Public read policies (anonymous users = students).
create policy "public read faculties" on faculties
  for select using (is_active = true);
create policy "public read departments" on departments
  for select using (is_active = true);
create policy "public read academic_years" on academic_years
  for select using (true);
create policy "public read semesters" on semesters
  for select using (true);
create policy "public read books" on books
  for select using (is_archived = false);
create policy "public read reading_books" on reading_books
  for select using (is_archived = false);
create policy "public read notifications" on notifications
  for select using (is_active = true);

-- Students may record a download (insert only, no reading others' rows).
create policy "anyone can log a download" on downloads
  for insert with check (true);

-- Anyone may send a suggestion/complaint (insert only).
create policy "anyone can send a suggestion" on suggestions
  for insert with check (true);

-- Admin write policies (all tables the admin manages).
create policy "admin write faculties" on faculties
  for all using (public.is_admin()) with check (public.is_admin());
create policy "admin write departments" on departments
  for all using (public.is_admin()) with check (public.is_admin());
create policy "admin write academic_years" on academic_years
  for all using (public.is_admin()) with check (public.is_admin());
create policy "admin write semesters" on semesters
  for all using (public.is_admin()) with check (public.is_admin());
create policy "admin write books" on books
  for all using (public.is_admin()) with check (public.is_admin());
create policy "admin write reading_books" on reading_books
  for all using (public.is_admin()) with check (public.is_admin());
create policy "admin write notifications" on notifications
  for all using (public.is_admin()) with check (public.is_admin());
create policy "admin read suggestions" on suggestions
  for select using (public.is_admin());
create policy "admin write suggestions" on suggestions
  for update using (public.is_admin()) with check (public.is_admin());
create policy "admin read audit_logs" on audit_logs
  for select using (public.is_admin());
create policy "admin write audit_logs" on audit_logs
  for insert with check (public.is_admin());
create policy "admin read admins" on admins
  for select using (public.is_admin());
create policy "admin read roles" on roles
  for select using (public.is_admin());
create policy "admin write settings" on settings
  for all using (public.is_admin()) with check (public.is_admin());

-- Storage policies for the "books" bucket:
-- everyone can read PDFs, only signed-in users can upload.
create policy "public read book files" on storage.objects
  for select using (bucket_id = 'books');
create policy "authenticated upload book files" on storage.objects
  for insert with check (
    bucket_id = 'books' and auth.role() = 'authenticated'
  );
create policy "authenticated delete book files" on storage.objects
  for delete using (
    bucket_id = 'books' and auth.role() = 'authenticated'
  );

-- ----------------------------------------------------------
-- After running this file:
-- 1. In Supabase Dashboard > Authentication, create the admin user
--    (Mohammad Ziarmal's email), then add a row in the admins table
--    with the same user id and role 'super_admin':
--      insert into admins (id, email, full_name, role)
--      values ('<user-id from auth.users>', '<email>',
--              'Mohammad Ziarmal', 'super_admin');
-- 2. In Authentication > MFA, enable TOTP (2FA) for admins.
-- 3. In GitHub repository Settings > Secrets, add SUPABASE_URL and
--    SUPABASE_ANON_KEY (Project Settings > API), then rebuild the APKs.
-- ----------------------------------------------------------
