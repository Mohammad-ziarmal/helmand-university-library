# د هلمند پوهنتون ډیجیټل کتابتون — Flutter پروژه

**مالک او اصلي مدیر:** محمد زیارمل — هلمند پوهنتون، ښوونې او روزنې پوهنځی، بیولوژي څانګه

دا د پروژې بشپړ کوډ دی: د محصلینو اپ، جلا اډمین اپ، ډیټابېس سکیما، او د APK جوړولو وړیا لار (GitHub Actions). له دې څخه دوه APK جوړېږي — یو د محصلینو لپاره، یو د اډمین لپاره.

> **مهمه خبرتیا:** دلته هېڅ پیسې غوښتونکی خدمت نشته. GitHub او Supabase وړیا پلانونه دي. هېڅ Secret Key په دې کوډ کې نشته — کیلي ګانې یوازې په GitHub Secrets کې ساتل کېږي.

## په دې پروژه کې څه شته

```text
helmand-university-flutter-project/
  student_app/        # د محصلینو اپ (7 پوهنځي، 21 څانګې، 227 کتابونه)
    lib/
      main.dart
      data/catalogue.dart   # ټول پوهنځي، څانګې، سمسترونه او کتابونه
      screens/              # کور، پوهنځي، سمسترونه، پلټنه، خوښې، پروفایل
    android/                # applicationId: com.helmandlibrary.student
  admin_app/          # جلا اډمین اپ (یوازې مدیران)
    lib/
      main.dart
      services/supabase_service.dart
      screens/              # ننوتل، ډشبورډ، کتابونه، پوهنځي، احصائیه، Setup
    android/                # applicationId: com.helmandlibrary.admin
  supabase/schema.sql       # ډیټابېس: 16 جدولونه + امنیتي قواعد (RLS)
  .github/workflows/build-apk.yml   # په وړیا توګه APK جوړول
```

**د محصلینو اپ:** پښتو (RTL) او انګلیسي (LTR)، روښانه/تیاره بڼه، پلټنه، خوښې کتابونه، د مطالعې کتابتون، د جوړونکي پروفایل. له انټرنېټ پرته هم کار کوي — کتابونه د لوستلو لپاره انټرنېټ غواړي. 227 کتابونه پکې دي (بیولوژي 74، سیول 37، عمومي وترنري 37، ریاضي 28، اوبه 22، فزیک 18، کیمیا 16، کرهڼه 31، برق 8) او 22 د مطالعې کتابونه (20 پښتو، 2 انګلیسي). کمپیوټر ساینس پوهنځی (معلوماتي سیستمونه، معلوماتي ټکنالوژي) اضافه شوی دی — نصاب یې لا نه دی خپور شوی، نو سمسترونه یې تش دي. هغه څانګې چې کتاب یې نشته (انګلیسي، پښتو، شرعیاتو، فقه او قانون) په اپ کې دا پیغام ښیي چې کتابونه به له پوهنتون څخه راوړل شي.

**اډمین اپ:** جلا ننوتل (ایمیل + پټ نوم)، پوهنځي/څانګې/کتابونه اضافه کول، بدلول او حذفول، له ټېلېفون څخه PDF اپلوډ، احصائیه، او د بدلونونو تاریخچه (audit log).

## ګام ۱ — GitHub حساب جوړ کړئ (وړیا، په خپل نوم)

1. په ګروم کې `github.com/join` پرانیستئ.
2. خپل ایمیل، پټ نوم او کارن‌نوم ولیکئ (کارن‌نوم دې ستاسو خپل وي، لکه `mohammad-ziarmal`).
3. ایمیل تایید کړئ. حساب وړیا دی.

## ګام ۲ — Repository جوړ کړئ

1. په GitHub کې **New repository** ټک کړئ.
2. نوم: `helmand-university-library` — **Private** وټاکئ (شخصي وي، عامه نه).
3. **Create repository** ټک کړئ.

## ګام ۳ — پروژه GitHub ته پورته کړئ (له ټېلېفون څخه)

له ټېلېفون څخه د یوې ټولې پروژې پورته کول لږ ستونزمن دي، خو کېږي. دوه لارې دي:

### لاره الف — Termux (وړیا اپ، په خپله وکړئ)

1. **Termux** له F-Droid څخه نصب کړئ (په Play Store کې زوړ دی؛ F-Droid وړیا دی).
2. په Termux کې دا امرونه یو په یو ولیکئ:
   ```bash
   pkg update && pkg install git -y
   git config --global user.name "Mohammad Ziarmal"
   git config --global user.email "ziarmalsahabmohammadullah@gmail.com"
   ```
3. په GitHub کې یو Token جوړ کړئ (دا ستاسو د پټ نوم پر ځای کارېږي):
   GitHub → خپل عکس → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)** → **Generate new token (classic)** → `repo` ټک کړئ → **Generate token** → Token کاپي کړئ (یوازې یو ځل ښکاري).
4. په Termux کې:
   ```bash
   git clone https://github.com/USERNAME/helmand-university-library.git
   ```
   د `USERNAME` پر ځای خپل GitHub کارن‌نوم ولیکئ.
