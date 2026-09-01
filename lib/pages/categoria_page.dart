import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dados/obras_recentes.dart';
import '../widgets/obra_detalhes_dialog.dart';
import '../widgets/paginacao_google_widget.dart';
import '../widgets/cartao_obra_widget.dart';

class CategoriaPage extends StatefulWidget {
  final String tipo;

  const CategoriaPage({
    super.key,
    required this.tipo,
  });

  @override
  State<CategoriaPage> createState() => _CategoriaPageState();
}

class _CategoriaPageState extends State<CategoriaPage> {
  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ==========================================================
  // DADOS
  // ==========================================================

  List<Map<String, dynamic>> _obras = [];

  bool _carregando = true;
  bool _erro = false;

  String _mensagemErro = '';

  // ==========================================================
  // PAGINAÇÃO
  // ==========================================================

  int _paginaAtual = 1;

  static const int _obrasPorPagina = 10;

  // ==========================================================
  // CICLO DE VIDA
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _carregarObras();
  }

  // ==========================================================
  // CARREGAR OBRAS
  // ==========================================================

  Future<void> _carregarObras() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = false;
      _mensagemErro = '';
    });

    try {
      final categoria =
      _normalizarCategoria(widget.tipo);

      final response = await _supabase
          .from('obras')
          .select(
        'id, '
            'titulo, '
            'descricao, '
            'autor, '
            'coautores, '
            'categoria, '
            'caminho_arquivo, '
            'url_documento, '
            'status, '
            'data_publicacao, '
            'ano_obra',
      )
          .eq(
        'status',
        'aprovada',
      )
          .eq(
        'categoria',
        categoria,
      )
          .order(
        'data_publicacao',
        ascending: false,
      );

      final lista =
      List<Map<String, dynamic>>.from(
        response,
      );

      if (!mounted) return;

      setState(() {
        _obras = lista;
        _paginaAtual = 1;
        _carregando = false;
        _erro = false;
        _mensagemErro = '';
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;

      setState(() {
        _obras = [];
        _carregando = false;
        _erro = true;
        _mensagemErro = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _obras = [];
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
  // NORMALIZAR CATEGORIA
  // ==========================================================

  String _normalizarCategoria(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'doutoramento':
        return 'Tese de Doutoramento';

      case 'mestrado':
        return 'Dissertação de Mestrado';

      case 'monografia':
        return 'Monografia';

      case 'artigos':
        return 'Artigos Científicos';

      case 'literatura':
        return 'Literatura';

      default:
        return tipo;
    }
  }

  // ==========================================================
  // PAGINAÇÃO
  // ==========================================================

  int get _totalPaginas {
    if (_obras.isEmpty) {
      return 1;
    }

    return (_obras.length / _obrasPorPagina).ceil();
  }

  List<Map<String, dynamic>> get _obrasDaPagina {
    final inicio =
        (_paginaAtual - 1) *
            _obrasPorPagina;

    if (inicio >= _obras.length) {
      return [];
    }

    final fim =
    (inicio + _obrasPorPagina).clamp(
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
  // MOSTRAR DETALHES
  // ==========================================================

  void _mostrarDetalhes(
      BuildContext context,
      Map<String, dynamic> obra,
      ) {
    final id =
        obra['id']?.toString().trim() ?? '';

    if (id.isEmpty) {
      _mostrarMensagem(
        'Não foi possível identificar esta obra.',
      );

      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) {
        return ObraDetalhesDialog(
          id: id,
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
          content: Text(mensagem),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // CONVERTER MAP PARA OBRA RECENTE
  // ==========================================================

  ObraRecente _converterParaObraRecente(
      Map<String, dynamic> obra,
      ) {
    return ObraRecente.fromMap({
      'id': obra['id'],
      'titulo': obra['titulo'],
      'resumo': obra['descricao'],
      'autor': obra['autor'],
      'coautores':
      obra['coautores'] ?? '',
      'categoria':
      obra['categoria'],
      'urlDocumento':
      obra['url_documento'],
      'dataPublicacao':
      obra['data_publicacao'],
      'status':
      obra['status'],
      'anoObra':
      obra['ano_obra'],
    });
  }

  // ==========================================================
  // CARTÃO PADRÃO DA OBRA
  //
  // Usa exatamente o mesmo CartaoObraWidget
  // utilizado pela Vitrine/Home.
  // ==========================================================

  Widget _construirCartaoObra(
      Map<String, dynamic> obra,
      ) {
    final obraRecente =
    _converterParaObraRecente(
      obra,
    );

    return CartaoObraWidget(
      obra: obraRecente,
    );
  }

  // ==========================================================
  // ESTADO DE ERRO
  // ==========================================================

  Widget _construirErro() {
    return Center(
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
                  ? 'Não foi possível carregar as obras.'
                  : _mensagemErro,
              textAlign:
              TextAlign.center,
            ),

            const SizedBox(
              height: 16,
            ),

            OutlinedButton(
              onPressed:
              _carregarObras,
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
  // SEM OBRAS
  // ==========================================================

  Widget _construirSemObras(
      String categoria,
      ) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.library_books_outlined,
              size: 50,
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              'Ainda não existem obras aprovadas em $categoria.',
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // LISTA DE OBRAS
  // ==========================================================

  Widget _construirLista(
      String categoria,
      ) {
    return RefreshIndicator(
      onRefresh:
      _carregarObras,

      child: ListView(
        padding:
        const EdgeInsets.all(16),

        children: [
          // ==================================================
          // TÍTULO DA CATEGORIA
          // ==================================================

          Text(
            categoria,
            style: const TextStyle(
              fontSize: 24,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          // ==================================================
          // QUANTIDADE
          // ==================================================

          Text(
            '${_obras.length} obra(s) aprovada(s)',
            style: TextStyle(
              fontSize: 14,
              color:
              Colors.grey.shade600,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // ==================================================
          // CARTÕES PADRÃO
          // ==================================================

          ..._obrasDaPagina.map(
            _construirCartaoObra,
          ),

          // ==================================================
          // PAGINAÇÃO
          // ==================================================

          if (_totalPaginas > 1) ...[
            const SizedBox(
              height: 10,
            ),

            PaginacaoGoogleWidget(
              paginaAtual:
              _paginaAtual,
              totalPaginas:
              _totalPaginas,
              onPaginaAlterada:
              _alterarPagina,
            ),
          ],

          const SizedBox(
            height: 20,
          ),
        ],
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
    final categoria =
    _normalizarCategoria(
      widget.tipo,
    );

    return Scaffold(
      backgroundColor:
      const Color(0xFFF7F8FA),

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        title: Text(
          categoria,
          style: const TextStyle(
            fontWeight:
            FontWeight.w600,
          ),
        ),

        elevation: 0,

        backgroundColor:
        Colors.white,

        foregroundColor:
        Colors.black87,
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: _carregando
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _erro
          ? _construirErro()
          : _obras.isEmpty
          ? _construirSemObras(
        categoria,
      )
          : _construirLista(
        categoria,
      ),
    );
  }
}

