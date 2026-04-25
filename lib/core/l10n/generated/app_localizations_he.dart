// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'Dualio';

  @override
  String get searchPlaceholder => 'חיפוש בכל מה ששמרת...';

  @override
  String get feedTab => 'תיבה';

  @override
  String get searchTab => 'חיפוש';

  @override
  String get savedTab => 'שמורים';

  @override
  String get settingsTab => 'הגדרות';

  @override
  String get addItem => 'הוספה';

  @override
  String get signInTitle => 'כניסה';

  @override
  String get signInBody => 'היכנסו עם Apple, Google או אימייל.';

  @override
  String get addTitle => 'שמירה';

  @override
  String get addBody => 'הדביקו קישור, הוסיפו תמונה, פתחו מצלמה או שמרו טקסט.';

  @override
  String get shareConfirmTitle => 'לשמור את זה?';

  @override
  String get shareConfirmBody =>
      'בדקו את הפריט ששותף והוסיפו הערה אישית לפני שהוא נכנס לתיבה.';

  @override
  String get searchTitle => 'חיפוש סמנטי';

  @override
  String get searchBody =>
      'חיפוש היברידי ישלב embeddings, טקסט מלא, ישויות, כינויים, עדכניות ודירוג מחדש.';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get settingsBody => 'חשבון, מנוי, שפה, ערכת נושא, שיתוף, יצוא ויציאה.';

  @override
  String get detailTitle => 'פריט';

  @override
  String get sourceLink => 'מקור';

  @override
  String get ingredients => 'מרכיבים';

  @override
  String get materials => 'חומרים';

  @override
  String get steps => 'שלבים';

  @override
  String get cast => 'שחקנים';

  @override
  String get whereToWatch => 'איפה לצפות';

  @override
  String get hours => 'שעות';

  @override
  String get notes => 'הערות';

  @override
  String get keySpecs => 'מפרט';

  @override
  String get articleType => 'כתבה';

  @override
  String get essayType => 'מאמר';

  @override
  String get recipeType => 'מתכון';

  @override
  String get filmType => 'סרט';

  @override
  String get placeType => 'מקום';

  @override
  String get productType => 'מוצר';

  @override
  String get videoType => 'וידאו';

  @override
  String get manualType => 'מדריך';

  @override
  String get highlightType => 'ציטוט';

  @override
  String get needsClarificationType => 'צריך הבהרה';

  @override
  String get socialLinkType => 'קישור חברתי';

  @override
  String get socialLinkLimited =>
      'נשמר כקישור. אפשר להוסיף צילום מסך בהמשך לחילוץ AI טוב יותר.';

  @override
  String minutesRead(int minutes) {
    return '$minutes דקות קריאה';
  }

  @override
  String stepsCount(int count) {
    return '$count שלבים';
  }

  @override
  String get streamingLinksPlaceholder => 'כאן יופיעו קישורי צפייה';

  @override
  String get playableLinkPlaceholder => 'כאן יופיע קישור לצפייה';

  @override
  String directedBy(String director) {
    return 'בימוי: $director';
  }

  @override
  String get captureSourceText => 'Text';

  @override
  String get captureSourceLink => 'Link';

  @override
  String get captureInputLabel => 'What do you want to save?';

  @override
  String get captureInputHint =>
      'Paste a link, note, quote, or anything you want to find later.';

  @override
  String get emptyCaptureError => 'Add something before saving.';

  @override
  String get saveToInbox => 'Save to inbox';

  @override
  String get addFromLibrary => 'Photo library';

  @override
  String get addFromCamera => 'Camera';

  @override
  String get searchInputLabel => 'Search memory';

  @override
  String get searchResults => 'Results';

  @override
  String get searchTryExample =>
      'Try: slow architecture, Copenhagen cafe, sourdough, or romantic drama.';

  @override
  String get searchNoResults => 'No saved items matched this search.';

  @override
  String get semanticDebugReason => 'Matched by local semantic fields';

  @override
  String get processingType => 'Processing';

  @override
  String get processingFailedType => 'לא ניתן לעבד';

  @override
  String get retryProcessing => 'נסה שוב';

  @override
  String get editItem => 'עריכה';

  @override
  String get editGeneratedContent => 'עריכת התוכן שנוצר';

  @override
  String get generatedTitleLabel => 'כותרת';

  @override
  String get ingredientsEditHint => 'מרכיב אחד בכל שורה.';

  @override
  String get materialsEditHint => 'חומר, כלי או דרישה אחת בכל שורה.';

  @override
  String get stepsEditHint => 'שלב אחד בכל שורה.';

  @override
  String get personalNote => 'הערה אישית';

  @override
  String get personalNoteHint => 'הוסיפו הקשר, תזכורת או תגובה משלכם.';

  @override
  String get personalNoteEmpty => 'אין עדיין הערה אישית.';

  @override
  String get saveChanges => 'שמירה';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get sendMagicLink => 'Send magic link';

  @override
  String get magicLinkSent => 'Check your email for the sign-in link.';

  @override
  String get magicLinkFailed => 'Could not send the magic link. Try again.';

  @override
  String get supabaseNotConfigured => 'Supabase is not configured yet.';

  @override
  String get themeSetting => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSetting => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get accountSetting => 'Account';

  @override
  String get accountSettingBody => 'Email, profile, and account lifecycle.';

  @override
  String get subscriptionSetting => 'Subscription';

  @override
  String get subscriptionSettingBody => 'Billing seam for a future paid plan.';

  @override
  String get shareExtensionSetting => 'Share extension';

  @override
  String get shareExtensionSettingBody =>
      'Instructions for saving from other apps.';

  @override
  String get exportSetting => 'Export';

  @override
  String get exportSettingBody => 'Prepare a portable archive of saved memory.';

  @override
  String get signOutSetting => 'Sign out';

  @override
  String get signOutSettingBody => 'End the current authenticated session.';

  @override
  String get categoriesTab => 'Categories';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesBody =>
      'עיון בפריטים לפי סוג: מתכונים, סרטים, מקומות, כתבות, מוצרים, וידאו, מדריכים, הערות ופריטים לא ידועים.';

  @override
  String get continueWithGoogle => 'המשך עם Google';

  @override
  String get continueWithApple => 'המשך עם Apple';

  @override
  String get orSignInWithEmail => 'or use email';

  @override
  String get googleSignInStarted => 'Continue in the Google sign-in window.';

  @override
  String get googleSignInFailed => 'לא ניתן להתחיל כניסה עם Google. נסו שוב.';

  @override
  String get appleSignInStarted => 'המשיכו בחלון הכניסה של Apple.';

  @override
  String get appleSignInFailed => 'לא ניתן להתחיל כניסה עם Apple. נסו שוב.';

  @override
  String get deleteItem => 'מחיקה';

  @override
  String get deleteItemTitle => 'למחוק את הפריט?';

  @override
  String get deleteItemBody => 'הפריט יוסר מהתיבה שלך.';

  @override
  String get deleteItemCancel => 'ביטול';

  @override
  String get deleteItemConfirm => 'מחיקה';

  @override
  String get signedInTitle => 'מחובר';

  @override
  String get signedInBody => 'Dualio מסנכרן פריטים שמורים עבור החשבון הזה.';

  @override
  String signedInAs(String email) {
    return 'מחובר בתור $email';
  }

  @override
  String get signOut => 'יציאה';

  @override
  String get unknownAccount => 'חשבון מחובר';

  @override
  String get deleteAccountSetting => 'מחיקת חשבון';

  @override
  String get deleteAccountSettingBody =>
      'מחיקה לצמיתות של החשבון, הפריטים השמורים והתמונות שהועלו.';

  @override
  String get deleteAccountTitle => 'למחוק את החשבון?';

  @override
  String get deleteAccountBody =>
      'הפעולה תמחק לצמיתות את החשבון, הפריטים השמורים, הנתונים שחולצו והתמונות שהועלו. אי אפשר לבטל אותה.';

  @override
  String get deleteAccountCancel => 'ביטול';

  @override
  String get deleteAccountConfirm => 'מחיקת חשבון';

  @override
  String get deleteAccountFailed => 'לא ניתן למחוק את החשבון. נסו שוב.';
}
