import 'dart:convert';
import 'dart:io';
import 'package:fast_mobo/models/questionario.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'api.dart';
import 'models/pergunta.dart';
import 'models/resposta_local.dart';
import 'utils/input_formatters.dart';

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

  // perguntaId -> RespostaLocal (estado atual offline)
  final Map<int, RespostaLocal> _respostas = {};

  // image picker
  final ImagePicker _picker = ImagePicker();

  // =========================================================
  // CACHE: PERGUNTAS
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

        // inicializa _respostas com base nas perguntas cacheadas
        for (final p in listaCache) {
          _respostas[p.id] = RespostaLocal(
            perguntaId: p.id,
            valor: p.respostaSimples,
            valoresMultiplos: List<String>.from(p.respostaMultipla),
            justificativa: p.justificativa,
            midias: List<String>.from(p.midias),
            sincronizado: true,
          );
        }
      } catch (_) {
        // cache inválido => ignora
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
  // CACHE: RESPOSTAS
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

        // aplica respostas carregadas nas perguntas em memória
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
              obrigaMidia: p.obrigaMidia,
              obrigaJustificativa: p.obrigaJustificativa,
              justificativa: r?.justificativa ?? p.justificativa,
              midias: r?.midias ?? p.midias,
            );
          }).toList();
        });
      } catch (_) {
        // cache inválido => ignora
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
  // LOAD GERAL
  // =========================================================
  Future<void> _loadTudo() async {
    // 1. tenta cache local primeiro
    await _loadPerguntasFromCache();
    await _loadRespostasFromCache();

    // 2. tenta API depois
    try {
      final idQuestionario = int.tryParse(widget.questionario.id ?? '') ?? 0;
      final listaApi =
          await ApiService.getPerguntasDoQuestionario(idQuestionario);

      setState(() {
        _perguntas = listaApi;
        _erro = null;
        _loading = false;
      });

      // garante que todas as perguntas tenham um RespostaLocal
      for (final p in listaApi) {
        _respostas.putIfAbsent(
          p.id,
          () => RespostaLocal(
            perguntaId: p.id,
            valor: p.respostaSimples,
            valoresMultiplos: List<String>.from(p.respostaMultipla),
            justificativa: p.justificativa,
            midias: List<String>.from(p.midias),
            sincronizado: true, // vindo da API, assumimos sincronizado
          ),
        );
      }

      // salva versão mais nova em cache
      await _savePerguntasToCache(listaApi);
      await _saveRespostasToCache();
    } catch (e) {
      if (_perguntas.isEmpty) {
        setState(() {
          _erro = 'Falha ao carregar perguntas: $e';
          _loading = false;
        });
      }
      // se já tinha cache, ok, segue offline
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTudo();
  }

  // =========================================================
  // ATUALIZAÇÕES DE ESTADO DO FORM (onChange)
  // =========================================================
  void _atualizarRespostaSimples(int perguntaId, String? novoValor) {
    setState(() {
      final atual = _respostas[perguntaId] ??
          RespostaLocal(perguntaId: perguntaId);

      atual.valor = novoValor;
      atual.sincronizado = false;
      _respostas[perguntaId] = atual;
    });
    _saveRespostasToCache();
  }

  void _toggleRespostaMultipla(int perguntaId, String valorOpcao) {
    setState(() {
      final atual = _respostas[perguntaId] ??
          RespostaLocal(perguntaId: perguntaId);

      final lista = List<String>.from(atual.valoresMultiplos);
      if (lista.contains(valorOpcao)) {
        lista.remove(valorOpcao);
      } else {
        lista.add(valorOpcao);
      }
      atual.valoresMultiplos = lista;
      atual.sincronizado = false;
      _respostas[perguntaId] = atual;
    });
    _saveRespostasToCache();
  }

  void _atualizarJustificativa(int perguntaId, String texto) {
    setState(() {
      final atual = _respostas[perguntaId] ??
          RespostaLocal(perguntaId: perguntaId);

      atual.justificativa = texto;
      atual.sincronizado = false;
      _respostas[perguntaId] = atual;
    });
    _saveRespostasToCache();
  }

  Future<void> _adicionarMidia(int perguntaId) async {
    // abre câmera
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75, // reduz tamanho, bom pra offline
    );

    if (foto == null) {
      // usuário cancelou
      return;
    }

    setState(() {
      final atual = _respostas[perguntaId] ??
          RespostaLocal(perguntaId: perguntaId);

      final novasMidias = List<String>.from(atual.midias);
      novasMidias.add(foto.path); // path local do arquivo .jpg no device

      atual.midias = novasMidias;
      atual.sincronizado = false;
      _respostas[perguntaId] = atual;
    });

    _saveRespostasToCache();
  }

  Widget _buildMiniaturasMidia(int perguntaId) {
    final r = _respostas[perguntaId];
    final midias = r?.midias ?? [];

    if (midias.isEmpty) {
      return const Text(
        'Nenhuma foto anexada ainda.',
        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: midias.map((path) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 64,
            height: 64,
            color: Colors.black12,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Center(
                  child: Icon(Icons.broken_image, size: 28),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================
  // BADGE DE SYNC
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
  // WIDGETS POR TIPO DE PERGUNTA
  // =========================================================
  Widget _buildCampoPergunta(Pergunta p) {
    final rLocal = _respostas[p.id];

    final respostaSimplesAtual =
        rLocal?.valor ?? p.respostaSimples ?? '';

    final respostaMultiplaAtual =
        (rLocal?.valoresMultiplos.isNotEmpty == true)
            ? rLocal!.valoresMultiplos
            : p.respostaMultipla;

    final justificativaAtual =
        rLocal?.justificativa ?? p.justificativa ?? '';

    final bool sincronizado = rLocal?.sincronizado ?? true;

    List<Widget> conteudoPrincipal;

    switch (p.tipo) {
      case 'TextBox': {
        final mask = p.mascara;
        final controllersValue = respostaSimplesAtual;

        conteudoPrincipal = [
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
        ];
        break;
      }

      case 'RadioButton': {
        conteudoPrincipal = [
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
        ];
        break;
      }

      case 'CheckBoxList': {
        conteudoPrincipal = [
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
        ];
        break;
      }

      default: {
        conteudoPrincipal = [
          Text(
            p.enunciado,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Tipo não suportado: ${p.tipo}'),
        ];
      }
    }

    // Campos adicionais condicionais (justificativa / mídia)
    final extras = <Widget>[];

    if (p.obrigaJustificativa == 1) {
      extras.addAll([
        const SizedBox(height: 12),
        const Text(
          'Justificativa',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: justificativaAtual)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: justificativaAtual.length),
            ),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Descreva o problema...',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) {
            _atualizarJustificativa(p.id, val);
          },
        ),
      ]);
    }

    if (p.obrigaMidia == 1) {
      extras.addAll([
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Foto(s) obrigatória(s)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _adicionarMidia(p.id);
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildMiniaturasMidia(p.id),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...conteudoPrincipal,
        ...extras,
      ],
    );
  }

  // =========================================================
  // AGRUPAMENTO POR BLOCO
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
  // SYNC ENVIO
  // =========================================================

  Map<String, dynamic> _buildPayloadNaoSincronizado() {
    final pendentes = _respostas.values
        .where((r) => r.sincronizado == false)
        .toList();

    return {
      'questionario_id': widget.questionario.id,
      'respostas': pendentes.map((r) {
        return {
          'pergunta_id': r.perguntaId,
          'valor': r.valor,
          'valores_multiplos': r.valoresMultiplos,
          'justificativa': r.justificativa,
          'midias': r.midias,
        };
      }).toList(),
    };
  }

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
      setState(() {}); // atualiza badges
    }
  }

  Future<void> _enviarRespostasNaoSincronizadas() async {
    final pendentes = _respostas.values
        .where((r) => r.sincronizado == false)
        .toList();

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
      await ApiService.enviarRespostas(payload);

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
