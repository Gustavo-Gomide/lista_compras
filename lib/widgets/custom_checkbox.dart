import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Checkbox customizável: usa SVGs definidos pelo usuário quando disponíveis,
/// caindo para o Checkbox padrão do Material caso não haja customização.
class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? checkedSvg;
  final String? uncheckedSvg;
  final double size;
  final String? semanticLabel;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.checkedSvg,
    this.uncheckedSvg,
    this.size = 28,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasCustomChecked = checkedSvg != null && checkedSvg!.trim().isNotEmpty;
    final hasCustomUnchecked = uncheckedSvg != null && uncheckedSvg!.trim().isNotEmpty;

    final usingCustom = (value && hasCustomChecked) || (!value && hasCustomUnchecked);

    final label = semanticLabel == null
        ? (value ? 'Marcado' : 'Não marcado')
        : '${value ? 'Marcado' : 'Não marcado'}: $semanticLabel';

    // Escala o tamanho do checkbox proporcionalmente à escala de texto
    final scaler = MediaQuery.textScalerOf(context);
    final scaledSize = scaler.scale(size);

    if (!usingCustom) {
      return Semantics(
        label: label,
        checked: value,
        child: Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
      );
    }

    final svg = value ? checkedSvg! : uncheckedSvg!;
    return Semantics(
      button: true,
      checked: value,
      label: label,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: scaledSize,
          height: scaledSize,
          child: SvgPicture.string(svg, width: scaledSize, height: scaledSize),
        ),
      ),
    );
  }
}
