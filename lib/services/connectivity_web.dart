import 'dart:async';
import 'dart:html' as html;

// ============================================================
// ESTADO ATUAL DO CHROME / EDGE
// ============================================================

Future<bool> getBrowserOnlineStatus() async {
  return html.window.navigator.onLine ?? true;
}

// ============================================================
// EVENTOS ONLINE / OFFLINE DO NAVEGADOR
// ============================================================

Stream<bool> get browserOnlineStatusStream {
  late StreamController<bool> controller;

  void handleOnline(html.Event event) {
    if (!controller.isClosed) {
      controller.add(true);
    }
  }

  void handleOffline(html.Event event) {
    if (!controller.isClosed) {
      controller.add(false);
    }
  }

  controller = StreamController<bool>(
    onListen: () {
      html.window.addEventListener(
        'online',
        handleOnline,
      );

      html.window.addEventListener(
        'offline',
        handleOffline,
      );
    },
    onCancel: () {
      html.window.removeEventListener(
        'online',
        handleOnline,
      );

      html.window.removeEventListener(
        'offline',
        handleOffline,
      );
    },
  );

  return controller.stream;
}

