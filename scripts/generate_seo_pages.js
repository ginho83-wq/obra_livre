const fs = require('fs');
const path = require('path');

const SITE_URL = 'https://ginho83-wq.github.io/obra_livre';
const SUPABASE_URL = (process.env.SUPABASE_URL || '').replace(/\/+$/, '');
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || '';
const BUILD_DIR = path.join(process.cwd(), 'build', 'web');

if (!SUPABASE_URL) {
  console.error('ERRO: SUPABASE_URL nao foi configurada.');
  process.exit(1);
}

if (!SUPABASE_ANON_KEY) {
  console.error('ERRO: SUPABASE_ANON_KEY nao foi configurada.');
  process.exit(1);
}

if (!fs.existsSync(BUILD_DIR)) {
  console.error('ERRO: build/web nao foi encontrado.');
  console.error('Execute primeiro: flutter build web');
  process.exit(1);
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function limparTexto(value) {
  return String(value ?? '')
    .replace(/\s+/g, ' ')
    .trim();
}

function limitarDescricao(value) {
  const texto = limparTexto(value);

  if (!texto) {
    return 'Obra academica disponivel na biblioteca Obra Livre.';
  }

  if (texto.length <= 160) {
    return texto;
  }

  return texto.substring(0, 157) + '...';
}

function escapeJsonLd(value) {
  return JSON.stringify(value)
    .replace(/</g, '\\u003c')
    .replace(/>/g, '\\u003e')
    .replace(/&/g, '\\u0026');
}

function obterUrlObra(id) {
  return `${SITE_URL}/obra/${encodeURIComponent(id)}/`;
}

async function carregarObras() {
  const campos = [
    'id',
    'titulo',
    'descricao',
    'autor',
    'categoria',
    'ano_obra',
    'data_publicacao',
    'url_documento'
  ].join(',');

  const url =
    `${SUPABASE_URL}/rest/v1/obras` +
    `?select=${encodeURIComponent(campos)}` +
    `&status=eq.aprovada` +
    `&order=data_publicacao.desc`;

  console.log('Consultando obras aprovadas no Supabase...');

  const resposta = await fetch(url, {
    method: 'GET',
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      Accept: 'application/json'
    }
  });

  if (!resposta.ok) {
    const texto = await resposta.text();

    throw new Error(
      `Supabase respondeu HTTP ${resposta.status}: ${texto}`
    );
  }

  const obras = await resposta.json();

  if (!Array.isArray(obras)) {
    throw new Error(
      'Resposta do Supabase nao e uma lista de obras.'
    );
  }

  return obras;
}

function gerarJsonLd(obra, url) {
  const titulo =
    limparTexto(obra.titulo) || 'Obra academica';

  const descricao =
    limitarDescricao(obra.descricao);

  const autor =
    limparTexto(obra.autor);

  const categoria =
    limparTexto(obra.categoria);

  const dados = {
    '@context': 'https://schema.org',
    '@type': 'ScholarlyArticle',

    headline: titulo,

    description: descricao,

    url: url,

    author: {
      '@type': 'Person',
      name: autor || 'Autor nao informado'
    },

    publisher: {
      '@type': 'Organization',
      name: 'Obra Livre',
      url: `${SITE_URL}/`
    },

    isPartOf: {
      '@type': 'WebSite',
      name: 'Obra Livre',
      url: `${SITE_URL}/`
    }
  };

  if (categoria) {
    dados.articleSection = categoria;
  }

  if (obra.ano_obra) {
    dados.datePublished =
      `${String(obra.ano_obra)}-01-01`;
  } else if (obra.data_publicacao) {
    dados.datePublished =
      String(obra.data_publicacao);
  }

  return escapeJsonLd(dados);
}

