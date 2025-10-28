class RespostaLocal {
  int perguntaId;

  // resposta principal
  String? valor;                 // Para TextBox/RadioButton
  List<String> valoresMultiplos; // Para CheckBoxList

  // complementos
  String? justificativa;
  List<String> midias;

  // status de sync
  bool sincronizado;

  RespostaLocal({
    required this.perguntaId,
    this.valor,
    this.valoresMultiplos = const [],
    this.justificativa,
    this.midias = const [],
    this.sincronizado = true,
  });

  factory RespostaLocal.fromJson(Map<String, dynamic> json) {
    return RespostaLocal(
      perguntaId: json['pergunta_id'] as int,
      valor: json['valor']?.toString(),
      valoresMultiplos: (json['valores_multiplos'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      justificativa: json['justificativa']?.toString(),
      midias: (json['midias'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      sincronizado: json['sincronizado'] == false ? false : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pergunta_id': perguntaId,
      'valor': valor,
      'valores_multiplos': valoresMultiplos,
      'justificativa': justificativa,
      'midias': midias,
      'sincronizado': sincronizado,
    };
  }
}
