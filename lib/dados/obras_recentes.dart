// ==========================================================
// MODELO DE OBRA RECENTE
// ==========================================================

class ObraRecente {
  final String id;
  final String titulo;
  final String resumo;
  final String autor;
  final String coautores;
  final String categoria;
  final String urlDocumento;
  final String dataPublicacao;
  final String status;

  // ========================================================
  // ANO DA OBRA
  // ========================================================

  final int? anoObra;

  // ========================================================
  // CONSTRUTOR
  // ========================================================

  const ObraRecente({
    required this.id,
    required this.titulo,
    required this.resumo,
    required this.autor,
    required this.coautores,
    required this.categoria,
    required this.urlDocumento,
    required this.dataPublicacao,
    required this.status,
    this.anoObra,
  });

  // ========================================================
  // CONVERTER PARA MAP
  // ========================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'resumo': resumo,
      'autor': autor,
      'coautores': coautores,
      'categoria': categoria,
      'urlDocumento': urlDocumento,
      'dataPublicacao': dataPublicacao,
      'status': status,
      'anoObra': anoObra,
    };
  }

  // ========================================================
  // CRIAR A PARTIR DE MAP
  // ========================================================

  factory ObraRecente.fromMap(
      Map<String, dynamic> mapa,
      ) {
    return ObraRecente(
      id: mapa['id']?.toString() ?? '',
      titulo: mapa['titulo']?.toString() ?? '',
      resumo: mapa['resumo']?.toString() ?? '',
      autor: mapa['autor']?.toString() ?? '',
      coautores: mapa['coautores']?.toString() ?? '',
      categoria: mapa['categoria']?.toString() ?? '',
      urlDocumento: mapa['urlDocumento']?.toString() ?? '',
      dataPublicacao:
      mapa['dataPublicacao']?.toString() ?? '',
      status: mapa['status']?.toString() ?? '',
      anoObra: _converterAno(mapa['anoObra']),
    );
  }

  // ========================================================
  // CONVERTER ANO COM SEGURANÇA
  // ========================================================

  static int? _converterAno(dynamic valor) {
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
  // COPIAR OBJETO
  // ========================================================

  ObraRecente copyWith({
    String? id,
    String? titulo,
    String? resumo,
    String? autor,
    String? coautores,
    String? categoria,
    String? urlDocumento,
    String? dataPublicacao,
    String? status,
    int? anoObra,
  }) {
    return ObraRecente(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      resumo: resumo ?? this.resumo,
      autor: autor ?? this.autor,
      coautores: coautores ?? this.coautores,
      categoria: categoria ?? this.categoria,
      urlDocumento: urlDocumento ?? this.urlDocumento,
      dataPublicacao:
      dataPublicacao ?? this.dataPublicacao,
      status: status ?? this.status,
      anoObra: anoObra ?? this.anoObra,
    );
  }
}
