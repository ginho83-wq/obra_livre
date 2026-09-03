import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../widgets/categories_horizontal_widget.dart';
import '../widgets/obras_recentes_widget.dart';
import '../widgets/search_bar.dart';
import '../widgets/web_ad_sense_widget.dart';

// ==========================================================
// HOME PAGE
// ==========================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// ==========================================================
// STATE
// ==========================================================

class _HomePageState extends State<HomePage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  StreamSubscription<AuthState>? _authSubscription;

  bool _carregando = true;
  bool _isAdministrador = false;
  bool _usuarioAutenticado = false;

  String? _nomeUsuario;

  // ==========================================================
  // CONFIGURAÇÃO VISUAL
  // ==========================================================

  static const double _larguraMaxima = 1080;

  // Margem horizontal única para toda a Home.
  static const double _margemHorizontal = 60;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _verificarUsuario();

    _authSubscription =
        _supabase.auth.onAuthStateChange.listen((_) {
          _verificarUsuario();
        });
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
  // VERIFICAR UTILIZADOR
  // ==========================================================

  Future<void> _verificarUsuario() async {
    try {
      final usuario = _supabase.auth.currentUser;

      if (usuario == null) {
        if (!mounted) return;

        setState(() {
          _usuarioAutenticado = false;
          _isAdministrador = false;
          _nomeUsuario = null;
          _carregando = false;
        });

        return;
      }

      final perfil = await AuthService.obterPerfil();

      if (!mounted) return;

      final usuarioAtual = _supabase.auth.currentUser;

      if (usuarioAtual == null ||
          usuarioAtual.id != usuario.id) {
        setState(() {
          _usuarioAutenticado = false;
          _isAdministrador = false;
          _nomeUsuario = null;
          _carregando = false;
        });

        return;
      }

      final role = perfil?['role']
          ?.toString()
          .trim()
          .toLowerCase();

      final administrador = role == 'admin';

      String? nome;

      if (!administrador) {
        nome = perfil?['nome_completo']
            ?.toString()
            .trim();

        if (nome == null || nome.isEmpty) {
          nome = AuthService.obterNomeUsuario();
        }
      }

      setState(() {
        _usuarioAutenticado = true;
        _isAdministrador = administrador;
        _nomeUsuario = administrador ? null : nome;
        _carregando = false;
      });
    } catch (e) {
      debugPrint(
        'ERRO AO VERIFICAR USUÁRIO: $e',
      );

      if (!mounted) return;

      setState(() {
        _usuarioAutenticado = false;
        _isAdministrador = false;
        _nomeUsuario = null;
        _carregando = false;
      });
    }
  }

  // ==========================================================
  // NAVEGAÇÃO
  // ==========================================================

  void _abrirAcervo() {
    context.push('/acervo');
  }

  void _abrirLogin() {
    context.go('/login');
  }

  void _abrirMinhaConta() {
    context.push('/minha-conta');
  }

  void _abrirAdministracao() {
    context.push('/admin-obras');
  }

  // ==========================================================
  // CONTAINER PADRÃO
  // ==========================================================

  Widget _containerPrincipal({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _larguraMaxima,
        ),
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: _margemHorizontal,
              ),
          child: child,
        ),
      ),
    );
  }

  // ==========================================================
  // CABEÇALHO
  // ==========================================================

  Widget _construirCabecalho() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(
              alpha: 0.10,
            ),
          ),
        ),
      ),
      child: _containerPrincipal(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // ==================================================
              // LOGOTIPO
              // ==================================================

              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  context.go('/');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 10,
                  ),
                  child: Text(
                    'Obra Livre',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ==================================================
              // ACERVO
              // ==================================================

              TextButton(
                onPressed: _abrirAcervo,
                style: TextButton.styleFrom(
                  foregroundColor:
                  theme.colorScheme.onSurface,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Acervo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 2),

              // ==================================================
              // AUTENTICAÇÃO
              // ==================================================

              if (_carregando)
                const SizedBox(
                  width: 120,
                  height: 40,
                )
              else if (!_usuarioAutenticado)
                TextButton(
                  onPressed: _abrirLogin,
                  style: TextButton.styleFrom(
                    foregroundColor:
                    theme.colorScheme.onSurface,
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else if (_isAdministrador)
                  TextButton(
                    onPressed: _abrirAdministracao,
                    style: TextButton.styleFrom(
                      foregroundColor:
                      theme.colorScheme.onSurface,
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Administração',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _abrirMinhaConta,
                    style: TextButton.styleFrom(
                      foregroundColor:
                      theme.colorScheme.onSurface,
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints:
                      const BoxConstraints(
                        maxWidth: 150,
                      ),
                      child: Text(
                        _nomeUsuario != null &&
                            _nomeUsuario!.isNotEmpty
                            ? _nomeUsuario!
                            : 'Minha Conta',
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ÁREA DE PESQUISA
  // ==========================================================

  Widget _construirAreaPesquisa() {
    final theme = Theme.of(context);

    return _containerPrincipal(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 720,
        ),
        child: Column(
          children: [
            Text(
              'Encontre conhecimento. Encontre obras.',
              textAlign: TextAlign.center,
              style:
              theme.textTheme.headlineSmall?.copyWith(
                fontSize: 27,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 11),

            Text(
              'Pesquise teses, dissertações, artigos e outras obras académicas.',
              textAlign: TextAlign.center,
              style:
              theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.55,
                color:
                theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.64),
              ),
            ),

            const SizedBox(height: 24),

            const SearchBarWidget(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CATEGORIAS
  // ==========================================================

  Widget _construirCategorias() {
    return _containerPrincipal(
      child: const CategoriesHorizontalWidget(),
    );
  }

  // ==========================================================
  // PUBLICIDADE
  // ==========================================================

  Widget _construirPublicidade() {
    return _containerPrincipal(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile =
              constraints.maxWidth < 600;

          return Align(
            alignment: isMobile
                ? Alignment.center
                : Alignment.topRight,
            child: const WebAdSenseWidget(
              adSize: 'small',
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // OBRAS RECENTES
  // ==========================================================

  Widget _construirSecaoObras() {
    final theme = Theme.of(context);

    return _containerPrincipal(
      // Usa exatamente os mesmos 60 px das restantes seções.
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Obras recentes',
            style:
            theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Últimas obras publicadas na plataforma',
            style:
            theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              height: 1.4,
              color:
              theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.62),
            ),
          ),

          const SizedBox(height: 18),

          const ObrasRecentesWidget(
            quantidade: 10,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RODAPÉ
  // ==========================================================

  Widget _construirRodape() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 58,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 24,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(
              alpha: 0.10,
            ),
          ),
        ),
      ),
      child: _containerPrincipal(
        child: Row(
          children: [
            Text(
              '© ${DateTime.now().year} Obra Livre',
              style:
              theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color:
                theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.58),
              ),
            ),

            const Spacer(),

            Text(
              'Acervo Digital',
              style:
              theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color:
                theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.58),
              ),
            ),
          ],
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _construirCabecalho(),

              const SizedBox(height: 48),

              _construirAreaPesquisa(),

              const SizedBox(height: 22),

              _construirCategorias(),

              const SizedBox(height: 24),

              _construirPublicidade(),

              const SizedBox(height: 36),

              _construirSecaoObras(),

              _construirRodape(),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

