import 'dart:async';

import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';

class NoInternetBanner extends StatefulWidget {
  const NoInternetBanner({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<NoInternetBanner> createState() =>
      _NoInternetBannerState();
}

class _NoInternetBannerState
    extends State<NoInternetBanner> {
  final ConnectivityService _connectivityService =
      ConnectivityService.instance;

  StreamSubscription<bool>? _statusSubscription;

  late bool _isOnline;

  bool _checking = false;

  @override
  void initState() {
    super.initState();

    _isOnline =
        _connectivityService.isOnline;

    _statusSubscription =
        _connectivityService.statusStream.listen(
              (isOnline) {
            if (!mounted) {
              return;
            }

            setState(() {
              _isOnline = isOnline;
            });
          },
        );
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // TENTAR NOVAMENTE
  // ============================================================

  Future<void> _tryAgain() async {
    if (_checking) {
      return;
    }

    setState(() {
      _checking = true;
    });

    final isOnline =
    await _connectivityService.checkNow();

    if (!mounted) {
      return;
    }

    setState(() {
      _isOnline = isOnline;
      _checking = false;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: IgnorePointer(
              ignoring: _isOnline,
              child: AnimatedSlide(
                duration:
                const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                offset: _isOnline
                    ? const Offset(0, -1.5)
                    : Offset.zero,
                child: AnimatedOpacity(
                  duration:
                  const Duration(milliseconds: 200),
                  opacity: _isOnline ? 0 : 1,
                  child: Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      0,
                    ),
                    child: _buildBanner(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BANNER
  // ============================================================

  Widget _buildBanner(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1200,
        ),
        child: Material(
          color: Colors.white,
          elevation: 5,
          shadowColor: Colors.black12,
          borderRadius:
          BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: LayoutBuilder(
              builder:
                  (context, constraints) {
                if (constraints.maxWidth < 650) {
                  return _buildMobileLayout();
                }

                return _buildDesktopLayout();
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildConnectionIcon(),

        const SizedBox(width: 18),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Sem ligação à Internet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(0xFF202124),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Verifique a sua ligação. '
                    'Algumas funcionalidades podem '
                    'estar temporariamente indisponíveis.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color:
                  Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        _buildRetryButton(),
      ],
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildConnectionIcon(),

            const SizedBox(width: 14),

            const Expanded(
              child: Text(
                'Sem ligação à Internet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(0xFF202124),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          'Verifique a sua ligação. '
              'Algumas funcionalidades podem '
              'estar temporariamente indisponíveis.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 16),

        Align(
          alignment:
          Alignment.centerRight,
          child: _buildRetryButton(),
        ),
      ],
    );
  }

  // ============================================================
  // ÍCONE
  // ============================================================

  Widget _buildConnectionIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.wifi_off_rounded,
        size: 23,
        color: Colors.grey.shade700,
      ),
    );
  }

  // ============================================================
  // BOTÃO TENTAR NOVAMENTE
  // ============================================================

  Widget _buildRetryButton() {
    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed:
        _checking ? null : _tryAgain,
        style: OutlinedButton.styleFrom(
          foregroundColor:
          const Color(0xFF303030),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(9),
          ),
        ),
        child: _checking
            ? const SizedBox(
          width: 17,
          height: 17,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
          ),
        )
            : const Text(
          'Tentar novamente',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
