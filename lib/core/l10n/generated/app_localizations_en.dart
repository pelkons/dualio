// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Dualio';

  @override
  String get searchPlaceholder => 'Find anything you saved...';

  @override
  String get feedTab => 'Inbox';

  @override
  String get searchTab => 'Search';

  @override
  String get savedTab => 'Saved';

  @override
  String get settingsTab => 'Settings';

  @override
  String get addItem => 'Add item';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInBody => 'Use your email to receive a magic link.';

  @override
  String get addTitle => 'Capture';

  @override
  String get addBody =>
      'Paste a link, add a photo, use the camera, or save raw text.';

  @override
  String get searchTitle => 'Semantic search';

  @override
  String get searchBody =>
      'Hybrid search will combine embeddings, full text, entities, aliases, recency, and reranking.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsBody =>
      'Account, subscription, language, theme, sharing, export, and sign out.';

  @override
  String get detailTitle => 'Item detail';

  @override
  String get sourceLink => 'Source';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get steps => 'Steps';

  @override
  String get cast => 'Cast';

  @override
  String get whereToWatch => 'Where to watch';

  @override
  String get hours => 'Hours';

  @override
  String get notes => 'Notes';

  @override
  String get keySpecs => 'Key specs';

  @override
  String get articleType => 'Article';

  @override
  String get essayType => 'Essay';

  @override
  String get recipeType => 'Recipe';

  @override
  String get filmType => 'Film';

  @override
  String get placeType => 'Place';

  @override
  String get productType => 'Product';

  @override
  String get videoType => 'Video';

  @override
  String get highlightType => 'Highlight';

  @override
  String get needsClarificationType => 'Needs clarification';

  @override
  String minutesRead(int minutes) {
    return '$minutes min read';
  }

  @override
  String get streamingLinksPlaceholder => 'Streaming links placeholder';

  @override
  String get playableLinkPlaceholder => 'Playable deep link placeholder';

  @override
  String directedBy(String director) {
    return 'Directed by $director';
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
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orSignInWithEmail => 'or use email';

  @override
  String get googleSignInStarted => 'Continue in the Google sign-in window.';

  @override
  String get googleSignInFailed => 'Could not start Google sign-in. Try again.';
}
