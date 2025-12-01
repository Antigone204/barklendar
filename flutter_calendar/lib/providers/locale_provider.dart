import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final StateNotifierProvider<LocaleNotifier, Locale> localeNotifierProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((StateNotifierProviderRef<LocaleNotifier, Locale> ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('zh', 'CN'));

  void setLocale(Locale locale) {
    state = locale;
  }
}
