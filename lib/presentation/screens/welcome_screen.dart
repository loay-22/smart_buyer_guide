import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.themeController,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  final ThemeController themeController;
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth({required bool isLogin}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      } else {
        await Supabase.instance.client.auth.signUp(email: email, password: password);
      }

      if (!mounted) return;
      setState(() {
        _message = l10n.translate('auth_success');
      });
      context.go('/shop');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = l10n.translate('auth_error');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.themeController.isDark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Exit app?'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Exit')),
            ],
          ),
        );
        if (shouldExit == true) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          final nextLocale = widget.currentLocale.languageCode == 'ar'
                              ? const Locale('en')
                              : const Locale('ar');
                          widget.onLocaleChanged(nextLocale);
                        },
                        icon: const Icon(Icons.language),
                        tooltip: l10n.translate('language'),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: IconButton(
                          key: ValueKey(isDark),
                          onPressed: () async {
                            await widget.themeController.toggleTheme();
                          },
                          icon: Icon(isDark ? Icons.sunny : Icons.nightlight_round),
                          tooltip: l10n.translate('theme'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.translate('login_title'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.translate('login_subtitle'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: l10n.translate('email'),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.translate('email');
                                }
                                if (!value.contains('@')) {
                                  return l10n.translate('email');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: l10n.translate('password'),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.translate('password');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _isSubmitting ? null : () => _submitAuth(isLogin: true),
                              icon: const Icon(Icons.login_rounded),
                              label: Text(l10n.translate('login')),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : () => _submitAuth(isLogin: false),
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: Text(l10n.translate('sign_up')),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _isSubmitting ? null : () => context.go('/shop'),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(l10n.translate('continue_as_guest')),
                            ),
                            if (_message != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _message!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
