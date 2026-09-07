import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositorios/obras_recentes_repository.dart';

class ObrasPendentesRepository {
  ObrasPendentesRepository._interno();

  static final ObrasPendentesRepository instancia =
  ObrasPendentesRepository._interno();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  static const String bucketPendentes =
      'obras_pendentes';

  static const String bucketPublico =
      'obras';

  // ==========================================================
  // NORMALIZAR PESQUISA
  // ==========================================================

  String _normalizarPesquisa(
      String pesquisa,
      ) {
    return pesquisa
        .trim()
        .replaceAll(',', ' ')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
  }

  // ==========================================================
  // LISTAR OBRAS PENDENTES
  // ==========================================================

  Future<List<Map<String, dynamic>>>
  carregarObrasPendentes({
    String pesquisa = '',
  }) async {
    try {
      dynamic consulta = _supabase
          .from('obras_pendentes')
          .select()
          .eq(
        'status',
        'pendente',
      );

      final termo =
      _normalizarPesquisa(
        pesquisa,
      );

      if (termo.isNotEmpty) {
        final anoPesquisa =
        int.tryParse(termo);

        if (anoPesquisa != null &&
            anoPesquisa >= 1900 &&
            anoPesquisa <=
                DateTime.now().year) {
          consulta = consulta.or(
            'titulo.ilike.%$termo%,'
                'descricao.ilike.%$termo%,'
                'autor.ilike.%$termo%,'
                'coautores.ilike.%$termo%,'
                'instituicao.ilike.%$termo%,'
                'curso.ilike.%$termo%,'
                'categoria.ilike.%$termo%,'
                'area.ilike.%$termo%,'
                'palavras_chave.ilike.%$termo%,'
                'ano_obra.eq.$anoPesquisa',
          );
        } else {
          consulta = consulta.or(
            'titulo.ilike.%$termo%,'
                'descricao.ilike.%$termo%,'
                'autor.ilike.%$termo%,'
                'coautores.ilike.%$termo%,'
                'instituicao.ilike.%$termo%,'
                'curso.ilike.%$termo%,'
                'categoria.ilike.%$termo%,'
                'area.ilike.%$termo%,'
                'palavras_chave.ilike.%$termo%',
          );
        }
      }

      final response =
      await consulta.order(
        'data_envio',
        ascending: false,
      );

      return List<
          Map<String, dynamic>>.from(
        response,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro ao carregar obras pendentes: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível carregar obras pendentes: $e',
      );
    }
  }

  // ==========================================================
  // LISTAR OBRAS PUBLICADAS
  // ==========================================================

  Future<List<Map<String, dynamic>>>
  carregarObrasPublicadas({
    String pesquisa = '',
  }) async {
    try {
      dynamic consulta = _supabase
          .from('obras')
          .select()
          .eq(
        'status',
        'aprovada',
      );

      final termo =
      _normalizarPesquisa(
        pesquisa,
      );

      if (termo.isNotEmpty) {
        final anoPesquisa =
        int.tryParse(termo);

        if (anoPesquisa != null &&
            anoPesquisa >= 1900 &&
            anoPesquisa <=
                DateTime.now().year) {
          consulta = consulta.or(
            'titulo.ilike.%$termo%,'
                'descricao.ilike.%$termo%,'
                'autor.ilike.%$termo%,'
                'coautores.ilike.%$termo%,'
                'instituicao.ilike.%$termo%,'
                'curso.ilike.%$termo%,'
                'categoria.ilike.%$termo%,'
                'area.ilike.%$termo%,'
                'palavras_chave.ilike.%$termo%,'
                'ano_obra.eq.$anoPesquisa',
          );
        } else {
          consulta = consulta.or(
            'titulo.ilike.%$termo%,'
                'descricao.ilike.%$termo%,'
                'autor.ilike.%$termo%,'
                'coautores.ilike.%$termo%,'
                'instituicao.ilike.%$termo%,'
                'curso.ilike.%$termo%,'
                'categoria.ilike.%$termo%,'
                'area.ilike.%$termo%,'
                'palavras_chave.ilike.%$termo%',
          );
        }
      }

      final response =
      await consulta.order(
        'data_publicacao',
        ascending: false,
      );

      return List<
          Map<String, dynamic>>.from(
        response,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro ao carregar obras publicadas: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível carregar obras publicadas: $e',
      );
    }
  }

  // ==========================================================
  // APROVAR OBRA
  // ==========================================================

