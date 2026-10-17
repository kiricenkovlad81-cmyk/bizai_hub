import 'package:flutter/material.dart';

import '../engine/parser.dart';
import '../engine/types.dart';
import '../state/app_state.dart';
import '../state/models.dart';
import '../theme.dart';
import 'analytics.dart';
import 'charts.dart';
import 'widgets.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth;
        final cols = w >= 1000 ? 4 : 2;
        const gap = SizedBox(height: kGap, width: kGap);
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EqualRows(cols: cols, gap: w < 520 ? 8 : kGap, children: const [
                _RevenueCard(),
                _TimeCard(),
                _ConversionCard(),
                _AiCard(),
              ]),
              gap,
              if (w >= 1000)
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(flex: 17, child: _HourPanel()), gap, Expanded(flex: 10, child: _FunnelPanel())],
                )
              else ...const [_HourPanel(), gap, _FunnelPanel()],
              gap,
              if (w >= 1100)
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: _ChannelsPanel()),
                    gap,
                    Expanded(flex: 5, child: _FeedPanel()),
                    gap,
                    Expanded(flex: 4, child: _TipPanel()),
                  ],
                )
              else if (w >= 700) ...const [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(child: _ChannelsPanel()), gap, Expanded(child: _FeedPanel())],
                ),
                gap,
                _TipPanel(),
              ] else
                ...const [_ChannelsPanel(), gap, _FeedPanel(), gap, _TipPanel()],
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value, required this.foot, this.hero = false});
  final IconData icon;
  final String label;
  final Widget value;
  final Widget foot;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return Container(
      padding: EdgeInsets.all(narrow ? 12 : 16),
      decoration: BoxDecoration(
        color: hero ? b.heroBg : b.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hero ? b.heroBg : b.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!narrow) ...[Icon(icon, size: 16, color: hero ? b.sun : b.accent), const SizedBox(width: 8)],
              Expanded(child: Text(label, style: tBody(narrow ? 12 : 13, hero ? b.heroInk2 : b.ink2, weight: FontWeight.w500, height: 1.3))),
            ],
          ),
          const SizedBox(height: 12),
          value,
          const SizedBox(height: 10),
          const Spacer(),
          foot,
        ],
      ),
    );
  }
}

Widget _bigNumber(BuildContext context, String number, String unit, {bool hero = false}) {
  final b = Biz.of(context);
  final narrow = MediaQuery.sizeOf(context).width < 520;
  final size = narrow ? 21.0 : 30.0;
  return FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text.rich(
      TextSpan(children: [
        TextSpan(text: number, style: tDisplay(size, hero ? b.heroInk : b.ink)),
        if (unit.isNotEmpty) TextSpan(text: ' $unit', style: tBody(size * .5, hero ? b.heroInk2 : b.ink3, weight: FontWeight.w500)),
      ]),
      maxLines: 1,
    ),
  );
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard();
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final d = st.revDeltaPct;
    final parts = st.tr.revFoot('${d >= 0 ? '+' : ''}$d%', st.m.paid);
    final footStyle = tBody(12.5, b.heroInk2);
    return _MetricCard(
      hero: true,
      icon: Icons.account_balance_wallet_outlined,
      label: st.tr.s('m_rev'),
      value: AnimatedNum(value: st.m.rev.toDouble(), builder: (v) => _bigNumber(context, fmtNum(v), '₸', hero: true)),
      foot: Text.rich(TextSpan(style: footStyle, children: [
        TextSpan(text: parts[0]),
        TextSpan(text: parts[1], style: tMono(12.5, b.heroUp, weight: FontWeight.w600)),
        TextSpan(text: parts[2]),
      ])),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard();
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    return _MetricCard(
      icon: Icons.schedule,
      label: st.tr.s('m_time'),
      value: AnimatedNum(value: st.timeSavedHours, builder: (v) => _bigNumber(context, dec1(v), st.tr.s('h'))),
      foot: Text(st.tr.timeFoot(st.m.ai), style: tBody(12.5, b.ink3)),
    );
  }
}

class _ConversionCard extends StatelessWidget {
  const _ConversionCard();
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final p = st.conversionPct;
    return _MetricCard(
      icon: Icons.track_changes,
      label: st.tr.s('m_conv'),
      value: AnimatedNum(value: p.toDouble(), builder: (v) => _bigNumber(context, '${v.round()}', '%')),
      foot: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: p / 100, end: p / 100),
            duration: const Duration(milliseconds: 600),
            builder: (context, v, _) => Track(value: v, color: b.ok, height: 5),
          ),
          const SizedBox(height: 8),
          Text(st.tr.convFoot(st.m.paid, st.m.dialogs), style: tBody(12.5, b.ink3)),
        ],
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard();
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    return _MetricCard(
      icon: Icons.auto_awesome,
      label: st.tr.s('m_ai'),
      value: AnimatedNum(value: st.m.ai.toDouble(), builder: (v) => _bigNumber(context, '${v.round()}', '')),
      foot: Text(st.tr.aiFoot(st.noOpPct), style: tBody(12.5, b.ink3)),
    );
  }
}

