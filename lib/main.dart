import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/security_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/crash_reporting_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/app_check_service.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Commented out debug printing
  // AppConfig.printCurrentConfig();
  
  await Firebase.initializeApp();
  await FirebaseService.init();
  
  // Initialize App Check first (security)
  await AppCheckService().initialize();
  
  // Initialize analytics
  await AnalyticsService().initialize();
  
  // Initialize crash reporting
  await CrashReportingService().initialize();
  
  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    CrashReportingService().recordError(
      details.exception,
      stackTrace: details.stack,
      fatal: true,
      customKeys: {
        'error_type': 'flutter_error',
        'environment': AppConfig.environmentName,
      },
    );
  };
  
  // Run security checks before launching
  final security = SecurityService();
  final isRisky = await security.isEnvironmentRisky();

  runApp(
    ProviderScope(
      child: PictoGramApp(showSecurityWarning: isRisky),
    ),
  );
}

class PictoGramApp extends ConsumerStatefulWidget {
  final bool showSecurityWarning;
  const PictoGramApp({super.key, this.showSecurityWarning = false});

  @override
  ConsumerState<PictoGramApp> createState() => _PictoGramAppState();
}

class _PictoGramAppState extends ConsumerState<PictoGramApp> {
  @override
  void initState() {
    super.initState();
    if (widget.showSecurityWarning) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWarning());
    }
  }

  void _showWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Security Warning'),
          ],
        ),
        content: const Text(
          'PictoGram has detected that this device may be rooted or running in an emulator.\n\n'
          'Using PictoGram on a compromised device puts your account and personal data at risk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand, Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final t = ref.watch(appThemeColorsProvider);

    final dynamicTheme = AppTheme.lightTheme.copyWith(
      textTheme: AppTheme.lightTheme.textTheme.apply(
        bodyColor: t.textColor,
        displayColor: t.textColor,
      ),
      iconTheme: IconThemeData(color: t.textColor),
    );

    return MaterialApp.router(
      title: 'PictoGram',
      debugShowCheckedModeBanner: false,
      theme: dynamicTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
