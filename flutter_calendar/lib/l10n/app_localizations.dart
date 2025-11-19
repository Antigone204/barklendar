import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearanceSettings.
  ///
  /// In en, this message translates to:
  /// **'Appearance Settings'**
  String get appearanceSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @aiSettings.
  ///
  /// In en, this message translates to:
  /// **'AI Settings'**
  String get aiSettings;

  /// No description provided for @aiConfiguration.
  ///
  /// In en, this message translates to:
  /// **'AI Configuration'**
  String get aiConfiguration;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get themeColor;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @taskReminders.
  ///
  /// In en, this message translates to:
  /// **'Task Reminders'**
  String get taskReminders;

  /// No description provided for @dailyDigest.
  ///
  /// In en, this message translates to:
  /// **'Daily Digest'**
  String get dailyDigest;

  /// No description provided for @aiSmartSuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI Smart Suggestions'**
  String get aiSmartSuggestions;

  /// No description provided for @taskOptimization.
  ///
  /// In en, this message translates to:
  /// **'Task Optimization'**
  String get taskOptimization;

  /// No description provided for @timePlanning.
  ///
  /// In en, this message translates to:
  /// **'Time Planning'**
  String get timePlanning;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup Data'**
  String get backupData;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'Restore Data'**
  String get restoreData;

  /// No description provided for @clearData.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get clearData;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @aiSettingsManagement.
  ///
  /// In en, this message translates to:
  /// **'AI Settings Management'**
  String get aiSettingsManagement;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @mainFeatures.
  ///
  /// In en, this message translates to:
  /// **'Main Features'**
  String get mainFeatures;

  /// No description provided for @aiTaskSuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI Task Suggestions'**
  String get aiTaskSuggestions;

  /// No description provided for @multiViewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Multi-view Calendar'**
  String get multiViewCalendar;

  /// No description provided for @smartReminders.
  ///
  /// In en, this message translates to:
  /// **'Smart Reminders'**
  String get smartReminders;

  /// No description provided for @dataSync.
  ///
  /// In en, this message translates to:
  /// **'Data Sync'**
  String get dataSync;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectThemeColor.
  ///
  /// In en, this message translates to:
  /// **'Select Theme Color'**
  String get selectThemeColor;

  /// No description provided for @clearDataConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all data? This action cannot be undone.'**
  String get clearDataConfirmation;

  /// No description provided for @dataCleared.
  ///
  /// In en, this message translates to:
  /// **'Data cleared'**
  String get dataCleared;

  /// No description provided for @themeColorUpdated.
  ///
  /// In en, this message translates to:
  /// **'Theme color updated'**
  String get themeColorUpdated;

  /// No description provided for @backupInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Backup feature is under development...'**
  String get backupInDevelopment;

  /// No description provided for @restoreInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Restore feature is under development...'**
  String get restoreInDevelopment;

  /// No description provided for @helpInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Help center is under development...'**
  String get helpInDevelopment;

  /// No description provided for @feedbackInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Feedback feature is under development...'**
  String get feedbackInDevelopment;

  /// No description provided for @rateInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Rating feature is under development...'**
  String get rateInDevelopment;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// No description provided for @green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get green;

  /// No description provided for @orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get orange;

  /// No description provided for @purple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get purple;

  /// No description provided for @pink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get pink;

  /// No description provided for @blueAccent.
  ///
  /// In en, this message translates to:
  /// **'Blue Accent'**
  String get blueAccent;

  /// No description provided for @cyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get cyan;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @customColor.
  ///
  /// In en, this message translates to:
  /// **'Custom Color'**
  String get customColor;

  /// No description provided for @saveNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Save notification settings'**
  String get saveNotificationSettings;

  /// No description provided for @saveTaskReminderSettings.
  ///
  /// In en, this message translates to:
  /// **'Save task reminder settings'**
  String get saveTaskReminderSettings;

  /// No description provided for @saveDailyDigestSettings.
  ///
  /// In en, this message translates to:
  /// **'Save daily digest settings'**
  String get saveDailyDigestSettings;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @learning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learning;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @appFailedToStart.
  ///
  /// In en, this message translates to:
  /// **'App failed to start'**
  String get appFailedToStart;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'minutes ago'**
  String get minutesAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hoursAgo;

  /// No description provided for @loadingTasksFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading tasks failed'**
  String get loadingTasksFailed;

  /// No description provided for @noTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks today'**
  String get noTasksToday;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @loadingFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading failed'**
  String get loadingFailed;

  /// No description provided for @todaysTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get todaysTasks;

  /// No description provided for @noTasksRest.
  ///
  /// In en, this message translates to:
  /// **'No tasks today, have a good rest!'**
  String get noTasksRest;

  /// No description provided for @pendingTasks.
  ///
  /// In en, this message translates to:
  /// **'Pending Tasks'**
  String get pendingTasks;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed Tasks'**
  String get completedTasks;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitle;

  /// No description provided for @pleaseEnterTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter task title'**
  String get pleaseEnterTaskTitle;

  /// No description provided for @taskDescription.
  ///
  /// In en, this message translates to:
  /// **'Task Description'**
  String get taskDescription;

  /// No description provided for @dueDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Due Date and Time'**
  String get dueDateAndTime;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @enterTags.
  ///
  /// In en, this message translates to:
  /// **'Enter tags and press Enter to add'**
  String get enterTags;

  /// No description provided for @enterTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tags and press Enter to add'**
  String get enterTagsHint;

  /// No description provided for @onTimeReminder.
  ///
  /// In en, this message translates to:
  /// **'On time reminder'**
  String get onTimeReminder;

  /// No description provided for @minutesEarly.
  ///
  /// In en, this message translates to:
  /// **'minutes early'**
  String get minutesEarly;

  /// No description provided for @hoursEarly.
  ///
  /// In en, this message translates to:
  /// **'hours early'**
  String get hoursEarly;

  /// No description provided for @daysEarly.
  ///
  /// In en, this message translates to:
  /// **'days early'**
  String get daysEarly;

  /// No description provided for @enableTaskReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable task reminders'**
  String get enableTaskReminders;

  /// No description provided for @earlyTime.
  ///
  /// In en, this message translates to:
  /// **'Early time'**
  String get earlyTime;

  /// No description provided for @getAISuggestions.
  ///
  /// In en, this message translates to:
  /// **'Get AI suggestions'**
  String get getAISuggestions;

  /// No description provided for @pleaseFillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill required fields'**
  String get pleaseFillRequiredFields;

  /// No description provided for @pleaseSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Please select date'**
  String get pleaseSelectDate;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm delete'**
  String get confirmDelete;

  /// No description provided for @deleteTaskConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this task? This action cannot be undone.'**
  String get deleteTaskConfirmation;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @aiSuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI Suggestions'**
  String get aiSuggestions;

  /// No description provided for @aiSuggestionsInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'AI suggestions feature is under development...'**
  String get aiSuggestionsInDevelopment;

  /// No description provided for @taskReminder.
  ///
  /// In en, this message translates to:
  /// **'Task Reminder'**
  String get taskReminder;

  /// No description provided for @taskDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Task due soon'**
  String get taskDueSoon;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get taskCompleted;

  /// No description provided for @dailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get dailySummary;

  /// No description provided for @aiSmartAdvice.
  ///
  /// In en, this message translates to:
  /// **'AI Smart Advice'**
  String get aiSmartAdvice;

  /// No description provided for @clearNotificationBadge.
  ///
  /// In en, this message translates to:
  /// **'Clear notification badge'**
  String get clearNotificationBadge;

  /// No description provided for @aiServiceNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI service not configured'**
  String get aiServiceNotConfigured;

  /// No description provided for @aiRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'AI request failed'**
  String get aiRequestFailed;

  /// No description provided for @apiEndpointNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'API endpoint not configured'**
  String get apiEndpointNotConfigured;

  /// No description provided for @apiKeyNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'API key not configured'**
  String get apiKeyNotConfigured;

  /// No description provided for @connectionTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection test failed'**
  String get connectionTestFailed;

  /// No description provided for @taskCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'Task creation failed'**
  String get taskCreationFailed;

  /// No description provided for @taskCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task created successfully'**
  String get taskCreatedSuccessfully;

  /// No description provided for @taskUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task updated successfully'**
  String get taskUpdatedSuccessfully;

  /// No description provided for @taskDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task deleted successfully'**
  String get taskDeletedSuccessfully;

  /// No description provided for @taskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found'**
  String get taskNotFound;

  /// No description provided for @taskMarkedAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task marked as completed'**
  String get taskMarkedAsCompleted;

  /// No description provided for @taskMarkedAsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Task marked as incomplete'**
  String get taskMarkedAsIncomplete;

  /// No description provided for @updateTaskStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Update task status failed'**
  String get updateTaskStatusFailed;

  /// No description provided for @aiSmartCalendar.
  ///
  /// In en, this message translates to:
  /// **'AI Smart Calendar'**
  String get aiSmartCalendar;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
