import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Smart Buyer Store',
      'start': 'Start',
      'language': 'Language',
      'theme': 'Theme',
      'welcome_title': 'Find the best product with confidence',
      'welcome_description': 'Describe what you need and let AI guide your purchase.',
      'login_title': 'Welcome back',
      'login_subtitle': 'Sign in or create an account to continue.',
      'email': 'Email',
      'password': 'Password',
      'login': 'Login',
      'sign_up': 'Sign Up',
      'continue_as_guest': 'Continue as Guest',
      'auth_error': 'Unable to complete authentication right now.',
      'auth_success': 'Signed in successfully.',
      'product_name': 'Product Name',
      'product_name_hint': 'e.g. Smartphone',
      'product_image': 'Product Image',
      'choose_image': 'Choose Image',
      'budget': 'Available Budget',
      'budget_hint': 'Enter amount in YER',
      'search': 'Search',
      'history': 'History',
      'validation_message': 'Please provide a product name or an image.',
      'loading': 'Analyzing your request...',
      'network_error': 'No internet connection. Please try again.',
      'timeout_error': 'The request timed out. Please try again.',
      'api_error': 'We could not process the request right now.',
      'invalid_json': 'The AI response was not valid. Please try again.',
      'estimated_new_price': 'Estimated New Price',
      'estimated_used_price': 'Estimated Used Price',
      'advantages': 'Advantages',
      'disadvantages': 'Disadvantages',
      'recommended_products': 'Recommended Products',
      'search_history': 'Search History',
      'delete_all': 'Delete All',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'confirm_delete': 'Delete this item?',
      'confirm_delete_all': 'Delete all history?',
      'yes': 'Yes',
      'no': 'No',
      'no_history': 'No search history yet.',
      'result_saved': 'Result saved to history.',
      'price_note': 'Budget comparison is based on the estimated prices.',
      'budget_enough': 'Your budget is enough for this product.',
      'budget_low': 'The following alternatives fit your budget better.',
      'budget_high': 'Higher quality alternatives may be better for you.',
    },
    'ar': {
      'app_title': 'متجر المشتري الذكي',
      'start': 'ابدأ',
      'language': 'اللغة',
      'theme': 'السمة',
      'welcome_title': 'اعثر على أفضل منتج بثقة',
      'welcome_description': 'صف ما تحتاجه واسمح للذكاء الاصطناعي بإرشاد شراءك.',
      'login_title': 'مرحبًا بك مرة أخرى',
      'login_subtitle': 'سجل الدخول أو أنشئ حسابًا للمتابعة.',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'login': 'تسجيل الدخول',
      'sign_up': 'إنشاء حساب',
      'continue_as_guest': 'المتابعة كزائر',
      'auth_error': 'تعذر إكمال المصادقة الآن.',
      'auth_success': 'تم تسجيل الدخول بنجاح.',
      'product_name': 'اسم المنتج',
      'product_name_hint': 'مثال: هاتف ذكي',
      'product_image': 'صورة المنتج',
      'choose_image': 'اختر صورة',
      'budget': 'الميزانية المتاحة',
      'budget_hint': 'أدخل المبلغ بالريال اليمني',
      'search': 'بحث',
      'history': 'السجل',
      'validation_message': 'يرجى إدخال اسم منتج أو صورة واحدة على الأقل.',
      'loading': 'يتم تحليل طلبك...',
      'network_error': 'لا يوجد اتصال بالإنترنت. يرجى المحاولة مرة أخرى.',
      'timeout_error': 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.',
      'api_error': 'لم نتمكن من معالجة الطلب الآن.',
      'invalid_json': 'استجابة الذكاء الاصطناعي غير صالحة. يرجى المحاولة مرة أخرى.',
      'estimated_new_price': 'السعر المتوقع الجديد',
      'estimated_used_price': 'السعر المتوقع المستعمل',
      'advantages': 'المميزات',
      'disadvantages': 'العيوب',
      'recommended_products': 'المنتجات المقترحة',
      'search_history': 'سجل البحث',
      'delete_all': 'حذف الكل',
      'delete': 'حذف',
      'cancel': 'إلغاء',
      'confirm_delete': 'هل تريد حذف هذا العنصر؟',
      'confirm_delete_all': 'هل تريد حذف كل السجل؟',
      'yes': 'نعم',
      'no': 'لا',
      'no_history': 'لا يوجد سجل بحث بعد.',
      'result_saved': 'تم حفظ النتيجة في السجل.',
      'price_note': 'يعتمد مقارنة الميزانية على الأسعار المقدرة.',
      'budget_enough': 'ميزانيتك كافية لشراء هذا المنتج.',
      'budget_low': 'البدائل التالية تناسب ميزانيتك بشكل أفضل.',
      'budget_high': 'بدائل أعلى جودة قد تكون أفضل لك.',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key]!;
  }

  String get formattedDate => DateFormat.yMMMd(locale.toString()).format(DateTime.now());
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(locale) ||
      (locale.languageCode == 'ar' || locale.languageCode == 'en');

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
