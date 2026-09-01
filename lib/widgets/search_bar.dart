import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    this.onSearch,
    this.hintText = 'Pesquisar trabalhos, autores ou temas...',
    this.initialQuery = '',
  });

  /// Quando definido, a pesquisa é entregue diretamente ao componente pai.
  /// Quando não definido, mantém o comportamento da Home:
  /// navegar para /search/:query.
  final ValueChanged<String>? onSearch;

  final String hintText;
  final String initialQuery;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialQuery,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pesquisar() {
    final pesquisa = _controller.text.trim();

    if (pesquisa.isEmpty) {
      return;
    }

    if (widget.onSearch != null) {
      widget.onSearch!(pesquisa);
      return;
    }

    context.push(
      '/search/${Uri.encodeComponent(pesquisa)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        final largura = constraints.maxWidth;

        final double larguraBarra;

        if (largura < 600) {
          larguraBarra = largura - 32;
        } else if (largura < 1000) {
          larguraBarra = largura - 80;
        } else {
          larguraBarra = 700;
        }

        return Center(
          child: SizedBox(
            width: larguraBarra,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    _pesquisar();
                  },
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
