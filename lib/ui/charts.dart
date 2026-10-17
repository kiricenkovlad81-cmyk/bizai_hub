import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/parser.dart';
import '../theme.dart';

/// Bar chart of paid revenue by hour, 08:00–22:00, current hour highlighted.
class HourChart extends StatelessWidget {
  const HourChart({super.key, required this.values, required this.current, required this.kLabel});
  final List<int> values;
  final int current;
  final String kLabel;

  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth.isFinite ? cons.maxWidth : 600.0;
        final h = w < 480 ? 200.0 : 230.0;
        return SizedBox(
          width: w,
          height: h,
          child: CustomPaint(painter: _HourPainter(values, current, b, kLabel)),
        );
      },
    );
  }
}

class _HourPainter extends CustomPainter {
  _HourPainter(this.vals, this.cur, this.b, this.kLabel);
  final List<int> vals;
  final int cur;
  final Biz b;
  final String kLabel;

  double _niceStep(double raw) {
    final p = pow(10, (log(max(raw, 1)) / ln10).floor()).toDouble();
    final n = raw / p;
    return (n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10) * p;
  }

  String _k(double v) {
    if (v == 0) return '0';
    if (v >= 1000) return '${fmtNum(v / 1000)} $kLabel';
    return fmtNum(v);
  }

  void _text(Canvas c, String s, Offset at, TextStyle st, {TextAlign align = TextAlign.left, Color? halo}) {
    final tp = TextPainter(text: TextSpan(text: s, style: st), textDirection: TextDirection.ltr)..layout();
    var dx = at.dx;
    if (align == TextAlign.right) dx -= tp.width;
    if (align == TextAlign.center) dx -= tp.width / 2;
    final dy = at.dy - tp.height / 2;
    if (halo != null) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(dx - 4, dy - 1, tp.width + 8, tp.height + 2), const Radius.circular(4));
      c.drawRRect(r, Paint()..color = halo);
    }
    tp.paint(c, Offset(dx, dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final padL = w < 480 ? 46.0 : 56.0, padR = 6.0, padT = 26.0, padB = 26.0;
    final maxV = max(1000, vals.fold<int>(0, max)).toDouble();
    final step = _niceStep(maxV * 1.12 / 4);
    final top = (maxV * 1.12 / step).ceil() * step;
    final iw = w - padL - padR, ih = h - padT - padB;
    final bw = iw / 15;
    final gap = min(10.0, max(3.0, bw * .3));
    double y(double v) => padT + ih - v / top * ih;

    final grid = Paint()
      ..color = b.line
      ..strokeWidth = 1;
    final axisStyle = tMono(10.5, b.ink3);
    for (double v = 0; v <= top + 1; v += step) {
      final yy = y(v);
      if (v == 0) {
        canvas.drawLine(Offset(padL, yy), Offset(w - padR, yy), Paint()..color = b.lineStrong);
      } else {
        for (double x = padL; x < w - padR; x += 6) {
          canvas.drawLine(Offset(x, yy), Offset(min(x + 2, w - padR), yy), grid);
        }
      }
      _text(canvas, _k(v), Offset(padL - 8, yy), axisStyle, align: TextAlign.right);
    }

    final every = bw < 30 ? 2 : 1;
    for (var i = 0; i < 15; i++) {
      final x = padL + i * bw + gap / 2, bwid = bw - gap;
      if (i <= cur) {
        final bh = max(2.0, vals[i] / top * ih);
        final r = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, padT + ih - bh, bwid, bh),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        );
        canvas.drawRRect(r, Paint()..color = i == cur ? b.accent : b.accentLine);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, padT + ih - 3, bwid, 3), const Radius.circular(1.5)),
          Paint()..color = b.sunken,
        );
      }
      if (i == cur || (i % every == 0 && (every == 1 || (i - cur).abs() != 1))) {
        _text(
          canvas,
          (8 + i).toString().padLeft(2, '0'),
          Offset(x + bwid / 2, h - 10),
          i == cur ? tMono(10.5, b.accent, weight: FontWeight.w600) : axisStyle,
          align: TextAlign.center,
        );
      }
    }

    final near = max(vals[cur], cur > 0 ? vals[cur - 1] : 0).toDouble();
    final cx = padL + cur * bw + bw / 2;
    final cy = max(12.0, y(near) - 12);
    final align = cur >= 12 ? TextAlign.right : (cur <= 1 ? TextAlign.left : TextAlign.center);
    final lx = align == TextAlign.right ? cx + bw / 2 - gap / 2 : (align == TextAlign.left ? cx - bw / 2 + gap / 2 : cx);
    _text(canvas, money(vals[cur]), Offset(lx, cy), tMono(12, b.ink, weight: FontWeight.w600), align: align, halo: b.surface);
  }

  @override
  bool shouldRepaint(covariant _HourPainter old) => true;
}

/// Simple drawings standing in for client photos (cake, cheesecake, cup).
class ItemIllustration extends StatelessWidget {
  const ItemIllustration({super.key, required this.item});
  final String item;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(150, 110), painter: _IllPainter(item, Biz.of(context)));
  }
}

class _IllPainter extends CustomPainter {
  _IllPainter(this.item, this.b);
  final String item;
  final Biz b;

