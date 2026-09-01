import 'package:flutter/material.dart';

import '../repositorios/solicitacoes_remocao_repository.dart';
import '../widgets/dialog_mensagem_widget.dart';

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
  // CONSTANTES DE DESIGN
  // ========================================================

  static const double _radius = 6;

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
      final cache = await _repository.carregarTodasDoCache(
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
      final resultado = await _repository.carregarTodas(
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
      final cache = await _repository.carregarTodasDoCache(
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

    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final ano = local.year.toString();
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  // ========================================================
  // APROVAR
  // ========================================================

  Future<void> _aprovar(
      SolicitacaoRemocao solicitacao,
      ) async {
    final resposta = await _mostrarRespostaDialog(
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
    final resposta = await _mostrarRespostaDialog(
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
    final controller = TextEditingController();

    final resultado = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            0,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            16,
            24,
            0,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            24,
            18,
            24,
            20,
          ),
          title: Text(
            titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    hintText:
                    'Resposta ao usuário (opcional)',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding:
                    const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(_radius),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(_radius),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(_radius),
                      borderSide: const BorderSide(
                        color: Colors.black87,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.black87,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(_radius),
                ),
              ),
              child: const Text(
                'Cancelar',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(
                  controller.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(_radius),
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 24,
        title: const Text(
          'Solicitações de remoção',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_atualizandoEmSegundoPlano)
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
              ),
              child: Center(
                child: SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(
              right: 16,
            ),
            child: IconButton(
              tooltip: 'Atualizar',
              onPressed:
              _processando ||
                  _atualizandoEmSegundoPlano
                  ? null
                  : _carregar,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 21,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              _buildCabecalho(),
              _buildFiltros(),
              const SizedBox(height: 4),
              Expanded(
                child: _buildConteudo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // CABEÇALHO
  // ========================================================

  Widget _buildCabecalho() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        16,
        24,
        18,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gerenciar solicitações',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _tituloFiltro(),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          if (!_carregando &&
              _solicitacoes.isNotEmpty)
            _buildContador(),
        ],
      ),
    );
  }

  String _tituloFiltro() {
    switch (_filtro) {
      case 'aprovada':
        return 'Solicitações aprovadas';
      case 'rejeitada':
        return 'Solicitações rejeitadas';
      default:
        return 'Solicitações aguardando análise';
    }
  }

  // ========================================================
  // CONTADOR
  // ========================================================

  Widget _buildContador() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
        BorderRadius.circular(_radius),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Text(
        '${_solicitacoes.length} '
            '${_solicitacoes.length == 1 ? 'solicitação' : 'solicitações'}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ========================================================
  // FILTROS
  // ========================================================

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius:
          BorderRadius.circular(_radius),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFiltro(
              valor: 'pendente',
              titulo: 'Aguardando',
              icone: Icons.schedule_rounded,
            ),
            _buildFiltro(
              valor: 'aprovada',
              titulo: 'Aprovadas',
              icone: Icons.check_rounded,
            ),
            _buildFiltro(
              valor: 'rejeitada',
              titulo: 'Rejeitadas',
              icone: Icons.close_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltro({
    required String valor,
    required String titulo,
    required IconData icone,
  }) {
    final selecionado = _filtro == valor;

    return TextButton(
      onPressed: _processando
          ? null
          : () => _alterarFiltro(valor),
      style: TextButton.styleFrom(
        backgroundColor: selecionado
            ? Colors.white
            : Colors.transparent,
        foregroundColor: selecionado
            ? Colors.black87
            : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(_radius),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icone,
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selecionado
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // CONTEÚDO
  // ========================================================

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_erro != null) {
      return _buildEstadoErro();
    }

    if (_solicitacoes.isEmpty) {
      return _buildEstadoVazio();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        24,
        20,
        24,
        30,
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
  // ESTADO DE ERRO
  // ========================================================

  Widget _buildEstadoErro() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 460,
        ),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          borderRadius:
          BorderRadius.circular(_radius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 38,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 14),
            const Text(
              'Não foi possível carregar as solicitações',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _erro!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _carregar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(_radius),
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

  // ========================================================
  // ESTADO VAZIO
  // ========================================================

  Widget _buildEstadoVazio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
              BorderRadius.circular(_radius),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 26,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma solicitação encontrada',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Não existem solicitações nesta categoria.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
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

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
        BorderRadius.circular(_radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // ==================================================
            // TOPO DO CARD
            // ==================================================

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitacao.tituloObra ??
                            'Obra',
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (solicitacao.autorObra !=
                          null &&
                          solicitacao.autorObra!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          solicitacao.autorObra!,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildStatusBadge(
                  pendente
                      ? 'Aguardando'
                      : solicitacao.status,
                  pendente,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // DATA
            // ==================================================

            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 15,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 7),
                Text(
                  _formatarData(
                    solicitacao.createdAt,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ==================================================
            // MOTIVO
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                BorderRadius.circular(_radius),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motivo da remoção',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    solicitacao.motivo
                        ?.trim()
                        .isNotEmpty ==
                        true
                        ? solicitacao.motivo!
                        : 'Nenhum motivo informado.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // RESPOSTA DO ADMIN
            // ==================================================

            if (solicitacao.respostaAdmin !=
                null &&
                solicitacao.respostaAdmin!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    _radius,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resposta do administrador',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      solicitacao.respostaAdmin!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ==================================================
            // AÇÕES
            // ==================================================

            if (pendente) ...[
              const SizedBox(height: 18),
              Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment:
                MainAxisAlignment.end,
                children: [
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
                        Colors.grey.shade400,
                      ),
                      elevation: 0,
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          _radius,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Rejeitar',
                    ),
                  ),
                  const SizedBox(width: 10),
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
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          _radius,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Aprovar',
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

  // ========================================================
  // STATUS BADGE
  // ========================================================

  Widget _buildStatusBadge(
      String status,
      bool pendente,
      ) {
    String texto = status;

    if (status.toLowerCase() == 'aprovada') {
      texto = 'Aprovada';
    } else if (status.toLowerCase() ==
        'rejeitada') {
      texto = 'Rejeitada';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: pendente
            ? Colors.grey.shade100
            : Colors.grey.shade50,
        borderRadius:
        BorderRadius.circular(_radius),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

