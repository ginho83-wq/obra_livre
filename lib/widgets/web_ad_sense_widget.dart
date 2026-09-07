import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/config_ads.dart';

class WebAdSenseWidget extends StatelessWidget {
  final String adSize;

  const WebAdSenseWidget({
    super.key,
    this.adSize = 'small',
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    final size = _obterTamanho();

    return Align(
      alignment: Alignment.topRight,
      child: Container(
        width: size.width,
        height: size.height,
        margin: const EdgeInsets.only(
          top: 4,
          right: 0,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context)
                .dividerColor
                .withValues(alpha: 0.08),
            width: 0.7,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _construirConteudo(
          context,
          size.width,
          size.height,
        ),
      ),
    );
  }

  Size _obterTamanho() {
    switch (adSize.toLowerCase()) {
      case 'small':
        return const Size(180, 100);

      case 'medium':
        return const Size(300, 250);

      case 'large':
        return const Size(728, 250);

      default:
        return const Size(180, 100);
    }
  }

  Widget _construirConteudo(
      BuildContext context,
      double width,
      double height,
      ) {
    if (ConfigAds.webTestMode) {
      return _construirAnuncioTeste(
        context,
        width,
        height,
      );
    }

    if (!ConfigAds.hasWebAdSenseConfig) {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // ADVERTISEMENT REAL
    // ==========================================================
    //
    // A integração real do AdSense será adicionada quando
    // o Publisher ID e o código definitivo do AdSense
    // estiverem configurados.
    //
    // Não colocamos aqui um anúncio falso ou um vídeo falso.

    return const SizedBox.shrink();
  }

  Widget _construirAnuncioTeste(
      BuildContext context,
      double width,
      double height,
      ) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ads_click_outlined,
              size: 20,
              color: theme.textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 4),
            Text(
              'Publicidade',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${width.toInt()} × ${height.toInt()}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                color: theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
