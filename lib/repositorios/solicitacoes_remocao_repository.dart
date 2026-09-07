import 'package:supabase_flutter/supabase_flutter.dart';

import '../cache/administracao_cache.dart';

// ==========================================================
// MODELO — SOLICITAÇÃO DE REMOÇÃO
// ==========================================================

class SolicitacaoRemocao {
  final String id;
  final String obraId;
  final String usuarioId;
  final String? motivo;
  final String status;
  final String? respostaAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? tituloObra;
  final String? autorObra;

  const SolicitacaoRemocao({
    required this.id,
    required this.obraId,
    required this.usuarioId,
    this.motivo,
    required this.status,
    this.respostaAdmin,
    this.createdAt,
    this.updatedAt,
    this.tituloObra,
    this.autorObra,
  });

  factory SolicitacaoRemocao.fromMap(
      Map<String, dynamic> map,
      ) {
    String? titulo;
    String? autor;

    final obra = map['obras'];

    if (obra is Map) {
      titulo =
          obra['titulo']?.toString();

      autor =
          obra['autor']?.toString();
    }

    return SolicitacaoRemocao(
      id:
      map['id']?.toString() ?? '',
      obraId:
      map['obra_id']?.toString() ?? '',
      usuarioId:
      map['user_id']?.toString() ?? '',
      motivo:
      map['motivo']?.toString(),
      status:
      map['status']?.toString() ??
          'pendente',
      respostaAdmin:
      map['resposta_admin']
          ?.toString(),
      createdAt:
      _parseDate(
        map['created_at'],
      ),
      updatedAt:
      _parseDate(
        map['updated_at'],
      ),
      tituloObra: titulo,
      autorObra: autor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'obra_id': obraId,
      'user_id': usuarioId,
      'motivo': motivo,
      'status': status,
      'resposta_admin':
      respostaAdmin,
      'created_at':
      createdAt
          ?.toIso8601String(),
      'updated_at':
      updatedAt
          ?.toIso8601String(),
      'obras': {
        'titulo': tituloObra,
        'autor': autorObra,
      },
    };
  }

  static DateTime? _parseDate(
      dynamic valor,
      ) {
    if (valor == null) {
      return null;
    }

    if (valor is DateTime) {
      return valor;
    }

    return DateTime.tryParse(
      valor.toString(),
    );
  }
}

// ==========================================================
// REPOSITORY
// ==========================================================

class SolicitacoesRemocaoRepository {
  SolicitacoesRemocaoRepository._();

  static final SolicitacoesRemocaoRepository
  instancia =
  SolicitacoesRemocaoRepository._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  final AdministracaoCache _cache =
      AdministracaoCache.instancia;

  static const String _tabela =
      'solicitacoes_remocao_obras';

  static const String _tabelaObras =
      'obras';

  static const String _bucketObras =
      'obras';

  // ==========================================================
  // UTILIZADOR ATUAL
  // ==========================================================

  String? get usuarioAtualId {
    return _supabase
        .auth
        .currentUser
        ?.id;
  }

  // ==========================================================
  // CHAVE DO CACHE
  // ==========================================================

  String _chaveCachePorStatus(
      String status,
      ) {
    switch (status) {
      case 'aprovada':
        return AdministracaoCache
            .chaveSolicitacoesAprovadas;

      case 'rejeitada':
        return AdministracaoCache
            .chaveSolicitacoesRejeitadas;

      case 'pendente':
      default:
        return AdministracaoCache
            .chaveSolicitacoesPendentes;
    }
  }

  // ==========================================================
  // CARREGAR CACHE
  // ==========================================================

