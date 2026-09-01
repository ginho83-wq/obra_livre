import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================================
// MODELO DO ACERVO
// ==========================================================

class AcervoObra {
  final String id;
  final String titulo;
  final String descricao;
  final String autor;
  final String coautores;
  final String categoria;
  final String urlDocumento;
  final DateTime? dataPublicacao;
  final int? anoObra;
  final int? tamanhoArquivo;

  const AcervoObra({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.autor,
    required this.coautores,
    required this.categoria,
    required this.urlDocumento,
    required this.dataPublicacao,
    required this.anoObra,
    required this.tamanhoArquivo,
  });

  // ========================================================
  // FROM MAP
  // ========================================================

  factory AcervoObra.fromMap(
      Map<String, dynamic> mapa,
      ) {
    DateTime? data;

    final valorData =
    mapa['data_publicacao'];

    if (valorData != null) {
      data = DateTime.tryParse(
        valorData.toString(),
      );
    }

    int? ano;

    final valorAno =
    mapa['ano_obra'];

    if (valorAno != null) {
      if (valorAno is int) {
        ano = valorAno;
      } else if (valorAno is num) {
        ano = valorAno.toInt();
      } else {
        ano = int.tryParse(
          valorAno.toString().trim(),
        );
      }
    }

    int? tamanho;

    final valorTamanho =
    mapa['tamanho_arquivo'];

    if (valorTamanho != null) {
      if (valorTamanho is int) {
        tamanho = valorTamanho;
      } else if (valorTamanho is num) {
        tamanho = valorTamanho.toInt();
      } else {
        tamanho = int.tryParse(
          valorTamanho.toString().trim(),
        );
      }
    }

    return AcervoObra(
      id: mapa['id']?.toString() ?? '',
      titulo:
      mapa['titulo']?.toString() ?? '',
      descricao:
      mapa['descricao']?.toString() ?? '',
      autor:
      mapa['autor']?.toString() ?? '',
      coautores:
      mapa['coautores']?.toString() ?? '',
      categoria:
      mapa['categoria']?.toString() ?? '',
      urlDocumento:
      mapa['url_documento']?.toString() ??
          '',
      dataPublicacao: data,
      anoObra: ano,
      tamanhoArquivo: tamanho,
    );
  }
}

// ==========================================================
// ACERVO REPOSITORY
// ==========================================================

class AcervoRepository {
  AcervoRepository._interno();

  static final AcervoRepository instancia =
  AcervoRepository._interno();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ========================================================
  // CATEGORIAS
  // ========================================================

  static const List<String> categorias = [
    'Todas',
    'Tese de Doutoramento',
    'Dissertação de Mestrado',
    'Monografia',
    'Artigos Científicos',
    'Literatura',
  ];

  // ========================================================
  // CAMPOS
  // ========================================================

  static const String _campos =
      'id,'
      'titulo,'
      'descricao,'
      'autor,'
      'coautores,'
      'categoria,'
      'url_documento,'
      'data_publicacao,'
      'ano_obra,'
      'tamanho_arquivo';

  // ========================================================
  // UUID
  // ========================================================

  bool _ehUuid(
      String valor,
      ) {
    final texto = valor.trim();

    final regex = RegExp(
      r'^[0-9a-fA-F]{8}-'
      r'[0-9a-fA-F]{4}-'
      r'[1-5][0-9a-fA-F]{3}-'
      r'[89abAB][0-9a-fA-F]{3}-'
      r'[0-9a-fA-F]{12}$',
    );

    return regex.hasMatch(texto);
  }

  // ========================================================
  // CONVERTER LISTA
  // ========================================================

  List<AcervoObra> _converterLista(
      dynamic resposta,
      ) {
    if (resposta is! List) {
      return [];
    }

    return resposta
        .map(
          (item) => AcervoObra.fromMap(
        Map<String, dynamic>.from(
          item,
        ),
      ),
    )
        .toList();
  }

  // ========================================================
  // VISUALIZAÇÃO
  // ========================================================

  Future<void> registarVisualizacao(
      String obraId,
      ) async {
    final id = obraId.trim();

    if (id.isEmpty || !_ehUuid(id)) {
      return;
    }

    try {
      await _supabase
          .from('obra_metricas')
          .insert({
        'obra_id': id,
        'tipo': 'visualizacao',
      });
    } catch (_) {}
  }

  // ========================================================
  // DOWNLOAD
  // ========================================================

  Future<void> registarDownload(
      String obraId,
      ) async {
    final id = obraId.trim();

    if (id.isEmpty || !_ehUuid(id)) {
      return;
    }

    try {
      await _supabase
          .from('obra_metricas')
          .insert({
        'obra_id': id,
        'tipo': 'download',
      });
    } catch (_) {}
  }

  // ========================================================
  // CARREGAR UMA OBRA
  // ========================================================

