import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth/auth_bloc.dart';
import '../theme.dart';

const _sun = Color(0xFFE8A33D);

/// Animated splash: the tent draws itself, the sun rises behind it and
/// the name slides in. Leaves once the animation ends and the session
/// is known.
class SplashView extends StatefulWidget {
  const SplashView({super.key, this.from});

  /// Deep link to open after the splash, if any.
  final String? from;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final Animation<double> ground = _curve(0.0, 0.30, Curves.easeOut);
  late final Animation<double> tent = _curve(0.08, 0.50, Curves.easeInOut);
  late final Animation<double> sun = _curve(0.30, 0.72, Curves.easeOutBack);
  late final Animation<double> title = _curve(0.50, 0.80, Curves.easeOut);
  late final Animation<double> tagline = _curve(0.66, 0.92, Curves.easeOut);
  late final Animation<double> loader = _curve(0.75, 1.0, Curves.easeInOut);

  Animation<double> _curve(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: controller,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  void initState() {
    super.initState();
    unawaited(_play());
  }

  Future<void> _play() async {
    try {
      await controller.forward().orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    final auth = context.read<AuthBloc>();
    var state = auth.state;
    if (state is AuthInitial || state is AuthLoading) {
      state = await auth.stream
          .firstWhere((s) => s is! AuthInitial && s is! AuthLoading)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => AuthUnauthenticated(),
          );
    }
    if (!mounted) return;
    final from = widget.from;
    if (from != null && from.isNotEmpty) {
      context.go(Uri.decodeComponent(from));
    } else {
      context.goNamed(state is AuthAuthenticated ? 'explore' : 'welcome');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                warmWhite,
                Color.lerp(warmWhite, softGreen, sun.value.clamp(0, 1))!,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 220,
                    height: 190,
                    child: CustomPaint(
                      painter: _CampScene(
                        ground: ground.value,
                        tent: tent.value,
                        sun: sun.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: title.value,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - title.value)),
                      child: Column(
                        children: [
                          Text(
                            'CAMPREADY',
                            style: TextStyle(
                              fontSize: 12,
                              color: forest,
                              letterSpacing: lerpDouble(8, 2, title.value),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'CampReady',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: tagline.value,
                    child: const Text(
                      'Know what to expect before you camp.',
                      style: TextStyle(color: muted),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 120,
                    child: Opacity(
                      opacity: loader.value,
                      child: LinearProgressIndicator(
                        value: loader.value,
                        minHeight: 3,
                        color: forest,
                        backgroundColor: outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampScene extends CustomPainter {
  _CampScene({required this.ground, required this.tent, required this.sun});

  final double ground;
  final double tent;
  final double sun;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final base = h * 0.86;
    final stroke = Paint()
      ..color = forest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Sun rising behind the tent, hidden below the ground line.
    if (sun > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, w, base));
      final center = Offset(w * 0.72, base + 30 - 110 * sun);
      canvas.drawCircle(
        center,
        44,
        Paint()
          ..color = _sun.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.drawCircle(center, 30, Paint()..color = _sun);
      canvas.restore();
    }

    // Ground line grows out from the middle.
    final half = w * 0.5 * ground;
    canvas.drawLine(
      Offset(w / 2 - half, base),
      Offset(w / 2 + half, base),
      stroke,
    );

    // Tent outline, pole and door drawn in order.
    final left = w * 0.18, right = w * 0.82, top = h * 0.08;
    final apex = Offset(w / 2, top);
    final path = Path()
      ..moveTo(left, base)
      ..lineTo(apex.dx, apex.dy)
      ..lineTo(right, base)
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(apex.dx, base)
      ..moveTo(apex.dx, top + (base - top) * 0.42)
      ..lineTo(w * 0.66, base);
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * tent;
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final length = remaining.clamp(0, metric.length).toDouble();
      canvas.drawPath(metric.extractPath(0, length), stroke);
      remaining -= metric.length;
    }
  }

  @override
  bool shouldRepaint(_CampScene old) =>
      old.ground != ground || old.tent != tent || old.sun != sun;
}
