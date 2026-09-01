class ConfigAds {
  ConfigAds._();

  /// Durante o desenvolvimento mantém o anúncio visual de teste.
  static const bool webTestMode = true;

  /// Será alterado para true quando o AdSense real estiver configurado.
  static const bool hasWebAdSenseConfig = false;

  /// Publisher ID do Google AdSense.
  ///
  /// Exemplo:
  /// ca-pub-XXXXXXXXXXXXXXXX
  ///
  /// Não colocar um ID fictício.
  static const String webPublisherId = '';

  /// Identificador do bloco de anúncio Web.
  ///
  /// Será preenchido quando criarmos o bloco real no AdSense.
  static const String webAdSlot = '';
}
