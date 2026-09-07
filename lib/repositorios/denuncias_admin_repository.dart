import 'package:supabase_flutter/supabase_flutter.dart';

import '../cache/administracao_cache.dart';

// ==========================================================
// DENUNCIAS ADMIN REPOSITORY
// ==========================================================

class DenunciasAdminRepository {
  DenunciasAdminRepository._();

  static final DenunciasAdminRepository instancia =
  DenunciasAdminRepository._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  final AdministracaoCache _cache =
      AdministracaoCache.instancia;

  // ==========================================================
  // TABELAS
  // ==========================================================

  static const String _tabelaDenuncias =
      'denuncias_obras';

  static const String _tabelaComprovantes =
      'denuncias_comprovantes';

  static const String _tabelaObras =
      'obras';

  static const String _tabelaProfiles =
      'profiles';

  // ==========================================================
  // BUCKETS
  // ==========================================================

  static const String _bucketObras =
      'obras';

  static const String _bucketComprovantes =
      'comprovantes_denuncias';

  // ==========================================================
  // CACHE
  // ==========================================================

  Future<List<Map<String, dynamic>>?>
  carregarDenunciasDoCache() async {
    return _cache.lerLista(
      AdministracaoCache.chaveDenuncias,
    );
  }

  Future<void> _guardarCache(
      List<Map<String, dynamic>> denuncias,
      ) async {
    await _cache.salvarLista(
      AdministracaoCache.chaveDenuncias,
      denuncias,
    );
  }

  Future<void> limparCacheDenuncias() async {
    await _cache.limpar(
      AdministracaoCache.chaveDenuncias,
    );
  }

  // ==========================================================
  // CRIAR DENÚNCIA
  // ==========================================================

  Future<String> criarDenuncia({
    required String obraId,
    required String motivo,
    required String descricao,
  }) async {
    final usuario =
        _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception(
        'É necessário estar autenticado para denunciar uma obra.',
      );
    }

