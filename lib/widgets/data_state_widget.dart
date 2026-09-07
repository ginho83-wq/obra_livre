import 'package:flutter/material.dart';

class DataStateWidget extends StatelessWidget {
  const DataStateWidget({
    super.key,
    required this.child,
    this.isLoading = false,
    this.isEmpty = false,
    this.hasError = false,
    this.errorMessage =
    'Não foi possível carregar os dados.',
    this.emptyTitle = 'Nenhum dado encontrado',
    this.emptyMessage =
    'Ainda não existem dados disponíveis.',
    this.onRetry,
  });

  final Widget child;
  final bool isLoading;
  final bool isEmpty;
  final bool hasError;

  final String errorMessage;
  final String emptyTitle;
  final String emptyMessage;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (hasError) {
      return _buildMessage(
        context,
        icon: Icons.error_outline_rounded,
        title: 'Não foi possível carregar',
        message: errorMessage,
        buttonText: 'Tentar novamente',
        onPressed: onRetry,
      );
    }

    if (isEmpty) {
      return _buildMessage(
        context,
        icon: Icons.library_books_outlined,
        title: emptyTitle,
        message: emptyMessage,
        buttonText: null,
        onPressed: null,
      );
    }

    return child;
  }

  Widget _buildMessage(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String message,
        required String? buttonText,
        required VoidCallback? onPressed,
      }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 52,
                  color: Colors.black38,
                ),

                const SizedBox(height: 16),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),

                if (buttonText != null &&
                    onPressed != null) ...[
                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    label: Text(buttonText),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
