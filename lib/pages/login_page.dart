import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/diagnostico_supabase.dart';

class LoginPage extends StatefulWidget {
  final String? redirect;

  const LoginPage({
    super.key,
    this.redirect,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  bool _carregando = false;
  bool _mostrarSenha = false;

  // ==========================================================
  // URL DE PRODUÇÃO
  // ==========================================================

  static const String _urlProducao =
      'https://ginho83-wq.github.io/obra_livre/';

  // ==========================================================
  // URL DO CALLBACK GOOGLE
  //
  // IMPORTANTE:
  // Não enviamos mais o redirect antigo.
  // Depois da autenticação o AuthCallbackPage sempre
  // levará o usuário para a Home autenticada.
  // ==========================================================

  String _urlCallbackGoogle() {
    return '${_urlProducao}auth-callback';
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOGIN COM E-MAIL E SENHA
  // ==========================================================

  Future<void> _entrar() async {
    final email = _emailController.text.trim();
    final senha = _passwordController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mostrarMensagem(
        'Preencha e-mail e senha.',
        erro: true,
      );
      return;
    }

    if (_carregando) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    DiagnosticoSupabase.inicio('LOGIN');

    developer.log(
      'E-mail informado: $email',
      name: 'LoginPage',
    );

    try {
      final response =
      await _supabase.auth.signInWithPassword(
        email: email,
        password: senha,
      );

      final usuario = response.user;

      if (usuario == null) {
        throw const AuthException(
          'O Supabase não devolveu o utilizador.',
        );
      }

      final usuarioAtual =
          _supabase.auth.currentUser;

      final sessaoAtual =
          _supabase.auth.currentSession;

      developer.log(
        'currentUser: ${usuarioAtual?.email ?? 'null'}',
        name: 'LoginPage',
      );

      developer.log(
        'currentSession existe: ${sessaoAtual != null}',
        name: 'LoginPage',
      );

      if (usuarioAtual == null) {
        throw const AuthException(
          'O login foi concluído, mas a sessão não foi encontrada.',
        );
      }

      if (sessaoAtual == null) {
        throw const AuthException(
          'A sessão de login não foi criada.',
        );
      }

      // ======================================================
      // DIAGNÓSTICO
      // ======================================================

      final usuarioDiagnostico =
      await DiagnosticoSupabase.diagnosticar(
        'LOGIN - APÓS AUTENTICAÇÃO',
      );

      if (usuarioDiagnostico == null) {
        throw const AuthException(
          'Usuário não encontrado após o login.',
        );
      }

      // ======================================================
      // CONSULTAR PROFILE
      // ======================================================

      final perfil = await _supabase
          .from('profiles')
          .select('role, nome_completo')
          .eq(
        'id',
        usuarioAtual.id,
      )
          .maybeSingle();

      final role = perfil?['role']
          ?.toString()
          .trim()
          .toLowerCase();

      developer.log(
        'ROLE FINAL: $role',
        name: 'LoginPage',
      );

      if (!mounted) {
        return;
      }

      // ======================================================
      // LOGIN CONCLUÍDO
      // ======================================================

      if (role == 'admin') {
        developer.log(
          'Administrador detetado.',
          name: 'LoginPage',
        );
      } else {
        developer.log(
          'Utilizador normal.',
          name: 'LoginPage',
        );
      }

      developer.log(
        'Login por e-mail concluído. Indo para Home.',
        name: 'LoginPage',
      );

      DiagnosticoSupabase.fim();

      // ======================================================
      // HOME AUTENTICADA
      // ======================================================
      //
      // O router '/' está configurado para HomeTestePage.
      //
      // Portanto:
      //
      // E-mail/senha → /
      // Google       → /
      //
      // ======================================================

      context.go('/');
    } on AuthException catch (e, stackTrace) {
      DiagnosticoSupabase.erro(
        'ERRO AUTH NO LOGIN',
        e,
        stackTrace,
      );

      DiagnosticoSupabase.fim();

      if (!mounted) {
        return;
      }

      _mostrarMensagem(
        e.message,
        erro: true,
      );
    } on PostgrestException catch (e, stackTrace) {
      DiagnosticoSupabase.erro(
        'ERRO POSTGRES NO LOGIN',
        e,
        stackTrace,
      );

      DiagnosticoSupabase.fim();

      if (!mounted) {
        return;
      }

      _mostrarMensagem(
        'Erro ao consultar o perfil: ${e.message}',
        erro: true,
      );
    } catch (e, stackTrace) {
      DiagnosticoSupabase.erro(
        'ERRO GERAL NO LOGIN',
        e,
        stackTrace,
      );

      DiagnosticoSupabase.fim();

      if (!mounted) {
        return;
      }

      _mostrarMensagem(
        'Ocorreu um erro ao entrar na conta.',
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ==========================================================
  // LOGIN COM GOOGLE
  // ==========================================================

  Future<void> _entrarComGoogle() async {
    if (_carregando) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    DiagnosticoSupabase.inicio(
      'LOGIN COM GOOGLE',
    );

    try {
      final callbackUrl =
      _urlCallbackGoogle();

      developer.log(
        'OAuth callback: $callbackUrl',
        name: 'LoginPage',
      );

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: callbackUrl,
      );

      DiagnosticoSupabase.fim();
    } on AuthException catch (e, stackTrace) {
      DiagnosticoSupabase.erro(
        'ERRO AUTH GOOGLE',
        e,
        stackTrace,
      );

      DiagnosticoSupabase.fim();

      if (!mounted) {
        return;
      }

      _mostrarMensagem(
        e.message,
        erro: true,
      );
    } catch (e, stackTrace) {
      DiagnosticoSupabase.erro(
        'ERRO GERAL GOOGLE',
        e,
        stackTrace,
      );

      DiagnosticoSupabase.fim();

      if (!mounted) {
        return;
      }

      _mostrarMensagem(
        'Não foi possível iniciar o login com Google.',
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ==========================================================
  // MENSAGEM
  // ==========================================================

  void _mostrarMensagem(
      String mensagem, {
        bool erro = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor:
          erro ? Colors.red.shade700 : null,
          content: Text(mensagem),
        ),
      );
  }

  // ==========================================================
  // IR PARA CADASTRO
  // ==========================================================

  void _irParaCadastro() {
    final destino = widget.redirect;

    if (destino != null &&
        destino.trim().isNotEmpty) {
      final url = Uri(
        path: '/cadastro',
        queryParameters: {
          'redirect': destino,
        },
      ).toString();

      context.go(url);
      return;
    }

    context.go('/cadastro');
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black12,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(24),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 56,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Obra Livre',
                        textAlign:
                        TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Entre na sua conta',
                        textAlign:
                        TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                          Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // E-MAIL
                      // ==================================================

                      TextField(
                        controller:
                        _emailController,
                        keyboardType:
                        TextInputType.emailAddress,
                        textInputAction:
                        TextInputAction.next,
                        decoration:
                        InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon:
                          const Icon(
                            Icons.email_outlined,
                          ),
                          filled: true,
                          fillColor:
                          Colors.grey.shade50,
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // SENHA
                      // ==================================================

                      TextField(
                        controller:
                        _passwordController,
                        obscureText:
                        !_mostrarSenha,
                        textInputAction:
                        TextInputAction.done,
                        onSubmitted: (_) =>
                            _entrar(),
                        decoration:
                        InputDecoration(
                          labelText: 'Senha',
                          prefixIcon:
                          const Icon(
                            Icons.lock_outline,
                          ),
                          suffixIcon:
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _mostrarSenha =
                                !_mostrarSenha;
                              });
                            },
                            icon: Icon(
                              _mostrarSenha
                                  ? Icons
                                  .visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                          filled: true,
                          fillColor:
                          Colors.grey.shade50,
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // ENTRAR
                      // ==================================================

                      SizedBox(
                        height: 52,
                        child:
                        ElevatedButton(
                          onPressed:
                          _carregando
                              ? null
                              : _entrar,
                          child: _carregando
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Entrar',
                            style:
                            TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // OU
                      // ==================================================

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors
                                  .grey.shade300,
                            ),
                          ),
                          Padding(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 12,
                            ),
                            child: Text(
                              'ou',
                              style: TextStyle(
                                color: Colors
                                    .grey.shade600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors
                                  .grey.shade300,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // GOOGLE
                      // ==================================================

                      SizedBox(
                        height: 50,
                        child:
                        OutlinedButton.icon(
                          onPressed:
                          _carregando
                              ? null
                              : _entrarComGoogle,
                          icon: const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          label: const Text(
                            'Continuar com Google',
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // CADASTRO
                      // ==================================================

                      TextButton(
                        onPressed:
                        _carregando
                            ? null
                            : _irParaCadastro,
                        child: const Text(
                          'Ainda não tenho uma conta',
                        ),
                      ),

                      // ==================================================
                      // HOME
                      // ==================================================

                      TextButton(
                        onPressed:
                        _carregando
                            ? null
                            : () =>
                            context.go('/'),
                        child: const Text(
                          'Voltar para Home',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
