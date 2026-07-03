import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/bloc/auth_bloc.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/orders_repository.dart';
import 'core/repositories/product_repository.dart';
import 'core/repositories/claims_repository.dart';
import 'core/services/api_service.dart';
import 'core/network/api_client.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/main_layout/screens/main_layout_screen.dart';
import 'features/orders/bloc/orders_bloc.dart';
import 'features/claims/bloc/claims_bloc.dart';
import 'features/product/bloc/product_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';
import 'core/widgets/tampered_device_warning.dart';
import 'core/utils/error_scrubber.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService.init();

  // SECTION 6: Root/Jailbreak and Mock Location Detection (Release only)
  if (!kDebugMode) {
    final isJailbroken = await SafeDevice.isJailBroken;
    final isRealDevice = await SafeDevice.isRealDevice;

    if (isJailbroken || !isRealDevice) {
      runApp(const TamperedDeviceWarningApp());
      return;
    }
  }

  // SECTION 13: Crash Reporting Scrubbing (Mock integration)
  FlutterError.onError = (errorDetails) {
    debugPrint(ErrorScrubber.sanitize(errorDetails.toString()));
  };

  // Network & Services
  final apiClient = ApiClient();
  final apiService = ApiService(apiClient);

  // Repositories
  final authRepo = AuthRepository();
  final ordersRepo = OrdersRepository();
  final productRepo = ProductRepository();
  final claimsRepo = ClaimsRepository();

  // Force portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make status bar transparent so hero section bleeds through
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0D0D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepo),
        RepositoryProvider.value(value: ordersRepo),
        RepositoryProvider.value(value: productRepo),
        RepositoryProvider.value(value: claimsRepo),
        RepositoryProvider<ApiService>.value(value: apiService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthBloc(apiService: apiService)..add(AuthCheckRequested())),
          BlocProvider(create: (context) => OrdersBloc(apiService: apiService)),
          BlocProvider(
            create: (context) => ProductBloc(apiService: apiService)..add(LoadProducts()),
          ),
          BlocProvider(
            create: (context) => ClaimsBloc(
              apiService: apiService,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

/// A custom page-transition builder that gives every pushed route a fluid
/// fade + slight slide-up + scale-in, replacing the default platform
/// transition with something more polished and consistent everywhere.
class _FluidPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FluidPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInCubic,
      reverseCurve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.02, 0.0),
          ).animate(secondaryCurved),
          child: child,
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIGIPe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF5A623),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _FluidPageTransitionsBuilder(),
            TargetPlatform.iOS: _FluidPageTransitionsBuilder(),
          },
        ),
      ),
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
              );
            },
            child: _buildHomeForState(state),
          );
        },
      ),
    );
  }

  Widget _buildHomeForState(AuthState state) {
    if (state is Authenticated || state is AuthSkipped) {
      return const MainLayoutScreen(key: ValueKey('main'));
    }
    if (state is AuthInitial) {
      return const Scaffold(
        key: ValueKey('loading'),
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }
    return const SignupScreen(key: ValueKey('signup'));
  }
}