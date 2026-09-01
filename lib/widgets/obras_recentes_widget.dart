import 'package:flutter/material.dart';

import '../dados/obras_recentes.dart';
import '../repositorios/obras_recentes_repository.dart';
import 'cartao_obra_widget.dart';

class ObrasRecentesWidget extends StatefulWidget {
  final int quantidade;

  const ObrasRecentesWidget({
    super.key,
    this.quantidade = 10,
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
  // CONTEÚDO
  // ==========================================================

  Widget _construirConteudo() {
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
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              const Text(
                'Não foi possível carregar as obras.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _carregarObras,
                icon: const Icon(
                  Icons.refresh,
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
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              const Text(
                'Nenhuma obra recente encontrada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _obras.length; i++) ...[
          CartaoObraWidget(
            obra: _obras[i],
          ),
          if (i < _obras.length - 1)
            const SizedBox(height: 18),
        ],
      ],
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

