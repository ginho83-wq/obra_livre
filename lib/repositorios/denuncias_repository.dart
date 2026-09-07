import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================================
// DENUNCIAS REPOSITORY
// ==========================================================

class DenunciasRepository {
  DenunciasRepository._();

  static final DenunciasRepository instancia =
  DenunciasRepository._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  static const String _tabelaDenuncias =
      'denuncias_obras';

  static const String _tabelaComprovantes =
      'denuncias_comprovantes';

  static const String _bucket =
      'comprovantes_denuncias';

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

      return resposta['id'].toString();
    } catch (e) {
      throw Exception(
        'Não foi possível criar a denúncia.',
      );
    }
  }

  // ==========================================================
  // CARREGAR MINHAS DENÚNCIAS
  //
  // Somente denúncias ainda em análise são apresentadas
  // ao usuário.
  //
  // Depois que o administrador aprovar ou rejeitar:
  //
  // - a denúncia continua no banco;
  // - deixa de aparecer em "Minhas denúncias";
  // - deixa de entrar nos números da Minha Conta.
  // ==========================================================

  Future<List<Map<String, dynamic>>>
  carregarMinhasDenuncias() async {
    final usuario =
        _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception(
        'É necessário estar autenticado.',
      );
    }

    try {
      final resposta = await _supabase
          .from(_tabelaDenuncias)
          .select(
        'id, '
            'obra_id, '
            'denunciante_id, '
            'motivo, '
            'descricao, '
            'status, '
            'resposta_admin, '
            'administrador_id, '
            'criado_em, '
            'atualizado_em',
      )
          .eq(
        'denunciante_id',
        usuario.id,
      )
          .filter(
        'status',
        'in',
        '(pendente,em_analise,"em análise")',
      )
          .order(
        'criado_em',
        ascending: false,
      );

      return List<Map<String, dynamic>>.from(
        resposta,
      );
    } catch (e) {
      throw Exception(
        'Não foi possível carregar as suas denúncias.',
      );
    }
  }

  // ==========================================================
  // CONTAR MINHAS DENÚNCIAS
  //
  // Somente denúncias ativas:
  //
  // Pendente / em análise = aparece
  //
  // Aprovada / rejeitada = NÃO aparece
  // ==========================================================

  Future<Map<String, int>>
  contarMinhasDenunciasPorStatus() async {
    final usuario =
        _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception(
        'É necessário estar autenticado.',
      );
    }

    try {
      final resposta = await _supabase
          .from(_tabelaDenuncias)
          .select('status')
          .eq(
        'denunciante_id',
        usuario.id,
      )
          .filter(
        'status',
        'in',
        '(pendente,em_analise,"em análise")',
      );

      int pendentes = 0;

      for (final item in resposta) {
        final status = item['status']
            ?.toString()
            .toLowerCase()
            .trim() ??
            '';

        if (_ehStatusPendente(status)) {
          pendentes++;
        }
      }

      return {
        'pendente': pendentes,
        'aprovada': 0,
        'rejeitada': 0,
      };
    } catch (e) {
      throw Exception(
        'Não foi possível carregar o resumo das suas denúncias.',
      );
    }
  }

  // ==========================================================
  // VERIFICAR SE ESTÁ PENDENTE
  // ==========================================================

  bool _ehStatusPendente(
      String status,
      ) {
    switch (status) {
      case 'pendente':
      case 'pendentes':
      case 'em_analise':
      case 'em análise':
        return true;

      default:
        return false;
    }
  }

  // ==========================================================
  // ENVIAR COMPROVANTE
  // ==========================================================

  Future<void> enviarComprovante({
    required String denunciaId,
    required Uint8List bytes,
    required String nomeArquivo,
    required String contentType,
  }) async {
    final usuario =
        _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception(
        'É necessário estar autenticado.',
      );
    }

    if (denunciaId.trim().isEmpty) {
      throw Exception(
        'ID da denúncia não encontrado.',
      );
    }

    if (bytes.isEmpty) {
      throw Exception(
        'O arquivo selecionado está vazio.',
      );
    }

    // ========================================================
    // EXTENSÃO
    // ========================================================

    final extensao =
    _obterExtensao(nomeArquivo);

    // ========================================================
    // CAMINHO DO ARQUIVO
    // ========================================================

    final caminho =
        '${usuario.id}/$denunciaId/'
        '${DateTime.now().millisecondsSinceEpoch}'
        '.$extensao';

    // ========================================================
    // UPLOAD PARA O STORAGE
    // ========================================================

    try {
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
        caminho,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );
    } catch (e) {
      throw Exception(
        'Não foi possível enviar o comprovante.',
      );
    }

    // ========================================================
    // REGISTAR COMPROVANTE
    // ========================================================

    try {
      await _supabase
          .from(_tabelaComprovantes)
          .insert({
        'denuncia_id': denunciaId,
        'nome_arquivo': nomeArquivo,
        'tipo_arquivo': contentType,
        'tamanho_bytes': bytes.length,
        'caminho_arquivo': caminho,
      });
    } catch (e) {
      // ======================================================
      // SE O REGISTO FALHAR, REMOVER O ARQUIVO
      // ======================================================

      try {
        await _supabase.storage
            .from(_bucket)
            .remove([
          caminho,
        ]);
      } catch (_) {
        // Ignorar erro de limpeza.
      }

      throw Exception(
        'O arquivo foi enviado, mas não foi possível registrar o comprovante.',
      );
    }
  }

  // ==========================================================
  // EXTENSÃO DO ARQUIVO
  // ==========================================================

  String _obterExtensao(
      String nomeArquivo,
      ) {
    final nome =
    nomeArquivo.trim();

    if (nome.isEmpty ||
        !nome.contains('.')) {
      return 'bin';
    }

    return nome
        .split('.')
        .last
        .toLowerCase();
  }
}

