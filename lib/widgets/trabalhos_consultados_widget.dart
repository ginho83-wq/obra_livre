import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../repositorios/historico_consultas_repository.dart';

class TrabalhosConsultadosWidget extends StatefulWidget {
  final int quantidade;

  const TrabalhosConsultadosWidget({
    super.key,
    this.quantidade = 6,
  });

  @override
  State<TrabalhosConsultadosWidget> createState() =>
      _TrabalhosConsultadosWidgetState();
}

class _TrabalhosConsultadosWidgetState
    extends State<TrabalhosConsultadosWidget> {
  final HistoricoConsultasRepository _repository =
      HistoricoConsultasRepository.instancia;

  List<Map<String, dynamic>> _obras = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();

    _repository.addListener(_atualizar);
    _carregar();
  }

  @override
  void dispose() {
    _repository.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (!mounted) {
      return;
    }

    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final obras =
      await _repository.carregarObrasConsultadas(
        quantidade: widget.quantidade,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _obras = obras;
        _carregando = false;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _carregando = false;
        _erro = 'Não foi possível carregar o histórico.';
      });
    }
  }

  void _abrirObra(Map<String, dynamic> obra) {
    final id = obra['id']?.toString();

    if (id == null || id.isEmpty) {
      return;
    }

    context.push('/obra/$id');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

    if (_erro != null) {
      return const SizedBox.shrink();
    }

    if (_obras.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 900,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==================================================
            // TÍTULO DA SECÇÃO
            // ==================================================

            Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: Text(
                'Trabalhos consultados recentemente',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // ==================================================
            // LINHA ABAIXO DO TÍTULO
            // ==================================================

            Divider(
              height: 1,
              thickness: 1,
              color: theme.dividerColor.withValues(
                alpha: 0.65,
              ),
            ),

            // ==================================================
            // LISTA DOS TRABALHOS
            // ==================================================

            for (int i = 0; i < _obras.length; i++) ...[
              _construirItem(
                context,
                _obras[i],
              ),

              if (i < _obras.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.dividerColor.withValues(
                    alpha: 0.55,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirItem(
      BuildContext context,
      Map<String, dynamic> obra,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final titulo =
        obra['titulo']?.toString().trim() ?? 'Sem título';

    final autor =
        obra['autor']?.toString().trim() ?? '';

    final categoria =
        obra['categoria']?.toString().trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrirObra(obra),
        borderRadius: BorderRadius.circular(8),
        hoverColor: colorScheme.onSurface.withValues(
          alpha: 0.035,
        ),
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
                  color: colorScheme.surfaceContainerHighest,
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
                    Text(
                      titulo.isNotEmpty
                          ? titulo
                          : 'Sem título',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                      theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),

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

              const SizedBox(width: 8),

              // ==================================================
              // SETA
              // ==================================================

              Icon(
                Icons.chevron_right,
                color: theme.iconTheme.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
