import 'package:flutter/material.dart';
import '../repositorios/solicitacoes_remocao_repository.dart';

// ==========================================================
// MINHAS SOLICITAÇÕES DE REMOÇÃO PAGE
// ==========================================================
class MinhasSolicitacoesRemocaoPage extends StatefulWidget {
  const MinhasSolicitacoesRemocaoPage({
    super.key,
  });

  @override
  State<MinhasSolicitacoesRemocaoPage> createState() =>
      _MinhasSolicitacoesRemocaoPageState();
}

class _MinhasSolicitacoesRemocaoPageState
    extends State<MinhasSolicitacoesRemocaoPage> {
  final SolicitacoesRemocaoRepository _repository =
      SolicitacoesRemocaoRepository.instancia;

  List<SolicitacaoRemocao> _solicitacoes = [];

  bool _carregando = true;
  String? _erro;

  // ==========================================================
  // INIT
  // ==========================================================
  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // ==========================================================
  // CARREGAR SOLICITAÇÕES
  // ==========================================================
  Future<void> _carregar() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final solicitacoes =
      await _repository.carregarMinhasSolicitacoes();

      if (!mounted) {
        return;
      }

      setState(() {
        _solicitacoes = solicitacoes;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _carregando = false;
        _erro = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================
  String _formatarData(DateTime? data) {
    if (data == null) {
      return 'Data não disponível';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  // ==========================================================
  // NORMALIZAR STATUS
  // ==========================================================
  String _normalizarStatus(String status) {
    return status.trim().toLowerCase();
  }

  // ==========================================================
  // TEXTO DO STATUS
  // ==========================================================
  String _textoStatus(String status) {
    switch (_normalizarStatus(status)) {
      case 'pendente':
        return 'Pendente';

      case 'aprovada':
        return 'Aprovada';

      case 'rejeitada':
        return 'Rejeitada';

      default:
        return status.isEmpty ? 'Desconhecido' : status;
    }
  }

  // ==========================================================
  // ÍCONE DO STATUS
  // ==========================================================
  IconData _iconeStatus(String status) {
    switch (_normalizarStatus(status)) {
      case 'pendente':
        return Icons.pending_actions_outlined;

      case 'aprovada':
        return Icons.check_circle_outline;

      case 'rejeitada':
        return Icons.cancel_outlined;

      default:
        return Icons.info_outline;
    }
  }

  // ==========================================================
  // COR DO STATUS
  // ==========================================================
  Color _corStatus(
      String status,
      ColorScheme colorScheme,
      ) {
    switch (_normalizarStatus(status)) {
      case 'pendente':
        return colorScheme.primary;

      case 'aprovada':
        return Colors.green.shade700;

      case 'rejeitada':
        return Colors.red.shade700;

      default:
        return Colors.grey.shade700;
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final primaryColor =
        Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,

      // ======================================================
      // APP BAR
      // ======================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Minhas solicitações',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),

      // ======================================================
      // BODY
      // ======================================================
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            24,
            30,
            24,
            50,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 900,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Minhas solicitações de remoção',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Acompanhe as solicitações de remoção das suas obras.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ========================================
                  // CONTEÚDO
                  // ========================================
                  if (_carregando)
                    _estadoCarregamento()
                  else if (_erro != null)
                    _estadoErro()
                  else if (_solicitacoes.isEmpty)
                      _estadoVazio()
                    else
                      _listaSolicitacoes(
                        primaryColor,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LISTA
  // ==========================================================
  Widget _listaSolicitacoes(
      Color primaryColor,
      ) {
    return Column(
      children: [
        for (int i = 0;
        i < _solicitacoes.length;
        i++) ...[
          _cartaoSolicitacao(
            _solicitacoes[i],
            primaryColor,
          ),
          if (i < _solicitacoes.length - 1)
            const SizedBox(height: 14),
        ],
      ],
    );
  }

  // ==========================================================
  // CARTÃO DA SOLICITAÇÃO
  // ==========================================================
  Widget _cartaoSolicitacao(
      SolicitacaoRemocao solicitacao,
      Color primaryColor,
      ) {
    final status =
    _normalizarStatus(solicitacao.status);

    final corStatus = _corStatus(
      status,
      Theme.of(context).colorScheme,
    );

    final iconeStatus =
    _iconeStatus(status);

    final titulo =
        solicitacao.tituloObra ??
            'Obra não encontrada';

    final autor =
        solicitacao.autorObra ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        borderRadius:
        BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ================================================
          // CABEÇALHO
          // ================================================
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
                      titulo,
                      maxLines: 3,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    if (autor
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        autor,
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                          Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // ==========================================
              // STATUS
              // ==========================================
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: corStatus.withValues(
                      alpha: 0.35,
                    ),
                  ),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Icon(
                      iconeStatus,
                      size: 16,
                      color: corStatus,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _textoStatus(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w500,
                        color: corStatus,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(height: 1),

          const SizedBox(height: 16),

          // ================================================
          // DATA
          // ================================================
          _linhaInformacao(
            titulo: 'Solicitação',
            valor: _formatarData(
              solicitacao.createdAt,
            ),
          ),

          // ================================================
          // MOTIVO
          // ================================================
          if (solicitacao.motivo != null &&
              solicitacao.motivo!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 12),
            _linhaInformacao(
              titulo: 'Motivo',
              valor:
              solicitacao.motivo!.trim(),
            ),
          ],

          // ================================================
          // RESPOSTA DO ADMINISTRADOR
          // ================================================
          if (solicitacao.respostaAdmin != null &&
              solicitacao.respostaAdmin!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resposta do administrador',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Colors.grey.shade800,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    solicitacao
                        .respostaAdmin!
                        .trim(),
                    style: TextStyle(
                      fontSize: 14,
                      color:
                      Colors.grey.shade700,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ================================================
          // DATA DA ATUALIZAÇÃO
          // ================================================
          if (solicitacao.updatedAt != null) ...[
            const SizedBox(height: 14),

            Text(
              'Atualizado em ${_formatarData(solicitacao.updatedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // LINHA DE INFORMAÇÃO
  // ==========================================================
  Widget _linhaInformacao({
    required String titulo,
    required String valor,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // CARREGAMENTO
  // ==========================================================
  Widget _estadoCarregamento() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 50,
      ),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'A carregar solicitações...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ERRO
  // ==========================================================
  Widget _estadoErro() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 40,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 42,
              color: Colors.grey.shade500,
            ),

            const SizedBox(height: 14),

            Text(
              _erro ??
                  'Não foi possível carregar as solicitações.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            TextButton(
              onPressed:
              _carregando ? null : _carregar,
              child: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // VAZIO
  // ==========================================================
  Widget _estadoVazio() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 55,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.delete_outline,
              size: 44,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 16),

            const Text(
              'Nenhuma solicitação de remoção',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Quando solicitar a remoção de uma obra,\n'
                  'ela aparecerá aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

