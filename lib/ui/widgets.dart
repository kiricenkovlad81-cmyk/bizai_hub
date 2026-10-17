import 'package:flutter/material.dart';

import '../engine/types.dart';
import '../state/models.dart';
import '../theme.dart';

const double kGap = 12;

String hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// White card with a hairline border — the basic surface of the app.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.borderColor});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? b.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? b.line),
      ),
      child: child,
    );
  }
}

class PanelHead extends StatelessWidget {
  const PanelHead({super.key, required this.title, this.hint, this.trailing});
  final String title;
  final String? hint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 4,
        children: [
          Text(title, style: tBody(15, b.ink, weight: FontWeight.w600, height: 1.25)),
          if (hint != null) Text(hint!, style: tBody(12.5, b.ink3)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ChannelChip extends StatelessWidget {
  const ChannelChip(this.ch, {super.key, this.big = false, this.ring});
  final Ch ch;
  final bool big;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    final bg = switch (ch) { Ch.ig => b.ig, Ch.tg => b.tg, Ch.wa => b.wa };
    return Container(
      height: big ? 24 : 18,
      padding: EdgeInsets.symmetric(horizontal: big ? 6 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: ring == null ? null : Border.all(color: ring!, width: 2),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(ch.short, style: tMono(big ? 11 : 9.5, b.chipInk, weight: FontWeight.w600, height: 1)),
      ),
    );
  }
}

(Color, Color) statusColors(Biz b, St s) => switch (s) {
      St.lead => (b.accent, b.accentSoft),
      St.kaspi => (b.warn, b.warnSoft),
      St.paid => (b.ok, b.okSoft),
      St.courier => (b.violet, b.violetSoft),
    };

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, this.label, {super.key});
  final St status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = statusColors(Biz.of(context), status);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: tBody(11.5, fg, weight: FontWeight.w600, height: 1.1)),
        ],
      ),
    );
  }
}

class Dot extends StatelessWidget {
  const Dot(this.color, {super.key, this.size = 8});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.ch, this.size = 40});
  final String name;
  final Ch? ch;
  final double size;

  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    final parts = name.replaceFirst('@', '').trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '?';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    var h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) % 360;
    }
    final bg = HSLColor.fromAHSL(1, h.toDouble(), .40, .36).toColor();
    return SizedBox(
      width: size + 5,
      height: size + 5,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * .3)),
            child: Text('$first$second'.toUpperCase(), style: tBody(size * .35, Colors.white, weight: FontWeight.w600, height: 1)),
          ),
          if (ch != null) Positioned(right: 0, bottom: 0, child: ChannelChip(ch!, ring: b.surface)),
        ],
      ),
    );
  }
}

/// Small segmented control (RU | KZ, chat | order, …).
class Seg<T> extends StatelessWidget {
  const Seg({super.key, required this.value, required this.options, required this.onChanged, this.mono = false, this.expand = false});
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final bool mono;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    final children = <Widget>[
      for (final (v, label) in options)
        _wrap(
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(v),
            child: Semantics(
              button: true,
              selected: v == value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(minHeight: 32, minWidth: 42),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: v == value ? b.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: v == value ? [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 2, offset: const Offset(0, 1))] : null,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mono
                      ? tMono(12.5, v == value ? b.ink : b.ink2, weight: FontWeight.w600)
                      : tBody(13, v == value ? b.ink : b.ink2, weight: FontWeight.w600, height: 1.2),
                ),
              ),
            ),
          ),
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: b.sunken, borderRadius: BorderRadius.circular(10), border: Border.all(color: b.line)),
      child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: children),
    );
  }

  Widget _wrap(Widget w) => expand ? Expanded(child: w) : w;
}

/// Number that counts up smoothly when it changes.
class AnimatedNum extends StatelessWidget {
  const AnimatedNum({super.key, required this.value, required this.builder});
  final double value;
  final Widget Function(double v) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(v),
    );
  }
}

/// Fades in messages that just arrived; older ones appear instantly.
class FadeIn extends StatefulWidget {
  const FadeIn({super.key, required this.enabled, required this.child});
  final bool enabled;
  final Widget child;
  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .15), end: Offset.zero).animate(curve),
        child: widget.child,
      ),
    );
  }
}

class Spinner extends StatelessWidget {
  const Spinner({super.key, this.size = 12});
  final double size;
  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2, color: b.accent, backgroundColor: b.accentLine),
    );
  }
}

/// Horizontal progress track used in funnel, channels, stock and refusals.
class Track extends StatelessWidget {
  const Track({super.key, required this.value, required this.color, this.height = 6});
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: b.sunken,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0).toDouble(),
          heightFactor: 1,
          child: Container(color: color),
        ),
      ),
    );
  }
}

/// Lays out [children] in rows of [cols] with equal heights inside each row.
class EqualRows extends StatelessWidget {
  const EqualRows({super.key, required this.cols, required this.children, this.gap = kGap});
  final int cols;
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += cols) {
      final rowChildren = <Widget>[];
      for (var j = 0; j < cols; j++) {
        if (j > 0) rowChildren.add(SizedBox(width: gap));
        final idx = i + j;
        rowChildren.add(Expanded(child: idx < children.length ? children[idx] : const SizedBox.shrink()));
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: rowChildren)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}
