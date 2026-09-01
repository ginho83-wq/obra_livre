import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositorios/obras_pendentes_repository.dart';
import '../widgets/paginacao_google_widget.dart';
import '../widgets/search_bar.dart';

// ==========================================================
// ADMIN OBRAS PAGE
// ==========================================================

class AdminObrasPage extends StatefulWidget {
  const AdminObrasPage({
    super.key,
  });

  @override
  State<AdminObrasPage> createState() => _AdminObrasPageState();
}

// ==========================================================
// STATE
// ==========================================================

class _AdminObrasPageState extends State<AdminObrasPage> {
  final ObrasPendentesRepository _repository =
      ObrasPendentesRepository.instancia;

  bool _carregando = true;

  List<Map<String, dynamic>> _obrasPendentes = [];

  int _paginaPendentes = 1;

  static const int _obrasPorPagina = 10;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _carregarObrasPendentes();
  }

  // ==========================================================
  // CARREGAR OBRAS PENDENTES
  // ==========================================================

  Future<void> _carregarObrasPendentes() async {
    if (mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      final pendentes =
      await _repository.carregarObrasPendentes();

      if (!mounted) return;

      setState(() {
        _obrasPendentes = pendentes;
        _paginaPendentes = 1;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ==========================================================
  // PESQUISA
  // ==========================================================

  void _executarPesquisa(String pesquisa) {
    final termo = pesquisa.trim();

    if (termo.isEmpty) {
      return;
    }

    context.push(
      '/admin-obras/resultados/'
          '${Uri.encodeComponent(termo)}',
    );
  }

  // ==========================================================
  // SAIR
  // ==========================================================

  Future<void> _sair() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      context.go('/login');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível terminar a sessão: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // TOTAL DE PÁGINAS
  // ==========================================================

  int get _totalPaginasPendentes {
    if (_obrasPendentes.isEmpty) {
      return 1;
    }

    return (_obrasPendentes.length / _obrasPorPagina).ceil();
  }

  // ==========================================================
  // OBRAS DA PÁGINA
  // ==========================================================

  List<Map<String, dynamic>> get _pendentesDaPagina {
    final inicio =
        (_paginaPendentes - 1) * _obrasPorPagina;

    if (inicio >= _obrasPendentes.length) {
      return [];
    }

    final fim = (inicio + _obrasPorPagina).clamp(
      0,
      _obrasPendentes.length,
    );

    return _obrasPendentes.sublist(
      inicio,
      fim,
    );
  }

  // ==========================================================
  // APROVAR OBRA
  // ==========================================================

  Future<void> _aprovarObra(
      Map<String, dynamic> obra,
      ) async {
    final id = obra['id']?.toString();

    if (id == null || id.isEmpty) {
      _mostrarMensagem(
        'ID da obra não encontrado.',
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          title: const Text(
            'Aprovar obra',
          ),
          content: Text(
            'Deseja aprovar a obra "${obra['titulo']}"?',
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Aprovar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      _mostrarCarregandoDialog(
        'A aprovar obra...',
      );

      await _repository.aprovarObra(id);

      if (!mounted) return;

      Navigator.of(context).pop();

      _mostrarMensagem(
        'Obra aprovada com sucesso.',
      );

      await _carregarObrasPendentes();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }

      _mostrarMensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ==========================================================
  // RECUSAR OBRA
  // ==========================================================

  Future<void> _recusarObra(
      Map<String, dynamic> obra,
      ) async {
    final id = obra['id']?.toString();

    if (id == null || id.isEmpty) {
      _mostrarMensagem(
        'ID da obra não encontrado.',
      );
      return;
    }

    final controller = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          title: const Text(
            'Recusar obra',
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Motivo da recusa',
              hintText:
              'Explique ao autor por que a obra foi recusada.',
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(6),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(6),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(6),
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                final texto =
                controller.text.trim();

                if (texto.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Informe o motivo da recusa.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop(
                  texto,
                );
              },
              child: const Text(
                'Recusar',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (motivo == null ||
        motivo.trim().isEmpty) {
      return;
    }

    try {
      _mostrarCarregandoDialog(
        'A recusar obra...',
      );

      await _repository.rejeitarObra(
        id: id,
        motivo: motivo,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      _mostrarMensagem(
        'Obra recusada.',
      );

      await _carregarObrasPendentes();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }

      _mostrarMensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ==========================================================
  // DIALOG CARREGAMENTO
  // ==========================================================

  void _mostrarCarregandoDialog(
      String mensagem,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(
                width: 18,
              ),
              Flexible(
                child: Text(
                  mensagem,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // MENSAGEM
  // ==========================================================

  void _mostrarMensagem(
      String mensagem,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            mensagem,
          ),
        ),
      );
  }

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String _formatarData(dynamic valor) {
    if (valor == null) {
      return '';
    }

    try {
      final data =
      DateTime.parse(valor.toString());

      final dia =
      data.day.toString().padLeft(2, '0');

      final mes =
      data.month.toString().padLeft(2, '0');

      return '$dia/$mes/${data.year}';
    } catch (_) {
      return valor.toString();
    }
  }

  // ==========================================================
  // PESQUISA
  // ==========================================================

  Widget _buildPesquisa() {
    return SearchBarWidget(
      onSearch: _executarPesquisa,
      hintText:
      'Pesquisar título, autor, instituição, categoria ou palavra-chave...',
    );
  }

  // ==========================================================
  // CABEÇALHO DA SECÇÃO
  // ==========================================================

  Widget _buildCabecalhoSecao() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Obras pendentes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                'Obras aguardando análise administrativa',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
            ),
            borderRadius:
            BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pending_actions_outlined,
                size: 18,
                color: Colors.grey.shade700,
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                '${_obrasPendentes.length}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // INFO ITEM
  // ==========================================================

  Widget _buildInfoItem(
      String label,
      String value,
      ) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CARD DA OBRA
  // ==========================================================

  Widget _buildObraPendenteCard(
      Map<String, dynamic> obra,
      ) {
    final titulo =
        obra['titulo']?.toString() ??
            'Sem título';

    final autor =
        obra['autor']?.toString() ??
            'Autor não informado';

    final categoria =
        obra['categoria']?.toString() ??
            'Sem categoria';

    final area =
        obra['area']?.toString() ?? '';

    final instituicao =
        obra['instituicao']?.toString() ?? '';

    final ano =
        obra['ano_obra']?.toString() ?? '';

    final descricao =
        obra['descricao']?.toString() ?? '';

    final data =
    _formatarData(obra['data_envio']);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
        BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            // ==================================================
            // CABEÇALHO
            // ==================================================

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                    borderRadius:
                    BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 22,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        autor,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                          Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                // ==================================================
                // STATUS
                // ==================================================

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                    borderRadius:
                    BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Pendente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // INFORMAÇÕES
            //
            // Categoria
            // Área
            // Ano
            // Enviada em
            //
            // Instituição fica na coluna lateral.
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
                      _buildInfoItem(
                        'Categoria',
                        categoria,
                      ),

                      _buildInfoItem(
                        'Área',
                        area,
                      ),

                      _buildInfoItem(
                        'Ano',
                        ano,
                      ),

                      _buildInfoItem(
                        'Enviada em',
                        data,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 40,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _buildInfoItem(
                        'Instituição',
                        instituicao,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ==================================================
            // RESUMO
            // ==================================================

            if (descricao.isNotEmpty) ...[
              const SizedBox(
                height: 8,
              ),

              const Text(
                'Resumo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                descricao,
                maxLines: 3,
                overflow:
                TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color:
                  Colors.grey.shade700,
                ),
              ),
            ],

            const SizedBox(
              height: 18,
            ),

            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // AÇÕES
            // ==================================================

            Row(
              mainAxisAlignment:
              MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style:
                  OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () {
                    _mostrarMensagem(
                      'A visualização do PDF será adicionada a seguir.',
                    );
                  },
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'Analisar',
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                OutlinedButton.icon(
                  style:
                  OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () =>
                      _recusarObra(obra),
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                  ),
                  label: const Text(
                    'Recusar',
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                FilledButton.icon(
                  style:
                  FilledButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () =>
                      _aprovarObra(obra),
                  icon: const Icon(
                    Icons.check,
                    size: 18,
                  ),
                  label: const Text(
                    'Aprovar',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // MENSAGEM VAZIA
  // ==========================================================

  Widget _buildMensagemVazia(
      String mensagem,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
        BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 38,
            color: Colors.grey.shade500,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // APP BAR
  // ==========================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      titleSpacing: 24,

      title: const Text(
        'Administração',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),

      actions: [
        TextButton(
          style: TextButton.styleFrom(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(6),
            ),
          ),
          onPressed: () {
            context.push(
              '/admin-solicitacoes-remocao',
            );
          },
          child: const Text(
            'Solicitações de remoção',
          ),
        ),

        const SizedBox(
          width: 4,
        ),

        TextButton(
          style: TextButton.styleFrom(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(6),
            ),
          ),
          onPressed: () {
            context.push(
              '/admin-denuncias',
            );
          },
          child: const Text(
            'Denúncias',
          ),
        ),

        const SizedBox(
          width: 4,
        ),

        TextButton(
          style: TextButton.styleFrom(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(6),
            ),
          ),
          onPressed: () {
            context.push(
              '/admin-estatisticas',
            );
          },
          child: const Text(
            'Estatísticas',
          ),
        ),

        const SizedBox(
          width: 4,
        ),

        Padding(
          padding:
          const EdgeInsets.only(
            right: 18,
          ),
          child: TextButton(
            style: TextButton.styleFrom(
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(6),
              ),
            ),
            onPressed: _sair,
            child: const Text(
              'Sair',
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),

      body: _carregando
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh:
        _carregarObrasPendentes,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.fromLTRB(
            32,
            28,
            32,
            40,
          ),
          children: [

            // ==========================================
            // PESQUISA
            // ==========================================

            _buildPesquisa(),

            const SizedBox(
              height: 34,
            ),

            // ==========================================
            // CABEÇALHO
            // ==========================================

            _buildCabecalhoSecao(),

            const SizedBox(
              height: 18,
            ),

            // ==========================================
            // LISTAGEM
            // ==========================================

            if (_obrasPendentes.isEmpty)
              _buildMensagemVazia(
                'Não existem obras pendentes.',
              )
            else ...[
              ..._pendentesDaPagina.map(
                _buildObraPendenteCard,
              ),

              // ========================================
              // PAGINAÇÃO
              // ========================================

              if (_totalPaginasPendentes > 1)
                Padding(
                  padding:
                  const EdgeInsets.only(
                    top: 8,
                  ),
                  child:
                  PaginacaoGoogleWidget(
                    paginaAtual:
                    _paginaPendentes,
                    totalPaginas:
                    _totalPaginasPendentes,
                    onPaginaAlterada:
                        (pagina) {
                      setState(() {
                        _paginaPendentes =
                            pagina;
                      });
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

