import 'package:flutter/material.dart';

import '../repositorios/denuncias_repository.dart';

// ==========================================================
// MINHAS DENÚNCIAS PAGE
// ==========================================================

class MinhasDenunciasPage extends StatefulWidget {
  const MinhasDenunciasPage({
    super.key,
  });

  @override
  State<MinhasDenunciasPage> createState() =>
      _MinhasDenunciasPageState();
}

class _MinhasDenunciasPageState
    extends State<MinhasDenunciasPage> {
  final DenunciasRepository _repository =
      DenunciasRepository.instancia;

  List<Map<String, dynamic>> _denuncias = [];

  bool _carregando = true;

  String? _erro;

  @override
  void initState() {
    super.initState();

    _carregarDenuncias();
  }

  // ==========================================================
  // CARREGAR DENÚNCIAS
  // ==========================================================

  Future<void> _carregarDenuncias() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado =
      await _repository.carregarMinhasDenuncias();

      if (!mounted) {
        return;
      }

      setState(() {
        _denuncias = resultado;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _carregando = false;

        _erro = e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ==========================================================
  // STATUS NORMALIZADO
  // ==========================================================

  String _normalizarStatus(
      String? valor,
      ) {
    final status =
        valor?.toLowerCase().trim() ?? '';

    switch (status) {
      case 'pendente':
      case 'pendentes':
      case 'em_analise':
      case 'em análise':
        return 'pendente';

      case 'aprovada':
      case 'aprovado':
      case 'aprovadas':
      case 'aprovados':
      case 'resolvida':
      case 'resolvido':
      case 'resolvidas':
      case 'resolvidos':
        return 'aprovada';

      case 'rejeitada':
      case 'rejeitado':
      case 'rejeitadas':
      case 'rejeitados':
      case 'recusada':
      case 'recusado':
      case 'recusadas':
      case 'recusados':
        return 'rejeitada';

      default:
        return status;
    }
  }

  // ==========================================================
  // TEXTO STATUS
  // ==========================================================

  String _textoStatus(
      String? valor,
      ) {
    switch (_normalizarStatus(valor)) {
      case 'pendente':
        return 'Pendente';

      case 'aprovada':
        return 'Aprovada';

      case 'rejeitada':
        return 'Rejeitada';

      default:
        return valor?.toString() ?? '—';
    }
  }

  // ==========================================================
  // ÍCONE STATUS
  // ==========================================================

  IconData _iconeStatus(
      String? valor,
      ) {
    switch (_normalizarStatus(valor)) {
      case 'pendente':
        return Icons.pending_actions_outlined;

      case 'aprovada':
        return Icons.check_circle_outline;

      case 'rejeitada':
        return Icons.cancel_outlined;

      default:
        return Icons.report_problem_outlined;
    }
  }

  // ==========================================================
  // COR STATUS
  // ==========================================================

  Color _corStatus(
      String? valor,
      Color primaryColor,
      ) {
    switch (_normalizarStatus(valor)) {
      case 'aprovada':
        return Colors.green.shade700;

      case 'rejeitada':
        return Colors.red.shade700;

      case 'pendente':
        return Colors.orange.shade700;

      default:
        return Colors.grey.shade700;
    }
  }

  // ==========================================================
  // DATA
  // ==========================================================

  String _formatarData(
      String? valor,
      ) {
    if (valor == null ||
        valor.trim().isEmpty) {
      return '';
    }

    try {
      final data =
      DateTime.parse(valor);

      final dia = data.day
          .toString()
          .padLeft(2, '0');

      final mes = data.month
          .toString()
          .padLeft(2, '0');

      final ano =
      data.year.toString();

      return '$dia/$mes/$ano';
    } catch (_) {
      return valor;
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final primaryColor =
        Theme.of(context)
            .colorScheme
            .primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Minhas denúncias',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize:
          const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDenuncias,
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.fromLTRB(
            24,
            30,
            24,
            50,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 900,
              ),
              child: _conteudo(
                primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CONTEÚDO
  // ==========================================================

  Widget _conteudo(
      Color primaryColor,
      ) {
    if (_carregando) {
      return _estadoCarregamento();
    }

    if (_erro != null) {
      return _estadoErro();
    }

    if (_denuncias.isEmpty) {
      return _estadoVazio();
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Acompanhe as suas denúncias',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Aqui pode consultar as denúncias que ainda estão em análise.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 32),

        Text(
          '${_denuncias.length} '
              '${_denuncias.length == 1 ? 'denúncia em análise' : 'denúncias em análise'}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 12),

        ..._denuncias.map(
              (denuncia) => _cartaoDenuncia(
            denuncia,
            primaryColor,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // CARTÃO DA DENÚNCIA
  // ==========================================================

  Widget _cartaoDenuncia(
      Map<String, dynamic> denuncia,
      Color primaryColor,
      ) {
    final motivo =
        denuncia['motivo']
            ?.toString() ??
            'Sem motivo informado';

    final descricao =
        denuncia['descricao']
            ?.toString() ??
            '';

    final status =
    denuncia['status']
        ?.toString();

    final data =
    denuncia['criado_em']
        ?.toString();

    final respostaAdmin =
        denuncia['resposta_admin']
            ?.toString() ??
            '';

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        borderRadius:
        BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Icon(
                _iconeStatus(status),
                size: 22,
                color: _corStatus(
                  status,
                  primaryColor,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  motivo,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Text(
                _textoStatus(status),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w500,
                  color: _corStatus(
                    status,
                    primaryColor,
                  ),
                ),
              ),
            ],
          ),

          if (descricao
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 14),

            Text(
              descricao,
              style: TextStyle(
                fontSize: 14,
                color:
                Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],

          if (respostaAdmin
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(12),
              decoration:
              BoxDecoration(
                color:
                Colors.grey.shade50,
                borderRadius:
                BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resposta da administração',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    respostaAdmin,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                      Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (data != null &&
              data.isNotEmpty) ...[
            const SizedBox(height: 14),

            Text(
              'Enviada em ${_formatarData(data)}',
              style: TextStyle(
                fontSize: 12,
                color:
                Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // CARREGAMENTO
  // ==========================================================

  Widget _estadoCarregamento() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 80,
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
                color:
                Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'A carregar denúncias...',
              style: TextStyle(
                fontSize: 14,
                color:
                Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ESTADO VAZIO
  // ==========================================================

  Widget _estadoVazio() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 80,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons
                  .report_problem_outlined,
              size: 42,
              color:
              Colors.grey.shade400,
            ),

            const SizedBox(height: 16),

            const Text(
              'Não possui denúncias em análise.',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'As denúncias que enviar e que ainda estiverem em análise aparecerão aqui.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ESTADO DE ERRO
  // ==========================================================

  Widget _estadoErro() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 60,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 42,
              color:
              Colors.red.shade400,
            ),

            const SizedBox(height: 16),

            Text(
              _erro ??
                  'Ocorreu um erro.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 18),

            TextButton(
              onPressed:
              _carregarDenuncias,
              child: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

