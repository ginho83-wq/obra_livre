import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dados/obras_recentes.dart';
import '../utils/diagnostico_supabase.dart';

// ==========================================================
// OBRAS REPOSITORY
// ==========================================================
class ObrasRepository {
  ObrasRepository._interno();

  static final ObrasRepository instancia =
  ObrasRepository._interno();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ==========================================================
  // VERIFICAR SE OBRA JÁ ESTÁ PUBLICADA
  // ==========================================================
  //
  // A verificação usa:
  // - título
  // - autor
  // - ano da obra
  //
  // A consulta é feita na tabela "obras", que representa
  // somente as obras já publicadas.
  //
  // ==========================================================
  Future<bool> obraJaPublicada({
    required String titulo,
    required String autor,
    required int anoObra,
  }) async {
    try {
      final tituloNormalizado = titulo.trim();
      final autorNormalizado = autor.trim();

      if (tituloNormalizado.isEmpty ||
          autorNormalizado.isEmpty) {
        return false;
      }

      final resposta = await _supabase
          .from('obras')
          .select('id')
          .ilike('titulo', tituloNormalizado)
          .ilike('autor', autorNormalizado)
          .eq('ano_obra', anoObra)
          .limit(1);

      if (resposta is List && resposta.isNotEmpty) {
        return true;
      }

      return false;
    } on PostgrestException catch (e, stackTrace) {
      DiagnosticoSupabase.erro(
        'ERRO AO VERIFICAR SE OBRA JÁ ESTÁ PUBLICADA',
        e,
        stackTrace,
      );

      throw Exception(
        'Não foi possível verificar se a obra já está publicada: '
            '${e.message}',
      );
    } catch (e, stackTrace) {
      DiagnosticoSupabase.erro(
        'ERRO GERAL AO VERIFICAR OBRA PUBLICADA',
        e,
        stackTrace,
      );

      throw Exception(
        'Não foi possível verificar se a obra já está publicada.',
      );
    }
  }

  // ==========================================================
  // ENVIAR OBRA PARA APROVAÇÃO
  // ==========================================================
  Future<void> enviarObraPendente({
    required String titulo,
    required String autor,
    required String coautores,
    required String area,
    required int anoObra,
    required String categoria,
    required String descricao,
    required String palavrasChave,
    required PlatformFile arquivo,
  }) async {
    DiagnosticoSupabase.inicio(
      'PUBLICAÇÃO DE OBRA PENDENTE',
    );

    String? caminhoArquivo;

    try {
      // ======================================================
      // USUÁRIO
      // ======================================================
      final usuario = _supabase.auth.currentUser;

      if (usuario == null) {
        throw Exception(
          'É necessário iniciar sessão para publicar uma obra.',
        );
      }

      // ======================================================
      // DADOS OBRIGATÓRIOS
      // ======================================================
      if (titulo.trim().isEmpty) {
        throw Exception(
          'Informe o título da obra.',
        );
      }

      if (autor.trim().isEmpty) {
        throw Exception(
          'Informe o nome do autor.',
        );
      }

      if (area.trim().isEmpty) {
        throw Exception(
          'Informe a área da obra.',
        );
      }

      if (categoria.trim().isEmpty) {
        throw Exception(
          'Selecione uma categoria.',
        );
      }

      if (descricao.trim().isEmpty) {
        throw Exception(
          'Informe a descrição da obra.',
        );
      }

      // ======================================================
      // ANO
      // ======================================================
      final anoAtual = DateTime.now().year;

      if (anoObra < 1900 || anoObra > anoAtual) {
        throw Exception(
          'O ano da obra deve estar entre 1900 e $anoAtual.',
        );
      }

      // ======================================================
      // VERIFICAR DUPLICAÇÃO
      // ======================================================
      final jaPublicada = await obraJaPublicada(
        titulo: titulo,
        autor: autor,
        anoObra: anoObra,
      );

      if (jaPublicada) {
        throw Exception(
          'Esta obra já se encontra publicada na plataforma '
              'e não pode ser enviada novamente.',
        );
      }

      // ======================================================
      // ARQUIVO
      // ======================================================
      if (arquivo.bytes == null) {
        throw Exception(
          'Não foi possível ler o arquivo PDF.',
        );
      }

      if (!arquivo.name.toLowerCase().endsWith('.pdf')) {
        throw Exception(
          'Somente arquivos PDF são permitidos.',
        );
      }

      // ======================================================
      // PREPARAR ARQUIVO
      // ======================================================
      final bytes = arquivo.bytes!;
      final nomeOriginal = arquivo.name;

      final nomeSeguro = nomeOriginal.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );

      final nomeUnico =
          '${DateTime.now().millisecondsSinceEpoch}_$nomeSeguro';

      caminhoArquivo =
      '${usuario.id}/$nomeUnico';

      // ======================================================
      // UPLOAD DO PDF
      // ======================================================
      await _supabase.storage
          .from('obras_pendentes')
          .uploadBinary(
        caminhoArquivo!,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'application/pdf',
          upsert: false,
        ),
      );

      // ======================================================
      // DADOS DA OBRA
      // ======================================================
      final dados = <String, dynamic>{
        'user_id': usuario.id,
        'titulo': titulo.trim(),
        'autor': autor.trim(),
        'coautores': coautores.trim(),
        'area': area.trim(),
        'ano_obra': anoObra,
        'categoria': categoria.trim(),
        'descricao': descricao.trim(),
        'palavras_chave': palavrasChave.trim(),
        'nome_arquivo': nomeOriginal,
        'tamanho_arquivo': bytes.length,
        'caminho_arquivo': caminhoArquivo,
        'status': 'pendente',
        'data_envio': DateTime.now().toIso8601String(),
      };

