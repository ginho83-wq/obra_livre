import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dados/obras_recentes.dart';

// ==========================================================
// OBRAS RECENTES REPOSITORY
// ==========================================================

class ObrasRecentesRepository {
  ObrasRecentesRepository._interno();

  static final ObrasRecentesRepository instancia =
  ObrasRecentesRepository._interno();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ==========================================================
  // CACHE
  // ==========================================================

  static const String _nomeBox =
      'obras_cache';

  static const String _chaveObras =
      'obras';

  static const String _chaveAtualizacao =
      'ultima_atualizacao';

  static const Duration _validadeCache =
  Duration(minutes: 10);

  // ==========================================================
  // BOX
  // ==========================================================

  Future<Box<dynamic>> _obterBox() async {
    if (Hive.isBoxOpen(_nomeBox)) {
      return Hive.box<dynamic>(_nomeBox);
    }

    return await Hive.openBox<dynamic>(
      _nomeBox,
    );
  }

  // ==========================================================
  // CARREGAR OBRAS
  // ==========================================================

  Future<List<ObraRecente>>
  carregarObrasRecentes({
    bool forcarAtualizacao = false,
  }) async {
    try {
      final box = await _obterBox();

      final dadosCache =
      box.get(_chaveObras);

      final ultimaAtualizacao =
      box.get(_chaveAtualizacao);

      if (!forcarAtualizacao &&
          dadosCache != null &&
          ultimaAtualizacao != null) {
        final dataCache =
        DateTime.tryParse(
          ultimaAtualizacao.toString(),
        );

        if (dataCache != null) {
          final idade =
          DateTime.now().difference(
            dataCache,
          );

          if (idade < _validadeCache) {
            final obras =
            _converterCache(
              dadosCache,
            );

            _ordenarPorDataPublicacao(
              obras,
            );

            return obras;
          }
        }
      }

      final obras =
      await _carregarDoSupabase();

      _ordenarPorDataPublicacao(
        obras,
      );

      await _guardarCache(
        box,
        obras,
      );

      return obras;
    } catch (e) {
      try {
        final box =
        await _obterBox();

        final dadosCache =
        box.get(_chaveObras);

        if (dadosCache != null) {
          final obras =
          _converterCache(
            dadosCache,
          );

          _ordenarPorDataPublicacao(
            obras,
          );

          if (obras.isNotEmpty) {
            return obras;
          }
        }
      } catch (_) {}

      throw Exception(
        'Não foi possível carregar as obras.',
      );
    }
  }

  // ==========================================================
  // SUPABASE
  // ==========================================================

  Future<List<ObraRecente>>
  _carregarDoSupabase() async {
    try {
      final response =
      await _supabase
          .from('obras')
          .select(
        'id,'
            'titulo,'
            'descricao,'
            'autor,'
            'coautores,'
            'categoria,'
            'ano_obra,'
            'url_documento,'
            'data_publicacao,'
            'status',
      )
          .eq(
        'status',
        'aprovada',
      )
          .order(
        'data_publicacao',
        ascending: false,
      );

      if (response is! List) {
        return [];
      }

      final obras =
      response.map((item) {
        final mapa =
        Map<String, dynamic>.from(
          item,
        );

        return ObraRecente(
          id: mapa['id']
              ?.toString() ??
              '',
          titulo: mapa['titulo']
              ?.toString() ??
              '',
          resumo: mapa['descricao']
              ?.toString() ??
              '',
          autor: mapa['autor']
              ?.toString() ??
              '',
          coautores:
          mapa['coautores']
              ?.toString() ??
              '',
          categoria:
          mapa['categoria']
              ?.toString() ??
              '',
          anoObra:
          _converterAno(
            mapa['ano_obra'],
          ),
          urlDocumento:
          mapa['url_documento']
              ?.toString() ??
              '',
          dataPublicacao:
          mapa['data_publicacao']
              ?.toString() ??
              '',
          status: 'publicada',
        );
      }).toList();

      _ordenarPorDataPublicacao(
        obras,
      );

      return obras;
    } on PostgrestException catch (
    e) {
      throw Exception(
        'Erro no Supabase: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível carregar as obras recentes.',
      );
    }
  }

  // ==========================================================
  // CONVERTER ANO
  // ==========================================================

  int? _converterAno(
      dynamic valor,
      ) {
    if (valor == null) {
      return null;
    }

    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(
      valor.toString().trim(),
    );
  }

  // ==========================================================
  // ORDENAR
  // ==========================================================

  void _ordenarPorDataPublicacao(
      List<ObraRecente> obras,
      ) {
    obras.sort(
          (a, b) {
        final dataA =
        DateTime.tryParse(
          a.dataPublicacao,
        );

        final dataB =
        DateTime.tryParse(
          b.dataPublicacao,
        );

        if (dataA == null &&
            dataB == null) {
          return 0;
        }

        if (dataA == null) {
          return 1;
        }

        if (dataB == null) {
          return -1;
        }

        return dataB.compareTo(
          dataA,
        );
      },
    );
  }

  // ==========================================================
  // GUARDAR CACHE
  // ==========================================================

  Future<void> _guardarCache(
      Box<dynamic> box,
      List<ObraRecente> obras,
      ) async {
    _ordenarPorDataPublicacao(
      obras,
    );

    final dados = obras
        .map(
          (obra) => obra.toMap(),
    )
        .toList();

    await box.put(
      _chaveObras,
      dados,
    );

    await box.put(
      _chaveAtualizacao,
      DateTime.now()
          .toIso8601String(),
    );
  }

  // ==========================================================
  // CONVERTER CACHE
  // ==========================================================

  List<ObraRecente> _converterCache(
      dynamic dados,
      ) {
    if (dados is! List) {
      return [];
    }

    return dados
        .map<ObraRecente>(
          (item) {
        final mapa =
        Map<String, dynamic>.from(
          item,
        );

        return ObraRecente.fromMap(
          mapa,
        );
      },
    )
        .toList();
  }

  // ==========================================================
  // LIMPAR CACHE
  // ==========================================================

  Future<void> limparCache() async {
    final box =
    await _obterBox();

    await box.delete(
      _chaveObras,
    );

    await box.delete(
      _chaveAtualizacao,
    );
  }

  // ==========================================================
  // ATUALIZAR
  // ==========================================================

  Future<List<ObraRecente>>
  atualizarAgora() async {
    return carregarObrasRecentes(
      forcarAtualizacao: true,
    );
  }
}