  Future<void> aprovarObra(
      String id,
      ) async {
    final administrador =
        _supabase.auth.currentUser;

    if (administrador == null) {
      throw Exception(
        'Administrador não autenticado.',
      );
    }

    try {
      // ======================================================
      // BUSCAR OBRA PENDENTE
      // ======================================================

      final resultado =
      await _supabase
          .from('obras_pendentes')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (resultado == null) {
        throw Exception(
          'Obra pendente não encontrada.',
        );
      }

      final obra =
      Map<String, dynamic>.from(
        resultado,
      );

      // ======================================================
      // CAMINHO DO ARQUIVO
      // ======================================================

      final caminho =
      obra['caminho_arquivo']
          ?.toString();

      if (caminho == null ||
          caminho.isEmpty) {
        throw Exception(
          'A obra não possui caminho de arquivo.',
        );
      }

      // ======================================================
      // ANO DA OBRA
      // ======================================================

      int? anoObra;

      final valorAno =
      obra['ano_obra'];

      if (valorAno != null) {
        if (valorAno is int) {
          anoObra = valorAno;
        } else if (valorAno is num) {
          anoObra = valorAno.toInt();
        } else {
          anoObra = int.tryParse(
            valorAno.toString(),
          );
        }
      }

      // ======================================================
      // VALIDAR ANO
      // ======================================================

      if (anoObra != null) {
        final anoAtual =
            DateTime.now().year;

        if (anoObra < 1900 ||
            anoObra > anoAtual) {
          throw Exception(
            'O ano da obra é inválido.',
          );
        }
      }

      // ======================================================
      // BAIXAR PDF DO BUCKET PENDENTE
      // ======================================================

      final bytes =
      await _supabase.storage
          .from(bucketPendentes)
          .download(caminho);

      // ======================================================
      // ENVIAR PDF PARA BUCKET PÚBLICO
      // ======================================================

      await _supabase.storage
          .from(bucketPublico)
          .uploadBinary(
        caminho,
        bytes,
        fileOptions:
        const FileOptions(
          contentType:
          'application/pdf',
          upsert: true,
        ),
      );

      // ======================================================
      // GERAR URL PÚBLICA
      // ======================================================

      final urlDocumento =
      _supabase.storage
          .from(bucketPublico)
          .getPublicUrl(
        caminho,
      );

      // ======================================================
      // DATA DE PUBLICAÇÃO
      // ======================================================

      final dataPublicacao =
      DateTime.now()
          .toIso8601String();

      // ======================================================
      // DADOS DA OBRA PUBLICADA
      // ======================================================

      final dadosObra = {
        'user_id':
        obra['user_id'],

        'titulo':
        obra['titulo'],

        'autor':
        obra['autor'],

        // ==================================================
        // COAUTORES
        // ==================================================

        'coautores':
        obra['coautores'],

        'instituicao':
        obra['instituicao'],

        'curso':
        obra['curso'],

        'ano_obra':
        anoObra,

        'categoria':
        obra['categoria'],

        'area':
        obra['area'],

        'descricao':
        obra['descricao'],

        'palavras_chave':
        obra['palavras_chave'],

        'nome_arquivo':
        obra['nome_arquivo'],

        'tamanho_arquivo':
        obra['tamanho_arquivo'],

        'caminho_arquivo':
        caminho,

        'url_documento':
        urlDocumento,

        'data_publicacao':
        dataPublicacao,

        'status':
        'aprovada',
      };

      // ======================================================
      // INSERIR NA TABELA OBRAS
      // ======================================================

      await _supabase
          .from('obras')
          .insert(dadosObra);

      // ======================================================
      // LIMPAR CACHE
      // ======================================================

      await ObrasRecentesRepository
          .instancia
          .limparCache();

      // ======================================================
      // ATUALIZAR STATUS DA OBRA PENDENTE
      // ======================================================

      await _supabase
          .from('obras_pendentes')
          .update({
        'status':
        'aprovada',
        'analisado_por':
        administrador.id,
        'data_analise':
        DateTime.now()
            .toIso8601String(),
      }).eq(
        'id',
        id,
      );

      // ======================================================
      // REMOVER PDF DO BUCKET PENDENTE
      // ======================================================

      await _supabase.storage
          .from(bucketPendentes)
          .remove([
        caminho,
      ]);
    } on StorageException catch (e) {
      throw Exception(
        'Erro no Storage: ${e.message}',
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro no banco de dados: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível aprovar a obra: $e',
      );
    }
  }

  // ==========================================================
  // REJEITAR OBRA
  // ==========================================================

  Future<void> rejeitarObra({
    required String id,
    required String motivo,
  }) async {
    final administrador =
        _supabase.auth.currentUser;

    if (administrador == null) {
      throw Exception(
        'Administrador não autenticado.',
      );
    }

    if (motivo.trim().isEmpty) {
      throw Exception(
        'Informe o motivo da rejeição.',
      );
    }

    try {
      await _supabase
          .from('obras_pendentes')
          .update({
        'status':
        'rejeitada',
        'motivo_rejeicao':
        motivo.trim(),
        'analisado_por':
        administrador.id,
        'data_analise':
        DateTime.now()
            .toIso8601String(),
      }).eq(
        'id',
        id,
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro ao rejeitar obra: ${e.message}',
      );
    }
  }

  // ==========================================================
  // EXCLUIR OBRA PUBLICADA
  // ==========================================================

  Future<void> excluirObra(
      String id,
      ) async {
    final administrador =
        _supabase.auth.currentUser;

    if (administrador == null) {
      throw Exception(
        'Administrador não autenticado.',
      );
    }

    try {
      final resultado =
      await _supabase
          .from('obras')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (resultado == null) {
        throw Exception(
          'Obra publicada não encontrada.',
        );
      }

      final obra =
      Map<String, dynamic>.from(
        resultado,
      );

      final caminho =
      obra['caminho_arquivo']
          ?.toString();

      if (caminho != null &&
          caminho.isNotEmpty) {
        await _supabase.storage
            .from(bucketPublico)
            .remove([
          caminho,
        ]);
      }

      await _supabase
          .from('obras')
          .delete()
          .eq(
        'id',
        id,
      );

      await ObrasRecentesRepository
          .instancia
          .limparCache();
    } on StorageException catch (e) {
      throw Exception(
        'Erro ao remover o arquivo: ${e.message}',
      );
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro ao excluir a obra do banco de dados: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível excluir a obra: $e',
      );
    }
  }
}
