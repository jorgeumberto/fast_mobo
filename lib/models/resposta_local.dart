class RespostaLocal {
  final int perguntaId;

  // Para TextBox / RadioButton
  String? valor;

  // Para CheckBoxList (múltiplas opções)
  List<String> valoresMultiplos;

  // Controle de sincronização
  bool sincronizado;

  RespostaLocal({
    required this.perguntaId,
    this.valor,
    List<String>? valoresMultiplos,
    this.sincronizado = false,
  }) : valoresMultiplos = valoresMultiplos ?? [];

  factory RespostaLocal.fromJson(Map<String, dynamic> json) {
    List<String> mult = [];
    if (json['valores_multiplos'] is List) {
      mult = (json['valores_multiplos'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return RespostaLocal(
      perguntaId: json['pergunta_id'] is int
          ? json['pergunta_id']
          : int.tryParse(json['pergunta_id'].toString()) ?? 0,
      valor: json['valor']?.toString(),
      valoresMultiplos: mult,
      sincronizado: json['sincronizado'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pergunta_id': perguntaId,
      'valor': valor,
      'valores_multiplos': valoresMultiplos,
      'sincronizado': sincronizado,
    };
  }
}
