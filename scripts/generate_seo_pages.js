const fs = require('fs');
const path = require('path');

const SITE_URL = 'https://ginho83-wq.github.io/obra_livre';

const SUPABASE_URL = (process.env.SUPABASE_URL || '').replace(/\/+$/, '');
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || '';

const BUILD_DIR = path.join(process.cwd(), 'build', 'web');
const INDEX_FILE = path.join(BUILD_DIR, 'index.html');

if (!SUPABASE_URL) {
  console.error('ERRO: SUPABASE_URL nao foi configurada.');
  process.exit(1);
}

if (!SUPABASE_ANON_KEY) {
  console.error('ERRO: SUPABASE_ANON_KEY nao foi configurada.');
  process.exit(1);
}

if (!fs.existsSync(INDEX_FILE)) {
  console.error('ERRO: build/web/index.html nao foi encontrado.');
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
    'data_publicacao'
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

function substituirOuAdicionar(
  html,
  regex,
  novoConteudo,
  local
) {
  if (regex.test(html)) {
    return html.replace(regex, novoConteudo);
  }

  return html.replace(
    local,
    `${local}\n    ${novoConteudo}`
  );
}

function gerarHtml(baseHtml, obra) {
  const id =
    limparTexto(obra.id);

  const titulo =
    limparTexto(obra.titulo) ||
    'Obra academica';

  const descricao =
    limitarDescricao(obra.descricao);

  const autor =
    limparTexto(obra.autor);

  const categoria =
    limparTexto(obra.categoria);

  const url =
    obterUrlObra(id);

  let html = baseHtml;

  const novoTitulo =
    `${escapeHtml(titulo)} | Obra Livre`;

  const metaDescription =
    `<meta name="description" content="${escapeHtml(descricao)}">`;

  const metaAuthor =
    `<meta name="author" content="${escapeHtml(
      autor || 'Obra Livre'
    )}">`;

  const metaRobots =
    `<meta name="robots" content="index, follow">`;

  const metaGooglebot =
    `<meta name="googlebot" content="index, follow">`;

  const metaKeywords =
    `<meta name="keywords" content="${escapeHtml(
      [
        titulo,
        autor,
        categoria,
        'trabalho academico',
        'pesquisa cientifica',
        'Obra Livre'
      ]
        .filter(Boolean)
        .join(', ')
    )}">`;

  const ogTitle =
    `<meta property="og:title" content="${escapeHtml(
      titulo
    )} | Obra Livre">`;

  const ogDescription =
    `<meta property="og:description" content="${escapeHtml(
      descricao
    )}">`;

  const ogUrl =
    `<meta property="og:url" content="${escapeHtml(
      url
    )}">`;

  const ogType =
    `<meta property="og:type" content="article">`;

  const ogSiteName =
    `<meta property="og:site_name" content="Obra Livre">`;

  const ogLocale =
    `<meta property="og:locale" content="pt_MZ">`;

  const imagePreview =
    `<meta name="robots" content="max-image-preview:large">`;

  const canonical =
    `<link rel="canonical" href="${escapeHtml(url)}">`;

  const jsonLd =
    `<script type="application/ld+json">${gerarJsonLd(
      obra,
      url
    )}</script>`;

  /*
   * ==========================================================
   * METADADOS SEO
   * ==========================================================
   */

  html = substituirOuAdicionar(
    html,
    /<title>[\s\S]*?<\/title>/i,
    `<title>${novoTitulo}</title>`,
    '<head>'
  );

  html = substituirOuAdicionar(
    html,
    /<meta\s+name=["']description["'][^>]*>/i,
    metaDescription,
    '<head>'
  );

  html = substituirOuAdicionar(
    html,
    /<meta\s+name=["']author["'][^>]*>/i,
    metaAuthor,
    '<head>'
  );

  html = substituirOuAdicionar(
    html,
    /<meta\s+name=["']robots["'][^>]*>/i,
    metaRobots,
    '<head>'
  );

  html = substituirOuAdicionar(
    html,
    /<meta\s+name=["']googlebot["'][^>]*>/i,
    metaGooglebot,
    '<head>'
  );

  html = substituirOuAdicionar(
    html,
    /<meta\s+name=["']keywords["'][^>]*>/i,
    metaKeywords,
    '<head>'
  );

  html = substituirOuAdicionar(
    html,
    /<link\s+rel=["']canonical["'][^>]*>/i,
    canonical,
    '<head>'
  );

  html = substituirOuAdicionar(
    html,
    /<meta\s+property=["']og:title["'][^>]*>/i,
    ogTitle,
    '<head>'
  );

  html = substituirOuAdicionar(
    html,
    /<meta\s+property=["']og:description["'][^>]*>/i,
    ogDescription,
    '<head>'
  );

  html = substituirOuAdicionar(
    html,
    /<meta\s+property=["']og:url["'][^>]*>/i,
    ogUrl,
    '<head>'
  );

  html = substituirOuAdicionar(
    html,
    /<meta\s+property=["']og:type["'][^>]*>/i,
    ogType,
    '<head>'
  );

  html = substituirOuAdicionar(
    html,
    /<meta\s+property=["']og:site_name["'][^>]*>/i,
    ogSiteName,
    '<head>'
  );

  html = substituirOuAdicionar(
    html,
    /<meta\s+property=["']og:locale["'][^>]*>/i,
    ogLocale,
    '<head>'
  );

  /*
   * max-image-preview
   */
  html = substituirOuAdicionar(
    html,
    /<meta\s+name=["']robots["'][^>]*>/i,
    `${metaRobots}\n    ${imagePreview}`,
    '<head>'
  );

  /*
   * JSON-LD
   */
  html = html.replace(
    /<head>/i,
    `<head>\n    ${jsonLd}`
  );

  return html;
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

  const baseHtml =
    fs.readFileSync(
      INDEX_FILE,
      'utf8'
    );

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

    const html =
      gerarHtml(
        baseHtml,
        obra
      );

    fs.writeFileSync(
      path.join(
        diretorio,
        'index.html'
      ),
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

  console.error(erro.message);

  console.error('');

  process.exit(1);
});



 