import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Só dígitos.
class DigitsOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final onlyDigits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    return newValue.copyWith(
      text: onlyDigits,
      selection: TextSelection.collapsed(offset: onlyDigits.length),
    );
  }
}

/// Máscara genérica tipo "000.000.000-00".
/// Usa 0/9/# como placeholder de dígito, o resto é literal.
class PatternMaskFormatter extends TextInputFormatter {
  final String pattern;
  final RegExp allowedCharMatcher;

  PatternMaskFormatter({
    required this.pattern,
    RegExp? allowedCharMatcher,
  }) : allowedCharMatcher = allowedCharMatcher ?? RegExp(r'[0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // pega só os caracteres aceitos
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    int rawIndex = 0;

    for (int i = 0; i < pattern.length && rawIndex < raw.length; i++) {
      final pChar = pattern[i];

      if (pChar == '0' || pChar == '9' || pChar == '#') {
        final nextDigit = raw[rawIndex];
        if (!allowedCharMatcher.hasMatch(nextDigit)) break;
        buffer.write(nextDigit);
        rawIndex++;
      } else {
        buffer.write(pChar);
      }
    }

    final masked = buffer.toString();
    return newValue.copyWith(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }
}

/// hh:mm
class HoraFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);

    String out = '';
    for (int i = 0; i < digits.length; i++) {
      out += digits[i];
      if (i == 1 && i != digits.length - 1) {
        out += ':';
      }
    }

    return newValue.copyWith(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

/// dd/mm/yyyy
class DataFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    String out = '';
    for (int i = 0; i < digits.length; i++) {
      out += digits[i];
      if ((i == 1 || i == 3) && i != digits.length - 1) {
        out += '/';
      }
    }

    return newValue.copyWith(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

/// ***-**** (3 letras + hífen + 4 dígitos)
class PlacaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
    final raw = newValue.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');

    String letras = '';
    String numeros = '';

    int i = 0;
    while (i < raw.length && letras.length < 3) {
      final ch = raw[i];
      if (RegExp(r'[A-Z]').hasMatch(ch)) {
        letras += ch;
      }
      i++;
    }
    while (i < raw.length && numeros.length < 4) {
      final ch = raw[i];
      if (RegExp(r'[0-9]').hasMatch(ch)) {
        numeros += ch;
      }
      i++;
    }

    String out = letras;
    if (letras.isNotEmpty && (letras.length == 3 || numeros.isNotEmpty)) {
      out += '-';
    }
    out += numeros;

    return newValue.copyWith(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

/// decide formatters pra máscara
List<TextInputFormatter> buildFormattersForMask(String? mascara) {
  if (mascara == null) return const [];

  final m = mascara.toLowerCase();

  if (m == 'hh:mm') {
    return [HoraFormatter()];
  }
  if (m == 'dd/mm/yyyy') {
    return [DataFormatter()];
  }
  if (m == '***-****') {
    return [PlacaFormatter()];
  }
  if (m == '0') {
    return [DigitsOnlyFormatter()];
  }
  if (m == 'a') {
    // texto livre, sem restrição
    return const [];
  }

  final hasZeroMaskChars = RegExp(r'[0#9]').hasMatch(mascara);
  final hasOnlyAllowedSymbols =
      RegExp(r'^[0-9#\-:./ ]+$').hasMatch(mascara.replaceAll('0', '0'));

  if (hasZeroMaskChars || hasOnlyAllowedSymbols) {
    return [
      PatternMaskFormatter(pattern: mascara),
    ];
  }

  return const [];
}

/// decide teclado pro campo
TextInputType pickKeyboardForMask(String? mascara) {
  if (mascara == null) {
    return TextInputType.text;
  }

  final m = mascara.toLowerCase();

  if (m == 'hh:mm') return TextInputType.number;
  if (m == 'dd/mm/yyyy') return TextInputType.number;
  if (m == '***-****') return TextInputType.text;
  if (m == '0') return TextInputType.number;

  return TextInputType.text;
}
