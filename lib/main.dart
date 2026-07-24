import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/screens/bloc/auth_bloc.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/orders_repository.dart';
import 'core/repositories/product_repository.dart';
import 'core/repositories/claims_repository.dart';
import 'core/services/api_service.dart';
import 'core/network/api_client.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/main_layout/screens/main_layout_screen.dart';
import 'features/orders/bloc/orders_bloc.dart';
import 'features/claims/bloc/claims_bloc.dart';
import 'features/product/bloc/product_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';
import 'core/widgets/tampered_device_warning.dart';
import 'core/widgets/splash_screen.dart';
import 'core/utils/error_scrubber.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';

// Geofencing Imports
import 'features/geofencing/services/geofence_api_service.dart';
import 'features/geofencing/services/geofence_event_handler.dart';
import 'features/geofencing/services/geofence_manager.dart';
import 'features/geofencing/services/geofence_notification_handler.dart';
import 'features/geofencing/screens/store_offer_screen.dart';

// Voucher Imports
import 'features/vouchers/services/voucher_service.dart';
import 'features/vouchers/bloc/voucher_bloc.dart';
import 'features/vouchers/bloc/redemption_bloc.dart';


// Hubble SDK Imports
import 'features/vouchers/services/hubble_sdk_service.dart';
import 'features/vouchers/bloc/hubble_bloc.dart';
import 'features/vouchers/screens/hubble_store_screen.dart';

// Global Navigator Key for Deep Linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();
  final prefs = await SharedPreferences.getInstance();

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

  // Geofencing Services
  final geofenceApiService = GeofenceApiService(apiClient.dio);
  final geofenceEventHandler = GeofenceEventHandler(geofenceApiService, prefs);
  final geofenceManager = GeofenceManager(geofenceApiService, geofenceEventHandler);
  final geofenceNotificationHandler = GeofenceNotificationHandler(navigatorKey);

  // Voucher Service
  final voucherService = VoucherService(apiClient.dio);

  // Hubble SDK Service
  final hubbleSdkService = HubbleSdkService(apiClient.dio);

  // Initialize Geofencing & Notifications
  geofenceNotificationHandler.initialize();
  if (!kIsWeb) {
    geofenceManager.initializeTracelet().catchError((e) => debugPrint('Tracelet init failed: $e'));
  }

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

  // Theme cubit — restore saved preference
  final themeCubit = ThemeCubit();
  await themeCubit.init(prefs);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepo),
        RepositoryProvider.value(value: ordersRepo),
        RepositoryProvider.value(value: productRepo),
        RepositoryProvider.value(value: claimsRepo),
        RepositoryProvider<ApiService>.value(value: apiService),
        RepositoryProvider<GeofenceApiService>.value(value: geofenceApiService),
        RepositoryProvider<GeofenceManager>.value(value: geofenceManager),
        RepositoryProvider<GeofenceEventHandler>.value(value: geofenceEventHandler),
        RepositoryProvider<VoucherService>.value(value: voucherService),
        RepositoryProvider<HubbleSdkService>.value(value: hubbleSdkService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>.value(value: themeCubit),
          BlocProvider(
            create: (context) => AuthBloc(authRepository: context.read<AuthRepository>())..add(AuthCheckRequested()),
          ),
          BlocProvider(create: (context) => OrdersBloc(apiService: apiService)),
          BlocProvider(
            create: (context) => ProductBloc(apiService: apiService)..add(LoadProducts()),
          ),
          BlocProvider(
            create: (context) => ClaimsBloc(
              apiService: apiService,
            ),
          ),
          BlocProvider(
            create: (context) => VoucherBloc(voucherService: voucherService),
          ),
          BlocProvider(
            create: (context) => RedemptionBloc(voucherService: voucherService),
          ),
          BlocProvider(
            create: (context) => HubbleBloc(service: hubbleSdkService),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        // Update system UI overlay based on active brightness
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9FAFB),
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp(
          title: 'DIGIPE',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          onGenerateRoute: (settings) {
            if (settings.name == '/store-offer') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => StoreOfferScreen(
                  storeId: args?['storeId'] ?? '',
                  couponId: args?['couponId'],
                ),
              );
            }
            if (settings.name == '/vouchers') {
              return MaterialPageRoute(builder: (_) => const HubbleStoreScreen());
            }
            return null;
          },
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
      },
    );
  }

  Widget _buildHomeForState(AuthState state) {
    if (state is Authenticated || state is AuthSkipped) {
      return const MainLayoutScreen(key: ValueKey('main'));
    }
    if (state is AuthInitial) {
      return const SplashScreen(key: ValueKey('loading'));
    }
    if (state is AuthOnboarding) {
      return const OnboardingScreen(key: ValueKey('onboarding'));
    }
    return const SignupScreen(key: ValueKey('signup'));
  }
}
