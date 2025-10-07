// lib/src/features/auth/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import '../../../../injection_container.dart';
// A importação correta para o repositório
import '../../../settings/domain/repositories/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // AQUI ESTÁ A CORREÇÃO PRINCIPAL:
  // Trocamos SettingsService por SettingsRepository
  final SettingsRepository _settingsRepository = sl<SettingsRepository>();
  
  final _urlController = TextEditingController();
  late Future<String> _initialUrlFuture;

  @override
  void initState() {
    super.initState();
    // Usamos a variável corrigida _settingsRepository
    _initialUrlFuture = _settingsRepository.getApiUrl();
    _initialUrlFuture.then((url) {
      _urlController.text = url;
    });
  }

  void _saveSettings() {
    // Usamos a variável corrigida _settingsRepository
    _settingsRepository.saveApiUrl(_urlController.text).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas!')),
      );
      Navigator.of(context).pop();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $error'), backgroundColor: Colors.red),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: FutureBuilder<String>(
        future: _initialUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar configurações: ${snapshot.error}'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'URL da API',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'https://sua.api.com',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Salvar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}