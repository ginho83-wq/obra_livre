import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoriesHorizontalWidget extends StatelessWidget {
  const CategoriesHorizontalWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final categorias = [
      {
        'nome': 'Todas',
        'rota': '/',
      },
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

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 24),

            ...categorias.asMap().entries.map(
                  (entry) {
                final index = entry.key;
                final categoria = entry.value;

                return Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        context.go(
                          categoria['rota'] as String,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 8,
                        ),
                        child: Text(
                          categoria['nome'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    if (index < categorias.length - 1)
                      const SizedBox(width: 26),
                  ],
                );
              },
            ),

            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}
