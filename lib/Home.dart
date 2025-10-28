import 'dart:convert';
import 'package:fast_mobo/questionario_page.dart';
import 'package:fast_mobo/models/questionario.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models/Usuario.dart';
import 'Login.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Usuario? _user;
  bool _loadingUser = true;

  List<Questionario> _questionarios = [];
  bool _loadingQuestionarios = true;
  String? _erroQuestionarios;

  // ---------------------------
  // CACHE: lê do SharedPreferences
  // ---------------------------
  Future<void> _loadQuestionariosFromCache() async {
    final sp = await SharedPreferences.getInstance();
    final cached = sp.getString('meus_questionarios_cache');

    if (cached != null && cached.isNotEmpty) {
      try {
        final decoded = jsonDecode(cached);
        final listaCache = List<Questionario>.from(
          decoded.map((item) => Questionario.fromJson(item)),
        );

        if (mounted) {
          setState(() {
            _questionarios = listaCache;
            _loadingQuestionarios = false; // já temos algo pra mostrar
            _erroQuestionarios = null;
          });
        }
      } catch (e) {
        // se der erro no parse do cache, só ignora e deixa carregar da API
      }
    }
  }

  // ---------------------------
  // CACHE: salva no SharedPreferences
  // ---------------------------
  Future<void> _saveQuestionariosToCache(List<Questionario> lista) async {
    final sp = await SharedPreferences.getInstance();

    // transformar List<Questionario> -> List<Map<String,dynamic>> -> json
    final jsonList = lista.map((q) {
      return {
        'id': q.id,
        'nome': q.nome,
        'data_inicio': q.dataInicio,
        'data_termino': q.dataTermino,
      };
    }).toList();

    await sp.setString('meus_questionarios_cache', jsonEncode(jsonList));
  }

  // ---------------------------
  // USER
  // ---------------------------
  Future<void> _loadUser() async {
    try {
      final me = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _user = me;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar usuário: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingUser = false;
        });
      }
    }
  }

  // ---------------------------
  // QUESTIONÁRIOS:
  // 1) tenta cache
  // 2) depois busca API e atualiza cache
  // ---------------------------
  Future<void> _loadQuestionarios() async {
    // 1. tenta cache primeiro (não bloqueia a API)
    await _loadQuestionariosFromCache();

    // 2. agora busca da API e atualiza
    try {
      final listaApi = await ApiService.getMeusQuestionarios();
      if (!mounted) return;
      setState(() {
        _questionarios = listaApi;
        _erroQuestionarios = null;
        _loadingQuestionarios = false; // se ainda estava true, agora não está mais
      });

      // salva no cache a versão boa da API
      await _saveQuestionariosToCache(listaApi);
    } catch (e) {
      // se falhar API:
      if (!mounted) return;

      // se já tínhamos cache mostrado, não derruba a tela.
      // se não tínhamos nada (lista vazia e nem cache carregado com sucesso),
      // aí mostramos erro.
      if (_questionarios.isEmpty) {
        setState(() {
          _erroQuestionarios = 'Erro ao carregar questionários: $e';
          _loadingQuestionarios = false;
        });
      }
      // se _questionarios já tem algo do cache, deixamos quieto
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadQuestionarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                _user?.nome.isNotEmpty == true ? _user!.nome : 'Usuário',
              ),
              accountEmail: Text(_user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: (_user?.fotoUrl != null &&
                        _user!.fotoUrl!.isNotEmpty)
                    ? NetworkImage(_user!.fotoUrl!)
                    : null,
                child: (_user?.fotoUrl == null || _user!.fotoUrl!.isEmpty)
                    ? Text(
                        (_user?.nome.isNotEmpty == true
                                ? _user!.nome[0]
                                : 'U')
                            .toUpperCase(),
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              decoration: const BoxDecoration(),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {},
            ),
            //const Spacer(),
            //const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _loadingUser
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // título de boas-vindas (inalterado)
                  Text(
                    'Bem-vindo, ${_user?.nome ?? 'Usuário'}!',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),

                  // ===== BLOCO DOS QUESTIONÁRIOS =====

                  if (_loadingQuestionarios)
                    const CircularProgressIndicator()
                  else if (_erroQuestionarios != null &&
                      _questionarios.isEmpty)
                    // só mostra erro se realmente não temos nada pra exibir
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _erroQuestionarios!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else if (_questionarios.isEmpty)
                    const Text('Nenhum questionário disponível.')
                  else
                    SizedBox(
                      height: 300, // pra ListView funcionar dentro do Column
                      child: ListView.builder(
                        itemCount: _questionarios.length,
                        itemBuilder: (context, index) {
                          final q = _questionarios[index];
                          return ListTile(
                            leading: const Icon(Icons.assignment),
                            title: Text(q.nome),
                            subtitle: Text(
                              'De ${q.dataInicio} até ${q.dataTermino}',
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuestionarioPage(questionario: q),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
