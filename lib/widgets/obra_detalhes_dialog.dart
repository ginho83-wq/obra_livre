import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../repositorios/acervo_repository.dart';
import '../repositorios/historico_consultas_repository.dart';

class ObraDetalhesDialog extends StatefulWidget {
  final String id;

  // ==========================================================
  // MODO EXCLUSÃO ADMINISTRATIVA
  // ==========================================================
  final bool modoExclusao;
  final VoidCallback? onExcluir;

  // ==========================================================
  // MODO DENÚNCIA ADMINISTRATIVA
  // ==========================================================
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

    // Exclusão
    this.modoExclusao = false,
    this.onExcluir,

    // Denúncia
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

class _ObraDetalhesDialogState
    extends State<ObraDetalhesDialog> {
  final HistoricoConsultasRepository _historico =
      HistoricoConsultasRepository.instancia;

  final AcervoRepository _repository =
      AcervoRepository.instancia;

  bool _carregando = true;
  bool _abrindo = false;
  String? _erro;

  // ==========================================================
  // CORREÇÃO:
  // O AcervoRepository retorna AcervoObra?, não Map.
  // ==========================================================
  AcervoObra? _obra;

  @override
  void initState() {
    super.initState();
    _carregarObra();
  }

  // ==========================================================
  // CARREGAR OBRA
  // ==========================================================
  Future<void> _carregarObra() async {
    try {
      final obra =
      await _repository.carregarObraPorId(widget.id);

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
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _carregando = false;
        _erro =
        'Não foi possível carregar os detalhes da obra.';
      });
    }
  }

  // ==========================================================
  // ABRIR DOCUMENTO
  // ==========================================================
  Future<void> _consultarObra() async {
    if (_abrindo) {
      return;
    }

    setState(() {
      _abrindo = true;
    });

    try {
      final url = _obra?.urlDocumento.trim();

      if (url == null || url.isEmpty) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O documento desta obra não está disponível.',
            ),
          ),
        );

        return;
      }

      // ======================================================
      // REGISTRAR CONSULTA
      // ======================================================
      await _historico.registrarConsulta(widget.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      context.push(
        '/visualizar-documento',
        extra: url,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o documento.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _abrindo = false;
        });
      }
    }
  }

  // ==========================================================
  // EXCLUIR OBRA
  // ==========================================================
  void _excluir() {
    if (widget.onExcluir == null) {
      return;
    }

    Navigator.of(context).pop();
    widget.onExcluir!();
  }

  // ==========================================================
  // RESOLVER DENÚNCIA
  // ==========================================================
  Future<void> _resolverDenuncia() async {
    if (widget.onResolver == null) {
      return;
    }

    await widget.onResolver!();
  }

  // ==========================================================
  // REJEITAR DENÚNCIA
  // ==========================================================
  Future<void> _rejeitarDenuncia() async {
    if (widget.onRejeitar == null) {
      return;
    }

    await widget.onRejeitar!();
  }

  // ==========================================================
  // TEXTO
  // ==========================================================
  String _texto(String? valor) {
    if (valor == null) {
      return '';
    }

    return valor.trim();
  }

  // ==========================================================
  // LIMITAR DESCRIÇÃO
  // ==========================================================
  String _limitarDescricao(String texto) {
    final palavras = texto
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList();

    if (palavras.length <= 50) {
      return texto;
    }

    return '${palavras.take(50).join(' ')}...';
  }

  // ==========================================================
  // STATUS DA DENÚNCIA
  // ==========================================================
  String _textoStatus(String? status) {
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

  // ==========================================================
  // COR STATUS
  // ==========================================================
  Color _corStatus(String? status) {
    switch (status) {
      case 'em_analise':
        return Colors.blueGrey;

      case 'resolvida':
        return Colors.green.shade700;

      case 'rejeitada':
        return Colors.red.shade700;

      case 'pendente':
      default:
        return Colors.black87;
    }
  }

  // ==========================================================
  // LINHA DE INFORMAÇÃO
  // ==========================================================
  Widget _linha(
      String titulo,
      String valor,
      IconData icone,
      ) {
    if (valor.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icone,
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style:
              DefaultTextStyle.of(context)
                  .style
                  .copyWith(
                fontSize: 13,
              ),
              children: [
                TextSpan(
                  text: '$titulo: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: valor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // BADGE DE STATUS
  // ==========================================================
  Widget _buildStatusBadge() {
    final status = widget.statusDenuncia;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
        BorderRadius.circular(6),
      ),
      child: Text(
        _textoStatus(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _corStatus(status),
        ),
      ),
    );
  }

  // ==========================================================
  // COMPROVANTES
  // ==========================================================
  Widget _buildComprovantes() {
    final comprovantes =
        widget.comprovantes ?? [];

    if (comprovantes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(
          height: 1,
        ),
        const SizedBox(height: 14),
        const Text(
          'Comprovantes',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),

        ...comprovantes.map(
              (comprovante) {
            final caminho =
                comprovante['caminho']
                    ?.toString()
                    .trim() ??
                    comprovante['path']
                        ?.toString()
                        .trim() ??
                    comprovante['arquivo']
                        ?.toString()
                        .trim() ??
                    '';

            final nome =
                comprovante['nome']
                    ?.toString()
                    .trim() ??
                    comprovante['nome_arquivo']
                        ?.toString()
                        .trim() ??
                    caminho
                        .split('/')
                        .last;

            return Padding(
              padding:
              const EdgeInsets.only(
                bottom: 6,
              ),
              child: OutlinedButton.icon(
                onPressed:
                caminho.isEmpty ||
                    widget
                        .onObterUrlComprovante ==
                        null
                    ? null
                    : () async {
                  try {
                    final url =
                    await widget
                        .onObterUrlComprovante!(
                      caminho,
                    );

                    if (!mounted) {
                      return;
                    }

                    if (url == null ||
                        url.trim().isEmpty) {
                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Não foi possível obter o comprovante.',
                          ),
                        ),
                      );

                      return;
                    }

                    await _abrirComprovante(
                      url,
                    );
                  } catch (_) {
                    if (!mounted) {
                      return;
                    }

                    ScaffoldMessenger
                        .of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Não foi possível abrir o comprovante.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.attach_file_outlined,
                  size: 18,
                ),
                label: Flexible(
                  child: Text(
                    nome.isEmpty
                        ? 'Comprovante'
                        : nome,
                    overflow:
                    TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================================
  // ABRIR COMPROVANTE
  // ==========================================================
  Future<void> _abrirComprovante(
      String url,
      ) async {
    if (!mounted) {
      return;
    }

    context.push(
      '/visualizar-documento',
      extra: url,
    );
  }

  // ==========================================================
  // CONTEÚDO NORMAL
  // ==========================================================
  Widget _buildConteudoObra() {
    final obra = _obra;

    if (obra == null) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'Obra não encontrada.',
          ),
        ),
      );
    }

    // ========================================================
    // CORREÇÃO:
    // Agora usamos as propriedades de AcervoObra.
    // ========================================================
    final titulo = _texto(obra.titulo);
    final autor = _texto(obra.autor);
    final coautores = _texto(obra.coautores);
    final categoria = _texto(obra.categoria);
    final descricao = _texto(obra.descricao);
    final ano =
        obra.anoObra?.toString() ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          if (titulo.isNotEmpty) ...[
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (autor.isNotEmpty) ...[
            _linha(
              'Autor',
              autor,
              Icons.person_outline,
            ),
            const SizedBox(height: 10),
          ],

          if (coautores.isNotEmpty) ...[
            _linha(
              'Coautores',
              coautores,
              Icons.people_outline,
            ),
            const SizedBox(height: 10),
          ],

          if (categoria.isNotEmpty) ...[
            _linha(
              'Categoria',
              categoria,
              Icons.category_outlined,
            ),
            const SizedBox(height: 10),
          ],

          if (ano.isNotEmpty) ...[
            _linha(
              'Ano da obra',
              ano,
              Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 10),
          ],

          if (descricao.isNotEmpty) ...[
            const Text(
              'Descrição',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _limitarDescricao(
                descricao,
              ),
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // CONTEÚDO DENÚNCIA
  // ==========================================================
  Widget _buildConteudoDenuncia() {
    final obra = _obra;

    final titulo =
    _texto(obra?.titulo);

    final autor =
    _texto(obra?.autor);

    final categoria =
    _texto(obra?.categoria);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          if (titulo.isNotEmpty) ...[
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (autor.isNotEmpty) ...[
            _linha(
              'Autor',
              autor,
              Icons.person_outline,
            ),
            const SizedBox(height: 10),
          ],

          if (categoria.isNotEmpty) ...[
            _linha(
              'Categoria',
              categoria,
              Icons.category_outlined,
            ),
            const SizedBox(height: 10),
          ],

          if (widget.denuncianteNome
              ?.trim()
              .isNotEmpty ==
              true) ...[
            _linha(
              'Denunciante',
              widget.denuncianteNome!,
              Icons.person_outline,
            ),
            const SizedBox(height: 10),
          ],

          if (widget.motivoDenuncia
              ?.trim()
              .isNotEmpty ==
              true) ...[
            _linha(
              'Motivo',
              widget.motivoDenuncia!,
              Icons.report_outlined,
            ),
            const SizedBox(height: 10),
          ],

          if (widget.statusDenuncia
              ?.trim()
              .isNotEmpty ==
              true) ...[
            Row(
              children: [
                const Icon(
                  Icons.flag_outlined,
                  size: 19,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Status: ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
          ],

          if (widget.descricaoDenuncia
              ?.trim()
              .isNotEmpty ==
              true) ...[
            const SizedBox(height: 16),
            const Divider(
              height: 1,
            ),
            const SizedBox(height: 14),
            const Text(
              'Descrição da denúncia',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.descricaoDenuncia!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],

          _buildComprovantes(),
        ],
      ),
    );
  }

  // ==========================================================
  // CONTEÚDO
  // ==========================================================
  Widget _buildConteudo() {
    if (_carregando) {
      return const SizedBox(
        height: 180,
        child: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    if (_erro != null) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            _erro!,
            textAlign:
            TextAlign.center,
          ),
        ),
      );
    }

    if (widget.modoDenunciaAdmin) {
      return _buildConteudoDenuncia();
    }

    return _buildConteudoObra();
  }

  // ==========================================================
  // AÇÕES
  // ==========================================================
  List<Widget> _buildActions() {
    // ========================================================
    // MODO EXCLUSÃO
    // ========================================================
    if (widget.modoExclusao) {
      return [
        OutlinedButton(
          onPressed: _carregando
              ? null
              : () =>
              Navigator.of(context)
                  .pop(),
          style:
          OutlinedButton.styleFrom(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(7),
            ),
          ),
          child:
          const Text('Cancelar'),
        ),

        FilledButton(
          onPressed:
          _carregando ||
              widget.onExcluir ==
                  null
              ? null
              : _excluir,
          style:
          FilledButton.styleFrom(
            backgroundColor:
            Colors.grey.shade700,
            foregroundColor:
            Colors.white,
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(7),
            ),
          ),
          child:
          const Text('Excluir'),
        ),
      ];
    }

    // ========================================================
    // MODO DENÚNCIA ADMIN
    // ========================================================
    if (widget.modoDenunciaAdmin) {
      final status =
          widget.statusDenuncia;

      final podeResolver =
          status == 'pendente' ||
              status == 'em_analise';

      final podeRejeitar =
          status == 'pendente' ||
              status == 'em_analise';

      return [
        OutlinedButton(
          onPressed: _carregando
              ? null
              : () =>
              Navigator.of(context)
                  .pop(),
          style:
          OutlinedButton.styleFrom(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(7),
            ),
          ),
          child:
          const Text('Fechar'),
        ),

        if (podeRejeitar &&
            widget.onRejeitar != null)
          OutlinedButton(
            onPressed: _carregando
                ? null
                : _rejeitarDenuncia,
            style:
            OutlinedButton.styleFrom(
              foregroundColor:
              Colors.black87,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(7),
              ),
            ),
            child:
            const Text('Rejeitar'),
          ),

        if (podeResolver &&
            widget.onResolver != null)
          FilledButton(
            onPressed: _carregando
                ? null
                : _resolverDenuncia,
            style:
            FilledButton.styleFrom(
              backgroundColor:
              Colors.black87,
              foregroundColor:
              Colors.white,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(7),
              ),
            ),
            child:
            const Text('Resolver'),
          ),
      ];
    }

    // ========================================================
    // MODO NORMAL
    // ========================================================
    return [
      OutlinedButton(
        onPressed: _carregando
            ? null
            : () =>
            Navigator.of(context)
                .pop(),
        style:
        OutlinedButton.styleFrom(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(7),
          ),
        ),
        child:
        const Text('Cancelar'),
      ),

      FilledButton(
        onPressed:
        _carregando || _abrindo
            ? null
            : _consultarObra,
        style:
        FilledButton.styleFrom(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(7),
          ),
        ),
        child: _abrindo
            ? const SizedBox(
          width: 18,
          height: 18,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
          ),
        )
            : const Text('Abrir'),
      ),
    ];
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    String titulo;

    if (widget.modoExclusao) {
      titulo = 'Excluir obra';
    } else if (widget.modoDenunciaAdmin) {
      titulo = 'Detalhes da denúncia';
    } else {
      titulo = 'Detalhes da obra';
    }

    return AlertDialog(
      titlePadding:
      const EdgeInsets.fromLTRB(
        24,
        16,
        8,
        0,
      ),
      contentPadding:
      const EdgeInsets.fromLTRB(
        24,
        12,
        24,
        8,
      ),
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style:
              const TextStyle(
                fontSize: 19,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Fechar',
            onPressed: () =>
                Navigator.of(context)
                    .pop(),
            icon: const Icon(
              Icons.close,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: _buildConteudo(),
      ),
      actionsPadding:
      const EdgeInsets.fromLTRB(
        24,
        8,
        24,
        16,
      ),
      actions: _buildActions(),
    );
  }
}
