import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'connectivity_web.dart'
if (dart.library.io) 'connectivity_mobile.dart';

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance =
  ConnectivityService._();

  // ============================================================
  // SUBSCRIÇÕES
  // ============================================================

  StreamSubscription<InternetStatus>? _internetSubscription;

  StreamSubscription<bool>? _webSubscription;

  Timer? _periodicTimer;

  final StreamController<bool> _statusController =
  StreamController<bool>.broadcast();

  // ============================================================
  // ESTADO
  // ============================================================

  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Stream<bool> get statusStream =>
      _statusController.stream;

  bool _initialized = false;

  bool _checking = false;

  // ============================================================
  // INICIALIZAÇÃO
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      debugPrint(
        'ConnectivityService: já inicializado.',
      );
      return;
    }

    _initialized = true;

    debugPrint(
      'ConnectivityService: inicializando...',
    );

    // ==========================================================
    // WEB — CHROME / EDGE
    // ==========================================================

    if (kIsWeb) {
      debugPrint(
        'ConnectivityService: Flutter Web '
            '(Chrome/Edge)',
      );

      await _initializeWeb();

      return;
    }

    // ==========================================================
    // MOBILE / DESKTOP
    // ==========================================================

    debugPrint(
      'ConnectivityService: Mobile/Desktop',
    );

    _internetSubscription =
        InternetConnection()
            .onStatusChange
            .listen(
              (InternetStatus status) {
            final bool online =
                status == InternetStatus.connected;

            _setStatus(online);
          },
          onError: (Object error) {
            debugPrint(
              'Erro no monitor de Internet: $error',
            );
          },
        );

    // Verificação inicial
    unawaited(checkNow());

    // Verificação periódica apenas fora da Web.
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 15),
          (_) {
        unawaited(checkNow());
      },
    );
  }

  // ============================================================
  // WEB — CHROME / EDGE
  // ============================================================

  Future<void> _initializeWeb() async {
    try {
      // Estado inicial informado diretamente pelo navegador.
      final bool initialStatus =
      await getBrowserOnlineStatus();

      debugPrint(
        'Chrome/Edge estado inicial: '
            '${initialStatus ? "ONLINE" : "OFFLINE"}',
      );

      _setStatus(initialStatus);

      // Escuta somente os eventos online/offline do navegador.
      _webSubscription =
          browserOnlineStatusStream.listen(
                (bool online) {
              debugPrint(
                'Chrome/Edge evento: '
                    '${online ? "ONLINE" : "OFFLINE"}',
              );

              _setStatus(online);
            },
            onError: (Object error) {
              debugPrint(
                'Erro no monitor Chrome/Edge: $error',
              );
            },
          );
    } catch (e, stackTrace) {
      debugPrint(
        'Erro ao inicializar conectividade Web: $e',
      );

      debugPrint(
        'StackTrace: $stackTrace',
      );

      // Não declarar OFFLINE por causa de uma
      // falha interna do monitor.
      _setStatus(true);
    }
  }

  // ============================================================
  // VERIFICAR INTERNET AGORA
  // ============================================================

  Future<bool> checkNow() async {
    if (_checking) {
      return _isOnline;
    }

    _checking = true;

    try {
      // ========================================================
      // WEB
      // ========================================================

      if (kIsWeb) {
        final bool online =
        await getBrowserOnlineStatus();

        _setStatus(online);

        return _isOnline;
      }

      // ========================================================
      // MOBILE / DESKTOP
      // ========================================================

      final bool hasInternet =
      await InternetConnection()
          .hasInternetAccess;

      _setStatus(hasInternet);

      return _isOnline;
    } catch (e, stackTrace) {
      debugPrint(
        'Erro ao verificar Internet: $e',
      );

      debugPrint(
        'StackTrace: $stackTrace',
      );

      // Uma falha isolada não altera o estado.
      return _isOnline;
    } finally {
      _checking = false;
    }
  }

  // ============================================================
  // ALTERAR ESTADO
  // ============================================================

  void _setStatus(bool value) {
    if (_isOnline == value) {
      return;
    }

    _isOnline = value;

    debugPrint(
      'Estado da Internet: '
          '${value ? "ONLINE" : "OFFLINE"}',
    );

    if (!_statusController.isClosed) {
      _statusController.add(value);
    }
  }

  // ============================================================
  // LIBERTAR RECURSOS
  // ============================================================

  Future<void> dispose() async {
    _periodicTimer?.cancel();
    _periodicTimer = null;

    await _internetSubscription?.cancel();
    _internetSubscription = null;

    await _webSubscription?.cancel();
    _webSubscription = null;

    if (!_statusController.isClosed) {
      await _statusController.close();
    }

    _initialized = false;
    _checking = false;
  }
}