function gerarHtmlObra(obra) {
  const id =
    limparTexto(obra.id);

  const titulo =
    limparTexto(obra.titulo) ||
    'Obra academica';

  const descricao =
    limitarDescricao(obra.descricao);

  const descricaoCompleta =
    limparTexto(obra.descricao);

  const autor =
    limparTexto(obra.autor);

  const categoria =
    limparTexto(obra.categoria);

  const ano =
    limparTexto(obra.ano_obra);

  const dataPublicacao =
    limparTexto(obra.data_publicacao);

  const url =
    obterUrlObra(id);

  const urlDocumento =
    limparTexto(obra.url_documento);

  const documentoHtml =
    urlDocumento
      ? `
        <p>
          <a
            href="${escapeHtml(urlDocumento)}"
            target="_blank"
            rel="noopener noreferrer"
          >
            Abrir documento completo
          </a>
        </p>
      `
      : `
        <p>
          O documento desta obra nao esta disponivel
          para abertura neste momento.
        </p>
      `;

  const anoHtml =
    ano
      ? `
        <p>
          <strong>Ano:</strong>
          ${escapeHtml(ano)}
        </p>
      `
      : '';

  const categoriaHtml =
    categoria
      ? `
        <p>
          <strong>Categoria:</strong>
          ${escapeHtml(categoria)}
        </p>
      `
      : '';

  const dataHtml =
    dataPublicacao
      ? `
        <p>
          <strong>Data de publicacao:</strong>
          ${escapeHtml(dataPublicacao)}
        </p>
      `
      : '';

  const descricaoHtml =
    descricaoCompleta
      ? `
        <p>
          ${escapeHtml(descricaoCompleta)}
        </p>
      `
      : `
        <p>
          Esta obra esta disponivel no acervo digital
          Obra Livre.
        </p>
      `;

  const jsonLd =
    gerarJsonLd(obra, url);

  return `<!DOCTYPE html>
<html lang="pt">
<head>

  <meta charset="UTF-8">

  <meta
    name="viewport"
    content="width=device-width, initial-scale=1.0"
  >

  <title>
    ${escapeHtml(titulo)} | Obra Livre
  </title>

  <meta
    name="description"
    content="${escapeHtml(descricao)}"
  >

  <meta
    name="author"
    content="${escapeHtml(autor || 'Obra Livre')}"
  >

  <meta
    name="robots"
    content="index, follow, max-image-preview:large"
  >

  <meta
    name="googlebot"
    content="index, follow"
  >

  <link
    rel="canonical"
    href="${escapeHtml(url)}"
  >

  <!-- Open Graph -->

  <meta
    property="og:title"
    content="${escapeHtml(titulo)} | Obra Livre"
  >

  <meta
    property="og:description"
    content="${escapeHtml(descricao)}"
  >

  <meta
    property="og:type"
    content="article"
  >

  <meta
    property="og:url"
    content="${escapeHtml(url)}"
  >

  <meta
    property="og:site_name"
    content="Obra Livre"
  >

  <meta
    property="og:locale"
    content="pt_MZ"
  >

  <!-- Dados estruturados -->

  <script type="application/ld+json">
    ${jsonLd}
  </script>

  <style>

    body {
      font-family:
        Arial,
        Helvetica,
        sans-serif;

      max-width: 900px;

      margin: 0 auto;

      padding: 30px;

      line-height: 1.7;

      color: #222;

      background: #ffffff;
    }

    header {
      border-bottom:
        1px solid #ddd;

      margin-bottom: 30px;

      padding-bottom: 20px;
    }

    h1 {
      font-size: 32px;

      line-height: 1.3;

      margin-bottom: 15px;
    }

    h2 {
      margin-top: 30px;

      border-bottom:
        1px solid #eee;

      padding-bottom: 8px;
    }

    .informacoes {
      background: #f7f7f7;

      padding: 20px;

      border-radius: 8px;

      margin-bottom: 30px;
    }

    .botao {
      display: inline-block;

      padding: 12px 18px;

      margin-top: 10px;

      border-radius: 6px;

      text-decoration: none;

      background: #333;

      color: #fff;
    }

    footer {
      margin-top: 50px;

      padding-top: 20px;

      border-top:
        1px solid #ddd;
    }

    a {
      color: #1a5fb4;
    }

  </style>

</head>

<body>

  <header>

    <h1>
      ${escapeHtml(titulo)}
    </h1>

    <p>
      <strong>Autor:</strong>
      ${escapeHtml(autor || 'Autor nao informado')}
    </p>

  </header>

  <main>

    <section class="informacoes">

      <h2>Informacoes da obra</h2>

      ${categoriaHtml}

      ${anoHtml}

      ${dataHtml}

    </section>

    <article>

      <h2>Resumo / Descricao</h2>

      ${descricaoHtml}

    </article>

    <section>

      <h2>Documento</h2>

      ${documentoHtml}

    </section>

  </main>

  <footer>

    <p>
      <a href="${SITE_URL}/">
        ← Voltar ao Obra Livre
      </a>
    </p>

    <p>
      <a href="${SITE_URL}/acervo">
        Ver acervo completo
      </a>
    </p>

  </footer>

</body>

</html>
`;
}

function obterLastMod(obra) {
  if (obra.data_publicacao) {
    const data =
      new Date(obra.data_publicacao);

    if (!Number.isNaN(data.getTime())) {
      return data
        .toISOString()
        .substring(0, 10);
    }
  }

  if (obra.ano_obra) {
    return `${String(obra.ano_obra)}-01-01`;
  }

  return new Date()
    .toISOString()
    .substring(0, 10);
}

