import 'package:flutter/material.dart';

import '../engine/parser.dart';
import '../state/app_state.dart';
import '../state/models.dart';
import '../theme.dart';
import 'analytics.dart';
import 'dashboard.dart';
import 'inbox.dart';
import 'sheets.dart';
import 'widgets.dart';

/// Responsive frame: side rail on tablets/PC, floating tab bar on phones.
class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return AnimatedBuilder(
      animation: st,
      builder: (context, _) {
        final b = Biz.of(context);
        final w = MediaQuery.sizeOf(context).width;
        final wide = w >= 900;
        final body = switch (st.view) {
          AppView.dashboard => const DashboardView(),
          AppView.inbox => const InboxView(),
          AppView.analytics => const AnalyticsView(),
        };
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TopBar(wide: wide),
            SizedBox(height: wide ? 14 : 10),
            Expanded(child: body),
            if (!wide) ...[const SizedBox(height: 10), const BottomBar()],
          ],
        );
        return Scaffold(
          backgroundColor: b.bg,
          body: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(wide ? 16 : 10).copyWith(left: 16, right: 16),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [const Rail(), const SizedBox(width: 16), Expanded(child: content)],
                        )
                      : content,
                ),
                ToastLayer(wide: wide),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 32});
  final double size;
  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: b.sun, borderRadius: BorderRadius.circular(size * .31)),
      child: Icon(Icons.auto_awesome, size: size * .56, color: b.sunInk),
    );
  }
}

class Rail extends StatelessWidget {
  const Rail({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    Widget item(AppView v, IconData icon, String label, {int badge = 0}) {
      final active = st.view == v;
      return Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Material(
          color: active ? b.railActive : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            hoverColor: b.railHover,
            onTap: () => st.setView(v),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 19, color: active ? b.railInk : b.railInk2),
                  const SizedBox(width: 11),
                  Expanded(child: Text(label, style: tBody(14, active ? b.railInk : b.railInk2, weight: FontWeight.w500))),
                  if (badge > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: b.sun, borderRadius: BorderRadius.circular(10)),
                      child: Text('$badge', style: tMono(11, b.sunInk, weight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 232,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 14),
      decoration: BoxDecoration(color: b.railBg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const BrandMark(),
                const SizedBox(width: 10),
                Text('BizAI', style: tDisplay(16, b.railInk)),
                Text(' Hub', style: tDisplay(16, b.railInk2)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          item(AppView.dashboard, Icons.grid_view_rounded, tr.s('nav_dash')),
          item(AppView.inbox, Icons.inbox_outlined, tr.s('nav_inbox'), badge: st.unreadCount),
          item(AppView.analytics, Icons.insights_outlined, tr.s('nav_an')),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: b.railHover, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: b.railActive, borderRadius: BorderRadius.circular(10)),
                  child: Text('ДК', style: tBody(13, b.railInk, weight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Дәмді Кофе', style: tBody(14, b.railInk, weight: FontWeight.w600)),
                      Text(tr.s('biz_type'), style: tBody(12, b.railInk2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Wrap(
              spacing: 5,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const ChannelChip(Ch.ig),
                const ChannelChip(Ch.tg),
                const ChannelChip(Ch.wa),
                Text(tr.s('channels_on'), style: tBody(12, b.railInk2)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: b.railInk2, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 4)),
            onPressed: st.resetDemo,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(tr.s('reset'), style: tBody(12.5, b.railInk2)),
          ),
        ],
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    final title = tr.s('title_${st.view.name}');
    final lang = Seg<String>(
      value: st.lang,
      mono: true,
      options: const [('ru', 'RU'), ('kz', 'KZ')],
      onChanged: st.setLang,
    );
    final settings = IconButton(
      tooltip: tr.s('settings'),
      onPressed: () => showSettingsSheet(context),
      icon: Icon(Icons.tune, color: b.ink2),
    );
    if (!wide) {
      return Row(
        children: [
          const BrandMark(size: 34),
          const SizedBox(width: 12),
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tBody(17, b.ink, weight: FontWeight.w700, height: 1.2))),
          lang,
          settings,
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, cons) {
        final roomy = cons.maxWidth >= 980;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tBody(22, b.ink, weight: FontWeight.w700, height: 1.15)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(child: Text(tr.today(st.now()), maxLines: 1, overflow: TextOverflow.ellipsis, style: tBody(13, b.ink3))),
                      const SizedBox(width: 8),
                      Dot(b.ok),
                      const SizedBox(width: 6),
                      Flexible(child: Text(tr.s('online'), maxLines: 1, overflow: TextOverflow.ellipsis, style: tBody(13, b.ink3))),
                    ],
                  ),
                ],
              ),
            ),
            if (roomy) ...[
              Switch(value: st.auto, onChanged: st.setAuto),
              const SizedBox(width: 4),
              Text(tr.s('auto'), style: tBody(13, b.ink2, weight: FontWeight.w500)),
              const SizedBox(width: 14),
            ],
            const SimSplitButton(),
            const SizedBox(width: 12),
            lang,
            const SizedBox(width: 4),
            settings,
          ],
        );
      },
    );
  }
}

