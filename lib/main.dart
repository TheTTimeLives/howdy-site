import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// Configurable via --dart-define
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5000',
);
const String kEmailCapturePath = String.fromEnvironment(
  'EMAIL_CAPTURE_PATH',
  defaultValue: '/site/waitlist',
);
// Firebase Web config via --dart-define (no Functions required)
const String kFbApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: '');
const String kFbAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: '');
const String kFbMessagingSenderId = String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID', defaultValue: '');
const String kFbProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
const String kFbStorageBucket = String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET', defaultValue: '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kFbApiKey.isNotEmpty &&
      kFbAppId.isNotEmpty &&
      kFbMessagingSenderId.isNotEmpty &&
      kFbProjectId.isNotEmpty) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: kFbApiKey,
        appId: kFbAppId,
        messagingSenderId: kFbMessagingSenderId,
        projectId: kFbProjectId,
        storageBucket: kFbStorageBucket.isNotEmpty ? kFbStorageBucket : null,
      ),
    );
  }
  // Helpful boot log
  // ignore: avoid_print
  print('Howdy Site starting (Firestore ${kFbProjectId.isNotEmpty ? "enabled" : "disabled"})');
  runApp(const HowdySiteApp());
}

class HowdySiteApp extends StatelessWidget {
  const HowdySiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandPrimary = Color.fromARGB(255, 238, 140, 13); // #EE8C0D
    final colorScheme = ColorScheme.fromSeed(seedColor: brandPrimary, primary: brandPrimary);

    return MaterialApp(
      title: 'Howdy',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: GoogleFonts.interTightTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandPrimary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: brandPrimary, width: 2),
          ),
        ),
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _submitting = false;
  String? _errorText;
  String? _successText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return false;
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    setState(() {
      _errorText = null;
      _successText = null;
    });
    if (!_isValidEmail(email)) {
      setState(() {
        _errorText = 'Please enter a valid email address';
      });
      return;
    }

    // Prefer Firestore direct if Firebase config is provided; otherwise show error
    final canUseFirestore = Firebase.apps.isNotEmpty;
    if (!canUseFirestore) {
      setState(() {
        _errorText = 'Configuration missing. Please try again later.';
      });
      return;
    }

    // ignore: avoid_print
    print('NotifyMe: saving to Firestore (project=$kFbProjectId) email="$email"');
    try {
      setState(() {
        _submitting = true;
      });

      await FirebaseFirestore.instance.collection('waitlist').doc(email).set({
        'email': email,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'source': 'howdy-site-web',
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 12));

      setState(() {
        _successText = 'Thanks! We\'ll be in touch.';
      });
      _emailController.clear();
    } on TimeoutException catch (_) {
      // ignore: avoid_print
      print('NotifyMe: Firestore write timed out');
      setState(() {
        _errorText = 'Request timed out. Please try again.';
      });
    } catch (e) {
      // ignore: avoid_print
      print('NotifyMe: Firestore error: $e');
      setState(() {
        _errorText = 'Something went wrong. Please try again.';
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/howdy2.svg',
                  height: 140,
                  semanticsLabel: 'Howdy Logo',
                ),
                const SizedBox(height: 24),
                Text(
                  'Launching in February 2026',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.interTight(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Drop your email and we\'ll notify you when we launch.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.interTight(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          errorText: _errorText,
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Notify me'),
                    ),
                  ],
                ),
                if (_successText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _successText!,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
