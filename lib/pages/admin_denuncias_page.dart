import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositorios/denuncias_admin_repository.dart';
import '../widgets/dialog_mensagem_widget.dart';
import '../widgets/paginacao_google_widget.dart';
import '../widgets/search_bar.dart';
import '../widgets/obra_detalhes_dialog.dart';

// ==========================================================
// ADMIN DENUNCIAS PAGE
// ==========================================================

class AdminDenunciasPage extends StatefulWidget {
  const AdminDenunciasPage({
    super.key,
  });

  @override
  State<AdminDenunciasPage> createState() =>
      _AdminDenunciasPageState();
}

// ==========================================================
// STATE
// ==========================================================

class _AdminDenunciasPageState
    extends State<AdminDenunciasPage> {
  final DenunciasAdminRepository _repository =
      DenunciasAdminRepository.instancia;

  List<Map<String, dynamic>> _denuncias = [];
  List<Map<String, dynamic>> _denunciasFiltradas = [];

  bool _carregando = true;
  bool _atualizandoEmSegundoPlano = false;
  bool _processando = false;

  String? _erro;

  String _filtro = 'pendente';
  String _pesquisa = '';

  int _paginaAtual = 1;

  static const int _porPagina = 10;
  static const double _radius = 6;

// ==========================================================
// INIT
// ==========================================================

  @override
  void initState() {
    super.initState();
    _carregarInicial();
  }

// ==========================================================
// CARREGAMENTO INICIAL
// ==========================================================

  Future<void> _carregarInicial() async {
    try {
      final cache =
      await _repository.carregarDenunciasDoCache();

      if (cache != null && mounted) {
        setState(() {
          _denuncias = cache;
          _aplicarFiltros();
          _paginaAtual = 1;
          _carregando = false;
          _erro = null;
          _atualizandoEmSegundoPlano = true;
        });
      }
    } catch (_) {}

    await _atualizarDoSupabase(
      mostrarCarregamento: _denuncias.isEmpty,
    );
  }

// ==========================================================
// ATUALIZAR DO SUPABASE
// ==========================================================

  Future<void> _atualizarDoSupabase({
    bool mostrarCarregamento = false,
  }) async {
    if (mostrarCarregamento && mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    if (mounted) {
      setState(() {
        _atualizandoEmSegundoPlano = true;
      });
    }

    try {
      final denuncias =
      await _repository.carregarDenuncias();

      if (!mounted) return;

      setState(() {
        _denuncias = denuncias;
        _aplicarFiltros();
        _paginaAtual = 1;
        _carregando = false;
        _atualizandoEmSegundoPlano = false;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _atualizandoEmSegundoPlano = false;
      });

      if (_denuncias.isNotEmpty) {
        await DialogMensagem.aviso(
          context,
          titulo: 'Não foi possível atualizar',
          mensagem:
          'Não foi possível atualizar as denúncias. '
              'Os dados anteriores continuam disponíveis.',
        );
      } else {
        setState(() {
          _erro = e
              .toString()
              .replaceFirst('Exception: ', '');
        });
      }
    }
  }

// ==========================================================
// REFRESH
// ==========================================================

  Future<void> _carregarDenuncias() async {
    await _atualizarDoSupabase(
      mostrarCarregamento: false,
    );
  }

// ==========================================================
// ALTERAR FILTRO
// ==========================================================

  void _alterarFiltro(String filtro) {
    if (_filtro == filtro) return;

    setState(() {
      _filtro = filtro;
      _paginaAtual = 1;
      _aplicarFiltros();
    });
  }

// ==========================================================
// PESQUISA
// ==========================================================

  void _executarPesquisa(String valor) {
    setState(() {
      _pesquisa = valor.trim();
      _paginaAtual = 1;
      _aplicarFiltros();
    });
  }

// ==========================================================
// APLICAR FILTROS
// ==========================================================

  void _aplicarFiltros() {
    final termo = _pesquisa.trim().toLowerCase();

    Iterable<Map<String, dynamic>> resultado =
    _denuncias.where((denuncia) {
      final status =
          denuncia['status']?.toString().toLowerCase() ??
              'pendente';

      return status == _filtro;
    });

    if (termo.isNotEmpty) {
      resultado = resultado.where((denuncia) {
        final obra =
        denuncia['obra'] as Map<String, dynamic>?;

        final perfil =
        denuncia['perfil'] as Map<String, dynamic>?;

        final titulo =
            obra?['titulo']?.toString() ?? '';

        final autor =
            obra?['autor']?.toString() ?? '';

        final motivo =
            denuncia['motivo']?.toString() ?? '';

        final descricao =
            denuncia['descricao']?.toString() ?? '';

        final status =
            denuncia['status']?.toString() ?? '';

        final nome =
            perfil?['nome_completo']?.toString() ??
                perfil?['full_name']?.toString() ??
                perfil?['name']?.toString() ??
                '';

        final texto = [
          titulo,
          autor,
          motivo,
          descricao,
          status,
          nome,
        ].join(' ').toLowerCase();

        return texto.contains(termo);
      });
    }

    _denunciasFiltradas = resultado.toList();
  }

// ==========================================================
// PAGINAÇÃO
// ==========================================================

  int get _totalPaginas {
    if (_denunciasFiltradas.isEmpty) {
      return 1;
    }

    return (_denunciasFiltradas.length / _porPagina)
        .ceil();
  }

  List<Map<String, dynamic>> get _denunciasDaPagina {
    final inicio =
        (_paginaAtual - 1) * _porPagina;

    if (inicio >= _denunciasFiltradas.length) {
      return [];
    }

    final fim = (inicio + _porPagina).clamp(
      0,
      _denunciasFiltradas.length,
    );

    return _denunciasFiltradas.sublist(
      inicio,
      fim,
    );
  }

// ==========================================================
// NOME DO USUÁRIO
// ==========================================================

  String _nomeUsuario(
      Map<String, dynamic> denuncia,
      ) {
    final perfil =
    denuncia['perfil'] as Map<String, dynamic>?;

    if (perfil == null) {
      return 'Usuário não identificado';
    }

    final nomeCompleto =
        perfil['nome_completo']
            ?.toString()
            .trim() ??
            '';

    if (nomeCompleto.isNotEmpty) {
      return nomeCompleto;
    }

    final fullName =
        perfil['full_name']
            ?.toString()
            .trim() ??
            '';

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final name =
        perfil['name']
            ?.toString()
            .trim() ??
            '';

    if (name.isNotEmpty) {
      return name;
    }

    return 'Usuário não identificado';
  }

// ==========================================================
// TÍTULO DO FILTRO
// ==========================================================

  String _tituloFiltro() {
    switch (_filtro) {
      case 'em_analise':
        return 'Denúncias em análise';

      case 'resolvida':
        return 'Denúncias resolvidas';

      case 'rejeitada':
        return 'Denúncias rejeitadas';

      case 'pendente':
      default:
        return 'Denúncias aguardando análise';
    }
  }

// ==========================================================
// TEXTO STATUS
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
// BADGE STATUS
// ==========================================================

  Widget _buildStatusBadge(String status) {
    final cor = _corStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Text(
        _textoStatus(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cor,
        ),
      ),
    );
  }

// ==========================================================
// INFO ITEM
// ==========================================================

  Widget _buildInfoItem({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 5,
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
            ),
          ],
        ),
      ),
    );
  }

