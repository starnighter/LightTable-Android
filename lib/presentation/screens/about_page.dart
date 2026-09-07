import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/generated/app_localizations.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.about)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 132,
                  height: 132,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.appTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const _VersionText(),
            const SizedBox(height: 28),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.balance_outlined),
                    title: Text(strings.license),
                    subtitle: Text(strings.licenseName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const _LicensePage(),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(strings.originalAuthor),
                    subtitle: Text(strings.originalAuthorValue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings.derivedProject,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              strings.copyrightText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LicensePage extends StatelessWidget {
  const _LicensePage();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.license)),
      body: const _LicenseBody(),
    );
  }
}

class _VersionText extends StatefulWidget {
  const _VersionText();

  @override
  State<_VersionText> createState() => _VersionTextState();
}

class _VersionTextState extends State<_VersionText> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return FutureBuilder<PackageInfo>(
      future: _packageInfo,
      builder: (context, snapshot) {
        final info = snapshot.data;
        final value = snapshot.connectionState != ConnectionState.done
            ? '…'
            : info == null
            ? '—'
            : '${info.version} (${info.buildNumber})';
        return Text(
          strings.version(value),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        );
      },
    );
  }
}

class _LicenseBody extends StatefulWidget {
  const _LicenseBody();

  @override
  State<_LicenseBody> createState() => _LicenseBodyState();
}

class _LicenseBodyState extends State<_LicenseBody> {
  late final Future<String> _license = rootBundle.loadString('LICENSE');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _license,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              snapshot.data!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}