  @override
  void paint(Canvas canvas, Size size) {
    final fillA = Paint()..color = b.sunSoft;
    final strokeA = Paint()
      ..color = b.sun
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fillB = Paint()..color = b.surface;
    final strokeB = Paint()
      ..color = b.ink3
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fillC = Paint()..color = b.sun;
    final shadow = Paint()..color = b.line;
    canvas.drawOval(Rect.fromCenter(center: const Offset(75, 93), width: 112, height: 16), shadow);
    if (item == 'med') {
      final body = RRect.fromRectAndRadius(const Rect.fromLTWH(24, 44, 102, 44), const Radius.circular(8));
      canvas.drawRRect(body, fillA);
      canvas.drawRRect(body, strokeA);
      canvas.drawRect(const Rect.fromLTWH(26, 58, 98, 6), fillB);
      canvas.drawRect(const Rect.fromLTWH(26, 72, 98, 6), fillB);
      final top = Path()
        ..moveTo(24, 52)
        ..quadraticBezierTo(75, 30, 126, 52)
        ..lineTo(126, 46)
        ..quadraticBezierTo(75, 24, 24, 46)
        ..close();
      canvas.drawPath(top, fillC);
      for (final x in [50.0, 75.0, 100.0]) {
        canvas.drawCircle(Offset(x, x == 75 ? 30 : 33), 4, fillC);
      }
    } else if (item == 'chz') {
      final slice = Path()
        ..moveTo(22, 84)
        ..lineTo(128, 52)
        ..lineTo(128, 86)
        ..lineTo(22, 86)
        ..close();
      canvas.drawPath(slice, fillB);
      canvas.drawPath(slice, strokeB);
      final crust = Path()
        ..moveTo(22, 84)
        ..lineTo(128, 52)
        ..lineTo(128, 60)
        ..lineTo(22, 88)
        ..close();
      canvas.drawPath(crust, fillC);
    } else {
      final cup = Path()
        ..moveTo(48, 34)
        ..lineTo(102, 34)
        ..lineTo(96, 86)
        ..quadraticBezierTo(95, 93, 88, 93)
        ..lineTo(62, 93)
        ..quadraticBezierTo(55, 93, 54, 86)
        ..close();
      canvas.drawPath(cup, fillB);
      canvas.drawPath(cup, strokeB);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(44, 26, 62, 10), const Radius.circular(4)), fillC);
      canvas.drawLine(const Offset(58, 56), const Offset(92, 56), strokeB);
    }
  }

  @override
  bool shouldRepaint(covariant _IllPainter old) => old.item != item || old.b != b;
}

/// Mini map with a pin for a client geolocation; the Talas river runs through Taraz.
class MiniMap extends StatelessWidget {
  const MiniMap({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 120, width: double.infinity, child: CustomPaint(painter: _MapPainter(Biz.of(context))));
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.b);
  final Biz b;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = b.surface2);
    final road = Paint()
      ..color = b.lineStrong
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final road2 = Paint()
      ..color = b.line
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, h * .28), Offset(w, h * .28), road);
    canvas.drawLine(Offset(0, h * .77), Offset(w, h * .77), road);
    canvas.drawLine(Offset(w * .24, 0), Offset(w * .24, h), road);
    canvas.drawLine(Offset(w * .65, 0), Offset(w * .65, h), road);
    canvas.drawLine(Offset(0, h * .52), Offset(w, h * .52), road2);
    canvas.drawLine(Offset(w * .44, 0), Offset(w * .44, h), road2);
    canvas.drawLine(Offset(w * .83, 0), Offset(w * .57, h), road2);
    final river = Path()
      ..moveTo(-5, h * .62)
      ..cubicTo(w * .23, h * .53, w * .43, h * .70, w + 5, h * .58);
    canvas.drawPath(
      river,
      Paint()
        ..color = b.accentLine
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    final tp = TextPainter(text: TextSpan(text: 'р. Талас', style: tMono(10, b.ink3)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(10, h * .66));
    final px = w / 2, py = h * .42;
    final pin = Path()
      ..moveTo(px, py + 20)
      ..cubicTo(px - 11, py + 7, px - 13, py + 1, px - 13, py - 6)
      ..arcToPoint(Offset(px + 13, py - 6), radius: const Radius.circular(13))
      ..cubicTo(px + 13, py + 1, px + 11, py + 7, px, py + 20)
      ..close();
    canvas.drawPath(pin, Paint()..color = b.danger);
    canvas.drawCircle(Offset(px, py - 6), 4.5, Paint()..color = b.surface);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.b != b;
}

/// Heatmap of what clients ask for, by hour.
class Heatmap extends StatelessWidget {
  const Heatmap({super.key, required this.rows, required this.labels, required this.current});
  final Map<String, List<int>> rows;
  final Map<String, String> labels;
  final int current;

  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    final maxC = rows.values.expand((r) => r).fold<int>(1, max);
    const cell = 30.0;
    Widget hourLabel(int i) => SizedBox(
          width: cell,
          child: Text(
            (8 + i).toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: i == current ? tMono(10.5, b.accent, weight: FontWeight.w600) : tMono(10.5, b.ink3),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const SizedBox(width: 108), for (var i = 0; i < 15; i++) ...[hourLabel(i), const SizedBox(width: 3)]]),
          const SizedBox(height: 4),
          for (final e in rows.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 108,
                    child: Text(labels[e.key] ?? e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: tBody(12.5, b.ink2, weight: FontWeight.w500)),
                  ),
                  for (var i = 0; i < e.value.length; i++) ...[
                    Tooltip(
                      message: '${labels[e.key]} · ${(8 + i).toString().padLeft(2, '0')}:00 — ${e.value[i]}',
                      child: Container(
                        width: cell,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Color.lerp(b.surface2, b.accent, min(.92, e.value[i] / maxC)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          e.value[i] == 0 ? '' : '${e.value[i]}',
                          style: tMono(10.5, e.value[i] / maxC > .52 ? b.accentInk : b.ink2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