// ==========================================================
// BOTÃO
// ==========================================================

  ButtonStyle _buttonStyle({
    bool principal = false,
  }) {
    if (principal) {
      return ElevatedButton.styleFrom(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(_radius),
        ),
      );
    }

    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black87,
      side: BorderSide(
        color: Colors.grey.shade400,
      ),
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(_radius),
      ),
    );
  }

// ==========================================================
// BUILD
// ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 24,
        title: const Text(
          'Denúncias',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_atualizandoEmSegundoPlano)
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
              ),
              child: Center(
                child: SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(
              right: 4,
            ),
            child: IconButton(
              tooltip: 'Atualizar',
              onPressed:
              _processando ||
                  _atualizandoEmSegundoPlano
                  ? null
                  : _carregarDenuncias,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 21,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(
              right: 16,
            ),
            child: TextButton(
              onPressed: _processando
                  ? null
                  : () async {
                await Supabase
                    .instance
                    .client
                    .auth
                    .signOut();

                if (!context.mounted) {
                  return;
                }

                context.go('/login');
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    _radius,
                  ),
                ),
              ),
              child: const Text('Sair'),
            ),
          ),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              _buildCabecalho(),
              _buildPesquisa(),
              _buildFiltros(),
              const SizedBox(height: 4),
              Expanded(
                child: _buildConteudo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ==========================================================
// CABEÇALHO
// ==========================================================

  Widget _buildCabecalho() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        16,
        24,
        18,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Gerenciar denúncias',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _tituloFiltro(),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          if (!_carregando)
            _buildContador(),
        ],
      ),
    );
  }

