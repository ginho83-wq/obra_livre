import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../repositorios/acervo_repository.dart';
import '../services/seo_service.dart';

class ObraDetalhesPage extends StatefulWidget {
  final String id;

  const ObraDetalhesPage({
    super.key,
    required this.id,
  });

  @override
  State<ObraDetalhesPage> createState() => _ObraDetalhesPageState();
}

class _ObraDetalhesPageState extends State<ObraDetalhesPage> {
  final AcervoRepository _repository = AcervoRepository.instancia;

  AcervoObra? _obra;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarObra();
  }

  @override
  void dispose() {
    SeoService.limpar();
    super.dispose();
  }

  // ==========================================================
  // CARREGAR OBRA
  // ==========================================================

  Future<void> _carregarObra() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final obra = await _repository.carregarObraPorId(widget.id);

      if (!mounted) return;

      if (obra == null) {
        SeoService.limpar();

        setState(() {
          _obra = null;
          _carregando = false;
          _erro = 'Obra não encontrada.';
        });

        return;
      }

      setState(() {
        _obra = obra;
        _carregando = false;
      });

      // ========================================================
      // SEO DA OBRA INDIVIDUAL
      // ========================================================

      final url =
          'https://ginho83-wq.github.io'
          '/obra_livre/obra/${obra.id}/';

      SeoService.definirObra(
        titulo: obra.titulo,
        descricao: obra.descricao,
        autor: obra.autor,
        categoria: obra.categoria,
        ano: obra.anoObra,
        url: url,
      );

      // ========================================================
      // REGISTAR VISUALIZAÇÃO
      // ========================================================

      await _repository.registarVisualizacao(obra.id);
    } catch (e) {
      if (!mounted) return;

      SeoService.limpar();

      setState(() {
        _obra = null;
        _carregando = false;
        _erro = 'Não foi possível carregar a obra.';
      });
    }
  }

  // ==========================================================
  // ABRIR DOCUMENTO PDF
  // ==========================================================

  Future<void> _abrirDocumento() async {
    final obra = _obra;

    if (obra == null || obra.urlDocumento.trim().isEmpty) {
      return;
    }

    final uri = Uri.tryParse(
      obra.urlDocumento.trim(),
    );

    if (uri == null) {
      return;
    }

    final sucesso = await launchUrl(
      uri,
      webOnlyWindowName: '_blank',
    );

    if (!sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o documento.',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // DESCRIÇÃO
  // ==========================================================

  String _descricao(String texto) {
    final palavras = texto.trim().split(RegExp(r'\s+'));

    const limite = 80;

    if (palavras.length <= limite) {
      return texto.trim();
    }

    return '${palavras.take(limite).join(' ')}...';
  }

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obra Livre'),
      ),
      body: _construirConteudo(),
    );
  }

  // ==========================================================
  // CONTEÚDO
  // ==========================================================

  Widget _construirConteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_erro != null || _obra == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _erro ?? 'Obra não encontrada.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _carregarObra,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final obra = _obra!;

    return SelectionArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // TÍTULO
                    // ==================================================

                    Text(
                      obra.titulo,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // AUTOR
                    // ==================================================

                    _campo(
                      'Autor',
                      obra.autor,
                    ),

                    // ==================================================
                    // COAUTORES
                    // ==================================================

                    if (obra.coautores.trim().isNotEmpty)
                      _campo(
                        'Coautores',
                        obra.coautores,
                      ),

                    // ==================================================
                    // CATEGORIA
                    // ==================================================

                    _campo(
                      'Categoria',
                      obra.categoria,
                    ),

                    // ==================================================
                    // ANO
                    // ==================================================

                    if (obra.anoObra != null)
                      _campo(
                        'Ano',
                        obra.anoObra.toString(),
                      ),

                    // ==================================================
                    // DATA DE PUBLICAÇÃO
                    // ==================================================

                    if (obra.dataPublicacao != null)
                      _campo(
                        'Data de publicação',
                        _formatarData(
                          obra.dataPublicacao!,
                        ),
                      ),

                    const Divider(
                      height: 32,
                    ),

                    // ==================================================
                    // DESCRIÇÃO
                    // ==================================================

                    Text(
                      'Descrição',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _descricao(obra.descricao),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge,
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // BOTÃO ABRIR DOCUMENTO
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _abrirDocumento,
                        icon: const Icon(
                          Icons.open_in_new,
                        ),
                        label: const Text(
                          'Abrir documento',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CAMPO DE INFORMAÇÃO
  // ==========================================================

  Widget _campo(
      String titulo,
      String valor,
      ) {
    if (valor.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          children: [
            TextSpan(
              text: '$titulo: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: valor,
            ),
          ],
        ),
      ),
    );
  }
}
