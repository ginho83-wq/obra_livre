import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../dados/obras_recentes.dart';
import '../repositorios/obras_recentes_repository.dart';

class ObrasRecentesWidget extends StatefulWidget {
  final int quantidade;

  const ObrasRecentesWidget({
    super.key,
    this.quantidade = 4,
  });

  @override
  State<ObrasRecentesWidget> createState() =>
      _ObrasRecentesWidgetState();
}

class _ObrasRecentesWidgetState
    extends State<ObrasRecentesWidget> {
  final ObrasRecentesRepository _repository =
      ObrasRecentesRepository.instancia;

  List<ObraRecente> _obras = [];
  bool _carregando = true;
  String? _erro;

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
      _erro = null;
    });

    try {
      final obras =
      await _repository.carregarObrasRecentes();

      if (!mounted) return;

      final limite = widget.quantidade;

      setState(() {
        _obras = limite > 0
            ? obras.take(limite).toList()
            : obras;

        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _obras = [];
        _carregando = false;
        _erro = e.toString();
      });
    }
  }

  // ==========================================================
  // ABRIR OBRA
  // ==========================================================

  void _abrirObra(ObraRecente obra) {
    final id = obra.id.trim();

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível identificar esta obra.',
          ),
        ),
      );
      return;
    }

    final idCodificado = Uri.encodeComponent(id);
    context.go('/obra/$idCodificado');
  }

  // ==========================================================
  // ITEM DA LISTA
  // ==========================================================

  Widget _construirItemObra(ObraRecente obra) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final titulo = obra.titulo.trim().isNotEmpty
        ? obra.titulo.trim()
        : 'Sem título';

    final autor = obra.autor.trim();
    final categoria = obra.categoria.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrirObra(obra),
        borderRadius: BorderRadius.circular(8),
        hoverColor:
        colorScheme.onSurface.withValues(alpha: 0.035),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 4,
          ),
          child: Row(
            children: [
              // ==================================================
              // ÍCONE
              // ==================================================

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:
                  colorScheme.surfaceContainerHighest,
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // ==================================================
              // INFORMAÇÕES
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // TÍTULO
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                      theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),

                    // AUTOR
                    if (autor.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        autor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                        theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          height: 1.3,
                          color: theme
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.60),
                        ),
                      ),
                    ],

                    // CATEGORIA
                    if (categoria.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        categoria,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                        theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          height: 1.3,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CABEÇALHO
  // ==========================================================

  Widget _construirCabecalho() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Text(
        'Pesquise Também',
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ==========================================================
  // CONTEÚDO
  // ==========================================================

  Widget _construirConteudo() {
    final theme = Theme.of(context);

    // ========================================================
    // CARREGANDO
    // ========================================================

    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 40,
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ========================================================
    // ERRO
    // ========================================================

    if (_erro != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 40,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 44,
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.40),
              ),
              const SizedBox(height: 12),
              Text(
                'Não foi possível carregar as obras.',
                textAlign: TextAlign.center,
                style:
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _carregarObras,
                icon: const Icon(
                  Icons.refresh,
                  size: 18,
                ),
                label: const Text(
                  'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ========================================================
    // NENHUMA OBRA
    // ========================================================

    if (_obras.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 40,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 44,
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.40),
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhuma obra recente encontrada.',
                textAlign: TextAlign.center,
                style:
                theme.textTheme.bodyMedium?.copyWith(
                  color: theme
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.70),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ========================================================
    // LISTA
    // ========================================================

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 900,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            // TÍTULO DA SECÇÃO
            _construirCabecalho(),

            // OBRAS
            for (final obra in _obras)
              _construirItemObra(obra),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return _construirConteudo();
  }
}


