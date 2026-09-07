import 'package:flutter/material.dart';

import '../../repositorios/obras_pendentes_repository.dart';
import '../widgets/obra_detalhes_dialog.dart';
import '../widgets/paginacao_google_widget.dart';

class AdminSearchResultsPage extends StatefulWidget {
  final String query;

  const AdminSearchResultsPage({
    super.key,
    required this.query,
  });

  @override
  State<AdminSearchResultsPage> createState() =>
      _AdminSearchResultsPageState();
}

class _AdminSearchResultsPageState
    extends State<AdminSearchResultsPage> {
  final ObrasPendentesRepository _repository =
      ObrasPendentesRepository.instancia;

  List<Map<String, dynamic>> _obras = [];

  bool _carregando = true;
  bool _erro = false;

  String _mensagemErro = '';

  int _paginaAtual = 1;

  static const int _obrasPorPagina = 10;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _pesquisar();
  }

  // ==========================================================
  // PESQUISAR
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

      final resultado =
      await _repository.carregarObrasPublicadas(
        pesquisa: pesquisa,
      );

      if (!mounted) return;

      setState(() {
        _obras = resultado;
        _paginaAtual = 1;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = true;
        _mensagemErro = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ==========================================================
  // LIMITAR TÍTULO NA CONFIRMAÇÃO
  // ==========================================================

  String _limitarPalavras(
      String texto, {
        int limite = 10,
      }) {
    final palavras = texto
        .trim()
        .split(RegExp(r'\s+'))
        .where((palavra) => palavra.isNotEmpty)
        .toList();

    if (palavras.length <= limite) {
      return texto.trim();
    }

    return '${palavras.take(limite).join(' ')}...';
  }

  // ==========================================================
  // TOTAL DE PÁGINAS
  // ==========================================================

  int get _totalPaginas {
    if (_obras.isEmpty) {
      return 1;
    }

    return (_obras.length / _obrasPorPagina).ceil();
  }

  // ==========================================================
  // OBRAS DA PÁGINA
  // ==========================================================

  List<Map<String, dynamic>> get _obrasDaPagina {
    final inicio =
        (_paginaAtual - 1) * _obrasPorPagina;

    if (inicio >= _obras.length) {
      return [];
    }

    final fim = (inicio + _obrasPorPagina).clamp(
      0,
      _obras.length,
    );

    return _obras.sublist(
      inicio,
      fim,
    );
  }

  // ==========================================================
  // PAGINAÇÃO
  // ==========================================================

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
    final id = obra['id']?.toString().trim();

    if (id == null || id.isEmpty) {
      _mostrarMensagem(
        'ID da obra não encontrado.',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return ObraDetalhesDialog(
          id: id,
          modoExclusao: true,
          onExcluir: () => _excluirObra(obra),
        );
      },
    );
  }

  // ==========================================================
  // EXCLUIR OBRA
  // ==========================================================

  Future<void> _excluirObra(
      Map<String, dynamic> obra,
      ) async {
    final id = obra['id']?.toString();

    if (id == null || id.isEmpty) {
      _mostrarMensagem(
        'ID da obra não encontrado.',
      );
      return;
    }

    final tituloOriginal =
        obra['titulo']?.toString().trim() ?? 'esta obra';

    // Limita o título para impedir que o diálogo
    // aumente demasiado de largura.
    final titulo = _limitarPalavras(
      tituloOriginal,
      limite: 10,
    );

    // ========================================================
    // FECHAR O DETALHES DIALOG
    // ========================================================

    if (mounted) {
      Navigator.of(context).pop();
    }

    // ========================================================
    // CONFIRMAÇÃO DE EXCLUSÃO
    // ========================================================

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          // SEM BORDER RADIUS NO DIÁLOGO
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),

          // LARGURA CONTROLADA DO DIÁLOGO
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),

          // ESPAÇAMENTO DO TÍTULO
          titlePadding: const EdgeInsets.fromLTRB(
            24,
            16,
            8,
            0,
          ),

          // ==================================================
          // TÍTULO + X NO CANTO SUPERIOR DIREITO
          // ==================================================

          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Excluir obra',
                ),
              ),

              IconButton(
                tooltip: 'Fechar',
                icon: const Icon(
                  Icons.close,
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          ),

          // ==================================================
          // INFORMAÇÃO DE CONFIRMAÇÃO
          // ==================================================

          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: Text(
              'Tem certeza que deseja excluir '
                  'a obra "$titulo"?\n\n'
                  'O PDF e o registro da obra serão '
                  'removidos permanentemente.',
            ),
          ),

          // ==================================================
          // BOTÕES
          // ==================================================

          actions: [
            // ==================================================
            // BOTÃO CANCELAR
            // ==================================================

            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.grey.shade800,

                // BORDER RADIUS
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),

                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),

            // ==================================================
            // BOTÃO EXCLUIR
            // ==================================================

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,

                // BORDER RADIUS
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),

                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Excluir',
              ),
            ),
          ],
        );
      },
    );

    // ========================================================
    // CANCELADO
    // ========================================================

    if (confirmar != true) {
      return;
    }

    // ========================================================
    // EXCLUSÃO
    // ========================================================

    try {
      _mostrarCarregandoDialog(
        'A excluir obra...',
      );

      await _repository.excluirObra(id);

      if (!mounted) return;

      // Fecha somente o diálogo de carregamento.
      Navigator.of(context).pop();

      _mostrarMensagem(
        'Obra excluída com sucesso.',
      );

      // Atualiza os resultados da pesquisa.
      await _pesquisar();
    } catch (e) {
      if (mounted) {
        // Fecha somente o diálogo de carregamento.
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
  // DIALOG DE CARREGAMENTO
  // ==========================================================

  void _mostrarCarregandoDialog(
      String mensagem,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),

              const SizedBox(
                width: 20,
              ),

              Expanded(
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
          content: Text(
            mensagem,
          ),
        ),
      );
  }

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String _formatarData(
      dynamic valor,
      ) {
    if (valor == null) {
      return '';
    }

    try {
      final data = DateTime.parse(
        valor.toString(),
      );

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
  // CARD DA OBRA
  // ==========================================================

  Widget _buildObraCard(
      Map<String, dynamic> obra,
      ) {
    final titulo =
        obra['titulo']?.toString() ??
            'Sem título';

    final autor =
        obra['autor']?.toString() ??
            '';

    final categoria =
        obra['categoria']?.toString() ??
            '';

    final instituicao =
        obra['instituicao']?.toString() ??
            '';

    final area =
        obra['area']?.toString() ??
            '';

    final ano =
        obra['ano_obra']?.toString() ??
            '';

    final descricao =
        obra['descricao']?.toString() ??
            '';

    final data = _formatarData(
      obra['data_publicacao'],
    );

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ==================================================
          // TÍTULO CLICÁVEL
          // ==================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
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

          // ==================================================
          // DESCRIÇÃO
          // ==================================================

          if (descricao.isNotEmpty) ...[
            const SizedBox(
              height: 7,
            ),
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

          // ==================================================
          // AUTOR
          // ==================================================

          if (autor.isNotEmpty) ...[
            const SizedBox(
              height: 7,
            ),
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

          // ==================================================
          // INSTITUIÇÃO
          // ==================================================

          if (instituicao.isNotEmpty) ...[
            const SizedBox(
              height: 4,
            ),
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

          // ==================================================
          // ÁREA
          // ==================================================

          if (area.isNotEmpty) ...[
            const SizedBox(
              height: 4,
            ),
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

          // ==================================================
          // CATEGORIA
          // ==================================================

          if (categoria.isNotEmpty) ...[
            const SizedBox(
              height: 4,
            ),
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

          // ==================================================
          // ANO
          // ==================================================

          if (ano.isNotEmpty) ...[
            const SizedBox(
              height: 3,
            ),
            Text(
              'Ano da obra: $ano',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ],

          // ==================================================
          // DATA
          // ==================================================

          if (data.isNotEmpty) ...[
            const SizedBox(
              height: 3,
            ),
            Text(
              'Publicado em $data',
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
  // BUILD
  // ==========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
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
          const EdgeInsets.all(
            24,
          ),
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
                onPressed:
                _pesquisar,
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
                'Nenhuma obra publicada encontrada para "${widget.query}".',
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

              const SizedBox(
                height: 24,
              ),

              OutlinedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop();
                },
                child:
                const Text(
                  'Cancelar',
                ),
              ),
            ],
          ),
        ),
      )

          : RefreshIndicator(
        onRefresh: _pesquisar,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(
            24,
          ),
          children: [
            const Text(
              'Resultados da pesquisa',
              style: TextStyle(
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
              style: TextStyle(
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
              _buildObraCard,
            ),

            if (_totalPaginas > 1)
              Padding(
                padding:
                const EdgeInsets.only(
                  top: 8,
                  bottom: 20,
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
        ),
      ),
    );
  }
}
