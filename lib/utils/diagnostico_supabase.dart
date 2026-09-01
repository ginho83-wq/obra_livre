import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

class DiagnosticoSupabase {
  DiagnosticoSupabase._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  // ==========================================================
  // LOG PRINCIPAL
  // ==========================================================

  static void log(String mensagem) {
    print('🔍 $mensagem');

    developer.log(
      mensagem,
      name: 'OBRA_LIVRE',
    );
  }

  // ==========================================================
  // INÍCIO DO DIAGNÓSTICO
  // ==========================================================

  static void inicio(String titulo) {
    print('');
    print('════════════════════════════════════');
    print('🔍 DIAGNÓSTICO SUPABASE');
    print('📌 $titulo');
    print('════════════════════════════════════');

    developer.log('');
    developer.log(
      '════════════════════════════════════',
      name: 'OBRA_LIVRE',
    );
    developer.log(
      '🔍 DIAGNÓSTICO SUPABASE',
      name: 'OBRA_LIVRE',
    );
    developer.log(
      '📌 $titulo',
      name: 'OBRA_LIVRE',
    );
    developer.log(
      '════════════════════════════════════',
      name: 'OBRA_LIVRE',
    );
  }

  // ==========================================================
  // FIM DO DIAGNÓSTICO
  // ==========================================================

  static void fim() {
    print('════════════════════════════════════');
    print('');

    developer.log(
      '════════════════════════════════════',
      name: 'OBRA_LIVRE',
    );
    developer.log(
      '',
      name: 'OBRA_LIVRE',
    );
  }

  // ==========================================================
  // VERIFICAR AUTENTICAÇÃO
  // ==========================================================

  static User? verificarAuth() {
    print('🔎 VERIFICANDO AUTENTICAÇÃO...');

    developer.log(
      '🔎 VERIFICANDO AUTENTICAÇÃO...',
      name: 'OBRA_LIVRE',
    );

    try {
      final usuario = _supabase.auth.currentUser;
      final sessao = _supabase.auth.currentSession;

      print(
        '👤 Usuário Auth: ${usuario?.email ?? 'null'}',
      );

      print(
        '🆔 User ID: ${usuario?.id ?? 'null'}',
      );

      print(
        '🔐 Sessão existe: ${sessao != null}',
      );

      developer.log(
        '👤 Usuário Auth: ${usuario?.email ?? 'null'}',
        name: 'OBRA_LIVRE',
      );

      developer.log(
        '🆔 User ID: ${usuario?.id ?? 'null'}',
        name: 'OBRA_LIVRE',
      );

      developer.log(
        '🔐 Sessão existe: ${sessao != null}',
        name: 'OBRA_LIVRE',
      );

      if (usuario == null) {
        print('❌ NÃO EXISTE USUÁRIO AUTENTICADO');

        developer.log(
          '❌ NÃO EXISTE USUÁRIO AUTENTICADO',
          name: 'OBRA_LIVRE',
        );
      } else {
        print('✅ USUÁRIO AUTENTICADO');
        print('📧 Email: ${usuario.email}');
        print('🆔 ID: ${usuario.id}');

        developer.log(
          '✅ USUÁRIO AUTENTICADO',
          name: 'OBRA_LIVRE',
        );

        developer.log(
          '📧 Email: ${usuario.email}',
          name: 'OBRA_LIVRE',
        );

        developer.log(
          '🆔 ID: ${usuario.id}',
          name: 'OBRA_LIVRE',
        );
      }

      return usuario;
    } catch (e, stackTrace) {
      erro(
        'ERRO AO VERIFICAR AUTENTICAÇÃO',
        e,
        stackTrace,
      );

      return null;
    }
  }

  // ==========================================================
  // VERIFICAR PROFILE
  // ==========================================================