  Future<List<SolicitacaoRemocao>?>
  carregarTodasDoCache({
    String? status,
  }) async {
    try {
      final chave =
      _chaveCachePorStatus(
        status ?? 'pendente',
      );

      final dados =
      await _cache.lerLista(chave);

      if (dados == null) {
        return null;
      }

      return dados
          .map(
            (item) =>
            SolicitacaoRemocao
                .fromMap(item),
      )
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // GUARDAR CACHE
  // ==========================================================

  Future<void> _guardarCache(
      String status,
      List<SolicitacaoRemocao>
      solicitacoes,
      ) async {
    await _cache.salvarLista(
      _chaveCachePorStatus(status),
      solicitacoes
          .map(
            (item) => item.toMap(),
      )
          .toList(),
    );
  }

  // ==========================================================
  // VERIFICAR SOLICITAÇÃO PENDENTE
  // ==========================================================

  Future<bool> existeSolicitacaoPendente(
      String obraId,
      ) async {
    final usuarioId =
        usuarioAtualId;

    if (usuarioId == null) {
      return false;
    }

    try {
      final resposta = await _supabase
          .from(_tabela)
          .select('id')
          .eq(
        'obra_id',
        obraId,
      )
          .eq(
        'user_id',
        usuarioId,
      )
          .eq(
        'status',
        'pendente',
      )
          .limit(1);

      return resposta.isNotEmpty;
    } catch (e) {
      throw Exception(
        'Não foi possível verificar a solicitação: $e',
      );
    }
  }

  // ==========================================================
  // CRIAR SOLICITAÇÃO
  // ==========================================================

  Future<SolicitacaoRemocao>
  criarSolicitacao({
    required String obraId,
    String? motivo,
  }) async {
    final usuarioId =
        usuarioAtualId;

    if (usuarioId == null) {
      throw Exception(
        'É necessário estar autenticado para solicitar a remoção.',
      );
    }

    try {
      final obra = await _supabase
          .from(_tabelaObras)
          .select(
        'id, user_id, titulo, autor',
      )
          .eq(
        'id',
        obraId,
      )
          .maybeSingle();

      if (obra == null) {
        throw Exception(
          'A obra não foi encontrada.',
        );
      }

      final donoId =
      obra['user_id']?.toString();

      if (donoId != usuarioId) {
        throw Exception(
          'Você só pode solicitar a remoção das suas próprias obras.',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível verificar a obra: ${e.message}',
      );
    }

    final existe =
    await existeSolicitacaoPendente(
      obraId,
    );

    if (existe) {
      throw Exception(
        'Já existe uma solicitação de remoção pendente para esta obra.',
      );
    }

    try {
      final dados =
      <String, dynamic>{
        'obra_id': obraId,
        'user_id': usuarioId,
        'status': 'pendente',
      };

      final motivoLimpo =
      motivo?.trim();

      if (motivoLimpo != null &&
          motivoLimpo.isNotEmpty) {
        dados['motivo'] =
            motivoLimpo;
      }

      final resposta =
      await _supabase
          .from(_tabela)
          .insert(dados)
          .select(
        '''
                id,
                obra_id,
                user_id,
                motivo,
                status,
                resposta_admin,
                created_at,
                updated_at,
                obras (
                  titulo,
                  autor
                )
                ''',
      )
          .single();

      final solicitacao =
      SolicitacaoRemocao.fromMap(
        Map<String, dynamic>.from(
          resposta,
        ),
      );

      await _limparCachesSolicitacoes();

      return solicitacao;
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível enviar a solicitação de remoção: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível enviar a solicitação de remoção: $e',
      );
    }
  }

  // ==========================================================
  // CONTAR MINHAS SOLICITAÇÕES
  // ==========================================================

  Future<Map<String, int>>
  contarMinhasSolicitacoesPorStatus()
  async {
    final usuarioId =
        usuarioAtualId;

    if (usuarioId == null) {
      return {
        'pendente': 0,
      };
    }

    try {
      final resposta = await _supabase
          .from(_tabela)
          .select('status')
          .eq(
        'user_id',
        usuarioId,
      );

      int pendente = 0;

      for (final item in resposta) {
        final status =
            item['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
                '';

        if (status == 'pendente') {
          pendente++;
        }
      }

      return {
        'pendente': pendente,
      };
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível carregar o resumo das solicitações: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível carregar o resumo das solicitações: $e',
      );
    }
  }

  // ==========================================================
  // MINHAS SOLICITAÇÕES
  // ==========================================================

  Future<List<SolicitacaoRemocao>>
  carregarMinhasSolicitacoes()
  async {
    final usuarioId =
        usuarioAtualId;

    if (usuarioId == null) {
      return [];
    }

    try {
      final resposta =
      await _supabase
          .from(_tabela)
          .select(
        '''
                id,
                obra_id,
                user_id,
                motivo,
                status,
                resposta_admin,
                created_at,
                updated_at,
                obras (
                  titulo,
                  autor
                )
                ''',
      )
          .eq(
        'user_id',
        usuarioId,
      )
          .order(
        'created_at',
        ascending: false,
      );

      return (resposta as List)
          .map(
            (item) =>
            SolicitacaoRemocao
                .fromMap(
              Map<String, dynamic>.from(
                item,
              ),
            ),
      )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível carregar as suas solicitações: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível carregar as suas solicitações: $e',
      );
    }
  }

  // ==========================================================
  // TODAS AS SOLICITAÇÕES — ADMIN
  // ==========================================================

  Future<List<SolicitacaoRemocao>>
  carregarTodas({
    String? status,
  }) async {
    try {
      var consulta = _supabase
          .from(_tabela)
          .select(
        '''
            id,
            obra_id,
            user_id,
            motivo,
            status,
            resposta_admin,
            created_at,
            updated_at,
            obras (
              titulo,
              autor
            )
            ''',
      );

      if (status != null &&
          status.trim().isNotEmpty) {
        consulta = consulta.eq(
          'status',
          status.trim(),
        );
      }

      final resposta =
      await consulta.order(
        'created_at',
        ascending: false,
      );

      final resultado =
      (resposta as List)
          .map(
            (item) =>
            SolicitacaoRemocao
                .fromMap(
              Map<String, dynamic>.from(
                item,
              ),
            ),
      )
          .toList();

      await _guardarCache(
        status ?? 'pendente',
        resultado,
      );

      return resultado;
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível carregar as solicitações: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível carregar as solicitações: $e',
      );
    }
  }

