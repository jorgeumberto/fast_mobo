class Pergunta {
  final int id;
  final String bloco;
  final String enunciado;
  final String tipo; // "TextBox", "RadioButton", "CheckBoxList"
  final bool obrigatoria;
  final String? mascara;
  final List<Opcao> opcoes;

  // resposta principal que veio do backend (estado inicial / última sync)
  final String? respostaSimples;        // TextBox e RadioButton
  final List<String> respostaMultipla;  // CheckBoxList

  // novos campos de evidência/complemento
  final int obrigaMidia;           // 0 ou 1
  final int obrigaJustificativa;   // 0 ou 1
  final String? justificativa;
  final List<String> midias;

  Pergunta({
    required this.id,
    required this.bloco,
    required this.enunciado,
    required this.tipo,
    required this.obrigatoria,
    required this.mascara,
    required this.opcoes,
    this.respostaSimples,
    this.respostaMultipla = const [],
    required this.obrigaMidia,
    required this.obrigaJustificativa,
    this.justificativa,
    this.midias = const [],
  });

  factory Pergunta.fromJson(Map<String, dynamic> json) {
    return Pergunta(
      id: json['id'] as int,
      bloco: (json['bloco'] ?? '').toString(),
      enunciado: (json['enunciado'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
      obrigatoria: json['obrigatoria'] == true || json['obrigatoria'] == 1,
      mascara: json['mascara']?.toString(),
      opcoes: (json['opcoes'] as List<dynamic>? ?? [])
          .map((o) => Opcao.fromJson(o))
          .toList(),

      // resposta pode ser string ou lista dependendo do tipo
      respostaSimples: json['resposta'] is String
          ? json['resposta']?.toString()
          : (json['resposta'] is List ? null : json['resposta']?.toString()),
      respostaMultipla: (json['resposta'] is List)
          ? List<String>.from(json['resposta'])
          : <String>[],

      obrigaMidia: (json['obriga_midia'] ?? 0) is bool
          ? ((json['obriga_midia'] ?? false) ? 1 : 0)
          : (json['obriga_midia'] ?? 0) as int,
      obrigaJustificativa: (json['obriga_justificativa'] ?? 0) is bool
          ? ((json['obriga_justificativa'] ?? false) ? 1 : 0)
          : (json['obriga_justificativa'] ?? 0) as int,
      justificativa: json['justificativa']?.toString(),
      midias: (json['midias'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bloco': bloco,
      'enunciado': enunciado,
      'tipo': tipo,
      'obrigatoria': obrigatoria,
      'mascara': mascara,
      'opcoes': opcoes.map((o) => o.toJson()).toList(),

      'resposta': respostaSimples ?? respostaMultipla,

      'obriga_midia': obrigaMidia,
      'obriga_justificativa': obrigaJustificativa,
      'justificativa': justificativa,
      'midias': midias,
    };
  }
}

class Opcao {
  final String valor;
  final String rotulo;
  Opcao({required this.valor, required this.rotulo});

  factory Opcao.fromJson(Map<String, dynamic> json) {
    return Opcao(
      valor: (json['valor'] ?? '').toString(),
      rotulo: (json['rotulo'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valor': valor,
      'rotulo': rotulo,
    };
  }
}
