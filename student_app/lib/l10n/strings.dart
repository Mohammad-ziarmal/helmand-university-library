// Simple Pashto / English strings for the student app.
// Pashto is the default language; English is the second language.
// No generated l10n files are needed, so the project stays small and
// buildable without extra tooling.

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/store.dart';

/// Translate [key] using the current language from [AppState].
String tr(BuildContext context, String key) {
  final ps = context.watch<AppState>().isPashto;
  return Strings.t(key, ps);
}

extension AppStateContext on BuildContext {
  /// Current language flag, watched so the widget rebuilds on change.
  bool watchAppStateIsPashto() => watch<AppState>().isPashto;
}

class Strings {
  static String t(String key, bool isPashto) {
    final map = isPashto ? ps : en;
    return map[key] ?? ps[key] ?? key;
  }

  static const Map<String, String> ps = {
    'appTitle': 'د هلمند پوهنتون کتابتون',
    'appSubtitle': 'ډیجیټل کتابتون — هلمند پوهنتون',
    'universityLibrary': 'د پوهنتون کتابتون',
    'universityLibraryDesc': 'پوهنځي، څانګې، سمسترونه او درسي کتابونه',
    'readingLibrary': 'د مطالعې کتابتون',
    'readingLibraryDesc': 'پښتو ادبي او عمومي کتابونه',
    'developerProfile': 'د اپلیکیشن جوړونکی',
    'developerProfileDesc': 'محمد زیارمل — هلمند پوهنتون',
    'searchHint': 'کتاب، مضمون یا لیکوال وپلټئ…',
    'search': 'پلټنه',
    'favorites': 'خوښې کتابونه',
    'settings': 'تنظیمات',
    'faculties': 'پوهنځي',
    'departments': 'څانګې',
    'semesters': 'سمسترونه',
    'semester': 'سمستر',
    'subjects': 'مضمونونه',
    'books': 'کتابونه',
    'book': 'کتاب',
    'read': 'ولولئ',
    'download': 'ډاونلوډ',
    'author': 'لیکوال',
    'credits': 'کریدیتونه',
    'code': 'کوډ',
    'newBooks': 'نوي کتابونه',
    'allBooks': 'ټول کتابونه',
    'language': 'ژبه',
    'theme': 'بڼه',
    'light': 'روښانه',
    'dark': 'تیاره',
    'system': 'د سیسټم له مخې',
    'about': 'په اړه',
    'aboutText':
        'دا اپ د هلمند پوهنتون د محصلینو لپاره جوړ شوی دی، تر څو درسي کتابونه په اسانۍ پیدا، ولولي او ډاونلوډ کړي. ټول کتابونه د لوړو زده کړو وزارت د درسي کتابونو ملي پروګرام (eCampus) له لارې وړیا دي.',
    'noFavorites': 'تر اوسه مو هېڅ کتاب نه دی خوښ کړی.',
    'noResults': 'هېڅ پایله ونه موندل شوه.',
    'openError': 'لینک پرانیستل نه شو.',
    'call': 'زنګ',
    'email': 'ایمیل',
    'serviceDeptNote':
        'دا خدمتي څانګه ده؛ خپله درجه نه لري، خو په نورو څانګو کې اسلامي ثقافت تدریسوي.',
    'generalSubjects': 'عمومي مضمونونه',
    'categories': 'کټګورۍ',
    'comingSoon': 'ژر راځي',
    'home': 'کور',
    'totalBooks': 'ټول کتابونه',
    'totalDepartments': 'ټولې څانګې',
    'totalFaculties': 'ټول پوهنځي',
    'unknownAuthor': 'نامعلوم',
    'version': 'نسخه 1.0.0+19',
    'catalogue': 'کټالوګ',
    'catalogueRemote':
        'تازه کټالوګ له سرور څخه ښودل کېږي.',
    'catalogueBundled':
        'په تلیفون کې خوندي شوی کټالوګ ښودل کېږي (آفلاین).',
    'catalogueRefresh': 'کټالوګ تازه کول',
    'catalogueUpdated': 'کټالوګ تازه شو.',
    'catalogueRefreshFailed':
        'تازه کول ونشول — انټرنیټ وګورئ؛ زوړ کټالوګ ښودل کېږي.',
    'noBooksNote':
        'د دې څانګې کتابونه لا په eCampus کې نشته؛ کتابونه به له پوهنتون څخه راوړل شي.',
    'pcbNote':
        'دا کتاب د eCampus د PCB پاڼې له لارې موندل کېږي؛ لینک تاسو هماغې پاڼې ته بیایي.',
    'freeBooksNote':
        'ټول کتابونه وړیا دي — د لوړو زده کړو وزارت، د درسي کتابونو ملي پروګرام.',
    'developerRole': 'د پروژې جوړونکی او اصلي مدیر',
    'developerMessage':
        'زما موخه د هلمند پوهنتون د محصلینو لپاره د علمي سرچینو او درسي کتابونو د لاسرسي یوه اسانه، عصري او ګټوره لاره رامنځته کول دي. زه غواړم د ټکنالوژۍ په مرسته د خپل پوهنتون او ټولنې لپاره داسې ډیجیټلي خدمات وړاندې کړم چې د علم، پوهې او پرمختګ په برخه کې دوامداره ګټه ولري.',
    'subject': 'مضمون',
    'tapToOpen': 'د پرانیستلو لپاره یې ټک کړئ',
    'savedOfflineNote':
        'دا اپ له انټرنېټ پرته هم کار کوي؛ کتابونه د لوستلو لپاره انټرنېټ غواړي.',
    'createAccount': 'اکونټ جوړول',
    'createAccountTitle': 'خپل اکونټ جوړ کړئ',
    'login': 'ننوتل',
    'loginTitle': 'بیرته ښه راغلاست',
    'register': 'راجستر',
    'firstName': 'نوم',
    'surname': 'تخلص',
    'faculty': 'پوهنځی',
    'department': 'څانګه',
    'selectFaculty': 'پوهنځی وټاکئ',
    'selectDepartment': 'څانګه وټاکئ',
    'password': 'پاسورډ',
    'yourPhoto': 'خپل عکس',
    'tapToAddPhoto': 'د عکس اضافه کولو لپاره ټک کړئ',
    'allFieldsRequired': 'ټول معلومات اړین دي — مهرباني وکړئ هر څه ډک کړئ.',
    'photoRequired': 'خپل عکس اړین دی.',
    'invalidEmail': 'ایمیل سم نه دی.',
    'passwordTooShort': 'پاسورډ باید لږ تر لږه ۶ توري ولري.',
    'wrongCredentials': 'ایمیل یا پاسورډ سم نه دی.',
    'noAccountYet': 'اکونټ نه لرئ؟',
    'haveAccount': 'اکونټ لرئ؟',
    'logout': 'وتل',
    'account': 'اکونټ',
    'welcome': 'ښه راغلاست',
    'share': 'شریکول',
    'internetRequired':
        'د اکونټ جوړولو لپاره انټرنیت فعال کړئ — بغیر له انټرنیټ څخه اکونټ نه جوړېږي.',
    'tapSubjectToOpenBook':
        'پر مضمون ټک کړئ — د هغه مضمون کتاب به درته راشي.',
    'tapBookToOpen':
        'د کتاب پر نوم ټک کړئ — هماغه کتاب به PDF کې پرانیستل شي.',
    'noBookForSubject': 'د دې مضمون کتاب لا نشته.',
    'noSubjectsYet': 'د دې سمستر مضمونونه لا نه دي اضافه شوي.',
    'bookComingSoon':
        'ډېر ژر به یې زیارمل صاحب اپلوډ کړي، ان‌شاءالله.',
    'downloaded': 'ډاونلوډ شو',
    'downloading': 'ډاونلوډ کېږي…',
    'downloadFailed': 'ډاونلوډ نه شو — انټرنېټ وګورئ.',
    'readOffline': 'بې انټرنېټه ولولئ',
    'savedOnPhone':
        'په موبایل کې خوندي شو — بیا یې بې انټرنېټه هم لوستلی شئ.',
  };

