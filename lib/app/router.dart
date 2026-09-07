import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

import '../pages/home_page.dart';
import '../pages/acervo_resultados_page.dart';
import '../pages/obra_detalhes_page.dart';
import '../pages/login_page.dart';
import '../pages/cadastro_page.dart';
import '../pages/categoria_page.dart';
import '../pages/search_results_page.dart';
import '../pages/minha_conta_page.dart';
import '../pages/editar_perfil_page.dart';
import '../pages/publicacoes_page.dart';
import '../pages/publicar_page.dart';
import '../pages/minhas_denuncias_page.dart';
import '../pages/minhas_solicitacoes_remocao_page.dart';
import '../pages/admin_obras_page.dart';
import '../pages/admin_search_results_page.dart';
import '../pages/admin_denuncias_page.dart';
import '../pages/admin_solicitacoes_remocao_page.dart';
import '../pages/estatistica_admin_page.dart';
import '../pages/politica_privacidade_page.dart';
import '../pages/termos_page.dart';
import '../pages/contacto_page.dart';
import '../pages/cookies_page.dart';
import '../pages/auth_callback_page.dart';

import '../widgets/obra_detalhes_dialog.dart';

// ==========================================================
// AUTH ROUTER REFRESH
// ==========================================================

class AuthRouterRefresh extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  AuthRouterRefresh() {
    _subscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
              (_) {
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ==========================================================
// ROUTER
// ==========================================================

late final GoRouter router;
late final AuthRouterRefresh _authRouterRefresh;

// ==========================================================
// INICIALIZAR ROUTER
// ==========================================================

void initializeRouter() {
  _authRouterRefresh = AuthRouterRefresh();

  router = GoRouter(
    // ========================================================
    // TESTE:
    // A aplicação começa sempre no LOGIN.
    // ========================================================
    initialLocation: '/login',

    refreshListenable: _authRouterRefresh,

    errorBuilder: (context, state) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Página não encontrada.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    },

    routes: [
      // ======================================================
      // HOME
      // ======================================================

      GoRoute(
        path: '/',
        builder: (context, state) {
          return const HomePage();
        },
      ),

      // ======================================================
      // CALLBACK GOOGLE
      // ======================================================

      GoRoute(
        path: '/auth-callback',
        builder: (context, state) {
          final redirect =
          state.uri.queryParameters['redirect'];

          return AuthCallbackPage(
            redirect: redirect,
          );
        },
      ),

      // ======================================================
      // LOGIN
      // ======================================================

      GoRoute(
        path: '/login',
        builder: (context, state) {
          final redirect =
          state.uri.queryParameters['redirect'];

          return LoginPage(
            redirect: redirect,
          );
        },
      ),

      // ======================================================
      // CADASTRO
      // ======================================================

      GoRoute(
        path: '/cadastro',
        builder: (context, state) {
          final redirect =
          state.uri.queryParameters['redirect'];

          return CadastroPage(
            redirect: redirect,
          );
        },
      ),

      // ======================================================
      // ACERVO
      // ======================================================

      GoRoute(
        path: '/acervo',
        builder: (context, state) {
          final query =
              state.uri.queryParameters['query'] ?? '';

          final categoria =
              state.uri.queryParameters['categoria'] ??
                  'Todas';

          final ano =
          state.uri.queryParameters['ano'];

          final ordenacao =
              state.uri.queryParameters['ordenacao'] ??
                  'Mais recentes';

          return AcervoResultadosPage(
            query: query,
            categoria: categoria,
            ano: ano,
            ordenacao: ordenacao,
          );
        },
      ),

      // ======================================================
      // OBRA
      // ======================================================

      GoRoute(
        path: '/obra/:id',
        builder: (context, state) {
          final id =
          state.pathParameters['id'];

          if (id == null || id.trim().isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Obra não encontrada.',
                ),
              ),
            );
          }

          final abrirDetalhes =
          state.uri.queryParameters[
          'abrirDetalhes'];

          if (abrirDetalhes == '1') {
            return _ObraRetornoDenunciaPage(
              id: id,
            );
          }

          return ObraDetalhesPage(
            id: id,
          );
        },
      ),

      // ======================================================
      // MINHA CONTA
      // ======================================================

      GoRoute(
        path: '/minha-conta',
        redirect: _verificarAutenticacao,
        builder: (context, state) {
          return const MinhaContaPage();
        },
      ),

      // ======================================================
      // EDITAR PERFIL
      // ======================================================

      GoRoute(
        path: '/editar-perfil',
        redirect: _verificarAutenticacao,
        builder: (context, state) {
          return const EditarPerfilPage();
        },
      ),

      // ======================================================
      // PUBLICAÇÕES
      // ======================================================

      GoRoute(
        path: '/publicacoes',
        redirect: _verificarAutenticacao,
        builder: (context, state) {
          return const PublicacoesPage();
        },
      ),

      // ======================================================
      // PUBLICAR
      // ======================================================

      GoRoute(
        path: '/publicar',
        redirect: _verificarAutenticacao,
        builder: (context, state) {
          return const PublicarPage();
        },
      ),

      // ======================================================
      // MINHAS DENÚNCIAS
      // ======================================================

      GoRoute(
        path: '/minhas-denuncias',
        redirect: _verificarAutenticacao,
        builder: (context, state) {
          return const MinhasDenunciasPage();
        },
      ),

