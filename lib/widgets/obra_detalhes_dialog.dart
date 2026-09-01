import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../repositorios/acervo_repository.dart';
import '../repositorios/solicitacoes_remocao_repository.dart';
import '../widgets/dialog_mensagem_widget.dart';
import 'denunciar_obra_dialog.dart';
import 'solicitar_remocao_dialog.dart';

// ==========================================================
// OBRA DETALHES DIALOG
// ==========================================================

class ObraDetalhesDialog extends StatefulWidget {
  final String id;

  // ========================================================
  // MODO EXCLUSÃO
  // ========================================================

  final bool modoExclusao;
  final Future<void> Function()? onExcluir;

  // ========================================================
  // MODO ADMINISTRAÇÃO DE DENÚNCIA
  // ========================================================

  final bool modoDenunciaAdmin;
  final String? denuncianteNome;
  final String? motivoDenuncia;
  final String? statusDenuncia;
  final String? descricaoDenuncia;
  final List<Map<String, dynamic>>? comprovantes;
  final Future<String?> Function(String caminho)?
  onObterUrlComprovante;
  final Future<void> Function()? onResolver;
  final Future<void> Function()? onRejeitar;

  const ObraDetalhesDialog({
    super.key,
    required this.id,
    this.modoExclusao = false,
    this.onExcluir,
    this.modoDenunciaAdmin = false,
    this.denuncianteNome,
    this.motivoDenuncia,
    this.statusDenuncia,
    this.descricaoDenuncia,
    this.comprovantes,
    this.onObterUrlComprovante,
    this.onResolver,
    this.onRejeitar,
  });

  @override
  State<ObraDetalhesDialog> createState() =>
      _ObraDetalhesDialogState();
}

// ==========================================================
// STATE
// ==========================================================

