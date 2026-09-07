import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/obra_detalhes_dialog.dart';
import '../widgets/paginacao_google_widget.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({
    super.key,
    required this.query,
  });

  @override
  State<SearchResultsPage> createState() =>
      _SearchResultsPageState();
}

class _SearchResultsPageState
    extends State<SearchResultsPage> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  List<Map<String, dynamic>> _obras = [];

  bool _carregando = true;
  bool _erro = false;

  String _mensagemErro = '';

  int _paginaAtual = 1;

  static const int _obrasPorPagina = 10;

  @override
  void initState() {
    super.initState();
    _pesquisar();
  }

  // ==========================================================
  // PESQUISA
  // ==========================================================

  Future<void> _pesquisar() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = false;
      _mensagemErro = '';
    });

    try {
      final pesquisa = widget.query.trim();

      if (pesquisa.isEmpty) {
        if (!mounted) return;

        setState(() {
          _obras = [];
          _paginaAtual = 1;
          _carregando = false;
        });

        return;
      }

      final valor = pesquisa
          .replaceAll(',', ' ')
          .replaceAll('\n', ' ')
          .trim();

      final resposta = await _supabase
          .from('obras')
          .select(
        'id, '
            'titulo, '
            'descricao, '
            'autor, '
            'instituicao, '
            'area, '
            'categoria, '
            'palavras_chave, '
            'ano_obra, '
            'caminho_arquivo, '
            'url_documento, '
            'status, '
            'data_publicacao',
      )
          .eq(
        'status',
        'aprovada',
      )
          .or(
        'titulo.ilike.%$valor%,'
            'descricao.ilike.%$valor%,'
            'autor.ilike.%$valor%,'
            'instituicao.ilike.%$valor%,'
            'area.ilike.%$valor%,'
            'categoria.ilike.%$valor%,'
            'palavras_chave.ilike.%$valor%',
      )
          .order(
        'data_publicacao',
        ascending: false,
      );

      final lista =
      List<Map<String, dynamic>>.from(
        resposta,
      );

      if (!mounted) return;

      setState(() {
        _obras = lista;
        _paginaAtual = 1;
        _carregando = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = true;
        _mensagemErro = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = true;
        _mensagemErro = e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ==========================================================
  // PAGINAÇÃO
  // ==========================================================

  int get _totalPaginas {
    if (_obras.isEmpty) {
      return 1;
    }

    return (_obras.length / _obrasPorPagina)
        .ceil();
  }

  List<Map<String, dynamic>>
  get _obrasDaPagina {
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

  void _alterarPagina(int pagina) {
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
  // ABRIR DETALHES DA OBRA
  // ==========================================================

  void _abrirObra(
      Map<String, dynamic> obra,
      ) {
    final id =
        obra['id']?.toString().trim() ?? '';

    if (id.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return ObraDetalhesDialog(
          id: id,
        );
      },
    );
  }

  // ==========================================================
  // CARTÃO DA OBRA
  // ==========================================================

  Widget _cartaoObra(
      Map<String, dynamic> obra,
      ) {
    final titulo =
        obra['titulo']?.toString() ?? '';

    final descricao =
        obra['descricao']?.toString() ?? '';

    final autor =
        obra['autor']?.toString() ?? '';

    final categoria =
        obra['categoria']?.toString() ?? '';

    final instituicao =
        obra['instituicao']?.toString() ?? '';

    final area =
        obra['area']?.toString() ?? '';

    final ano =
        obra['ano_obra']?.toString() ?? '';

    final dataPublicacao =
        obra['data_publicacao']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                const EdgeInsets.only(
                  top: 3,
                  right: 8,
                ),
                child: Icon(
                  Icons.public,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ),

              Expanded(
                child: InkWell(
                  onTap: () {
                    _abrirObra(obra);
                  },
                  borderRadius:
                  BorderRadius.circular(4),
                  child: Text(
                    titulo,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.w600,
                      height: 1.3,
                      color: Colors.blue,
                      decoration:
                      TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (descricao.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              descricao,
              maxLines: 3,
              overflow:
              TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.black54,
              ),
            ),
          ],

          if (autor.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              autor,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ],

          if (instituicao.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              instituicao,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],

          if (area.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              area,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],

          if (categoria.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              categoria,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],

          if (ano.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Ano da obra: $ano',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ],

          if (dataPublicacao.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Publicado em '
                  '${_formatarData(dataPublicacao)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String _formatarData(
      String valor,
      ) {
    final data =
    DateTime.tryParse(valor);

    if (data == null) {
      return valor;
    }

    final dia =
    data.day.toString().padLeft(2, '0');

    final mes =
    data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pesquisa: ${widget.query}',
        ),
      ),

      body: _carregando
          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : _erro
          ? Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                _mensagemErro.isEmpty
                    ? 'Não foi possível realizar a pesquisa.'
                    : _mensagemErro,
                textAlign:
                TextAlign.center,
              ),

              const SizedBox(
                height: 16,
              ),

              OutlinedButton(
                onPressed: _pesquisar,
                child:
                const Text(
                  'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      )

          : _obras.isEmpty
          ? Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .search_off_outlined,
                size: 50,
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                'Nenhum resultado encontrado para "${widget.query}".',
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 17,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Tente pesquisar por outro título, autor, tema ou categoria.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color: Colors
                      .grey
                      .shade600,
                ),
              ),
            ],
          ),
        ),
      )

          : RefreshIndicator(
        onRefresh: _pesquisar,
        child: ListView(
          padding:
          const EdgeInsets.all(
            16,
          ),
          children: [
            const Text(
              'Resultados da pesquisa',
              style:
              TextStyle(
                fontSize: 24,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              '${_obras.length} resultado(s) encontrado(s) para "${widget.query}"',
              style:
              TextStyle(
                fontSize: 14,
                color: Colors
                    .grey
                    .shade600,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ..._obrasDaPagina.map(
              _cartaoObra,
            ),

            if (_totalPaginas > 1)
              PaginacaoGoogleWidget(
                paginaAtual:
                _paginaAtual,
                totalPaginas:
                _totalPaginas,
                onPaginaAlterada:
                _alterarPagina,
              ),
          ],
        ),
      ),
    );
  }
}

