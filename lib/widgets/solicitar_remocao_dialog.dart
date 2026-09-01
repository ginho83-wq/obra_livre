import 'package:flutter/material.dart';
import '../repositorios/solicitacoes_remocao_repository.dart';
import 'dialog_mensagem_widget.dart';

// ==========================================================
// SOLICITAR REMOÇÃO DIALOG
// ==========================================================
class SolicitarRemocaoDialog extends StatefulWidget {
  final String obraId;
  final String tituloObra;

  const SolicitarRemocaoDialog({
    super.key,
    required this.obraId,
    required this.tituloObra,
  });

  @override
  State<SolicitarRemocaoDialog> createState() =>
      _SolicitarRemocaoDialogState();
}

class _SolicitarRemocaoDialogState
    extends State<SolicitarRemocaoDialog> {
  final TextEditingController _motivoController =
  TextEditingController();

  final SolicitacoesRemocaoRepository _repository =
      SolicitacoesRemocaoRepository.instancia;

  bool _enviando = false;

  // ========================================================
  // DISPOSE
  // ========================================================
  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  // ========================================================
  // ENVIAR SOLICITAÇÃO
  // ========================================================
  Future<void> _enviar() async {
    if (_enviando) {
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      await _repository.criarSolicitacao(
        obraId: widget.obraId,
        motivo: _motivoController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);

      await DialogMensagem.sucesso(
        context,
        titulo: 'Solicitação enviada',
        mensagem:
        'A sua solicitação de remoção foi enviada com sucesso e será analisada pelo administrador.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final mensagem =
      e.toString().replaceFirst('Exception: ', '');

      await DialogMensagem.erro(
        context,
        titulo: 'Não foi possível enviar',
        mensagem: mensagem,
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  // ========================================================
  // BUILD
  // ========================================================
  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: largura > 600 ? 500 : largura - 48,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TÍTULO
              // ==================================================
              const Text(
                'Solicitar remoção',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // OBRA
              // ==================================================
              const Text(
                'Obra',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                widget.tituloObra,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // MOTIVO
              // ==================================================
              const Text(
                'Motivo da solicitação',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _motivoController,
                minLines: 4,
                maxLines: 7,
                maxLength: 1000,
                enabled: !_enviando,
                decoration: InputDecoration(
                  hintText:
                  'Explique, se desejar, o motivo da remoção...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding:
                  const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // INFORMAÇÃO
              // ==================================================
              const Text(
                'A solicitação será analisada pelo administrador.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // BOTÕES
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ==================================================
                  // CANCELAR
                  // ==================================================
                  TextButton(
                    onPressed: _enviando
                        ? null
                        : () {
                      Navigator.of(context).pop(false);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ==================================================
                  // ENVIAR
                  // ==================================================
                  ElevatedButton(
                    onPressed: _enviando ? null : _enviar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                    ),
                    child: _enviando
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                        : const Text(
                      'Enviar solicitação',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// ADMIN SOLICITAÇÕES DE REMOÇÃO PAGE
// ==========================================================
class AdminSolicitacoesRemocaoPage extends StatefulWidget {
  const AdminSolicitacoesRemocaoPage({
    super.key,
  });

  @override
  State<AdminSolicitacoesRemocaoPage> createState() =>
      _AdminSolicitacoesRemocaoPageState();
}

class _AdminSolicitacoesRemocaoPageState
    extends State<AdminSolicitacoesRemocaoPage> {
  final SolicitacoesRemocaoRepository _repository =
      SolicitacoesRemocaoRepository.instancia;

  List<SolicitacaoRemocao> _solicitacoes = [];

  bool _carregando = true;
  bool _atualizandoEmSegundoPlano = false;

  String? _erro;

  String _filtro = 'pendente';

  bool _processando = false;

  // ========================================================
  // INIT
  // ========================================================
  @override
  void initState() {
    super.initState();
    _carregarInicial();
  }

  // ========================================================
  // CARREGAMENTO INICIAL
  // ========================================================
  Future<void> _carregarInicial() async {
    try {
      final cache =
      await _repository.carregarTodasDoCache(
        status: _filtro,
      );

      if (cache != null && mounted) {
        setState(() {
          _solicitacoes = cache;
          _carregando = false;
          _erro = null;
          _atualizandoEmSegundoPlano = true;
        });
      }
    } catch (_) {}

    await _atualizarDoSupabase(
      mostrarCarregamento: _solicitacoes.isEmpty,
    );
  }

  // ========================================================
  // ATUALIZAR
  // ========================================================
  Future<void> _atualizarDoSupabase({
    bool mostrarCarregamento = false,
  }) async {
    if (mostrarCarregamento && mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    if (mounted) {
      setState(() {
        _atualizandoEmSegundoPlano = true;
      });
    }

    try {
      final resultado =
      await _repository.carregarTodas(
        status: _filtro,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _solicitacoes = resultado;
        _carregando = false;
        _erro = null;
        _atualizandoEmSegundoPlano = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _carregando = false;
        _atualizandoEmSegundoPlano = false;
      });

      if (_solicitacoes.isEmpty) {
        setState(() {
          _erro = e.toString().replaceFirst(
            'Exception: ',
            '',
          );
        });
      } else {
        await DialogMensagem.aviso(
          context,
          titulo: 'Não foi possível atualizar',
          mensagem:
          'Não foi possível atualizar as solicitações. '
              'Os dados anteriores continuam disponíveis.',
        );
      }
    }
  }

  // ========================================================
  // CARREGAR
  // ========================================================
  Future<void> _carregar() async {
    await _atualizarDoSupabase(
      mostrarCarregamento: false,
    );
  }

  // ========================================================
  // ALTERAR FILTRO
  // ========================================================
  Future<void> _alterarFiltro(
      String filtro,
      ) async {
    if (_filtro == filtro) {
      return;
    }

    setState(() {
      _filtro = filtro;
      _erro = null;
      _carregando = true;
    });

    try {
      final cache =
      await _repository.carregarTodasDoCache(
        status: filtro,
      );

      if (cache != null && mounted) {
        setState(() {
          _solicitacoes = cache;
          _carregando = false;
          _atualizandoEmSegundoPlano = true;
        });
      }
    } catch (_) {}

    await _atualizarDoSupabase(
      mostrarCarregamento: _solicitacoes.isEmpty,
    );
  }

  // ========================================================
  // DATA
  // ========================================================
  String _formatarData(
      DateTime? data,
      ) {
    if (data == null) {
      return '';
    }

    final local = data.toLocal();

    final dia =
    local.day.toString().padLeft(2, '0');
    final mes =
    local.month.toString().padLeft(2, '0');
    final ano =
    local.year.toString();

    final hora =
    local.hour.toString().padLeft(2, '0');
    final minuto =
    local.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  // ========================================================
  // APROVAR
  // ========================================================
  Future<void> _aprovar(
      SolicitacaoRemocao solicitacao,
      ) async {
    final resposta =
    await _mostrarRespostaDialog(
      titulo: 'Aprovar solicitação',
      texto:
      'Deseja aprovar a solicitação de remoção desta obra? '
          'A obra publicada e o respetivo PDF serão removidos.',
      botao: 'Aprovar',
    );

    if (resposta == null) {
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      await _repository.aprovarSolicitacao(
        solicitacaoId: solicitacao.id,
        respostaAdmin: resposta,
      );

      if (!mounted) {
        return;
      }

      await DialogMensagem.sucesso(
        context,
        titulo: 'Solicitação aprovada',
        mensagem:
        'A solicitação foi aprovada e a obra publicada '
            'e o respetivo PDF foram removidos.',
      );

      if (!mounted) {
        return;
      }

      await _carregar();
    } catch (e) {
      if (!mounted) {
        return;
      }

      await DialogMensagem.erro(
        context,
        titulo: 'Erro ao aprovar',
        mensagem: e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  // ========================================================
  // REJEITAR
  // ========================================================
  Future<void> _rejeitar(
      SolicitacaoRemocao solicitacao,
      ) async {
    final resposta =
    await _mostrarRespostaDialog(
      titulo: 'Rejeitar solicitação',
      texto:
      'Informe, se desejar, o motivo da rejeição.',
      botao: 'Rejeitar',
    );

    if (resposta == null) {
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      await _repository.rejeitarSolicitacao(
        solicitacaoId: solicitacao.id,
        respostaAdmin: resposta,
      );

      if (!mounted) {
        return;
      }

      await DialogMensagem.aviso(
        context,
        titulo: 'Solicitação rejeitada',
        mensagem:
        'A solicitação de remoção foi rejeitada.',
      );

      if (!mounted) {
        return;
      }

      await _carregar();
    } catch (e) {
      if (!mounted) {
        return;
      }

      await DialogMensagem.erro(
        context,
        titulo: 'Erro ao rejeitar',
        mensagem: e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  // ========================================================
  // DIALOG RESPOSTA
  // ========================================================
  Future<String?> _mostrarRespostaDialog({
    required String titulo,
    required String texto,
    required String botao,
  }) async {
    final controller =
    TextEditingController();

    final resultado =
    await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,

          // ==================================================
          // BORDER RADIUS DO DIALOG
          // ==================================================
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),

          title: Text(titulo),

          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(texto),

                const SizedBox(
                  height: 18,
                ),

                // ==================================================
                // CAMPO DE RESPOSTA
                // ==================================================
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    hintText:
                    'Resposta ao usuário (opcional)',
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                    disabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            // ==================================================
            // CANCELAR
            // ==================================================
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              style: TextButton.styleFrom(
                backgroundColor:
                Colors.grey.shade200,
                foregroundColor:
                Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Cancelar',
              ),
            ),

            // ==================================================
            // APROVAR / REJEITAR
            // ==================================================
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(
                  controller.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.black87,
                foregroundColor:
                Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(6),
                ),
              ),
              child: Text(botao),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return resultado;
  }

  // ========================================================
  // BUILD
  // ========================================================
  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Solicitações de remoção',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_atualizandoEmSegundoPlano)
            const Padding(
              padding: EdgeInsets.only(
                right: 8,
              ),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),

          IconButton(
            tooltip: 'Atualizar',
            onPressed:
            _processando ||
                _atualizandoEmSegundoPlano
                ? null
                : _carregar,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          _buildFiltros(),

          const Divider(
            height: 1,
          ),

          Expanded(
            child: _buildConteudo(),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // FILTROS
  // ========================================================
  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          _buildFiltro(
            valor: 'pendente',
            titulo: 'Aguardando',
          ),

          const SizedBox(
            width: 8,
          ),

          _buildFiltro(
            valor: 'aprovada',
            titulo: 'Aprovadas',
          ),

          const SizedBox(
            width: 8,
          ),

          _buildFiltro(
            valor: 'rejeitada',
            titulo: 'Rejeitadas',
          ),
        ],
      ),
    );
  }

  Widget _buildFiltro({
    required String valor,
    required String titulo,
  }) {
    final selecionado =
        _filtro == valor;

    return OutlinedButton(
      onPressed: _processando
          ? null
          : () => _alterarFiltro(valor),
      style: OutlinedButton.styleFrom(
        backgroundColor: selecionado
            ? Colors.black87
            : Colors.white,
        foregroundColor: selecionado
            ? Colors.white
            : Colors.black87,
        side: BorderSide(
          color: selecionado
              ? Colors.black87
              : Colors.grey.shade400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(6),
        ),
      ),
      child: Text(titulo),
    );
  }

  // ========================================================
  // CONTEÚDO
  // ========================================================
  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: Colors.grey,
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                _erro!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(
                height: 16,
              ),

              ElevatedButton(
                onPressed: _carregar,
                style:
                ElevatedButton.styleFrom(
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_solicitacoes.isEmpty) {
      return const Center(
        child: Text(
          'Não existem solicitações nesta categoria.',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(
        20,
      ),
      itemCount: _solicitacoes.length,
      itemBuilder: (context, index) {
        return _buildCard(
          _solicitacoes[index],
        );
      },
    );
  }

  // ========================================================
  // CARD
  // ========================================================
  Widget _buildCard(
      SolicitacaoRemocao solicitacao,
      ) {
    final pendente =
        solicitacao.status.toLowerCase() ==
            'pendente';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      elevation: 1,

      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(6),
      ),

      child: Padding(
        padding: const EdgeInsets.all(
          20,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              solicitacao.tituloObra ??
                  'Obra',
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w600,
              ),
            ),

            if (solicitacao.autorObra !=
                null &&
                solicitacao.autorObra!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(
                height: 5,
              ),

              Text(
                'Autor: '
                    '${solicitacao.autorObra}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(
              height: 12,
            ),

            Text(
              'Data da solicitação: '
                  '${_formatarData(solicitacao.createdAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'Motivo',
              style: TextStyle(
                fontWeight:
                FontWeight.w600,
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              solicitacao.motivo
                  ?.trim()
                  .isNotEmpty ==
                  true
                  ? solicitacao.motivo!
                  : 'Nenhum motivo informado.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),

            if (solicitacao
                .respostaAdmin !=
                null &&
                solicitacao.respostaAdmin!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(
                height: 18,
              ),

              const Divider(),

              const SizedBox(
                height: 12,
              ),

              const Text(
                'Resposta',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                solicitacao
                    .respostaAdmin!,
                style:
                const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],

            if (pendente) ...[
              const SizedBox(
                height: 20,
              ),

              const Divider(),

              const SizedBox(
                height: 12,
              ),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // ==================================================
                  // APROVAR
                  // ==================================================
                  ElevatedButton(
                    onPressed: _processando
                        ? null
                        : () => _aprovar(
                      solicitacao,
                    ),
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.black87,
                      foregroundColor:
                      Colors.white,
                      elevation: 0,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          6,
                        ),
                      ),
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                    ),
                    child: const Text(
                      'Aprovar',
                    ),
                  ),

                  // ==================================================
                  // REJEITAR
                  // ==================================================
                  OutlinedButton(
                    onPressed: _processando
                        ? null
                        : () => _rejeitar(
                      solicitacao,
                    ),
                    style:
                    OutlinedButton.styleFrom(
                      foregroundColor:
                      Colors.black87,
                      side: BorderSide(
                        color:
                        Colors.grey.shade500,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          6,
                        ),
                      ),
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                    ),
                    child: const Text(
                      'Rejeitar',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

