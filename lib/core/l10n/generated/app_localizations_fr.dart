// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Dualio';

  @override
  String get searchPlaceholder =>
      'Retrouvez tout ce que vous avez sauvegarde...';

  @override
  String get feedTab => 'Inbox';

  @override
  String get searchTab => 'Recherche';

  @override
  String get savedTab => 'Sauvegardes';

  @override
  String get settingsTab => 'Reglages';

  @override
  String get addItem => 'Ajouter';

  @override
  String get signInTitle => 'Connexion';

  @override
  String get signInBody => 'Connectez-vous avec Apple, Google ou email.';

  @override
  String get addTitle => 'Capture';

  @override
  String get addBody =>
      'Collez un lien, ajoutez une photo, utilisez l appareil photo ou sauvegardez du texte.';

  @override
  String get shareConfirmTitle => 'Enregistrer ceci ?';

  @override
  String get shareConfirmBody =>
      'Verifiez l element partage et ajoutez une note personnelle avant l envoi dans la boite.';

  @override
  String get searchTitle => 'Recherche semantique';

  @override
  String get searchBody =>
      'La recherche hybride combinera embeddings, texte integral, entites, alias, recence et reranking.';

  @override
  String get settingsTitle => 'Reglages';

  @override
  String get settingsBody =>
      'Compte, abonnement, langue, theme, partage, export et deconnexion.';

  @override
  String get detailTitle => 'Detail';

  @override
  String get sourceLink => 'Source';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get steps => 'Etapes';

  @override
  String get cast => 'Distribution';

  @override
  String get whereToWatch => 'Ou regarder';

  @override
  String get hours => 'Horaires';

  @override
  String get notes => 'Notes';

  @override
  String get keySpecs => 'Caracteristiques';

  @override
  String get articleType => 'Article';

  @override
  String get essayType => 'Essai';

  @override
  String get recipeType => 'Recette';

  @override
  String get filmType => 'Film';

  @override
  String get placeType => 'Lieu';

  @override
  String get productType => 'Produit';

  @override
  String get videoType => 'Video';

  @override
  String get highlightType => 'Citation';

  @override
  String get needsClarificationType => 'Clarification requise';

  @override
  String get socialLinkType => 'Lien social';

  @override
  String get socialLinkLimited =>
      'Enregistre comme lien. Ajoutez une capture d\'ecran plus tard pour une meilleure extraction IA.';

  @override
  String minutesRead(int minutes) {
    return '$minutes min de lecture';
  }

  @override
  String get streamingLinksPlaceholder => 'Liens de streaming a venir';

  @override
  String get playableLinkPlaceholder => 'Lien de lecture a venir';

  @override
  String directedBy(String director) {
    return 'Realise par $director';
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
      'Browse saved memory by inferred type: recipes, films, places, articles, products, videos, notes, and unknown items.';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get orSignInWithEmail => 'or use email';

  @override
  String get googleSignInStarted => 'Continue in the Google sign-in window.';

  @override
  String get googleSignInFailed =>
      'Impossible de lancer la connexion Google. Reessayez.';

  @override
  String get appleSignInStarted =>
      'Continuez dans la fenetre de connexion Apple.';

  @override
  String get appleSignInFailed =>
      'Impossible de lancer la connexion Apple. Reessayez.';

  @override
  String get deleteItem => 'Supprimer';

  @override
  String get deleteItemTitle => 'Supprimer cet element ?';

  @override
  String get deleteItemBody => 'Il sera retire de votre inbox.';

  @override
  String get deleteItemCancel => 'Annuler';

  @override
  String get deleteItemConfirm => 'Supprimer';

  @override
  String get signedInTitle => 'Connecte';

  @override
  String get signedInBody =>
      'Dualio synchronise les elements sauvegardes pour ce compte.';

  @override
  String signedInAs(String email) {
    return 'Connecte avec $email';
  }

  @override
  String get signOut => 'Se deconnecter';

  @override
  String get unknownAccount => 'Compte connecte';
}
