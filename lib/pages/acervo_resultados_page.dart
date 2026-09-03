import 'package:flutter/material.dart';

import '../dados/obras_recentes.dart';
import '../repositorios/acervo_repository.dart';
import '../widgets/cartao_obra_widget.dart';
import '../widgets/paginacao_google_widget.dart';

// ==========================================================
// ACERVO RESULTADOS PAGE
// ==========================================================
class AcervoResultadosPage extends StatefulWidget {
  final String query;
  final String categoria;
  final String? ano;
  final String autor;
  final String ordenacao;

  const AcervoResultadosPage({
    super.key,
    this.query = '',
    this.categoria = 'Todas',
    this.ano,
    this.autor = '',
    this.ordenacao = 'Mais recentes',
  });

  @override
  State<AcervoResultadosPage> createState() =>
      _AcervoResultadosPageState();
}

class _AcervoResultadosPageState
    extends State<AcervoResultadosPage> {
  final AcervoRepository _repository =
      AcervoRepository.instancia;

  late String _consultaAtual;

  late final TextEditingController
  _pesquisaController;

  late final TextEditingController
  _autorController;

  late String _categoriaSelecionada;
  late String _anoSelecionado;
  late String _ordenacao;

  String _autorPesquisa = '';

  List<AcervoObra> _obras = [];

  bool _carregando = false;
  bool _pesquisaRealizada = false;

  String? _erro;

  int _paginaAtual = 1;

  static const int _obrasPorPagina = 10;

  // ==========================================================
  // INIT
  // ==========================================================
  @override
  void initState() {
    super.initState();

    _consultaAtual =
        widget.query.trim();

    _pesquisaController =
        TextEditingController(
          text: _consultaAtual,
        );

    _autorPesquisa =
        widget.autor.trim();

    _autorController =
        TextEditingController(
          text: _autorPesquisa,
        );

    _categoriaSelecionada =
    AcervoRepository.categorias
        .contains(widget.categoria)
        ? widget.categoria
        : 'Todas';

    _anoSelecionado =
    widget.ano?.isNotEmpty == true
        ? widget.ano!
        : 'Todos os anos';

    _ordenacao = [
      'Mais recentes',
      'Mais antigas',
      'Título A–Z',
    ].contains(widget.ordenacao)
        ? widget.ordenacao
        : 'Mais recentes';

    if (_consultaAtual.isNotEmpty ||
        _categoriaSelecionada != 'Todas' ||
        _anoSelecionado !=
            'Todos os anos' ||
        _autorPesquisa.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        _carregarResultados(
          primeiraPagina: true,
        );
      });
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================
  @override
  void dispose() {
    _pesquisaController.dispose();
    _autorController.dispose();
    super.dispose();
  }

  // ==========================================================
  // PESQUISA PELA LUPA
  // ==========================================================
  Future<void> _abrirPesquisa() async {
    _pesquisaController.text =
        _consultaAtual;

    final resultado =
    await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Pesquisar no acervo',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
              FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller:
              _pesquisaController,
              autofocus: true,
              textInputAction:
              TextInputAction.search,
              decoration: InputDecoration(
                hintText:
                'Título, autor, tema ou categoria...',
                prefixIcon:
                const Icon(
                  Icons.search,
                  size: 20,
                ),
                border:
                const OutlineInputBorder(),
                isDense: true,
                suffixIcon:
                IconButton(
                  tooltip: 'Limpar',
                  icon:
                  const Icon(
                    Icons.clear,
                    size: 19,
                  ),
                  onPressed: () {
                    _pesquisaController
                        .clear();
                  },
                ),
              ),
              onSubmitted: (valor) {
                Navigator.of(
                  dialogContext,
                ).pop(
                  valor.trim(),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
              const Text(
                'Cancelar',
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  _pesquisaController
                      .text
                      .trim(),
                );
              },
              icon: const Icon(
                Icons.search,
                size: 18,
              ),
              label:
              const Text(
                'Pesquisar',
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
                    4,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (resultado == null ||
        !mounted) {
      return;
    }

    await _pesquisar(resultado);
  }

  // ==========================================================
  // PESQUISA
  // ==========================================================
  Future<void> _pesquisar(
      String pesquisa,
      ) async {
    setState(() {
      _consultaAtual =
          pesquisa.trim();

      _pesquisaController.text =
          pesquisa.trim();
    });

    await _carregarResultados(
      primeiraPagina: true,
    );
  }

  // ==========================================================
  // CARREGAR RESULTADOS
  // ==========================================================
  Future<void> _carregarResultados({
    bool primeiraPagina = true,
  }) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
      _pesquisaRealizada = true;

      if (primeiraPagina) {
        _paginaAtual = 1;
      }
    });

    try {
      int? ano;

      if (_anoSelecionado !=
          'Todos os anos' &&
          _anoSelecionado.isNotEmpty) {
        ano = int.tryParse(
          _anoSelecionado,
        );
      }

      final resultados =
      await _repository.pesquisarAcervo(
        query: _consultaAtual,
        categoria:
        _categoriaSelecionada,
        ano: ano,
        autor:
        _autorPesquisa.trim(),
        ordenacao: _ordenacao,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _obras = resultados;
        _carregando = false;
        _pesquisaRealizada = true;

        if (_obras.isEmpty) {
          _paginaAtual = 1;
        } else if (_paginaAtual >
            _totalPaginas) {
          _paginaAtual =
              _totalPaginas;
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _obras = [];
        _carregando = false;

        _erro = e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        );

        _paginaAtual = 1;
        _pesquisaRealizada = true;
      });
    }
  }

  // ==========================================================
  // FILTRO — CATEGORIA
  // ==========================================================
  Widget _construirFiltroCategoria() {
    return SizedBox(
      width: 250,
      height: 48,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color:
          const Color(0xFFE4E6E9),
          borderRadius:
          BorderRadius.circular(6),
        ),
        child:
        DropdownButtonHideUnderline(
          child:
          DropdownButton<String>(
            value:
            _categoriaSelecionada,
            isExpanded: true,
            alignment:
            AlignmentDirectional
                .centerStart,
            icon: const Padding(
              padding: EdgeInsets.only(
                right: 12,
              ),
              child: Icon(
                Icons
                    .keyboard_arrow_down,
                size: 21,
                color: Colors.black54,
              ),
            ),
            dropdownColor: Colors.white,
            borderRadius:
            BorderRadius.circular(4),
            menuMaxHeight: 350,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight:
              FontWeight.w500,
            ),
            items:
            AcervoRepository
                .categorias
                .map(
                  (categoria) {
                return DropdownMenuItem<
                    String>(
                  value: categoria,
                  alignment:
                  AlignmentDirectional
                      .centerStart,
                  child: Padding(
                    padding:
                    const EdgeInsets
                        .only(
                      left: 12,
                    ),
                    child: Text(
                      categoria == 'Todas'
                          ? 'Categoria'
                          : categoria,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                    ),
                  ),
                );
              },
            ).toList(),
            selectedItemBuilder:
                (context) {
              return AcervoRepository
                  .categorias
                  .map(
                    (categoria) {
                  return Align(
                    alignment:
                    Alignment.centerLeft,
                    child: Padding(
                      padding:
                      const EdgeInsets
                          .only(
                        left: 14,
                      ),
                      child: Text(
                        categoria == 'Todas'
                            ? 'Categoria'
                            : categoria,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 14,
                          color:
                          Colors.black87,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ).toList();
            },
            onChanged: (valor) {
              if (valor == null) {
                return;
              }

              setState(() {
                _categoriaSelecionada =
                    valor;
              });

              _aplicarFiltro();
            },
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ANOS DISPONÍVEIS
  // ==========================================================
  List<String> get _anosDisponiveis {
    final anos = <int>{};

    for (final obra in _obras) {
      if (obra.anoObra != null) {
        anos.add(
          obra.anoObra!,
        );
      }
    }

    final anoAtual =
        DateTime.now().year;

    for (
    int ano = anoAtual;
    ano >= 2000;
    ano--
    ) {
      anos.add(ano);
    }

    final lista = anos.toList();

    lista.sort(
          (a, b) => b.compareTo(a),
    );

    return lista
        .map(
          (ano) => ano.toString(),
    )
        .toList();
  }

  // ==========================================================
  // PAGINAÇÃO
  // ==========================================================
  int get _totalPaginas {
    if (_obras.isEmpty) {
      return 1;
    }

    return (
        _obras.length /
            _obrasPorPagina
    ).ceil();
  }

  List<AcervoObra> get _obrasDaPagina {
    if (_obras.isEmpty) {
      return [];
    }

    final inicio =
        (_paginaAtual - 1) *
            _obrasPorPagina;

    if (inicio >= _obras.length) {
      return [];
    }

    final fim = (
        inicio + _obrasPorPagina
    ).clamp(
      0,
      _obras.length,
    );

    return _obras.sublist(
      inicio,
      fim,
    );
  }

  void _alterarPagina(
      int pagina,
      ) {
    if (pagina < 1 ||
        pagina > _totalPaginas ||
        pagina == _paginaAtual) {
      return;
    }

    setState(() {
      _paginaAtual = pagina;
    });
  }

  // ==========================================================
  // CARTÃO DA OBRA
  //
  // IMPORTANTE:
  // O CartaoObraWidget agora é responsável por
  // abrir a página individual através de obra.id.
  // ==========================================================
  Widget _construirObra(
      AcervoObra obra,
      ) {
    final obraRecente = ObraRecente(
      id: obra.id,
      titulo: obra.titulo,
      resumo: obra.descricao,
      autor: obra.autor,
      coautores: obra.coautores,
      categoria: obra.categoria,
      urlDocumento:
      obra.urlDocumento,
      dataPublicacao:
      obra.dataPublicacao
          ?.toIso8601String() ??
          '',
      status: 'publicada',
      anoObra: obra.anoObra,
    );

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 28,
      ),
      child: CartaoObraWidget(
        obra: obraRecente,
      ),
    );
  }

  // ==========================================================
  // FILTRO — ANO
  // ==========================================================
  Widget _construirFiltroAno() {
    return SizedBox(
      width: 145,
      height: 48,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color:
          const Color(0xFFE9EAEC),
          borderRadius:
          BorderRadius.circular(4),
        ),
        child:
        DropdownButtonHideUnderline(
          child:
          DropdownButton<String>(
            value:
            _anoSelecionado ==
                'Todos os anos'
                ? null
                : _anoSelecionado,
            hint: const Row(
              children: [
                Icon(
                  Icons
                      .calendar_today_outlined,
                  size: 17,
                  color: Colors.black87,
                ),
                SizedBox(width: 8),
                Text(
                  'Ano',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                    Colors.black87,
                  ),
                ),
              ],
            ),
            isExpanded: true,
            alignment:
            AlignmentDirectional
                .centerStart,
            icon: const Padding(
              padding: EdgeInsets.only(
                right: 10,
              ),
              child: Icon(
                Icons
                    .keyboard_arrow_down,
                size: 19,
                color: Colors.black54,
              ),
            ),
            dropdownColor: Colors.white,
            borderRadius:
            BorderRadius.circular(4),
            menuMaxHeight: 350,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
            items:
            _anosDisponiveis.map(
                  (ano) {
                return DropdownMenuItem<
                    String>(
                  value: ano,
                  child: Text(
                    ano,
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ).toList(),
            selectedItemBuilder:
                (context) {
              return _anosDisponiveis
                  .map(
                    (ano) {
                  return Row(
                    children: [
                      const Icon(
                        Icons
                            .calendar_today_outlined,
                        size: 17,
                        color:
                        Colors.black87,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          ano,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 13,
                            color:
                            Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ).toList();
            },
            onChanged: (valor) {
              if (valor == null) {
                return;
              }

              setState(() {
                _anoSelecionado =
                    valor;
              });

              _aplicarFiltro();
            },
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FILTRO — ORDENAÇÃO
  // ==========================================================
  Widget _construirFiltroOrdenacao() {
    return SizedBox(
      width: 180,
      height: 48,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color:
          const Color(0xFFE9EAEC),
          borderRadius:
          BorderRadius.circular(4),
        ),
        child:
        DropdownButtonHideUnderline(
          child:
          DropdownButton<String>(
            value: _ordenacao,
            isExpanded: true,
            alignment:
            AlignmentDirectional
                .centerStart,
            icon: const Padding(
              padding: EdgeInsets.only(
                right: 10,
              ),
              child: Icon(
                Icons
                    .keyboard_arrow_down,
                size: 19,
                color: Colors.black54,
              ),
            ),
            dropdownColor: Colors.white,
            borderRadius:
            BorderRadius.circular(4),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Mais recentes',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort,
                      size: 18,
                      color: Colors.black87,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Mais recentes',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'Mais antigas',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort,
                      size: 18,
                      color: Colors.black87,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Mais antigas',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'Título A–Z',
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .sort_by_alpha,
                      size: 18,
                      color: Colors.black87,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Título A–Z',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (valor) {
              if (valor == null) {
                return;
              }

              setState(() {
                _ordenacao = valor;
              });

              _aplicarFiltro();
            },
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BOTÃO DE PESQUISA
  // ==========================================================
  Widget _construirBotaoPesquisa() {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color:
        const Color(0xFFE9EAEC),
        borderRadius:
        BorderRadius.circular(4),
        child: InkWell(
          onTap: _abrirPesquisa,
          borderRadius:
          BorderRadius.circular(4),
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Icon(
                Icons.search,
                size: 22,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BOTÃO MAIS FILTROS
  // ==========================================================
  Widget _construirBotaoMaisFiltros() {
    return SizedBox(
      height: 48,
      child: Material(
        color:
        const Color(0xFFE9EAEC),
        borderRadius:
        BorderRadius.circular(4),
        child: InkWell(
          onTap: _abrirMaisFiltros,
          borderRadius:
          BorderRadius.circular(4),
          child: const SizedBox(
            height: 48,
            child: Padding(
              padding:
              EdgeInsets.symmetric(
                horizontal: 14,
              ),
              child: Row(
                mainAxisSize:
                MainAxisSize.min,
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  Icon(
                    Icons.tune,
                    size: 18,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Mais filtros',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      Colors.black87,
                      fontWeight:
                      FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons
                        .keyboard_arrow_down,
                    size: 18,
                    color:
                    Colors.black54,
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
  // BOTÃO LIMPAR FILTROS
  // ==========================================================
  Widget _construirBotaoLimparFiltros() {
    return SizedBox(
      height: 48,
      child: Material(
        color:
        const Color(0xFFE9EAEC),
        borderRadius:
        BorderRadius.circular(4),
        child: InkWell(
          onTap: _limparFiltros,
          borderRadius:
          BorderRadius.circular(4),
          child: const SizedBox(
            height: 48,
            child: Padding(
              padding:
              EdgeInsets.symmetric(
                horizontal: 14,
              ),
              child: Row(
                mainAxisSize:
                MainAxisSize.min,
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  Icon(
                    Icons.clear,
                    size: 17,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Limpar filtros',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      Colors.black87,
                    ),
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
  // MAIS FILTROS
  // ==========================================================
  Future<void> _abrirMaisFiltros() async {
    _autorController.text =
        _autorPesquisa;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
          Colors.white,
          title: const Text(
            'Mais filtros',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
              FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                const Text(
                  'Autor',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Colors.black87,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                TextField(
                  controller:
                  _autorController,
                  autofocus: true,
                  textInputAction:
                  TextInputAction.done,
                  decoration:
                  InputDecoration(
                    hintText:
                    'Nome do autor',
                    prefixIcon:
                    const Icon(
                      Icons
                          .person_outline,
                      size: 19,
                    ),
                    suffixIcon:
                    IconButton(
                      tooltip:
                      'Limpar',
                      icon:
                      const Icon(
                        Icons.clear,
                        size: 18,
                      ),
                      onPressed: () {
                        _autorController
                            .clear();
                      },
                    ),
                    filled: true,
                    fillColor:
                    const Color(
                      0xFFF1F2F4,
                    ),
                    border:
                    const OutlineInputBorder(
                      borderSide:
                      BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Use este filtro quando quiser '
                      'procurar especificamente obras '
                      'de um determinado autor.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
              const Text(
                'Cancelar',
              ),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _autorPesquisa =
                  '';
                  _autorController
                      .clear();
                });

                Navigator.of(
                  dialogContext,
                ).pop();

                _aplicarFiltro();
              },
              style:
              OutlinedButton.styleFrom(
                foregroundColor:
                Colors.black87,
                side:
                const BorderSide(
                  color:
                  Colors.black12,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    4,
                  ),
                ),
              ),
              child:
              const Text(
                'Limpar',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _autorPesquisa =
                      _autorController
                          .text
                          .trim();
                });

                Navigator.of(
                  dialogContext,
                ).pop();

                _aplicarFiltro();
              },
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
                    4,
                  ),
                ),
              ),
              child:
              const Text(
                'Aplicar filtros',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // FILTROS HORIZONTAIS
  // ==========================================================
  Widget _construirFiltrosHorizontais() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(10),
      decoration:
      const BoxDecoration(
        color:
        Color(0xFFF0F1F3),
        borderRadius:
        BorderRadius.only(
          bottomLeft:
          Radius.circular(6),
          bottomRight:
          Radius.circular(6),
        ),
      ),
      child:
      SingleChildScrollView(
        scrollDirection:
        Axis.horizontal,
        child: Row(
          mainAxisSize:
          MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.center,
          children: [
            _construirBotaoPesquisa(),
            const SizedBox(
              width: 10,
            ),
            _construirFiltroAno(),
            const SizedBox(
              width: 10,
            ),
            _construirFiltroOrdenacao(),
            const SizedBox(
              width: 10,
            ),
            _construirBotaoMaisFiltros(),
            const SizedBox(
              width: 10,
            ),
            _construirBotaoLimparFiltros(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // APLICAR FILTRO
  // ==========================================================
  void _aplicarFiltro() {
    _carregarResultados(
      primeiraPagina: true,
    );
  }

  // ==========================================================
  // LIMPAR FILTROS
  // ==========================================================
  void _limparFiltros() {
    setState(() {
      _categoriaSelecionada =
      'Todas';

      _anoSelecionado =
      'Todos os anos';

      _ordenacao =
      'Mais recentes';

      _consultaAtual = '';

      _autorPesquisa = '';

      _pesquisaController.clear();

      _autorController.clear();

      _obras = [];

      _erro = null;

      _paginaAtual = 1;

      _pesquisaRealizada = false;

      _carregando = false;
    });
  }

  // ==========================================================
  // CONTEÚDO
  // ==========================================================
  Widget _construirConteudo() {
    if (!_pesquisaRealizada) {
      return _construirEstadoInicial();
    }

    if (_carregando) {
      return const Center(
        child: Padding(
          padding:
          EdgeInsets.all(60),
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    if (_erro != null) {
      return _construirErro();
    }

    if (_obras.isEmpty) {
      return _construirVazio();
    }

    final titulo =
    _categoriaSelecionada ==
        'Todas'
        ? 'Resultados do Acervo'
        : _categoriaSelecionada;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          maxLines: 2,
          overflow:
          TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 23,
            fontWeight:
            FontWeight.bold,
            color:
            Colors.black87,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          _consultaAtual.isEmpty
              ? '${_obras.length} obra(s) encontrada(s)'
              : '${_obras.length} obra(s) encontrada(s) '
              'para "$_consultaAtual"',
          style: const TextStyle(
            fontSize: 13,
            color:
            Colors.black54,
          ),
        ),
        const SizedBox(
          height: 22,
        ),

        // ======================================================
        // O CARTÃO USA obra.id E ABRE /obra/:id
        // ======================================================
        ..._obrasDaPagina.map(
          _construirObra,
        ),

        if (_totalPaginas > 1)
          Padding(
            padding:
            const EdgeInsets.only(
              top: 4,
            ),
            child:
            PaginacaoGoogleWidget(
              paginaAtual:
              _paginaAtual,
              totalPaginas:
              _totalPaginas,
              onPaginaAlterada:
              _alterarPagina,
            ),
          ),
      ],
    );
  }

  // ==========================================================
  // ESTADO INICIAL
  // ==========================================================
  Widget _construirEstadoInicial() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical: 70,
        ),
        child: Column(
          children: [
            Icon(
              Icons
                  .menu_book_outlined,
              size: 58,
              color:
              Colors.grey.shade400,
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'Explore o Acervo',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                FontWeight.w500,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'Pesquise por títulos, autores, '
                  'temas ou categorias.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                Colors.black54,
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
  Widget _construirVazio() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical: 60,
        ),
        child: Column(
          children: [
            Icon(
              Icons
                  .menu_book_outlined,
              size: 58,
              color:
              Colors.grey.shade400,
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'Nenhuma obra encontrada',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'Experimente alterar a pesquisa '
                  'ou os filtros.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                Colors.black54,
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
  Widget _construirErro() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical: 60,
        ),
        child: Column(
          children: [
            Icon(
              Icons
                  .cloud_off_outlined,
              size: 58,
              color:
              Colors.grey.shade400,
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'Não foi possível carregar o acervo',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 24,
              ),
              child: Text(
                _erro ?? '',
                textAlign:
                TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color:
                  Colors.black54,
                ),
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            OutlinedButton(
              onPressed: () {
                _carregarResultados(
                  primeiraPagina: true,
                );
              },
              child:
              const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      ),
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
      const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Acervo',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor:
        Colors.white,
        foregroundColor:
        Colors.black87,
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          if (!_pesquisaRealizada) {
            return Future.value();
          }

          return _carregarResultados(
            primeiraPagina: true,
          );
        },
        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 1080,
              ),
              child: Padding(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    // ==========================================
                    // CATEGORIA
                    // ==========================================
                    _construirFiltroCategoria(),

                    const SizedBox(
                      height: 6,
                    ),

                    // ==========================================
                    // PAINEL DOS FILTROS
                    // ==========================================
                    _construirFiltrosHorizontais(),

                    const SizedBox(
                      height: 30,
                    ),

                    // ==========================================
                    // RESULTADOS
                    // ==========================================
                    _construirConteudo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
