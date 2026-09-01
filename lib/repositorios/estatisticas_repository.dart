import 'package:supabase_flutter/supabase_flutter.dart';

import '../cache/administracao_cache.dart';

// ==========================================================
// MODELO DAS ESTATÍSTICAS
// ==========================================================

class EstatisticasDados {
  final int totalObras;
  final int obrasPublicadas;
  final int obrasPendentes;
  final int obrasRejeitadas;
  final int totalUtilizadores;
  final int totalVisualizacoes;
  final int totalDownloads;
  final Map<String, int> obrasPorCategoria;
  final Map<int, int> obrasPorAno;

  const EstatisticasDados({
    required this.totalObras,
    required this.obrasPublicadas,
    required this.obrasPendentes,
    required this.obrasRejeitadas,
    required this.totalUtilizadores,
    required this.totalVisualizacoes,
    required this.totalDownloads,
    required this.obrasPorCategoria,
    required this.obrasPorAno,
  });

  // ========================================================
  // CONVERTER PARA MAPA
  // ========================================================

  Map<String, dynamic> toMap() {
    return {
      'total_obras': totalObras,
      'obras_publicadas': obrasPublicadas,
      'obras_pendentes': obrasPendentes,
      'obras_rejeitadas': obrasRejeitadas,
      'total_utilizadores': totalUtilizadores,
      'total_visualizacoes': totalVisualizacoes,
      'total_downloads': totalDownloads,
      'obras_por_categoria': obrasPorCategoria,
      'obras_por_ano': obrasPorAno.map(
            (chave, valor) => MapEntry(
          chave.toString(),
          valor,
        ),
      ),
    };
  }

  // ========================================================
  // CONVERTER DO MAPA
  // ========================================================

  factory EstatisticasDados.fromMap(
      Map<String, dynamic> mapa,
      ) {
    final categoriasBrutas =
    mapa['obras_por_categoria'];

    final Map<String, int> categorias = {};

    if (categoriasBrutas is Map) {
      categoriasBrutas.forEach((chave, valor) {
        final numero = _converterInt(valor);

        if (numero != null) {
          categorias[chave.toString()] = numero;
        }
      });
    }

    final anosBrutos =
    mapa['obras_por_ano'];

    final Map<int, int> anos = {};

    if (anosBrutos is Map) {
      anosBrutos.forEach((chave, valor) {
        final ano = int.tryParse(
          chave.toString(),
        );

        final numero = _converterInt(valor);

        if (ano != null && numero != null) {
          anos[ano] = numero;
        }
      });
    }

    return EstatisticasDados(
      totalObras:
      _converterInt(mapa['total_obras']) ?? 0,
      obrasPublicadas:
      _converterInt(mapa['obras_publicadas']) ?? 0,
      obrasPendentes:
      _converterInt(mapa['obras_pendentes']) ?? 0,
      obrasRejeitadas:
      _converterInt(mapa['obras_rejeitadas']) ?? 0,
      totalUtilizadores:
      _converterInt(mapa['total_utilizadores']) ?? 0,
      totalVisualizacoes:
      _converterInt(mapa['total_visualizacoes']) ?? 0,
      totalDownloads:
      _converterInt(mapa['total_downloads']) ?? 0,
      obrasPorCategoria: categorias,
      obrasPorAno: anos,
    );
  }

  // ========================================================
  // CONVERTER VALOR PARA INT
  // ========================================================

  static int? _converterInt(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    if (valor != null) {
      return int.tryParse(
        valor.toString(),
      );
    }

    return null;
  }
}

// ==========================================================
// ESTATISTICAS REPOSITORY
// ==========================================================

class EstatisticasRepository {
  EstatisticasRepository._interno();

  static final EstatisticasRepository instancia =
  EstatisticasRepository._interno();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  final AdministracaoCache _cache =
      AdministracaoCache.instancia;

  // ========================================================
  // CARREGAR DO CACHE
  // ========================================================

  Future<EstatisticasDados?> carregarDoCache() async {
    try {
      final dados =
      await _cache.lerEstatisticas();

      if (dados == null) {
        return null;
      }

      return EstatisticasDados.fromMap(
        dados,
      );
    } catch (_) {
      return null;
    }
  }

  // ========================================================
  // CARREGAR ESTATÍSTICAS
  //
  // Mantido para compatibilidade com outras páginas.
  //
  // Primeiro tenta cache.
  // Se não houver cache, consulta o Supabase.
  // ========================================================

  Future<EstatisticasDados> carregarEstatisticas() async {
    final cache =
    await carregarDoCache();

    if (cache != null) {
      return cache;
    }

    return atualizarEstatisticas();
  }

  // ========================================================
  // ATUALIZAR ESTATÍSTICAS PELO SUPABASE
  // ========================================================