  // ==========================================================
  // OBTER URL DO PDF
  // ==========================================================

  Future<String?> _obterUrlDocumento(
      String obraId,
      ) async {
    final resposta =
    await _supabase
        .from(_tabelaObras)
        .select(
      'url_documento',
    )
        .eq(
      'id',
      obraId,
    )
        .maybeSingle();

    if (resposta == null) {
      return null;
    }

    return resposta['url_documento']
        ?.toString();
  }

  // ==========================================================
  // EXTRAIR CAMINHO DO STORAGE
  // ==========================================================

  String? _extrairCaminhoStorage(
      String? url,
      ) {
    if (url == null ||
        url.trim().isEmpty) {
      return null;
    }

    final valor = url.trim();

    const marcadorPublico =
        '/storage/v1/object/public/obras/';

    final indicePublico =
    valor.indexOf(
      marcadorPublico,
    );

    if (indicePublico >= 0) {
      return Uri.decodeComponent(
        valor.substring(
          indicePublico +
              marcadorPublico.length,
        ),
      );
    }

    const marcadorAutenticado =
        '/storage/v1/object/authenticated/obras/';

    final indiceAutenticado =
    valor.indexOf(
      marcadorAutenticado,
    );

    if (indiceAutenticado >= 0) {
      return Uri.decodeComponent(
        valor.substring(
          indiceAutenticado +
              marcadorAutenticado.length,
        ),
      );
    }

    if (!valor.startsWith('http://') &&
        !valor.startsWith('https://')) {
      return valor;
    }

    return null;
  }

  // ==========================================================
  // APROVAR
  // ==========================================================

  Future<void> aprovarSolicitacao({
    required String solicitacaoId,
    String? respostaAdmin,
  }) async {
    try {
      final solicitacao =
      await _supabase
          .from(_tabela)
          .select(
        'id, obra_id, status',
      )
          .eq(
        'id',
        solicitacaoId,
      )
          .maybeSingle();

      if (solicitacao == null) {
        throw Exception(
          'A solicitação não foi encontrada.',
        );
      }

      final status =
          solicitacao['status']
              ?.toString() ??
              '';

      if (status != 'pendente') {
        throw Exception(
          'Esta solicitação já foi analisada.',
        );
      }

      final obraId =
          solicitacao['obra_id']
              ?.toString() ??
              '';

      if (obraId.isEmpty) {
        throw Exception(
          'A solicitação não possui uma obra válida.',
        );
      }

      final urlDocumento =
      await _obterUrlDocumento(
        obraId,
      );

      final caminhoStorage =
      _extrairCaminhoStorage(
        urlDocumento,
      );

      await _supabase
          .from(_tabelaObras)
          .delete()
          .eq(
        'id',
        obraId,
      );

      if (caminhoStorage != null &&
          caminhoStorage
              .trim()
              .isNotEmpty) {
        try {
          await _supabase.storage
              .from(_bucketObras)
              .remove([
            caminhoStorage,
          ]);
        } catch (_) {}
      }

      final dados =
      <String, dynamic>{
        'status': 'aprovada',
        'updated_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      };

      final resposta =
      respostaAdmin?.trim();

      if (resposta != null &&
          resposta.isNotEmpty) {
        dados['resposta_admin'] =
            resposta;
      }

      await _supabase
          .from(_tabela)
          .update(dados)
          .eq(
        'id',
        solicitacaoId,
      );

      await _limparCachesSolicitacoes();
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível aprovar a solicitação: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível aprovar a solicitação: $e',
      );
    }
  }

  // ==========================================================
  // REJEITAR
  // ==========================================================

  Future<void> rejeitarSolicitacao({
    required String solicitacaoId,
    String? respostaAdmin,
  }) async {
    try {
      final dados =
      <String, dynamic>{
        'status': 'rejeitada',
        'updated_at':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      };

      final resposta =
      respostaAdmin?.trim();

      if (resposta != null &&
          resposta.isNotEmpty) {
        dados['resposta_admin'] =
            resposta;
      }

      await _supabase
          .from(_tabela)
          .update(dados)
          .eq(
        'id',
        solicitacaoId,
      );

      await _limparCachesSolicitacoes();
    } on PostgrestException catch (e) {
      throw Exception(
        'Não foi possível rejeitar a solicitação: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível rejeitar a solicitação: $e',
      );
    }
  }

  // ==========================================================
  // LIMPAR CACHES
  // ==========================================================

  Future<void> _limparCachesSolicitacoes()
  async {
    await Future.wait([
      _cache.limpar(
        AdministracaoCache
            .chaveSolicitacoesPendentes,
      ),
      _cache.limpar(
        AdministracaoCache
            .chaveSolicitacoesAprovadas,
      ),
      _cache.limpar(
        AdministracaoCache
            .chaveSolicitacoesRejeitadas,
      ),
    ]);
  }
}

