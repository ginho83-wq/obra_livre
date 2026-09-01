import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoriesWidget extends StatelessWidget {
  const CategoriesWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final categorias = [
      {
        'nome': 'Tese de Doutoramento',
        'rota': '/categoria/doutoramento',
      },
      {
        'nome': 'Dissertação de Mestrado',
        'rota': '/categoria/mestrado',
      },
      {
        'nome': 'Monografia',
        'rota': '/categoria/monografia',
      },
      {
        'nome': 'Artigos Científicos',
        'rota': '/categoria/artigos',
      },
      {
        'nome': 'Literatura',
        'rota': '/categoria/literatura',
      },
    ];

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        // ==========================================================
        // ACERVO
        // ==========================================================

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFDADCE0),
            ),
            borderRadius:
            BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: () =>
                context.go('/acervo'),
            borderRadius:
            BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 14,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 21,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Acervo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 22,
        ),

        // ==========================================================
        // TÍTULO DAS CATEGORIAS
        // ==========================================================

        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 8,
          ),
          child: Text(
            'Categorias',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        // ==========================================================
        // CATEGORIAS
        // ==========================================================

        ...categorias.map(
              (categoria) {
            return Padding(
              padding:
              const EdgeInsets.only(
                bottom: 4,
              ),
              child: InkWell(
                onTap: () => context.go(
                  categoria['rota']!,
                ),
                borderRadius:
                BorderRadius.circular(8),
                child: Padding(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Text(
                    categoria['nome']!,
                    style:
                    const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
