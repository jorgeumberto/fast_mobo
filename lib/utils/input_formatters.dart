import 'package:flutter/services.dart';

/// Força que o usuário só digite dígitos.
class DigitsOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final onlyDigits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    return newValue.copyWith(
      text: onlyDigits,
      selection: updateCursor(onlyDigits),
    );
  }

  TextSelection updateCursor(String text) {
    return TextSelection.collapsed(offset: text.length);
  }
}

/// Máscara genérica tipo "hh:mm", "dd/mm/yyyy", "000.000.000-00", etc.
/// Usa `maskChar` pra saber o que é caractere dinâmico.
/// - default: `0` ou `9` ou `#` = dígito
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
    // remove tudo que não bate com allowedCharMatcher
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    int rawIndex = 0;

    for (int i = 0; i < pattern.length && rawIndex < raw.length; i++) {
      final pChar = pattern[i];

      // se o pattern pede dígito (0,9,#), preenche com o próximo número
      if (pChar == '0' || pChar == '9' || pChar == '#') {
        final nextDigit = raw[rawIndex];
        if (!allowedCharMatcher.hasMatch(nextDigit)) break;
        buffer.write(nextDigit);
        rawIndex++;
      } else {
        // caractere fixo da máscara ("/", ":", "-", etc)
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

/// Máscara especial para hora "hh:mm"
class HoraFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
    // pega só dígitos
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

/// Máscara especial para data "dd/mm/yyyy"
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

/// Máscara especial de placa "***-****"
/// A regra que você mandou sugere:
/// - 3 letras (qualquer coisa?), hífen, 4 números.
/// Vou assumir:
///   primeiras 3 posições = letras maiúsculas [A-Z]
///   últimas 4 = dígitos [0-9]
class PlacaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
    // separa letras e dígitos conforme posição
    final raw = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    String letras = '';
    String numeros = '';

    int i = 0;
    // pega até 3 letras
    while (i < raw.length && letras.length < 3) {
      final ch = raw[i];
      if (RegExp(r'[A-Z]').hasMatch(ch)) {
        letras += ch;
      }
      i++;
    }
    // pega até 4 dígitos depois
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

/// Retorna o(s) formatter(s) corretos baseado na máscara declarada.
List<TextInputFormatter> buildFormattersForMask(String? mascara) {
  if (mascara == null) {
    return const [];
  }

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

  // "0" = só dígitos (ex: KM VEÍCULO)
  if (m == '0') {
    return [DigitsOnlyFormatter()];
  }

  // "a" = qualquer coisa livre, então sem formatter especial
  if (m == 'a') {
    return const [];
  }

  // fallback genérico:
  // Se você quiser no futuro suportar outras máscaras tipo "000.000.000-00" (CPF),
  // você pode mapear pra PatternMaskFormatter('000.000.000-00')
  // Aqui vamos tentar detectar automaticamente se a máscara é feita só de
  // dígitos fixos e separadores.
  final hasZeroMaskChars = RegExp(r'[0#9]').hasMatch(mascara);
  final hasOnlyAllowedSymbols =
      RegExp(r'^[0-9#\-:./ ]+$').hasMatch(mascara.replaceAll('0', '0'));
  if (hasZeroMaskChars || hasOnlyAllowedSymbols) {
    // Exemplo: "000.000.000-00"
    return [
      PatternMaskFormatter(
        pattern: mascara,
      ),
    ];
  }

  return const [];
}

/// Também escolhemos o teclado ideal pro campo.
TextInputType pickKeyboardForMask(String? mascara) {
  if (mascara == null) {
    return TextInputType.text;
  }

  final m = mascara.toLowerCase();

  if (m == 'hh:mm') return TextInputType.number;
  if (m == 'dd/mm/yyyy') return TextInputType.number;
  if (m == '***-****') return TextInputType.text; // placa tem letra e número
  if (m == '0') return TextInputType.number;

  // fallback (texto livre)
  return TextInputType.text;
}
