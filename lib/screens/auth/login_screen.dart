import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _serverCtrl = TextEditingController(text: 'http://ott1.co:8080');
  final _userCtrl = TextEditingController(text: 'umesh905');
  final _passCtrl = TextEditingController(text: '032026');

  final _serverFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  final _btnFocus = FocusNode();

  bool _obscurePass = true;
  bool _loading = false;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _serverFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _serverFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _btnFocus.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final provider = context.read<AppProvider>();
    final ok = await provider.login(
      _serverCtrl.text.trim(),
      _userCtrl.text.trim(),
      _passCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  KeyEventResult _fieldKeyEvent(LogicalKeyboardKey key, FocusNode next) {
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.tab) {
      next.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UhvaColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          return isLandscape
              ? _LandscapeLayout(
                  formKey: _formKey,
                  serverCtrl: _serverCtrl,
                  userCtrl: _userCtrl,
                  passCtrl: _passCtrl,
                  serverFocus: _serverFocus,
                  userFocus: _userFocus,
                  passFocus: _passFocus,
                  btnFocus: _btnFocus,
                  obscurePass: _obscurePass,
                  loading: _loading,
                  glowAnim: _glowAnim,
                  onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
                  onLogin: _login,
                  onFieldKey: _fieldKeyEvent,
                )
              : _PortraitLayout(
                  formKey: _formKey,
                  serverCtrl: _serverCtrl,
                  userCtrl: _userCtrl,
                  passCtrl: _passCtrl,
                  serverFocus: _serverFocus,
                  userFocus: _userFocus,
                  passFocus: _passFocus,
                  btnFocus: _btnFocus,
                  obscurePass: _obscurePass,
                  loading: _loading,
                  glowAnim: _glowAnim,
                  onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
                  onLogin: _login,
                  onFieldKey: _fieldKeyEvent,
                );
        },
      ),
    );
  }
}

// ── Landscape (TV) layout ─────────────────────────────────────────────────────

