import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//  ICON ENUM
// ══════════════════════════════════════════════════════════════
enum OnboardingIcon {
  weather,
  route,
  angkot,
  heatmap,
  prediction,
  traffic,
  notification,
}

// ══════════════════════════════════════════════════════════════
//  ONBOARDING STEP MODEL
// ══════════════════════════════════════════════════════════════
class OnboardingStep {
  final GlobalKey targetKey;
  final OnboardingIcon icon;
  final String title;
  final String description;
  final EdgeInsets padding;

  const OnboardingStep({
    required this.targetKey,
    required this.icon,
    required this.title,
    required this.description,
    this.padding = const EdgeInsets.all(8),
  });
}

// ══════════════════════════════════════════════════════════════
//  SPOTLIGHT PAINTER
// ══════════════════════════════════════════════════════════════
class _SpotlightPainter extends CustomPainter {
  final Rect spotRect;
  final double cornerRadius;
  final double dimOpacity;

  const _SpotlightPainter({
    required this.spotRect,
    required this.cornerRadius,
    required this.dimOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(spotRect, Radius.circular(cornerRadius)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF0B1437).withOpacity(dimOpacity),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        spotRect.inflate(1.5),
        Radius.circular(cornerRadius + 1),
      ),
      Paint()
        ..color = Colors.white.withOpacity(0.70 * (dimOpacity / 0.72))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.spotRect != spotRect || old.dimOpacity != dimOpacity;
}

// ══════════════════════════════════════════════════════════════
//  ICON BADGE
// ══════════════════════════════════════════════════════════════
class _IconBadge extends StatelessWidget {
  final OnboardingIcon icon;
  const _IconBadge(this.icon);

  @override
  Widget build(BuildContext context) {
    final (iconData, iconColor, bgColor) = _resolve(icon);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }

