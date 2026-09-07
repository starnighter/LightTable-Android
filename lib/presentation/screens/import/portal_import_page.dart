import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../domain/errors/validation_exception.dart';
import '../../../domain/models/school_source.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/app_controller.dart';
import '../../utils/ui_formatters.dart';

class PortalImportPage extends StatefulWidget {
  const PortalImportPage({
    required this.controller,
    required this.source,
    super.key,
  });

  final AppController controller;
  final SchoolSource source;

  @override
  State<PortalImportPage> createState() => _PortalImportPageState();
}

class _PortalImportPageState extends State<PortalImportPage> {
  late final WebViewController _webViewController;
  String? _script;
  Object? _pageError;
  var _progress = 0;
  var _isImporting = false;
  var _canGoBack = false;
  var _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _pageError = null);
          },
          onPageFinished: (_) => _updateNavigationState(),
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() => _pageError = error);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.source.portalUrl));
    _loadScript();
  }

  Future<void> _loadScript() async {
    try {
      final script = await rootBundle.loadString(widget.source.scriptAsset);
      if (mounted) setState(() => _script = script);
    } catch (error) {
      if (mounted) setState(() => _pageError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.importNewSchedule),
        actions: [
          IconButton(
            tooltip: strings.webBack,
            onPressed: _canGoBack ? _goBack : null,
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          IconButton(
            tooltip: strings.webForward,
            onPressed: _canGoForward ? _goForward : null,
            icon: const Icon(Icons.arrow_forward_ios),
          ),
          IconButton(
            tooltip: strings.webRefresh,
            onPressed: _webViewController.reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_pageError != null)
                  ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_outlined, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              strings.webPageLoadFailed,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _webViewController.reload,
                              icon: const Icon(Icons.refresh),
                              label: Text(strings.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.portalImportHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.privacyHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    key: const Key('run-import-button'),
                    onPressed: _isImporting || _script == null ? null : _import,
                    icon: _isImporting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_outlined),
                    label: Text(
                      _isImporting ? strings.importing : strings.runImport,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateNavigationState() async {
    final canGoBack = await _webViewController.canGoBack();
    final canGoForward = await _webViewController.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
  }

  Future<void> _goBack() async {
    await _webViewController.goBack();
    await _updateNavigationState();
  }

  Future<void> _goForward() async {
    await _webViewController.goForward();
    await _updateNavigationState();
  }

  Future<void> _import() async {
    final script = _script;
    if (script == null) return;
    setState(() => _isImporting = true);
    try {
      final result = await _webViewController.runJavaScriptReturningResult(
        script,
      );
      if (result is! String) {
        throw const ValidationException('网页没有返回可识别的课表数据');
      }
      await widget.controller.importScheduleResult(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).importSucceeded)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context).importFailed),
          content: Text(
            '${AppLocalizations.of(context).importPageRequired}\n\n'
            '${UiFormatters.error(error)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      );
    }
  }
}
