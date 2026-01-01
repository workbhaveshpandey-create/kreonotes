import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Premium Login Screen for Kreo Notes
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo with glow
              Container(
                    width: size.width * 0.3,
                    height: size.width * 0.3,
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
                              size: 64,
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
                style: AppTextStyles.displayMedium(
                  color: Colors.white,
                ).copyWith(letterSpacing: 4, fontWeight: FontWeight.w300),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 12),

              // Tagline
              Text(
                'Your ideas, organized',
                style: AppTextStyles.bodyLarge(color: Colors.white54),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const Spacer(flex: 3),

              // Sign in button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return GestureDetector(
                    onTap: isLoading
                        ? null
                        : () {
                            context.read<AuthBloc>().add(
                              const AuthSignInRequested(),
                            );
                          },
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(0),
                      ),
                      child: isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://www.google.com/favicon.ico',
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.g_mobiledata,
                                      color: Colors.black,
                                      size: 24,
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'CONTINUE WITH GOOGLE',
                                  style: AppTextStyles.labelLarge(
                                    color: Colors.black,
                                  ).copyWith(letterSpacing: 1),
                                ),
                              ],
                            ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
                },
              ),

              const SizedBox(height: 24),

              // Terms
              Text(
                'By continuing, you agree to our Terms of Service',
                style: AppTextStyles.labelSmall(color: Colors.white38),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
