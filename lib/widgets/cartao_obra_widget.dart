import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dados/obras_recentes.dart';

class CartaoObraWidget extends StatelessWidget {
  final ObraRecente obra;

  const CartaoObraWidget({
    super.key,
    required this.obra,
  });

  // ==========================================================
  // ABRIR PÁGINA INDIVIDUAL DA OBRA
  // ==========================================================
  void _abrirObra(BuildContext context) {
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

    // Usa o ID real da obra.
    // Exemplo:
    // /obra/550e8400-e29b-41d4-a716-446655440000
    final idCodificado = Uri.encodeComponent(id);

    context.go('/obra/$idCodificado');
  }

  // ==========================================================
  // ABRIR PDF
  // ==========================================================
  Future<void> _abrirPdf(BuildContext context) async {
    if (obra.urlDocumento.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O documento desta obra não está disponível.',
          ),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(
      obra.urlDocumento.trim(),
    );

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O endereço do documento é inválido.',
          ),
        ),
      );
      return;
    }

    try {
      final abriu = await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
      );

      if (!abriu && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir o documento.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;

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
  // FORMATAR DATA
  // ==========================================================
  String _formatarData(String data) {
    if (data.trim().isEmpty) {
      return '';
    }

    final dataConvertida = DateTime.tryParse(
      data,
    );

    if (dataConvertida == null) {
      return data;
    }

    final dia = dataConvertida.day
        .toString()
        .padLeft(2, '0');

    final mes = dataConvertida.month
        .toString()
        .padLeft(2, '0');

    final ano = dataConvertida.year.toString();

    return '$dia/$mes/$ano';
  }

  // ==========================================================
  // OBTER LISTA DE AUTORES
  //
  // Autor principal + coautores
  // ==========================================================
  List<String> _obterAutores() {
    final nomes = <String>[];

    final autor = obra.autor.trim();

    if (autor.isNotEmpty) {
      nomes.add(autor);
    }

    final coautores = obra.coautores.trim();

    if (coautores.isNotEmpty) {
      final listaCoautores = coautores
          .split(RegExp(r'\r?\n|;|,'))
          .map(
            (nome) => nome.trim(),
      )
          .where(
            (nome) => nome.isNotEmpty,
      )
          .toList();

      nomes.addAll(listaCoautores);
    }

    return nomes;
  }

  // ==========================================================
  // CONSTRUIR TEXTO DOS AUTORES
  //
  // 1 autor:
  // João Manuel
  //
  // 2 autores:
  // João Manuel, Maria José
  //
  // 3 autores:
  // João Manuel, Maria José, Pedro António
  //
  // Mais de 3:
  // João Manuel, Maria José, Pedro António et al.
  // ==========================================================
  String _textoAutores() {
    final nomes = _obterAutores();

    if (nomes.isEmpty) {
      return '';
    }

    final existemMaisAutores = nomes.length > 3;

    final nomesVisiveis = existemMaisAutores
        ? nomes.take(3).toList()
        : nomes;

    String texto = nomesVisiveis.join(', ');

    if (existemMaisAutores) {
      texto = '$texto et al.';
    }

    return texto;
  }

  // ==========================================================
  // CONSTRUIR INFORMAÇÕES DA OBRA
  //
  // Autor, Coautores • Categoria • Ano • Publicado em data
  // ==========================================================
  Widget _construirInformacoesObra() {
    final informacoes = <String>[];

    // ----------------------------------------------------------
    // AUTORES
    // ----------------------------------------------------------
    final textoAutores = _textoAutores();

    if (textoAutores.isNotEmpty) {
      informacoes.add(textoAutores);
    }

    // ----------------------------------------------------------
    // CATEGORIA
    // ----------------------------------------------------------
    final categoria = obra.categoria.trim();

    if (categoria.isNotEmpty) {
      informacoes.add(categoria);
    }

    // ----------------------------------------------------------
    // ANO DA OBRA
    // ----------------------------------------------------------
    final anoObra = obra.anoObra.toString().trim();

    if (anoObra.isNotEmpty &&
        anoObra != '0' &&
        anoObra != 'null') {
      informacoes.add(anoObra);
    }

    // ----------------------------------------------------------
    // DATA DE PUBLICAÇÃO
    // ----------------------------------------------------------
    final dataPublicacao =
    obra.dataPublicacao.trim();

    if (dataPublicacao.isNotEmpty) {
      final dataFormatada =
      _formatarData(dataPublicacao);

      if (dataFormatada.isNotEmpty) {
        informacoes.add(
          'Publicado em $dataFormatada',
        );
      }
    }

    // ----------------------------------------------------------
    // NENHUMA INFORMAÇÃO
    // ----------------------------------------------------------
    if (informacoes.isEmpty) {
      return const SizedBox.shrink();
    }

    // ----------------------------------------------------------
    // INFORMAÇÕES EM UMA ÚNICA LINHA
    // COM QUEBRA AUTOMÁTICA
    // ----------------------------------------------------------
    return Text(
      informacoes.join(' • '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 12,
      ),
    );
  }

  // ==========================================================
  // CARD PRINCIPAL
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 4,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // ==================================================
            // 1ª LINHA — TÍTULO
            // ==================================================
            InkWell(
              onTap: () {
                _abrirObra(context);
              },
              borderRadius:
              BorderRadius.circular(4),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(
                  vertical: 4,
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // ------------------------------------------------
                    // GLOBO
                    // ------------------------------------------------
                    const Padding(
                      padding: EdgeInsets.only(
                        top: 2,
                        right: 7,
                      ),
                      child: Icon(
                        Icons.public,
                        size: 20,
                      ),
                    ),

                    // ------------------------------------------------
                    // TÍTULO
                    // ------------------------------------------------
                    Expanded(
                      child: Text(
                        obra.titulo,
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w500,
                          decoration:
                          TextDecoration
                              .underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ==================================================
            // 2ª LINHA — DESCRIÇÃO
            // ==================================================
            if (obra.resumo.trim().isNotEmpty)
              Text(
                obra.resumo,
                maxLines: 3,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

            const SizedBox(height: 6),

            // ==================================================
            // 3ª LINHA
            //
            // AUTORES • CATEGORIA • ANO • DATA
            // ==================================================
            _construirInformacoesObra(),
          ],
        ),
      ),
    );
  }
}
