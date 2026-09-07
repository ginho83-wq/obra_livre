import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthCallbackPage extends StatefulWidget {
  final String? redirect;

  const AuthCallbackPage({
    super.key,
    this.redirect,
  });

  @override
  State<AuthCallbackPage> createState() =>
      _AuthCallbackPageState();
}

class _AuthCallbackPageState
    extends State<AuthCallbackPage> {
  StreamSubscription<AuthState>? _authSubscription;

  bool _processando = false;
  bool _processado = false;

  String? _erro;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    developer.log(
      'AuthCallbackPage iniciado',
      name: 'AuthCallbackPage',
    );

    _escutarAutenticacao();
    _iniciarProcessamento();
  }

  // ==========================================================
  // ESCUTAR ALTERAÇÕES DE AUTENTICAÇÃO
  // ==========================================================

  void _escutarAutenticacao() {
    _authSubscription = Supabase
        .instance
        .client
        .auth
        .onAuthStateChange
        .listen(
          (data) async {
        final event = data.event;
        final session = data.session;

        developer.log(
          'Evento de autenticação: $event',
          name: 'AuthCallbackPage',
        );

        developer.log(
          'Sessão disponível: ${session != null}',
          name: 'AuthCallbackPage',
        );

        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.initialSession) {
          await _processarLogin();
        }
      },
      onError: (Object erro, StackTrace stackTrace) {
        developer.log(
          'Erro no listener de autenticação',
          name: 'AuthCallbackPage',
          error: erro,
          stackTrace: stackTrace,
        );
      },
    );
  }

  // ==========================================================
  // PROCESSAMENTO INICIAL
  // ==========================================================

  Future<void> _iniciarProcessamento() async {
    try {
      final uri = Uri.base;

      developer.log(
        'URL atual: $uri',
        name: 'AuthCallbackPage',
      );

      final code = uri.queryParameters['code'];

      if (code != null && code.isNotEmpty) {
        developer.log(
          'Código OAuth encontrado. Trocando por sessão...',
          name: 'AuthCallbackPage',
        );

        try {
          await Supabase
              .instance
              .client
              .auth
              .exchangeCodeForSession(code);

          developer.log(
            'Código OAuth trocado com sucesso.',
            name: 'AuthCallbackPage',
          );
        } catch (erro, stackTrace) {
          developer.log(
            'Erro ao trocar código OAuth por sessão.',
            name: 'AuthCallbackPage',
            error: erro,
            stackTrace: stackTrace,
          );

          // O Supabase pode já ter processado
          // o código automaticamente.
        }
      }

      await _verificarSessaoInicial();
    } catch (erro, stackTrace) {
      developer.log(
        'Erro no processamento inicial do callback.',
        name: 'AuthCallbackPage',
        error: erro,
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _erro = 'Não foi possível concluir o login.';
        _processando = false;
      });
    }
  }

  // ==========================================================
  // VERIFICAR SESSÃO INICIAL
  // ==========================================================

  Future<void> _verificarSessaoInicial() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    final session =
        Supabase.instance.client.auth.currentSession;

    final user =
        Supabase.instance.client.auth.currentUser;

    developer.log(
      'Verificação inicial - usuário: ${user?.email}',
      name: 'AuthCallbackPage',
    );

    developer.log(
      'Verificação inicial - sessão: ${session != null}',
      name: 'AuthCallbackPage',
    );

    if (user != null && session != null) {
      await _processarLogin();
      return;
    }

    developer.log(
      'Sessão ainda não disponível. '
          'Aguardando evento de autenticação...',
      name: 'AuthCallbackPage',
    );
  }

  // ==========================================================
  // PROCESSAR LOGIN
  // ==========================================================

  Future<void> _processarLogin() async {
    if (_processando || _processado) {
      return;
    }

    _processando = true;

    try {
      final supabase = Supabase.instance.client;

      final user = supabase.auth.currentUser;
      final session = supabase.auth.currentSession;

      developer.log(
        'Processando login...',
        name: 'AuthCallbackPage',
      );

      developer.log(
        'Usuário: ${user?.email}',
        name: 'AuthCallbackPage',
      );

      developer.log(
        'ID: ${user?.id}',
        name: 'AuthCallbackPage',
      );

      developer.log(
        'Sessão: ${session != null}',
        name: 'AuthCallbackPage',
      );

      // ======================================================
      // VERIFICAR SESSÃO
      // ======================================================

      if (user == null || session == null) {
        developer.log(
          'Usuário ou sessão ainda não disponível.',
          name: 'AuthCallbackPage',
        );

        _processando = false;
        return;
      }

      // ======================================================
      // CONSULTAR PROFILE
      // ======================================================

      String? role;
      String? nome;

      try {
        final perfil = await supabase
            .from('profiles')
            .select('id, nome, email, avatar_url, role')
            .eq('id', user.id)
            .maybeSingle();

        if (perfil != null) {
          role = perfil['role']?.toString();
          nome = perfil['nome']?.toString();
        }

        developer.log(
          'Perfil encontrado. '
              'role=$role, nome=$nome',
          name: 'AuthCallbackPage',
        );
      } catch (erro, stackTrace) {
        developer.log(
          'Não foi possível carregar o perfil.',
          name: 'AuthCallbackPage',
          error: erro,
          stackTrace: stackTrace,
        );

        // O perfil não bloqueia o login.
      }

      if (!mounted) {
        return;
      }

      _processado = true;

      // ======================================================
      // ADMINISTRADOR
      // ======================================================

      if (role?.trim().toLowerCase() == 'admin') {
        developer.log(
          'Usuário administrador. Indo para Home.',
          name: 'AuthCallbackPage',
        );

        context.go('/');
        return;
      }

      // ======================================================
      // USUÁRIO NORMAL
      // ======================================================

      developer.log(
        'Login concluído.',
        name: 'AuthCallbackPage',
      );

      developer.log(
        'Indo para Home autenticado (/).',
        name: 'AuthCallbackPage',
      );

      context.go('/');
    } catch (erro, stackTrace) {
      developer.log(
        'Erro ao processar login.',
        name: 'AuthCallbackPage',
        error: erro,
        stackTrace: stackTrace,
      );

      _processando = false;

      if (!mounted) {
        return;
      }

      setState(() {
        _erro = 'Erro ao concluir o login.';
      });
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (_erro != null) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Erro ao entrar',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _erro!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      child: const Text(
                        'Voltar para entrar',
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

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Concluindo o login...',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
