import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

// 10 MB test file from Cloudflare's speed test infrastructure
const _kTestUrl =
    'https://speed.cloudflare.com/__down?bytes=10000000';
const _kTestBytes = 10000000;

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

enum _TestState { idle, running, done, error }

class _SpeedTestScreenState extends State<SpeedTestScreen>
    with SingleTickerProviderStateMixin {
  _TestState _state = _TestState.idle;
  double _mbps = 0;
  double _progress = 0;
  String _error = '';

  late AnimationController _needleCtrl;
  late Animation<double> _needleAnim;
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  @override
  void initState() {
    super.initState();
    _needleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _needleAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _needleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _needleCtrl.dispose();
    _dio.close(force: true);
    super.dispose();
  }

  void _animateTo(double mbps) {
    final prev = _needleAnim.value;
    _needleAnim = Tween<double>(begin: prev, end: mbps).animate(
      CurvedAnimation(parent: _needleCtrl, curve: Curves.easeOut),
    );
    _needleCtrl.forward(from: 0);
  }

  Future<void> _runTest() async {
    setState(() {
      _state = _TestState.running;
      _mbps = 0;
      _progress = 0;
      _error = '';
    });
    _animateTo(0);

    final stopwatch = Stopwatch()..start();
    int received = 0;

    try {
      await _dio.get<ResponseBody>(
        _kTestUrl,
        options: Options(responseType: ResponseType.stream),
      ).then((resp) async {
        await for (final chunk in resp.data!.stream) {
          received += chunk.length;
          final elapsed = stopwatch.elapsed.inMilliseconds;
          if (elapsed > 0) {
            final mbps = (received * 8) / (elapsed / 1000.0) / 1e6;
            _animateTo(mbps.clamp(0, 1000));
            setState(() {
              _mbps = mbps;
              _progress = (received / _kTestBytes).clamp(0.0, 1.0);
            });
          }
        }
      });
      final totalMs = stopwatch.elapsedMilliseconds;
      final finalMbps = totalMs > 0
          ? (received * 8) / (totalMs / 1000.0) / 1e6
          : 0.0;
      _animateTo(finalMbps.clamp(0, 1000));
      setState(() {
        _mbps = finalMbps;
        _progress = 1.0;
        _state = _TestState.done;
      });
    } catch (e) {
      setState(() {
        _state = _TestState.error;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speed Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _needleAnim,
                builder: (_, __) => _SpeedometerDial(mbps: _needleAnim.value),
              ),
              const SizedBox(height: 8),
              _SpeedLabel(mbps: _mbps, state: _state),
              const SizedBox(height: 32),
              if (_state == _TestState.running)
                Column(children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: UhvaColors.card,
                    color: UhvaColors.primary,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}% — downloading ${(_kTestBytes / 1e6).toStringAsFixed(0)} MB test file',
                    style: const TextStyle(
                        fontSize: 11, color: UhvaColors.onSurfaceMuted),
                  ),
                ]),
              if (_state == _TestState.error)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12, color: UhvaColors.liveRed)),
                ),
              const SizedBox(height: 24),
              if (_state != _TestState.running)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: UhvaColors.primary,
                    minimumSize: const Size(200, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.speed),
                  label: Text(
                    _state == _TestState.idle ? 'Start Test' : 'Test Again',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: _runTest,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Speedometer dial ──────────────────────────────────────────────────────────

class _SpeedometerDial extends StatelessWidget {
  final double mbps;
  const _SpeedometerDial({required this.mbps});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 170,
      child: CustomPaint(painter: _DialPainter(mbps: mbps)),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double mbps;
  const _DialPainter({required this.mbps});

  // Max displayed on gauge = 500 Mbps (covers 99% of real-world scenarios)
  static const double _maxMbps = 500;

  // Arc goes from 200° to -20° (220° sweep, semicircle + a bit)
  static const double _startAngle = pi * (200 / 180);
  static const double _sweepAngle = pi * (220 / 180);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.88;
    final radius = size.width * 0.44;

    // Background arc track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF181832);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      _startAngle,
      _sweepAngle,
      false,
      trackPaint,
    );

    // Speed arc (colored)
    final fraction = (mbps / _maxMbps).clamp(0.0, 1.0);
    if (fraction > 0) {
      final speedPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00E5FF)],
        ).createShader(Rect.fromCircle(
            center: Offset(cx, cy), radius: radius));
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        _startAngle,
        _sweepAngle * fraction,
        false,
        speedPaint,
      );
    }

    // Tick marks
    final tickPaint = Paint()
      ..color = const Color(0xFF2A2A4A)
      ..strokeWidth = 1.5;
    final labels = [0, 50, 100, 200, 300, 500];
    for (final label in labels) {
      final f = label / _maxMbps;
      final angle = _startAngle + _sweepAngle * f;
      final outerX = cx + cos(angle) * (radius + 8);
      final outerY = cy + sin(angle) * (radius + 8);
      final innerX = cx + cos(angle) * (radius - 8);
      final innerY = cy + sin(angle) * (radius - 8);
      canvas.drawLine(
          Offset(innerX, innerY), Offset(outerX, outerY), tickPaint);
    }

    // Needle
    final needleAngle = _startAngle + _sweepAngle * fraction;
    final needleLen = radius * 0.78;
    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + cos(needleAngle) * needleLen,
          cy + sin(needleAngle) * needleLen),
      needlePaint,
    );

    // Centre dot
    canvas.drawCircle(Offset(cx, cy), 6,
        Paint()..color = UhvaColors.primary);
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.mbps != mbps;
}

// ── Speed label ───────────────────────────────────────────────────────────────

class _SpeedLabel extends StatelessWidget {
  final double mbps;
  final _TestState state;

  const _SpeedLabel({required this.mbps, required this.state});

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      _TestState.idle  => 'Ready',
      _TestState.error => 'Error',
      _         => '${mbps.toStringAsFixed(1)} Mbps',
    };
    final sub = switch (state) {
      _TestState.idle  => 'Tap Start Test to measure your download speed',
      _TestState.running => _rating(mbps),
      _TestState.done  => _rating(mbps),
      _TestState.error => '',
    };

    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: UhvaColors.onBackground)),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: UhvaColors.onSurfaceMuted)),
        ],
      ],
    );
  }

  String _rating(double mbps) {
    if (mbps < 5)  return 'Poor — buffering likely';
    if (mbps < 15) return 'OK — HD streaming possible';
    if (mbps < 50) return 'Good — Full HD & 4K streaming';
    return 'Excellent — Ultra HD with ease';
  }
}
