import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dados/obras_recentes.dart';
import '../repositorios/obras_repository.dart';
import '../widgets/cartao_obra_widget.dart';
import '../widgets/paginacao_google_widget.dart';

// ==========================================================
// PUBLICAÇÕES PAGE
// ==========================================================

class PublicacoesPage extends StatefulWidget {
  final String? status;

  const PublicacoesPage({
    super.key,
    this.status,
  });

  @override
  State<PublicacoesPage> createState() => _PublicacoesPageState();
}

// ==========================================================
// STATE
// ==========================================================

class _PublicacoesPageState extends State<PublicacoesPage> {
  List<ObraRecente> _publicacoes = [];

  bool _carregando = true;
  bool _erro = false;

  String _mensagemErro = '';

  // ========================================================
  // PAGINAÇÃO
  // ========================================================

  static const int _obrasPorPagina = 10;

  int _paginaAtual = 1;

  // ========================================================
  // INIT
  // ========================================================

  @override
  void initState() {
    super.initState();
    _carregarPublicacoes();
  }

  // ========================================================
  // FILTRO
  // ========================================================

  String? get _statusFiltro {
    final valor = widget.status?.trim().toLowerCase();

    if (valor == null || valor.isEmpty) {
      return null;
    }

    return valor;
  }

  // ========================================================
  // TOTAL DE PÁGINAS
  // ========================================================

  int get _totalPaginas {
    if (_publicacoes.isEmpty) {
      return 1;
    }

    return (_publicacoes.length / _obrasPorPagina).ceil();
  }

  // ========================================================
  // PUBLICAÇÕES DA PÁGINA ATUAL
  // ========================================================

  List<ObraRecente> get _publicacoesDaPagina {
    if (_publicacoes.isEmpty) {
      return [];
    }

    final inicio =
        (_paginaAtual - 1) * _obrasPorPagina;

    if (inicio >= _publicacoes.length) {
      return [];
    }

    final fim =
    (inicio + _obrasPorPagina)
        .clamp(0, _publicacoes.length);

    return _publicacoes.sublist(
      inicio,
      fim,
    );
  }

  // ========================================================
  // ALTERAR PÁGINA
  // ========================================================

  void _alterarPagina(int pagina) {
    if (pagina < 1 || pagina > _totalPaginas) {
      return;
    }

    if (pagina == _paginaAtual) {
      return;
    }

    setState(() {
      _paginaAtual = pagina;
    });
  }

  // ========================================================
  // CARREGAR PUBLICAÇÕES
  // ========================================================

