import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoricoConsulta {
  final String obraId;
  final DateTime consultadoEm;

  HistoricoConsulta({
    required this.obraId,
    required this.consultadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'obra_id': obraId,
      'consultado_em': consultadoEm.toIso8601String(),
    };
  }

  factory HistoricoConsulta.fromMap(Map<String, dynamic> map) {
    return HistoricoConsulta(
      obraId: map['obra_id']?.toString() ?? '',
      consultadoEm:
      DateTime.tryParse(map['consultado_em']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class HistoricoConsultasRepository extends ChangeNotifier {
  HistoricoConsultasRepository._();

  static final HistoricoConsultasRepository instancia =
  HistoricoConsultasRepository._();

  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _boxName = 'historico_consultas_local';
  static const String _keyHistorico = 'consultas';

  Box<dynamic>? _box;
  bool _inicializado = false;

  List<HistoricoConsulta> _historico = [];

  List<HistoricoConsulta> get historico =>
      List.unmodifiable(_historico);

  Future<Box<dynamic>> _obterBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }

    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<dynamic>(_boxName);
    } else {
      _box = await Hive.openBox<dynamic>(_boxName);
    }

    return _box!;
  }

  Future<void> inicializar() async {
    if (_inicializado) {
      return;
    }

    try {
      final box = await _obterBox();

      await _carregarHistoricoLocal(box);

      _inicializado = true;

      final usuario = _supabase.auth.currentUser;

      if (usuario != null) {
        await sincronizarHistoricoLocal();
      }

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Erro ao inicializar histórico de consultas: $e',
      );
    }
  }

  Future<void> _carregarHistoricoLocal(
      Box<dynamic> box,
      ) async {
    try {
      final valor = box.get(_keyHistorico);

      if (valor == null) {
        _historico = [];
        return;
      }

      List<dynamic> lista;

      if (valor is String) {
        final decodificado = jsonDecode(valor);

        if (decodificado is List) {
          lista = decodificado;
        } else {
          lista = [];
        }
      } else if (valor is List) {
        lista = valor;
      } else {
        lista = [];
      }

      _historico = lista
          .whereType<Map>()
          .map(
            (item) => HistoricoConsulta.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .where((item) => item.obraId.isNotEmpty)
          .toList();

      _ordenarHistorico();
    } catch (e) {
      debugPrint(
        'Erro ao carregar histórico local: $e',
      );

      _historico = [];
    }
  }

  Future<void> _salvarHistoricoLocal() async {
    try {
      final box = await _obterBox();

      final lista = _historico
          .map((item) => item.toMap())
          .toList();

      await box.put(
        _keyHistorico,
        jsonEncode(lista),
      );
    } catch (e) {
      debugPrint(
        'Erro ao salvar histórico local: $e',
      );
    }
  }

  void _ordenarHistorico() {
    _historico.sort(
          (a, b) => b.consultadoEm.compareTo(
        a.consultadoEm,
      ),
    );
  }

  Future<void> registrarConsulta(
      String obraId,
      ) async {
    if (obraId.trim().isEmpty) {
      return;
    }

    if (!_inicializado) {
      await inicializar();
    }

    final id = obraId.trim();

    final agora = DateTime.now();

    final existenteIndex = _historico.indexWhere(
          (item) => item.obraId == id,
    );

    if (existenteIndex >= 0) {
      _historico.removeAt(existenteIndex);
    }

    _historico.insert(
      0,
      HistoricoConsulta(
        obraId: id,
        consultadoEm: agora,
      ),
    );

    // Mantém somente os últimos 20 registros.
    if (_historico.length > 20) {
      _historico = _historico.take(20).toList();
    }

    await _salvarHistoricoLocal();

    notifyListeners();

    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      return;
    }

    await _registrarNoSupabase(
      usuario.id,
      id,
      agora,
    );
  }

  Future<void> _registrarNoSupabase(
      String usuarioId,
      String obraId,
      DateTime data,
      ) async {
    try {
      await _supabase.from('historico_consultas').upsert(
        {
          'usuario_id': usuarioId,
          'obra_id': obraId,
          'consultado_em': data.toIso8601String(),
        },
        onConflict: 'usuario_id,obra_id',
      );
    } catch (e) {
      debugPrint(
        'Erro ao registrar consulta no Supabase: $e',
      );

      // O registro já foi salvo localmente.
    }
  }

  Future<List<HistoricoConsulta>> carregarHistorico() async {
    if (!_inicializado) {
      await inicializar();
    }

    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      return List.unmodifiable(_historico);
    }

    try {
      final resposta = await _supabase
          .from('historico_consultas')
          .select('obra_id, consultado_em')
          .eq('usuario_id', usuario.id)
          .order('consultado_em', ascending: false)
          .limit(20);

      final lista = (resposta as List)
          .whereType<Map>()
          .map(
            (item) => HistoricoConsulta.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .where((item) => item.obraId.isNotEmpty)
          .toList();

      if (lista.isNotEmpty) {
        _historico = lista;

        await _salvarHistoricoLocal();

        notifyListeners();
      }

      return List.unmodifiable(_historico);
    } catch (e) {
      debugPrint(
        'Erro ao carregar histórico do Supabase: $e',
      );

      return List.unmodifiable(_historico);
    }
  }

  Future<List<Map<String, dynamic>>> carregarObrasConsultadas({
    int quantidade = 6,
  }) async {
    if (!_inicializado) {
      await inicializar();
    }

    final historico = await carregarHistorico();

    if (historico.isEmpty) {
      return [];
    }

    final ids = historico
        .map((item) => item.obraId)
        .where((id) => id.isNotEmpty)
        .toList();

    if (ids.isEmpty) {
      return [];
    }

    try {
      final resposta = await _supabase
          .from('obras')
          .select(
        'id,titulo,descricao,autor,categoria,'
            'url_documento,data_publicacao,ano_obra',
      )
          .inFilter('id', ids);

      final obras = (resposta as List)
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();

      final mapaObras = <String, Map<String, dynamic>>{};

      for (final obra in obras) {
        final id = obra['id']?.toString();

        if (id != null && id.isNotEmpty) {
          mapaObras[id] = obra;
        }
      }

      final resultado = <Map<String, dynamic>>[];

      for (final consulta in historico) {
        final obra = mapaObras[consulta.obraId];

        if (obra != null) {
          resultado.add(obra);
        }

        if (resultado.length >= quantidade) {
          break;
        }
      }

      return resultado;
    } catch (e) {
      debugPrint(
        'Erro ao carregar obras consultadas: $e',
      );

      return [];
    }
  }

  Future<void> sincronizarHistoricoLocal() async {
    if (!_inicializado) {
      await inicializar();
    }

    final usuario = _supabase.auth.currentUser;

    if (usuario == null || _historico.isEmpty) {
      return;
    }

    try {
      for (final consulta in _historico) {
        await _registrarNoSupabase(
          usuario.id,
          consulta.obraId,
          consulta.consultadoEm,
        );
      }

      await carregarHistorico();
    } catch (e) {
      debugPrint(
        'Erro ao sincronizar histórico local: $e',
      );
    }
  }

  Future<void> limparHistorico() async {
    _historico = [];

    await _salvarHistoricoLocal();

    final usuario = _supabase.auth.currentUser;

    if (usuario != null) {
      try {
        await _supabase
            .from('historico_consultas')
            .delete()
            .eq('usuario_id', usuario.id);
      } catch (e) {
        debugPrint(
          'Erro ao limpar histórico do Supabase: $e',
        );
      }
    }

    notifyListeners();
  }
}
