class Opcao {
  final String valor;
  final String rotulo;

  Opcao({
    required this.valor,
    required this.rotulo,
  });

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
