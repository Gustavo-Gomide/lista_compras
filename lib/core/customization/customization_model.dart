import 'package:flutter/material.dart';

class CustomizationModel {
  final Color seedColor;
  final String fontFamily;
  final Brightness brightness;
  final String? checkedSvg; // svg customizado para o checkbox marcado
  final String? uncheckedSvg; // svg customizado para o checkbox desmarcado
  final double fontScale; // acessibilidade: 0.85 a 1.6
  final List<String> userCustomCheckedSvgs; // SVGs do usuário (local)
  final List<String> userCustomUncheckedSvgs; // SVGs do usuário (local)

  const CustomizationModel({
    this.seedColor = const Color(0xFF2E7D32),
    this.fontFamily = 'Roboto',
    this.brightness = Brightness.light,
    this.checkedSvg,
    this.uncheckedSvg,
    this.fontScale = 1.0,
    this.userCustomCheckedSvgs = const [],
    this.userCustomUncheckedSvgs = const [],
  });

  CustomizationModel copyWith({
    Color? seedColor,
    String? fontFamily,
    Brightness? brightness,
    String? checkedSvg,
    String? uncheckedSvg,
    double? fontScale,
    bool clearCheckedSvg = false,
    bool clearUncheckedSvg = false,
    List<String>? userCustomCheckedSvgs,
    List<String>? userCustomUncheckedSvgs,
  }) {
    return CustomizationModel(
      seedColor: seedColor ?? this.seedColor,
      fontFamily: fontFamily ?? this.fontFamily,
      brightness: brightness ?? this.brightness,
      checkedSvg: clearCheckedSvg ? null : (checkedSvg ?? this.checkedSvg),
      uncheckedSvg: clearUncheckedSvg ? null : (uncheckedSvg ?? this.uncheckedSvg),
      fontScale: fontScale ?? this.fontScale,
      userCustomCheckedSvgs: userCustomCheckedSvgs ?? this.userCustomCheckedSvgs,
      userCustomUncheckedSvgs: userCustomUncheckedSvgs ?? this.userCustomUncheckedSvgs,
    );
  }

  Map<String, dynamic> toMap() => {
        'seedColor': seedColor.toARGB32(),
        'fontFamily': fontFamily,
        'brightness': brightness == Brightness.dark ? 'dark' : 'light',
        'checkedSvg': checkedSvg,
        'uncheckedSvg': uncheckedSvg,
        'fontScale': fontScale,
        'userCustomCheckedSvgs': userCustomCheckedSvgs,
        'userCustomUncheckedSvgs': userCustomUncheckedSvgs,
      };

  factory CustomizationModel.fromMap(Map<String, dynamic> map) => CustomizationModel(
        seedColor: Color(map['seedColor'] as int? ?? 0xFF2E7D32),
        fontFamily: map['fontFamily'] as String? ?? 'Roboto',
        brightness: (map['brightness'] as String? ?? 'light') == 'dark' ? Brightness.dark : Brightness.light,
        checkedSvg: map['checkedSvg'] as String?,
        uncheckedSvg: map['uncheckedSvg'] as String?,
        fontScale: (map['fontScale'] as num?)?.toDouble() ?? 1.0,
        userCustomCheckedSvgs: (map['userCustomCheckedSvgs'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        userCustomUncheckedSvgs: (map['userCustomUncheckedSvgs'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
}

