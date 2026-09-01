import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositorios/estatisticas_repository.dart';

// ==========================================================
// ESTATISTICA ADMIN PAGE
// ==========================================================

class EstatisticaAdminPage extends StatefulWidget {
  const EstatisticaAdminPage({
    super.key,
  });

  @override
  State<EstatisticaAdminPage> createState() =>
      _EstatisticaAdminPageState();
}

// ==========================================================
// STATE
// ==========================================================

class _EstatisticaAdminPageState
    extends State<EstatisticaAdminPage> {
  final EstatisticasRepository _repository =
      EstatisticasRepository.instancia;

  bool _carregando = true;

  bool _atualizando = false;

  EstatisticasDados? _dados;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _carregarEstatisticas();
  }

  // ==========================================================
  // CARREGAR ESTATÍSTICAS
  //
  // 1. Mostra cache imediatamente.
  // 2. Depois atualiza pelo Supabase.
  // ==========================================================

  Future<void> _carregarEstatisticas({
    bool mostrarErro = true,
  }) async {
    if (_dados == null && mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      // ======================================================
      // PRIMEIRO: TENTAR CACHE
      // ======================================================

      final dadosCache =
      await _repository.carregarDoCache();

      if (dadosCache != null &&
          mounted) {
        setState(() {
          _dados = dadosCache;
          _carregando = false;
        });
      }

      // ======================================================
      // DEPOIS: ATUALIZAR PELO SUPABASE
      // ======================================================

      if (mounted) {
        setState(() {
          _atualizando = true;
        });
      }

      final dadosAtualizados =
      await _repository.atualizarEstatisticas();

      if (!mounted) {
        return;
      }

      setState(() {
        _dados = dadosAtualizados;
        _carregando = false;
        _atualizando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _carregando = false;
        _atualizando = false;
      });

      // ======================================================
      // SE JÁ TEM CACHE, NÃO PRECISA MOSTRAR ERRO BLOQUEANTE
      // ======================================================

      if (_dados != null) {
        _mostrarMensagem(
          'Não foi possível atualizar as estatísticas.',
        );

        return;
      }

      if (mostrarErro) {
        _mostrarMensagem(
          e.toString().replaceFirst(
            'Exception: ',
            '',
          ),
        );
      }
    }
  }

  // ==========================================================
  // ATUALIZAR MANUALMENTE
  // ==========================================================

  Future<void> _atualizarManualmente() async {
    if (_atualizando) {
      return;
    }

    await _carregarEstatisticas();
  }

  // ==========================================================
  // SAIR
  // ==========================================================

  Future<void> _sair() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) {
        return;
      }

      context.go('/login');
    } catch (e) {
      if (!mounted) {
        return;
      }

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
  // MENSAGEM
  // ==========================================================

  void _mostrarMensagem(
      String mensagem,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
        ),
      );
  }

  // ==========================================================
  // INDICADOR DE ESTATÍSTICA
  // ==========================================================

  Widget _buildIndicadorEstatistica({
    required String titulo,
    required int valor,
    required IconData icone,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icone,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          valor.toString(),
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // TÍTULO DE SECÇÃO
  // ==========================================================

  Widget _buildTituloSecao(
      String titulo,
      String descricao,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 17,
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          descricao,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // OBRAS POR CATEGORIA
  // ==========================================================

  Widget _buildCategorias() {
    final categorias =
        _dados!.obrasPorCategoria;

    if (categorias.isEmpty) {
      return _buildMensagemVazia(
        'Ainda não existem obras publicadas com categoria.',
      );
    }

    return Column(
      children:
      categorias.entries.map(
            (entrada) {
          final total =
              _dados!.obrasPublicadas;

          final percentual =
          total == 0
              ? 0.0
              : entrada.value / total;

          return Padding(
            padding:
            const EdgeInsets.only(
              bottom: 14,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entrada.key,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                          Colors.grey.shade800,
                          fontWeight:
                          FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      entrada.value.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color:
                        Colors.grey.shade800,
                        fontWeight:
                        FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius:
                  BorderRadius.circular(4),
                  child:
                  LinearProgressIndicator(
                    value: percentual,
                    minHeight: 5,
                    backgroundColor:
                    Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  // ==========================================================
  // PUBLICAÇÕES POR ANO
  // ==========================================================

  Widget _buildAnos() {
    final anos = _dados!.obrasPorAno;

    if (anos.isEmpty) {
      return _buildMensagemVazia(
        'Ainda não existem dados suficientes para mostrar as publicações por ano.',
      );
    }

    return Column(
      children:
      anos.entries.map(
            (entrada) {
          final percentual =
          _percentualAno(
            entrada.value,
            anos,
          );

          return Padding(
            padding:
            const EdgeInsets.only(
              bottom: 13,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 45,
                  child: Text(
                    entrada.key.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      Colors.grey.shade800,
                      fontWeight:
                      FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.circular(4),
                    child:
                    LinearProgressIndicator(
                      value: percentual,
                      minHeight: 5,
                      backgroundColor:
                      Colors.grey.shade200,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 30,
                  child: Text(
                    entrada.value.toString(),
                    textAlign:
                    TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      Colors.grey.shade800,
                      fontWeight:
                      FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  // ==========================================================
  // PERCENTUAL DO ANO
  // ==========================================================

  double _percentualAno(
      int valor,
      Map<int, int> dados,
      ) {
    if (dados.isEmpty) {
      return 0;
    }

    final maior =
    dados.values.reduce(
          (a, b) => a > b ? a : b,
    );

    if (maior == 0) {
      return 0;
    }

    return valor / maior;
  }

  // ==========================================================
  // MENSAGEM VAZIA
  // ==========================================================

  Widget _buildMensagemVazia(
      String mensagem,
      ) {
    return Text(
      mensagem,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // ==========================================================
  // CABEÇALHO
  // ==========================================================

  Widget _buildCabecalho() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment:
          CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Estatísticas',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            // =================================================
            // INDICADOR DE ATUALIZAÇÃO
            // =================================================

            if (_atualizando)
              const SizedBox(
                width: 16,
                height: 16,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              IconButton(
                tooltip:
                'Atualizar estatísticas',
                onPressed:
                _atualizarManualmente,
                icon: const Icon(
                  Icons.refresh,
                  size: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Visão geral da atividade da plataforma.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ESTATÍSTICAS PRINCIPAIS
  // ==========================================================

  Widget _buildEstatisticasPrincipais() {
    final indicadores = [
      _buildIndicadorEstatistica(
        titulo: 'Total de obras',
        valor: _dados!.totalObras,
        icone:
        Icons.library_books_outlined,
      ),
      _buildIndicadorEstatistica(
        titulo: 'Publicadas',
        valor: _dados!.obrasPublicadas,
        icone:
        Icons.check_circle_outline,
      ),
      _buildIndicadorEstatistica(
        titulo: 'Pendentes',
        valor: _dados!.obrasPendentes,
        icone:
        Icons.hourglass_empty,
      ),
      _buildIndicadorEstatistica(
        titulo: 'Rejeitadas',
        valor: _dados!.obrasRejeitadas,
        icone:
        Icons.cancel_outlined,
      ),
      _buildIndicadorEstatistica(
        titulo: 'Utilizadores',
        valor: _dados!.totalUtilizadores,
        icone:
        Icons.people_outline,
      ),
      _buildIndicadorEstatistica(
        titulo: 'Visualizações',
        valor: _dados!.totalVisualizacoes,
        icone:
        Icons.visibility_outlined,
      ),
      _buildIndicadorEstatistica(
        titulo: 'Downloads',
        valor: _dados!.totalDownloads,
        icone:
        Icons.download_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        final largura =
            constraints.maxWidth;

        if (largura >= 1100) {
          return Row(
            children:
            List.generate(
              indicadores.length,
                  (index) {
                return Expanded(
                  child: Padding(
                    padding:
                    EdgeInsets.only(
                      right: index ==
                          indicadores
                              .length -
                              1
                          ? 0
                          : 16,
                    ),
                    child:
                    indicadores[index],
                  ),
                );
              },
            ),
          );
        }

        return Wrap(
          spacing: 22,
          runSpacing: 14,
          children: indicadores,
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      Colors.grey.shade100,

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        automaticallyImplyLeading:
        false,
        elevation: 0,
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
        title: const Text(
          'Administração',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 17,
          ),
        ),
        actions: [
          Padding(
            padding:
            const EdgeInsets.only(
              right: 16,
            ),
            child: TextButton(
              onPressed: _sair,
              child: const Text(
                'Sair',
              ),
            ),
          ),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: _carregando &&
          _dados == null
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _dados == null
          ? Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child:
          _buildMensagemVazia(
            'Não foi possível carregar as estatísticas.',
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh:
        _atualizarManualmente,
        child: LayoutBuilder(
          builder: (
              context,
              constraints,
              ) {
            final largura =
                constraints.maxWidth;

            final larguraConteudo =
            largura > 1180
                ? 1180.0
                : largura;

            return ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 24,
                vertical: 26,
              ),
              children: [
                Center(
                  child:
                  ConstrainedBox(
                    constraints:
                    BoxConstraints(
                      maxWidth:
                      larguraConteudo,
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        _buildCabecalho(),

                        const SizedBox(
                          height: 24,
                        ),

                        _buildEstatisticasPrincipais(),

                        const SizedBox(
                          height: 34,
                        ),

                        _buildTituloSecao(
                          'Obras por categoria',
                          'Distribuição das obras publicadas por categoria.',
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _buildCategorias(),

                        const SizedBox(
                          height: 24,
                        ),

                        _buildTituloSecao(
                          'Publicações por ano',
                          'Evolução das publicações registadas na plataforma.',
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _buildAnos(),

                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
