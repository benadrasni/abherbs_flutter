// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars

class S {
  S();
  
  static S current;
  
  static const AppLocalizationDelegate delegate =
    AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false) ? locale.languageCode : locale.toString();
    final localeName = Intl.canonicalizedLocale(name); 
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      S.current = S();
      
      return S.current;
    });
  } 

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Legend`
  String get legend {
    return Intl.message(
      'Legend',
      name: 'legend',
      desc: '',
      args: [],
    );
  }

  /// `mature flower`
  String get legend_flower_1 {
    return Intl.message(
      'mature flower',
      name: 'legend_flower_1',
      desc: '',
      args: [],
    );
  }

  /// `stigma`
  String get legend_flower_2 {
    return Intl.message(
      'stigma',
      name: 'legend_flower_2',
      desc: '',
      args: [],
    );
  }

  /// `style`
  String get legend_flower_3 {
    return Intl.message(
      'style',
      name: 'legend_flower_3',
      desc: '',
      args: [],
    );
  }

  /// `filament`
  String get legend_flower_4 {
    return Intl.message(
      'filament',
      name: 'legend_flower_4',
      desc: '',
      args: [],
    );
  }

  /// `floral axis`
  String get legend_flower_5 {
    return Intl.message(
      'floral axis',
      name: 'legend_flower_5',
      desc: '',
      args: [],
    );
  }

  /// `joint`
  String get legend_flower_6 {
    return Intl.message(
      'joint',
      name: 'legend_flower_6',
      desc: '',
      args: [],
    );
  }

  /// `pedicel`
  String get legend_flower_7 {
    return Intl.message(
      'pedicel',
      name: 'legend_flower_7',
      desc: '',
      args: [],
    );
  }

  /// `nectary`
  String get legend_flower_8 {
    return Intl.message(
      'nectary',
      name: 'legend_flower_8',
      desc: '',
      args: [],
    );
  }

  /// `stamen`
  String get legend_flower_9 {
    return Intl.message(
      'stamen',
      name: 'legend_flower_9',
      desc: '',
      args: [],
    );
  }

  /// `pistil`
  String get legend_flower_10 {
    return Intl.message(
      'pistil',
      name: 'legend_flower_10',
      desc: '',
      args: [],
    );
  }

  /// `ovules`
  String get legend_flower_11 {
    return Intl.message(
      'ovules',
      name: 'legend_flower_11',
      desc: '',
      args: [],
    );
  }

  /// `connective`
  String get legend_flower_12 {
    return Intl.message(
      'connective',
      name: 'legend_flower_12',
      desc: '',
      args: [],
    );
  }

  /// `microsporangium`
  String get legend_flower_13 {
    return Intl.message(
      'microsporangium',
      name: 'legend_flower_13',
      desc: '',
      args: [],
    );
  }

  /// `anther`
  String get legend_flower_14 {
    return Intl.message(
      'anther',
      name: 'legend_flower_14',
      desc: '',
      args: [],
    );
  }

  /// `perianth`
  String get legend_flower_15 {
    return Intl.message(
      'perianth',
      name: 'legend_flower_15',
      desc: '',
      args: [],
    );
  }

  /// `petal/corolla`
  String get legend_flower_16 {
    return Intl.message(
      'petal/corolla',
      name: 'legend_flower_16',
      desc: '',
      args: [],
    );
  }

  /// `sepal/calyx`
  String get legend_flower_17 {
    return Intl.message(
      'sepal/calyx',
      name: 'legend_flower_17',
      desc: '',
      args: [],
    );
  }

  /// `Enhancements`
  String get enhancements {
    return Intl.message(
      'Enhancements',
      name: 'enhancements',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Feedback`
  String get feedback {
    return Intl.message(
      'Feedback',
      name: 'feedback',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get about {
    return Intl.message(
      'About',
      name: 'about',
      desc: '',
      args: [],
    );
  }

  /// `Help`
  String get help {
    return Intl.message(
      'Help',
      name: 'help',
      desc: '',
      args: [],
    );
  }

  /// `Restore Purchases`
  String get product_restore_purchases {
    return Intl.message(
      'Restore Purchases',
      name: 'product_restore_purchases',
      desc: '',
      args: [],
    );
  }

  /// `No unwanted advertisement`
  String get product_no_ads_title {
    return Intl.message(
      'No unwanted advertisement',
      name: 'product_no_ads_title',
      desc: '',
      args: [],
    );
  }

  /// `Application won't show advertisement banner at the bottom of the screen.`
  String get product_no_ads_description {
    return Intl.message(
      'Application won\'t show advertisement banner at the bottom of the screen.',
      name: 'product_no_ads_description',
      desc: '',
      args: [],
    );
  }

  /// `Search in names or taxonomy`
  String get product_search_title {
    return Intl.message(
      'Search in names or taxonomy',
      name: 'product_search_title',
      desc: '',
      args: [],
    );
  }

  /// `You'll be able to find a flower by its English or Latin name or by its taxon (e.g. order, family, genus).`
  String get product_search_description {
    return Intl.message(
      'You\'ll be able to find a flower by its English or Latin name or by its taxon (e.g. order, family, genus).',
      name: 'product_search_description',
      desc: '',
      args: [],
    );
  }

  /// `Custom filter`
  String get product_custom_filter_title {
    return Intl.message(
      'Custom filter',
      name: 'product_custom_filter_title',
      desc: '',
      args: [],
    );
  }

  /// `You'll be able to change default order and number of filters (color, habitat, petal, distribution).`
  String get product_custom_filter_description {
    return Intl.message(
      'You\'ll be able to change default order and number of filters (color, habitat, petal, distribution).',
      name: 'product_custom_filter_description',
      desc: '',
      args: [],
    );
  }

  /// `Offline mode`
  String get product_offline_title {
    return Intl.message(
      'Offline mode',
      name: 'product_offline_title',
      desc: '',
      args: [],
    );
  }

  /// `Application will work without internet connection.`
  String get product_offline_description {
    return Intl.message(
      'Application will work without internet connection.',
      name: 'product_offline_description',
      desc: '',
      args: [],
    );
  }

  /// `Observations`
  String get product_observations_title {
    return Intl.message(
      'Observations',
      name: 'product_observations_title',
      desc: '',
      args: [],
    );
  }

  /// `You'll be able to save your observations with flower name, date, location, photos and note.`
  String get product_observations_description {
    return Intl.message(
      'You\'ll be able to save your observations with flower name, date, location, photos and note.',
      name: 'product_observations_description',
      desc: '',
      args: [],
    );
  }

  /// `Search by photo`
  String get product_photo_search_title {
    return Intl.message(
      'Search by photo',
      name: 'product_photo_search_title',
      desc: '',
      args: [],
    );
  }

  /// `You'll be able to find a flower by photo. This feature is using Artificial Intelligence for labeling photos from third party.`
  String get product_photo_search_description {
    return Intl.message(
      'You\'ll be able to find a flower by photo. This feature is using Artificial Intelligence for labeling photos from third party.',
      name: 'product_photo_search_description',
      desc: '',
      args: [],
    );
  }

  /// `Store photos`
  String get subscription_monthly_title {
    return Intl.message(
      'Store photos',
      name: 'subscription_monthly_title',
      desc: '',
      args: [],
    );
  }

  /// `Preserve observation's photos across devices, see shared observations - monthly payment.`
  String get subscription_monthly_description {
    return Intl.message(
      'Preserve observation\'s photos across devices, see shared observations - monthly payment.',
      name: 'subscription_monthly_description',
      desc: '',
      args: [],
    );
  }

  /// `Store photos`
  String get subscription_yearly_title {
    return Intl.message(
      'Store photos',
      name: 'subscription_yearly_title',
      desc: '',
      args: [],
    );
  }

  /// `Preserve observation's photos across devices, see shared observations - yearly payment.`
  String get subscription_yearly_description {
    return Intl.message(
      'Preserve observation\'s photos across devices, see shared observations - yearly payment.',
      name: 'subscription_yearly_description',
      desc: '',
      args: [],
    );
  }

  /// `Subscribe`
  String get product_subscribe {
    return Intl.message(
      'Subscribe',
      name: 'product_subscribe',
      desc: '',
      args: [],
    );
  }

  /// `Subscription failed`
  String get product_subscribe_failed {
    return Intl.message(
      'Subscription failed',
      name: 'product_subscribe_failed',
      desc: '',
      args: [],
    );
  }

  /// `Subscribed`
  String get product_subscribed {
    return Intl.message(
      'Subscribed',
      name: 'product_subscribed',
      desc: '',
      args: [],
    );
  }

  /// `Change`
  String get product_change {
    return Intl.message(
      'Change',
      name: 'product_change',
      desc: '',
      args: [],
    );
  }

  /// `Purchase`
  String get product_purchase {
    return Intl.message(
      'Purchase',
      name: 'product_purchase',
      desc: '',
      args: [],
    );
  }

  /// `Purchase failed`
  String get product_purchase_failed {
    return Intl.message(
      'Purchase failed',
      name: 'product_purchase_failed',
      desc: '',
      args: [],
    );
  }

  /// `Purchased`
  String get product_purchased {
    return Intl.message(
      'Purchased',
      name: 'product_purchased',
      desc: '',
      args: [],
    );
  }

  /// `poisonous plant`
  String get toxicity1 {
    return Intl.message(
      'poisonous plant',
      name: 'toxicity1',
      desc: '',
      args: [],
    );
  }

  /// `slightly poisonous plant`
  String get toxicity2 {
    return Intl.message(
      'slightly poisonous plant',
      name: 'toxicity2',
      desc: '',
      args: [],
    );
  }

  /// `Preferred language`
  String get pref_language {
    return Intl.message(
      'Preferred language',
      name: 'pref_language',
      desc: '',
      args: [],
    );
  }

  /// `My region`
  String get my_region {
    return Intl.message(
      'My region',
      name: 'my_region',
      desc: '',
      args: [],
    );
  }

  /// `Always add my region to the filter`
  String get always_my_region_title {
    return Intl.message(
      'Always add my region to the filter',
      name: 'always_my_region_title',
      desc: '',
      args: [],
    );
  }

  /// `Your region will be pre-set to the filter`
  String get always_my_region_subtitle {
    return Intl.message(
      'Your region will be pre-set to the filter',
      name: 'always_my_region_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `My filter`
  String get my_filter {
    return Intl.message(
      'My filter',
      name: 'my_filter',
      desc: '',
      args: [],
    );
  }

  /// `Offline mode`
  String get offline_title {
    return Intl.message(
      'Offline mode',
      name: 'offline_title',
      desc: '',
      args: [],
    );
  }

  /// `requires 500+ MB additional space.`
  String get offline_subtitle {
    return Intl.message(
      'requires 500+ MB additional space.',
      name: 'offline_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `You're going to download 500+ MB of photos and illustrations. Please check if your device is connected to wi-fi. Are you ready for a download?`
  String get offline_download_message {
    return Intl.message(
      'You\'re going to download 500+ MB of photos and illustrations. Please check if your device is connected to wi-fi. Are you ready for a download?',
      name: 'offline_download_message',
      desc: '',
      args: [],
    );
  }

  /// `Downloading photos and illustrations...`
  String get offline_download_progress {
    return Intl.message(
      'Downloading photos and illustrations...',
      name: 'offline_download_progress',
      desc: '',
      args: [],
    );
  }

  /// `Photos and illustrations have been successfully downloaded.`
  String get offline_download_success {
    return Intl.message(
      'Photos and illustrations have been successfully downloaded.',
      name: 'offline_download_success',
      desc: '',
      args: [],
    );
  }

  /// `Download failed. Please check your internet connection or free space on device and try again.`
  String get offline_download_fail {
    return Intl.message(
      'Download failed. Please check your internet connection or free space on device and try again.',
      name: 'offline_download_fail',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to delete offline data?`
  String get offline_delete_message {
    return Intl.message(
      'Do you want to delete offline data?',
      name: 'offline_delete_message',
      desc: '',
      args: [],
    );
  }

  /// `Resume download`
  String get offline_download {
    return Intl.message(
      'Resume download',
      name: 'offline_download',
      desc: '',
      args: [],
    );
  }

  /// `Scale down observation's photos`
  String get scale_down_photos_title {
    return Intl.message(
      'Scale down observation\'s photos',
      name: 'scale_down_photos_title',
      desc: '',
      args: [],
    );
  }

  /// `Switch on when you don't see your photos after pick.`
  String get scale_down_photos_subtitle {
    return Intl.message(
      'Switch on when you don\'t see your photos after pick.',
      name: 'scale_down_photos_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `You have been contributing to this application since you have installed it on your device, thanks. If you are looking for something more, here are some options:`
  String get feedback_intro {
    return Intl.message(
      'You have been contributing to this application since you have installed it on your device, thanks. If you are looking for something more, here are some options:',
      name: 'feedback_intro',
      desc: '',
      args: [],
    );
  }

  /// `You can write a positive review.`
  String get feedback_review {
    return Intl.message(
      'You can write a positive review.',
      name: 'feedback_review',
      desc: '',
      args: [],
    );
  }

  /// `How to contribute`
  String get feedback_title {
    return Intl.message(
      'How to contribute',
      name: 'feedback_title',
      desc: '',
      args: [],
    );
  }

  /// `You can report any typo or mistranslation you found or submit new translation for flower's data or application's labels at whatsthatflower.com.`
  String get feedback_translate {
    return Intl.message(
      'You can report any typo or mistranslation you found or submit new translation for flower\'s data or application\'s labels at whatsthatflower.com.',
      name: 'feedback_translate',
      desc: '',
      args: [],
    );
  }

  /// `Improve flower's data`
  String get feedback_submit_translate_data {
    return Intl.message(
      'Improve flower\'s data',
      name: 'feedback_submit_translate_data',
      desc: '',
      args: [],
    );
  }

  /// `Improve application's labels`
  String get feedback_submit_translate_app {
    return Intl.message(
      'Improve application\'s labels',
      name: 'feedback_submit_translate_app',
      desc: '',
      args: [],
    );
  }

  /// `You can buy additional functionality like offline mode, search in names or in taxonomy, search by photo, observations and configurable filter.`
  String get feedback_buy_extended {
    return Intl.message(
      'You can buy additional functionality like offline mode, search in names or in taxonomy, search by photo, observations and configurable filter.',
      name: 'feedback_buy_extended',
      desc: '',
      args: [],
    );
  }

  /// `You can display full screen advertisement or watch video advertisement to support further development and database enhancement.`
  String get feedback_run_ads {
    return Intl.message(
      'You can display full screen advertisement or watch video advertisement to support further development and database enhancement.',
      name: 'feedback_run_ads',
      desc: '',
      args: [],
    );
  }

  /// `Show a fullscreen advertisement`
  String get feedback_run_ads_fullscreen {
    return Intl.message(
      'Show a fullscreen advertisement',
      name: 'feedback_run_ads_fullscreen',
      desc: '',
      args: [],
    );
  }

  /// `Watch a video advertisement`
  String get feedback_run_ads_video {
    return Intl.message(
      'Watch a video advertisement',
      name: 'feedback_run_ads_video',
      desc: '',
      args: [],
    );
  }

  /// `Sign in`
  String get auth_sign_in {
    return Intl.message(
      'Sign in',
      name: 'auth_sign_in',
      desc: '',
      args: [],
    );
  }

  /// `Sign out`
  String get auth_sign_out {
    return Intl.message(
      'Sign out',
      name: 'auth_sign_out',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with email`
  String get auth_email {
    return Intl.message(
      'Sign in with email',
      name: 'auth_email',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with phone`
  String get auth_phone {
    return Intl.message(
      'Sign in with phone',
      name: 'auth_phone',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with Google`
  String get auth_google {
    return Intl.message(
      'Sign in with Google',
      name: 'auth_google',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with Apple`
  String get auth_apple {
    return Intl.message(
      'Sign in with Apple',
      name: 'auth_apple',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with Facebook`
  String get auth_facebook {
    return Intl.message(
      'Sign in with Facebook',
      name: 'auth_facebook',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with Twitter`
  String get auth_twitter {
    return Intl.message(
      'Sign in with Twitter',
      name: 'auth_twitter',
      desc: '',
      args: [],
    );
  }

  /// `Sign in failed. Check your connection and try again.`
  String get auth_sign_in_failed {
    return Intl.message(
      'Sign in failed. Check your connection and try again.',
      name: 'auth_sign_in_failed',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get auth_email_hint {
    return Intl.message(
      'Email',
      name: 'auth_email_hint',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid email address`
  String get auth_invalid_email_address {
    return Intl.message(
      'Enter a valid email address',
      name: 'auth_invalid_email_address',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get auth_password_hint {
    return Intl.message(
      'Password',
      name: 'auth_password_hint',
      desc: '',
      args: [],
    );
  }

  /// `Password can't be empty`
  String get auth_empty_password {
    return Intl.message(
      'Password can\'t be empty',
      name: 'auth_empty_password',
      desc: '',
      args: [],
    );
  }

  /// `Reset Password`
  String get auth_reset_password {
    return Intl.message(
      'Reset Password',
      name: 'auth_reset_password',
      desc: '',
      args: [],
    );
  }

  /// `Create an account`
  String get auth_create_account {
    return Intl.message(
      'Create an account',
      name: 'auth_create_account',
      desc: '',
      args: [],
    );
  }

  /// `Have an account? Sign in`
  String get auth_sign_in_text {
    return Intl.message(
      'Have an account? Sign in',
      name: 'auth_sign_in_text',
      desc: '',
      args: [],
    );
  }

  /// `Verify your account`
  String get auth_verify_email_title {
    return Intl.message(
      'Verify your account',
      name: 'auth_verify_email_title',
      desc: '',
      args: [],
    );
  }

  /// `Link to verify account has been sent to your email address.`
  String get auth_verify_email_message {
    return Intl.message(
      'Link to verify account has been sent to your email address.',
      name: 'auth_verify_email_message',
      desc: '',
      args: [],
    );
  }

  /// `Reset password`
  String get auth_reset_password_email_title {
    return Intl.message(
      'Reset password',
      name: 'auth_reset_password_email_title',
      desc: '',
      args: [],
    );
  }

  /// `Follow the instructions sent to {email} to reset your password.`
  String auth_reset_password_email_message(Object email) {
    return Intl.message(
      'Follow the instructions sent to $email to reset your password.',
      name: 'auth_reset_password_email_message',
      desc: '',
      args: [email],
    );
  }

  /// `Resend Email`
  String get auth_resend_email {
    return Intl.message(
      'Resend Email',
      name: 'auth_resend_email',
      desc: '',
      args: [],
    );
  }

  /// `Verify phone number`
  String get auth_verify_phone_number {
    return Intl.message(
      'Verify phone number',
      name: 'auth_verify_phone_number',
      desc: '',
      args: [],
    );
  }

  /// `Enter your phone number`
  String get auth_verify_phone_number_title {
    return Intl.message(
      'Enter your phone number',
      name: 'auth_verify_phone_number_title',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number`
  String get auth_phone_hint {
    return Intl.message(
      'Phone Number',
      name: 'auth_phone_hint',
      desc: '',
      args: [],
    );
  }

  /// `SMS code`
  String get auth_code_hint {
    return Intl.message(
      'SMS code',
      name: 'auth_code_hint',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid phone number`
  String get auth_invalid_phone_number {
    return Intl.message(
      'Enter a valid phone number',
      name: 'auth_invalid_phone_number',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid SMS code`
  String get auth_invalid_code {
    return Intl.message(
      'Enter a valid SMS code',
      name: 'auth_invalid_code',
      desc: '',
      args: [],
    );
  }

  /// `Wrong code. Try again.`
  String get auth_incorrect_code {
    return Intl.message(
      'Wrong code. Try again.',
      name: 'auth_incorrect_code',
      desc: '',
      args: [],
    );
  }

  /// `By tapping "Verify Phone Number", an SMS may be sent. Message & data rates may apply.`
  String get auth_sms_terms_of_service {
    return Intl.message(
      'By tapping "Verify Phone Number", an SMS may be sent. Message & data rates may apply.',
      name: 'auth_sms_terms_of_service',
      desc: '',
      args: [],
    );
  }

  /// `Enter the 6-digit code we sent to `
  String get auth_enter_confirmation_code {
    return Intl.message(
      'Enter the 6-digit code we sent to ',
      name: 'auth_enter_confirmation_code',
      desc: '',
      args: [],
    );
  }

  /// `Resend Code`
  String get auth_resend_code {
    return Intl.message(
      'Resend Code',
      name: 'auth_resend_code',
      desc: '',
      args: [],
    );
  }

  /// `Is this app helpful?`
  String get rate_question {
    return Intl.message(
      'Is this app helpful?',
      name: 'rate_question',
      desc: '',
      args: [],
    );
  }

  /// `Author of this application is fueled by positive response from the users. Please send him some starflowers through application store.`
  String get rate_text {
    return Intl.message(
      'Author of this application is fueled by positive response from the users. Please send him some starflowers through application store.',
      name: 'rate_text',
      desc: '',
      args: [],
    );
  }

  /// `Never`
  String get rate_never {
    return Intl.message(
      'Never',
      name: 'rate_never',
      desc: '',
      args: [],
    );
  }

  /// `Later`
  String get rate_later {
    return Intl.message(
      'Later',
      name: 'rate_later',
      desc: '',
      args: [],
    );
  }

  /// `Review`
  String get rate {
    return Intl.message(
      'Review',
      name: 'rate',
      desc: '',
      args: [],
    );
  }

  /// `New version is available, please update.`
  String get new_version {
    return Intl.message(
      'New version is available, please update.',
      name: 'new_version',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get yes {
    return Intl.message(
      'Yes',
      name: 'yes',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get no {
    return Intl.message(
      'No',
      name: 'no',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get close {
    return Intl.message(
      'Close',
      name: 'close',
      desc: '',
      args: [],
    );
  }

  /// `Pause`
  String get pause {
    return Intl.message(
      'Pause',
      name: 'pause',
      desc: '',
      args: [],
    );
  }

  /// `color`
  String get filter_color {
    return Intl.message(
      'color',
      name: 'filter_color',
      desc: '',
      args: [],
    );
  }

  /// `habitat`
  String get filter_habitat {
    return Intl.message(
      'habitat',
      name: 'filter_habitat',
      desc: '',
      args: [],
    );
  }

  /// `petal`
  String get filter_petal {
    return Intl.message(
      'petal',
      name: 'filter_petal',
      desc: '',
      args: [],
    );
  }

  /// `distribution`
  String get filter_distribution {
    return Intl.message(
      'distribution',
      name: 'filter_distribution',
      desc: '',
      args: [],
    );
  }

  /// `What's the color of the flower? Choose the closest one.`
  String get color_message {
    return Intl.message(
      'What\'s the color of the flower? Choose the closest one.',
      name: 'color_message',
      desc: '',
      args: [],
    );
  }

  /// `What's around you? Identify plant's habitat.`
  String get habitat_message {
    return Intl.message(
      'What\'s around you? Identify plant\'s habitat.',
      name: 'habitat_message',
      desc: '',
      args: [],
    );
  }

  /// `Is the flower zygomorphic? No? Then how many petals does it have?`
  String get petal_message {
    return Intl.message(
      'Is the flower zygomorphic? No? Then how many petals does it have?',
      name: 'petal_message',
      desc: '',
      args: [],
    );
  }

  /// `Which geographic area should we focus on?`
  String get distribution_message {
    return Intl.message(
      'Which geographic area should we focus on?',
      name: 'distribution_message',
      desc: '',
      args: [],
    );
  }

  /// `white`
  String get color_white {
    return Intl.message(
      'white',
      name: 'color_white',
      desc: '',
      args: [],
    );
  }

  /// `yellow`
  String get color_yellow {
    return Intl.message(
      'yellow',
      name: 'color_yellow',
      desc: '',
      args: [],
    );
  }

  /// `red, pink`
  String get color_red {
    return Intl.message(
      'red, pink',
      name: 'color_red',
      desc: '',
      args: [],
    );
  }

  /// `blue, purple`
  String get color_blue {
    return Intl.message(
      'blue, purple',
      name: 'color_blue',
      desc: '',
      args: [],
    );
  }

  /// `green, brown, black`
  String get color_green {
    return Intl.message(
      'green, brown, black',
      name: 'color_green',
      desc: '',
      args: [],
    );
  }

  /// `meadows or grasslands`
  String get habitat_meadow {
    return Intl.message(
      'meadows or grasslands',
      name: 'habitat_meadow',
      desc: '',
      args: [],
    );
  }

  /// `gardens or fields`
  String get habitat_garden {
    return Intl.message(
      'gardens or fields',
      name: 'habitat_garden',
      desc: '',
      args: [],
    );
  }

  /// `moorlands or wetlands`
  String get habitat_wetland {
    return Intl.message(
      'moorlands or wetlands',
      name: 'habitat_wetland',
      desc: '',
      args: [],
    );
  }

  /// `woodlands or forests`
  String get habitat_forest {
    return Intl.message(
      'woodlands or forests',
      name: 'habitat_forest',
      desc: '',
      args: [],
    );
  }

  /// `rocks or mountains`
  String get habitat_rock {
    return Intl.message(
      'rocks or mountains',
      name: 'habitat_rock',
      desc: '',
      args: [],
    );
  }

  /// `trees or shrubs`
  String get habitat_tree {
    return Intl.message(
      'trees or shrubs',
      name: 'habitat_tree',
      desc: '',
      args: [],
    );
  }

  /// `4 or less`
  String get petal_4 {
    return Intl.message(
      '4 or less',
      name: 'petal_4',
      desc: '',
      args: [],
    );
  }

  /// `5`
  String get petal_5 {
    return Intl.message(
      '5',
      name: 'petal_5',
      desc: '',
      args: [],
    );
  }

  /// `more than 5`
  String get petal_many {
    return Intl.message(
      'more than 5',
      name: 'petal_many',
      desc: '',
      args: [],
    );
  }

  /// `zygomorphic`
  String get petal_zygomorphic {
    return Intl.message(
      'zygomorphic',
      name: 'petal_zygomorphic',
      desc: '',
      args: [],
    );
  }

  /// `Europe`
  String get europe {
    return Intl.message(
      'Europe',
      name: 'europe',
      desc: '',
      args: [],
    );
  }

  /// `Africa`
  String get africa {
    return Intl.message(
      'Africa',
      name: 'africa',
      desc: '',
      args: [],
    );
  }

  /// `Asia-Temperate`
  String get asia_temperate {
    return Intl.message(
      'Asia-Temperate',
      name: 'asia_temperate',
      desc: '',
      args: [],
    );
  }

  /// `Asia-Tropical`
  String get asia_tropical {
    return Intl.message(
      'Asia-Tropical',
      name: 'asia_tropical',
      desc: '',
      args: [],
    );
  }

  /// `Australasia`
  String get australasia {
    return Intl.message(
      'Australasia',
      name: 'australasia',
      desc: '',
      args: [],
    );
  }

  /// `Pacific`
  String get pacific {
    return Intl.message(
      'Pacific',
      name: 'pacific',
      desc: '',
      args: [],
    );
  }

  /// `Northern America`
  String get northern_america {
    return Intl.message(
      'Northern America',
      name: 'northern_america',
      desc: '',
      args: [],
    );
  }

  /// `Southern America`
  String get southern_america {
    return Intl.message(
      'Southern America',
      name: 'southern_america',
      desc: '',
      args: [],
    );
  }

  /// `Northern Europe`
  String get northern_europe {
    return Intl.message(
      'Northern Europe',
      name: 'northern_europe',
      desc: '',
      args: [],
    );
  }

  /// `Middle Europe`
  String get middle_europe {
    return Intl.message(
      'Middle Europe',
      name: 'middle_europe',
      desc: '',
      args: [],
    );
  }

  /// `Southwestern Europe`
  String get southwestern_europe {
    return Intl.message(
      'Southwestern Europe',
      name: 'southwestern_europe',
      desc: '',
      args: [],
    );
  }

  /// `Southeastern Europe`
  String get southeastern_europe {
    return Intl.message(
      'Southeastern Europe',
      name: 'southeastern_europe',
      desc: '',
      args: [],
    );
  }

  /// `Eastern Europe`
  String get eastern_europe {
    return Intl.message(
      'Eastern Europe',
      name: 'eastern_europe',
      desc: '',
      args: [],
    );
  }

  /// `Northern Africa`
  String get northern_africa {
    return Intl.message(
      'Northern Africa',
      name: 'northern_africa',
      desc: '',
      args: [],
    );
  }

  /// `Macaronesia`
  String get macaronesia {
    return Intl.message(
      'Macaronesia',
      name: 'macaronesia',
      desc: '',
      args: [],
    );
  }

  /// `West-Central Tropical Africa`
  String get west_central_tropical_africa {
    return Intl.message(
      'West-Central Tropical Africa',
      name: 'west_central_tropical_africa',
      desc: '',
      args: [],
    );
  }

  /// `East Tropical Africa`
  String get east_tropical_africa {
    return Intl.message(
      'East Tropical Africa',
      name: 'east_tropical_africa',
      desc: '',
      args: [],
    );
  }

  /// `West Tropical Africa`
  String get west_tropical_africa {
    return Intl.message(
      'West Tropical Africa',
      name: 'west_tropical_africa',
      desc: '',
      args: [],
    );
  }

  /// `Northeast Tropical Africa`
  String get northeast_tropical_africa {
    return Intl.message(
      'Northeast Tropical Africa',
      name: 'northeast_tropical_africa',
      desc: '',
      args: [],
    );
  }

  /// `South Tropical Africa`
  String get south_tropical_africa {
    return Intl.message(
      'South Tropical Africa',
      name: 'south_tropical_africa',
      desc: '',
      args: [],
    );
  }

  /// `Southern Africa`
  String get southern_africa {
    return Intl.message(
      'Southern Africa',
      name: 'southern_africa',
      desc: '',
      args: [],
    );
  }

  /// `Middle Atlantic Ocean`
  String get middle_atlantic_ocean {
    return Intl.message(
      'Middle Atlantic Ocean',
      name: 'middle_atlantic_ocean',
      desc: '',
      args: [],
    );
  }

  /// `Western Indian Ocean`
  String get western_indian_ocean {
    return Intl.message(
      'Western Indian Ocean',
      name: 'western_indian_ocean',
      desc: '',
      args: [],
    );
  }

  /// `Eastern Asia`
  String get eastern_asia {
    return Intl.message(
      'Eastern Asia',
      name: 'eastern_asia',
      desc: '',
      args: [],
    );
  }

  /// `Mongolia`
  String get mongolia {
    return Intl.message(
      'Mongolia',
      name: 'mongolia',
      desc: '',
      args: [],
    );
  }

  /// `China`
  String get china {
    return Intl.message(
      'China',
      name: 'china',
      desc: '',
      args: [],
    );
  }

  /// `Arabian Peninsula`
  String get arabian_peninsula {
    return Intl.message(
      'Arabian Peninsula',
      name: 'arabian_peninsula',
      desc: '',
      args: [],
    );
  }

  /// `Western Asia`
  String get western_asia {
    return Intl.message(
      'Western Asia',
      name: 'western_asia',
      desc: '',
      args: [],
    );
  }

  /// `Caucasus`
  String get caucasus {
    return Intl.message(
      'Caucasus',
      name: 'caucasus',
      desc: '',
      args: [],
    );
  }

  /// `Middle Asia`
  String get middle_asia {
    return Intl.message(
      'Middle Asia',
      name: 'middle_asia',
      desc: '',
      args: [],
    );
  }

  /// `Russian Far East`
  String get russian_far_east {
    return Intl.message(
      'Russian Far East',
      name: 'russian_far_east',
      desc: '',
      args: [],
    );
  }

  /// `Siberia`
  String get siberia {
    return Intl.message(
      'Siberia',
      name: 'siberia',
      desc: '',
      args: [],
    );
  }

  /// `Indian Subcontinent`
  String get indian_subcontinent {
    return Intl.message(
      'Indian Subcontinent',
      name: 'indian_subcontinent',
      desc: '',
      args: [],
    );
  }

  /// `Indo-China`
  String get indochina {
    return Intl.message(
      'Indo-China',
      name: 'indochina',
      desc: '',
      args: [],
    );
  }

  /// `Malesia`
  String get malesia {
    return Intl.message(
      'Malesia',
      name: 'malesia',
      desc: '',
      args: [],
    );
  }

  /// `Papuasia`
  String get papuasia {
    return Intl.message(
      'Papuasia',
      name: 'papuasia',
      desc: '',
      args: [],
    );
  }

  /// `Australia`
  String get australia {
    return Intl.message(
      'Australia',
      name: 'australia',
      desc: '',
      args: [],
    );
  }

  /// `New Zealand`
  String get new_zealand {
    return Intl.message(
      'New Zealand',
      name: 'new_zealand',
      desc: '',
      args: [],
    );
  }

  /// `Southwestern Pacific`
  String get southwestern_pacific {
    return Intl.message(
      'Southwestern Pacific',
      name: 'southwestern_pacific',
      desc: '',
      args: [],
    );
  }

  /// `South-Central Pacific`
  String get south_central_pacific {
    return Intl.message(
      'South-Central Pacific',
      name: 'south_central_pacific',
      desc: '',
      args: [],
    );
  }

  /// `Northwestern Pacific`
  String get northwestern_pacific {
    return Intl.message(
      'Northwestern Pacific',
      name: 'northwestern_pacific',
      desc: '',
      args: [],
    );
  }

  /// `North-Central Pacific`
  String get north_central_pacific {
    return Intl.message(
      'North-Central Pacific',
      name: 'north_central_pacific',
      desc: '',
      args: [],
    );
  }

  /// `Subarctic America`
  String get subarctic_america {
    return Intl.message(
      'Subarctic America',
      name: 'subarctic_america',
      desc: '',
      args: [],
    );
  }

  /// `Western Canada`
  String get western_canada {
    return Intl.message(
      'Western Canada',
      name: 'western_canada',
      desc: '',
      args: [],
    );
  }

  /// `Northwestern U.S.A.`
  String get northwestern_usa {
    return Intl.message(
      'Northwestern U.S.A.',
      name: 'northwestern_usa',
      desc: '',
      args: [],
    );
  }

  /// `North-Central U.S.A.`
  String get north_central_usa {
    return Intl.message(
      'North-Central U.S.A.',
      name: 'north_central_usa',
      desc: '',
      args: [],
    );
  }

  /// `Northeastern U.S.A.`
  String get northeastern_usa {
    return Intl.message(
      'Northeastern U.S.A.',
      name: 'northeastern_usa',
      desc: '',
      args: [],
    );
  }

  /// `Southwestern U.S.A.`
  String get southwestern_usa {
    return Intl.message(
      'Southwestern U.S.A.',
      name: 'southwestern_usa',
      desc: '',
      args: [],
    );
  }

  /// `South-Central U.S.A.`
  String get south_central_usa {
    return Intl.message(
      'South-Central U.S.A.',
      name: 'south_central_usa',
      desc: '',
      args: [],
    );
  }

  /// `Southeastern U.S.A.`
  String get southeastern_usa {
    return Intl.message(
      'Southeastern U.S.A.',
      name: 'southeastern_usa',
      desc: '',
      args: [],
    );
  }

  /// `Mexico`
  String get mexico {
    return Intl.message(
      'Mexico',
      name: 'mexico',
      desc: '',
      args: [],
    );
  }

  /// `Central America`
  String get central_america {
    return Intl.message(
      'Central America',
      name: 'central_america',
      desc: '',
      args: [],
    );
  }

  /// `Caribbean`
  String get caribbean {
    return Intl.message(
      'Caribbean',
      name: 'caribbean',
      desc: '',
      args: [],
    );
  }

  /// `Northern South America`
  String get northern_south_america {
    return Intl.message(
      'Northern South America',
      name: 'northern_south_america',
      desc: '',
      args: [],
    );
  }

  /// `Western South America`
  String get western_south_america {
    return Intl.message(
      'Western South America',
      name: 'western_south_america',
      desc: '',
      args: [],
    );
  }

  /// `Brazil`
  String get brazil {
    return Intl.message(
      'Brazil',
      name: 'brazil',
      desc: '',
      args: [],
    );
  }

  /// `Southern South America`
  String get southern_south_america {
    return Intl.message(
      'Southern South America',
      name: 'southern_south_america',
      desc: '',
      args: [],
    );
  }

  /// `Eastern Canada`
  String get eastern_canada {
    return Intl.message(
      'Eastern Canada',
      name: 'eastern_canada',
      desc: '',
      args: [],
    );
  }

  /// `Subantarctic Islands`
  String get subantarctic_islands {
    return Intl.message(
      'Subantarctic Islands',
      name: 'subantarctic_islands',
      desc: '',
      args: [],
    );
  }

  /// `Antarctic Continent`
  String get antarctic_continent {
    return Intl.message(
      'Antarctic Continent',
      name: 'antarctic_continent',
      desc: '',
      args: [],
    );
  }

  /// `Pick one`
  String get list_info {
    return Intl.message(
      'Pick one',
      name: 'list_info',
      desc: '',
      args: [],
    );
  }

  /// `Info`
  String get plant_info {
    return Intl.message(
      'Info',
      name: 'plant_info',
      desc: '',
      args: [],
    );
  }

  /// `Gallery`
  String get plant_gallery {
    return Intl.message(
      'Gallery',
      name: 'plant_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Taxonomy`
  String get plant_taxonomy {
    return Intl.message(
      'Taxonomy',
      name: 'plant_taxonomy',
      desc: '',
      args: [],
    );
  }

  /// `Sources`
  String get plant_sources {
    return Intl.message(
      'Sources',
      name: 'plant_sources',
      desc: '',
      args: [],
    );
  }

  /// `Translated with Google Translate`
  String get google_translate {
    return Intl.message(
      'Translated with Google Translate',
      name: 'google_translate',
      desc: '',
      args: [],
    );
  }

  /// `Show English text`
  String get show_original {
    return Intl.message(
      'Show English text',
      name: 'show_original',
      desc: '',
      args: [],
    );
  }

  /// `Improve translation`
  String get improve_translation {
    return Intl.message(
      'Improve translation',
      name: 'improve_translation',
      desc: '',
      args: [],
    );
  }

  /// `Show translated text`
  String get show_translation {
    return Intl.message(
      'Show translated text',
      name: 'show_translation',
      desc: '',
      args: [],
    );
  }

  /// `Height from`
  String get plant_height_from {
    return Intl.message(
      'Height from',
      name: 'plant_height_from',
      desc: '',
      args: [],
    );
  }

  /// `to`
  String get plant_height_to {
    return Intl.message(
      'to',
      name: 'plant_height_to',
      desc: '',
      args: [],
    );
  }

  /// `Flowering from`
  String get plant_flowering_from {
    return Intl.message(
      'Flowering from',
      name: 'plant_flowering_from',
      desc: '',
      args: [],
    );
  }

  /// `to`
  String get plant_flowering_to {
    return Intl.message(
      'to',
      name: 'plant_flowering_to',
      desc: '',
      args: [],
    );
  }

  /// `Flower`
  String get plant_flower {
    return Intl.message(
      'Flower',
      name: 'plant_flower',
      desc: '',
      args: [],
    );
  }

  /// `Inflorescence`
  String get plant_inflorescence {
    return Intl.message(
      'Inflorescence',
      name: 'plant_inflorescence',
      desc: '',
      args: [],
    );
  }

  /// `Fruit`
  String get plant_fruit {
    return Intl.message(
      'Fruit',
      name: 'plant_fruit',
      desc: '',
      args: [],
    );
  }

  /// `Leaf`
  String get plant_leaf {
    return Intl.message(
      'Leaf',
      name: 'plant_leaf',
      desc: '',
      args: [],
    );
  }

  /// `Stem`
  String get plant_stem {
    return Intl.message(
      'Stem',
      name: 'plant_stem',
      desc: '',
      args: [],
    );
  }

  /// `Habitat`
  String get plant_habitat {
    return Intl.message(
      'Habitat',
      name: 'plant_habitat',
      desc: '',
      args: [],
    );
  }

  /// `Trivia`
  String get plant_trivia {
    return Intl.message(
      'Trivia',
      name: 'plant_trivia',
      desc: '',
      args: [],
    );
  }

  /// `Toxicity`
  String get plant_toxicity {
    return Intl.message(
      'Toxicity',
      name: 'plant_toxicity',
      desc: '',
      args: [],
    );
  }

  /// `Herbalism`
  String get plant_herbalism {
    return Intl.message(
      'Herbalism',
      name: 'plant_herbalism',
      desc: '',
      args: [],
    );
  }

  /// `Scientific name`
  String get plant_scientific_label {
    return Intl.message(
      'Scientific name',
      name: 'plant_scientific_label',
      desc: '',
      args: [],
    );
  }

  /// `Synonyms`
  String get plant_synonyms {
    return Intl.message(
      'Synonyms',
      name: 'plant_synonyms',
      desc: '',
      args: [],
    );
  }

  /// `(tap to see all)`
  String get plant_tap_synonyms {
    return Intl.message(
      '(tap to see all)',
      name: 'plant_tap_synonyms',
      desc: '',
      args: [],
    );
  }

  /// `Domain`
  String get taxonomy_superregnum {
    return Intl.message(
      'Domain',
      name: 'taxonomy_superregnum',
      desc: '',
      args: [],
    );
  }

  /// `Kingdom`
  String get taxonomy_regnum {
    return Intl.message(
      'Kingdom',
      name: 'taxonomy_regnum',
      desc: '',
      args: [],
    );
  }

  /// `(clade)`
  String get taxonomy_cladus {
    return Intl.message(
      '(clade)',
      name: 'taxonomy_cladus',
      desc: '',
      args: [],
    );
  }

  /// `Order`
  String get taxonomy_ordo {
    return Intl.message(
      'Order',
      name: 'taxonomy_ordo',
      desc: '',
      args: [],
    );
  }

  /// `Family`
  String get taxonomy_familia {
    return Intl.message(
      'Family',
      name: 'taxonomy_familia',
      desc: '',
      args: [],
    );
  }

  /// `Subfamily`
  String get taxonomy_subfamilia {
    return Intl.message(
      'Subfamily',
      name: 'taxonomy_subfamilia',
      desc: '',
      args: [],
    );
  }

  /// `Tribe`
  String get taxonomy_tribus {
    return Intl.message(
      'Tribe',
      name: 'taxonomy_tribus',
      desc: '',
      args: [],
    );
  }

  /// `Subtribe`
  String get taxonomy_subtribus {
    return Intl.message(
      'Subtribe',
      name: 'taxonomy_subtribus',
      desc: '',
      args: [],
    );
  }

  /// `Genus`
  String get taxonomy_genus {
    return Intl.message(
      'Genus',
      name: 'taxonomy_genus',
      desc: '',
      args: [],
    );
  }

  /// `Subgenus`
  String get taxonomy_subgenus {
    return Intl.message(
      'Subgenus',
      name: 'taxonomy_subgenus',
      desc: '',
      args: [],
    );
  }

  /// `Supersectio`
  String get taxonomy_supersectio {
    return Intl.message(
      'Supersectio',
      name: 'taxonomy_supersectio',
      desc: '',
      args: [],
    );
  }

  /// `Sectio`
  String get taxonomy_sectio {
    return Intl.message(
      'Sectio',
      name: 'taxonomy_sectio',
      desc: '',
      args: [],
    );
  }

  /// `Subsectio`
  String get taxonomy_subsectio {
    return Intl.message(
      'Subsectio',
      name: 'taxonomy_subsectio',
      desc: '',
      args: [],
    );
  }

  /// `Serie`
  String get taxonomy_serie {
    return Intl.message(
      'Serie',
      name: 'taxonomy_serie',
      desc: '',
      args: [],
    );
  }

  /// `Subserie`
  String get taxonomy_subserie {
    return Intl.message(
      'Subserie',
      name: 'taxonomy_subserie',
      desc: '',
      args: [],
    );
  }

  /// `Species`
  String get taxonomy_species {
    return Intl.message(
      'Species',
      name: 'taxonomy_species',
      desc: '',
      args: [],
    );
  }

  /// `unknown`
  String get taxonomy_unknown {
    return Intl.message(
      'unknown',
      name: 'taxonomy_unknown',
      desc: '',
      args: [],
    );
  }

  /// `There are no flowers matching criteria.`
  String get snack_no_flowers {
    return Intl.message(
      'There are no flowers matching criteria.',
      name: 'snack_no_flowers',
      desc: '',
      args: [],
    );
  }

  /// `Ad is still loading, press button again.`
  String get snack_loading_ad {
    return Intl.message(
      'Ad is still loading, press button again.',
      name: 'snack_loading_ad',
      desc: '',
      args: [],
    );
  }

  /// `Copied to Clipboard`
  String get snack_copy {
    return Intl.message(
      'Copied to Clipboard',
      name: 'snack_copy',
      desc: '',
      args: [],
    );
  }

  /// `... to be published later`
  String get snack_publish {
    return Intl.message(
      '... to be published later',
      name: 'snack_publish',
      desc: '',
      args: [],
    );
  }

  /// `Thanks for your contribution. It'll be published soon.`
  String get snack_translation {
    return Intl.message(
      'Thanks for your contribution. It\'ll be published soon.',
      name: 'snack_translation',
      desc: '',
      args: [],
    );
  }

  /// `Search...`
  String get search {
    return Intl.message(
      'Search...',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  /// `Search in names`
  String get search_names {
    return Intl.message(
      'Search in names',
      name: 'search_names',
      desc: '',
      args: [],
    );
  }

  /// `Search in taxonomy`
  String get search_taxonomy {
    return Intl.message(
      'Search in taxonomy',
      name: 'search_taxonomy',
      desc: '',
      args: [],
    );
  }

  /// `Observation`
  String get observation {
    return Intl.message(
      'Observation',
      name: 'observation',
      desc: '',
      args: [],
    );
  }

  /// `Observations`
  String get observations {
    return Intl.message(
      'Observations',
      name: 'observations',
      desc: '',
      args: [],
    );
  }

  /// `Place for your private note.`
  String get observation_note {
    return Intl.message(
      'Place for your private note.',
      name: 'observation_note',
      desc: '',
      args: [],
    );
  }

  /// `Observation was saved.`
  String get observation_saved {
    return Intl.message(
      'Observation was saved.',
      name: 'observation_saved',
      desc: '',
      args: [],
    );
  }

  /// `Observation was incomplete thus it wasn't saved. Photo is missing.`
  String get observation_missing_photo {
    return Intl.message(
      'Observation was incomplete thus it wasn\'t saved. Photo is missing.',
      name: 'observation_missing_photo',
      desc: '',
      args: [],
    );
  }

  /// `Observation was incomplete thus it wasn't saved. Location is missing.`
  String get observation_missing_location {
    return Intl.message(
      'Observation was incomplete thus it wasn\'t saved. Location is missing.',
      name: 'observation_missing_location',
      desc: '',
      args: [],
    );
  }

  /// `Delete observation`
  String get observation_delete {
    return Intl.message(
      'Delete observation',
      name: 'observation_delete',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to delete the observation?`
  String get observation_delete_question {
    return Intl.message(
      'Do you want to delete the observation?',
      name: 'observation_delete_question',
      desc: '',
      args: [],
    );
  }

  /// `There is no observation yet.`
  String get observation_empty {
    return Intl.message(
      'There is no observation yet.',
      name: 'observation_empty',
      desc: '',
      args: [],
    );
  }

  /// `Observations are available only for logged users. Please log in.`
  String get observation_no_login {
    return Intl.message(
      'Observations are available only for logged users. Please log in.',
      name: 'observation_no_login',
      desc: '',
      args: [],
    );
  }

  /// `Remove photo`
  String get observation_photo_delete {
    return Intl.message(
      'Remove photo',
      name: 'observation_photo_delete',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to remove photo from the observation?`
  String get observation_photo_delete_question {
    return Intl.message(
      'Do you want to remove photo from the observation?',
      name: 'observation_photo_delete_question',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate photo. Skipped.`
  String get observation_photo_duplicate {
    return Intl.message(
      'Duplicate photo. Skipped.',
      name: 'observation_photo_duplicate',
      desc: '',
      args: [],
    );
  }

  /// `Upload observations`
  String get observation_upload_title {
    return Intl.message(
      'Upload observations',
      name: 'observation_upload_title',
      desc: '',
      args: [],
    );
  }

  /// `You're going to upload {param} observations. Please check if your device is connected to wi-fi. Are you ready for an upload?`
  String observation_upload_message(Object param) {
    return Intl.message(
      'You\'re going to upload $param observations. Please check if your device is connected to wi-fi. Are you ready for an upload?',
      name: 'observation_upload_message',
      desc: '',
      args: [param],
    );
  }

  /// `Uploading observations...`
  String get observation_upload_progress {
    return Intl.message(
      'Uploading observations...',
      name: 'observation_upload_progress',
      desc: '',
      args: [],
    );
  }

  /// `Observations have been successfully uploaded.`
  String get observation_upload_success {
    return Intl.message(
      'Observations have been successfully uploaded.',
      name: 'observation_upload_success',
      desc: '',
      args: [],
    );
  }

  /// `Upload failed. Please check your internet connection and try again.`
  String get observation_upload_fail {
    return Intl.message(
      'Upload failed. Please check your internet connection and try again.',
      name: 'observation_upload_fail',
      desc: '',
      args: [],
    );
  }

  /// `Uploads`
  String get observation_logs {
    return Intl.message(
      'Uploads',
      name: 'observation_logs',
      desc: '',
      args: [],
    );
  }

  /// `Subscription`
  String get subscription {
    return Intl.message(
      'Subscription',
      name: 'subscription',
      desc: '',
      args: [],
    );
  }

  /// `Shared observations are visible only for subscribed users.`
  String get subscription_info {
    return Intl.message(
      'Shared observations are visible only for subscribed users.',
      name: 'subscription_info',
      desc: '',
      args: [],
    );
  }

  /// `Your observation's date, location and note are saved and persisted across devices without subscription, but photos are stored only locally on the device. You will lose connection to them (even photo itself when you shot it from the application) when you clear data, reinstall or switch device.`
  String get subscription_intro1 {
    return Intl.message(
      'Your observation\'s date, location and note are saved and persisted across devices without subscription, but photos are stored only locally on the device. You will lose connection to them (even photo itself when you shot it from the application) when you clear data, reinstall or switch device.',
      name: 'subscription_intro1',
      desc: '',
      args: [],
    );
  }

  /// `You are about to subscribe for saving and persisting your photos across all your devices. With subscription you agree to share your observations with other subscribed users. You'll also be able to see their observations. All shared observations are anonymous and its note stays private and won't be shared. To simplify process your photos will be shared under CC0 (Creative Commons Zero) licence, so you also agree with this.`
  String get subscription_intro2 {
    return Intl.message(
      'You are about to subscribe for saving and persisting your photos across all your devices. With subscription you agree to share your observations with other subscribed users. You\'ll also be able to see their observations. All shared observations are anonymous and its note stays private and won\'t be shared. To simplify process your photos will be shared under CC0 (Creative Commons Zero) licence, so you also agree with this.',
      name: 'subscription_intro2',
      desc: '',
      args: [],
    );
  }

  /// `If you still hesitate to hit the button below, there is a 30 days trial period for both subscriptions.`
  String get subscription_intro3 {
    return Intl.message(
      'If you still hesitate to hit the button below, there is a 30 days trial period for both subscriptions.',
      name: 'subscription_intro3',
      desc: '',
      args: [],
    );
  }

  /// `month`
  String get subscription_period_month {
    return Intl.message(
      'month',
      name: 'subscription_period_month',
      desc: '',
      args: [],
    );
  }

  /// `year`
  String get subscription_period_year {
    return Intl.message(
      'year',
      name: 'subscription_period_year',
      desc: '',
      args: [],
    );
  }

  /// `First payment will be charged to your Google Play account 30 days after the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings on the Google Play Store after purchase.`
  String get subscription_disclaimer_android {
    return Intl.message(
      'First payment will be charged to your Google Play account 30 days after the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings on the Google Play Store after purchase.',
      name: 'subscription_disclaimer_android',
      desc: '',
      args: [],
    );
  }

  /// `Payment will be charged to your Apple ID account after the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.`
  String get subscription_disclaimer_ios {
    return Intl.message(
      'Payment will be charged to your Apple ID account after the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.',
      name: 'subscription_disclaimer_ios',
      desc: '',
      args: [],
    );
  }

  /// `Terms of use`
  String get terms_of_use {
    return Intl.message(
      'Terms of use',
      name: 'terms_of_use',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacy_policy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacy_policy',
      desc: '',
      args: [],
    );
  }

  /// `Apple`
  String get apple {
    return Intl.message(
      'Apple',
      name: 'apple',
      desc: '',
      args: [],
    );
  }

  /// `Google`
  String get google {
    return Intl.message(
      'Google',
      name: 'google',
      desc: '',
      args: [],
    );
  }

  /// `App Store`
  String get app_store {
    return Intl.message(
      'App Store',
      name: 'app_store',
      desc: '',
      args: [],
    );
  }

  /// `Google Play Store`
  String get play_store {
    return Intl.message(
      'Google Play Store',
      name: 'play_store',
      desc: '',
      args: [],
    );
  }

  /// `Paid feature`
  String get promotion_title {
    return Intl.message(
      'Paid feature',
      name: 'promotion_title',
      desc: '',
      args: [],
    );
  }

  /// `This is a paid feature. You can use it for free until {date}`
  String promotion_content(Object date) {
    return Intl.message(
      'This is a paid feature. You can use it for free until $date',
      name: 'promotion_content',
      desc: '',
      args: [date],
    );
  }

  /// `Connection`
  String get no_connection_title {
    return Intl.message(
      'Connection',
      name: 'no_connection_title',
      desc: '',
      args: [],
    );
  }

  /// `This feature doesn't work without Internet connection.`
  String get no_connection_content {
    return Intl.message(
      'This feature doesn\'t work without Internet connection.',
      name: 'no_connection_content',
      desc: '',
      args: [],
    );
  }

  /// `Search by photo is available only for logged users. Please log in.`
  String get photo_search_no_login {
    return Intl.message(
      'Search by photo is available only for logged users. Please log in.',
      name: 'photo_search_no_login',
      desc: '',
      args: [],
    );
  }

  /// `Search by photo failed. Check your internet connection and try again.`
  String get photo_search_failed {
    return Intl.message(
      'Search by photo failed. Check your internet connection and try again.',
      name: 'photo_search_failed',
      desc: '',
      args: [],
    );
  }

  /// `Photo to search by`
  String get photo_to_search_by {
    return Intl.message(
      'Photo to search by',
      name: 'photo_to_search_by',
      desc: '',
      args: [],
    );
  }

  /// `This is feature works only online. Sometimes it finds exactly what you're looking for, sometimes not even close. I'm totally relying on third party here since they're doing all the hard work. As time goes it should be better and better. Use it wisely and please don't judge the whole application based on this feature. For quality purposes all search results (not photos) will be saved.`
  String get photo_search_note {
    return Intl.message(
      'This is feature works only online. Sometimes it finds exactly what you\'re looking for, sometimes not even close. I\'m totally relying on third party here since they\'re doing all the hard work. As time goes it should be better and better. Use it wisely and please don\'t judge the whole application based on this feature. For quality purposes all search results (not photos) will be saved.',
      name: 'photo_search_note',
      desc: '',
      args: [],
    );
  }

  /// `AI (artificial intelligence) didn't recognize any particular flower on the picture. Try again with different angle, distance or light conditions. If you already did it looks like AI overlord won't come anytime soon.`
  String get photo_search_empty {
    return Intl.message(
      'AI (artificial intelligence) didn\'t recognize any particular flower on the picture. Try again with different angle, distance or light conditions. If you already did it looks like AI overlord won\'t come anytime soon.',
      name: 'photo_search_empty',
      desc: '',
      args: [],
    );
  }

  /// `Notification`
  String get notification {
    return Intl.message(
      'Notification',
      name: 'notification',
      desc: '',
      args: [],
    );
  }

  /// `Open`
  String get notification_open {
    return Intl.message(
      'Open',
      name: 'notification_open',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get notification_close {
    return Intl.message(
      'Close',
      name: 'notification_close',
      desc: '',
      args: [],
    );
  }

  /// `Lists of flowers`
  String get custom_lists {
    return Intl.message(
      'Lists of flowers',
      name: 'custom_lists',
      desc: '',
      args: [],
    );
  }

  /// `New flowers`
  String get new_flowers {
    return Intl.message(
      'New flowers',
      name: 'new_flowers',
      desc: '',
      args: [],
    );
  }

  /// `Common lists`
  String get common_lists {
    return Intl.message(
      'Common lists',
      name: 'common_lists',
      desc: '',
      args: [],
    );
  }

  /// `My lists`
  String get my_lists {
    return Intl.message(
      'My lists',
      name: 'my_lists',
      desc: '',
      args: [],
    );
  }

  /// `Favorite flowers`
  String get favorite_title {
    return Intl.message(
      'Favorite flowers',
      name: 'favorite_title',
      desc: '',
      args: [],
    );
  }

  /// `There is no favorite flowers yet.`
  String get favorite_empty {
    return Intl.message(
      'There is no favorite flowers yet.',
      name: 'favorite_empty',
      desc: '',
      args: [],
    );
  }

  /// `List of favorite flowers is available only for logged users. Please log in.`
  String get favorite_no_login {
    return Intl.message(
      'List of favorite flowers is available only for logged users. Please log in.',
      name: 'favorite_no_login',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar', countryCode: 'EG'),
      Locale.fromSubtags(languageCode: 'bg', countryCode: 'BG'),
      Locale.fromSubtags(languageCode: 'cs', countryCode: 'CZ'),
      Locale.fromSubtags(languageCode: 'da', countryCode: 'DK'),
      Locale.fromSubtags(languageCode: 'de', countryCode: 'DE'),
      Locale.fromSubtags(languageCode: 'en', countryCode: 'UK'),
      Locale.fromSubtags(languageCode: 'en', countryCode: 'US'),
      Locale.fromSubtags(languageCode: 'es', countryCode: 'ES'),
      Locale.fromSubtags(languageCode: 'et', countryCode: 'EE'),
      Locale.fromSubtags(languageCode: 'fa', countryCode: 'IR'),
      Locale.fromSubtags(languageCode: 'fi', countryCode: 'FI'),
      Locale.fromSubtags(languageCode: 'fr', countryCode: 'FR'),
      Locale.fromSubtags(languageCode: 'he', countryCode: 'IL'),
      Locale.fromSubtags(languageCode: 'hi', countryCode: 'IN'),
      Locale.fromSubtags(languageCode: 'hr', countryCode: 'HR'),
      Locale.fromSubtags(languageCode: 'hu', countryCode: 'HU'),
      Locale.fromSubtags(languageCode: 'id', countryCode: 'ID'),
      Locale.fromSubtags(languageCode: 'it', countryCode: 'IT'),
      Locale.fromSubtags(languageCode: 'ja', countryCode: 'JP'),
      Locale.fromSubtags(languageCode: 'ko', countryCode: 'KR'),
      Locale.fromSubtags(languageCode: 'lt', countryCode: 'LT'),
      Locale.fromSubtags(languageCode: 'lv', countryCode: 'LV'),
      Locale.fromSubtags(languageCode: 'nb', countryCode: 'NO'),
      Locale.fromSubtags(languageCode: 'nl', countryCode: 'NL'),
      Locale.fromSubtags(languageCode: 'pl', countryCode: 'PL'),
      Locale.fromSubtags(languageCode: 'pt', countryCode: 'PT'),
      Locale.fromSubtags(languageCode: 'ro', countryCode: 'RO'),
      Locale.fromSubtags(languageCode: 'ru', countryCode: 'RU'),
      Locale.fromSubtags(languageCode: 'sk', countryCode: 'SK'),
      Locale.fromSubtags(languageCode: 'sl', countryCode: 'SI'),
      Locale.fromSubtags(languageCode: 'sr', countryCode: 'RS'),
      Locale.fromSubtags(languageCode: 'sv', countryCode: 'SE'),
      Locale.fromSubtags(languageCode: 'uk', countryCode: 'UA'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    if (locale != null) {
      for (var supportedLocale in supportedLocales) {
        if (supportedLocale.languageCode == locale.languageCode) {
          return true;
        }
      }
    }
    return false;
  }
}