function gerarSitemap(obras) {
  const hoje =
    new Date()
      .toISOString()
      .substring(0, 10);

  const urls = [
    {
      loc: `${SITE_URL}/`,
      lastmod: hoje,
      changefreq: 'weekly',
      priority: '1.0'
    },

    {
      loc: `${SITE_URL}/acervo`,
      lastmod: hoje,
      changefreq: 'weekly',
      priority: '0.9'
    },

    {
      loc: `${SITE_URL}/categoria/doutoramento`,
      lastmod: hoje,
      changefreq: 'monthly',
      priority: '0.7'
    },

    {
      loc: `${SITE_URL}/categoria/mestrado`,
      lastmod: hoje,
      changefreq: 'monthly',
      priority: '0.7'
    },

    {
      loc: `${SITE_URL}/categoria/monografia`,
      lastmod: hoje,
      changefreq: 'monthly',
      priority: '0.7'
    },

    {
      loc: `${SITE_URL}/categoria/artigos-cientificos`,
      lastmod: hoje,
      changefreq: 'monthly',
      priority: '0.7'
    },

    {
      loc: `${SITE_URL}/categoria/literatura`,
      lastmod: hoje,
      changefreq: 'monthly',
      priority: '0.7'
    }
  ];

  for (const obra of obras) {
    const id =
      limparTexto(obra.id);

    if (!id) {
      continue;
    }

    urls.push({
      loc: obterUrlObra(id),
      lastmod: obterLastMod(obra),
      changefreq: 'monthly',
      priority: '0.8'
    });
  }

  let xml =
    '<?xml version="1.0" encoding="UTF-8"?>\n';

  xml +=
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n';

  for (const item of urls) {
    xml += '  <url>\n';

    xml +=
      `    <loc>${escapeHtml(item.loc)}</loc>\n`;

    xml +=
      `    <lastmod>${escapeHtml(item.lastmod)}</lastmod>\n`;

    xml +=
      `    <changefreq>${item.changefreq}</changefreq>\n`;

    xml +=
      `    <priority>${item.priority}</priority>\n`;

    xml += '  </url>\n';
  }

  xml += '</urlset>\n';

  fs.writeFileSync(
    path.join(BUILD_DIR, 'sitemap.xml'),
    xml,
    'utf8'
  );

  return urls.length;
}

function gerarRobots() {
  const robots = [
    'User-agent: *',
    'Allow: /',
    '',
    `Sitemap: ${SITE_URL}/sitemap.xml`,
    ''
  ].join('\n');

  fs.writeFileSync(
    path.join(BUILD_DIR, 'robots.txt'),
    robots,
    'utf8'
  );
}

async function main() {
  console.log('==============================================');
  console.log('OBRA LIVRE - GERADOR DE PAGINAS SEO');
  console.log('==============================================');

  const obras =
    await carregarObras();

  console.log(
    `Obras aprovadas encontradas: ${obras.length}`
  );

  let paginasCriadas = 0;

  for (const obra of obras) {
    const id =
      limparTexto(obra.id);

    if (!id) {
      console.warn(
        'Obra ignorada porque nao possui ID.'
      );

      continue;
    }

    const diretorio =
      path.join(
        BUILD_DIR,
        'obra',
        id
      );

    fs.mkdirSync(
      diretorio,
      {
        recursive: true
      }
    );

    /*
     * IMPORTANTE:
     *
     * A pagina individual NAO usa
     * build/web/index.html do Flutter.
     *
     * Ela e um HTML independente.
     */

    const html =
      gerarHtmlObra(obra);

    const arquivo =
      path.join(
        diretorio,
        'index.html'
      );

    fs.writeFileSync(
      arquivo,
      html,
      'utf8'
    );

    paginasCriadas++;

    console.log(
      `Pagina criada: /obra/${id}/`
    );
  }

  const quantidadeUrls =
    gerarSitemap(obras);

  gerarRobots();

  console.log('');

  console.log(
    `Paginas individuais criadas: ${paginasCriadas}`
  );

  console.log(
    `URLs no sitemap: ${quantidadeUrls}`
  );

  console.log('');

  console.log(
    'SEO concluido com sucesso.'
  );
}

main().catch((erro) => {
  console.error('');

  console.error(
    '=============================================='
  );

  console.error(
    'ERRO NO GERADOR SEO'
  );

  console.error(
    '=============================================='
  );

  console.error(
    erro.message
  );

  console.error('');

  process.exit(1);
});
