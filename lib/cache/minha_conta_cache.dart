import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

// ==========================================================
// MINHA CONTA CACHE
// ==========================================================
//
// Responsável por guardar localmente os dados carregados
// da MinhaContaPage.
//
// O Hive funciona apenas como CACHE.
// O Supabase continua sendo a fonte principal dos dados.
//
// ATENÇÃO:
// Este cache NÃO guarda:
// - Atividade recente
// - Última publicação
//
// Esses dados foram removidos da área "Dados da conta".
// ==========================================================

class MinhaContaCache {
  MinhaContaCache._();

  static final MinhaContaCache instancia = MinhaContaCache._();

  // ========================================================
  // CONFIGURAÇÃO
  // ========================================================

  static const String _nomeBox = 'minha_conta_cache';
  static const String _chaveDados = 'dados';

  // Tempo máximo considerado válido para o cache.
  static const Duration validadeCache = Duration(minutes: 10);

  Box<dynamic>? _box;

  // ========================================================
  // INICIALIZAR HIVE
  // ========================================================

  Future<void> inicializar() async {
    if (_box != null && _box!.isOpen) {
      return;
    }

    await Hive.initFlutter();

    _box = await Hive.openBox<dynamic>(_nomeBox);
  }

  // ========================================================
  // BOX
  // ========================================================

  Future<Box<dynamic>> _obterBox() async {
    await inicializar();
    return _box!;
  }

  // ========================================================
  // SALVAR DADOS
  // ========================================================
  //
  // Guarda somente os dados atualmente utilizados
  // pela MinhaContaPage.
  //
  // REMOVIDOS:
  // - atividades
  // - ultimaPublicacao
  // ========================================================

  Future<void> salvarDados({
    required String nomeUsuario,
    required String emailUsuario,
    required int pendentes,
    required int publicadas,
    required int recusadas,
    required int totalObras,
    required int denunciasPendentes,
    required int solicitacoesPendentes,
  }) async {
    final box = await _obterBox();

    final dados = <String, dynamic>{
      'nome_usuario': nomeUsuario,
      'email_usuario': emailUsuario,
      'pendentes': pendentes,
      'publicadas': publicadas,
      'recusadas': recusadas,
      'total_obras': totalObras,
      'denuncias_pendentes': denunciasPendentes,
      'solicitacoes_pendentes': solicitacoesPendentes,
      'atualizado_em': DateTime.now().toIso8601String(),
    };

    await box.put(_chaveDados, dados);
  }

  // ========================================================
  // CARREGAR DADOS
  // ========================================================

  Future<Map<String, dynamic>?> carregarDados() async {
    final box = await _obterBox();

    final dados = box.get(_chaveDados);

    if (dados == null) {
      return null;
    }

    if (dados is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(dados);
  }

  // ========================================================
  // VERIFICAR SE EXISTE CACHE
  // ========================================================

  Future<bool> temCache() async {
    final dados = await carregarDados();

    return dados != null;
  }

  // ========================================================
  // VERIFICAR VALIDADE
  // ========================================================

  Future<bool> cacheValido() async {
    final dados = await carregarDados();

    if (dados == null) {
      return false;
    }

    final atualizadoEm =
    dados['atualizado_em']?.toString();

    if (atualizadoEm == null ||
        atualizadoEm.isEmpty) {
      return false;
    }

    final data = DateTime.tryParse(atualizadoEm);

    if (data == null) {
      return false;
    }

    final diferenca =
    DateTime.now().difference(data);

    return diferenca <= validadeCache;
  }

  // ========================================================
  // DATA DA ÚLTIMA ATUALIZAÇÃO
  // ========================================================

  Future<DateTime?> obterDataAtualizacao() async {
    final dados = await carregarDados();

    if (dados == null) {
      return null;
    }

    final valor =
    dados['atualizado_em']?.toString();

    if (valor == null || valor.isEmpty) {
      return null;
    }

    return DateTime.tryParse(valor);
  }

  // ========================================================
  // LIMPAR CACHE
  // ========================================================

  Future<void> limparCache() async {
    final box = await _obterBox();

    await box.delete(_chaveDados);
  }

  // ========================================================
  // FECHAR BOX
  // ========================================================

  Future<void> fechar() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }

    _box = null;
  }
}
