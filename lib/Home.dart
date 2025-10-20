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
  bool _loading = true;

  Future<void> _loadUser() async {
    try {
      final me = await ApiService.getMe();
      if (mounted) setState(() => _user = me);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar usuário: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
              accountName: Text(_user?.nome.isNotEmpty == true ? _user!.nome : 'Usuário'),
              accountEmail: Text(_user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: (_user?.fotoUrl != null && _user!.fotoUrl!.isNotEmpty)
                    ? NetworkImage(_user!.fotoUrl!)
                    : null,
                child: (_user?.fotoUrl == null || _user!.fotoUrl!.isEmpty)
                    ? Text(
                        (_user?.nome.isNotEmpty == true ? _user!.nome[0] : 'U').toUpperCase(),
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              // Mostra a imagem/cabeçalho acima do conteúdo do Drawer
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
            const Spacer(),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bem-vindo${_user?.nome.isNotEmpty == true ? ', ${_user!.nome}' : ''}!'),
                  const SizedBox(height: 8),
                  Text(_user?.email ?? ''),
                ],
              ),
            ),
    );
  }
}