  static Future<Map<String, dynamic>?> verificarProfile(
      String userId,
      ) async {
    print('');
    print('🔎 PROCURANDO PROFILE...');
    print('🆔 Profile ID: $userId');

    developer.log(
      '🔎 PROCURANDO PROFILE...',
      name: 'OBRA_LIVRE',
    );

    developer.log(
      '🆔 Profile ID: $userId',
      name: 'OBRA_LIVRE',
    );

    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) {
        print('❌ Existe profiles: false');
        print(
          '❌ Não existe profile para este User ID.',
        );

        developer.log(
          '❌ Existe profiles: false',
          name: 'OBRA_LIVRE',
        );

        developer.log(
          '❌ Não existe profile para este User ID.',
          name: 'OBRA_LIVRE',
        );
      } else {
        print('✅ Existe profiles: true');
        print('📋 Profile: $profile');

        developer.log(
          '✅ Existe profiles: true',
          name: 'OBRA_LIVRE',
        );

        developer.log(
          '📋 Profile: $profile',
          name: 'OBRA_LIVRE',
        );
      }

      return profile;
    } catch (e, stackTrace) {
      erro(
        'ERRO AO CONSULTAR PROFILES',
        e,
        stackTrace,
      );

      return null;
    }
  }

  // ==========================================================
  // TRATAR ERROS
  // ==========================================================

  static void erro(
      String titulo,
      Object erro, [
        StackTrace? stackTrace,
      ]) {
    print('');
    print('❌❌❌ $titulo ❌❌❌');
    print('Tipo: ${erro.runtimeType}');
    print('Mensagem: $erro');

    developer.log(
      '',
      name: 'OBRA_LIVRE',
    );

    developer.log(
      '❌❌❌ $titulo ❌❌❌',
      name: 'OBRA_LIVRE',
    );

    developer.log(
      'Tipo: ${erro.runtimeType}',
      name: 'OBRA_LIVRE',
    );

    developer.log(
      'Mensagem: $erro',
      name: 'OBRA_LIVRE',
    );

    if (erro is PostgrestException) {
      print('🗄️ Código Supabase: ${erro.code}');
      print('🗄️ Detalhes: ${erro.details}');
      print('🗄️ Hint: ${erro.hint}');
      print(
        '🗄️ Mensagem PostgREST: ${erro.message}',
      );

      developer.log(
        '🗄️ Código Supabase: ${erro.code}',
        name: 'OBRA_LIVRE',
      );

      developer.log(
        '🗄️ Detalhes: ${erro.details}',
        name: 'OBRA_LIVRE',
      );

      developer.log(
        '🗄️ Hint: ${erro.hint}',
        name: 'OBRA_LIVRE',
      );

      developer.log(
        '🗄️ Mensagem PostgREST: ${erro.message}',
        name: 'OBRA_LIVRE',
      );
    }

    if (erro is AuthException) {
      print('🔐 Mensagem Auth: ${erro.message}');
      print('🔐 Status: ${erro.statusCode}');

      developer.log(
        '🔐 Mensagem Auth: ${erro.message}',
        name: 'OBRA_LIVRE',
      );

      developer.log(
        '🔐 Status: ${erro.statusCode}',
        name: 'OBRA_LIVRE',
      );
    }

    if (stackTrace != null) {
      print('📚 STACK TRACE:');
      print(stackTrace);

      developer.log(
        '📚 STACK TRACE:',
        name: 'OBRA_LIVRE',
      );

      developer.log(
        stackTrace.toString(),
        name: 'OBRA_LIVRE',
      );
    }

    print('');
  }

  // ==========================================================
  // DIAGNÓSTICO COMPLETO
  // ==========================================================

  static Future<User?> diagnosticar(
      String origem,
      ) async {
    inicio(origem);

    print('▶️ Etapa 1: verificando Auth...');

    final usuario = verificarAuth();

    if (usuario != null) {
      print('▶️ Etapa 2: verificando Profile...');

      await verificarProfile(
        usuario.id,
      );
    } else {
      print(
        '⚠️ Profile não pode ser verificado porque '
            'não existe usuário autenticado.',
      );

      developer.log(
        '⚠️ Profile não pode ser verificado porque '
            'não existe usuário autenticado.',
        name: 'OBRA_LIVRE',
      );
    }

    print('▶️ Diagnóstico concluído.');

    fim();

    return usuario;
  }
}
