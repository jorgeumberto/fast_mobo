import 'opcao.dart';

class Pergunta {
  final int id;
  final String bloco; // <-- novo
  final String enunciado;
  final String tipo; // "TextBox", "RadioButton", "CheckBoxList"
  final bool obrigatoria;
  final String? mascara;
  final List<Opcao> opcoes;

  // Para TextBox / RadioButton
  final String? respostaSimples;

  // Para CheckBoxList
  final List<String> respostaMultipla;

  Pergunta({
    required this.id,
    required this.bloco,
    required this.enunciado,
    required this.tipo,
    required this.obrigatoria,
    required this.mascara,
    required this.opcoes,
    required this.respostaSimples,
    required this.respostaMultipla,
  });

  factory Pergunta.fromJson(Map<String, dynamic> json) {
    final rawOpcoes = json['opcoes'];
    final listaOpcoes = (rawOpcoes is List)
        ? rawOpcoes.map((o) => Opcao.fromJson(o)).toList()
        : <Opcao>[];

    String? simples;
    List<String> multipla = [];

    if (json['resposta'] is List) {
      multipla = (json['resposta'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (json['resposta'] != null) {
      simples = json['resposta'].toString();
    }

    return Pergunta(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      bloco: (json['bloco'] ?? '').toString(),
      enunciado: (json['enunciado'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
      obrigatoria: json['obrigatoria'] == true,
      mascara: json['mascara']?.toString(),
      opcoes: listaOpcoes,
      respostaSimples: simples,
      respostaMultipla: multipla,
    );
  }

  Map<String, dynamic> toJson() {
    final dynamic respostaJson;
    if (tipo == 'CheckBoxList') {
      respostaJson = respostaMultipla;
    } else {
      respostaJson = respostaSimples;
    }

    return {
      'id': id,
      'bloco': bloco,
      'enunciado': enunciado,
      'tipo': tipo,
      'obrigatoria': obrigatoria,
      'mascara': mascara,
      'opcoes': opcoes.map((o) => o.toJson()).toList(),
      'resposta': respostaJson,
    };
  }
}