  Future<EstatisticasDados> atualizarEstatisticas() async {
    try {
      // ====================================================
      // OBRAS PUBLICADAS
      // ====================================================

      final respostaPublicadas =
      await _supabase
          .from('obras')
          .select(
        'id, categoria, ano_obra, status, data_publicacao',
      );

      // ====================================================
      // OBRAS PENDENTES / REJEITADAS
      // ====================================================

      final respostaPendentes =
      await _supabase
          .from('obras_pendentes')
          .select(
        'id, categoria, ano_obra, status, data_envio',
      );

      // ====================================================
      // UTILIZADORES
      // ====================================================

      final respostaUtilizadores =
      await _supabase
          .from('profiles')
          .select('id');

      // ====================================================
      // MÉTRICAS
      //
      // Tabela:
      // obra_metricas
      //
      // Campos:
      // id
      // obra_id
      // tipo
      // created_at
      // ====================================================

      final respostaMetricas =
      await _supabase
          .from('obra_metricas')
          .select(
        'id, obra_id, tipo, created_at',
      );

      final publicadas =
      List<Map<String, dynamic>>.from(
        respostaPublicadas,
      );

      final pendentes =
      List<Map<String, dynamic>>.from(
        respostaPendentes,
      );

      final metricas =
      List<Map<String, dynamic>>.from(
        respostaMetricas,
      );

      // ====================================================
      // CONTADORES
      // ====================================================

      int obrasPublicadas = 0;
      int obrasPendentes = 0;
      int obrasRejeitadas = 0;

      // ====================================================
      // CONTAR PUBLICADAS
      // ====================================================

      for (final obra in publicadas) {
        final status =
        _normalizarStatus(
          obra['status'],
        );

        if (status == 'aprovada') {
          obrasPublicadas++;
        }
      }

      // ====================================================
      // CONTAR PENDENTES E REJEITADAS
      // ====================================================

      for (final obra in pendentes) {
        final status =
        _normalizarStatus(
          obra['status'],
        );

        if (status == 'pendente') {
          obrasPendentes++;
        }

        if (status == 'rejeitada') {
          obrasRejeitadas++;
        }
      }

      // ====================================================
      // TOTAL DE OBRAS
      // ====================================================

      final totalObras =
          obrasPublicadas +
              obrasPendentes +
              obrasRejeitadas;

      // ====================================================
      // VISUALIZAÇÕES E DOWNLOADS
      // ====================================================

      int totalVisualizacoes = 0;
      int totalDownloads = 0;

      for (final metrica in metricas) {
        final tipo =
            metrica['tipo']
                ?.toString()
                .toLowerCase()
                .trim() ??
                '';

        if (tipo == 'visualizacao' ||
            tipo == 'visualização') {
          totalVisualizacoes++;
        }

        if (tipo == 'download') {
          totalDownloads++;
        }
      }

      // ====================================================
      // OBRAS POR CATEGORIA
      // ====================================================

      final Map<String, int>
      obrasPorCategoria = {};

      for (final obra in publicadas) {
        final status =
        _normalizarStatus(
          obra['status'],
        );

        if (status != 'aprovada') {
          continue;
        }

        final categoria =
            obra['categoria']
                ?.toString()
                .trim() ??
                '';

        final categoriaFinal =
        categoria.isEmpty
            ? 'Sem categoria'
            : categoria;

        obrasPorCategoria[categoriaFinal] =
            (obrasPorCategoria[categoriaFinal] ??
                0) +
                1;
      }

      // ====================================================
      // OBRAS POR ANO
      // ====================================================

      final Map<int, int> obrasPorAno = {};

      for (final obra in publicadas) {
        final status =
        _normalizarStatus(
          obra['status'],
        );

        if (status != 'aprovada') {
          continue;
        }

        int? ano;

        final valorAno =
        obra['ano_obra'];

        if (valorAno is int) {
          ano = valorAno;
        } else if (valorAno != null) {
          ano = int.tryParse(
            valorAno.toString(),
          );
        }

        // ==================================================
        // SE NÃO EXISTIR ANO DA OBRA,
        // USAR O ANO DA DATA DE PUBLICAÇÃO
        // ==================================================

        if (ano == null) {
          final data =
          DateTime.tryParse(
            obra['data_publicacao']
                ?.toString() ??
                '',
          );

          if (data != null) {
            ano = data.year;
          }
        }

        if (ano != null &&
            ano >= 1900 &&
            ano <= DateTime.now().year) {
          obrasPorAno[ano] =
              (obrasPorAno[ano] ?? 0) +
                  1;
        }
      }

      // ====================================================
      // ORDENAR CATEGORIAS
      // ====================================================

      final categoriasOrdenadas =
      Map<String, int>.fromEntries(
        obrasPorCategoria.entries.toList()
          ..sort(
                (a, b) =>
                b.value.compareTo(
                  a.value,
                ),
          ),
      );

      // ====================================================
      // ORDENAR ANOS
      // ====================================================

      final anosOrdenados =
      Map<int, int>.fromEntries(
        obrasPorAno.entries.toList()
          ..sort(
                (a, b) =>
                a.key.compareTo(
                  b.key,
                ),
          ),
      );

      // ====================================================
      // CRIAR OBJETO FINAL
      // ====================================================

      final dados = EstatisticasDados(
        totalObras: totalObras,
        obrasPublicadas:
        obrasPublicadas,
        obrasPendentes:
        obrasPendentes,
        obrasRejeitadas:
        obrasRejeitadas,
        totalUtilizadores:
        respostaUtilizadores.length,
        totalVisualizacoes:
        totalVisualizacoes,
        totalDownloads:
        totalDownloads,
        obrasPorCategoria:
        categoriasOrdenadas,
        obrasPorAno:
        anosOrdenados,
      );

      // ====================================================
      // SALVAR NO CACHE
      // ====================================================

      await _cache.salvarEstatisticas(
        dados.toMap(),
      );

      return dados;
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro ao carregar estatísticas: '
            '${e.message}',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ========================================================
  // NORMALIZAR STATUS
  // ========================================================

  String _normalizarStatus(
      dynamic valor,
      ) {
    final status =
        valor
            ?.toString()
            .toLowerCase()
            .trim() ??
            '';

    switch (status) {
      case 'aprovada':
      case 'aprovado':
      case 'publicada':
      case 'publicado':
        return 'aprovada';

      case 'pendente':
        return 'pendente';

      case 'rejeitada':
      case 'rejeitado':
      case 'recusada':
      case 'recusado':
        return 'rejeitada';

      default:
        return status;
    }
  }
}
