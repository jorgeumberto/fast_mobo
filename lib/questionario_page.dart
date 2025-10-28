import 'dart:convert';
import 'package:fast_mobo/models/questionario.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models/pergunta.dart';
import 'models/resposta_local.dart';
import 'utils/input_formatters.dart'; // <- garante que esse caminho bate com onde você salvou

class QuestionarioPage extends StatefulWidget {
  final Questionario questionario;

  const QuestionarioPage({super.key, required this.questionario});

  @override
  State<QuestionarioPage> createState() => _QuestionarioPageState();
}

class _QuestionarioPageState extends State<QuestionarioPage> {
  bool _loading = true;
  bool _enviando = false;
  String? _erro;
  List<Pergunta> _perguntas = [];

  // Respostas atuais do usuário (perguntaId -> respostaLocal)
  final Map<int, RespostaLocal> _respostas = {};

  // =========================================================
  // Helpers de cache - PERGUNTAS
  // =========================================================
  Future<void> _loadPerguntasFromCache() async {
    final sp = await SharedPreferences.getInstance();
    final cacheKey = 'perguntas_${widget.questionario.id}';
    final cached = sp.getString(cacheKey);

    if (cached != null && cached.isNotEmpty) {
      try {
        final decoded = jsonDecode(cached);
        final listaCache = List<Pergunta>.from(
          decoded.map((item) => Pergunta.fromJson(item)),
        );

        setState(() {
          _perguntas = listaCache;
          _loading = false;
          _erro = null;
        });

        // Inicializa respostas com base nas perguntas em cache
        for (final p in listaCache) {
          _respostas[p.id] = RespostaLocal(
            perguntaId: p.id,
            valor: p.respostaSimples,
            valoresMultiplos: List<String>.from(p.respostaMultipla),
            sincronizado: true, // default inicial, pode ser sobrescrito depois
          );
        }
      } catch (_) {
        // cache corrompido → ignora
      }
    }
  }

  Future<void> _savePerguntasToCache(List<Pergunta> perguntas) async {
    final sp = await SharedPreferences.getInstance();
    final cacheKey = 'perguntas_${widget.questionario.id}';
    final jsonList = perguntas.map((p) => p.toJson()).toList();
    await sp.setString(cacheKey, jsonEncode(jsonList));
  }

  // =========================================================
  // Helpers de cache - RESPOSTAS
  // =========================================================
  Future<void> _loadRespostasFromCache() async {
    final sp = await SharedPreferences.getInstance();
    final cacheKey = 'respostas_${widget.questionario.id}';
    final cached = sp.getString(cacheKey);

    if (cached != null && cached.isNotEmpty) {
      try {
        final decoded = jsonDecode(cached);

        for (final item in decoded) {
          final r = RespostaLocal.fromJson(item);
          _respostas[r.perguntaId] = r;
        }

        // aplica essas respostas carregadas nas perguntas atuais
        setState(() {
          _perguntas = _perguntas.map((p) {
            final r = _respostas[p.id];
            return Pergunta(
              id: p.id,
              bloco: p.bloco,
              enunciado: p.enunciado,
              tipo: p.tipo,
              obrigatoria: p.obrigatoria,
              mascara: p.mascara,
              opcoes: p.opcoes,
              respostaSimples: r?.valor ?? p.respostaSimples,
              respostaMultipla: r?.valoresMultiplos.isNotEmpty == true
                  ? List<String>.from(r!.valoresMultiplos)
                  : List<String>.from(p.respostaMultipla),
            );
          }).toList();
        });
      } catch (_) {
        // cache corrompido → ignora
      }
    }
  }

  Future<void> _saveRespostasToCache() async {
    final sp = await SharedPreferences.getInstance();
    final cacheKey = 'respostas_${widget.questionario.id}';

    final jsonList = _respostas.values.map((r) => r.toJson()).toList();
    await sp.setString(cacheKey, jsonEncode(jsonList));
  }