class SimSplitButton extends StatelessWidget {
  const SimSplitButton({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    return Material(
      color: b.accent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => st.simulate(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 7, 16, 7),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: b.accentInk, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tr.s('sim_btn'), style: tBody(14, b.accentInk, weight: FontWeight.w600, height: 1.15)),
                        Text('Instagram / Telegram', style: tBody(11, b.accentInk.withAlpha(215), height: 1.15)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 1, color: b.accentInk.withAlpha(70)),
            InkWell(
              onTap: () => showSimulatorSheet(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.expand_more, color: b.accentInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    Widget tab({required IconData icon, required String label, required VoidCallback onTap, bool active = false, bool accent = false, int badge = 0}) {
      final fg = accent ? b.accentInk : (active ? b.accent : b.ink3);
      return Expanded(
        child: Material(
          color: accent ? b.accent : (active ? b.accentSoft : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, size: 21, color: fg),
                      if (badge > 0)
                        Positioned(
                          right: -12,
                          top: -5,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 17),
                            height: 17,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: b.sun, borderRadius: BorderRadius.circular(9)),
                            child: Text('$badge', style: tMono(10, b.sunInk, weight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: tBody(11, fg, weight: FontWeight.w600, height: 1.1)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: b.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: b.line),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          tab(icon: Icons.grid_view_rounded, label: tr.s('nav_dash'), active: st.view == AppView.dashboard, onTap: () => st.setView(AppView.dashboard)),
          const SizedBox(width: 4),
          tab(icon: Icons.inbox_outlined, label: tr.s('nav_inbox'), active: st.view == AppView.inbox, badge: st.unreadCount, onTap: () => st.setView(AppView.inbox)),
          const SizedBox(width: 4),
          tab(icon: Icons.bolt, label: tr.s('sim_short'), accent: true, onTap: () => showSimulatorSheet(context)),
          const SizedBox(width: 4),
          tab(icon: Icons.insights_outlined, label: tr.s('nav_an_short'), active: st.view == AppView.analytics, onTap: () => st.setView(AppView.analytics)),
        ],
      ),
    );
  }
}

/// Live notifications about simulated conversations.
class ToastLayer extends StatelessWidget {
  const ToastLayer({super.key, required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    if (st.toasts.isEmpty) return const SizedBox.shrink();
    final list = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final t in st.toasts)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: ToastCard(key: ValueKey(t.id), toast: t)),
      ],
    );
    if (wide) {
      return Positioned(right: 16, bottom: 8, width: 350, child: list);
    }
    return Positioned(left: 16, right: 16, top: 10, child: list);
  }
}

class ToastCard extends StatelessWidget {
  const ToastCard({super.key, required this.toast});
  final ToastData toast;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    final c = st.convById(toast.convId);
    final decoration = BoxDecoration(
      color: b.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: b.line),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 24, offset: const Offset(0, 8))],
    );
    if (c == null) {
      return FadeIn(
        enabled: true,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: decoration,
          child: Row(
            children: [
              Icon(toast.err ? Icons.error_outline : Icons.check_circle_outline, size: 18, color: toast.err ? b.danger : b.ok),
              const SizedBox(width: 10),
              Expanded(child: Text(toast.text ?? '', style: tBody(13, toast.err ? b.danger : b.ok, weight: FontWeight.w600))),
            ],
          ),
        ),
      );
    }
    final total = c.order?.total ?? 0;
    final (Widget lead, String label, Color color) = switch (toast.stage) {
      'invoiced' => (Icon(Icons.receipt_long_outlined, size: 15, color: b.warn), tr.toastInvoiced(total), b.warn),
      'paid' => (Icon(Icons.check, size: 15, color: b.ok), tr.toastPaid(total), b.ok),
      'clarify' => (Icon(Icons.chat_bubble_outline, size: 15, color: b.ink2), tr.s('t_clarify'), b.ink2),
      'parsing' => (const Spinner(), tr.s('t_parsing'), b.accent),
      _ => (const Spinner(), tr.toastNew(c.ch.label), b.accent),
    };
    final m = toast.msg;
    var preview = m?.text ?? '';
    if (preview.isEmpty && m?.att != null) preview = tr.s('voice');
    return FadeIn(
      enabled: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => st.openFromToast(toast),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: decoration,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Avatar(name: c.name, ch: c.ch, size: 36),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tBody(13, b.ink, weight: FontWeight.w700))),
                          Text(hhmm(c.createdAt), style: tMono(11, b.ink3)),
                        ],
                      ),
                      Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: tBody(12.5, b.ink2)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          lead,
                          const SizedBox(width: 6),
                          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: tBody(12.5, color, weight: FontWeight.w600))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Formats revenue for the metric card: "175 400" (the ₸ sign is drawn separately).
String revenueNumber(double v) => fmtNum(v);
