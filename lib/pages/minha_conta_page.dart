import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../cache/minha_conta_cache.dart';
import '../dados/obras_recentes.dart';
import '../repositorios/denuncias_repository.dart';
import '../repositorios/solicitacoes_remocao_repository.dart';
import '../widgets/cartao_obra_widget.dart';

// ==========================================================
// MINHA CONTA PAGE
// ==========================================================
class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({
    super.key,
  });

  @override
  State<MinhaContaPage> createState() =>
      _MinhaContaPageState();
}

class _MinhaContaPageState
    extends State<MinhaContaPage> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final DenunciasRepository
  _denunciasRepository =
      DenunciasRepository.instancia;

  final SolicitacoesRemocaoRepository
  _solicitacoesRepository =
      SolicitacoesRemocaoRepository.instancia;

  final MinhaContaCache _cache =
      MinhaContaCache.instancia;

  String _nomeUsuario = 'Usuário';
  String _emailUsuario = '';

  bool _carregando = true;
  bool _atualizando = false;
  bool _saindo = false;

  int _pendentes = 0;
  int _publicadas = 0;
  int _recusadas = 0;
  int _totalObras = 0;

  // ========================================================
  // OBRAS PUBLICADAS
  // ========================================================
  List<ObraRecente> _obrasPublicadas = [];

  // ========================================================
  // CONTROLE DO MENU
  // ========================================================
  bool _dadosContaSelecionados = false;

  // ========================================================
  // DENÚNCIAS
  // ========================================================
  int _denunciasPendentes = 0;

  // ========================================================
  // SOLICITAÇÕES
  // ========================================================
  int _solicitacoesPendentes = 0;

  // ========================================================
  // INIT
  // ========================================================
  @override
  void initState() {
    super.initState();

    _carregarDadosUsuario();
  }

  // ========================================================
  // CARREGAR DADOS DO UTILIZADOR
  // ========================================================
  Future<void> _carregarDadosUsuario() async {
    final usuario =
        _supabase.auth.currentUser;

    if (usuario == null) {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }

      return;
    }

    _emailUsuario =
        usuario.email ?? '';

    _obterNomeUsuario(usuario);

    // ======================================================
    // PRIMEIRO: CACHE
    // ======================================================
    try {
      final dadosCache =
      await _cache.carregarDados();

      if (dadosCache != null &&
          mounted) {
        _aplicarDadosCache(
          dadosCache,
        );

        setState(() {
          _carregando = false;
        });
      }
    } catch (_) {
      // Cache não impede o funcionamento.
    }

    // ======================================================
    // SEGUNDO: SUPABASE
    // ======================================================
    await _atualizarDadosSupabase();
  }

  // ========================================================
  // APLICAR CACHE
  // ========================================================
  void _aplicarDadosCache(
      Map<String, dynamic> dados,
      ) {
    _nomeUsuario =
        dados['nome_usuario']
            ?.toString() ??
            _nomeUsuario;

    _emailUsuario =
        dados['email_usuario']
            ?.toString() ??
            _emailUsuario;

    _pendentes =
        _converterParaInt(
          dados['pendentes'],
        );

    _publicadas =
        _converterParaInt(
          dados['publicadas'],
        );

    _recusadas =
        _converterParaInt(
          dados['recusadas'],
        );

    _totalObras =
        _converterParaInt(
          dados['total_obras'],
        );

    _denunciasPendentes =
        _converterParaInt(
          dados['denuncias_pendentes'],
        );

    _solicitacoesPendentes =
        _converterParaInt(
          dados['solicitacoes_pendentes'],
        );
  }

  // ========================================================
  // CONVERTER INT
  // ========================================================
  int _converterParaInt(
      dynamic valor,
      ) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse(
      valor?.toString() ?? '',
    ) ??
        0;
  }

  // ========================================================
  // RECARREGAR
  // ========================================================
  Future<void> _recarregarDados() async {
    await _atualizarDadosSupabase(
      mostrarCarregamento: false,
    );
  }

  // ========================================================
  // ATUALIZAR SUPABASE
  // ========================================================
  Future<void> _atualizarDadosSupabase({
    bool mostrarCarregamento = true,
  }) async {
    if (_atualizando) {
      return;
    }

    final usuario =
        _supabase.auth.currentUser;

    if (usuario == null) {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }

      return;
    }

    _atualizando = true;

    if (mostrarCarregamento &&
        mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      await _carregarDadosPublicacoes();

      await _carregarDadosDenuncias(
        atualizarCache: false,
      );

      await _carregarDadosSolicitacoes(
        atualizarCache: false,
      );

      await _salvarCache();

      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _carregando = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            backgroundColor:
            Colors.red.shade700,
            content: Text(
              'Erro ao atualizar dados: ${e.message}',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _carregando = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Não foi possível atualizar os dados da conta.',
            ),
          ),
        );
      }
    } finally {
      _atualizando = false;
    }
  }

  // ========================================================
  // SALVAR CACHE
  // ========================================================
  Future<void> _salvarCache() async {
    try {
      await _cache.salvarDados(
        nomeUsuario: _nomeUsuario,
        emailUsuario: _emailUsuario,
        pendentes: _pendentes,
        publicadas: _publicadas,
        recusadas: _recusadas,
        totalObras: _totalObras,
        denunciasPendentes:
        _denunciasPendentes,
        solicitacoesPendentes:
        _solicitacoesPendentes,
      );
    } catch (_) {
      // Cache não impede o funcionamento.
    }
  }

  // ========================================================
  // NOME
  // ========================================================
  void _obterNomeUsuario(
      User usuario,
      ) {
    final metadata =
        usuario.userMetadata;

    final nomeCompleto =
    metadata?['nome_completo']
        ?.toString();

    if (nomeCompleto != null &&
        nomeCompleto.trim().isNotEmpty) {
      _nomeUsuario =
          nomeCompleto.trim();

      return;
    }

    final nomeGoogle =
    metadata?['full_name']
        ?.toString();

    if (nomeGoogle != null &&
        nomeGoogle.trim().isNotEmpty) {
      _nomeUsuario =
          nomeGoogle.trim();

      return;
    }

    final nome =
    metadata?['name']?.toString();

    if (nome != null &&
        nome.trim().isNotEmpty) {
      _nomeUsuario =
          nome.trim();
    }
  }

  // ========================================================
  // PUBLICAÇÕES
  // ========================================================
  Future<void> _carregarDadosPublicacoes() async {
    final usuario =
        _supabase.auth.currentUser;

    if (usuario == null) {
      return;
    }

    // ======================================================
    // PUBLICADAS
    // ======================================================
    final respostaPublicadas =
    await _supabase
        .from('obras')
        .select(
      'id, titulo, descricao, autor, coautores, '
          'categoria, url_documento, status, '
          'data_publicacao, ano_obra',
    )
        .eq(
      'user_id',
      usuario.id,
    )
        .order(
      'data_publicacao',
      ascending: false,
    );

    // ======================================================
    // PENDENTES / RECUSADAS
    // ======================================================
    final respostaPendentes =
    await _supabase
        .from('obras_pendentes')
        .select(
      'id, titulo, autor, categoria, '
          'status, data_envio, data_analise, '
          'motivo_rejeicao',
    )
        .eq(
      'user_id',
      usuario.id,
    )
        .order(
      'data_envio',
      ascending: false,
    );

    int pendentes = 0;
    int publicadas = 0;
    int recusadas = 0;

    final List<ObraRecente>
    obrasPublicadas = [];

    // ======================================================
    // PUBLICADAS
    // ======================================================
    for (final item
    in respostaPublicadas) {
      final obra =
      Map<String, dynamic>.from(
        item,
      );

      final status =
      _normalizarStatus(
        obra['status']?.toString(),
      );

      if (status == 'publicada') {
        publicadas++;

        obrasPublicadas.add(
          ObraRecente(
            id: obra['id']
                ?.toString() ??
                '',
            titulo:
            obra['titulo']
                ?.toString() ??
                '',
            resumo:
            obra['descricao']
                ?.toString() ??
                '',
            autor:
            obra['autor']
                ?.toString() ??
                '',
            coautores:
            obra['coautores']
                ?.toString() ??
                '',
            categoria:
            obra['categoria']
                ?.toString() ??
                '',
            urlDocumento:
            obra['url_documento']
                ?.toString() ??
                '',
            dataPublicacao:
            obra['data_publicacao']
                ?.toString() ??
                '',
            status:
            obra['status']
                ?.toString() ??
                '',
            anoObra:
            _converterAno(
              obra['ano_obra'],
            ),
          ),
        );
      }
    }

    // ======================================================
    // PENDENTES / RECUSADAS
    // ======================================================
    for (final item
    in respostaPendentes) {
      final obra =
      Map<String, dynamic>.from(
        item,
      );

      final status =
      _normalizarStatus(
        obra['status']?.toString(),
      );

      if (status == 'pendente') {
        pendentes++;
      } else if (status == 'recusada') {
        recusadas++;
      }
    }

    // ======================================================
    // TOTAL
    // ======================================================
    final total =
        publicadas +
            pendentes +
            recusadas;

    if (!mounted) {
      return;
    }

    setState(() {
      _pendentes = pendentes;
      _publicadas = publicadas;
      _recusadas = recusadas;
      _totalObras = total;

      _obrasPublicadas =
          obrasPublicadas;

      _carregando = false;
    });
  }

  // ========================================================
  // CONVERTER ANO
  // ========================================================
  int? _converterAno(
      dynamic valor,
      ) {
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

  // ========================================================
  // DENÚNCIAS
  // ========================================================
  Future<void> _carregarDadosDenuncias({
    bool atualizarCache = true,
  }) async {
    try {
      final resultado =
      await _denunciasRepository
          .contarMinhasDenunciasPorStatus();

      if (!mounted) {
        return;
      }

      setState(() {
        _denunciasPendentes =
            resultado['pendente'] ?? 0;
      });

      if (atualizarCache) {
        await _salvarCache();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _denunciasPendentes = 0;
      });
    }
  }

  // ========================================================
  // SOLICITAÇÕES
  // ========================================================
  Future<void> _carregarDadosSolicitacoes({
    bool atualizarCache = true,
  }) async {
    try {
      final resultado =
      await _solicitacoesRepository
          .contarMinhasSolicitacoesPorStatus();

      if (!mounted) {
        return;
      }

      setState(() {
        _solicitacoesPendentes =
            resultado['pendente'] ?? 0;
      });

      if (atualizarCache) {
        await _salvarCache();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _solicitacoesPendentes = 0;
      });
    }
  }

  // ========================================================
  // NORMALIZAR STATUS
  // ========================================================
  String _normalizarStatus(
      String? valor,
      ) {
    final status =
        valor?.toLowerCase().trim() ?? '';

    switch (status) {
      case 'pendente':
      case 'pendentes':
        return 'pendente';

      case 'recusada':
      case 'recusado':
      case 'rejeitada':
      case 'rejeitado':
        return 'recusada';

      case 'aprovada':
      case 'aprovado':
      case 'publicada':
      case 'publicado':
        return 'publicada';

      default:
        return status;
    }
  }

  // ========================================================
  // SAIR
  // ========================================================
  Future<void> _sair() async {
    if (_saindo) {
      return;
    }

    setState(() {
      _saindo = true;
    });

    try {
      await _supabase.auth.signOut();

      if (!mounted) {
        return;
      }

      context.go('/login');
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saindo = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
          Colors.red.shade700,
          content: Text(e.message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saindo = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Não foi possível sair da conta.',
          ),
        ),
      );
    }
  }

  // ========================================================
  // DADOS DA CONTA
  // ========================================================
  void _abrirDadosConta() {
    if (_saindo) {
      return;
    }

    setState(() {
      _dadosContaSelecionados = true;
    });
  }

  // ========================================================
  // ACERVO
  // ========================================================
  void _abrirAcervo() {
    if (_saindo) {
      return;
    }

    setState(() {
      _dadosContaSelecionados = false;
    });

    context.push('/acervo');
  }

  // ========================================================
  // PUBLICAÇÕES
  // ========================================================
  Future<void> _abrirPublicacoes() async {
    if (_saindo) {
      return;
    }

    // ======================================================
    // ABRE A PÁGINA DE PUBLICAÇÕES
    // ======================================================
    await context.push(
      '/publicacoes',
    );

    // ======================================================
    // AO VOLTAR, ATUALIZA OS CONTADORES
    // ======================================================
    if (!mounted) {
      return;
    }

    await _recarregarDados();
  }

  // ========================================================
  // PUBLICAR
  // ========================================================
  void _abrirPublicar() {
    if (_saindo) {
      return;
    }

    setState(() {
      _dadosContaSelecionados = false;
    });

    context.push('/publicar');
  }

  // ========================================================
  // PUBLICAÇÕES COM FILTRO
  // ========================================================
  Future<void> _abrirPublicacoesComFiltro(
      String status,
      ) async {
    if (_saindo) {
      return;
    }

    await context.push(
      '/publicacoes?status=${Uri.encodeComponent(status)}',
    );

    if (!mounted) {
      return;
    }

    await _recarregarDados();
  }

  // ========================================================
  // DENÚNCIAS
  // ========================================================
  Future<void> _abrirDenuncias() async {
    if (_saindo) {
      return;
    }

    setState(() {
      _dadosContaSelecionados = false;
    });

    await context.push('/denuncias');

    if (!mounted) {
      return;
    }

    await _carregarDadosDenuncias();
    await _salvarCache();
  }

  // ========================================================
  // REMOÇÕES
  // ========================================================
  Future<void> _abrirRemocoes() async {
    if (_saindo) {
      return;
    }

    setState(() {
      _dadosContaSelecionados = false;
    });

    await context.push(
      '/solicitacoes-remocao',
    );

    if (!mounted) {
      return;
    }

    await _carregarDadosSolicitacoes();
    await _salvarCache();
  }

  // ========================================================
  // EDITAR PERFIL
  // ========================================================
  Future<void> _editarPerfil() async {
    if (_saindo) {
      return;
    }

    final resultado =
    await context.push<bool>(
      '/editar-perfil',
    );

    if (resultado == true &&
        mounted) {
      final usuario =
          _supabase.auth.currentUser;

      if (usuario != null) {
        setState(() {
          _emailUsuario =
              usuario.email ?? '';

          _obterNomeUsuario(usuario);
        });

        await _salvarCache();
      }
    }
  }

  // ========================================================
  // BUILD
  // ========================================================
  @override
  Widget build(
      BuildContext context,
      ) {
    final primaryColor =
        Theme.of(context)
            .colorScheme
            .primary;

    return Scaffold(
      backgroundColor: Colors.white,

      // ====================================================
      // APP BAR
      // ====================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        title: const Text(
          'Minha Conta',
          style: TextStyle(
            fontWeight:
            FontWeight.w600,
            fontSize: 20,
          ),
        ),

        bottom: PreferredSize(
          preferredSize:
          const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),

        actions: [
          TextButton(
            onPressed: _saindo
                ? null
                : _abrirAcervo,
            child: const Text(
              'Acervo',
              style: TextStyle(
                fontWeight:
                FontWeight.normal,
              ),
            ),
          ),

          TextButton(
            onPressed: _saindo
                ? null
                : _abrirPublicar,
            child: const Text(
              'Publicar',
              style: TextStyle(
                fontWeight:
                FontWeight.normal,
              ),
            ),
          ),

          Padding(
            padding:
            const EdgeInsets.only(
              right: 18,
            ),
            child: TextButton(
              onPressed: _saindo
                  ? null
                  : _sair,
              child: Text(
                _saindo
                    ? 'A sair...'
                    : 'Sair',
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),

      // ====================================================
      // BODY
      // ====================================================
      body: RefreshIndicator(
        onRefresh: _recarregarDados,

        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.fromLTRB(
            24,
            30,
            24,
            50,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 1100,
              ),

              child: LayoutBuilder(
                builder: (
                    context,
                    constraints,
                    ) {
                  final largura =
                      constraints.maxWidth;

                  // ========================================
                  // MOBILE
                  // ========================================
                  if (largura < 750) {
                    return Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [
                        _menuLateral(
                          primaryColor,
                        ),

                        const SizedBox(
                          height: 42,
                        ),

                        _conteudoPrincipal(),
                      ],
                    );
                  }

                  // ========================================
                  // DESKTOP / WEB
                  // ========================================
                  return Row(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [
                      SizedBox(
                        width: 230,
                        child:
                        _menuLateral(
                          primaryColor,
                        ),
                      ),

                      const SizedBox(
                        width: 70,
                      ),

                      Expanded(
                        child:
                        _conteudoPrincipal(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // MENU LATERAL
  // ========================================================
  Widget _menuLateral(
      Color primaryColor,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        const Text(
          'Conta',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        _itemMenu(
          titulo: 'Dados da conta',
          icone:
          Icons.person_outline,
          selecionado:
          _dadosContaSelecionados,
          primaryColor:
          primaryColor,
          onTap:
          _abrirDadosConta,
        ),

        const SizedBox(height: 30),

        const Text(
          'Publicações',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        _itemStatus(
          titulo:
          'Minhas publicações',
          valor: _publicadas,
          primaryColor:
          primaryColor,
          cor:
          Colors.green.shade700,
          onTap:
          _abrirPublicacoes,
        ),

        if (_pendentes > 0)
          _itemStatus(
            titulo: 'Pendente',
            valor: _pendentes,
            primaryColor:
            primaryColor,
            cor:
            Colors.orange.shade700,
            onTap: () =>
                _abrirPublicacoesComFiltro(
                  'pendente',
                ),
          ),

        if (_recusadas > 0)
          _itemStatus(
            titulo: 'Recusada',
            valor: _recusadas,
            primaryColor:
            primaryColor,
            cor:
            Colors.red.shade700,
            onTap: () =>
                _abrirPublicacoesComFiltro(
                  'recusada',
                ),
          ),

        const SizedBox(height: 30),

        const Text(
          'Denúncias',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        _itemMenu(
          titulo:
          'Minhas denúncias',
          icone:
          Icons.report_problem_outlined,
          selecionado: false,
          primaryColor:
          primaryColor,
          onTap:
          _abrirDenuncias,
        ),

        if (_denunciasPendentes > 0)
          _itemStatus(
            titulo: 'Pendente',
            valor:
            _denunciasPendentes,
            primaryColor:
            primaryColor,
            cor:
            Colors.orange.shade700,
            onTap:
            _abrirDenuncias,
          ),

        const SizedBox(height: 30),

        const Text(
          'Remoções',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        _itemMenu(
          titulo:
          'Minhas solicitações',
          icone:
          Icons.delete_outline,
          selecionado: false,
          primaryColor:
          primaryColor,
          onTap:
          _abrirRemocoes,
        ),

        if (_solicitacoesPendentes > 0)
          _itemStatus(
            titulo: 'Pendente',
            valor:
            _solicitacoesPendentes,
            primaryColor:
            primaryColor,
            cor:
            Colors.orange.shade700,
            onTap:
            _abrirRemocoes,
          ),
      ],
    );
  }

  // ========================================================
  // ITEM STATUS
  // ========================================================
  Widget _itemStatus({
    required String titulo,
    required int valor,
    required Color primaryColor,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap:
      _saindo ? null : onTap,

      borderRadius:
      BorderRadius.circular(6),

      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 8,
        ),

        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,

              decoration:
              BoxDecoration(
                color: cor,
                shape:
                BoxShape.circle,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Text(
                '$titulo ($valor)',
                style: TextStyle(
                  fontSize: 14,
                  color:
                  Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // ITEM MENU
  // ========================================================
  Widget _itemMenu({
    required String titulo,
    required IconData icone,
    required bool selecionado,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selecionado
          ? primaryColor.withValues(
        alpha: 0.08,
      )
          : Colors.transparent,

      borderRadius:
      BorderRadius.circular(6),

      child: InkWell(
        onTap:
        _saindo ? null : onTap,

        borderRadius:
        BorderRadius.circular(6),

        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),

          child: Row(
            children: [
              Icon(
                icone,
                size: 20,
                color: selecionado
                    ? primaryColor
                    : Colors.grey.shade700,
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selecionado
                        ? FontWeight.w500
                        : FontWeight.normal,
                    color: selecionado
                        ? primaryColor
                        : Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // CONTEÚDO PRINCIPAL
  // ========================================================
  Widget _conteudoPrincipal() {
    if (_dadosContaSelecionados) {
      return _conteudoDadosConta();
    }

    return _conteudoPublicacoes();
  }

  // ========================================================
  // CONTEÚDO DAS PUBLICAÇÕES
  // ========================================================
  Widget _conteudoPublicacoes() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        const Text(
          'Publicações',
          style: TextStyle(
            fontSize: 23,
            fontWeight:
            FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Obras publicadas mais recentemente.',
          style: TextStyle(
            fontSize: 15,
            color:
            Colors.grey.shade600,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 32),

        if (_carregando &&
            _obrasPublicadas.isEmpty)
          _estadoCarregamento()
        else if (_obrasPublicadas.isEmpty)
          _estadoPublicacoesVazio()
        else
          _listaObrasPublicadas(),
      ],
    );
  }

  // ========================================================
  // LISTA DAS OBRAS PUBLICADAS
  // ========================================================
  Widget _listaObrasPublicadas() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        for (final obra
        in _obrasPublicadas)
          Padding(
            padding:
            const EdgeInsets.only(
              bottom: 18,
            ),

            child:
            CartaoObraWidget(
              obra: obra,
            ),
          ),
      ],
    );
  }

  // ========================================================
  // PUBLICAÇÕES VAZIAS
  // ========================================================
  Widget _estadoPublicacoesVazio() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.symmetric(
        vertical: 28,
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 34,
            color:
            Colors.grey.shade400,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            'Ainda não existem publicações.',
            style: TextStyle(
              fontSize: 15,
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // DADOS DA CONTA
  // ========================================================
  Widget _conteudoDadosConta() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Text(
          'Olá, $_nomeUsuario',
          style: TextStyle(
            fontSize: 23,
            fontWeight:
            FontWeight.w500,
            color:
            Colors.grey.shade900,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Gerencie as informações da sua conta na Obra Livre.',
          style: TextStyle(
            fontSize: 15,
            color:
            Colors.grey.shade600,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 42),

        const Text(
          'Dados da conta',
          style: TextStyle(
            fontSize: 19,
            fontWeight:
            FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Informações associadas à sua conta.',
          style: TextStyle(
            fontSize: 14,
            color:
            Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 20),

        _linhaConta(
          titulo: 'Nome',
          valor: _nomeUsuario,
        ),

        const Divider(
          height: 1,
        ),

        _linhaConta(
          titulo: 'Email',
          valor: _emailUsuario.isNotEmpty
              ? _emailUsuario
              : 'Não disponível',
        ),

        const Divider(
          height: 1,
        ),

        _linhaConta(
          titulo: 'Estado',
          valor: 'Conta ativa',
        ),

        const SizedBox(height: 22),

        OutlinedButton(
          onPressed:
          _saindo
              ? null
              : _editarPerfil,

          style:
          OutlinedButton.styleFrom(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 13,
            ),

            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(6),
            ),
          ),

          child: const Text(
            'Editar perfil',
          ),
        ),
      ],
    );
  }

  // ========================================================
  // CARREGAMENTO
  // ========================================================
  Widget _estadoCarregamento() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 20,
      ),

      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,

            child:
            CircularProgressIndicator(
              strokeWidth: 2,
              color:
              Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Text(
            'A carregar...',
            style: TextStyle(
              fontSize: 14,
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // LINHA CONTA
  // ========================================================
  Widget _linhaConta({
    required String titulo,
    required String valor,
  }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 17,
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 110,

            child: Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                color:
                Colors.grey.shade600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              valor,
              style:
              const TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


