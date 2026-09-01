import 'package:flutter/material.dart';
import '../repositorios/solicitacoes_remocao_repository.dart';

class SolicitacoesRemocaoPage
    extends StatefulWidget {
  const SolicitacoesRemocaoPage({
    super.key,
  });

  @override
  State<SolicitacoesRemocaoPage> createState() =>
      _SolicitacoesRemocaoPageState();
}

class _SolicitacoesRemocaoPageState
    extends State<SolicitacoesRemocaoPage> {
  final SolicitacoesRemocaoRepository
  _repository =
      SolicitacoesRemocaoRepository.instancia;

  List<SolicitacaoRemocao> _solicitacoes = [];

  bool _carregando = true;

  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado =
      await _repository
          .carregarMinhasSolicitacoes();

      if (!mounted) {
        return;
      }

      setState(() {
        _solicitacoes = resultado;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erro = e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        );
        _carregando = false;
      });
    }
  }

  String _textoStatus(String status) {
    switch (status.toLowerCase()) {
      case 'aprovada':
        return 'Aprovada';

      case 'rejeitada':
        return 'Rejeitada';

      case 'pendente':
      default:
        return 'Aguardando análise';
    }
  }

  IconData _iconeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'aprovada':
        return Icons.check_circle_outline;

      case 'rejeitada':
        return Icons.cancel_outlined;

      default:
        return Icons.hourglass_empty;
    }
  }

  Color _corStatus(String status) {
    switch (status.toLowerCase()) {
      case 'aprovada':
        return Colors.green;

      case 'rejeitada':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  String _formatarData(DateTime? data) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Solicitações de remoção',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.grey,
              ),

              const SizedBox(height: 12),

              Text(
                _erro!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _carregar,
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
      return RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.description_outlined,
              size: 50,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Não existem solicitações de remoção.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _solicitacoes.length,
        itemBuilder: (context, index) {
          return _buildCard(
            _solicitacoes[index],
          );
        },
      ),
    );
  }

  Widget _buildCard(
      SolicitacaoRemocao solicitacao,
      ) {
    final cor =
    _corStatus(solicitacao.status);

    return Card(
      margin:
      const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape:
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              solicitacao.tituloObra ??
                  'Obra',
              style: const TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w600,
              ),
            ),

            if (solicitacao.autorObra !=
                null &&
                solicitacao.autorObra!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                'Autor: ${solicitacao.autorObra}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                Icon(
                  _iconeStatus(
                    solicitacao.status,
                  ),
                  size: 20,
                  color: cor,
                ),

                const SizedBox(width: 8),

                Text(
                  _textoStatus(
                    solicitacao.status,
                  ),
                  style: TextStyle(
                    color: cor,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),

            if (solicitacao.createdAt !=
                null) ...[
              const SizedBox(height: 8),
              Text(
                'Solicitada em '
                    '${_formatarData(solicitacao.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],

            if (solicitacao.motivo != null &&
                solicitacao.motivo!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(height: 16),

              const Text(
                'Motivo enviado',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                solicitacao.motivo!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],

            if (solicitacao.respostaAdmin !=
                null &&
                solicitacao.respostaAdmin!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(height: 16),

              const Divider(),

              const SizedBox(height: 12),

              const Text(
                'Resposta do administrador',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                solicitacao.respostaAdmin!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
