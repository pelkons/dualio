// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Dualio';

  @override
  String get searchPlaceholder => 'Finde alles, was du gespeichert hast...';

  @override
  String get feedTab => 'Inbox';

  @override
  String get searchTab => 'Suche';

  @override
  String get savedTab => 'Gespeichert';

  @override
  String get settingsTab => 'Einstellungen';

  @override
  String get addItem => 'Hinzufugen';

  @override
  String get signInTitle => 'Anmelden';

  @override
  String get signInBody => 'Melde dich mit Apple, Google oder E-Mail an.';

  @override
  String get addTitle => 'Erfassen';

  @override
  String get addBody =>
      'Fuge einen Link ein, wahle ein Foto, nutze die Kamera oder speichere Text.';

  @override
  String get searchTitle => 'Semantische Suche';

  @override
  String get searchBody =>
      'Hybride Suche kombiniert Embeddings, Volltext, Entitaten, Aliase, Aktualitat und Reranking.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsBody =>
      'Konto, Abo, Sprache, Theme, Teilen, Export und Abmelden.';

  @override
  String get detailTitle => 'Detail';

  @override
  String get sourceLink => 'Quelle';

  @override
  String get ingredients => 'Zutaten';

  @override
  String get steps => 'Schritte';

  @override
  String get cast => 'Besetzung';

  @override
  String get whereToWatch => 'Wo ansehen';

  @override
  String get hours => 'Zeiten';

  @override
  String get notes => 'Notizen';

  @override
  String get keySpecs => 'Daten';

  @override
  String get articleType => 'Artikel';

  @override
  String get essayType => 'Essay';

  @override
  String get recipeType => 'Rezept';

  @override
  String get filmType => 'Film';

  @override
  String get placeType => 'Ort';

  @override
  String get productType => 'Produkt';

  @override
  String get videoType => 'Video';

  @override
  String get highlightType => 'Zitat';

  @override
  String get needsClarificationType => 'Klarung notig';

  @override
  String minutesRead(int minutes) {
    return '$minutes Min. Lesezeit';
  }

  @override
  String get streamingLinksPlaceholder => 'Streaming-Links folgen';

  @override
  String get playableLinkPlaceholder => 'Abspielbarer Link folgt';

  @override
  String directedBy(String director) {
    return 'Regie: $director';
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
  String get continueWithGoogle => 'Mit Google fortfahren';

  @override
  String get continueWithApple => 'Mit Apple fortfahren';

  @override
  String get orSignInWithEmail => 'or use email';

  @override
  String get googleSignInStarted => 'Continue in the Google sign-in window.';

  @override
  String get googleSignInFailed =>
      'Google-Anmeldung konnte nicht gestartet werden. Versuche es erneut.';

  @override
  String get appleSignInStarted => 'Fahre im Apple-Anmeldefenster fort.';

  @override
  String get appleSignInFailed =>
      'Apple-Anmeldung konnte nicht gestartet werden. Versuche es erneut.';
}
