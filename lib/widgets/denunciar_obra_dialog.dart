import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../repositorios/denuncias_repository.dart';
import '../widgets/dialog_mensagem_widget.dart';

// ==========================================================
// DENUNCIAR OBRA DIALOG
// ==========================================================

class DenunciarObraDialog extends StatefulWidget {
  final String obraId;
  final String tituloObra;

  const DenunciarObraDialog({
    super.key,
    required this.obraId,
    required this.tituloObra,
  });

  @override
  State<DenunciarObraDialog> createState() =>
      _DenunciarObraDialogState();
}

// ==========================================================
// STATE
// ==========================================================

class _DenunciarObraDialogState
    extends State<DenunciarObraDialog> {
  final DenunciasRepository _repository =
      DenunciasRepository.instancia;

  final TextEditingController _descricaoController =
  TextEditingController();

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  String? _motivoSelecionado;
  Uint8List? _arquivoBytes;
  String? _nomeArquivo;
  String? _tipoArquivo;
  bool _enviando = false;

  // ==========================================================
  // MOTIVOS
  // ==========================================================

  final List<String> _motivos = [
    'Obra falsa ou inexistente',
    'Obra atribuída ao autor errado',
    'Violação de direitos autorais',
    'Conteúdo inadequado',
    'Informações falsas ou incorretas',
    'Outro',
  ];

  // ==========================================================
  // POSIÇÃO DO DIALOG
  // ==========================================================

  Offset _deslocamento = Offset.zero;

  // ==========================================================
  // SELECIONAR COMPROVANTE
  // ==========================================================

  Future<void> _selecionarComprovante() async {
    try {
      final arquivos = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
        ],
        withData: true,
      );

      if (arquivos == null ||
          arquivos.files.isEmpty) {
        return;
      }

      final arquivo = arquivos.files.first;

      final Uint8List? bytes = arquivo.bytes;

      if (bytes == null || bytes.isEmpty) {
        await _mostrarAviso(
          'O arquivo selecionado está vazio ou não pôde ser lido.',
        );
        return;
      }

      if (bytes.length > 10 * 1024 * 1024) {
        await _mostrarAviso(
          'O comprovante não pode ultrapassar 10 MB.',
        );
        return;
      }

      final contentType =
      _obterContentType(arquivo.extension);

      if (!mounted) {
        return;
      }

      setState(() {
        _arquivoBytes = bytes;
        _nomeArquivo = arquivo.name;
        _tipoArquivo = contentType;
      });
    } catch (_) {
      await _mostrarErro(
        'Não foi possível selecionar o arquivo.',
      );
    }
  }

  // ==========================================================
  // CONTENT TYPE
  // ==========================================================

  String _obterContentType(String? extensao) {
    switch (extensao?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';

      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      default:
        return 'application/octet-stream';
    }
  }

  // ==========================================================
  // REMOVER ARQUIVO
  // ==========================================================

  void _removerComprovante() {
    if (_enviando) {
      return;
    }

    setState(() {
      _arquivoBytes = null;
      _nomeArquivo = null;
      _tipoArquivo = null;
    });
  }

  // ==========================================================
  // ENVIAR DENÚNCIA
  // ==========================================================

  Future<void> _enviarDenuncia() async {
    if (_enviando) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      final denunciaId =
      await _repository.criarDenuncia(
        obraId: widget.obraId,
        motivo: _motivoSelecionado!,
        descricao:
        _descricaoController.text.trim(),
      );

      if (_arquivoBytes != null &&
          _nomeArquivo != null &&
          _tipoArquivo != null) {
        await _repository.enviarComprovante(
          denunciaId: denunciaId,
          bytes: _arquivoBytes!,
          nomeArquivo: _nomeArquivo!,
          contentType: _tipoArquivo!,
        );
      }

      if (!mounted) {
        return;
      }

      // ======================================================
      // SUCESSO
      // ======================================================

      await DialogMensagem.sucesso(
        context,
        titulo: 'Denúncia enviada',
        mensagem:
        'Sua denúncia foi enviada com sucesso.',
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (erro) {
      if (!mounted) {
        return;
      }

      setState(() {
        _enviando = false;
      });

      await DialogMensagem.erro(
        context,
        titulo: 'Erro ao enviar denúncia',
        mensagem: _mensagemErro(erro),
      );
    }
  }

  // ==========================================================
  // MENSAGEM DE ERRO
  // ==========================================================

  String _mensagemErro(Object erro) {
    final texto = erro
        .toString()
        .replaceFirst(
      'Exception: ',
      '',
    )
        .trim();

    if (texto.isEmpty) {
      return 'Não foi possível enviar a denúncia.';
    }

    return texto;
  }

  // ==========================================================
  // AVISO
  // ==========================================================

  Future<void> _mostrarAviso(
      String mensagem,
      ) async {
    if (!mounted) {
      return;
    }

    await DialogMensagem.aviso(
      context,
      titulo: 'Atenção',
      mensagem: mensagem,
    );
  }

  // ==========================================================
  // ERRO
  // ==========================================================

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

  // ==========================================================
  // ARRASTAR DIALOG
  // ==========================================================

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

  // ==========================================================
  // CABEÇALHO ARRASTÁVEL
  // ==========================================================

  Widget _construirCabecalho() {
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
                'Denunciar esta obra',
                style: const TextStyle(
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
                onPressed: _enviando
                    ? null
                    : () {
                  Navigator.of(context).pop();
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

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _deslocamento,
      child: Dialog(
        backgroundColor: Colors.grey.shade300,
        surfaceTintColor: Colors.grey.shade300,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),

        // ====================================================
        // BORDER RADIUS DO DIALOG
        // ====================================================

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),

        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 540,
            maxHeight: 700,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ==================================================
              // CABEÇALHO
              // ==================================================

              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  28,
                  24,
                  28,
                  0,
                ),
                child: _construirCabecalho(),
              ),

              // ==================================================
              // CONTEÚDO COM SCROLL
              // ==================================================

              Expanded(
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.fromLTRB(
                    28,
                    6,
                    28,
                    22,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        // ========================================
                        // OBRA
                        // ========================================

                        Text(
                          widget.tituloObra,
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ========================================
                        // MOTIVO
                        // ========================================

                        const Text(
                          'Motivo da denúncia',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 5),

                        DropdownButtonFormField<String>(
                          value: _motivoSelecionado,
                          isExpanded: true,
                          decoration:
                          InputDecoration(
                            filled: true,
                            fillColor: Colors.white,

                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(6),
                            ),

                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(6),
                            ),

                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(6),
                            ),

                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          hint: const Text(
                            'Selecione o motivo',
                          ),
                          items: _motivos
                              .map(
                                (motivo) =>
                                DropdownMenuItem<String>(
                                  value: motivo,
                                  child: Text(
                                    motivo,
                                  ),
                                ),
                          )
                              .toList(),
                          onChanged: _enviando
                              ? null
                              : (valor) {
                            setState(() {
                              _motivoSelecionado =
                                  valor;
                            });
                          },
                          validator: (valor) {
                            if (valor == null ||
                                valor.trim().isEmpty) {
                              return 'Selecione o motivo da denúncia.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ========================================
                        // DESCRIÇÃO
                        // ========================================

                        const Text(
                          'Explique o motivo da denúncia',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 5),

                        TextFormField(
                          controller:
                          _descricaoController,
                          enabled: !_enviando,
                          minLines: 5,
                          maxLines: 8,
                          maxLength: 2000,
                          decoration:
                          InputDecoration(
                            hintText:
                            'Descreva o problema ou forneça informações que ajudem na análise.',
                            filled: true,
                            fillColor: Colors.white,
                            alignLabelWithHint: true,

                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(6),
                            ),

                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(6),
                            ),

                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(6),
                            ),
                          ),
                          validator: (valor) {
                            if (valor == null ||
                                valor.trim().isEmpty) {
                              return 'Informe uma descrição.';
                            }

                            if (valor.trim().length < 10) {
                              return 'Forneça mais detalhes sobre a denúncia.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // ========================================
                        // COMPROVANTE
                        // ========================================

                        const Text(
                          'Comprovante',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 5),

                        OutlinedButton.icon(
                          onPressed: _enviando
                              ? null
                              : _selecionarComprovante,
                          style:
                          OutlinedButton.styleFrom(
                            backgroundColor:
                            Colors.white,
                            foregroundColor:
                            Colors.black87,

                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(6),
                            ),
                          ),
                          icon: const Icon(
                            Icons.attach_file,
                            size: 18,
                          ),
                          label: const Text(
                            'Anexar comprovante',
                          ),
                        ),

                        // ========================================
                        // ARQUIVO SELECIONADO
                        // ========================================

                        if (_nomeArquivo != null) ...[
                          const SizedBox(height: 8),

                          Container(
                            width: double.infinity,
                            padding:
                            const EdgeInsets.all(10),

                            decoration:
                            BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(6),
                            ),

                            child: Row(
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 18,
                                  color: Colors.black54,
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: Text(
                                    _nomeArquivo!,
                                    softWrap: true,
                                    style:
                                    const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),

                                IconButton(
                                  onPressed: _enviando
                                      ? null
                                      : _removerComprovante,
                                  tooltip:
                                  'Remover comprovante',
                                  icon: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 5),

                        const Text(
                          'Formatos aceitos: PDF, JPG, JPEG ou PNG. Máximo: 10 MB.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ========================================
                        // BOTÕES
                        // ========================================

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.end,
                          children: [
                            // ==================================
                            // CANCELAR
                            // ==================================

                            TextButton(
                              onPressed: _enviando
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
                              child: const Text(
                                'Cancelar',
                              ),
                            ),

                            const SizedBox(width: 10),

                            // ==================================
                            // ENVIAR DENÚNCIA
                            // ==================================

                            ElevatedButton(
                              onPressed: _enviando
                                  ? null
                                  : _enviarDenuncia,
                              style:
                              ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.grey.shade600,
                                foregroundColor:
                                Colors.white,

                                padding:
                                const EdgeInsets.symmetric(
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
                              child: _enviando
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
                                'Enviar denúncia',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }
}

