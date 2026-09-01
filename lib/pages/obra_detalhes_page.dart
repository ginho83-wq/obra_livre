import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../repositorios/acervo_repository.dart';

class ObraDetalhesPage extends StatefulWidget {
  final String id;

  const ObraDetalhesPage({
    super.key,
    required this.id,
  });

  @override
  State<ObraDetalhesPage> createState() =>
      _ObraDetalhesPageState();
}

class _ObraDetalhesPageState extends State<ObraDetalhesPage> {
  final AcervoRepository _repository =
      AcervoRepository.instancia;

  AcervoObra? _obra;

  bool _carregando = true;

  String? _erro;

  @override
  void initState() {
    super.initState();

    _carregarObra();
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
      final obra =
      await _repository.carregarObraPorId(
        widget.id,
      );

      if (!mounted) return;

      if (obra == null) {
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _obra = null;
        _carregando = false;
        _erro =
        'Não foi possível carregar a obra.';
      });
    }
  }

  // ==========================================================
  // ABRIR DOCUMENTO
  // ==========================================================

  Future<void> _abrirDocumento() async {
    final obra = _obra;

    if (obra == null ||
        obra.urlDocumento.trim().isEmpty) {
      _mostrarMensagem(
        'Documento não disponível.',
      );

      return;
    }

    final uri = Uri.tryParse(
      obra.urlDocumento.trim(),
    );

    if (uri == null) {
      _mostrarMensagem(
        'O endereço do documento é inválido.',
      );

      return;
    }

    try {
      final abriu = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!abriu) {
        _mostrarMensagem(
          'Não foi possível abrir o documento.',
        );
      }
    } catch (_) {
      _mostrarMensagem(
        'Não foi possível abrir o documento.',
      );
    }
  }

  // ==========================================================
  // MENSAGEM
  // ==========================================================

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // FORMATAR DATA
  // ==========================================================

  String _formatarData(DateTime? data) {
    if (data == null) return '';

    final dia =
    data.day.toString().padLeft(2, '0');

    final mes =
    data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  // ==========================================================
  // LINHA DE DETALHE
  // ==========================================================

  Widget _linha(
      String titulo,
      String valor,
      ) {
    if (valor.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 15,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final obra = _obra;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Obra Livre',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _carregando
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _erro != null || obra == null
          ? Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 54,
                color: Colors.grey,
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                _erro ??
                    'Obra não encontrada.',
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              OutlinedButton.icon(
                onPressed:
                _carregarObra,
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
      )
          : SingleChildScrollView(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 850,
            ),
            child: Container(
              padding:
              const EdgeInsets.all(
                28,
              ),
              decoration:
              BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                border: Border.all(
                  color: Colors.black12,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  // ==================================================
                  // TÍTULO
                  // ==================================================

                  Text(
                    obra.titulo,
                    style:
                    const TextStyle(
                      fontSize: 28,
                      fontWeight:
                      FontWeight.w700,
                      height: 1.3,
                      color:
                      Colors.black87,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  // ==================================================
                  // CATEGORIA
                  // ==================================================

                  if (obra
                      .categoria
                      .isNotEmpty)
                    Text(
                      obra.categoria,
                      style:
                      const TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        Colors.blue,
                      ),
                    ),

                  const SizedBox(
                    height: 24,
                  ),

                  // ==================================================
                  // AUTOR
                  // ==================================================

                  _linha(
                    'Autor',
                    obra.autor,
                  ),

                  // ==================================================
                  // COAUTORES
                  // ==================================================

                  _linha(
                    'Coautores',
                    obra.coautores,
                  ),

                  // ==================================================
                  // ANO DA OBRA
                  // ==================================================

                  if (obra.anoObra !=
                      null)
                    _linha(
                      'Ano da obra',
                      obra.anoObra
                          .toString(),
                    ),

                  // ==================================================
                  // DATA DE PUBLICAÇÃO
                  // ==================================================

                  if (obra
                      .dataPublicacao !=
                      null)
                    _linha(
                      'Data de publicação',
                      _formatarData(
                        obra
                            .dataPublicacao,
                      ),
                    ),

                  // ==================================================
                  // DESCRIÇÃO
                  // ==================================================

                  if (obra.descricao
                      .isNotEmpty)
                    _linha(
                      'Descrição',
                      obra.descricao,
                    ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==================================================
                  // BOTÃO ABRIR DOCUMENTO
                  // ==================================================

                  if (obra.urlDocumento
                      .trim()
                      .isNotEmpty)
                    ElevatedButton.icon(
                      onPressed:
                      _abrirDocumento,
                      icon:
                      const Icon(
                        Icons
                            .picture_as_pdf_outlined,
                      ),
                      label:
                      const Text(
                        'Abrir documento PDF',
                      ),
                      style:
                      ElevatedButton
                          .styleFrom(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