class _HourPanel extends StatelessWidget {
  const _HourPanel();
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHead(title: st.tr.s('chart_hourly'), hint: st.tr.s('chart_hint')),
          HourChart(values: st.hourly, current: st.hourIdx(st.now()), kLabel: st.tr.s('k')),
        ],
      ),
    );
  }
}

class _FunnelPanel extends StatelessWidget {
  const _FunnelPanel();
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final cnt = {for (final s in St.values) s: 0};
    final sum = {for (final s in St.values) s: 0};
    for (final c in st.convs) {
      cnt[c.status] = cnt[c.status]! + 1;
      if (c.order != null) sum[c.status] = sum[c.status]! + c.order!.total;
    }
    final maxC = cnt.values.fold<int>(1, (a, x) => x > a ? x : a);
    final total = cnt.values.fold<int>(0, (a, x) => a + x);
    final tsum = sum.values.fold<int>(0, (a, x) => a + x);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHead(title: st.tr.s('funnel')),
          for (final s in St.values) ...[
            Row(
              children: [
                Dot(statusColors(b, s).$1),
                const SizedBox(width: 8),
                Flexible(child: Text(st.tr.s('st_${s.name}'), maxLines: 1, overflow: TextOverflow.ellipsis, style: tBody(14, b.ink, weight: FontWeight.w500))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: b.sunken, borderRadius: BorderRadius.circular(6)),
                  child: Text('${cnt[s]}', style: tMono(11.5, b.ink2, weight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(sum[s]! > 0 ? money(sum[s]!) : '—', style: tMono(13, b.ink, weight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Track(value: cnt[s]! / maxC, color: statusColors(b, s).$1),
            const SizedBox(height: 12),
          ],
          Divider(color: b.line, height: 1),
          const SizedBox(height: 10),
          Text(st.tr.funnelTotal(total, tsum), style: tBody(13, b.ink2)),
        ],
      ),
    );
  }
}

class _ChannelsPanel extends StatelessWidget {
  const _ChannelsPanel();
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tot = st.chStats.values.fold<int>(0, (a, x) => a + x.r);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHead(title: st.tr.s('channels'), hint: st.tr.s('channels_hint')),
          for (final ch in Ch.values) ...[
            Row(
              children: [
                ChannelChip(ch),
                const SizedBox(width: 8),
                Expanded(child: Text(ch.label, style: tBody(14, b.ink, weight: FontWeight.w500))),
                Text(money(st.chStats[ch]!.r), style: tMono(13, b.ink, weight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text(st.tr.dialogs(st.chStats[ch]!.d), style: tMono(11, b.ink3)),
              ],
            ),
            const SizedBox(height: 6),
            Track(
              value: tot == 0 ? 0.0 : st.chStats[ch]!.r / tot,
              color: switch (ch) { Ch.ig => b.ig, Ch.tg => b.tg, Ch.wa => b.wa },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _FeedPanel extends StatelessWidget {
  const _FeedPanel();
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    Color dot(String type) => switch (type) {
          'new' => b.accent,
          'invoice' => b.warn,
          'paid' => b.ok,
          'courier' || 'handed' => b.violet,
          'rec' => b.sun,
          _ => b.ink3,
        };
    final items = st.feed.take(14).toList();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHead(
            title: st.tr.s('feed'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Dot(b.ok, size: 7), const SizedBox(width: 6), Text('LIVE', style: tMono(11, b.ok, weight: FontWeight.w600))],
            ),
          ),
          SizedBox(
            height: 300,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(color: b.line, height: 1),
              itemBuilder: (context, i) {
                final e = items[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: e.convId == null ? null : () => st.openConv(e.convId!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 44, child: Text(hhmm(e.at), style: tMono(12, b.ink3))),
                        Padding(padding: const EdgeInsets.only(top: 5, right: 8), child: Dot(dot(e.type))),
                        Expanded(child: Text(st.tr.event(e), style: tBody(13, b.ink))),
                      ],
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

class _TipPanel extends StatelessWidget {
  const _TipPanel();
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final recs = buildRecs(st);
    final r = recs.firstWhere((x) => !st.applied.contains(x.id), orElse: () => recs.first);
    return Panel(
      color: b.sunSoft,
      borderColor: Color.lerp(b.line, b.sun, .35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelHead(title: st.tr.s('top_rec')),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 15, color: b.sun),
              const SizedBox(width: 6),
              Text(st.tr.s('tag_${r.kind}'), style: tBody(12, b.sun, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(r.title, style: tBody(16, b.ink, weight: FontWeight.w600, height: 1.3)),
          const SizedBox(height: 6),
          Text(r.body, style: tBody(13, b.ink2)),
          const SizedBox(height: 10),
          Text(r.effect, style: tMono(12.5, b.ok, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: () => st.setView(AppView.analytics), child: Text(st.tr.s('open_an'))),
        ],
      ),
    );
  }
}