class _ObraDetalhesDialogState
    extends State<ObraDetalhesDialog> {
  final AcervoRepository _repository =
      AcervoRepository.instancia;

  final SolicitacoesRemocaoRepository
  _remocaoRepository =
      SolicitacoesRemocaoRepository.instancia;

  AcervoObra? _obra;

  bool _carregando = true;
  bool _excluindo = false;
  bool _processandoAcao = false;
  bool _podeSolicitarRemocao = false;
  bool _solicitacaoPendente = false;

  String? _erro;

  static const int _limitePalavrasDescricao = 50;

  Offset _deslocamento = Offset.zero;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _carregarObra();
      }
    });
  }

  // ========================================================
  // CARREGAR OBRA
  // ========================================================

  Future<void> _carregarObra() async {
    try {
      final obra =
      await _repository.carregarObraPorId(
        widget.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _obra = obra;
        _carregando = false;

        if (obra == null) {
          _erro = 'Obra não encontrada.';
        }
      });

      if (obra != null &&
          obra.id.trim().isNotEmpty &&
          !widget.modoExclusao &&
          !widget.modoDenunciaAdmin) {
        await _repository.registarVisualizacao(
          obra.id,
        );

        await _verificarPermissaoRemocao(
          obra,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _carregando = false;
        _erro =
        'Não foi possível carregar a obra.';
      });
    }
  }

  // ========================================================
  // VERIFICAR SE O USUÁRIO É DONO DA OBRA
  // ========================================================

  Future<void> _verificarPermissaoRemocao(
      AcervoObra obra,
      ) async {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    if (usuario == null) {
      return;
    }

    try {
      final resposta =
      await Supabase.instance.client
          .from('obras')
          .select('user_id')
          .eq('id', obra.id)
          .maybeSingle();

      if (!mounted) {
        return;
      }

      if (resposta == null) {
        return;
      }

      final donoId =
      resposta['user_id']?.toString();

      if (donoId != usuario.id) {
        return;
      }

      final pendente =
      await _remocaoRepository
          .existeSolicitacaoPendente(
        obra.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _podeSolicitarRemocao = true;
        _solicitacaoPendente = pendente;
      });
    } catch (_) {
      // Não mostrar o botão caso não seja
      // possível confirmar a propriedade.
    }
  }

  // ========================================================
  // ARRASTAR
  // ========================================================

  void _arrastar(
      DragUpdateDetails detalhes,
      ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _deslocamento += detalhes.delta;
    });
  }

  // ========================================================
  // SOLICITAR REMOÇÃO
  // ========================================================

  Future<void> _solicitarRemocao() async {
    final obra = _obra;

    if (obra == null ||
        !_podeSolicitarRemocao ||
        _solicitacaoPendente) {
      return;
    }

    Navigator.of(context).pop();

    await Future<void>.delayed(
      const Duration(milliseconds: 50),
    );

    if (!mounted) {
      return;
    }

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SolicitarRemocaoDialog(
          obraId: obra.id,
          tituloObra: obra.titulo,
        );
      },
    );

    if (resultado == true) {
      // A confirmação de sucesso da solicitação
      // será feita pelo próprio diálogo de solicitação.
    }
  }

  // ========================================================
  // ABRIR DOCUMENTO
  // ========================================================

  Future<void> _abrirDocumento() async {
    final obra = _obra;

    if (obra == null ||
        obra.urlDocumento.trim().isEmpty) {
      await _mostrarErro(
        'Documento não disponível.',
      );
      return;
    }

    final uri = Uri.tryParse(
      obra.urlDocumento.trim(),
    );

    if (uri == null) {
      await _mostrarErro(
        'O endereço do documento é inválido.',
      );
      return;
    }

    try {
      final abriu = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (abriu && mounted) {
        Navigator.of(context).pop();
      } else if (!abriu) {
        await _mostrarErro(
          'Não foi possível abrir o documento.',
        );
      }
    } catch (_) {
      await _mostrarErro(
        'Não foi possível abrir o documento.',
      );
    }
  }

  // ========================================================
  // EXCLUIR
  // ========================================================

  Future<void> _excluir() async {
    if (widget.onExcluir == null ||
        _excluindo) {
      return;
    }

    setState(() {
      _excluindo = true;
    });

    try {
      await widget.onExcluir!();
    } finally {
      if (mounted) {
        setState(() {
          _excluindo = false;
        });
      }
    }
  }

  // ========================================================
  // DENUNCIAR OBRA
  // ========================================================

  Future<void> _denunciarObra() async {
    final obra = _obra;

    if (obra == null) {
      return;
    }

    final String obraId = obra.id;
    final String tituloObra = obra.titulo;

    final usuario =
        Supabase.instance.client.auth.currentUser;

    if (usuario == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );

      if (!mounted) {
        return;
      }

      final destino = Uri(
        path: '/obra/$obraId',
        queryParameters: {
          'abrirDetalhes': '1',
        },
      ).toString();

      context.go(
        Uri(
          path: '/login',
          queryParameters: {
            'redirect': destino,
          },
        ).toString(),
      );

      return;
    }

    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return DenunciarObraDialog(
            obraId: obraId,
            tituloObra: tituloObra,
          );
        },
      );
    });
  }

  // ========================================================
  // MENSAGEM DE ERRO
  // ========================================================

  Future<void> _mostrarErro(
      String mensagem,
      ) async {
    if (!mounted) {
      return;
    }

    await DialogMensagem.erro(
      context,
      titulo: 'Erro',
      mensagem: mensagem,
    );
  }

  // ========================================================
  // FORMATAR DATA
  // ========================================================

  String _formatarData(
      DateTime? data,
      ) {
    if (data == null) {
      return '';
    }

    final dia =
    data.day.toString().padLeft(2, '0');

    final mes =
    data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  // ========================================================
  // FORMATAR TAMANHO
  // ========================================================

  String _formatarTamanhoArquivo(
      int? bytes,
      ) {
    if (bytes == null || bytes <= 0) {
      return '';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    final kb = bytes / 1024;

    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }

    final mb = kb / 1024;

    if (mb < 1024) {
      return '${mb.toStringAsFixed(2)} MB';
    }

    final gb = mb / 1024;

    return '${gb.toStringAsFixed(2)} GB';
  }

  // ========================================================
  // LIMITAR DESCRIÇÃO
  // ========================================================

  String _limitarDescricao(
      String descricao,
      ) {
    final texto = descricao.trim();

    if (texto.isEmpty) {
      return '';
    }

    final palavras =
    texto.split(RegExp(r'\s+'));

    if (palavras.length <=
        _limitePalavrasDescricao) {
      return texto;
    }

    return '${palavras.take(
      _limitePalavrasDescricao,
    ).join(' ')}...';
  }

  // ========================================================
  // INFORMAÇÃO
  // ========================================================

  Widget _informacao(
      String titulo,
      String valor,
      ) {
    if (valor.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 14,
            height: 1.3,
            color: Colors.black87,
            fontWeight: FontWeight.normal,
          ),
          children: [
            TextSpan(
              text: '$titulo: ',
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            TextSpan(
              text: valor,
            ),
          ],
        ),
        softWrap: true,
      ),
    );
  }

  // ========================================================
  // COAUTORES
  // ========================================================

  Widget _construirCoautores(
      String coautores,
      ) {
    final texto = coautores.trim();

    if (texto.isEmpty) {
      return const SizedBox.shrink();
    }

    final lista = texto
        .split(RegExp(r'\r?\n|;'))
        .map((item) => item.trim())
        .where(
          (item) => item.isNotEmpty,
    )
        .toList();

    if (lista.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Coautores',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        for (final coautor in lista)
          Padding(
            padding:
            const EdgeInsets.only(
              bottom: 3,
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding:
                  EdgeInsets.only(
                    top: 2,
                    right: 6,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.black54,
                  ),
                ),
                Expanded(
                  child: Text(
                    coautor,
                    softWrap: true,
                    style:
                    const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ========================================================
  // CABEÇALHO
  // ========================================================

  Widget _construirCabecalho(
      AcervoObra? obra,
      ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: _arrastar,
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.modoDenunciaAdmin
                    ? 'Detalhes da denúncia'
                    : obra?.titulo ??
                    'Detalhes da obra',
                softWrap: true,
                style:
                const TextStyle(
                  fontSize: 21,
                  height: 1.25,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed:
                _processandoAcao
                    ? null
                    : () {
                  Navigator.of(
                    context,
                  ).pop();
                },
                tooltip: 'Fechar',
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // STATUS DENÚNCIA
  // ========================================================

  String _textoStatusDenuncia(
      String? status,
      ) {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'em_analise':
        return 'Em análise';
      case 'resolvida':
        return 'Resolvida';
      case 'rejeitada':
        return 'Rejeitada';
      default:
        return status?.isNotEmpty == true
            ? status!
            : 'Pendente';
    }
  }

  // ========================================================
  // DETALHES DENÚNCIA
  // ========================================================

  Widget _construirDetalhesDenuncia() {
    final descricao =
        widget.descricaoDenuncia
            ?.trim() ??
            '';

    final comprovantes =
        widget.comprovantes ?? [];

    final status =
        widget.statusDenuncia ??
            'pendente';

    final encerrada =
        status == 'resolvida' ||
            status == 'rejeitada';

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _informacao(
          'Autor',
          _obra?.autor ?? '',
        ),

        const SizedBox(height: 6),

        _informacao(
          'Denunciante',
          widget.denuncianteNome ??
              'Usuário não identificado',
        ),

        const SizedBox(height: 6),

        _informacao(
          'Motivo',
          widget.motivoDenuncia ??
              'Não informado',
        ),

        const SizedBox(height: 6),

        _informacao(
          'Estado',
          _textoStatusDenuncia(status),
        ),

        if (descricao.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Descrição da denúncia',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            descricao,
            softWrap: true,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],

        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 12),

        const Text(
          'Comprovantes',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 6),

        if (comprovantes.isEmpty)
          const Text(
            'Nenhum comprovante anexado.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          )
        else
          ...comprovantes.map(
                (item) {
              final dados =
              Map<String, dynamic>.from(
                item,
              );

              final nomeArquivo =
                  dados['nome_arquivo']
                      ?.toString() ??
                      'Comprovante';

              final caminho =
                  dados['caminho_arquivo']
                      ?.toString() ??
                      '';

              return Container(
                width: double.infinity,
                margin:
                const EdgeInsets.only(
                  bottom: 6,
                ),
                padding:
                const EdgeInsets.symmetric(
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_file,
                      size: 18,
                      color: Colors.black54,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        nomeArquivo,
                        softWrap: true,
                        style:
                        const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    if (caminho
                        .trim()
                        .isNotEmpty)
                      IconButton(
                        tooltip:
                        'Abrir comprovante',
                        icon: const Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: Colors.black54,
                        ),
                        onPressed:
                        _processandoAcao
                            ? null
                            : () =>
                            _abrirComprovante(
                              caminho,
                            ),
                      ),
                  ],
                ),
              );
            },
          ),

        if (widget.modoDenunciaAdmin &&
            !encerrada) ...[
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                _processandoAcao
                    ? null
                    : () {
                  Navigator.of(
                    context,
                  ).pop();
                },
                style:
                TextButton.styleFrom(
                  backgroundColor:
                  Colors.grey.shade200,
                  foregroundColor:
                  Colors.grey.shade800,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(6),
                  ),
                ),
                child:
                const Text('Cancelar'),
              ),

              const SizedBox(width: 10),

              if (widget.onRejeitar != null)
                ElevatedButton(
                  onPressed:
                  _processandoAcao
                      ? null
                      : () async {
                    await widget
                        .onRejeitar!();
                  },
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.grey.shade600,
                    foregroundColor:
                    Colors.white,
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    elevation: 0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                  ),
                  child:
                  const Text('Rejeitar'),
                ),

              if (widget.onRejeitar != null)
                const SizedBox(width: 10),

              if (widget.onResolver != null)
                ElevatedButton(
                  onPressed:
                  _processandoAcao
                      ? null
                      : () async {
                    await widget
                        .onResolver!();
                  },
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.grey.shade600,
                    foregroundColor:
                    Colors.white,
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    elevation: 0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                  ),
                  child:
                  const Text('Resolver'),
                ),
            ],
          ),
        ],

        if (widget.modoDenunciaAdmin &&
            encerrada) ...[
          const SizedBox(height: 24),

          Align(
            alignment:
            Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style:
              TextButton.styleFrom(
                backgroundColor:
                Colors.grey.shade200,
                foregroundColor:
                Colors.grey.shade800,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(6),
                ),
              ),
              child:
              const Text('Fechar'),
            ),
          ),
        ],
      ],
    );
  }

  // ========================================================
  // ABRIR COMPROVANTE
  // ========================================================

  Future<void> _abrirComprovante(
      String caminho,
      ) async {
    try {
      final url =
      await _obterUrlComprovante(
        caminho,
      );

      if (url == null ||
          url.trim().isEmpty) {
        await _mostrarErro(
          'Não foi possível abrir o comprovante.',
        );
        return;
      }

      if (!mounted) {
        return;
      }

      final uri = Uri.tryParse(url);

      if (uri == null) {
        await _mostrarErro(
          'O endereço do comprovante é inválido.',
        );
        return;
      }

      final abriu = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!abriu) {
        await _mostrarErro(
          'Não foi possível abrir o comprovante.',
        );
      }
    } catch (_) {
      await _mostrarErro(
        'Não foi possível abrir o comprovante.',
      );
    }
  }

  // ========================================================
  // URL COMPROVANTE
  // ========================================================

  Future<String?> _obterUrlComprovante(
      String caminho,
      ) async {
    if (widget.onObterUrlComprovante !=
        null) {
      return widget
          .onObterUrlComprovante!(
        caminho,
      );
    }

    return null;
  }

  // ========================================================
  // CARREGAMENTO
  // ========================================================

  Widget _construirCarregamento() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding:
        const EdgeInsets.fromLTRB(
          28,
          24,
          28,
          24,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _construirCabecalho(null),

            const SizedBox(height: 24),

            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2.5,
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Center(
              child: Text(
                'A carregar detalhes...',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // CONTEÚDO
  // ========================================================

  Widget _construirConteudo() {
    if (_carregando) {
      return _construirCarregamento();
    }

    if (_erro != null ||
        _obra == null) {
      return Padding(
        padding:
        const EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            _construirCabecalho(null),

            const SizedBox(height: 18),

            const Icon(
              Icons.menu_book_outlined,
              size: 42,
              color: Colors.grey,
            ),

            const SizedBox(height: 12),

            Text(
              _erro ??
                  'Obra não encontrada.',
              textAlign: TextAlign.center,
              softWrap: true,
              style:
              const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: _carregarObra,
              icon:
              const Icon(Icons.refresh),
              label:
              const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      );
    }

    final obra = _obra!;

    // ======================================================
    // MODO DENÚNCIA ADMIN
    // ======================================================

    if (widget.modoDenunciaAdmin) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
            28,
            24,
            28,
            22,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _construirCabecalho(obra),

              const SizedBox(height: 18),

              Text(
                obra.titulo,
                softWrap: true,
                style:
                const TextStyle(
                  fontSize: 18,
                  height: 1.3,
                  color: Colors.black87,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              _construirDetalhesDenuncia(),
            ],
          ),
        ),
      );
    }

    // ======================================================
    // DETALHES NORMAIS
    // ======================================================

    final descricao =
    _limitarDescricao(
      obra.descricao,
    );

    final temCategoria =
        obra.categoria
            .trim()
            .isNotEmpty;

    final temAutor =
        obra.autor.trim().isNotEmpty;

    final temAno =
        obra.anoObra != null;

    final temData =
        obra.dataPublicacao != null;

    final temTamanhoArquivo =
        obra.tamanhoArquivo != null &&
            obra.tamanhoArquivo! > 0;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding:
        const EdgeInsets.fromLTRB(
          28,
          24,
          28,
          22,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _construirCabecalho(obra),

            if (descricao.isNotEmpty) ...[
              const SizedBox(height: 8),

              const Text(
                'Descrição',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                descricao,
                maxLines: 6,
                softWrap: true,
                overflow:
                TextOverflow.ellipsis,
                style:
                const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ],

            if (temCategoria) ...[
              const SizedBox(height: 7),

              _informacao(
                'Tipo',
                obra.categoria,
              ),
            ],

            if (temAutor) ...[
              const SizedBox(height: 4),

              _informacao(
                'Autor',
                obra.autor,
              ),
            ],

            _construirCoautores(
              obra.coautores,
            ),

            if (temAno) ...[
              const SizedBox(height: 4),

              _informacao(
                'Ano da obra',
                obra.anoObra.toString(),
              ),
            ],

            if (temData) ...[
              const SizedBox(height: 4),

              _informacao(
                'Publicado em',
                _formatarData(
                  obra.dataPublicacao,
                ),
              ),
            ],

            if (obra.urlDocumento
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 4),

              _informacao(
                'Formato',
                'PDF',
              ),
            ],

            if (temTamanhoArquivo) ...[
              const SizedBox(height: 4),

              _informacao(
                'Tamanho do arquivo',
                _formatarTamanhoArquivo(
                  obra.tamanhoArquivo,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ==================================================
            // DENUNCIAR
            // ==================================================

            TextButton(
              onPressed:
              widget.modoExclusao
                  ? null
                  : _denunciarObra,
              style:
              TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize:
                MaterialTapTargetSize
                    .shrinkWrap,
                foregroundColor:
                Colors.grey.shade600,
              ),
              child: const Text(
                'Denunciar esta obra',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.normal,
                  decoration:
                  TextDecoration
                      .underline,
                ),
              ),
            ),

            // ==================================================
            // SOLICITAR REMOÇÃO
            // ==================================================

            if (_podeSolicitarRemocao) ...[
              const SizedBox(height: 10),

              TextButton(
                onPressed:
                _solicitacaoPendente
                    ? null
                    : _solicitarRemocao,
                style:
                TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize:
                  MaterialTapTargetSize
                      .shrinkWrap,
                  foregroundColor:
                  _solicitacaoPendente
                      ? Colors.grey
                      : Colors.grey.shade700,
                ),
                child: Text(
                  _solicitacaoPendente
                      ? 'Remoção solicitada'
                      : 'Solicitar remoção',
                  style:
                  const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.normal,
                    decoration:
                    TextDecoration
                        .underline,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.end,
              children: [
                // ==================================================
                // CANCELAR
                // ==================================================

                TextButton(
                  onPressed:
                  _excluindo
                      ? null
                      : () {
                    Navigator.of(
                      context,
                    ).pop();
                  },
                  style:
                  TextButton.styleFrom(
                    backgroundColor:
                    Colors.grey.shade200,
                    foregroundColor:
                    Colors.grey.shade800,
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                  ),
                  child:
                  const Text('Cancelar'),
                ),

                const SizedBox(width: 10),

                // ==================================================
                // EXCLUIR
                // ==================================================

                if (widget.modoExclusao)
                  ElevatedButton(
                    onPressed:
                    _excluindo
                        ? null
                        : _excluir,
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.grey.shade600,
                      foregroundColor:
                      Colors.white,
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      elevation: 0,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(6),
                      ),
                    ),
                    child: _excluindo
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                          Colors.white,
                        ),
                      ),
                    )
                        : const Text(
                      'Excluir',
                    ),
                  ),

                // ==================================================
                // ABRIR
                // ==================================================

                if (!widget.modoExclusao &&
                    obra.urlDocumento
                        .trim()
                        .isNotEmpty)
                  ElevatedButton(
                    onPressed:
                    _abrirDocumento,
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.grey.shade600,
                      foregroundColor:
                      Colors.white,
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      elevation: 0,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(6),
                      ),
                    ),
                    child:
                    const Text('Abrir'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // BUILD
  // ========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Transform.translate(
      offset: _deslocamento,
      child: Dialog(
        backgroundColor:
        Colors.grey.shade300,
        surfaceTintColor:
        Colors.grey.shade300,
        insetPadding:
        const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),

        // ==================================================
        // BORDER RADIUS DO DIALOG = 6 PX
        // ==================================================

        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(6),
        ),

        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 540,
            maxHeight: 700,
          ),
          child:
          SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child:
              _construirConteudo(),
            ),
          ),
        ),
      ),
    );
  }
}
