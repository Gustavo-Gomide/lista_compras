import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'customization_model.dart';

/// Guarda as preferências de aparência (cor, fonte, svg do checkbox) APENAS
/// no dispositivo do usuário (shared_preferences). Nunca é enviado ao Supabase.
class CustomizationProvider extends ChangeNotifier {
  static const _prefsKey = 'customization_settings_v1';

  CustomizationModel _model = const CustomizationModel();
  CustomizationModel get model => _model;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        _model = CustomizationModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // ignora preferências corrompidas e usa o padrão
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_model.toMap()));
  }

  Future<void> updateSeedColor(Color color) async {
    _model = _model.copyWith(seedColor: color);
    notifyListeners();
    await _persist();
  }

  Future<void> updateFontFamily(String font) async {
    _model = _model.copyWith(fontFamily: font);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleBrightness() async {
    _model = _model.copyWith(
      brightness: _model.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> updateFontScale(double scale) async {
    _model = _model.copyWith(fontScale: scale);
    notifyListeners();
    await _persist();
  }

  Future<void> updateCheckedSvg(String? svg) async {
    _model = _model.copyWith(checkedSvg: svg, clearCheckedSvg: svg == null);
    notifyListeners();
    await _persist();
  }

  Future<void> updateUncheckedSvg(String? svg) async {
    _model = _model.copyWith(uncheckedSvg: svg, clearUncheckedSvg: svg == null);
    notifyListeners();
    await _persist();
  }

  Future<void> addCustomSvg(String svg, {required bool checked}) async {
    if (checked) {
      final list = List<String>.from(_model.userCustomCheckedSvgs)..add(svg);
      _model = _model.copyWith(userCustomCheckedSvgs: list);
    } else {
      final list = List<String>.from(_model.userCustomUncheckedSvgs)..add(svg);
      _model = _model.copyWith(userCustomUncheckedSvgs: list);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> removeCustomSvg(int index, {required bool checked}) async {
    if (checked) {
      final list = List<String>.from(_model.userCustomCheckedSvgs)..removeAt(index);
      _model = _model.copyWith(userCustomCheckedSvgs: list);
    } else {
      final list = List<String>.from(_model.userCustomUncheckedSvgs)..removeAt(index);
      _model = _model.copyWith(userCustomUncheckedSvgs: list);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> reset() async {
    _model = const CustomizationModel();
    notifyListeners();
    await _persist();
  }
}