// ==========================================================
// CONTADOR
// ==========================================================

  Widget _buildContador() {
    final total =
        _denunciasFiltradas.length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
        BorderRadius.circular(_radius),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Text(
        '$total '
            '${total == 1 ? 'denúncia' : 'denúncias'}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

// ==========================================================
// PESQUISA
// ==========================================================

  Widget _buildPesquisa() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: SearchBarWidget(
        onSearch: _executarPesquisa,
        hintText:
        'Pesquisar por obra, autor, denunciante ou motivo...',
      ),
    );
  }

// ==========================================================
// FILTROS
// ==========================================================

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        18,
        24,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius:
          BorderRadius.circular(_radius),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Wrap(
          spacing: 2,
          runSpacing: 2,
          children: [
            _buildFiltro(
              valor: 'pendente',
              titulo: 'Pendentes',
              icone: Icons.schedule_rounded,
            ),
            _buildFiltro(
              valor: 'em_analise',
              titulo: 'Em análise',
              icone: Icons.manage_search_rounded,
            ),
            _buildFiltro(
              valor: 'resolvida',
              titulo: 'Resolvidas',
              icone: Icons.check_rounded,
            ),
            _buildFiltro(
              valor: 'rejeitada',
              titulo: 'Rejeitadas',
              icone: Icons.close_rounded,
            ),
          ],
        ),
      ),
    );
  }

// ==========================================================
// FILTRO
// ==========================================================

  Widget _buildFiltro({
    required String valor,
    required String titulo,
    required IconData icone,
  }) {
    final selecionado =
        _filtro == valor;

    return TextButton(
      onPressed: _processando
          ? null
          : () => _alterarFiltro(valor),
      style: TextButton.styleFrom(
        backgroundColor: selecionado
            ? Colors.white
            : Colors.transparent,
        foregroundColor: selecionado
            ? Colors.black87
            : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(_radius),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icone,
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selecionado
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

// ==========================================================
// CONTEÚDO
// ==========================================================

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_erro != null) {
      return _buildEstadoErro();
    }

    if (_denunciasFiltradas.isEmpty) {
      return _buildEstadoVazio();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        24,
        20,
        24,
        30,
      ),
      itemCount:
      _denunciasDaPagina.length +
          (_totalPaginas > 1 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index <
            _denunciasDaPagina.length) {
          return _buildDenunciaCard(
            _denunciasDaPagina[index],
          );
        }

        return Padding(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 20,
          ),
          child: PaginacaoGoogleWidget(
            paginaAtual: _paginaAtual,
            totalPaginas: _totalPaginas,
            onPaginaAlterada: (pagina) {
              setState(() {
                _paginaAtual = pagina;
              });
            },
          ),
        );
      },
    );
  }

