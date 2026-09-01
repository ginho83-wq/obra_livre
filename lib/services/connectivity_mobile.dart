import 'dart:async';

// ============================================================
// IMPLEMENTAÇÃO PARA MOBILE / DESKTOP
// ============================================================

Future<bool> getBrowserOnlineStatus() async {
  // Não é utilizada no Mobile/Desktop.
  return true;
}

Stream<bool> get browserOnlineStatusStream {
  // Não é utilizada no Mobile/Desktop.
  return const Stream<bool>.empty();
}

