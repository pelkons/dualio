import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('he'),
    Locale('it'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Dualio'**
  String get appName;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Find anything you saved...'**
  String get searchPlaceholder;

  /// No description provided for @feedTab.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get feedTab;

  /// No description provided for @searchTab.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTab;

  /// No description provided for @savedTab.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInBody.
  ///
  /// In en, this message translates to:
  /// **'Use Apple, Google, or email to sign in.'**
  String get signInBody;

  /// No description provided for @addTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get addTitle;

  /// No description provided for @addBody.
  ///
  /// In en, this message translates to:
  /// **'Paste a link, add a photo, use the camera, or save raw text.'**
  String get addBody;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Semantic search'**
  String get searchTitle;

  /// No description provided for @searchBody.
  ///
  /// In en, this message translates to:
  /// **'Hybrid search will combine embeddings, full text, entities, aliases, recency, and reranking.'**
  String get searchBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsBody.
  ///
  /// In en, this message translates to:
  /// **'Account, subscription, language, theme, sharing, export, and sign out.'**
  String get settingsBody;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Item detail'**
  String get detailTitle;

  /// No description provided for @sourceLink.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceLink;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @cast.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get cast;

  /// No description provided for @whereToWatch.
  ///
  /// In en, this message translates to:
  /// **'Where to watch'**
  String get whereToWatch;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @keySpecs.
  ///
  /// In en, this message translates to:
  /// **'Key specs'**
  String get keySpecs;

  /// No description provided for @articleType.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get articleType;

  /// No description provided for @essayType.
  ///
  /// In en, this message translates to:
  /// **'Essay'**
  String get essayType;

  /// No description provided for @recipeType.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get recipeType;

  /// No description provided for @filmType.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get filmType;

  /// No description provided for @placeType.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get placeType;

  /// No description provided for @productType.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productType;

  /// No description provided for @videoType.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoType;

  /// No description provided for @highlightType.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get highlightType;

  /// No description provided for @needsClarificationType.
  ///
  /// In en, this message translates to:
  /// **'Needs clarification'**
  String get needsClarificationType;

  /// No description provided for @minutesRead.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min read'**
  String minutesRead(int minutes);

  /// No description provided for @streamingLinksPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Streaming links placeholder'**
  String get streamingLinksPlaceholder;

  /// No description provided for @playableLinkPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Playable deep link placeholder'**
  String get playableLinkPlaceholder;

  /// No description provided for @directedBy.
  ///
  /// In en, this message translates to:
  /// **'Directed by {director}'**
  String directedBy(String director);

  /// No description provided for @captureSourceText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get captureSourceText;

  /// No description provided for @captureSourceLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get captureSourceLink;

  /// No description provided for @captureInputLabel.
  ///
  /// In en, this message translates to:
  /// **'What do you want to save?'**
  String get captureInputLabel;

  /// No description provided for @captureInputHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a link, note, quote, or anything you want to find later.'**
  String get captureInputHint;

  /// No description provided for @emptyCaptureError.
  ///
  /// In en, this message translates to:
  /// **'Add something before saving.'**
  String get emptyCaptureError;

  /// No description provided for @saveToInbox.
  ///
  /// In en, this message translates to:
  /// **'Save to inbox'**
  String get saveToInbox;

  /// No description provided for @addFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo library'**
  String get addFromLibrary;

  /// No description provided for @addFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get addFromCamera;

  /// No description provided for @searchInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Search memory'**
  String get searchInputLabel;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get searchResults;

  /// No description provided for @searchTryExample.
  ///
  /// In en, this message translates to:
  /// **'Try: slow architecture, Copenhagen cafe, sourdough, or romantic drama.'**
  String get searchTryExample;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No saved items matched this search.'**
  String get searchNoResults;

  /// No description provided for @semanticDebugReason.
  ///
  /// In en, this message translates to:
  /// **'Matched by local semantic fields'**
  String get semanticDebugReason;

  /// No description provided for @processingType.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processingType;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @sendMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Send magic link'**
  String get sendMagicLink;

  /// No description provided for @magicLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email for the sign-in link.'**
  String get magicLinkSent;

  /// No description provided for @magicLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the magic link. Try again.'**
  String get magicLinkFailed;

  /// No description provided for @supabaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Supabase is not configured yet.'**
  String get supabaseNotConfigured;

  /// No description provided for @themeSetting.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSetting;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get languageSystem;

  /// No description provided for @accountSetting.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSetting;

  /// No description provided for @accountSettingBody.
  ///
  /// In en, this message translates to:
  /// **'Email, profile, and account lifecycle.'**
  String get accountSettingBody;

  /// No description provided for @subscriptionSetting.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionSetting;

  /// No description provided for @subscriptionSettingBody.
  ///
  /// In en, this message translates to:
  /// **'Billing seam for a future paid plan.'**
  String get subscriptionSettingBody;

  /// No description provided for @shareExtensionSetting.
  ///
  /// In en, this message translates to:
  /// **'Share extension'**
  String get shareExtensionSetting;

  /// No description provided for @shareExtensionSettingBody.
  ///
  /// In en, this message translates to:
  /// **'Instructions for saving from other apps.'**
  String get shareExtensionSettingBody;

  /// No description provided for @exportSetting.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportSetting;

  /// No description provided for @exportSettingBody.
  ///
  /// In en, this message translates to:
  /// **'Prepare a portable archive of saved memory.'**
  String get exportSettingBody;

  /// No description provided for @signOutSetting.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutSetting;

  /// No description provided for @signOutSettingBody.
  ///
  /// In en, this message translates to:
  /// **'End the current authenticated session.'**
  String get signOutSettingBody;

  /// No description provided for @categoriesTab.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTab;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesBody.
  ///
  /// In en, this message translates to:
  /// **'Browse saved memory by inferred type: recipes, films, places, articles, products, videos, notes, and unknown items.'**
  String get categoriesBody;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @orSignInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'or use email'**
  String get orSignInWithEmail;

  /// No description provided for @googleSignInStarted.
  ///
  /// In en, this message translates to:
  /// **'Continue in the Google sign-in window.'**
  String get googleSignInStarted;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start Google sign-in. Try again.'**
  String get googleSignInFailed;

  /// No description provided for @appleSignInStarted.
  ///
  /// In en, this message translates to:
  /// **'Continue in the Apple sign-in window.'**
  String get appleSignInStarted;

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start Apple sign-in. Try again.'**
  String get appleSignInFailed;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteItem;

  /// No description provided for @deleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get deleteItemTitle;

  /// No description provided for @deleteItemBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it from your inbox.'**
  String get deleteItemBody;

  /// No description provided for @deleteItemCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteItemCancel;

  /// No description provided for @deleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteItemConfirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'he',
    'it',
    'ru',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'it':
      return AppLocalizationsIt();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