5. دا ZIP فایل په ټېلېفون کې ډاونلوډ او Extract کړئ (د فایل منیجر په وسیله)، بیا په Termux کې:
   ```bash
   cp -r /sdcard/Download/helmand-university-flutter-project/. helmand-university-library/
   cd helmand-university-library
   git add .
   git commit -m "Helmand University Library v1"
   git push
   ```
   کله چې کارن‌نوم وغواړي، خپل GitHub کارن‌نوم ولیکئ؛ کله چې پټ نوم وغواړي، هغه Token چې په ۳ ګام کې مو جوړ کړی و، پېسټ کړئ.
   > که د `Download` فولډر لار بله وي (لکه `/storage/emulated/0/Download/`)، هماغه لار وکاروئ. مهمه دا ده چې پټه `.github` فولډر هم کاپي شي — نو د `/.` بڼه وکاروئ، نه `/*`.

### لاره ب — د ملګري کمپیوټر (اسانه)

که Termux ستونزمن وي، له یوه ملګري وغواړئ چې په ۵ دقیقو کې دا کار وکړي: Repository کلون کړي، د پروژې فایلونه پکې کاپي کړي، `git add .`، `git commit`، `git push`. له هغه وروسته هر څه (APK جوړول، ډاونلوډ) تاسو په خپله له ټېلېفون څخه کوئ.

## ګام ۴ — APK جوړ کړئ (وړیا)

1. په ګروم کې خپل Repository پرانیستئ → **Actions** ټب.
2. **Build APKs** وټاکئ → **Run workflow** → **Run workflow**.
3. څو دقیقې انتظار وکړئ تر څو دواړه کارونه شنه (✓) شي.
4. په هماغه پاڼه کې لاندې **Artifacts** ته ورشئ:
   - `student-app-apk` — د محصلینو اپ ډاونلوډ کړئ.
   - `admin-app-apk` — د اډمین اپ ډاونلوډ کړئ (یوازې تاسو یې وساتئ).
5. ډاونلوډ شوی ZIP فایل Extract کړئ، APK ټک کړئ او **Install** کړئ. که ټېلېفون وپوښتي، د ګروم لپاره **Allow install from this source** فعال کړئ.

> د GitHub وړیا پلان میاشت کې محدودې دقیقې لري؛ یو جوړول څو دقیقې نیسي. یوازې هغه وخت یې وچلوئ چې نوې نسخه تیاره وي.

## ګام ۵ — Supabase (اختیاري؛ لومړی ځل یې پرېږدئ)

د محصلینو اپ له Supabase پرته هم بشپړ کار کوي. Supabase هغه وخت اړین دی چې وغواړئ اډمین اپ وکاروئ:

1. په `supabase.com` کې په خپل نوم وړیا پروژه جوړه کړئ.
2. **SQL Editor** کې د پروژې `supabase/schema.sql` فایل وچلوئ (۶ پوهنځي او ۲۲ څانګې په خپله جوړېږي).
3. **Storage** کې د `books` په نوم یو Public Bucket جوړ کړئ.
4. **Authentication** کې د مدیر لپاره یو کارن جوړ کړئ، او په `admins` جدول کې یې `super_admin` رول ورکړئ (لارښوونه د `schema.sql` په پای کې ده).
5. په GitHub کې **Settings → Secrets → Actions → New secret** کې دوه Secret اضافه کړئ: `SUPABASE_URL` او `SUPABASE_ANON_KEY` (له Supabase → Project Settings → API څخه یې کاپي کړئ).
6. بیا Actions وچلوئ او نوي APK ډاونلوډ کړئ.

**2FA:** په Supabase Dashboard کې **Authentication → MFA** کې TOTP فعال کړئ. د Admin App په Setup پاڼه کې هم لارښوونه شته.

## وروسته بدلونونه څنګه کوئ

- **نوی کتاب یا نوی سمستر:** که Supabase وصل وي، په اډمین اپ کې یې اضافه کړئ. که نه وي، په `student_app/lib/data/catalogue.dart` کې یې ولیکئ او APK بیا جوړ کړئ.
- **نوې نسخه:** په `pubspec.yaml` کې نسخه زیاته کړئ (لکه `1.0.0+1` څخه `1.0.1+2` ته)، بیا `git push` وکړئ او Actions وچلوئ.
- **د محصلینو APK** له محصلینو سره شریک کړئ. **د اډمین APK هېڅکله له محصلینو سره مه شریکوئ.**

## امنیت — مهم ټکي

- Secret Keys یوازې په GitHub Secrets کې دي — په کوډ کې نشته.
- Admin App جلا دی؛ محصل یوازې لوستلی شي.
- یوازې هغه کتابونه خپاره کړئ چې قانوني اجازه لري.
- د خپرولو لپاره خپله Keystore جوړه کړئ او په خوندي ځای کې یې وساتئ (اوسنۍ نسخه د ازموینې لپاره د Debug کیلي سره لاسلیک کېږي).
- هر بدلون په `audit_logs` کې ثبتېږي.

## لا پاتې کار

- د پوهنتون رسمي PDF کتابونه (په ځانګړي ډول د انګلیسي، پښتو، شرعیاتو او د غذایي موادو ټکنالوژۍ څانګو لپاره) — له پوهنتون څخه ترلاسه کړئ او په اډمین اپ کې یې اضافه کړئ.
- د اپ دننه PDF Reader او آفلاین ډاونلوډ — راتلونکې نسخه.
- د Play Store لپاره Keystore او خپرول — کله چې اپ بشپړ شو.
