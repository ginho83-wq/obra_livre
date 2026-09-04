import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/diagnostico_supabase.dart';

class CadastroPage extends StatefulWidget {
  final String? redirect;

  const CadastroPage({
    super.key,
    this.redirect,
  });

  @override
  State<CadastroPage> createState() =>
      _CadastroPageState();
}

class _CadastroPageState
    extends State<CadastroPage> {
  final _formKey =
  GlobalKey<FormState>();

  final _nomeController =
  TextEditingController();

  final _emailController =
  TextEditingController();

  final _senhaController =
  TextEditingController();

  final _confirmarSenhaController =
  TextEditingController();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  bool _mostrarSenha = false;
  bool _mostrarConfirmarSenha = false;
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  // ==========================================================
  // CADASTRAR
  // ==========================================================

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_carregando) return;

    setState(() {
      _carregando = true;
    });

    final nome =
    _nomeController.text.trim();

    final email =
    _emailController.text.trim();

    final senha =
        _senhaController.text;

    DiagnosticoSupabase.inicio(
      'CADASTRO',
    );

    developer.log(
      '👤 Nome: $nome',
    );

    developer.log(
      '📧 E-mail: $email',
    );

    try {
      // ======================================================
      // AUTH ANTES
      // ======================================================

      DiagnosticoSupabase.verificarAuth();

      // ======================================================
      // SIGN UP
      // ======================================================

      final response =
      await _supabase.auth.signUp(
        email: email,
        password: senha,
        data: {
          'nome_completo': nome,
        },
      );

      developer.log(
        '✅ signUp concluído.',
      );

      developer.log(
        '👤 User: ${response.user}',
      );

      developer.log(
        '🆔 User ID: ${response.user?.id}',
      );

      developer.log(
        '🔐 Session existe: '
            '${response.session != null}',
      );

      developer.log(
        '📨 Email confirmado: '
            '${response.user?.emailConfirmedAt}',
      );

      if (response.user == null) {
        throw const AuthException(
          'O Supabase não devolveu o utilizador criado.',
        );
      }

      final userId =
          response.user!.id;

      // ======================================================
      // VERIFICAR AUTH
      // ======================================================

      final usuarioAtual =
          _supabase.auth.currentUser;

      final sessaoAtual =
          _supabase.auth.currentSession;

      developer.log(
        '👤 currentUser: '
            '${usuarioAtual?.email ?? 'null'}',
      );

      developer.log(
        '🔐 currentSession existe: '
            '${sessaoAtual != null}',
      );

      // ======================================================
      // VERIFICAR PROFILE
      // ======================================================

      await DiagnosticoSupabase.verificarProfile(
        userId,
      );

      // ======================================================
      // CONFIRMAÇÃO DE E-MAIL
      // ======================================================

      if (response.session == null) {
        developer.log(
          '⚠️ SESSION NULL APÓS CADASTRO.',
        );

        developer.log(
          '📧 Confirmação de e-mail provavelmente está ativa.',
        );
      } else {
        developer.log(
          '✅ SESSION EXISTE APÓS CADASTRO.',
        );
      }

      DiagnosticoSupabase.fim();

      if (!mounted) return;

      _mostrarMensagem(
        response.session == null
            ? 'Conta criada! Verifique o seu e-mail para confirmar a conta.'
            : 'Conta criada com sucesso!',
      );

      // ======================================================
      // AGUARDAR MENSAGEM
      // ======================================================

      await Future.delayed(
        const Duration(
          milliseconds: 1500,
        ),
      );

      if (!mounted) return;

      // ======================================================
      // VOLTAR PARA LOGIN PRESERVANDO DESTINO
      // ======================================================

      final destino =
          widget.redirect;

      if (destino != null &&
          destino.trim().isNotEmpty) {
        context.go(
          Uri(
            path: '/login',
            queryParameters: {
              'redirect': destino,
            },
          ).toString(),
        );
      } else {
        context.go('/login');
      }
    } on AuthException catch (
    e,
    stackTrace
    ) {
      DiagnosticoSupabase.erro(
        'ERRO AUTH NO CADASTRO',
        e,
        stackTrace,
      );

      DiagnosticoSupabase.fim();

      if (!mounted) return;

      _mostrarMensagem(
        e.message,
        erro: true,
      );
    } on PostgrestException catch (
    e,
    stackTrace
    ) {
      DiagnosticoSupabase.erro(
        'ERRO POSTGRES NO CADASTRO',
        e,
        stackTrace,
      );

      DiagnosticoSupabase.fim();

      if (!mounted) return;

      _mostrarMensagem(
        'Erro na base de dados: ${e.message}',
        erro: true,
      );
    } catch (
    e,
    stackTrace
    ) {
      DiagnosticoSupabase.erro(
        'ERRO GERAL NO CADASTRO',
        e,
        stackTrace,
      );

      DiagnosticoSupabase.fim();

      if (!mounted) return;

      _mostrarMensagem(
        'Ocorreu um erro ao criar a conta.',
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
    if (!mounted) return;

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
  // CAMPO
  // ==========================================================

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
      ),
    );
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
            padding:
            const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 520,
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
                  child: Form(
                    key: _formKey,
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
                          'Crie a sua conta',
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color:
                            Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 28),

                        _campo(
                          controller:
                          _nomeController,
                          label:
                          'Nome completo',
                          icon:
                          Icons.person_outline,
                          textInputAction:
                          TextInputAction.next,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Digite o seu nome completo.';
                            }

                            if (value.trim().length <
                                3) {
                              return 'Digite um nome válido.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _campo(
                          controller:
                          _emailController,
                          label: 'E-mail',
                          icon:
                          Icons.email_outlined,
                          keyboardType:
                          TextInputType.emailAddress,
                          textInputAction:
                          TextInputAction.next,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Digite o seu e-mail.';
                            }

                            final email =
                            value.trim();

                            final regex =
                            RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );

                            if (!regex
                                .hasMatch(email)) {
                              return 'Digite um e-mail válido.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _campo(
                          controller:
                          _senhaController,
                          label: 'Senha',
                          icon:
                          Icons.lock_outline,
                          obscureText:
                          !_mostrarSenha,
                          textInputAction:
                          TextInputAction.next,
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
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Digite uma senha.';
                            }

                            if (value.length < 6) {
                              return 'A senha deve ter pelo menos 6 caracteres.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _campo(
                          controller:
                          _confirmarSenhaController,
                          label:
                          'Confirmar senha',
                          icon:
                          Icons.lock_outline,
                          obscureText:
                          !_mostrarConfirmarSenha,
                          textInputAction:
                          TextInputAction.done,
                          suffixIcon:
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _mostrarConfirmarSenha =
                                !_mostrarConfirmarSenha;
                              });
                            },
                            icon: Icon(
                              _mostrarConfirmarSenha
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Confirme a sua senha.';
                            }

                            if (value !=
                                _senhaController
                                    .text) {
                              return 'As senhas não coincidem.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          height: 52,
                          child:
                          ElevatedButton(
                            onPressed:
                            _carregando
                                ? null
                                : _cadastrar,
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
                              'Criar conta',
                              style:
                              TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        OutlinedButton.icon(
                          onPressed:
                          _carregando
                              ? null
                              : () {
                            final destino =
                                widget.redirect;

                            if (destino !=
                                null &&
                                destino
                                    .trim()
                                    .isNotEmpty) {
                              context.go(
                                Uri(
                                  path:
                                  '/login',
                                  queryParameters:
                                  {
                                    'redirect':
                                    destino,
                                  },
                                ).toString(),
                              );
                            } else {
                              context.go(
                                '/login',
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.login,
                          ),
                          label: const Text(
                            'Já tenho uma conta',
                          ),
                          style:
                          OutlinedButton.styleFrom(
                            minimumSize:
                            const Size.fromHeight(
                              50,
                            ),
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                14,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

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
      ),
    );
  }
}
