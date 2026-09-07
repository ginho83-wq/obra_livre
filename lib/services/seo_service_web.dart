import 'dart:convert';
import 'dart:html' as html;

class SeoService {
  static const String _siteName = 'Obra Livre';

  static String _limparTexto(String texto) {
    return texto
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _descricaoLimitada(String texto) {
    final valor = _limparTexto(texto);

    if (valor.length <= 160) {
      return valor;
    }

    return '${valor.substring(0, 157)}...';
  }

  static void _definirMeta(
      String nome,
      String valor, {
        String? propriedade,
      }) {
    html.MetaElement? meta;

    if (propriedade != null) {
      meta = html.document.head
          ?.querySelector(
        'meta[property="$propriedade"]',
      ) as html.MetaElement?;
    } else {
      meta = html.document.head
          ?.querySelector(
        'meta[name="$nome"]',
      ) as html.MetaElement?;
    }

    if (meta == null) {
      meta = html.MetaElement();

      if (propriedade != null) {
        meta.setAttribute(
          'property',
          propriedade,
        );
      } else {
        meta.name = nome;
      }

      html.document.head?.append(meta);
    }

    meta.content = valor;
  }

  static void _definirCanonical(String url) {
    var link = html.document.head
        ?.querySelector(
      'link[rel="canonical"]',
    ) as html.LinkElement?;

    if (link == null) {
      link = html.LinkElement()
        ..rel = 'canonical';

      html.document.head?.append(link);
    }

    link.href = url;
  }

  static void _definirJsonLd(
      Map<String, dynamic> dados,
      ) {
    html.ScriptElement? script =
    html.document.head?.querySelector(
      'script[data-seo-jsonld="obra"]',
    ) as html.ScriptElement?;

    if (script == null) {
      script = html.ScriptElement()
        ..setAttribute(
          'data-seo-jsonld',
          'obra',
        )
        ..type = 'application/ld+json';

      html.document.head?.append(script);
    }

    script.text = jsonEncode(dados);
  }

  static void definirObra({
    required String titulo,
    required String descricao,
    required String autor,
    required String categoria,
    required String url,
    int? ano,
  }) {
    final tituloLimpo = _limparTexto(titulo);

    final descricaoLimpa =
    _descricaoLimitada(descricao);

    final autorLimpo = _limparTexto(autor);

    final categoriaLimpa =
    _limparTexto(categoria);

    final tituloSeo =
        '$tituloLimpo | $_siteName';

    html.document.title = tituloSeo;

    _definirMeta(
      'description',
      descricaoLimpa,
    );

    _definirMeta(
      'author',
      autorLimpo.isEmpty
          ? _siteName
          : autorLimpo,
    );

    _definirMeta(
      'robots',
      'index, follow',
    );

    _definirMeta(
      'googlebot',
      'index, follow',
    );

    _definirMeta(
      'keywords',
      [
        tituloLimpo,
        autorLimpo,
        categoriaLimpa,
        'trabalho académico',
        'pesquisa',
        'Obra Livre',
      ].where((item) => item.isNotEmpty).join(', '),
    );

    _definirMeta(
      'og:title',
      tituloSeo,
      propriedade: 'og:title',
    );

    _definirMeta(
      'og:description',
      descricaoLimpa,
      propriedade: 'og:description',
    );

    _definirMeta(
      'og:url',
      url,
      propriedade: 'og:url',
    );

    _definirMeta(
      'og:type',
      'article',
      propriedade: 'og:type',
    );

    _definirMeta(
      'og:site_name',
      _siteName,
      propriedade: 'og:site_name',
    );

    _definirMeta(
      'og:locale',
      'pt_MZ',
      propriedade: 'og:locale',
    );

    _definirCanonical(url);

    final dados = <String, dynamic>{
      '@context': 'https://schema.org',
      '@type': 'ScholarlyArticle',
      'headline': tituloLimpo,
      'description': descricaoLimpa,
      'url': url,
      'author': {
        '@type': 'Person',
        'name': autorLimpo,
      },
      'publisher': {
        '@type': 'Organization',
        'name': _siteName,
        'url':
        'https://ginho83-wq.github.io/obra_livre/',
      },
      'isPartOf': {
        '@type': 'WebSite',
        'name': _siteName,
        'url':
        'https://ginho83-wq.github.io/obra_livre/',
      },
    };

    if (categoriaLimpa.isNotEmpty) {
      dados['articleSection'] =
          categoriaLimpa;
    }

    if (ano != null) {
      dados['datePublished'] =
      '$ano-01-01';
    }

    _definirJsonLd(dados);
  }

  static void limpar() {
    html.document.title =
    'Obra Livre — Acervo Digital Académico';

    final seletores = [
      'meta[name="description"]',
      'meta[name="author"]',
      'meta[name="robots"]',
      'meta[name="googlebot"]',
      'meta[name="keywords"]',
      'meta[property="og:title"]',
      'meta[property="og:description"]',
      'meta[property="og:url"]',
      'meta[property="og:type"]',
      'meta[property="og:site_name"]',
      'meta[property="og:locale"]',
      'script[data-seo-jsonld="obra"]',
    ];

    for (final seletor in seletores) {
      html.document.head
          ?.querySelector(seletor)
          ?.remove();
    }

    _definirCanonical(
      'https://ginho83-wq.github.io/obra_livre/',
    );
  }
}
