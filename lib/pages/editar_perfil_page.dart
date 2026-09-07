import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() =>
      _EditarPerfilPageState();
}

class _EditarPerfilPageState
    extends State<EditarPerfilPage> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final TextEditingController _nomeController =
  TextEditingController();

  bool _carregando = true;
  bool _salvando = false;

  String _email = '';

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  // ==========================================================
  // CARREGAR PERFIL
  // ==========================================================

  void _carregarPerfil() {
    final usuario =
        _supabase.auth.currentUser;

    if (usuario == null) {
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    final metadata = usuario.userMetadata;

    String nome = '';

    final nomeCompleto =
    metadata?['nome_completo']?.toString();

    final nomeGoogle =
    metadata?['full_name']?.toString();

    final nomeUsuario =
    metadata?['name']?.toString();

    if (nomeCompleto != null &&
        nomeCompleto.trim().isNotEmpty) {
      nome = nomeCompleto.trim();
    } else if (nomeGoogle != null &&
        nomeGoogle.trim().isNotEmpty) {
      nome = nomeGoogle.trim();
    } else if (nomeUsuario != null &&
        nomeUsuario.trim().isNotEmpty) {
      nome = nomeUsuario.trim();
    }

    _nomeController.text = nome;
    _email = usuario.email ?? '';

    if (mounted) {
      setState(() {
        _carregando = false;
      });
    }
  }

  // ==========================================================
  // GUARDAR
  // ==========================================================

  Future<void> _guardarAlteracoes() async {
    if (_salvando) {
      return;
    }

    final nome =
    _nomeController.text.trim();

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Digite o seu nome.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'nome_completo': nome,
          },
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Perfil atualizado com sucesso.',
          ),
        ),
      );

      context.pop(true);
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _salvando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(e.message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _salvando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: const Text(
            'Não foi possível atualizar o perfil.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: _salvando
              ? null
              : () => context.pop(),
        ),

        title: const Text(
          'Editar perfil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
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
      ),

      body: _carregando
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding:
        const EdgeInsets.fromLTRB(
          24,
          36,
          24,
          50,
        ),

        child: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 700,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // ========================================
                // CABEÇALHO
                // ========================================

                const Text(
                  'Informações do perfil',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Atualize as informações que serão utilizadas na sua conta Obra Livre.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color:
                    Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 40),

                // ========================================
                // NOME
                // ========================================

                const Text(
                  'Nome completo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 9),

                TextField(
                  controller:
                  _nomeController,
                  textInputAction:
                  TextInputAction.done,
                  enabled: !_salvando,

                  decoration:
                  InputDecoration(
                    hintText:
                    'Digite o seu nome',
                    border:
                    const OutlineInputBorder(),
                    enabledBorder:
                    OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                        Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder:
                    OutlineInputBorder(
                      borderSide:
                      BorderSide(
                        color: Theme.of(
                          context,
                        )
                            .colorScheme
                            .primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ========================================
                // EMAIL
                // ========================================

                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 9),

                TextField(
                  controller:
                  TextEditingController(
                    text: _email,
                  ),
                  enabled: false,

                  decoration:
                  InputDecoration(
                    border:
                    const OutlineInputBorder(),
                    disabledBorder:
                    OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                        Colors.grey.shade200,
                      ),
                    ),
                    filled: true,
                    fillColor:
                    Colors.grey.shade50,
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'O endereço de email não pode ser alterado nesta área.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Colors.grey.shade500,
                  ),
                ),

                const SizedBox(height: 42),

                // ========================================
                // BOTÕES
                // ========================================

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _salvando
                          ? null
                          : () =>
                          context.pop(),
                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    const SizedBox(width: 12),

                    FilledButton(
                      onPressed: _salvando
                          ? null
                          : _guardarAlteracoes,

                      child: Padding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 8,
                        ),

                        child: _salvando
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                            Colors.white,
                          ),
                        )
                            : const Text(
                          'Guardar alterações',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 55),

                const Divider(),

                const SizedBox(height: 18),

                Center(
                  child: Text(
                    'Obra Livre • Ajuda • Termos • Privacidade',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
