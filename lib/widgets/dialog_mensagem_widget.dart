import 'package:flutter/material.dart';

// ==========================================================
// DIALOG MENSAGEM
// Componente padrão para mensagens do Obra Livre
// ==========================================================
class DialogMensagem {
  DialogMensagem._();

  // ========================================================
  // SUCESSO
  // ========================================================
  static Future<void> sucesso(
      BuildContext context, {
        required String titulo,
        required String mensagem,
      }) async {
    await _mostrar(
      context,
      titulo: titulo,
      mensagem: mensagem,
      icone: Icons.check_circle_outline,
      mostrarBotaoOk: false,
      fecharAutomaticamente: true,
    );
  }

  // ========================================================
  // ERRO
  // ========================================================
  static Future<void> erro(
      BuildContext context, {
        required String titulo,
        required String mensagem,
      }) async {
    await _mostrar(
      context,
      titulo: titulo,
      mensagem: mensagem,
      icone: Icons.error_outline,
      mostrarBotaoOk: true,
      fecharAutomaticamente: false,
    );
  }

  // ========================================================
  // AVISO
  // ========================================================
  static Future<void> aviso(
      BuildContext context, {
        required String titulo,
        required String mensagem,
      }) async {
    await _mostrar(
      context,
      titulo: titulo,
      mensagem: mensagem,
      icone: Icons.warning_amber_outlined,
      mostrarBotaoOk: true,
      fecharAutomaticamente: false,
    );
  }

  // ========================================================
  // INFORMAÇÃO
  // ========================================================
  static Future<void> informacao(
      BuildContext context, {
        required String titulo,
        required String mensagem,
      }) async {
    await _mostrar(
      context,
      titulo: titulo,
      mensagem: mensagem,
      icone: Icons.info_outline,
      mostrarBotaoOk: true,
      fecharAutomaticamente: false,
    );
  }

  // ========================================================
  // DIALOG PRINCIPAL
  // ========================================================
  static Future<void> _mostrar(
      BuildContext context, {
        required String titulo,
        required String mensagem,
        required IconData icone,
        required bool mostrarBotaoOk,
        required bool fecharAutomaticamente,
      }) async {
    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        if (fecharAutomaticamente) {
          Future.delayed(
            const Duration(milliseconds: 1600),
                () {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
          );
        }

        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,

          // ==================================================
          // TAMANHO DO DIALOG
          // ==================================================
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),

          // ==================================================
          // CANTOS DO DIALOG
          // Border Radius: 6 px
          // ==================================================
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),

          // ==================================================
          // TÍTULO
          // ==================================================
          titlePadding: const EdgeInsets.fromLTRB(
            24,
            20,
            8,
            0,
          ),

          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icone,
                size: 25,
                color: Colors.black87,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  titulo,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              // ==================================================
              // FECHAR
              // ==================================================
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                tooltip: 'Fechar',
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.black54,
                ),
              ),
            ],
          ),

          // ==================================================
          // CONTEÚDO
          // ==================================================
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            16,
            24,
            8,
          ),

          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: Text(
              mensagem,
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.black87,
              ),
            ),
          ),

          // ==================================================
          // AÇÕES
          // ==================================================
          actionsPadding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            16,
          ),

          actions: mostrarBotaoOk
              ? [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,
                elevation: 0,

                // ==================================================
                // BORDER RADIUS DO BOTÃO
                // 6 px
                // ==================================================
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),

                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'OK',
              ),
            ),
          ]
              : null,
        );
      },
    );
  }
}


