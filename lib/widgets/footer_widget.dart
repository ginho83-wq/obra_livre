import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Obra Livre',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'Plataforma de trabalhos académicos e científicos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 5),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 2,
            children: [
              _FooterLink(
                label: 'Explorar',
                onTap: () => context.go('/explorar'),
              ),
              _FooterLink(
                label: 'Biblioteca',
                onTap: () => context.go('/biblioteca'),
              ),
              _FooterLink(
                label: 'Publicar',
                onTap: () => context.go('/publicar'),
              ),
              const _FooterLink(
                label: 'Contacto',
              ),
            ],
          ),

          const SizedBox(height: 3),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 1,
            children: const [
              _FooterLink(label: 'Termos'),
              _FooterLink(label: 'Privacidade'),
              _FooterLink(label: 'Cookies'),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            '© ${DateTime.now().year} Obra Livre. Todos os direitos reservados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _FooterLink({
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 1,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