  static const Map<String, String> en = {
    'appTitle': 'Helmand University Library',
    'appSubtitle': 'Digital Library — Helmand University',
    'universityLibrary': 'University Library',
    'universityLibraryDesc': 'Faculties, departments, semesters and textbooks',
    'readingLibrary': 'Reading Library',
    'readingLibraryDesc': 'Pashto literary and general books',
    'developerProfile': 'App Developer',
    'developerProfileDesc': 'Mohammad Ziarmal — Helmand University',
    'searchHint': 'Search a book, subject or author…',
    'search': 'Search',
    'favorites': 'Favorites',
    'settings': 'Settings',
    'faculties': 'Faculties',
    'departments': 'Departments',
    'semesters': 'Semesters',
    'semester': 'Semester',
    'subjects': 'Subjects',
    'books': 'Books',
    'book': 'Book',
    'read': 'Read',
    'download': 'Download',
    'author': 'Author',
    'credits': 'Credits',
    'code': 'Code',
    'newBooks': 'New Books',
    'allBooks': 'All Books',
    'language': 'Language',
    'theme': 'Appearance',
    'light': 'Light',
    'dark': 'Dark',
    'system': 'System',
    'about': 'About',
    'aboutText':
        'This app is made for Helmand University students, so they can easily find, read and download their textbooks. All books are free through the Ministry of Higher Education National Textbooks Program (eCampus).',
    'noFavorites': 'You have not favourited any book yet.',
    'noResults': 'No results found.',
    'openError': 'Could not open the link.',
    'call': 'Call',
    'email': 'Email',
    'serviceDeptNote':
        'This is a service department; it has no degree of its own, but teaches Islamic Culture in the other departments.',
    'generalSubjects': 'General Subjects',
    'categories': 'Categories',
    'comingSoon': 'Coming soon',
    'home': 'Home',
    'totalBooks': 'Total books',
    'totalDepartments': 'Total departments',
    'totalFaculties': 'Total faculties',
    'unknownAuthor': 'Unknown',
    'version': 'Version 1.0.0+19',
    'catalogue': 'Catalogue',
    'catalogueRemote': 'Showing the latest catalogue from the server.',
    'catalogueBundled':
        'Showing the catalogue saved on the phone (offline).',
    'catalogueRefresh': 'Refresh catalogue',
    'catalogueUpdated': 'Catalogue updated.',
    'catalogueRefreshFailed':
        'Could not refresh — check the internet; showing the saved catalogue.',
    'noBooksNote':
        'No books for this department on eCampus yet; books will come from the university.',
    'pcbNote':
        'This book is found through the eCampus PCB textbooks page; the link opens that page.',
    'freeBooksNote':
        'All books are free — Ministry of Higher Education, National Textbooks Program.',
    'developerRole': 'Project founder and main administrator',
    'developerMessage':
        'My goal is to create an easy, modern and useful way for Helmand University students to access academic resources and textbooks. With the help of technology, I want to provide digital services for my university and community that bring lasting benefit in knowledge and progress.',
    'subject': 'Subject',
    'tapToOpen': 'Tap to open',
    'savedOfflineNote':
        'This app also works without internet; opening a book needs internet.',
    'createAccount': 'Create Account',
    'createAccountTitle': 'Create your account',
    'login': 'Log in',
    'loginTitle': 'Welcome back',
    'register': 'Register',
    'firstName': 'First name',
    'surname': 'Surname',
    'faculty': 'Faculty',
    'department': 'Department',
    'selectFaculty': 'Choose a faculty',
    'selectDepartment': 'Choose a department',
    'password': 'Password',
    'yourPhoto': 'Your photo',
    'tapToAddPhoto': 'Tap to add your photo',
    'allFieldsRequired':
        'All fields are required — please fill in everything.',
    'photoRequired': 'Your photo is required.',
    'invalidEmail': 'The email is not valid.',
    'passwordTooShort': 'Password must be at least 6 characters.',
    'wrongCredentials': 'Email or password is wrong.',
    'noAccountYet': 'No account yet?',
    'haveAccount': 'Already have an account?',
    'logout': 'Log out',
    'account': 'Account',
    'welcome': 'Welcome',
    'share': 'Share',
    'internetRequired':
        'Turn on the internet to create an account — an account cannot be created without internet.',
    'tapSubjectToOpenBook':
        'Tap a subject — that subject\'s book will open.',
    'tapBookToOpen':
        'Tap the book name — that same book will open as a PDF.',
    'noBookForSubject': 'This subject\'s book is not available yet.',
    'noSubjectsYet': 'This semester\'s subjects are not added yet.',
    'bookComingSoon':
        'Ziarmal Sahib will upload it very soon, inshallah.',
    'downloaded': 'Downloaded',
    'downloading': 'Downloading…',
    'downloadFailed': 'Download failed — check the internet.',
    'readOffline': 'Read offline',
    'savedOnPhone':
        'Saved on the phone — you can read it again without internet.',
  };
}
