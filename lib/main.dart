import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// Configurable via --dart-define
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5000',
);
const String kEmailCapturePath = String.fromEnvironment(
  'EMAIL_CAPTURE_PATH',
  defaultValue: '/site/waitlist',
);
const String kWaitlistUrl = String.fromEnvironment(
  'WAITLIST_URL',
  defaultValue: '',
);

void main() {
  // Helpful boot log
  // ignore: avoid_print
  print('Howdy Site starting with API_BASE_URL=$kApiBaseUrl, EMAIL_CAPTURE_PATH=$kEmailCapturePath');
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

    // Build endpoint robustly to avoid missing slashes
    // Prefer explicit WAITLIST_URL if provided (e.g., Firebase Functions URL)
    final override = kWaitlistUrl.trim();
    final uri = override.isNotEmpty
        ? Uri.parse(override)
        : (() {
            final capture = kEmailCapturePath.trim();
            final isAbsolute = capture.startsWith('http://') || capture.startsWith('https://');
            return isAbsolute
                ? Uri.parse(capture)
                : Uri.parse(kApiBaseUrl).resolve(capture.startsWith('/') ? capture : '/$capture');
          })();

    // ignore: avoid_print
    print('NotifyMe: submitting to $uri with email="$email"');
    try {
      setState(() {
        _submitting = true;
      });

      final response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      // ignore: avoid_print
      print('NotifyMe: response status=${response.statusCode}');
      // ignore: avoid_print
      print('NotifyMe: response body=${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final saved = data['saved'];
          // ignore: avoid_print
          print('NotifyMe: parsed ok, saved=$saved');
        } catch (e) {
          // ignore: avoid_print
          print('NotifyMe: parse ok body failed: $e');
        }
        setState(() {
          _successText = 'Thanks! We\'ll be in touch.';
        });
        _emailController.clear();
      } else {
        String message = 'Something went wrong. Please try again.';
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final err = data['error']?.toString();
          if (err != null && err.isNotEmpty) message = err;
        } catch (_) {}
        setState(() {
          _errorText = '$message (HTTP ${response.statusCode})';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('NotifyMe: network error: $e');
      setState(() {
        _errorText = 'Network error. Please try again.';
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