  static (IconData, Color, Color) _resolve(OnboardingIcon icon) {
    switch (icon) {
      case OnboardingIcon.weather:
        return (
          Icons.wb_cloudy_outlined,
          const Color(0xFF38BDF8),
          const Color(0xFFE0F2FE),
        );
      case OnboardingIcon.route:
        return (
          Icons.alt_route_rounded,
          const Color(0xFF3B82F6),
          const Color(0xFFDBEAFE),
        );
      case OnboardingIcon.angkot:
        return (
          Icons.directions_bus_rounded,
          const Color(0xFF0EA5E9),
          const Color(0xFFE0F2FE),
        );
      case OnboardingIcon.heatmap:
        return (
          Icons.grid_view_rounded,
          const Color(0xFF16A34A),
          const Color(0xFFDCFCE7),
        );
      case OnboardingIcon.prediction:
        return (
          Icons.schedule_rounded,
          const Color(0xFFEA580C),
          const Color(0xFFFED7AA),
        );
      case OnboardingIcon.traffic:
        return (
          Icons.show_chart_rounded,
          const Color(0xFF7C3AED),
          const Color(0xFFEDE9FE),
        );
      case OnboardingIcon.notification:
        return (
          Icons.notifications_none_outlined,
          const Color(0xFFDC2626),
          const Color(0xFFFEE2E2),
        );
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  POPOVER CARD
// ══════════════════════════════════════════════════════════════
class _PopoverCard extends StatelessWidget {
  final int current;
  final int total;
  final OnboardingIcon icon;
  final String title;
  final String description;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool isLast;

  const _PopoverCard({
    required this.current,
    required this.total,
    required this.icon,
    required this.title,
    required this.description,
    required this.onNext,
    required this.onSkip,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E40AF).withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Row(
                children: [
                  _IconBadge(icon),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Langkah $current dari $total',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Deskripsi
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF475569),
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: current / total,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
            // Tombol aksi
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onSkip,
                    child: const Text(
                      'Lewati',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLast ? 'Selesai' : 'Lanjut',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  MAIN ONBOARDING OVERLAY
//  Fix: menggunakan OverlayEntry agar bisa di-remove bersih
//  sehingga tidak ada layer yang tersisa yang menghalangi
//  scroll/tap setelah onboarding selesai.
// ══════════════════════════════════════════════════════════════
class OnboardingOverlay extends StatefulWidget {
  final List<OnboardingStep> steps;
  final VoidCallback onFinished;

  const OnboardingOverlay({
    super.key,
    required this.steps,
    required this.onFinished,
  });

  /// Tampilkan onboarding overlay menggunakan [OverlayEntry].
  /// Cara ini lebih bersih daripada [showGeneralDialog] karena
  /// entry benar-benar dihapus dari Overlay tree saat selesai,
  /// sehingga tidak ada layer transparan yang tersisa.
  static void show({
    required BuildContext context,
    required List<OnboardingStep> steps,
    required VoidCallback onFinished,
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => OnboardingOverlay(
        steps: steps,
        onFinished: () {
          entry.remove();
          onFinished();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with TickerProviderStateMixin {
  int _index = 0;
  Rect? _spot;

  late AnimationController _dimCtrl;
  late Animation<double> _dimAnim;

  late AnimationController _popCtrl;
  late Animation<double> _popAnim;

  @override
  void initState() {
    super.initState();

    _dimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _dimAnim = CurvedAnimation(parent: _dimCtrl, curve: Curves.easeOut);

    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _popAnim = CurvedAnimation(parent: _popCtrl, curve: Curves.easeOutBack);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _goTo(0);
      });
    });
  }

  @override
  void dispose() {
    _dimCtrl.dispose();
    _popCtrl.dispose();
    super.dispose();
  }

  Rect? _getRenderRect(GlobalKey key, EdgeInsets padding) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    return Rect.fromLTWH(
      pos.dx - padding.left,
      pos.dy - padding.top,
      size.width + padding.left + padding.right,
      size.height + padding.top + padding.bottom,
    );
  }

  void _goTo(int i) {
    if (i >= widget.steps.length) {
      _dismiss();
      return;
    }
    final step = widget.steps[i];
    Rect? rect = _getRenderRect(step.targetKey, step.padding);
    if (rect == null) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        final r = _getRenderRect(step.targetKey, step.padding);
        if (r != null) _applyStep(i, r);
      });
      return;
    }
    _applyStep(i, rect);
  }

  void _applyStep(int i, Rect rect) {
    if (!mounted) return;
    setState(() {
      _index = i;
      _spot = rect;
    });
    _popCtrl.reset();
    _dimCtrl.forward();
    _popCtrl.forward();
  }

  void _next() => _popCtrl.reverse().then((_) => _goTo(_index + 1));

  void _dismiss() {
    _dimCtrl.reverse().then((_) {
      if (mounted) widget.onFinished();
    });
  }

  Offset _popoverPos(Rect spot, Size screen) {
    const cardW = 260.0;
    const cardH = 210.0;
    const gap = 14.0;
    const hMargin = 16.0;

    double left = spot.left + spot.width / 2 - cardW / 2;
    left = left.clamp(hMargin, screen.width - cardW - hMargin);

    final belowFits = spot.bottom + gap + cardH < screen.height - 60;
    final aboveFits = spot.top - gap - cardH > 60;

    double top;
    if (belowFits) {
      top = spot.bottom + gap;
    } else if (aboveFits) {
      top = spot.top - cardH - gap;
    } else {
      top = 60.0;
    }
    top = top.clamp(60.0, screen.height - cardH - 20);

    return Offset(left, top);
  }

  @override
  Widget build(BuildContext context) {
    if (_spot == null) return const SizedBox.shrink();

    final screen = MediaQuery.of(context).size;
    final popPos = _popoverPos(_spot!, screen);
    final step = widget.steps[_index];
    final isLast = _index == widget.steps.length - 1;

    return AnimatedBuilder(
      animation: Listenable.merge([_dimAnim, _popAnim]),
      builder: (_, __) {
        final dim = _dimAnim.value;
        final pop = _popAnim.value.clamp(0.0, 1.0);

        // Jika animasi dim sudah 0 (selesai dismiss), jangan render apapun
        // agar tidak ada layer yang menghalangi interaksi
        if (dim == 0.0 && _dimCtrl.status == AnimationStatus.dismissed) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // ── Overlay gelap + spotlight ──────────────────
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _next,
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    spotRect: _spot!,
                    cornerRadius: 18,
                    dimOpacity: 0.72 * dim,
                  ),
                ),
              ),
            ),

            // ── Popover card ───────────────────────────────
            Positioned(
              left: popPos.dx,
              top: popPos.dy,
              child: Opacity(
                opacity: pop,
                child: Transform.translate(
                  offset: Offset(0, (1 - pop) * 14),
                  child: _PopoverCard(
                    current: _index + 1,
                    total: widget.steps.length,
                    icon: step.icon,
                    title: step.title,
                    description: step.description,
                    onNext: _next,
                    onSkip: _dismiss,
                    isLast: isLast,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