class _LandscapeLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController serverCtrl, userCtrl, passCtrl;
  final FocusNode serverFocus, userFocus, passFocus, btnFocus;
  final bool obscurePass, loading;
  final Animation<double> glowAnim;
  final VoidCallback onTogglePass, onLogin;
  final KeyEventResult Function(LogicalKeyboardKey, FocusNode) onFieldKey;

  const _LandscapeLayout({
    required this.formKey,
    required this.serverCtrl,
    required this.userCtrl,
    required this.passCtrl,
    required this.serverFocus,
    required this.userFocus,
    required this.passFocus,
    required this.btnFocus,
    required this.obscurePass,
    required this.loading,
    required this.glowAnim,
    required this.onTogglePass,
    required this.onLogin,
    required this.onFieldKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Left brand panel (60%) ─────────────────────────────────────
        Expanded(
          flex: 60,
          child: Stack(
            children: [
              // Background glow
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: glowAnim,
                  builder: (_, __) => CustomPaint(
                    painter: _GlowPainter(glowAnim.value),
                  ),
                ),
              ),
              // Grid lines overlay
              Positioned.fill(
                child: CustomPaint(painter: _GridPainter()),
              ),
              // Brand content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: UhvaColors.primary.withValues(alpha: 0.6),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              color: UhvaColors.primary,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 60),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Brand name
                    const Text(
                      'UHVA',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 10,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'P L A Y E R',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: UhvaColors.primaryLight,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tagline
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: UhvaColors.primary.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(20),
                        color: UhvaColors.primary.withValues(alpha: 0.08),
                      ),
                      child: const Text(
                        'Premium IPTV Entertainment',
                        style: TextStyle(
                          fontSize: 13,
                          color: UhvaColors.onSurfaceMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Feature pills
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        _FeaturePill(
                            icon: Icons.live_tv_rounded,
                            label: 'Live TV',
                            color: Color(0xFFE53935)),
                        SizedBox(width: 12),
                        _FeaturePill(
                            icon: Icons.movie_rounded,
                            label: 'Movies',
                            color: UhvaColors.primary),
                        SizedBox(width: 12),
                        _FeaturePill(
                            icon: Icons.video_library_rounded,
                            label: 'Series',
                            color: Color(0xFF2196F3)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Right form panel (40%) ─────────────────────────────────────
        Expanded(
          flex: 40,
          child: Container(
            decoration: const BoxDecoration(
              color: UhvaColors.surface,
              border: Border(left: BorderSide(color: UhvaColors.divider)),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter your Xtream Codes credentials',
                        style: TextStyle(
                          fontSize: 13,
                          color: UhvaColors.onSurfaceMuted,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _FormContent(
                        formKey: formKey,
                        serverCtrl: serverCtrl,
                        userCtrl: userCtrl,
                        passCtrl: passCtrl,
                        serverFocus: serverFocus,
                        userFocus: userFocus,
                        passFocus: passFocus,
                        btnFocus: btnFocus,
                        obscurePass: obscurePass,
                        loading: loading,
                        onTogglePass: onTogglePass,
                        onLogin: onLogin,
                        onFieldKey: onFieldKey,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'UHVA Player · Thirdsan Enterprises Ltd',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: UhvaColors.onSurfaceHint,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Portrait (phone) layout ───────────────────────────────────────────────────

class _PortraitLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController serverCtrl, userCtrl, passCtrl;
  final FocusNode serverFocus, userFocus, passFocus, btnFocus;
  final bool obscurePass, loading;
  final Animation<double> glowAnim;
  final VoidCallback onTogglePass, onLogin;
  final KeyEventResult Function(LogicalKeyboardKey, FocusNode) onFieldKey;

  const _PortraitLayout({
    required this.formKey,
    required this.serverCtrl,
    required this.userCtrl,
    required this.passCtrl,
    required this.serverFocus,
    required this.userFocus,
    required this.passFocus,
    required this.btnFocus,
    required this.obscurePass,
    required this.loading,
    required this.glowAnim,
    required this.onTogglePass,
    required this.onLogin,
    required this.onFieldKey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: glowAnim,
            builder: (_, __) =>
                CustomPaint(painter: _GlowPainter(glowAnim.value, compact: true)),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: UhvaColors.primary.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            'assets/images/icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: UhvaColors.primary,
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 44),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'UHVA Player',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Premium IPTV Entertainment',
                        style: TextStyle(
                          fontSize: 12,
                          color: UhvaColors.onSurfaceMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: UhvaColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: UhvaColors.divider),
                      ),
                      child: _FormContent(
                        formKey: formKey,
                        serverCtrl: serverCtrl,
                        userCtrl: userCtrl,
                        passCtrl: passCtrl,
                        serverFocus: serverFocus,
                        userFocus: userFocus,
                        passFocus: passFocus,
                        btnFocus: btnFocus,
                        obscurePass: obscurePass,
                        loading: loading,
                        onTogglePass: onTogglePass,
                        onLogin: onLogin,
                        onFieldKey: onFieldKey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'UHVA Player · Thirdsan Enterprises Ltd',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: UhvaColors.onSurfaceHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared form content ───────────────────────────────────────────────────────

class _FormContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController serverCtrl, userCtrl, passCtrl;
  final FocusNode serverFocus, userFocus, passFocus, btnFocus;
  final bool obscurePass, loading;
  final VoidCallback onTogglePass, onLogin;
  final KeyEventResult Function(LogicalKeyboardKey, FocusNode) onFieldKey;

  const _FormContent({
    required this.formKey,
    required this.serverCtrl,
    required this.userCtrl,
    required this.passCtrl,
    required this.serverFocus,
    required this.userFocus,
    required this.passFocus,
    required this.btnFocus,
    required this.obscurePass,
    required this.loading,
    required this.onTogglePass,
    required this.onLogin,
    required this.onFieldKey,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Server URL
          Focus(
            onKeyEvent: (_, ev) {
              if (ev is! KeyDownEvent) return KeyEventResult.ignored;
              return onFieldKey(ev.logicalKey, userFocus);
            },
            child: TextFormField(
              controller: serverCtrl,
              focusNode: serverFocus,
              style: const TextStyle(color: UhvaColors.onBackground),
              decoration: const InputDecoration(
                labelText: 'Server URL',
                labelStyle: TextStyle(color: UhvaColors.onSurfaceMuted),
                hintText: 'http://yourserver.com:8080',
                prefixIcon:
                    Icon(Icons.dns_outlined, color: UhvaColors.onSurfaceMuted),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter server URL' : null,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => userFocus.requestFocus(),
            ),
          ),
          const SizedBox(height: 14),

          // Username
          Focus(
            onKeyEvent: (_, ev) {
              if (ev is! KeyDownEvent) return KeyEventResult.ignored;
              return onFieldKey(ev.logicalKey, passFocus);
            },
            child: TextFormField(
              controller: userCtrl,
              focusNode: userFocus,
              style: const TextStyle(color: UhvaColors.onBackground),
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: UhvaColors.onSurfaceMuted),
                hintText: 'Your username',
                prefixIcon: Icon(Icons.person_outline,
                    color: UhvaColors.onSurfaceMuted),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter username' : null,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => passFocus.requestFocus(),
            ),
          ),
          const SizedBox(height: 14),

          // Password
          Focus(
            onKeyEvent: (_, ev) {
              if (ev is! KeyDownEvent) return KeyEventResult.ignored;
              return onFieldKey(ev.logicalKey, btnFocus);
            },
            child: TextFormField(
              controller: passCtrl,
              focusNode: passFocus,
              obscureText: obscurePass,
              style: const TextStyle(color: UhvaColors.onBackground),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle:
                    const TextStyle(color: UhvaColors.onSurfaceMuted),
                hintText: 'Your password',
                prefixIcon: const Icon(Icons.lock_outline,
                    color: UhvaColors.onSurfaceMuted),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: UhvaColors.onSurfaceMuted,
                  ),
                  onPressed: onTogglePass,
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter password' : null,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onLogin(),
            ),
          ),
          const SizedBox(height: 28),

          // Connect button
          Focus(
            focusNode: btnFocus,
            onKeyEvent: (_, ev) {
              if (ev is! KeyDownEvent) return KeyEventResult.ignored;
              if (ev.logicalKey == LogicalKeyboardKey.select ||
                  ev.logicalKey == LogicalKeyboardKey.enter) {
                onLogin();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: AnimatedBuilder(
              animation: btnFocus,
              builder: (_, __) {
                final focused = btnFocus.hasFocus;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: focused
                        ? [
                            BoxShadow(
                              color: UhvaColors.primary.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    onPressed: loading ? null : onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          focused ? UhvaColors.primaryLight : UhvaColors.primary,
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Connect & Watch',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature pill ──────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ambient glow painter ──────────────────────────────────────────────────────

class _GlowPainter extends CustomPainter {
  final double t;
  final bool compact;
  _GlowPainter(this.t, {this.compact = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Primary purple orb — drifts gently
    final cx1 = size.width * (compact ? 0.5 : 0.38);
    final cy1 = size.height * (0.35 + t * 0.08);
    final r1 = (compact ? size.width * 0.55 : size.width * 0.38) *
        (0.85 + t * 0.15);

    canvas.drawCircle(
      Offset(cx1, cy1),
      r1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF6C63FF).withValues(alpha: 0.18 + t * 0.07),
            const Color(0xFF6C63FF).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx1, cy1), radius: r1)),
    );

    // Secondary blue-violet orb
    final cx2 = size.width * (compact ? 0.7 : 0.62);
    final cy2 = size.height * (0.65 - t * 0.06);
    final r2 = (compact ? size.width * 0.4 : size.width * 0.25) *
        (0.9 + t * 0.1);

    canvas.drawCircle(
      Offset(cx2, cy2),
      r2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF2196F3).withValues(alpha: 0.10 + t * 0.05),
            const Color(0xFF2196F3).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx2, cy2), radius: r2)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t;
}

// ── Subtle perspective grid painter ──────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = UhvaColors.primary.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    const cols = 12;
    const rows = 8;
    final dx = size.width / cols;
    final dy = size.height / rows;

    for (var i = 0; i <= cols; i++) {
      canvas.drawLine(
        Offset(i * dx, 0),
        Offset(i * dx, size.height),
        paint,
      );
    }
    for (var j = 0; j <= rows; j++) {
      canvas.drawLine(
        Offset(0, j * dy),
        Offset(size.width, j * dy),
        paint,
      );
    }

    // Diagonal accent lines
    final accentPaint = Paint()
      ..color = UhvaColors.primary.withValues(alpha: 0.06)
      ..strokeWidth = 0.8;

    for (var i = -rows; i <= cols + rows; i++) {
      canvas.drawLine(
        Offset(i * dx, 0),
        Offset((i - rows) * dx, size.height),
        accentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

