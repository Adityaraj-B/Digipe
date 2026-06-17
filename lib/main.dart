import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/bloc/auth_bloc.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/orders_repository.dart';
import 'core/repositories/product_repository.dart';
import 'core/repositories/claims_repository.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/main_layout/presentation/screens/main_layout_screen.dart';
import 'features/orders/bloc/orders_bloc.dart';
import 'features/claims/bloc/claims_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthBloc(repository: authRepo)),
          BlocProvider(create: (context) => OrdersBloc(repository: ordersRepo)),
          BlocProvider(
            create: (context) => ProductBloc(repository: productRepo)..add(LoadProductDetails()),
          ),
          BlocProvider(
            create: (context) => ClaimsBloc(
              claimsRepository: claimsRepo,
              ordersRepository: ordersRepo,
            ),
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
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthInitial) {
            return const SignupScreen();
          }
          return const MainLayoutScreen();
        },
      ),
    );
  }
}
