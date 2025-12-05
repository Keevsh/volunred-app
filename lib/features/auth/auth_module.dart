import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/auth_repository.dart';
import 'bloc/auth_bloc.dart';
import 'pages/login_page.dart';
import 'pages/login_page_desktop.dart';
import 'pages/register_page.dart';
import 'pages/welcome_page.dart';

class AuthModule extends Module {
  @override
  List<Bind> get binds => [Bind.factory((i) => AuthBloc(i<AuthRepository>()))];

  @override
  List<ModularRoute> get routes => [
    ChildRoute(
      '/',
      child: (_, __) => BlocProvider(
        create: (_) => Modular.get<AuthBloc>(),
        child: const _LoginPageAdaptive(),
      ),
    ),
    ChildRoute(
      '/welcome',
      child: (_, __) => const WelcomePage(),
    ),
    ChildRoute(
      '/login',
      child: (_, __) => BlocProvider(
        create: (_) => Modular.get<AuthBloc>(),
        child: const _LoginPageAdaptive(),
      ),
    ),
    ChildRoute(
      '/register',
      child: (_, __) => BlocProvider(
        create: (_) => Modular.get<AuthBloc>(),
        child: const RegisterPage(),
      ),
    ),
  ];
}

/// Selecciona el login según el tamaño de pantalla:
/// - Desktop: layout dividido moderno
/// - Mobile/Tablet: layout original vertical
class _LoginPageAdaptive extends StatelessWidget {
  const _LoginPageAdaptive();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // mismo breakpoint que ResponsiveLayout: desktop > 1100
    final isDesktop = width >= 1100;

    if (isDesktop) return const LoginPageDesktop();
    return const LoginPage();
  }
}
