import 'package:dualio/core/l10n/generated/app_localizations.dart';
import 'package:dualio/core/theme/dualio_theme.dart';
import 'package:dualio/features/auth/application/auth_controller.dart';
import 'package:dualio/features/feed/presentation/widgets/feed_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;
    final palette = Theme.of(context).extension<DualioPalette>()!;
    final email = session?.user.email;

    if (session != null) {
      return FeedShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(DualioTheme.mobileMargin, 24, DualioTheme.mobileMargin, 128),
          children: <Widget>[
            Icon(Icons.verified_user_rounded, size: 30, color: palette.muted),
            const SizedBox(height: 16),
            Text(strings.signedInTitle, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(strings.signedInBody, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.muted, fontSize: 14)),
            const SizedBox(height: 22),
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
                border: Border.all(color: palette.outline.withValues(alpha: 0.45)),
              ),
              child: ListTile(
                leading: const Icon(Icons.person_rounded),
                title: Text(email == null ? strings.unknownAccount : strings.signedInAs(email)),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: authState.isLoading ? null : _signOut,
              icon: const Icon(Icons.logout_rounded),
              label: Text(strings.signOut),
            ),
          ],
        ),
      );
    }

    return FeedShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(DualioTheme.mobileMargin, 24, DualioTheme.mobileMargin, 128),
        children: <Widget>[
          Icon(Icons.mail_rounded, size: 30, color: palette.muted),
          const SizedBox(height: 16),
          Text(strings.signInTitle, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(strings.signInBody, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.muted, fontSize: 14)),
          const SizedBox(height: 22),
          if (defaultTargetPlatform == TargetPlatform.iOS) ...<Widget>[
            OutlinedButton.icon(
              onPressed: authState.isLoading ? null : _signInWithApple,
              icon: const Icon(Icons.apple),
              label: Text(strings.continueWithApple),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: authState.isLoading ? null : _signInWithGoogle,
            icon: const Icon(Icons.account_circle_rounded),
            label: Text(strings.continueWithGoogle),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: Divider(color: palette.outline.withValues(alpha: 0.45))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(strings.orSignInWithEmail, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: palette.muted)),
              ),
              Expanded(child: Divider(color: palette.outline.withValues(alpha: 0.45))),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const <String>[AutofillHints.email],
            decoration: InputDecoration(
              labelText: strings.emailAddress,
              hintText: strings.emailHint,
              filled: true,
              fillColor: palette.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DualioTheme.cardRadius)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DualioTheme.cardRadius),
                borderSide: BorderSide(color: palette.outline.withValues(alpha: 0.45)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: authState.isLoading ? null : _sendMagicLink,
            icon: authState.isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            label: Text(strings.sendMagicLink),
          ),
          if (_message != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(_message!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.muted, fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Future<void> _sendMagicLink() async {
    final strings = AppLocalizations.of(context);
    try {
      await ref.read(authControllerProvider.notifier).sendMagicLink(_emailController.text);
      if (!mounted) {
        return;
      }
      setState(() => _message = strings.magicLinkSent);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is AuthConfigurationException ? strings.supabaseNotConfigured : strings.magicLinkFailed;
      setState(() => _message = message);
    }
  }

  Future<void> _signInWithGoogle() async {
    final strings = AppLocalizations.of(context);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      if (!mounted) {
        return;
      }
      setState(() => _message = strings.googleSignInStarted);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is AuthConfigurationException ? strings.supabaseNotConfigured : strings.googleSignInFailed;
      setState(() => _message = message);
    }
  }

  Future<void> _signInWithApple() async {
    final strings = AppLocalizations.of(context);
    try {
      await ref.read(authControllerProvider.notifier).signInWithApple();
      if (!mounted) {
        return;
      }
      setState(() => _message = strings.appleSignInStarted);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is AuthConfigurationException ? strings.supabaseNotConfigured : strings.appleSignInFailed;
      setState(() => _message = message);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _message = AppLocalizations.of(context).supabaseNotConfigured);
    }
  }
}
