import 'dart:developer' as developer;

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../repositorios/obras_repository.dart';
import '../utils/diagnostico_supabase.dart';
import '../widgets/dialog_mensagem_widget.dart';

// ==========================================================
// FORMATADOR DE LIMITE DE PALAVRAS
// ==========================================================
class _LimitePalavrasFormatter extends TextInputFormatter {
  final int maxPalavras;

  _LimitePalavrasFormatter(this.maxPalavras);

  int _contarPalavras(String texto) {
    final textoLimpo = texto.trim();

    if (textoLimpo.isEmpty) {
      return 0;
    }

    return textoLimpo.split(RegExp(r'\s+')).length;
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final quantidade = _contarPalavras(newValue.text);

    // Dentro do limite.
    if (quantidade <= maxPalavras) {
      return newValue;
    }

    // Se ultrapassar, mantém o texto anterior.
    return oldValue;
  }
}

// ==========================================================
// PUBLICAR PAGE
// ==========================================================
class PublicarPage extends StatefulWidget {
  const PublicarPage({super.key});

  @override
  State<PublicarPage> createState() => _PublicarPageState();
}

// ==========================================================
// MODELO LOCAL DE COAUTOR
// ==========================================================
class _CoautorCampos {
  final TextEditingController nomeController;
  final TextEditingController instituicaoController;

  _CoautorCampos()
      : nomeController = TextEditingController(),
        instituicaoController = TextEditingController();

  void dispose() {
    nomeController.dispose();
    instituicaoController.dispose();
  }
}

