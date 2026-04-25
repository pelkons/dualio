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
  String get shareConfirmTitle => 'Сохранить это?';

  @override
  String get shareConfirmBody =>
      'Проверьте общий материал и добавьте личную заметку перед сохранением во входящие.';

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
  String get materials => 'Материалы';

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
  String get manualType => 'Инструкция';

  @override
  String get highlightType => 'Цитата';

  @override
  String get needsClarificationType => 'Нужно уточнение';

  @override
  String get socialLinkType => 'Соцссылка';

  @override
  String get socialLinkLimited =>
      'Сохранено как ссылка. Позже можно добавить скриншот для более точного AI-разбора.';

  @override
  String minutesRead(int minutes) {
    return '$minutes мин чтения';
  }

  @override
  String stepsCount(int count) {
    return '$count шагов';
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
  String get processingFailedType => 'Could not process';

  @override
  String get retryProcessing => 'Retry';

  @override
  String get editItem => 'Edit';

  @override
  String get editGeneratedContent => 'Редактировать сгенерированное';

  @override
  String get generatedTitleLabel => 'Название';

  @override
  String get ingredientsEditHint => 'Один ингредиент на строку.';

  @override
  String get materialsEditHint =>
      'Один материал, инструмент или требование на строку.';

  @override
  String get stepsEditHint => 'Один шаг на строку.';

  @override
  String get personalNote => 'Personal note';

  @override
  String get personalNoteHint => 'Add your own context, reminder, or comment.';

  @override
  String get personalNoteEmpty => 'No personal note yet.';

  @override
  String get saveChanges => 'Save';

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
      'Просматривайте сохраненное по типам: рецепты, фильмы, места, статьи, товары, видео, инструкции, заметки и неизвестные элементы.';

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

  @override
  String get deleteItem => 'Удалить';

  @override
  String get deleteItemTitle => 'Удалить этот элемент?';

  @override
  String get deleteItemBody => 'Он будет удален из входящих.';

  @override
  String get deleteItemCancel => 'Отмена';

  @override
  String get deleteItemConfirm => 'Удалить';

  @override
  String get signedInTitle => 'Вы вошли';

  @override
  String get signedInBody =>
      'Dualio синхронизирует сохраненные элементы для этого аккаунта.';

  @override
  String signedInAs(String email) {
    return 'Вход выполнен как $email';
  }

  @override
  String get signOut => 'Выйти';

  @override
  String get unknownAccount => 'Аккаунт в системе';

  @override
  String get deleteAccountSetting => 'Удалить аккаунт';

  @override
  String get deleteAccountSettingBody =>
      'Навсегда удалить аккаунт, сохраненные элементы и загруженные изображения.';

  @override
  String get deleteAccountTitle => 'Удалить аккаунт?';

  @override
  String get deleteAccountBody =>
      'Это навсегда удалит аккаунт, сохраненные элементы, извлеченные данные и загруженные изображения. Действие нельзя отменить.';

  @override
  String get deleteAccountCancel => 'Отмена';

  @override
  String get deleteAccountConfirm => 'Удалить аккаунт';

  @override
  String get deleteAccountFailed =>
      'Не удалось удалить аккаунт. Попробуйте снова.';
}