  // =========================================================
  // Carregamento geral da tela
  // =========================================================
  Future<void> _loadTudo() async {
    // 1. tenta cache
    await _loadPerguntasFromCache();
    await _loadRespostasFromCache();

    // 2. tenta API
    try {
      final idQuestionario = int.tryParse(widget.questionario.id ?? '') ?? 0;
      final listaApi =
          await ApiService.getPerguntasDoQuestionario(idQuestionario);

      setState(() {
        _perguntas = listaApi;
        _erro = null;
        _loading = false;
      });

      // garante que todas as perguntas tenham entrada em _respostas
      for (final p in listaApi) {
        _respostas.putIfAbsent(
          p.id,
          () => RespostaLocal(
            perguntaId: p.id,
            valor: p.respostaSimples,
            valoresMultiplos: List<String>.from(p.respostaMultipla),
            sincronizado: true, // veio do servidor, então sync
          ),
        );
      }

      // salva estado atualizado em cache
      await _savePerguntasToCache(listaApi);
      await _saveRespostasToCache();
    } catch (e) {
      if (_perguntas.isEmpty) {
        setState(() {
          _erro = 'Falha ao carregar perguntas: $e';
          _loading = false;
        });
      }
      // se já tinha cache, segue offline
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTudo();
  }

  // =========================================================
  // Atualização de respostas (onChange do usuário)
  // =========================================================
  void _atualizarRespostaSimples(int perguntaId, String? novoValor) {
    setState(() {
      final atual = _respostas[perguntaId] ??
          RespostaLocal(perguntaId: perguntaId);

      atual.valor = novoValor;
      atual.sincronizado = false; // ficou pendente de envio
      _respostas[perguntaId] = atual;
    });
    _saveRespostasToCache();
  }

  void _toggleRespostaMultipla(int perguntaId, String valorOpcao) {
    setState(() {
      final atual = _respostas[perguntaId] ??
          RespostaLocal(perguntaId: perguntaId);

      final lista = atual.valoresMultiplos;
      if (lista.contains(valorOpcao)) {
        lista.remove(valorOpcao);
      } else {
        lista.add(valorOpcao);
      }

      atual.sincronizado = false; // pendente
      _respostas[perguntaId] = atual;
    });
    _saveRespostasToCache();
  }

  // =========================================================
  // Badge visual de sync
  // =========================================================
  Widget _buildSyncBadge(bool sincronizado) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          sincronizado ? Icons.cloud_done : Icons.cloud_off,
          size: 16,
          color: sincronizado ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 4),
        Text(
          sincronizado ? 'sync' : 'offline',
          style: TextStyle(
            fontSize: 12,
            color: sincronizado ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // Widgets por tipo de pergunta
  // =========================================================
  Widget _buildCampoPergunta(Pergunta p) {
    final rLocal = _respostas[p.id];

    // para TextBox / RadioButton
    final respostaSimplesAtual = rLocal?.valor ?? p.respostaSimples ?? '';

    // para CheckBoxList
    final respostaMultiplaAtual =
        (rLocal?.valoresMultiplos.isNotEmpty == true)
            ? rLocal!.valoresMultiplos
            : p.respostaMultipla;

    final bool sincronizado = rLocal?.sincronizado ?? true;

    switch (p.tipo) {
      case 'TextBox': {
        final mask = p.mascara;
        final controllersValue = respostaSimplesAtual;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // título da pergunta + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    p.enunciado,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildSyncBadge(sincronizado),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: controllersValue)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: controllersValue.length),
                ),
              decoration: InputDecoration(
                hintText: mask,
              ),
              keyboardType: pickKeyboardForMask(mask),
              inputFormatters: buildFormattersForMask(mask),
              onChanged: (val) {
                _atualizarRespostaSimples(p.id, val);
              },
            ),
          ],
        );
      }