  Future<AcervoObra?> carregarObraPorId(
      String identificador,
      ) async {
    try {
      final valor =
      identificador.trim();

      if (valor.isEmpty) {
        return null;
      }

      dynamic resposta;

      if (_ehUuid(valor)) {
        resposta = await _supabase
            .from('obras')
            .select(_campos)
            .eq('id', valor)
            .eq(
          'status',
          'aprovada',
        )
            .maybeSingle();
      } else {
        final resultados =
        await _supabase
            .from('obras')
            .select(_campos)
            .eq(
          'titulo',
          valor,
        )
            .eq(
          'status',
          'aprovada',
        )
            .limit(1);

        if (resultados is List &&
            resultados.isNotEmpty) {
          resposta = resultados.first;
        }
      }

      if (resposta == null) {
        return null;
      }

      final mapa =
      Map<String, dynamic>.from(
        resposta,
      );

      return AcervoObra.fromMap(
        mapa,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro no Supabase: ${e.message}',
      );
    } catch (_) {
      throw Exception(
        'Não foi possível carregar a obra.',
      );
    }
  }

  // ========================================================
  // TODAS AS OBRAS
  // ========================================================

  Future<List<AcervoObra>>
  carregarObras() async {
    try {
      final resposta =
      await _supabase
          .from('obras')
          .select(_campos)
          .eq(
        'status',
        'aprovada',
      )
          .order(
        'data_publicacao',
        ascending: false,
      );

      return _converterLista(
        resposta,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro no Supabase: ${e.message}',
      );
    } catch (_) {
      throw Exception(
        'Não foi possível carregar o acervo.',
      );
    }
  }

  // ========================================================
  // POR CATEGORIA
  // ========================================================

  Future<List<AcervoObra>>
  carregarPorCategoria(
      String categoria,
      ) async {
    try {
      final resposta =
      await _supabase
          .from('obras')
          .select(_campos)
          .eq(
        'status',
        'aprovada',
      )
          .eq(
        'categoria',
        categoria,
      )
          .order(
        'data_publicacao',
        ascending: false,
      );

      return _converterLista(
        resposta,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro no Supabase: ${e.message}',
      );
    } catch (_) {
      throw Exception(
        'Não foi possível carregar esta categoria.',
      );
    }
  }

  // ========================================================
  // PESQUISA
  // ========================================================

  Future<List<AcervoObra>> pesquisarAcervo({
    String query = '',
    String categoria = 'Todas',
    int? ano,
    String autor = '',
    String ordenacao = 'Mais recentes',
  }) async {
    try {
      dynamic consulta =
      _supabase
          .from('obras')
          .select(_campos)
          .eq(
        'status',
        'aprovada',
      );

      if (categoria.trim().isNotEmpty &&
          categoria != 'Todas') {
        consulta = consulta.eq(
          'categoria',
          categoria,
        );
      }

      if (ano != null) {
        consulta = consulta.eq(
          'ano_obra',
          ano,
        );
      }

      final pesquisaAutor =
      autor.trim();

      if (pesquisaAutor.isNotEmpty) {
        final autorSeguro =
        pesquisaAutor.replaceAll(
          ',',
          ' ',
        );

        consulta = consulta.ilike(
          'autor',
          '%$autorSeguro%',
        );
      }

      final pesquisa =
      query.trim();

      if (pesquisa.isNotEmpty) {
        final pesquisaSegura =
        pesquisa.replaceAll(
          ',',
          ' ',
        );

        consulta = consulta.or(
          'titulo.ilike.%$pesquisaSegura%,'
              'descricao.ilike.%$pesquisaSegura%,'
              'autor.ilike.%$pesquisaSegura%,'
              'coautores.ilike.%$pesquisaSegura%,'
              'categoria.ilike.%$pesquisaSegura%',
        );
      }

      if (ordenacao ==
          'Mais antigas') {
        consulta = consulta.order(
          'data_publicacao',
          ascending: true,
        );
      } else if (ordenacao ==
          'Título A–Z') {
        consulta = consulta.order(
          'titulo',
          ascending: true,
        );
      } else {
        consulta = consulta.order(
          'data_publicacao',
          ascending: false,
        );
      }

      final resposta =
      await consulta;

      return _converterLista(
        resposta,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro no Supabase: ${e.message}',
      );
    } catch (_) {
      throw Exception(
        'Não foi possível pesquisar o acervo.',
      );
    }
  }

  // ========================================================
  // OBRAS RECENTES
  // ========================================================

  Future<List<AcervoObra>>
  carregarObrasRecentes() async {
    try {
      final resposta =
      await _supabase
          .from('obras')
          .select(_campos)
          .eq(
        'status',
        'aprovada',
      )
          .order(
        'data_publicacao',
        ascending: false,
      );

      return _converterLista(
        resposta,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro no Supabase: ${e.message}',
      );
    } catch (_) {
      throw Exception(
        'Não foi possível carregar as obras recentes.',
      );
    }
  }

  // ========================================================
  // DESTAQUES
  // ========================================================

  Future<List<AcervoObra>>
  carregarDestaques({
    int limite = 4,
  }) async {
    try {
      final resposta =
      await _supabase
          .from('obras')
          .select(_campos)
          .eq(
        'status',
        'aprovada',
      )
          .order(
        'data_publicacao',
        ascending: false,
      )
          .limit(limite);

      return _converterLista(
        resposta,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro no Supabase: ${e.message}',
      );
    } catch (_) {
      throw Exception(
        'Não foi possível carregar os destaques.',
      );
    }
  }
}

