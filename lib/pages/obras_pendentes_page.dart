import 'package:flutter/material.dart';

import '../../repositorios/obras_pendentes_repository.dart';

class ObrasPendentesPage extends StatefulWidget {
  const ObrasPendentesPage({
    super.key,
  });

  @override
  State<ObrasPendentesPage> createState() =>
      _ObrasPendentesPageState();
}

class _ObrasPendentesPageState
    extends State<ObrasPendentesPage> {
  final _repository =
      ObrasPendentesRepository.instancia;

  List<Map<String, dynamic>> _obras = [];

  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
    });

    try {
      final obras =
      await _repository.carregarObrasPendentes();

      if (!mounted) return;

      setState(() {
        _obras = obras;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  Future<void> _aprovar(
      Map<String, dynamic> obra,
      ) async {
    final id = obra['id']?.toString();

    if (id == null) return;

    final confirmar =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Aprovar obra',
          ),
          content: Text(
            'Deseja aprovar a obra '
                '"${obra['titulo']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Aprovar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _repository.aprovarObra(id);

      if (!mounted) return;

      _mensagem(
        'Obra aprovada com sucesso.',
      );

      await _carregar();
    } catch (e) {
      if (!mounted) return;

      _mensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  Future<void> _rejeitar(
      Map<String, dynamic> obra,
      ) async {
    final id = obra['id']?.toString();

    if (id == null) return;

    final controller =
    TextEditingController();

    final motivo =
    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Rejeitar obra',
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration:
            const InputDecoration(
              labelText:
              'Motivo da rejeição',
              hintText:
              'Informe o motivo...',
              border:
              OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final texto =
                controller.text.trim();

                if (texto.isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  texto,
                );
              },
              child: const Text(
                'Rejeitar',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (motivo == null ||
        motivo.trim().isEmpty) {
      return;
    }

    try {
      await _repository.rejeitarObra(
        id: id,
        motivo: motivo,
      );

      if (!mounted) return;

      _mensagem(
        'Obra rejeitada.',
      );

      await _carregar();
    } catch (e) {
      if (!mounted) return;

      _mensagem(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Obras pendentes',
        ),
        actions: [
          IconButton(
            onPressed: _carregando
                ? null
                : _carregar,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: _carregando
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _obras.isEmpty
          ? const Center(
        child: Text(
          'Não existem obras pendentes.',
        ),
      )
          : ListView.separated(
        padding:
        const EdgeInsets.all(20),
        itemCount: _obras.length,
        separatorBuilder:
            (_, __) =>
        const SizedBox(
          height: 12,
        ),
        itemBuilder:
            (context, index) {
          final obra =
          _obras[index];

          return Card(
            child: Padding(
              padding:
              const EdgeInsets.all(
                18,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    obra['titulo']
                        ?.toString() ??
                        '',
                    style:
                    const TextStyle(
                      fontSize: 19,
                      fontWeight:
                      FontWeight
                          .bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'Autor: ${obra['autor'] ?? ''}',
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    'Categoria: '
                        '${obra['categoria'] ?? ''}',
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    'Área: '
                        '${obra['area'] ?? ''}',
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  Row(
                    children: [
                      ElevatedButton
                          .icon(
                        onPressed:
                            () => _aprovar(
                          obra,
                        ),
                        icon:
                        const Icon(
                          Icons
                              .check_circle,
                        ),
                        label:
                        const Text(
                          'Aprovar',
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      OutlinedButton
                          .icon(
                        onPressed:
                            () => _rejeitar(
                          obra,
                        ),
                        icon:
                        const Icon(
                          Icons
                              .cancel,
                        ),
                        label:
                        const Text(
                          'Rejeitar',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