      // ======================================================
      // REGISTRO DA OBRA
      // ======================================================
      await _supabase
          .from('obras_pendentes')
          .insert(dados);

      DiagnosticoSupabase.fim();
    } catch (e, stackTrace) {
      // ======================================================
      // ROLLBACK DO PDF
      // ======================================================
      if (caminhoArquivo != null) {
        try {
          await _supabase.storage
              .from('obras_pendentes')
              .remove([
            caminhoArquivo!,
          ]);
        } catch (erroRemocao, stackRemocao) {
          DiagnosticoSupabase.erro(
            'ERRO AO FAZER ROLLBACK DO PDF',
            erroRemocao,
            stackRemocao,
          );
        }
      }

      // ======================================================
      // DIAGNÓSTICO
      // ======================================================
      DiagnosticoSupabase.erro(
        'ERRO AO ENVIAR OBRA',
        e,
        stackTrace,
      );

      DiagnosticoSupabase.fim();

      // ======================================================
      // ERRO DO STORAGE
      // ======================================================
      if (e is StorageException) {
        throw Exception(
          'Erro ao enviar o PDF: ${e.message}',
        );
      }

      // ======================================================
      // ERRO DO BANCO DE DADOS
      // ======================================================
      if (e is PostgrestException) {
        throw Exception(
          'Erro ao registrar a obra: ${e.message}',
        );
      }

      // ======================================================
      // ERRO DE AUTENTICAÇÃO
      // ======================================================
      if (e is AuthException) {
        throw Exception(
          'Erro de autenticação: ${e.message}',
        );
      }

      // ======================================================
      // OUTROS ERROS
      // ======================================================
      if (e is Exception) {
        throw Exception(
          e.toString().replaceFirst(
            'Exception: ',
            '',
          ),
        );
      }

      throw Exception(
        'Não foi possível enviar a obra.',
      );
    }
  }

  // ==========================================================
  // CARREGAR MINHAS PUBLICAÇÕES
  // ==========================================================
  Future<List<ObraRecente>>
  carregarMinhasPublicacoes() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception(
        'É necessário iniciar sessão.',
      );
    }

    try {
      final List<ObraRecente> resultado = [];

      // ======================================================
      // PUBLICADAS
      // ======================================================
      final respostaPublicadas = await _supabase
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
            'nome_arquivo,'
            'tamanho_arquivo,'
            'caminho_arquivo,'
            'data_publicacao,'
            'status',
      )
          .eq(
        'user_id',
        usuario.id,
      )
          .order(
        'data_publicacao',
        ascending: false,
      );

      if (respostaPublicadas is List) {
        for (final item in respostaPublicadas) {
          final mapa =
          Map<String, dynamic>.from(item);

          resultado.add(
            ObraRecente(
              id: mapa['id']?.toString() ?? '',
              titulo:
              mapa['titulo']?.toString() ?? '',
              resumo:
              mapa['descricao']?.toString() ?? '',
              autor:
              mapa['autor']?.toString() ?? '',
              coautores:
              mapa['coautores']?.toString() ?? '',
              categoria:
              mapa['categoria']?.toString() ?? '',
              anoObra:
              _converterAno(mapa['ano_obra']),
              urlDocumento:
              mapa['url_documento']?.toString() ?? '',
              dataPublicacao:
              mapa['data_publicacao']?.toString() ?? '',
              status: 'publicada',
            ),
          );
        }
      }

      // ======================================================
      // PENDENTES / RECUSADAS
      // ======================================================
      final respostaPendentes = await _supabase
          .from('obras_pendentes')
          .select(
        'id,'
            'titulo,'
            'descricao,'
            'autor,'
            'coautores,'
            'categoria,'
            'ano_obra,'
            'nome_arquivo,'
            'tamanho_arquivo,'
            'caminho_arquivo,'
            'status,'
            'motivo_rejeicao,'
            'data_envio',
      )
          .eq(
        'user_id',
        usuario.id,
      )
          .order(
        'data_envio',
        ascending: false,
      );

      if (respostaPendentes is List) {
        for (final item in respostaPendentes) {
          final mapa =
          Map<String, dynamic>.from(item);

          final status =
              mapa['status']
                  ?.toString()
                  .toLowerCase() ??
                  'pendente';

          final statusNormalizado =
          _normalizarStatus(status);

          resultado.add(
            ObraRecente(
              id: mapa['id']?.toString() ?? '',
              titulo:
              mapa['titulo']?.toString() ?? '',
              resumo:
              mapa['descricao']?.toString() ?? '',
              autor:
              mapa['autor']?.toString() ?? '',
              coautores:
              mapa['coautores']?.toString() ?? '',
              categoria:
              mapa['categoria']?.toString() ?? '',
              anoObra:
              _converterAno(mapa['ano_obra']),
              urlDocumento: '',
              dataPublicacao:
              mapa['data_envio']?.toString() ?? '',
              status: statusNormalizado,
            ),
          );
        }
      }

      return resultado;
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro ao carregar as publicações: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível carregar as publicações.',
      );
    }
  }

  // ==========================================================
  // CONVERTER ANO
  // ==========================================================
  int? _converterAno(dynamic valor) {
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
  // NORMALIZAR STATUS
  // ==========================================================
  String _normalizarStatus(String status) {
    switch (status) {
      case 'pendente':
        return 'pendente';

      case 'recusada':
      case 'recusado':
      case 'rejeitada':
      case 'rejeitado':
        return 'recusada';

      case 'publicada':
      case 'publicado':
      case 'aprovada':
      case 'aprovado':
        return 'publicada';

      default:
        return status;
    }
  }
}
