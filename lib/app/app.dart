import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme/app_theme.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/pages/data/page_repository.dart';
import '../features/pages/presentation/bloc/pages_bloc.dart';
import '../features/pages/presentation/bloc/pages_event.dart';
import '../features/pages/presentation/bloc/pages_state.dart';
import '../features/pages/presentation/screens/home_screen.dart';
import 'theme/theme_cubit.dart';

/// Kreo Notes App
/// Premium dark note-taking application
class KreoNotesApp extends StatelessWidget {
  const KreoNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => PageRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>())
                  ..add(const AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) =>
                PagesBloc(pageRepository: context.read<PageRepository>()),
          ),
          BlocProvider(create: (context) => ThemeCubit()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'Kreo Notes',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              themeAnimationDuration: const Duration(milliseconds: 300),
              themeAnimationCurve: Curves.easeInOut,
              home: const _AuthWrapper(),
            );
          },
        ),
      ),
    );
  }
}

/// Handles authentication state and navigation
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Handle unauthenticated state
        if (authState is AuthUnauthenticated) {
          return const LoginScreen(key: ValueKey('login'));
        }

        // Handle authenticated state
        if (authState is AuthAuthenticated) {
          // Load pages for the user
          final pagesBloc = context.read<PagesBloc>();
          if (pagesBloc.state is PagesInitial) {
            pagesBloc.add(PagesLoadRequested(authState.user.uid));
          }

          return BlocBuilder<PagesBloc, PagesState>(
            builder: (context, pagesState) {
              if (pagesState is PagesLoaded) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: HomeScreen(key: const ValueKey('home')),
                );
              } else if (pagesState is PagesError) {
                return Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Something went wrong",
                            style: AppTextStyles.headlineSmall(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pagesState.message,
                            style: AppTextStyles.bodyMedium(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              context.read<PagesBloc>().add(
                                PagesLoadRequested(authState.user.uid),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Show splash while pages are loading
              return const _PremiumSplashScreen(
                key: ValueKey('splash'),
                status: 'Loading notes...',
              );
            },
          );
        }

        // Default: show splash
        return const _PremiumSplashScreen(
          key: ValueKey('splash'),
          status: 'Loading notes...',
        );
      },
    );
  }
}

/// Premium Splash Screen with Animated Loading Bar
class _PremiumSplashScreen extends StatefulWidget {
  final String status;
  const _PremiumSplashScreen({super.key, required this.status});

  @override
  State<_PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<_PremiumSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with glow
            Container(
                  width: size.width * 0.25,
                  height: size.width * 0.25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/kreonotes_logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.note_alt_outlined,
                            size: 48,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 32),

            // App Name
            Text(
              'KREO NOTES',
              style: AppTextStyles.headlineLarge(
                color: Colors.white,
              ).copyWith(letterSpacing: 6, fontWeight: FontWeight.w300),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 48),

            // Premium Progress Bar
            SizedBox(
              width: size.width * 0.5,
              child: Column(
                children: [
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(1),
                    ),
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    widget.status.toUpperCase(),
                    style: AppTextStyles.labelSmall(
                      color: Colors.white38,
                    ).copyWith(letterSpacing: 2),
                  ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
