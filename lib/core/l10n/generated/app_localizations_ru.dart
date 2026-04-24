// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Dualio';

  @override
  String get searchPlaceholder => 'Найдите все, что сохранили...';

  @override
  String get feedTab => 'Входящие';

  @override
  String get searchTab => 'Поиск';

  @override
  String get savedTab => 'Сохраненное';

  @override
  String get settingsTab => 'Настройки';

  @override
  String get addItem => 'Добавить';

  @override
  String get signInTitle => 'Войти';

  @override
  String get signInBody => 'Войдите через Apple, Google или email.';

  @override
  String get addTitle => 'Сохранить';

  @override
  String get addBody =>
      'Вставьте ссылку, добавьте фото, откройте камеру или сохраните текст.';

  @override
  String get searchTitle => 'Семантический поиск';

  @override
  String get searchBody =>
      'Гибридный поиск объединит embeddings, полный текст, сущности, алиасы, свежесть и reranking.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsBody =>
      'Аккаунт, подписка, язык, тема, sharing, экспорт и выход.';

  @override
  String get detailTitle => 'Детали';

  @override
  String get sourceLink => 'Источник';

  @override
  String get ingredients => 'Ингредиенты';

  @override
  String get steps => 'Шаги';

  @override
  String get cast => 'Актеры';

  @override
  String get whereToWatch => 'Где смотреть';

  @override
  String get hours => 'Часы';

  @override
  String get notes => 'Заметки';

  @override
  String get keySpecs => 'Характеристики';

  @override
  String get articleType => 'Статья';

  @override
  String get essayType => 'Эссе';

  @override
  String get recipeType => 'Рецепт';

  @override
  String get filmType => 'Фильм';

  @override
  String get placeType => 'Место';

  @override
  String get productType => 'Товар';

  @override
  String get videoType => 'Видео';

  @override
  String get highlightType => 'Цитата';

  @override
  String get needsClarificationType => 'Нужно уточнение';

  @override
  String minutesRead(int minutes) {
    return '$minutes мин чтения';
  }

  @override
  String get streamingLinksPlaceholder => 'Здесь будут ссылки на просмотр';

  @override
  String get playableLinkPlaceholder => 'Здесь будет ссылка для просмотра';

  @override
  String directedBy(String director) {
    return 'Режиссер: $director';
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
      'Browse saved memory by inferred type: recipes, films, places, articles, products, videos, notes, and unknown items.';

  @override
  String get continueWithGoogle => 'Продолжить с Google';

  @override
  String get continueWithApple => 'Продолжить с Apple';

  @override
  String get orSignInWithEmail => 'or use email';

  @override
  String get googleSignInStarted => 'Continue in the Google sign-in window.';

  @override
  String get googleSignInFailed =>
      'Не удалось начать вход через Google. Попробуйте снова.';

  @override
  String get appleSignInStarted => 'Продолжите вход в окне Apple.';

  @override
  String get appleSignInFailed =>
      'Не удалось начать вход через Apple. Попробуйте снова.';
}