// ==========================================================
// STATE
// ==========================================================
class _PublicarPageState extends State<PublicarPage> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _autorController = TextEditingController();
  final _autorInstituicaoController = TextEditingController();
  final _areaController = TextEditingController();
  final _anoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _palavrasChaveController = TextEditingController();

  final List<_CoautorCampos> _coautores = [];

  String? _categoria;

  fp.PlatformFile? _arquivoSelecionado;

  bool _enviando = false;

  // ==========================================================
  // LIMITE DA DESCRIÇÃO
  // ==========================================================
  static const int _limitePalavrasDescricao = 100;

  int _quantidadePalavrasDescricao = 0;

  // ==========================================================
  // CATEGORIAS
  // ==========================================================
  final List<String> _categorias = const [
    'Tese de Doutoramento',
    'Dissertação de Mestrado',
    'Monografia',
    'Artigos Científicos',
    'Literatura',
  ];

  // ==========================================================
  // INIT
  // ==========================================================
  @override
  void initState() {
    super.initState();

    developer.log('');
    developer.log('🚀 PUBLICAR PAGE INICIADA');

    _descricaoController.addListener(_atualizarContadorDescricao);

    _diagnosticarPagina();
  }

  // ==========================================================
  // CONTAR PALAVRAS
  // ==========================================================
  int _contarPalavras(String texto) {
    final textoLimpo = texto.trim();

    if (textoLimpo.isEmpty) {
      return 0;
    }

    return textoLimpo.split(RegExp(r'\s+')).length;
  }

  // ==========================================================
  // ATUALIZAR CONTADOR DA DESCRIÇÃO
  // ==========================================================
  void _atualizarContadorDescricao() {
    final quantidade = _contarPalavras(
      _descricaoController.text,
    );

    if (quantidade == _quantidadePalavrasDescricao) {
      return;
    }

    if (mounted) {
      setState(() {
        _quantidadePalavrasDescricao = quantidade;
      });
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================
  @override
  void dispose() {
    _descricaoController.removeListener(
      _atualizarContadorDescricao,
    );

    _tituloController.dispose();
    _autorController.dispose();
    _autorInstituicaoController.dispose();
    _areaController.dispose();
    _anoController.dispose();
    _descricaoController.dispose();
    _palavrasChaveController.dispose();

    for (final coautor in _coautores) {
      coautor.dispose();
    }

    super.dispose();
  }

  // ==========================================================
  // MENSAGEM PADRÃO
  // ==========================================================
  Future<void> _mostrarMensagem(
      String mensagem, {
        bool erro = false,
        String? titulo,
      }) async {
    if (!mounted) return;

    if (erro) {
      await DialogMensagem.erro(
        context,
        titulo: titulo ?? 'Erro',
        mensagem: mensagem,
      );
    } else {
      await DialogMensagem.sucesso(
        context,
        titulo: titulo ?? 'Sucesso',
        mensagem: mensagem,
      );
    }
  }

  // ==========================================================
  // DIAGNÓSTICO
  // ==========================================================
  Future<void> _diagnosticarPagina() async {
    try {
      await DiagnosticoSupabase.diagnosticar(
        'PUBLICAR PAGE - ABERTURA',
      );
    } catch (e, stackTrace) {
      DiagnosticoSupabase.erro(
        'ERRO NO DIAGNÓSTICO DA PUBLICAR PAGE',
        e,
        stackTrace,
      );
    }
  }

  // ==========================================================
  // ADICIONAR COAUTOR
  // ==========================================================
  void _adicionarCoautor() {
    if (_enviando) return;

    setState(() {
      _coautores.add(_CoautorCampos());
    });
  }

  // ==========================================================
  // REMOVER COAUTOR
  // ==========================================================
  void _removerCoautor(int index) {
    if (_enviando) return;

    if (index < 0 || index >= _coautores.length) {
      return;
    }

    final coautor = _coautores[index];

    coautor.dispose();

    setState(() {
      _coautores.removeAt(index);
    });
  }

  // ==========================================================
  // MONTAR COAUTORES
  // ==========================================================
  String _montarCoautores() {
    final lista = <String>[];

    for (final coautor in _coautores) {
      final nome = coautor.nomeController.text.trim();

      if (nome.isEmpty) {
        continue;
      }

      lista.add(nome);
    }

    return lista.join('\n');
  }

  // ==========================================================
  // VALIDAR COAUTORES
  // ==========================================================
  String? _validarCoautores() {
    for (int i = 0; i < _coautores.length; i++) {
      final coautor = _coautores[i];

      final nome = coautor.nomeController.text.trim();

      final instituicao =
      coautor.instituicaoController.text.trim();

      if (nome.isEmpty && instituicao.isEmpty) {
        continue;
      }

      if (nome.isEmpty) {
        return 'Informe o nome do coautor ${i + 1}.';
      }
    }

    return null;
  }

  // ==========================================================
  // VALIDAR CAMPOS PRINCIPAIS
  // ==========================================================
  bool _validarCamposObrigatorios() {
    final formularioValido =
        _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return false;
    }

    if (_categoria == null || _categoria!.trim().isEmpty) {
      return false;
    }

    return true;
  }

  // ==========================================================
  // VERIFICAR OBRA PUBLICADA
  // ==========================================================
  Future<bool> _verificarObraJaPublicada() async {
    final titulo = _tituloController.text.trim();

    final autor = _autorController.text.trim();

    final anoObra = int.tryParse(
      _anoController.text.trim(),
    );

    if (titulo.isEmpty || autor.isEmpty || anoObra == null) {
      return false;
    }

    try {
      return await ObrasRepository.instancia.obraJaPublicada(
        titulo: titulo,
        autor: autor,
        anoObra: anoObra,
      );
    } catch (e) {
      if (!mounted) return false;

      await _mostrarMensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        erro: true,
        titulo: 'Verificação',
      );

      return true;
    }
  }

  // ==========================================================
  // SELECIONAR PDF
  // ==========================================================
  Future<void> _selecionarArquivo() async {
    if (_enviando) return;

    // ========================================================
    // PRIMEIRO: VALIDAR CAMPOS NECESSÁRIOS
    // ========================================================
    final camposValidos = _validarCamposObrigatorios();

    if (!camposValidos) {
      await _mostrarMensagem(
        'Preencha todos os campos obrigatórios '
            'antes de anexar o PDF.',
        erro: true,
        titulo: 'Campos obrigatórios',
      );

      return;
    }

    // ========================================================
    // VALIDAR ANO
    // ========================================================
    final anoObra = int.tryParse(
      _anoController.text.trim(),
    );

    if (anoObra == null) {
      await _mostrarMensagem(
        'Informe um ano válido para a obra.',
        erro: true,
      );

      return;
    }

    final anoAtual = DateTime.now().year;

    if (anoObra < 1900 || anoObra > anoAtual) {
      await _mostrarMensagem(
        'O ano da obra deve estar entre '
            '1900 e $anoAtual.',
        erro: true,
      );

      return;
    }

    // ========================================================
    // VERIFICAR LIMITE DA DESCRIÇÃO
    // ========================================================
    final palavrasDescricao = _contarPalavras(
      _descricaoController.text,
    );

    if (palavrasDescricao > _limitePalavrasDescricao) {
      await _mostrarMensagem(
        'A descrição não pode ultrapassar '
            '$_limitePalavrasDescricao palavras.',
        erro: true,
        titulo: 'Limite da descrição',
      );

      return;
    }

    // ========================================================
    // VERIFICAR DUPLICIDADE ANTES DO ANEXO
    // ========================================================
    DiagnosticoSupabase.inicio(
      'PUBLICAR - VERIFICAÇÃO DE OBRA ANTES DO ANEXO',
    );

    try {
      final jaPublicada =
      await ObrasRepository.instancia.obraJaPublicada(
        titulo: _tituloController.text.trim(),
        autor: _autorController.text.trim(),
        anoObra: anoObra,
      );

      DiagnosticoSupabase.fim();

      if (jaPublicada) {
        await _mostrarMensagem(
          'Esta obra já se encontra publicada '
              'na plataforma e não pode ser enviada novamente.',
          erro: true,
          titulo: 'Obra já publicada',
        );

        return;
      }
    } catch (e, stackTrace) {
      DiagnosticoSupabase.erro(
        'ERRO AO VERIFICAR OBRA ANTES DO ANEXO',
        e,
        stackTrace,
      );

      DiagnosticoSupabase.fim();

      if (!mounted) return;

      await _mostrarMensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        erro: true,
        titulo: 'Erro na verificação',
      );

      return;
    }

    // ========================================================
    // ABRIR FILE PICKER
    // ========================================================
    DiagnosticoSupabase.inicio(
      'PUBLICAR - SELEÇÃO DO ARQUIVO',
    );

    developer.log(
      '📂 Abrindo FilePicker...',
    );

    try {
      final resultado = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
        allowMultiple: false,
      );

      if (resultado == null || resultado.files.isEmpty) {
        developer.log(
          '⚠️ Nenhum arquivo foi selecionado.',
        );

        DiagnosticoSupabase.fim();

        return;
      }

      final arquivo = resultado.files.first;

      developer.log(
        '📄 Nome: ${arquivo.name}',
      );

      developer.log(
        '📏 Tamanho: ${arquivo.size} bytes',
      );

      developer.log(
        '📁 Extensão: ${arquivo.extension}',
      );

      developer.log(
        '📂 Caminho: ${arquivo.path}',
      );

      developer.log(
        '🧠 Bytes disponíveis: ${arquivo.bytes != null}',
      );

      if (arquivo.bytes == null) {
        DiagnosticoSupabase.fim();

        await _mostrarMensagem(
          'Não foi possível ler o arquivo selecionado.',
          erro: true,
        );

        return;
      }

      if (!arquivo.name.toLowerCase().endsWith('.pdf')) {
        DiagnosticoSupabase.fim();

        await _mostrarMensagem(
          'Selecione somente arquivos PDF.',
          erro: true,
        );

        return;
      }

      // ======================================================
      // SEGUNDA VERIFICAÇÃO
      // ======================================================
      final aindaPublicada =
      await _verificarObraJaPublicada();

      if (aindaPublicada) {
        DiagnosticoSupabase.fim();

        if (!mounted) return;

        await _mostrarMensagem(
          'Esta obra já se encontra publicada '
              'na plataforma e não pode ser enviada novamente.',
          erro: true,
          titulo: 'Obra já publicada',
        );

        return;
      }

      setState(() {
        _arquivoSelecionado = arquivo;
      });

      developer.log(
        '✅ PDF selecionado com sucesso.',
      );

      DiagnosticoSupabase.fim();
    } catch (e, stackTrace) {
      DiagnosticoSupabase.erro(
        'ERRO AO SELECIONAR PDF',
        e,
        stackTrace,
      );

      DiagnosticoSupabase.fim();

      if (!mounted) return;

      await _mostrarMensagem(
        'Erro ao selecionar o arquivo: $e',
        erro: true,
      );
    }
  }

  // ==========================================================
  // PUBLICAR
  // ==========================================================
  Future<void> _publicar() async {
    if (_enviando) return;

    DiagnosticoSupabase.inicio(
      'PUBLICAR - INÍCIO DO PROCESSO',
    );

    // ========================================================
    // VALIDAR FORMULÁRIO
    // ========================================================
    final formularioValido =
        _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      DiagnosticoSupabase.fim();

      await _mostrarMensagem(
        'Preencha todos os campos obrigatórios '
            'antes de enviar a obra.',
        erro: true,
        titulo: 'Campos obrigatórios',
      );

      return;
    }

    // ========================================================
    // LIMITE DA DESCRIÇÃO
    // ========================================================
    final palavrasDescricao = _contarPalavras(
      _descricaoController.text,
    );

    if (palavrasDescricao > _limitePalavrasDescricao) {
      DiagnosticoSupabase.fim();

      await _mostrarMensagem(
        'A descrição não pode ultrapassar '
            '$_limitePalavrasDescricao palavras.',
        erro: true,
        titulo: 'Limite da descrição',
      );

      return;
    }

    // ========================================================
    // CATEGORIA
    // ========================================================
    if (_categoria == null || _categoria!.trim().isEmpty) {
      DiagnosticoSupabase.fim();

      await _mostrarMensagem(
        'Selecione uma categoria antes de enviar a obra.',
        erro: true,
        titulo: 'Campos obrigatórios',
      );

      return;
    }

    // ========================================================
    // COAUTORES
    // ========================================================
    final erroCoautores = _validarCoautores();

    if (erroCoautores != null) {
      DiagnosticoSupabase.fim();

      await _mostrarMensagem(
        erroCoautores,
        erro: true,
        titulo: 'Coautor',
      );

      return;
    }

    // ========================================================
    // ANO
    // ========================================================
    final anoObra = int.tryParse(
      _anoController.text.trim(),
    );

    if (anoObra == null) {
      DiagnosticoSupabase.fim();

      await _mostrarMensagem(
        'Informe um ano válido para a obra.',
        erro: true,
      );

      return;
    }

    final anoAtual = DateTime.now().year;

    if (anoObra < 1900 || anoObra > anoAtual) {
      DiagnosticoSupabase.fim();

      await _mostrarMensagem(
        'O ano da obra deve estar entre '
            '1900 e $anoAtual.',
        erro: true,
      );

      return;
    }

    // ========================================================
    // VERIFICAR PDF
    // ========================================================
    if (_arquivoSelecionado == null) {
      DiagnosticoSupabase.fim();

      await _mostrarMensagem(
        'Selecione o arquivo PDF da obra.',
        erro: true,
        titulo: 'Arquivo obrigatório',
      );

      return;
    }

    if (_arquivoSelecionado!.bytes == null) {
      DiagnosticoSupabase.fim();

      await _mostrarMensagem(
        'Não foi possível ler o PDF selecionado.',
        erro: true,
      );

      return;
    }

    // ========================================================
    // VERIFICAR OBRA JÁ PUBLICADA
    // ========================================================
    final jaPublicada =
    await _verificarObraJaPublicada();

    if (jaPublicada) {
      DiagnosticoSupabase.fim();

      if (!mounted) return;

      await _mostrarMensagem(
        'Esta obra já se encontra publicada '
            'na plataforma e não pode ser enviada novamente.',
        erro: true,
        titulo: 'Obra já publicada',
      );

      return;
    }

    // ========================================================
    // AUTH
    // ========================================================
    final usuario = await DiagnosticoSupabase.diagnosticar(
      'PUBLICAR - VERIFICAÇÃO AUTH ANTES DO ENVIO',
    );

    if (usuario == null) {
      DiagnosticoSupabase.fim();

      if (!mounted) return;

      await _mostrarMensagem(
        'É necessário entrar na sua conta para publicar.',
        erro: true,
      );

      return;
    }

    // ========================================================
    // DADOS
    // ========================================================
    final titulo = _tituloController.text.trim();

    final autor = _autorController.text.trim();

    final autorInstituicao =
    _autorInstituicaoController.text.trim();

    final coautores = _montarCoautores();

    final area = _areaController.text.trim();

    final categoria = _categoria!.trim();

    final descricao = _descricaoController.text.trim();

    final palavrasChave =
    _palavrasChaveController.text.trim();

    final arquivo = _arquivoSelecionado!;

    developer.log(
      '📌 título: $titulo',
    );

    developer.log(
      '👤 autor: $autor',
    );

    developer.log(
      '🏛️ instituição/campus do autor: '
          '$autorInstituicao',
    );

    developer.log(
      '👥 coautores:\n$coautores',
    );

    for (int i = 0; i < _coautores.length; i++) {
      final coautor = _coautores[i];

      developer.log(
        '👤 coautor ${i + 1}: '
            '${coautor.nomeController.text.trim()}',
      );

      developer.log(
        '🏛️ instituição/campus coautor '
            '${i + 1}: '
            '${coautor.instituicaoController.text.trim()}',
      );
    }

    developer.log(
      '🎓 área: $area',
    );

    developer.log(
      '📅 ano: $anoObra',
    );

    developer.log(
      '🏷️ categoria: $categoria',
    );

    developer.log(
      '📝 palavras da descrição: '
          '${_contarPalavras(descricao)}/'
          '$_limitePalavrasDescricao',
    );

    // ========================================================
    // BLOQUEAR FORMULÁRIO
    // ========================================================
    setState(() {
      _enviando = true;
    });

    try {
      // ======================================================
      // ÚLTIMA VERIFICAÇÃO NO REPOSITORY
      // ======================================================
      final ultimaVerificacao =
      await ObrasRepository.instancia.obraJaPublicada(
        titulo: titulo,
        autor: autor,
        anoObra: anoObra,
      );

      if (ultimaVerificacao) {
        throw Exception(
          'Esta obra já se encontra publicada '
              'na plataforma e não pode ser enviada novamente.',
        );
      }

      // ======================================================
      // ENVIAR
      // ======================================================
      await ObrasRepository.instancia.enviarObraPendente(
        titulo: titulo,
        autor: autor,
        coautores: coautores,
        area: area,
        anoObra: anoObra,
        categoria: categoria,
        descricao: descricao,
        palavrasChave: palavrasChave,
        arquivo: arquivo,
      );

      DiagnosticoSupabase.fim();

      if (!mounted) return;

      await _mostrarMensagem(
        'Obra enviada com sucesso! '
            'Ela ficará pendente de aprovação.',
      );

      if (!mounted) return;

      // ======================================================
      // LIMPAR FORMULÁRIO
      // ======================================================
      _formKey.currentState?.reset();

      _tituloController.clear();
      _autorController.clear();
      _autorInstituicaoController.clear();
      _areaController.clear();
      _anoController.clear();
      _descricaoController.clear();
      _palavrasChaveController.clear();

      for (final coautor in _coautores) {
        coautor.dispose();
      }

      setState(() {
        _coautores.clear();
        _categoria = null;
        _arquivoSelecionado = null;
      });

      await Future.delayed(
        const Duration(
          milliseconds: 1200,
        ),
      );

      if (!mounted) return;

      context.go('/minha-conta');
    } catch (e, stackTrace) {
      DiagnosticoSupabase.erro(
        'ERRO AO PUBLICAR OBRA',
        e,
        stackTrace,
      );

      DiagnosticoSupabase.fim();

      if (!mounted) return;

      await _mostrarMensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  // ==========================================================
  // CAMPO PADRÃO
  // ==========================================================
  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    bool obrigatorio = true,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    int? maxPalavras,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_enviando,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: maxPalavras != null
          ? [
        _LimitePalavrasFormatter(maxPalavras),
      ]
          : null,
      validator: validator ??
              (value) {
            if (!obrigatorio) {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Preencha o campo $label.';
            }

            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(14),
          ),
          borderSide: BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
        helper: maxPalavras != null
            ? Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$_quantidadePalavrasDescricao'
                  ' / $maxPalavras palavras',
              style: TextStyle(
                fontSize: 12,
                color: _quantidadePalavrasDescricao >=
                    maxPalavras
                    ? Colors.orange.shade700
                    : Colors.grey.shade600,
              ),
            ),
          ],
        )
            : null,
      ),
    );
  }

  // ==========================================================
  // CAMPO INSTITUIÇÃO
  // ==========================================================
  Widget _campoInstituicao({
    required TextEditingController controller,
    required String label,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_enviando,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText:
        hintText ?? 'Ex.: Universidade Politécnica',
        prefixIcon: const Icon(
          Icons.account_balance_outlined,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CAMPO COAUTOR
  // ==========================================================
  Widget _construirCoautor(int index) {
    final coautor = _coautores[index];

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Coautor ${index + 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remover coautor',
                onPressed: _enviando
                    ? null
                    : () {
                  _removerCoautor(index);
                },
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: coautor.nomeController,
            enabled: !_enviando,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Nome do coautor',
              hintText: 'Ex.: João Silva',
              prefixIcon: const Icon(
                Icons.person_outline,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o nome do coautor.';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          _campoInstituicao(
            controller: coautor.instituicaoController,
            label: 'Instituição/Campus (opcional)',
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // AVISO DE RESPONSABILIDADE
  // ==========================================================
  Widget _avisoResponsabilidade() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: Colors.grey.shade700,
          ),
          children: const [
            TextSpan(
              text: 'Aviso de responsabilidade: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text:
              'O conteúdo submetido é de responsabilidade '
                  'do autor ou responsável pela publicação. '
                  'A plataforma Obra Livre não garante a '
                  'autenticidade, originalidade ou veracidade '
                  'das obras submetidas. As obras passam por '
                  'análise e aprovação antes da publicação, '
                  'sem que esse processo constitua certificação '
                  'de autoria ou originalidade.',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Publicar obra',
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 700,
              ),
              child: Card(
                elevation: 6,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Envie a sua obra para análise e aprovação.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ==================================================
                        // TÍTULO
                        // ==================================================
                        _campo(
                          controller: _tituloController,
                          label: 'Título',
                          icon: Icons.title,
                          hintText: 'Título da obra',
                          textInputAction:
                          TextInputAction.next,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Digite o título da obra.';
                            }

                            if (value.trim().length < 3) {
                              return 'O título é muito curto.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // AUTOR
                        // ==================================================
                        _campo(
                          controller: _autorController,
                          label: 'Autor',
                          icon: Icons.person_outline,
                          hintText: 'Nome do autor',
                          textInputAction:
                          TextInputAction.next,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Digite o nome do autor.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        _campoInstituicao(
                          controller:
                          _autorInstituicaoController,
                          label:
                          'Instituição/Campus (opcional)',
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // COAUTORES
                        // ==================================================
                        Row(
                          children: [
                            const Icon(
                              Icons.group_outlined,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Coautores',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _enviando
                                  ? null
                                  : _adicionarCoautor,
                              icon: const Icon(
                                Icons.add,
                                size: 18,
                              ),
                              label: const Text(
                                'Adicionar',
                              ),
                              style:
                              OutlinedButton.styleFrom(
                                minimumSize:
                                const Size(0, 40),
                                padding:
                                const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        if (_coautores.isEmpty)
                          Text(
                            'Nenhum coautor adicionado.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),

                        if (_coautores.isNotEmpty)
                          const SizedBox(height: 8),

                        for (int i = 0;
                        i < _coautores.length;
                        i++)
                          _construirCoautor(i),

                        const SizedBox(height: 16),

                        // ==================================================
                        // ÁREA
                        // ==================================================
                        _campo(
                          controller: _areaController,
                          label: 'Área',
                          icon: Icons.school_outlined,
                          hintText:
                          'Ex.: Engenharia Civil',
                          textInputAction:
                          TextInputAction.next,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Digite a área da obra.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // ANO
                        // ==================================================
                        _campo(
                          controller: _anoController,
                          label: 'Ano da obra',
                          icon:
                          Icons.calendar_today_outlined,
                          hintText: 'Ex.: 2025',
                          keyboardType:
                          TextInputType.number,
                          textInputAction:
                          TextInputAction.next,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Digite o ano da obra.';
                            }

                            final ano = int.tryParse(
                              value.trim(),
                            );

                            if (ano == null) {
                              return 'Digite um ano válido.';
                            }

                            final anoAtual =
                                DateTime.now().year;

                            if (ano < 1900 ||
                                ano > anoAtual) {
                              return 'Informe um ano entre '
                                  '1900 e $anoAtual.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // CATEGORIA
                        // ==================================================
                        DropdownButtonFormField<String>(
                          initialValue: _categoria,
                          decoration: InputDecoration(
                            labelText: 'Categoria',
                            prefixIcon: const Icon(
                              Icons.category_outlined,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(14),
                            ),
                          ),
                          items: _categorias
                              .map(
                                (categoria) =>
                                DropdownMenuItem<String>(
                                  value: categoria,
                                  child: Text(categoria),
                                ),
                          )
                              .toList(),
                          onChanged: _enviando
                              ? null
                              : (valor) {
                            setState(() {
                              _categoria = valor;
                            });
                          },
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Selecione uma categoria.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // DESCRIÇÃO - MÁXIMO 100 PALAVRAS
                        // ==================================================
                        _campo(
                          controller: _descricaoController,
                          label: 'Resumo / descrição',
                          icon:
                          Icons.description_outlined,
                          hintText:
                          'Faça uma breve descrição da obra',
                          maxLines: 5,
                          maxPalavras:
                          _limitePalavrasDescricao,
                          keyboardType:
                          TextInputType.multiline,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Digite uma descrição da obra.';
                            }

                            final quantidade =
                            _contarPalavras(value);

                            if (quantidade >
                                _limitePalavrasDescricao) {
                              return 'A descrição deve ter no máximo '
                                  '$_limitePalavrasDescricao palavras.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // PALAVRAS-CHAVE
                        // ==================================================
                        _campo(
                          controller:
                          _palavrasChaveController,
                          label: 'Palavras-chave',
                          icon: Icons.key_outlined,
                          hintText:
                          'Ex.: estruturas, concreto, construção',
                          maxLines: 2,
                          obrigatorio: false,
                          keyboardType:
                          TextInputType.multiline,
                        ),

                        const SizedBox(height: 24),

                        // ==================================================
                        // PDF
                        // ==================================================
                        Container(
                          padding:
                          const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius:
                            BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .picture_as_pdf_outlined,
                                    color: Colors.red,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _arquivoSelecionado ==
                                          null
                                          ? 'Nenhum PDF selecionado'
                                          : _arquivoSelecionado!
                                          .name,
                                      style:
                                      const TextStyle(
                                        fontWeight:
                                        FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              SizedBox(
                                height: 44,
                                child: Align(
                                  alignment:
                                  Alignment.centerLeft,
                                  child:
                                  OutlinedButton.icon(
                                    onPressed: _enviando
                                        ? null
                                        : _selecionarArquivo,
                                    icon: const Icon(
                                      Icons.upload_file,
                                      size: 19,
                                    ),
                                    label: Text(
                                      _arquivoSelecionado ==
                                          null
                                          ? 'Selecionar PDF'
                                          : 'Alterar PDF',
                                      style:
                                      const TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                        FontWeight.w500,
                                      ),
                                    ),
                                    style: OutlinedButton
                                        .styleFrom(
                                      padding:
                                      const EdgeInsets
                                          .symmetric(
                                        horizontal: 16,
                                      ),
                                      side: BorderSide(
                                        color: Colors
                                            .grey.shade500,
                                        width: 1,
                                      ),
                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius
                                            .circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              if (_arquivoSelecionado !=
                                  null)
                                ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${(_arquivoSelecionado!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                    textAlign:
                                    TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                      Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        _avisoResponsabilidade(),

                        const SizedBox(height: 20),

                        // ==================================================
                        // BOTÕES
                        // ==================================================
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                onPressed: _enviando
                                    ? null
                                    : () => context.go(
                                  '/minha-conta',
                                ),
                                style: OutlinedButton
                                    .styleFrom(
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal: 14,
                                  ),
                                  side: BorderSide(
                                    color:
                                    Colors.grey.shade500,
                                    width: 1,
                                  ),
                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                        6),
                                  ),
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: _enviando
                                    ? null
                                    : _publicar,
                                style: ElevatedButton
                                    .styleFrom(
                                  elevation: 0,
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal: 14,
                                  ),
                                  side:
                                  const BorderSide(
                                    color: Colors.blue,
                                    width: 1,
                                  ),
                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                        6),
                                  ),
                                ),
                                child: Text(
                                  _enviando
                                      ? 'Enviando...'
                                      : 'Enviar para aprovação',
                                  style:
                                  const TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

