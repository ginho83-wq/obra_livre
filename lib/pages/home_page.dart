
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositorios/historico_consultas_repository.dart';
import '../widgets/categories_horizontal_widget.dart';
import '../widgets/footer_widget.dart';
import '../widgets/obras_recentes_widget.dart';
import '../widgets/search_bar.dart';
import '../widgets/trabalhos_consultados_widget.dart';
import '../widgets/web_ad_sense_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final HistoricoConsultasRepository _historico =
      HistoricoConsultasRepository.instancia;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _inicializarHistorico();

    _authSubscription = _supabase.auth.onAuthStateChange.listen(
          (data) async {
        final evento = data.event;

        if (evento == AuthChangeEvent.signedIn ||
            evento == AuthChangeEvent.tokenRefreshed) {
          await _historico.sincronizarHistoricoLocal();

          if (mounted) {
            setState(() {});
          }
        }

        if (evento == AuthChangeEvent.signedOut) {
          if (mounted) {
            setState(() {});
          }
        }
      },
    );
  }

  Future<void> _inicializarHistorico() async {
    await _historico.inicializar();

    final usuario = _supabase.auth.currentUser;

    if (usuario != null) {
      await _historico.sincronizarHistoricoLocal();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _sair() async {
    try {
      await _supabase.auth.signOut();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sessão terminada com sucesso.',
          ),
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao terminar sessão: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // NOME DO UTILIZADOR
  // ==========================================================

  String _nomeUsuario(User usuario) {
    final metadata = usuario.userMetadata;

    final nomeCompleto =
    metadata?['nome_completo']?.toString().trim();

    if (nomeCompleto != null && nomeCompleto.isNotEmpty) {
      return nomeCompleto;
    }

    final nomeGoogle =
    metadata?['full_name']?.toString().trim();

    if (nomeGoogle != null && nomeGoogle.isNotEmpty) {
      return nomeGoogle;
    }

    final nome =
    metadata?['name']?.toString().trim();

    if (nome != null && nome.isNotEmpty) {
      return nome;
    }

    final email = usuario.email?.trim();

    if (email != null && email.isNotEmpty) {
      final parteEmail = email.split('@').first.trim();

      if (parteEmail.isNotEmpty) {
        return parteEmail;
      }
    }

    return 'Usuário';
  }

  // ==========================================================
  // BOTÃO DA CONTA
  // ==========================================================

  Widget _botaoConta() {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      return TextButton(
        onPressed: () {
          context.push('/login');
        },
        child: const Text(
          'Entrar',
        ),
      );
    }

    final nome = _nomeUsuario(usuario);

    return TextButton(
      onPressed: () {
        context.push('/minha-conta');
      },
      child: Text(
        nome,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ==========================================================
  // BOTÃO PUBLICAR
  // ==========================================================

  Widget _botaoPublicar() {
    return TextButton(
      onPressed: () {
        context.push('/publicar');
      },
      child: const Text(
        'Publicar',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Obra Livre',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.push('/acervo');
            },
            child: const Text(
              'Acervo',
            ),
          ),

          // ==================================================
          // PUBLICAR
          // ==================================================

          _botaoPublicar(),

          // ==================================================
          // CONTA / NOME DO UTILIZADOR
          // ==================================================

          _botaoConta(),

          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CategoriesHorizontalWidget(),

              const SizedBox(
                height: 8,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: SearchBarWidget(),
              ),

              const SizedBox(
                height: 20,
              ),

              const ObrasRecentesWidget(
                quantidade: 4,
              ),

              const SizedBox(
                height: 8,
              ),

              const TrabalhosConsultadosWidget(
                quantidade: 6,
              ),

              const SizedBox(
                height: 8,
              ),

              const WebAdSenseWidget(),

              const SizedBox(
                height: 20,
              ),

              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }
}


