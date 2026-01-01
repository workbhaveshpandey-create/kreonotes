import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/theme_cubit.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/services/update_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UpdateService _updateService = UpdateService();
  bool _isCheckingUpdate = false;
  UpdateResult? _updateResult;

  @override
  void initState() {
    super.initState();
    _checkForUpdates(silent: true);
  }

  Future<void> _checkForUpdates({bool silent = false}) async {
    setState(() => _isCheckingUpdate = true);

    final result = await _updateService.checkForUpdates();

    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
        _updateResult = result;
      });

      if (!silent) {
        if (result.available) {
          _showUpdateDialog(result);
        } else if (result.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result.error!)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are on the latest version!')),
          );
        }
      } else if (result.available) {
        // Auto-show update dialog on silent check if update available
        _showUpdateDialog(result);
      }
    }
  }

  void _showUpdateDialog(UpdateResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.system_update, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(
              'Update Available',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${result.latestVersion} is available!',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current: v${result.currentVersion}',
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
            if (result.releaseNotes != null &&
                result.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                "What's New:",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(
                    result.releaseNotes!,
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Later',
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (result.downloadUrl != null) {
                final uri = Uri.parse(result.downloadUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Download',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: AppTextStyles.headlineMedium(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = (authState is AuthAuthenticated) ? authState.user : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section
              if (user != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        child: user.photoUrl == null
                            ? Text(
                                user.email.isNotEmpty
                                    ? user.email[0].toUpperCase()
                                    : 'U',
                                style: AppTextStyles.headlineSmall(
                                  color: Theme.of(context).primaryColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? 'User',
                              style: AppTextStyles.titleMedium(
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              user.email,
                              style: AppTextStyles.bodySmall(
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.logout,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () {
                          context.read<AuthBloc>().add(AuthSignOutRequested());
                          Navigator.pop(context); // Close Settings
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Appearance Section
              Text(
                "Appearance",
                style: AppTextStyles.titleMedium(
                  color: Theme.of(context).primaryColor,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, currentTheme) {
                    return Column(
                      children: [
                        _buildThemeOption(
                          context,
                          title: "System Default",
                          icon: Icons.brightness_auto,
                          value: ThemeMode.system,
                          groupValue: currentTheme,
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        _buildThemeOption(
                          context,
                          title: "Light Mode",
                          icon: Icons.light_mode,
                          value: ThemeMode.light,
                          groupValue: currentTheme,
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        _buildThemeOption(
                          context,
                          title: "Dark Mode",
                          icon: Icons.dark_mode,
                          value: ThemeMode.dark,
                          groupValue: currentTheme,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Updates Section
              Text(
                "Updates",
                style: AppTextStyles.titleMedium(
                  color: Theme.of(context).primaryColor,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: ListTile(
                  leading: _isCheckingUpdate
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : Icon(
                          _updateResult?.available == true
                              ? Icons.system_update
                              : Icons.check_circle,
                          color: _updateResult?.available == true
                              ? Colors.orangeAccent
                              : Colors.greenAccent,
                        ),
                  title: Text(
                    _updateResult?.available == true
                        ? 'Update Available!'
                        : 'Check for Updates',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: _updateResult?.available == true
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: _updateResult?.available == true
                      ? Text(
                          'v${_updateResult!.latestVersion} is available',
                          style: TextStyle(color: Colors.orangeAccent),
                        )
                      : null,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "v${_updateService.currentVersion}",
                      style: AppTextStyles.bodySmall(
                        color: Theme.of(context).primaryColor,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: _isCheckingUpdate
                      ? null
                      : () => _checkForUpdates(silent: false),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
  }) {
    final isSelected = value == groupValue;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Colors.blueAccent
            : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.blueAccent)
          : Icon(Icons.circle_outlined, color: Theme.of(context).disabledColor),
      onTap: () {
        context.read<ThemeCubit>().updateTheme(value);
      },
    );
  }
}
