export 'seo_service_stub.dart'
if (dart.library.html) 'seo_service_web.dart';

class SeoService {
  static void definirObra({
    required String titulo,
    required String descricao,
    required String autor,
    required String categoria,
    required String url,
    int? ano,
  }) {
    // Implementação específica da Web.
    // Fora da Web não é necessário fazer nada.
  }

  static void limpar() {
    // Nada a fazer fora da Web.
  }
}
