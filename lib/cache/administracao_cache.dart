import 'dart:convert';

import 'package:hive_ce/hive.dart';

/// ==========================================================
/// ADMINISTRAÇÃO CACHE
/// ==========================================================
/// Cache centralizado da área administrativa.
///
/// Não usa Hive TypeAdapter porque os dados são mapas dinâmicos
/// vindos do Supabase. Os dados são convertidos para JSON antes
/// de serem armazenados, garantindo compatibilidade com mapas,
/// listas, DateTime e outros valores vindos da API.
/// ==========================================================

class AdministracaoCache {
  AdministracaoCache._();

  static final AdministracaoCache instancia =
  AdministracaoCache._();

  static const String _boxName = 'administracao_cache';

  static const String chaveDenuncias =
      'admin_denuncias';

  static const String chaveSolicitacoesPendentes =
      'admin_solicitacoes_pendentes';

  static const String chaveSolicitacoesAprovadas =
      'admin_solicitacoes_aprovadas';

  static const String chaveSolicitacoesRejeitadas =
      'admin_solicitacoes_rejeitadas';

  static const String chaveEstatisticas =
      'admin_estatisticas';

  Future<Box> _obterBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }

    return Hive.openBox(_boxName);
  }

  // ==========================================================
  // SALVAR LISTA
  // ==========================================================

  Future<void> salvarLista(
      String chave,
      List<Map<String, dynamic>> dados,
      ) async {
    try {
      final box = await _obterBox();

      final json = jsonEncode(dados);

      await box.put(chave, json);
    } catch (_) {
      // Cache nunca deve impedir o funcionamento normal.
    }
  }

  // ==========================================================
  // LER LISTA
  // ==========================================================

  Future<List<Map<String, dynamic>>?> lerLista(
      String chave,
      ) async {
    try {
      final box = await _obterBox();

      final valor = box.get(chave);

      if (valor == null) {
        return null;
      }

      if (valor is! String) {
        return null;
      }

      final decodificado = jsonDecode(valor);

      if (decodificado is! List) {
        return null;
      }

      return decodificado
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(
          item as Map,
        ),
      )
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // SALVAR ESTATÍSTICAS
  // ==========================================================

  Future<void> salvarEstatisticas(
      Map<String, dynamic> dados,
      ) async {
    try {
      final box = await _obterBox();

      await box.put(
        chaveEstatisticas,
        jsonEncode(dados),
      );
    } catch (_) {
      // Ignorar erro do cache.
    }
  }

  // ==========================================================
  // LER ESTATÍSTICAS
  // ==========================================================

  Future<Map<String, dynamic>?> lerEstatisticas() async {
    try {
      final box = await _obterBox();

      final valor = box.get(chaveEstatisticas);

      if (valor == null || valor is! String) {
        return null;
      }

      final decodificado = jsonDecode(valor);

      if (decodificado is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(
        decodificado,
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // LIMPAR UMA CHAVE
  // ==========================================================

  Future<void> limpar(String chave) async {
    try {
      final box = await _obterBox();

      await box.delete(chave);
    } catch (_) {
      // Ignorar erro.
    }
  }

  // ==========================================================
  // LIMPAR TODO O CACHE ADMINISTRATIVO
  // ==========================================================

  Future<void> limparTudo() async {
    try {
      final box = await _obterBox();

      await box.clear();
    } catch (_) {
      // Ignorar erro.
    }
  }
}

