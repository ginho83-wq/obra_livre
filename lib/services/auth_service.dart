import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  // ==========================================================
  // USUÁRIO ATUAL
  // ==========================================================

  static User? get usuarioAtual {
    return _supabase.auth.currentUser;
  }

  // ==========================================================
  // SESSÃO ATUAL
  // ==========================================================

  static Session? get sessaoAtual {
    return _supabase.auth.currentSession;
  }

  // ==========================================================
  // AUTENTICADO
  // ==========================================================

  static bool get estaAutenticado {
    return usuarioAtual != null;
  }

  // ==========================================================
  // OBTER USUÁRIO AUTENTICADO
  // ==========================================================

  static Future<User?> obterUsuarioAutenticado() async {
    final session = _supabase.auth.currentSession;

    if (session != null) {
      developer.log(
        'Sessão encontrada.',
        name: 'AUTH_SERVICE',
      );

      developer.log(
        'User ID: ${session.user.id}',
        name: 'AUTH_SERVICE',
      );

      developer.log(
        'E-mail: ${session.user.email}',
        name: 'AUTH_SERVICE',
      );

      return session.user;
    }

    final user = _supabase.auth.currentUser;

    if (user != null) {
      developer.log(
        'Usuário encontrado em currentUser.',
        name: 'AUTH_SERVICE',
      );

      developer.log(
        'User ID: ${user.id}',
        name: 'AUTH_SERVICE',
      );

      return user;
    }

    developer.log(
      'Nenhum usuário autenticado.',
      name: 'AUTH_SERVICE',
    );

    return null;
  }

  // ==========================================================
  // OBTER PROFILE
  // ==========================================================

  static Future<Map<String, dynamic>?> obterPerfil() async {
    final usuario = await obterUsuarioAutenticado();

    if (usuario == null) {
      developer.log(
        'Não existe usuário autenticado para consultar profile.',
        name: 'AUTH_SERVICE',
      );

      return null;
    }

    try {
      developer.log(
        'Consultando profiles para ${usuario.id}',
        name: 'AUTH_SERVICE',
      );

      final perfil = await _supabase
          .from('profiles')
          .select('id, role, nome_completo')
          .eq('id', usuario.id)
          .maybeSingle();

      if (perfil == null) {
        developer.log(
          'PROFILE NÃO ENCONTRADO.',
          name: 'AUTH_SERVICE',
        );
      } else {
        developer.log(
          'PROFILE ENCONTRADO: $perfil',
          name: 'AUTH_SERVICE',
        );
      }

      return perfil;
    } on PostgrestException catch (e, stackTrace) {
      developer.log(
        'ERRO AO CONSULTAR PROFILES',
        name: 'AUTH_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );

      developer.log(
        'Código: ${e.code}',
        name: 'AUTH_SERVICE',
      );

      developer.log(
        'Mensagem: ${e.message}',
        name: 'AUTH_SERVICE',
      );

      developer.log(
        'Detalhes: ${e.details}',
        name: 'AUTH_SERVICE',
      );

      developer.log(
        'Hint: ${e.hint}',
        name: 'AUTH_SERVICE',
      );

      return null;
    }
  }

  // ==========================================================
  // VERIFICAR ADMIN
  // ==========================================================

  static Future<bool> ehAdministrador() async {
    final perfil = await obterPerfil();

    if (perfil == null) {
      return false;
    }

    final role = perfil['role']
        ?.toString()
        .trim()
        .toLowerCase();

    developer.log(
      'ROLE DO UTILIZADOR: $role',
      name: 'AUTH_SERVICE',
    );

    return role == 'admin';
  }

  // ==========================================================
  // NOME DO USUÁRIO
  // ==========================================================

  static String? obterNomeUsuario() {
    final usuario = usuarioAtual;

    if (usuario == null) {
      return null;
    }

    final metadata = usuario.userMetadata;

    final nome =
        metadata?['nome_completo'] ??
            metadata?['nome'] ??
            usuario.email?.split('@').first;

    return nome?.toString();
  }

  // ==========================================================
  // SAIR
  // ==========================================================

  static Future<void> sair() async {
    developer.log(
      'Encerrando sessão...',
      name: 'AUTH_SERVICE',
    );

    await _supabase.auth.signOut();

    developer.log(
      'Sessão encerrada.',
      name: 'AUTH_SERVICE',
    );
  }
}
