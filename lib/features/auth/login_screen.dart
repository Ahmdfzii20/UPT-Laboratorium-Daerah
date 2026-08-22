import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider).signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Redirect otomatis oleh go_router berdasarkan role.
    } on FirebaseAuthException catch (e) {
      final pesan = switch (e.code) {
        'invalid-credential' || 'user-not-found' || 'wrong-password' =>
          'Email atau password salah.',
        'user-disabled' => 'Akun dinonaktifkan.',
        'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
        _ => 'Gagal masuk: ${e.message ?? e.code}',
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pesan),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 162, 196, 215),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final contentWidth = wide
              ? (constraints.maxWidth - 48).clamp(0.0, 1080.0)
              : constraints.maxWidth - 48;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: contentWidth,
                  child: wide
                      ? Row(
                          // SingleChildScrollView vertikal memberikan tinggi
                          // tak terbatas. `stretch` membutuhkan tinggi terukur
                          // dan dapat membuat anak Row tidak memiliki ukuran.
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildWelcomePanel()),
                            Expanded(child: _buildLoginPanel()),
                          ],
                        )
                      : _buildLoginPanel(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomePanel() {
    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        color: Color(0xF7FFFFFF),
        borderRadius: BorderRadius.horizontal(left: Radius.circular(22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              _buildWelcomeIllustration(),
              const SizedBox(height: 32),
          Text(
            'Lapor Lab',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sistem Pelaporan Laboratorium\nKesehatan Daerah\nDeli Serdang',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 18),
          Text(
            'Kelola laporan pemeriksaan puskesmas secara cepat, rapi, dan terintegrasi.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeIllustration() {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 190,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFD5EBF7),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF7FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.key, color: AppTheme.primary, size: 30),
            ),
          ),
          const Icon(Icons.person_outline, color: AppTheme.primary, size: 110),
          Positioned(
            right: 34,
            bottom: 18,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 4),
              ),
              child: const Icon(Icons.lock_outline, color: AppTheme.primary, size: 46),
            ),
          ),
          Positioned(
            left: 28,
            top: 18,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA9D2EA), width: 2),
              ),
              child: const Icon(Icons.password, color: AppTheme.primary, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPanel() {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.horizontal(right: Radius.circular(22)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selamat Datang',
              style: textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masuk ke akun Anda untuk melanjutkan',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 36),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Email institusi',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Email tidak valid'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan password',
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Password wajib diisi'
                  : null,
              onFieldSubmitted: (_) => _login(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading ? null : () => context.go('/forgot-password'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Lupa Password?'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _login,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF4B41A),
                  foregroundColor: AppTheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Masuk', style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(width: 8),
                          Icon(Icons.login, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '© 2026 Laboratorium Kesehatan Daerah',
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
