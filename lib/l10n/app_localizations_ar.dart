// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'كلين سبيس';

  @override
  String get welcome => 'مرحبا';

  @override
  String get welcomeBack => 'مرحباً بعودتك!';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailOrUsername => 'البريد الإلكتروني أو اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get loginWithGoogle => 'تسجيل الدخول عبر Google';

  @override
  String get loginWithFacebook => 'تسجيل الدخول عبر Facebook';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get createOneNow => 'أنشئ واحداً الآن';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get address => 'العنوان';

  @override
  String get bio => 'نبذة';

  @override
  String get gender => 'الجنس';

  @override
  String get birthdate => 'تاريخ الميلاد';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get iAmA => 'أنا...';

  @override
  String get client => 'عميل';

  @override
  String get agency => 'وكالة';

  @override
  String get individualCleaner => 'منظف فردي';

  @override
  String get agencyName => 'اسم الوكالة';

  @override
  String get businessId => 'رقم تسجيل الأعمال';

  @override
  String get services => 'الخدمات المقدمة';

  @override
  String get hourlyRate => 'السعر بالساعة';

  @override
  String get home => 'الرئيسية';

  @override
  String get search => 'بحث';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get activeListings => 'القوائم النشطة';

  @override
  String get pastBookings => 'الحجوزات السابقة';

  @override
  String get cleanerTeam => 'فريق المنظفين';

  @override
  String get jobsCompleted => 'وظائف مكتملة';

  @override
  String get addNewJob => 'إضافة وظيفة جديدة';

  @override
  String get noActiveListings =>
      'لا توجد قوائم نشطة بعد.\nاضغط على زر + لإضافة وظيفة جديدة.';

  @override
  String get noPastBookings => 'لا توجد حجوزات سابقة بعد.';

  @override
  String get noCleaners => 'لا يوجد منظفون في فريقك بعد.';

  @override
  String postedOn(String date) {
    return 'نُشر في: $date';
  }

  @override
  String get edit => 'تعديل';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get activate => 'تفعيل';

  @override
  String get delete => 'حذف';

  @override
  String get searchMyListings => 'البحث في قوائمي...';

  @override
  String get filterByStatus => 'تصفية حسب الحالة';

  @override
  String get sortByDate => 'ترتيب حسب التاريخ';

  @override
  String get all => 'الكل';

  @override
  String get active => 'نشط';

  @override
  String get paused => 'متوقف مؤقتاً';

  @override
  String get booked => 'محجوز';

  @override
  String get completed => 'مكتمل';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String get newestFirst => 'الأحدث أولاً';

  @override
  String get oldestFirst => 'الأقدم أولاً';

  @override
  String get recentListings => 'القوائم الأخيرة';

  @override
  String get topAgencies => 'أفضل الوكالات';

  @override
  String get topCleaners => 'أفضل المنظفين';

  @override
  String get viewProfile => 'عرض الملف الشخصي';

  @override
  String get apply => 'تقديم';

  @override
  String get bookNow => 'احجز الآن';

  @override
  String get myPosts => 'منشوراتي';

  @override
  String get history => 'السجل';

  @override
  String get reviews => 'التقييمات';

  @override
  String get favorites => 'المفضلة';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجح';

  @override
  String accountCreated(String role) {
    return 'تم إنشاء الحساب كـ $role!';
  }

  @override
  String get invalidCredentials => 'اسم المستخدم أو كلمة المرور غير صحيحة';

  @override
  String get usernameExists => 'اسم المستخدم موجود بالفعل';

  @override
  String get emailExists => 'البريد الإلكتروني موجود بالفعل';

  @override
  String get phoneExists => 'رقم الهاتف موجود بالفعل';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get invalidEmail => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get passwordTooShort => 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';

  @override
  String confirmDelete(String title) {
    return 'هل أنت متأكد من حذف \"$title\"؟';
  }

  @override
  String get deleteJob => 'حذف الوظيفة';

  @override
  String get jobDeleted => 'تم حذف الوظيفة بنجاح';

  @override
  String get jobStatusChanged => 'تم تحديث حالة الوظيفة';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get goToHome => 'الذهاب إلى الرئيسية';

  @override
  String hello(String name) {
    return 'مرحباً $name';
  }
}