      // ======================================================
      // MINHAS SOLICITAÇÕES DE REMOÇÃO
      // ======================================================

      GoRoute(
        path: '/minhas-solicitacoes-remocao',
        redirect: _verificarAutenticacao,
        builder: (context, state) {
          return const MinhasSolicitacoesRemocaoPage();
        },
      ),

      // ======================================================
      // ADMIN OBRAS
      // ======================================================

      GoRoute(
        path: '/admin-obras',
        redirect: _verificarAdministrador,
        builder: (context, state) {
          return const AdminObrasPage();
        },
      ),

      // ======================================================
      // ADMIN BUSCA
      // ======================================================

      GoRoute(
        path: '/admin-obras/resultados/:query',
        redirect: _verificarAdministrador,
        builder: (context, state) {
          final query =
              state.pathParameters['query'] ?? '';

          return AdminSearchResultsPage(
            query: query,
          );
        },
      ),

      // ======================================================
      // ADMIN DENÚNCIAS
      // ======================================================

      GoRoute(
        path: '/admin-denuncias',
        redirect: _verificarAdministrador,
        builder: (context, state) {
          return const AdminDenunciasPage();
        },
      ),

      // ======================================================
      // ADMIN SOLICITAÇÕES DE REMOÇÃO
      // ======================================================

      GoRoute(
        path: '/admin-solicitacoes-remocao',
        redirect: _verificarAdministrador,
        builder: (context, state) {
          return const AdminSolicitacoesRemocaoPage();
        },
      ),

      // ======================================================
      // ESTATÍSTICAS
      // ======================================================

      GoRoute(
        path: '/estatisticas',
        redirect: _verificarAdministrador,
        builder: (context, state) {
          return const EstatisticaAdminPage();
        },
      ),

      // ======================================================
      // CATEGORIA
      // ======================================================

      GoRoute(
        path: '/categoria/:categoria',
        builder: (context, state) {
          final categoria =
              state.pathParameters['categoria'] ?? '';

          return CategoriaPage(
            tipo: categoria,
          );
        },
      ),

      // ======================================================
      // PESQUISA
      // ======================================================

      GoRoute(
        path: '/pesquisa',
        builder: (context, state) {
          final query =
              state.uri.queryParameters['query'] ?? '';

          return SearchResultsPage(
            query: query,
          );
        },
      ),

      // ======================================================
      // POLÍTICA DE PRIVACIDADE
      // ======================================================

      GoRoute(
        path: '/politica-privacidade',
        builder: (context, state) {
          return const PoliticaPrivacidadePage();
        },
      ),

      // ======================================================
      // TERMOS
      // ======================================================

      GoRoute(
        path: '/termos',
        builder: (context, state) {
          return const TermosPage();
        },
      ),

      // ======================================================
      // CONTACTO
      // ======================================================

      GoRoute(
        path: '/contacto',
        builder: (context, state) {
          return const ContactoPage();
        },
      ),

      // ======================================================
      // COOKIES
      // ======================================================

      GoRoute(
        path: '/cookies',
        builder: (context, state) {
          return const CookiesPage();
        },
      ),
    ],
  );
}

// ==========================================================
// LOGIN COM RETORNO
// ==========================================================

String _rotaLoginComRetorno(
    GoRouterState state,
    ) {
  final localizacao =
  state.uri.toString();

  return Uri(
    path: '/login',
    queryParameters: {
      'redirect': localizacao,
    },
  ).toString();
}

// ==========================================================
// VERIFICAR AUTENTICAÇÃO
// ==========================================================

String? _verificarAutenticacao(
    BuildContext context,
    GoRouterState state,
    ) {
  final usuario =
      Supabase.instance.client.auth.currentUser;

  if (usuario == null) {
    return _rotaLoginComRetorno(state);
  }

  return null;
}

// ==========================================================
// VERIFICAR ADMINISTRADOR
// ==========================================================

Future<String?> _verificarAdministrador(
    BuildContext context,
    GoRouterState state,
    ) async {
  final usuario =
      AuthService.usuarioAtual;

  if (usuario == null) {
    return _rotaLoginComRetorno(state);
  }

  try {
    final administrador =
    await AuthService.ehAdministrador();

    if (!administrador) {
      return '/';
    }

    return null;
  } catch (e) {
    debugPrint(
      'ERRO AO VERIFICAR ADMINISTRADOR: $e',
    );

    return '/';
  }
}

// ==========================================================
// RETORNO DA DENÚNCIA
// ==========================================================

class _ObraRetornoDenunciaPage
    extends StatefulWidget {
  final String id;

  const _ObraRetornoDenunciaPage({
    required this.id,
  });

  @override
  State<_ObraRetornoDenunciaPage> createState() =>
      _ObraRetornoDenunciaPageState();
}

class _ObraRetornoDenunciaPageState
    extends State<_ObraRetornoDenunciaPage> {
  bool _dialogAberto = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _abrirDialog();
    });
  }

  Future<void> _abrirDialog() async {
    if (!mounted || _dialogAberto) {
      return;
    }

    _dialogAberto = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ObraDetalhesDialog(
          id: widget.id,
        );
      },
    );

    if (!mounted) {
      return;
    }

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

