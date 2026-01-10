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
  String get bio => 'السيرة الذاتية';

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
  String get enterAgencyName => 'أدخل اسم الوكالة';

  @override
  String get enterBusinessRegistrationId => 'أدخل رقم تسجيل الأعمال';

  @override
  String get agencyNameRequired => 'اسم الوكالة مطلوب';

  @override
  String get businessIdRequired => 'رقم تسجيل الأعمال مطلوب';

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
  String get noActiveListings => 'لا توجد قوائم نشطة بعد.';

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
  String get apply => 'تطبيق';

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

  @override
  String get notifications => 'الإشعارات';

  @override
  String get noNotifications => 'لا توجد إشعارات';

  @override
  String get markAllRead => 'تعليم الكل كمقروء';

  @override
  String get notificationPermissionRequired =>
      'إذن الإشعارات مطلوب لتلقي التحديثات';

  @override
  String get notificationPermissionDenied => 'تم رفض إذن الإشعارات';

  @override
  String get newBooking => 'حجز جديد';

  @override
  String get bookingUpdated => 'تم تحديث الحجز';

  @override
  String get newJobAvailable => 'وظيفة جديدة متاحة';

  @override
  String get settingsPage => 'صفحة الإعدادات';

  @override
  String get account => 'الحساب';

  @override
  String get language => 'اللغة';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get payment => 'الدفع';

  @override
  String get paymentMethods => 'طرق الدفع';

  @override
  String get support => 'الدعم';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get logOut => 'تسجيل الخروج؟';

  @override
  String get logOutMessage =>
      'هل أنت متأكد من أنك تريد تسجيل الخروج من حساب CleanSpace الخاص بك؟';

  @override
  String get yesLogOut => 'نعم، تسجيل الخروج';

  @override
  String get loggedOutSuccessfully => 'تم تسجيل الخروج بنجاح';

  @override
  String get addPost => 'إضافة منشور';

  @override
  String get postNow => 'نشر الآن';

  @override
  String get jobTitle => 'عنوان الوظيفة';

  @override
  String get jobDescription => 'وصف الوظيفة';

  @override
  String get budget => 'الميزانية';

  @override
  String get estimatedDuration => 'المدة المقدرة';

  @override
  String get hours => 'ساعات';

  @override
  String get days => 'أيام';

  @override
  String get selectServiceType => 'اختر نوع الخدمة';

  @override
  String get selectProvince => 'اختر الولاية';

  @override
  String get uploadImages => 'رفع الصور';

  @override
  String get maxImages => 'حد أقصى 5 صور';

  @override
  String get pleaseLogin => 'يرجى تسجيل الدخول لنشر وظيفة';

  @override
  String get jobPostedSuccessfully => 'تم نشر الوظيفة بنجاح!';

  @override
  String get searchForCleaningServices => 'البحث عن خدمات التنظيف';

  @override
  String get location => 'الموقع';

  @override
  String get rating => 'التقييم';

  @override
  String get price => 'السعر';

  @override
  String get selectWilayasMultiple => 'اختر الولايات (متعدد)';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get deselectAll => 'إلغاء تحديد الكل';

  @override
  String get done => 'تم';

  @override
  String get ratingRange => 'نطاق التقييم';

  @override
  String get minRating => 'الحد الأدنى للتقييم (0-5)';

  @override
  String get maxRating => 'الحد الأقصى للتقييم (0-5)';

  @override
  String get clear => 'مسح';

  @override
  String get priceRangeDzd => 'نطاق السعر (دج)';

  @override
  String get minPrice => 'الحد الأدنى للسعر';

  @override
  String get maxPrice => 'الحد الأقصى للسعر';

  @override
  String get noCleanersFound => 'لم يتم العثور على منظفين';

  @override
  String get addToTeam => 'إضافة إلى الفريق';

  @override
  String get invalidProfile => 'ملف شخصي غير صالح';

  @override
  String get cleanerAlreadyInTeam => 'هذا المنظف موجود بالفعل في فريقك';

  @override
  String get cleanerAddedSuccessfully => 'تمت إضافة المنظف بنجاح!';

  @override
  String get errorAddingCleaner => 'خطأ في إضافة المنظف';

  @override
  String get remove => 'إزالة';

  @override
  String get removeCleaner => 'إزالة المنظف';

  @override
  String get areYouSureRemoveCleaner =>
      'هل أنت متأكد أنك تريد إزالة هذا المنظف من فريقك؟';

  @override
  String get cleanerRemovedSuccessfully => 'تمت إزالة المنظف بنجاح!';

  @override
  String get errorRemovingCleaner => 'خطأ في إزالة المنظف';

  @override
  String get availableJobs => 'الوظائف المتاحة';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get assigned => 'مُعيَّن';

  @override
  String get jobDone => 'تم';

  @override
  String get cancelled => 'ملغي';

  @override
  String get manageJob => 'إدارة الوظيفة';

  @override
  String get pauseJob => 'إيقاف الوظيفة مؤقتاً';

  @override
  String get activateJob => 'تفعيل الوظيفة';

  @override
  String get leaveReview => 'ترك تقييم';

  @override
  String get accept => 'قبول';

  @override
  String get decline => 'رفض';

  @override
  String get applications => 'الطلبات';

  @override
  String get noApplications => 'لا توجد طلبات بعد';

  @override
  String get assignedWorker => 'العامل المعين';

  @override
  String get noWorkerAssigned => 'لم يتم تعيين عامل بعد';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get aboutMe => 'نبذة عني';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get enterYourFullName => 'أدخل اسمك الكامل';

  @override
  String get emailAddress => 'عنوان البريد الإلكتروني';

  @override
  String get enterYourEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get enterYourPhoneNumber => 'أدخل رقم هاتفك';

  @override
  String get profilePicture => 'صورة الملف الشخصي';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get identityVerification => 'التحقق من الهوية';

  @override
  String get idVerificationMessage => 'لحماية مجتمعنا، نطلب التحقق من الهوية.';

  @override
  String get uploadId => 'رفع بطاقة الهوية';

  @override
  String get idUploadDescription => 'الوجه الأمامي والخلفي لبطاقة الهوية';

  @override
  String get accountDetails => 'تفاصيل الحساب';

  @override
  String get dateFormatHint => 'شهر/يوم/سنة';

  @override
  String get wilayaProvince => 'الولاية';

  @override
  String get selectYourWilaya => 'اختر ولايتك';

  @override
  String get baladiya => 'البلدية';

  @override
  String get selectYourBaladiya => 'اختر بلديتك (اختياري)';

  @override
  String get enterStreetName => 'أدخل اسم الشارع، رقم المبنى، إلخ.';

  @override
  String get tellUsAboutYourself => 'أخبرنا عن نفسك...';

  @override
  String get contactForPricing => 'اتصل للاستفسار عن السعر';

  @override
  String get postANewJob => 'نشر وظيفة جديدة';

  @override
  String get locationWilaya => 'الموقع (الولاية)';

  @override
  String get selectYourProvince => 'اختر ولايتك';

  @override
  String get yourBudgetDzd => 'ميزانيتك (دج)';

  @override
  String get enterYourBudget => 'أدخل ميزانيتك';

  @override
  String get durationExample => 'مثال: 3';

  @override
  String get addPhotos => 'إضافة صور';

  @override
  String get maximumPhotosAllowed => 'حد أقصى 5 صور';

  @override
  String get pleaseSelectServiceType => 'يرجى اختيار نوع الخدمة';

  @override
  String get pleaseSelectLocation => 'يرجى اختيار الموقع';

  @override
  String get pleaseEnterBudget => 'يرجى إدخال الميزانية';

  @override
  String get pleaseEnterJobDescription => 'يرجى إدخال وصف الوظيفة';

  @override
  String errorPickingImages(String error) {
    return 'خطأ في اختيار الصور: $error';
  }

  @override
  String errorPostingJob(String error) {
    return 'خطأ في نشر الوظيفة: $error';
  }

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String daysAgo(int days) {
    return 'منذ $days يوم';
  }

  @override
  String get posted => 'نُشر';

  @override
  String get weeks => 'أسابيع';

  @override
  String get homeCleaning => 'تنظيف المنازل';

  @override
  String get officeCleaning => 'تنظيف المكاتب';

  @override
  String get specialtyCleaning => 'تنظيف متخصص';

  @override
  String get industrialCleaning => 'تنظيف صناعي';

  @override
  String get clickToUpload => 'انقر للتحميل';

  @override
  String get dragAndDrop => ' أو اسحب وأفلت';

  @override
  String get maximumPhotosReached => 'تم الوصول إلى الحد الأقصى 5 صور';

  @override
  String get egPlaceholder => 'مثال: 3';

  @override
  String fromDzdPerHr(String hourlyRate) {
    return 'من $hourlyRate دج/ساعة';
  }

  @override
  String get available => 'متاح';

  @override
  String get noActiveListingsYet => 'لا توجد قوائم نشطة بعد.';

  @override
  String get errorLoadingProfile => 'خطأ في تحميل الملف الشخصي';

  @override
  String get noUserDataAvailable => 'لا توجد بيانات مستخدم متاحة';

  @override
  String get unknown => 'غير معروف';

  @override
  String get anErrorOccurred => 'حدث خطأ';

  @override
  String get justNow => 'الآن';

  @override
  String get budgetNegotiable => 'الميزانية قابلة للتفاوض';

  @override
  String get untitledJob => 'وظيفة بدون عنوان';

  @override
  String areYouSureDeleteJob(String title) {
    return 'هل أنت متأكد أنك تريد حذف \"$title\"؟';
  }

  @override
  String get verified => 'مُتحقق منه';

  @override
  String partOfAgency(String agency) {
    return 'جزء من $agency';
  }

  @override
  String get experience => 'الخبرة';

  @override
  String get age => 'العمر';

  @override
  String get languages => 'اللغات';

  @override
  String get servicesOffered => 'الخدمات المقدمة';

  @override
  String get noCleaningHistoryYet => 'لا يوجد سجل تنظيف بعد.';

  @override
  String get jobDetails => 'تفاصيل الوظيفة';

  @override
  String get postedBy => 'نشر بواسطة';

  @override
  String get description => 'الوصف';

  @override
  String estimatedHours(int hours) {
    return 'مقدر $hours ساعة';
  }

  @override
  String get submitBid => 'تقديم عرض';

  @override
  String get yourBidPrice => 'سعر عرضك (دج)';

  @override
  String get enterBidPrice => 'أدخل سعر عرضك';

  @override
  String get messageToClient => 'رسالة للعميل (اختياري)';

  @override
  String get enterMessage => 'أدخل رسالتك';

  @override
  String get pleaseLoginToSubmitBid => 'يرجى تسجيل الدخول لتقديم عرض';

  @override
  String get unableToGetUserId => 'تعذر الحصول على معرف المستخدم';

  @override
  String get pleaseEnterValidBidPrice => 'يرجى إدخال سعر عرض صالح';

  @override
  String get bidSubmittedSuccessfully => 'تم تقديم العرض بنجاح!';

  @override
  String get errorSubmittingBid => 'خطأ في تقديم العرض';

  @override
  String get errorSubmittingBidInvalidData =>
      'خطأ في تقديم العرض: تنسيق البيانات غير صالح. يرجى المحاولة مرة أخرى.';

  @override
  String get errorSubmittingBidUnexpected =>
      'خطأ في تقديم العرض: حدث خطأ غير متوقع';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get profilePictureUpdatedSuccessfully =>
      'تم تحديث صورة الملف الشخصي بنجاح!';

  @override
  String get profilePictureRemovedSuccessfully =>
      'تم إزالة صورة الملف الشخصي بنجاح!';

  @override
  String get failedToRemoveProfilePicture => 'فشل في إزالة صورة الملف الشخصي';

  @override
  String get servicesOfferedLabel => 'الخدمات المقدمة';

  @override
  String get experienceLevel => 'مستوى الخبرة';

  @override
  String get selectExperienceLevel => 'اختر مستوى الخبرة';

  @override
  String get entry => 'مبتدئ';

  @override
  String get mid => 'متوسط';

  @override
  String get senior => 'خبير';

  @override
  String get hourlyRateDzd => 'السعر بالساعة (دج)';

  @override
  String get pleaseSelectAtLeastOneService =>
      'يرجى اختيار خدمة واحدة على الأقل';

  @override
  String get wilayaRequired => 'الولاية مطلوبة';

  @override
  String get baladiyaMunicipality => 'البلدية';

  @override
  String get streetAddressOptional => 'عنوان الشارع (اختياري)';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get areYouSureDeleteAccount =>
      'هل أنت متأكد أنك تريد حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه وستتم حذف جميع منشوراتك.';

  @override
  String get yesDeleteAccount => 'نعم، احذف الحساب';

  @override
  String get accountDeletedSuccessfully => 'تم حذف الحساب بنجاح';

  @override
  String get settings => 'الإعدادات';

  @override
  String get cleaner => 'منظف';

  @override
  String get individual => 'فردي';

  @override
  String get agencyProfileComingSoon => 'ملف الوكالة قادم قريباً';

  @override
  String get noPastBookingsYet => 'لا توجد حجوزات سابقة بعد.';

  @override
  String get noCleanersInTeamYet => 'لا يوجد منظفون في فريقك بعد.';

  @override
  String get errorLoadingCleanerProfile => 'خطأ في تحميل ملف المنظف';

  @override
  String get addCleaner => 'إضافة منظف';

  @override
  String get requiredServices => 'الخدمات المطلوبة';

  @override
  String get yourBid => 'عرضك';

  @override
  String get yourPriceDa => 'سعرك (دج)';

  @override
  String get enterYourBidPrice => 'أدخل سعر عرضك';

  @override
  String get pleaseEnterBidPrice => 'يرجى إدخال سعر عرض';

  @override
  String get pleaseEnterValidPrice => 'يرجى إدخال سعر صالح';

  @override
  String get messageOptional => 'الرسالة (اختياري)';

  @override
  String get addShortMessageToClient => 'أضف رسالة قصيرة للعميل...';

  @override
  String estimatedHoursFormat(int hours) {
    return 'مقدر $hours ساعة';
  }

  @override
  String get noReviewsYet => 'لا توجد تقييمات بعد.';

  @override
  String get bid => 'عرض';

  @override
  String minutesAgo(int minutes) {
    return 'منذ $minutes دقيقة';
  }

  @override
  String hoursAgo(int hours) {
    return 'منذ $hours ساعة';
  }

  @override
  String get phone => 'الهاتف';

  @override
  String get partOf => 'جزء من';

  @override
  String get allReviews => 'جميع التقييمات';

  @override
  String get cleaningHistory => 'سجل التنظيف';

  @override
  String get noCleaningHistoryAvailable => 'لا يوجد سجل تنظيف متاح';

  @override
  String get cleanerIdNotFound => 'لم يتم العثور على معرف المنظف';

  @override
  String get cleaningJob => 'وظيفة تنظيف';

  @override
  String get activePosts => 'المنشورات النشطة';

  @override
  String get noPostsYet => 'لا توجد منشورات بعد.';

  @override
  String get noActivePosts => 'لا توجد منشورات نشطة.';

  @override
  String get myPostsOnlyForClients => 'منشوراتي متاحة للعملاء فقط.';

  @override
  String get activePostsOnlyForClients => 'المنشورات النشطة متاحة للعملاء فقط.';

  @override
  String reviewsCount(int count) {
    return '$count تقييم';
  }

  @override
  String get cleanSpaceFeatures => 'مميزات CleanSpace';

  @override
  String get everythingYouNeed => 'كل ما تحتاجه في تطبيق واحد';

  @override
  String get findVerifiedCleaners => 'العثور على منظفين موثوقين';

  @override
  String get browseTrustedProfessionals =>
      'تصفح المحترفين الموثوقين مع الملفات الشخصية والتصنيفات الم verified';

  @override
  String get easyBooking => 'الحجز السهل';

  @override
  String get postYourJob => 'انشر وظيفتك واحصل على عروض من المنظفين المؤهلين';

  @override
  String get jobOpportunities => 'فرص العمل';

  @override
  String get findStableWork =>
      'ابحث عن عمل مستقر ونمّي أعمال التنظيف الخاصة بك';

  @override
  String get cleaspaceExperience => 'تجربة CLEASPACE';

  @override
  String get allInOnePlatform => 'منصة شاملة لخدمات التنظيف الموثوقة.';

  @override
  String get verifiedProfessionals => 'المهنيون الموثوقون';

  @override
  String get everyCleanerPasses =>
      'كل منظف ووكالة يمر بفحوصات الهوية والجودة للثقة الكاملة.';

  @override
  String get smartMatching => 'المطابقة الذكية';

  @override
  String get browseCuratedLists =>
      'تصفح القوائم المنسقة أو دع CleanSpace يقترح أفضل المنظفين المناسبين.';

  @override
  String get transparentPricing => 'التسعير الشفاف';

  @override
  String get seeClearHourlyRates =>
      'شاهد أسعار الساعة الواضحة قبل الحجز. لا مفاجآت خفية.';

  @override
  String get cleaspaceAlgeria => 'CLEASPACE الجزائر';

  @override
  String get readyToLaunch => 'هل أنت مستعد لإطلاق مساحة نظيفة جديدة؟';

  @override
  String get createAccountDescription =>
      'أنشئ حسابًا لحجز منظفين موثوقين، أو إدارة الوكالات، أو تقديم خدمات التنظيف الخاصة بك إلى السوق المتنامي في الجزائر.';

  @override
  String get next => 'التالي';

  @override
  String get skipToLogin => 'تخطي إلى تسجيل الدخول';

  @override
  String get iAlreadyHaveAccount => 'لدي حساب بالفعل';

  @override
  String get createAccountPage => 'صفحة إنشاء الحساب';

  @override
  String get uploadProfilePicture => 'رفع صورة الملف الشخصي';

  @override
  String get uploadAClearPhoto => 'قم بتحميل صورة واضحة';

  @override
  String get photoSelected => 'تم اختيار الصورة';
}
