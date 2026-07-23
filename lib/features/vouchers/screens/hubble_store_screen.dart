import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/widgets/Cards.dart';
import '../bloc/hubble_bloc.dart';

/// Hubble Gift Card Store — embedded WebView, matching the app's design language.
/// No custom app bar — sits inside the main layout's bottom nav tab.
class HubbleStoreScreen extends StatefulWidget {
  const HubbleStoreScreen({super.key});

  @override
  State<HubbleStoreScreen> createState() => _HubbleStoreScreenState();
}

class _HubbleStoreScreenState extends State<HubbleStoreScreen> {
  WebViewController? _controller;
  bool _pageLoading = true;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    context.read<HubbleBloc>().add(LoadHubbleSDK());
  }

  void _initWebView(String sdkUrl) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.surface)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _loadingProgress = p),
          onPageStarted: (_) => setState(() => _pageLoading = true),
          onPageFinished: (_) => setState(() => _pageLoading = false),
          onWebResourceError: (_) => setState(() => _pageLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(sdkUrl));

    setState(() {
      _controller = controller;
      _pageLoading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<HubbleBloc, HubbleState>(
          listenWhen: (_, curr) => curr is HubbleReady,
          listener: (context, state) {
            if (state is HubbleReady) _initWebView(state.sdkUrl);
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header matching other screens ──
                const ScreenHeader(
                  title: 'Gift Cards',
                  subtitle: 'Shop from hundreds of top brands instantly.',
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                  titleFontSize: 25,
                  subtitleFontSize: 15,
                  gap: 4,
                ),

                // ── Progress bar while page loads ──
                if (_controller != null && _pageLoading)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _loadingProgress / 100),
                    duration: const Duration(milliseconds: 200),
                    builder: (_, value, __) => LinearProgressIndicator(
                      value: value,
                      minHeight: 2.5,
                      backgroundColor: AppColors.hairline,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF5A623)),
                    ),
                  ),

                // ── Body ──
                Expanded(child: _buildBody(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(HubbleState state) {
    // WebView ready — show it with optional loading overlay
    if (_controller != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller!),
          if (_pageLoading) _buildOverlay('Opening Gift Card Store…'),
        ],
      );
    }

    // Error state
    if (state is HubbleError) return _buildError(state.message);

    // Initial / Loading — fetching SDK token
    return _buildOverlay('Loading Gift Card Store…');
  }

  // ── Loading overlay ──
  Widget _buildOverlay(String message) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF5A623).withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFF5A623), size: 30),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFF5A623),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.bodyGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ──
  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.dangerFg.withValues(alpha: 0.15)),
              ),
              child: Icon(Icons.wifi_off_rounded, size: 34, color: AppColors.dangerFg),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.bodyGrey,
                fontWeight: FontWeight.w500,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 28),
            GradientCtaButton(
              icon: Icons.refresh_rounded,
              label: 'Try Again',
              onTap: () => context.read<HubbleBloc>().add(LoadHubbleSDK()),
              colors: const [Color(0xFFF5A623), Color(0xFFE6961A)],
            ),
          ],
        ),
      ),
    );
  }
}
