// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Dualio';

  @override
  String get searchPlaceholder => 'Encuentra todo lo que guardaste...';

  @override
  String get feedTab => 'Bandeja';

  @override
  String get searchTab => 'Buscar';

  @override
  String get savedTab => 'Guardados';

  @override
  String get settingsTab => 'Ajustes';

  @override
  String get addItem => 'Anadir';

  @override
  String get signInTitle => 'Iniciar sesion';

  @override
  String get signInBody => 'Usa tu email para recibir un enlace magico.';

  @override
  String get addTitle => 'Capturar';

  @override
  String get addBody =>
      'Pega un enlace, agrega una foto, usa la camara o guarda texto.';

  @override
  String get searchTitle => 'Busqueda semantica';

  @override
  String get searchBody =>
      'La busqueda hibrida combinara embeddings, texto completo, entidades, alias, recencia y reranking.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsBody =>
      'Cuenta, suscripcion, idioma, tema, compartir, exportar y cerrar sesion.';

  @override
  String get detailTitle => 'Detalle';

  @override
  String get sourceLink => 'Fuente';

  @override
  String get ingredients => 'Ingredientes';

  @override
  String get steps => 'Pasos';

  @override
  String get cast => 'Reparto';

  @override
  String get whereToWatch => 'Donde ver';

  @override
  String get hours => 'Horario';

  @override
  String get notes => 'Notas';

  @override
  String get keySpecs => 'Especificaciones';

  @override
  String get articleType => 'Articulo';

  @override
  String get essayType => 'Ensayo';

  @override
  String get recipeType => 'Receta';

  @override
  String get filmType => 'Pelicula';

  @override
  String get placeType => 'Lugar';

  @override
  String get productType => 'Producto';

  @override
  String get videoType => 'Video';

  @override
  String get highlightType => 'Cita';

  @override
  String get needsClarificationType => 'Necesita aclaracion';

  @override
  String minutesRead(int minutes) {
    return '$minutes min de lectura';
  }

  @override
  String get streamingLinksPlaceholder => 'Enlaces de streaming pendientes';

  @override
  String get playableLinkPlaceholder => 'Enlace reproducible pendiente';

  @override
  String directedBy(String director) {
    return 'Dirigida por $director';
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
