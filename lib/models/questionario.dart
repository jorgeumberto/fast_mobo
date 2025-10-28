class Questionario {
  String? id;
  String nome;
  String dataInicio;
  String dataTermino;

  Questionario({
    this.id,
    required this.nome,
    required this.dataInicio,
    required this.dataTermino,
  });

  factory Questionario.fromJson(Map<String, dynamic> json) {
    return Questionario(
      id: (json['id'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      dataInicio: (json['data_inicio'] ?? '').toString(),
      dataTermino: (json['data_termino'] ?? '').toString(),
    );
  }
}
