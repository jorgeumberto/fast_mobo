class Usuario {
  String ? id;
  String nome;
  String email;
  String? fotoUrl;

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    this.fotoUrl,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    // Ajuste os nomes dos campos conforme sua API (ex.: 'name', 'email', 'avatar')
    return Usuario(
      id: (json['id'] ?? '').toString(),
      nome: (json['name'] ?? json['nome'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fotoUrl: (json['avatar'] ?? json['photo_url'] ?? json['foto'])?.toString(),
    );
  }
}