    try {
      final resposta = await _supabase
          .from(_tabelaDenuncias)
          .insert({
        'obra_id': obraId,
        'denunciante_id': usuario.id,
        'motivo': motivo.trim(),
        'descricao': descricao.trim(),
        'status': 'pendente',
      })
          .select('id')
          .single();

      await _invalidarCacheDepoisDeAlteracao();

      return resposta['id'].toString();
    } catch (_) {
      throw Exception(
        'Não foi possível criar a denúncia.',
      );
    }
  }

  // ==========================================================
  // CARREGAR DENÚNCIAS
  // ==========================================================

  Future<List<Map<String, dynamic>>>
  carregarDenuncias() async {
    try {
      final resposta = await _supabase
          .from(_tabelaDenuncias)
          .select(
        '''
            id,
            obra_id,
            denunciante_id,
            motivo,
            descricao,
            status,
            resposta_admin,
            administrador_id,
            criado_em,
            atualizado_em
            ''',
      )
          .order(
        'criado_em',
        ascending: false,
      );

      final denuncias =
      List<Map<String, dynamic>>.from(
        resposta,
      );

      await _carregarDadosRelacionadosEmLote(
        denuncias,
      );

      await _guardarCache(
        denuncias,
      );

      return denuncias;
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível carregar as denúncias: ${e.message}',
      );
    } catch (_) {
      throw Exception(
        'Não foi possível carregar as denúncias.',
      );
    }
  }

  // ==========================================================
  // CARREGAR RELACIONAMENTOS EM LOTE
  // ==========================================================

  Future<void> _carregarDadosRelacionadosEmLote(
      List<Map<String, dynamic>> denuncias,
      ) async {
    if (denuncias.isEmpty) {
      return;
    }

    final obraIds = <String>{};
    final denuncianteIds = <String>{};
    final denunciaIds = <String>{};

    for (final denuncia in denuncias) {
      final obraId =
      denuncia['obra_id']?.toString();

      if (obraId != null &&
          obraId.trim().isNotEmpty) {
        obraIds.add(obraId);
      }

      final denuncianteId =
      denuncia['denunciante_id']?.toString();

      if (denuncianteId != null &&
          denuncianteId.trim().isNotEmpty) {
        denuncianteIds.add(denuncianteId);
      }

      final denunciaId =
      denuncia['id']?.toString();

      if (denunciaId != null &&
          denunciaId.trim().isNotEmpty) {
        denunciaIds.add(denunciaId);
      }
    }

    final Map<String, Map<String, dynamic>>
    obras = {};

    final Map<String, Map<String, dynamic>>
    perfis = {};

    final Map<String, List<Map<String, dynamic>>>
    comprovantes = {};

    // ========================================================
    // OBRAS
    // ========================================================

    if (obraIds.isNotEmpty) {
      try {
        final resposta = await _supabase
            .from(_tabelaObras)
            .select(
          'id,titulo,autor,categoria,ano_obra,descricao,url_documento',
        )
            .inFilter(
          'id',
          obraIds.toList(),
        );

        for (final item in resposta) {
          final mapa =
          Map<String, dynamic>.from(item);

          final id =
          mapa['id']?.toString();

          if (id != null) {
            obras[id] = mapa;
          }
        }
      } catch (_) {
        // Continuar mesmo sem dados da obra.
      }
    }

    // ========================================================
    // PERFIS
    // ========================================================

    if (denuncianteIds.isNotEmpty) {
      try {
        final resposta = await _supabase
            .from(_tabelaProfiles)
            .select()
            .inFilter(
          'id',
          denuncianteIds.toList(),
        );

        for (final item in resposta) {
          final mapa =
          Map<String, dynamic>.from(item);

          final id =
          mapa['id']?.toString();

          if (id != null) {
            perfis[id] = mapa;
          }
        }
      } catch (_) {
        // Continuar mesmo sem perfis.
      }
    }

    // ========================================================
    // COMPROVANTES
    // ========================================================

    if (denunciaIds.isNotEmpty) {
      try {
        final resposta = await _supabase
            .from(_tabelaComprovantes)
            .select(
          'id,denuncia_id,nome_arquivo,tipo_arquivo,'
              'tamanho_bytes,caminho_arquivo,criado_em',
        )
            .inFilter(
          'denuncia_id',
          denunciaIds.toList(),
        )
            .order(
          'criado_em',
          ascending: false,
        );

        for (final item in resposta) {
          final mapa =
          Map<String, dynamic>.from(item);

          final denunciaId =
          mapa['denuncia_id']?.toString();

          if (denunciaId == null) {
            continue;
          }

          comprovantes
              .putIfAbsent(
            denunciaId,
                () => [],
          )
              .add(mapa);
        }
      } catch (_) {
        // Continuar sem comprovantes.
      }
    }

    // ========================================================
    // MONTAR RESULTADO
    // ========================================================

    for (final denuncia in denuncias) {
      final obraId =
      denuncia['obra_id']?.toString();

      final denuncianteId =
      denuncia['denunciante_id']?.toString();

      final denunciaId =
      denuncia['id']?.toString();

      denuncia['obra'] =
      obraId != null
          ? obras[obraId]
          : null;

      denuncia['perfil'] =
      denuncianteId != null
          ? perfis[denuncianteId]
          : null;

      denuncia['comprovantes'] =
      denunciaId != null
          ? comprovantes[denunciaId] ?? []
          : [];
    }
  }

  // ==========================================================
  // CARREGAR POR ID
  // ==========================================================

  Future<Map<String, dynamic>?>
  carregarDenunciaPorId(
      String id,
      ) async {
    try {
      final resposta = await _supabase
          .from(_tabelaDenuncias)
          .select(
        '''
            id,
            obra_id,
            denunciante_id,
            motivo,
            descricao,
            status,
            resposta_admin,
            administrador_id,
            criado_em,
            atualizado_em
            ''',
      )
          .eq(
        'id',
        id,
      )
          .maybeSingle();

      if (resposta == null) {
        return null;
      }

      final denuncia =
      Map<String, dynamic>.from(
        resposta,
      );

      await _carregarDadosRelacionadosEmLote(
        [denuncia],
      );

      return denuncia;
    } catch (_) {
      throw Exception(
        'Não foi possível carregar a denúncia.',
      );
    }
  }

  // ==========================================================
  // ATUALIZAR STATUS
  // ==========================================================

  Future<void> atualizarStatus({
    required String denunciaId,
    required String status,
  }) async {
    const estadosPermitidos = [
      'pendente',
      'em_analise',
      'resolvida',
      'rejeitada',
    ];

    if (!estadosPermitidos.contains(status)) {
      throw Exception(
        'Status de denúncia inválido.',
      );
    }

    if (denunciaId.trim().isEmpty) {
      throw Exception(
        'ID da denúncia não encontrado.',
      );
    }

    try {
      await _supabase
          .from(_tabelaDenuncias)
          .update({
        'status': status,
        'atualizado_em':
        DateTime.now().toIso8601String(),
      })
          .eq(
        'id',
        denunciaId,
      );

      await _atualizarItemCache(
        denunciaId,
        status,
      );
    } catch (_) {
      throw Exception(
        'Não foi possível atualizar a denúncia.',
      );
    }
  }

  // ==========================================================
  // ATUALIZAR ITEM NO CACHE
  // ==========================================================

  Future<void> _atualizarItemCache(
      String denunciaId,
      String novoStatus,
      ) async {
    try {
      final cache =
      await carregarDenunciasDoCache();

      if (cache == null) {
        return;
      }

      for (final item in cache) {
        if (item['id']?.toString() ==
            denunciaId) {
          item['status'] = novoStatus;

          item['atualizado_em'] =
              DateTime.now().toIso8601String();

          break;
        }
      }

      await _guardarCache(cache);
    } catch (_) {
      // Ignorar.
    }
  }

  // ==========================================================
  // RESOLVER DENÚNCIA
  // ==========================================================

  Future<void> resolverDenuncia(
      String denunciaId,
      ) async {
    if (denunciaId.trim().isEmpty) {
      throw Exception(
        'ID da denúncia não encontrado.',
      );
    }

    try {
      final denuncia = await _supabase
          .from(_tabelaDenuncias)
          .select(
        'id,obra_id,status',
      )
          .eq(
        'id',
        denunciaId,
      )
          .maybeSingle();

      if (denuncia == null) {
        throw Exception(
          'Denúncia não encontrada.',
        );
      }

      final statusAtual =
          denuncia['status']?.toString() ?? '';

      if (statusAtual == 'resolvida') {
        throw Exception(
          'Esta denúncia já foi resolvida.',
        );
      }

      if (statusAtual == 'rejeitada') {
        throw Exception(
          'Esta denúncia já foi rejeitada.',
        );
      }

      final obraId =
      denuncia['obra_id']?.toString();

      if (obraId == null ||
          obraId.trim().isEmpty) {
        throw Exception(
          'A denúncia não possui uma obra associada.',
        );
      }

      final obra = await _supabase
          .from(_tabelaObras)
          .select(
        'id,titulo,url_documento',
      )
          .eq(
        'id',
        obraId,
      )
          .maybeSingle();

      if (obra == null) {
        await _marcarComoResolvida(
          denunciaId,
        );

        await _atualizarItemCache(
          denunciaId,
          'resolvida',
        );

        return;
      }

      final urlDocumento =
          obra['url_documento']?.toString() ?? '';

      final caminhoPdf =
      _obterCaminhoStorage(
        urlDocumento,
      );

      if (caminhoPdf != null &&
          caminhoPdf.trim().isNotEmpty) {
        try {
          await _supabase.storage
              .from(_bucketObras)
              .remove([
            caminhoPdf,
          ]);
        } catch (_) {
          // Continuar.
        }
      }

      await _supabase
          .from(_tabelaObras)
          .delete()
          .eq(
        'id',
        obraId,
      );

      await _marcarComoResolvida(
        denunciaId,
      );

      await _atualizarItemCache(
        denunciaId,
        'resolvida',
      );
    } catch (e) {
      if (e is Exception) {
        throw e;
      }

      throw Exception(
        'Não foi possível resolver a denúncia.',
      );
    }
  }

  // ==========================================================
  // MARCAR COMO RESOLVIDA
  // ==========================================================

  Future<void> _marcarComoResolvida(
      String denunciaId,
      ) async {
    await _supabase
        .from(_tabelaDenuncias)
        .update({
      'status': 'resolvida',
      'atualizado_em':
      DateTime.now().toIso8601String(),
    })
        .eq(
      'id',
      denunciaId,
    );
  }

  // ==========================================================
  // STORAGE
  // ==========================================================

  String? _obterCaminhoStorage(
      String valor,
      ) {
    final texto = valor.trim();

    if (texto.isEmpty) {
      return null;
    }

    if (!texto.startsWith('http://') &&
        !texto.startsWith('https://')) {
      return texto;
    }

    final marcadores = [
      '/storage/v1/object/public/$_bucketObras/',
      '/storage/v1/object/sign/$_bucketObras/',
      '/storage/v1/object/authenticated/$_bucketObras/',
    ];

    for (final marcador in marcadores) {
      final indice =
      texto.indexOf(marcador);

      if (indice != -1) {
        final inicio =
            indice + marcador.length;

        if (inicio < texto.length) {
          var caminho =
          texto.substring(inicio);

          final indiceQuery =
          caminho.indexOf('?');

          if (indiceQuery != -1) {
            caminho = caminho.substring(
              0,
              indiceQuery,
            );
          }

          return Uri.decodeFull(
            caminho,
          );
        }
      }
    }

    return null;
  }

  // ==========================================================
  // URL DO COMPROVANTE
  // ==========================================================

  Future<String?> obterUrlComprovante(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      return null;
    }

    try {
      return await _supabase.storage
          .from(_bucketComprovantes)
          .createSignedUrl(
        caminho,
        60 * 10,
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // EXCLUIR DENÚNCIA
  // ==========================================================

  Future<void> excluirDenuncia(
      String denunciaId,
      ) async {
    if (denunciaId.trim().isEmpty) {
      throw Exception(
        'ID da denúncia não encontrado.',
      );
    }

    try {
      final comprovantes = await _supabase
          .from(_tabelaComprovantes)
          .select(
        'caminho_arquivo',
      )
          .eq(
        'denuncia_id',
        denunciaId,
      );

      final caminhos =
      List<Map<String, dynamic>>.from(
        comprovantes,
      )
          .map(
            (item) =>
        item['caminho_arquivo']
            ?.toString() ??
            '',
      )
          .where(
            (caminho) =>
        caminho.trim().isNotEmpty,
      )
          .toList();

      if (caminhos.isNotEmpty) {
        await _supabase.storage
            .from(_bucketComprovantes)
            .remove(
          caminhos,
        );
      }

      await _supabase
          .from(_tabelaComprovantes)
          .delete()
          .eq(
        'denuncia_id',
        denunciaId,
      );

      await _supabase
          .from(_tabelaDenuncias)
          .delete()
          .eq(
        'id',
        denunciaId,
      );

      final cache =
      await carregarDenunciasDoCache();

      if (cache != null) {
        cache.removeWhere(
              (item) =>
          item['id']?.toString() ==
              denunciaId,
        );

        await _guardarCache(cache);
      }
    } catch (_) {
      throw Exception(
        'Não foi possível excluir a denúncia.',
      );
    }
  }

  // ==========================================================
  // INVALIDAR CACHE
  // ==========================================================

  Future<void> _invalidarCacheDepoisDeAlteracao()
  async {
    // Não apagamos necessariamente o cache.
    // O próximo carregamento atualizará os dados.
  }
}

