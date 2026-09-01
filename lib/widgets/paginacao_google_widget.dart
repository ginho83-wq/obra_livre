

import 'package:flutter/material.dart';

class PaginacaoGoogleWidget extends StatelessWidget {
  final int paginaAtual;
  final int totalPaginas;
  final ValueChanged<int> onPaginaAlterada;

  const PaginacaoGoogleWidget({
    super.key,
    required this.paginaAtual,
    required this.totalPaginas,
    required this.onPaginaAlterada,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPaginas <= 1) {
      return const SizedBox.shrink();
    }

    final paginas = _gerarPaginas();

    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 28,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ANTERIOR
          _BotaoNavegacao(
            icone: Icons.chevron_left,
            habilitado: paginaAtual > 1,
            tooltip: 'Página anterior',
            onPressed: paginaAtual > 1
                ? () => onPaginaAlterada(paginaAtual - 1)
                : null,
          ),

          const SizedBox(width: 4),

          // PÁGINAS
          ...paginas.map((pagina) {
            if (pagina == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                child: Text(
                  '…',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              );
            }

            final selecionada = pagina == paginaAtual;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: selecionada
                    ? null
                    : () => onPaginaAlterada(pagina),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selecionada
                        ? Theme.of(context)
                        .colorScheme
                        .primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pagina',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selecionada
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selecionada
                          ? Theme.of(context)
                          .colorScheme
                          .onPrimary
                          : Theme.of(context)
                          .colorScheme
                          .primary,
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 4),

          // PRÓXIMA
          _BotaoNavegacao(
            icone: Icons.chevron_right,
            habilitado: paginaAtual < totalPaginas,
            tooltip: 'Próxima página',
            onPressed: paginaAtual < totalPaginas
                ? () => onPaginaAlterada(paginaAtual + 1)
                : null,
          ),
        ],
      ),
    );
  }

  List<int?> _gerarPaginas() {
    if (totalPaginas <= 7) {
      return List<int?>.generate(
        totalPaginas,
            (index) => index + 1,
      );
    }

    final List<int?> resultado = [];

    // Primeira página
    resultado.add(1);

    if (paginaAtual <= 4) {
      resultado.add(2);
      resultado.add(3);
      resultado.add(4);
      resultado.add(5);
      resultado.add(null);
      resultado.add(totalPaginas);
      return resultado;
    }

    if (paginaAtual >= totalPaginas - 3) {
      resultado.add(null);
      resultado.add(totalPaginas - 4);
      resultado.add(totalPaginas - 3);
      resultado.add(totalPaginas - 2);
      resultado.add(totalPaginas - 1);
      resultado.add(totalPaginas);
      return resultado;
    }

    resultado.add(null);
    resultado.add(paginaAtual - 1);
    resultado.add(paginaAtual);
    resultado.add(paginaAtual + 1);
    resultado.add(null);
    resultado.add(totalPaginas);

    return resultado;
  }
}

class _BotaoNavegacao extends StatelessWidget {
  final IconData icone;
  final bool habilitado;
  final String tooltip;
  final VoidCallback? onPressed;

  const _BotaoNavegacao({
    required this.icone,
    required this.habilitado,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: habilitado ? onPressed : null,
      icon: Icon(
        icone,
        size: 25,
      ),
    );
  }
}