  Future<void> _carregarPublicacoes() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _carregando = true;
      _erro = false;
      _mensagemErro = '';
    });

    try {
      final usuario =
          Supabase.instance.client.auth.currentUser;

      // ====================================================
      // VERIFICAR LOGIN
      // ====================================================

      if (usuario == null) {
        if (!mounted) {
          return;
        }

        context.go('/login');
        return;
      }

      // ====================================================
      // CARREGAR PUBLICAÇÕES
      // ====================================================

      final publicacoes =
      await ObrasRepository.instancia
          .carregarMinhasPublicacoes();

      if (!mounted) {
        return;
      }

      // ====================================================
      // APLICAR FILTRO
      // ====================================================

      final filtradas =
      _filtrarPublicacoes(publicacoes);

      // ====================================================
      // ORDENAR
      // MAIS RECENTE -> MAIS ANTIGA
      // ====================================================

      filtradas.sort(
            (a, b) {
          final dataA =
          DateTime.tryParse(a.dataPublicacao);

          final dataB =
          DateTime.tryParse(b.dataPublicacao);

          if (dataA == null && dataB == null) {
            return 0;
          }

          if (dataA == null) {
            return 1;
          }

          if (dataB == null) {
            return -1;
          }

          return dataB.compareTo(dataA);
        },
      );

      // ====================================================
      // CORRIGIR PÁGINA
      // ====================================================

      final totalPaginas =
      filtradas.isEmpty
          ? 1
          : (filtradas.length /
          _obrasPorPagina)
          .ceil();

      var pagina = _paginaAtual;

      if (pagina > totalPaginas) {
        pagina = totalPaginas;
      }

      setState(() {
        _publicacoes = filtradas;
        _paginaAtual = pagina;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

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

  // ========================================================
  // FILTRAR PUBLICAÇÕES
  // ========================================================

  List<ObraRecente> _filtrarPublicacoes(
      List<ObraRecente> publicacoes,
      ) {
    final filtro = _statusFiltro;

    // ======================================================
    // SEM FILTRO
    // ======================================================

    if (filtro == null) {
      return List<ObraRecente>.from(
        publicacoes,
      );
    }

    // ======================================================
    // COM FILTRO
    // ======================================================

    return publicacoes.where(
          (obra) {
        final status =
        obra.status
            .toLowerCase()
            .trim();

        switch (filtro) {
          case 'pendente':
          case 'pendentes':
            return status == 'pendente' ||
                status == 'pendentes';

          case 'publicada':
          case 'publicado':
          case 'aprovada':
          case 'aprovado':
            return status == 'publicada' ||
                status == 'publicado' ||
                status == 'aprovada' ||
                status == 'aprovado';

          case 'recusada':
          case 'recusado':
          case 'rejeitada':
          case 'rejeitado':
            return status == 'recusada' ||
                status == 'recusado' ||
                status == 'rejeitada' ||
                status == 'rejeitado';

          default:
            return true;
        }
      },
    ).toList();
  }

  // ========================================================
  // TÍTULO
  // ========================================================

  String get _tituloFiltro {
    switch (_statusFiltro) {
      case 'pendente':
      case 'pendentes':
        return 'Publicações pendentes';

      case 'publicada':
      case 'publicado':
      case 'aprovada':
      case 'aprovado':
        return 'Publicações publicadas';

      case 'recusada':
      case 'recusado':
      case 'rejeitada':
      case 'rejeitado':
        return 'Publicações recusadas';

      default:
        return 'Minhas publicações';
    }
  }

  // ========================================================
  // DESCRIÇÃO
  // ========================================================

  String get _descricaoFiltro {
    switch (_statusFiltro) {
      case 'pendente':
      case 'pendentes':
        return 'Obras que estão aguardando avaliação.';

      case 'publicada':
      case 'publicado':
      case 'aprovada':
      case 'aprovado':
        return 'Obras aprovadas e disponíveis na biblioteca.';

      case 'recusada':
      case 'recusado':
      case 'rejeitada':
      case 'rejeitado':
        return 'Obras que não foram aprovadas.';

      default:
        return 'Todas as suas publicações.';
    }
  }

  // ========================================================
  // BUILD
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ====================================================
      // APP BAR
      // ====================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        title: const Text(
          'Publicações',
          style: TextStyle(
            fontWeight: FontWeight.w500,
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

        actions: [
          TextButton(
            onPressed: () {
              context.push('/publicar');
            },
            child: const Text(
              'Publicar',
              style: TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
          ),

          const SizedBox(width: 10),
        ],
      ),

      // ====================================================
      // BODY
      // ====================================================

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 900,
          ),
          child: _buildConteudo(),
        ),
      ),
    );
  }

  // ========================================================
  // CONTEÚDO
  // ========================================================

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_erro) {
      return _buildErro();
    }

    if (_publicacoes.isEmpty) {
      return _buildVazio();
    }

    final publicacoesPagina =
        _publicacoesDaPagina;

    return RefreshIndicator(
      onRefresh: _carregarPublicacoes,

      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(
          24,
          30,
          24,
          40,
        ),

        children: [

          // ==================================================
          // TÍTULO
          // ==================================================

          Text(
            _tituloFiltro,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 7),

          // ==================================================
          // DESCRIÇÃO
          // ==================================================

          Text(
            _descricaoFiltro,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 28),

          // ==================================================
          // TOTAL DE PUBLICAÇÕES
          // ==================================================

          Text(
            '${_publicacoes.length} '
                '${_publicacoes.length == 1 ? 'publicação' : 'publicações'}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // CARTÕES
          // ==================================================

          for (final obra in publicacoesPagina)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 18,
              ),

              child: CartaoObraWidget(
                obra: obra,
              ),
            ),

          // ==================================================
          // PAGINAÇÃO
          //
          // APARECE SOMENTE QUANDO EXISTIR
          // MAIS DE UMA PÁGINA
          // ==================================================

          if (_totalPaginas > 1)
            PaginacaoGoogleWidget(
              paginaAtual: _paginaAtual,
              totalPaginas: _totalPaginas,
              onPaginaAlterada: _alterarPagina,
            ),
        ],
      ),
    );
  }

  // ========================================================
  // ERRO
  // ========================================================

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [

            Icon(
              Icons.error_outline,
              size: 45,
              color: Colors.grey.shade600,
            ),

            const SizedBox(height: 12),

            Text(
              _mensagemErro.isEmpty
                  ? 'Não foi possível carregar as suas publicações.'
                  : _mensagemErro,

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton(
              onPressed:
              _carregarPublicacoes,

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
  // VAZIO
  // ========================================================

  Widget _buildVazio() {
    final temFiltro =
        _statusFiltro != null &&
            _statusFiltro!.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [

            Icon(
              temFiltro
                  ? Icons.filter_alt_off_outlined
                  : Icons.library_books_outlined,

              size: 55,

              color:
              Theme.of(context)
                  .colorScheme
                  .primary,
            ),

            const SizedBox(height: 16),

            Text(
              temFiltro
                  ? 'Não existem publicações nesta categoria.'
                  : 'Você ainda não possui publicações.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              temFiltro
                  ? 'Quando houver obras nesta categoria, elas aparecerão aqui.'
                  : 'Publique uma obra para ela aparecer aqui.',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 22),

            if (!temFiltro)
              TextButton(
                onPressed: () {
                  context.push('/publicar');
                },

                child: const Text(
                  'Publicar uma obra',
                ),
              )
            else
              TextButton(
                onPressed: () {
                  context.go(
                    '/publicacoes',
                  );
                },

                child: const Text(
                  'Ver todas as publicações',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