      case 'RadioButton':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // título da pergunta + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    p.enunciado,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildSyncBadge(sincronizado),
              ],
            ),
            const SizedBox(height: 8),
            // opções lado a lado
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: p.opcoes.map((op) {
                final selectedValue = (respostaSimplesAtual.isEmpty
                    ? null
                    : respostaSimplesAtual);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: op.valor,
                      groupValue: selectedValue,
                      onChanged: (val) {
                        _atualizarRespostaSimples(p.id, val);
                      },
                    ),
                    Text(op.rotulo),
                  ],
                );
              }).toList(),
            ),
          ],
        );

      case 'CheckBoxList':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // título da pergunta + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    p.enunciado,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildSyncBadge(sincronizado),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: p.opcoes.map((op) {
                final marcado = respostaMultiplaAtual.contains(op.valor);
                return CheckboxListTile(
                  title: Text(op.rotulo),
                  value: marcado,
                  onChanged: (_) {
                    _toggleRespostaMultipla(p.id, op.valor);
                  },
                );
              }).toList(),
            ),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.enunciado,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Tipo não suportado: ${p.tipo}'),
          ],
        );
    }
  }

  // =========================================================
  // Agrupamento por bloco (para montar os ExpansionTile)
  // =========================================================
  Map<String, List<Pergunta>> _groupPerguntasPorBloco(List<Pergunta> perguntas) {
    final Map<String, List<Pergunta>> grupos = {};
    for (final p in perguntas) {
      grupos.putIfAbsent(p.bloco, () => []);
      grupos[p.bloco]!.add(p);
    }
    return grupos;
  }

  // =========================================================
  // Envio (sincronização manual)
  // =========================================================

  // Monta o payload só com o que está offline (sincronizado == false)
  Map<String, dynamic> _buildPayloadNaoSincronizado() {
    final pendentes = _respostas.values
        .where((r) => r.sincronizado == false)
        .toList();

    return {
      'questionario_id': widget.questionario.id,
      'respostas': pendentes.map((r) => r.toJson()).toList(),
    };
  }

  // Após enviar com sucesso, marcar tudo como sincronizado = true
  Future<void> _marcarComoSincronizadoLocal() async {
    bool mudouAlgo = false;
    for (final r in _respostas.values) {
      if (!r.sincronizado) {
        r.sincronizado = true;
        mudouAlgo = true;
      }
    }
    if (mudouAlgo) {
      await _saveRespostasToCache();
      setState(() {}); // atualiza ícones visuais
    }
  }

  Future<void> _enviarRespostasNaoSincronizadas() async {
    final pendentes =
        _respostas.values.where((r) => r.sincronizado == false).toList();

    if (pendentes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma resposta pendente de sincronização.'),
        ),
      );
      return;
    }

    setState(() {
      _enviando = true;
    });

    final payload = _buildPayloadNaoSincronizado();

    try {
      // Chama a API que você implementou no ApiService
      await ApiService.enviarRespostas(payload);

      // Se deu certo: marca localmente como sincronizado
      await _marcarComoSincronizadoLocal();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Respostas enviadas com sucesso!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  // =========================================================
  // BUILD
  // =========================================================
  @override
  Widget build(BuildContext context) {
    final blocosMap = _groupPerguntasPorBloco(_perguntas);
    final blocosOrdenados = blocosMap.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.questionario.nome),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _enviando ? null : _enviarRespostasNaoSincronizadas,
        icon: _enviando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.cloud_upload),
        label: Text(_enviando ? 'Enviando...' : 'Enviar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null && _perguntas.isEmpty
              ? Center(
                  child: Text(
                    _erro!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: blocosOrdenados.length,
                  itemBuilder: (context, blocoIndex) {
                    final nomeBloco = blocosOrdenados[blocoIndex];
                    final perguntasDoBloco = blocosMap[nomeBloco] ?? [];

                    // bloco está sincronizado se TODAS as respostas dele estão sincronizadas
                    final bool blocoSincronizado = perguntasDoBloco.every((p) {
                      final rLocal = _respostas[p.id];
                      return rLocal?.sincronizado ?? true;
                    });

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Card(
                        child: ExpansionTile(
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  nomeBloco,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    blocoSincronizado
                                        ? Icons.cloud_done
                                        : Icons.cloud_off,
                                    size: 16,
                                    color: blocoSincronizado
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    blocoSincronizado ? 'sync' : 'offline',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: blocoSincronizado
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            for (final pergunta in perguntasDoBloco) ...[
                              _buildCampoPergunta(pergunta),
                              const SizedBox(height: 24),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
