// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Dualio';

  @override
  String get searchPlaceholder => 'Trova tutto cio che hai salvato...';

  @override
  String get feedTab => 'Inbox';

  @override
  String get searchTab => 'Cerca';

  @override
  String get savedTab => 'Salvati';

  @override
  String get settingsTab => 'Impostazioni';

  @override
  String get addItem => 'Aggiungi';

  @override
  String get signInTitle => 'Accedi';

  @override
  String get signInBody => 'Accedi con Apple, Google o email.';

  @override
  String get addTitle => 'Acquisisci';

  @override
  String get addBody =>
      'Incolla un link, aggiungi una foto, usa la fotocamera o salva testo.';

  @override
  String get shareConfirmTitle => 'Salvare questo?';

  @override
  String get shareConfirmBody =>
      'Controlla l elemento condiviso e aggiungi una nota personale prima di salvarlo nella inbox.';

  @override
  String get searchTitle => 'Ricerca semantica';

  @override
  String get searchBody =>
      'La ricerca ibrida combinera embeddings, testo completo, entita, alias, recency e reranking.';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsBody =>
      'Account, abbonamento, lingua, tema, condivisione, esportazione e uscita.';

  @override
  String get detailTitle => 'Dettaglio';

  @override
  String get sourceLink => 'Fonte';

  @override
  String get ingredients => 'Ingredienti';

  @override
  String get materials => 'Materiali';

  @override
  String get steps => 'Passaggi';

  @override
  String get cast => 'Cast';

  @override
  String get whereToWatch => 'Dove guardare';

  @override
  String get hours => 'Orari';

  @override
  String get notes => 'Note';

  @override
  String get keySpecs => 'Specifiche';

  @override
  String get articleType => 'Articolo';

  @override
  String get essayType => 'Saggio';

  @override
  String get recipeType => 'Ricetta';

  @override
  String get filmType => 'Film';

  @override
  String get placeType => 'Luogo';

  @override
  String get productType => 'Prodotto';

  @override
  String get videoType => 'Video';

  @override
  String get manualType => 'Manuale';

  @override
  String get highlightType => 'Citazione';

  @override
  String get needsClarificationType => 'Serve chiarimento';

  @override
  String get socialLinkType => 'Link social';

  @override
  String get socialLinkLimited =>
      'Salvato come link. Aggiungi uno screenshot piu tardi per una migliore estrazione AI.';

  @override
  String minutesRead(int minutes) {
    return '$minutes min di lettura';
  }

  @override
  String stepsCount(int count) {
    return '$count passaggi';
  }

  @override
  String get streamingLinksPlaceholder => 'Link di streaming in arrivo';

  @override
  String get playableLinkPlaceholder => 'Link riproducibile in arrivo';

  @override
  String directedBy(String director) {
    return 'Regia di $director';
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
  String get editGeneratedContent => 'Modifica contenuto generato';

  @override
  String get generatedTitleLabel => 'Titolo';

  @override
  String get ingredientsEditHint => 'Un ingrediente per riga.';

  @override
  String get materialsEditHint =>
      'Un materiale, strumento o requisito per riga.';

  @override
  String get stepsEditHint => 'Un passaggio per riga.';

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
      'Sfoglia la memoria salvata per tipo: ricette, film, luoghi, articoli, prodotti, video, manuali, note ed elementi sconosciuti.';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get continueWithApple => 'Continua con Apple';

  @override
  String get orSignInWithEmail => 'or use email';

  @override
  String get googleSignInStarted => 'Continue in the Google sign-in window.';

  @override
  String get googleSignInFailed =>
      'Impossibile avviare l\'accesso con Google. Riprova.';

  @override
  String get appleSignInStarted => 'Continua nella finestra di accesso Apple.';

  @override
  String get appleSignInFailed =>
      'Impossibile avviare l\'accesso con Apple. Riprova.';

  @override
  String get deleteItem => 'Elimina';

  @override
  String get deleteItemTitle => 'Eliminare questo elemento?';

  @override
  String get deleteItemBody => 'Verra rimosso dalla tua inbox.';

  @override
  String get deleteItemCancel => 'Annulla';

  @override
  String get deleteItemConfirm => 'Elimina';

  @override
  String get signedInTitle => 'Accesso effettuato';

  @override
  String get signedInBody =>
      'Dualio sincronizza gli elementi salvati per questo account.';

  @override
  String signedInAs(String email) {
    return 'Accesso come $email';
  }

  @override
  String get signOut => 'Esci';

  @override
  String get unknownAccount => 'Account connesso';

  @override
  String get deleteAccountSetting => 'Elimina account';

  @override
  String get deleteAccountSettingBody =>
      'Elimina definitivamente account, elementi salvati e immagini caricate.';

  @override
  String get deleteAccountTitle => 'Eliminare l\'account?';

  @override
  String get deleteAccountBody =>
      'Questa azione elimina definitivamente account, elementi salvati, dati estratti e immagini caricate. Non puo essere annullata.';

  @override
  String get deleteAccountCancel => 'Annulla';

  @override
  String get deleteAccountConfirm => 'Elimina account';

  @override
  String get deleteAccountFailed =>
      'Impossibile eliminare l\'account. Riprova.';
}