// ==========================================================
// ESTADO DE ERRO
// ==========================================================

  Widget _buildEstadoErro() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 460,
        ),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          borderRadius:
          BorderRadius.circular(_radius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 38,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 14),
            const Text(
              'Não foi possível carregar as denúncias',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _erro!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _carregarDenuncias,
              style: _buttonStyle(
                principal: true,
              ),
              child:
              const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

// ==========================================================
// ESTADO VAZIO
// ==========================================================

  Widget _buildEstadoVazio() {
    final pesquisando =
        _pesquisa.trim().isNotEmpty;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
              BorderRadius.circular(_radius),
            ),
            child: Icon(
              pesquisando
                  ? Icons.search_off_rounded
                  : Icons.inbox_outlined,
              size: 26,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            pesquisando
                ? 'Nenhuma denúncia encontrada'
                : 'Nenhuma denúncia nesta categoria',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pesquisando
                ? 'Tente pesquisar por outro termo.'
                : 'Não existem denúncias neste estado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

// ==========================================================
// CARD DENÚNCIA
// ==========================================================

  Widget _buildDenunciaCard(
      Map<String, dynamic> denuncia,
      ) {
    final obra =
    denuncia['obra']
    as Map<String, dynamic>?;

    final titulo =
        obra?['titulo']?.toString() ??
            'Obra não encontrada';

    final autor =
        obra?['autor']?.toString() ??
            'Autor não informado';

    final motivo =
        denuncia['motivo']?.toString() ??
            'Não informado';

    final descricao =
        denuncia['descricao']?.toString() ??
            '';

    final status =
        denuncia['status']?.toString() ??
            'pendente';

    final nomeUsuario =
    _nomeUsuario(denuncia);

    final podeAnalisar =
        status == 'pendente';

    final podeResolver =
        status == 'pendente' ||
            status == 'em_analise';

    final podeRejeitar =
        status == 'pendente' ||
            status == 'em_analise';

    final encerrada =
        status == 'resolvida' ||
            status == 'rejeitada';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
        BorderRadius.circular(_radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            // ==========================================
            // CABEÇALHO DO CARD
            // ==========================================

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                    BorderRadius.circular(
                      _radius,
                    ),
                  ),
                  child: const Icon(
                    Icons.report_outlined,
                    size: 21,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      _buildInfoItem(
                        label: 'Autor',
                        value: autor,
                      ),

                      _buildInfoItem(
                        label: 'Denunciante',
                        value: nomeUsuario,
                      ),

                      _buildInfoItem(
                        label: 'Motivo',
                        value: motivo,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                _buildStatusBadge(status),
              ],
            ),

            // ==========================================
            // DESCRIÇÃO
            // ==========================================

            if (descricao.trim().isNotEmpty) ...[
              const SizedBox(height: 14),

              Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),

              const SizedBox(height: 14),

              Text(
                'Descrição da denúncia',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                descricao,
                maxLines: 3,
                overflow:
                TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.grey.shade700,
                ),
              ),
            ],

            // ==========================================
            // AÇÕES
            // ==========================================

            const SizedBox(height: 16),

            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [

                  if (podeAnalisar)
                    OutlinedButton(
                      onPressed: _processando
                          ? null
                          : () =>
                          _analisarDenuncia(
                            denuncia,
                          ),
                      style: _buttonStyle(),
                      child:
                      const Text('Analisar'),
                    ),

                  if (status == 'em_analise')
                    OutlinedButton(
                      onPressed: _processando
                          ? null
                          : () =>
                          _abrirDetalhes(
                            denuncia,
                          ),
                      style: _buttonStyle(),
                      child:
                      const Text('Ver análise'),
                    ),

                  if (podeResolver)
                    ElevatedButton(
                      onPressed: _processando
                          ? null
                          : () =>
                          _abrirDetalhes(
                            denuncia,
                          ),
                      style: _buttonStyle(
                        principal: true,
                      ),
                      child:
                      const Text('Resolver'),
                    ),

                  if (podeRejeitar)
                    OutlinedButton(
                      onPressed: _processando
                          ? null
                          : () =>
                          _abrirDetalhes(
                            denuncia,
                          ),
                      style: _buttonStyle(),
                      child:
                      const Text('Rejeitar'),
                    ),

                  if (encerrada)
                    OutlinedButton(
                      onPressed: _processando
                          ? null
                          : () =>
                          _abrirDetalhes(
                            denuncia,
                          ),
                      style: _buttonStyle(),
                      child:
                      const Text('Ver detalhes'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// ==========================================================
// ANALISAR
// ==========================================================

  Future<void> _analisarDenuncia(
      Map<String, dynamic> denuncia,
      ) async {
    final id =
    denuncia['id']?.toString();

    if (id == null || id.isEmpty) {
      if (!mounted) return;

      await DialogMensagem.erro(
        context,
        titulo: 'Erro',
        mensagem:
        'ID da denúncia não encontrado.',
      );

      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      await _repository.atualizarStatus(
        denunciaId: id,
        status: 'em_analise',
      );

      final atualizada =
      await _repository
          .carregarDenunciaPorId(id);

      if (atualizada != null) {
        final indice =
        _denuncias.indexWhere(
              (item) =>
          item['id']?.toString() == id,
        );

        if (indice >= 0) {
          _denuncias[indice] =
              atualizada;
        } else {
          _denuncias.insert(
            0,
            atualizada,
          );
        }

        _aplicarFiltros();
      }

      if (!mounted) return;

      setState(() {
        _paginaAtual = 1;
      });

      await _abrirDetalhes(
        atualizada ?? denuncia,
      );
    } catch (e) {
      if (!mounted) return;

      await DialogMensagem.erro(
        context,
        titulo: 'Erro',
        mensagem: e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

// ==========================================================
// ABRIR DETALHES
// ==========================================================

  Future<void> _abrirDetalhes(
      Map<String, dynamic> denuncia,
      ) async {
    final obra =
    denuncia['obra']
    as Map<String, dynamic>?;

    final obraId =
        obra?['id']?.toString() ??
            denuncia['obra_id']?.toString() ??
            '';

    if (obraId.trim().isEmpty) {
      if (!mounted) return;

      await DialogMensagem.erro(
        context,
        titulo: 'Erro',
        mensagem:
        'ID da obra não encontrado.',
      );

      return;
    }

    final comprovantes =
    (denuncia['comprovantes']
    as List<dynamic>? ??
        [])
        .map<Map<String, dynamic>>(
          (item) =>
      Map<String, dynamic>.from(
        item as Map,
      ),
    )
        .toList();

    final idDenuncia =
        denuncia['id']?.toString() ??
            '';

    String? acaoSolicitada;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ObraDetalhesDialog(
          id: obraId,
          modoDenunciaAdmin: true,
          denuncianteNome:
          _nomeUsuario(denuncia),
          motivoDenuncia:
          denuncia['motivo']
              ?.toString() ??
              'Não informado',
          statusDenuncia:
          denuncia['status']
              ?.toString() ??
              'pendente',
          descricaoDenuncia:
          denuncia['descricao']
              ?.toString() ??
              '',
          comprovantes:
          comprovantes,
          onObterUrlComprovante:
              (caminho) async {
            return _repository
                .obterUrlComprovante(
              caminho,
            );
          },
          onResolver: () async {
            acaoSolicitada =
            'resolver';

            if (dialogContext.mounted) {
              Navigator.of(
                dialogContext,
              ).pop();
            }
          },
          onRejeitar: () async {
            acaoSolicitada =
            'rejeitar';

            if (dialogContext.mounted) {
              Navigator.of(
                dialogContext,
              ).pop();
            }
          },
        );
      },
    );

    if (!mounted ||
        acaoSolicitada == null) {
      return;
    }

    final confirmou =
    await _mostrarConfirmacaoAcao(
      acao: acaoSolicitada!,
    );

    if (!mounted || !confirmou) {
      return;
    }

    bool sucesso = false;

    setState(() {
      _processando = true;
    });

    try {
      if (acaoSolicitada ==
          'resolver') {
        sucesso =
        await _resolverDenuncia(
          idDenuncia,
        );
      } else if (acaoSolicitada ==
          'rejeitar') {
        sucesso =
        await _rejeitarDenuncia(
          idDenuncia,
        );
      }
    } catch (e) {
      if (mounted) {
        await DialogMensagem.erro(
          context,
          titulo: 'Erro',
          mensagem: e
              .toString()
              .replaceFirst(
            'Exception: ',
            '',
          ),
        );
      }

      return;
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }

    if (!mounted || !sucesso) {
      return;
    }

    await _carregarDenuncias();

    if (!mounted) return;

    if (acaoSolicitada ==
        'resolver') {
      await DialogMensagem.sucesso(
        context,
        titulo: 'Denúncia resolvida',
        mensagem:
        'A denúncia foi resolvida e '
            'a obra foi removida da '
            'publicação.',
      );
    } else {
      await DialogMensagem.sucesso(
        context,
        titulo: 'Denúncia rejeitada',
        mensagem:
        'A denúncia foi rejeitada. '
            'A obra permanece publicada.',
      );
    }
  }

// ==========================================================
// CONFIRMAÇÃO
// ==========================================================

  Future<bool> _mostrarConfirmacaoAcao({
    required String acao,
  }) async {
    final resolver =
        acao == 'resolver';

    final resultado =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              _radius,
            ),
          ),
          titlePadding:
          const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            0,
          ),
          contentPadding:
          const EdgeInsets.fromLTRB(
            24,
            16,
            24,
            0,
          ),
          actionsPadding:
          const EdgeInsets.fromLTRB(
            24,
            18,
            24,
            20,
          ),
          title: Text(
            resolver
                ? 'Confirmar resolução'
                : 'Confirmar rejeição',
            style: const TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.w600,
            ),
          ),
          content: Text(
            resolver
                ? 'Tem certeza que deseja '
                'resolver esta denúncia? '
                'A obra denunciada será '
                'removida da publicação e '
                'a denúncia será mantida '
                'no histórico administrativo.'
                : 'Tem certeza que deseja '
                'rejeitar esta denúncia? '
                'A denúncia será marcada '
                'como rejeitada e a obra '
                'continuará publicada.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              style:
              TextButton.styleFrom(
                backgroundColor:
                Colors.grey.shade100,
                foregroundColor:
                Colors.black87,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    _radius,
                  ),
                ),
              ),
              child:
              const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.black87,
                foregroundColor:
                Colors.white,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    _radius,
                  ),
                ),
              ),
              child: Text(
                resolver
                    ? 'Resolver'
                    : 'Rejeitar',
              ),
            ),
          ],
        );
      },
    );

    return resultado == true;
  }

// ==========================================================
// RESOLVER
// ==========================================================

  Future<bool> _resolverDenuncia(
      String id,
      ) async {
    try {
      await _repository.resolverDenuncia(
        id,
      );

      return true;
    } catch (e) {
      if (mounted) {
        await DialogMensagem.erro(
          context,
          titulo: 'Erro ao resolver',
          mensagem: e
              .toString()
              .replaceFirst(
            'Exception: ',
            '',
          ),
        );
      }

      return false;
    }
  }

// ==========================================================
// REJEITAR
// ==========================================================

  Future<bool> _rejeitarDenuncia(
      String id,
      ) async {
    try {
      await _repository.atualizarStatus(
        denunciaId: id,
        status: 'rejeitada',
      );

      return true;
    } catch (e) {
      if (mounted) {
        await DialogMensagem.erro(
          context,
          titulo: 'Erro ao rejeitar',
          mensagem: e
              .toString()
              .replaceFirst(
            'Exception: ',
            '',
          ),
        );
      }

      return false;
    }
  }
}
