import 'package:flutter/material.dart';

import '../engine/parser.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'charts.dart';
import 'widgets.dart';

class Rec {
  const Rec(this.id, this.kind, this.title, this.body, this.effect);
  final String id;
  final String kind;
  final String title;
  final String body;
  final String effect;
}

/// AI recommendations for the owner; demand and stock numbers come from live data.
List<Rec> buildRecs(AppState st) {
  final tr = st.tr;
  final beans = st.stockById('beans');
  return [
    Rec('demand', 'demand', tr.recDemandTitle(st.dessertEveningPct), tr.s('r_demand_b'), tr.s('r_demand_e')),
    Rec('stock', 'stock', tr.recStockTitle(dec1(beans.qty / beans.daily)), tr.recStockBody(dec1(beans.daily), dec1(beans.qty)), tr.s('r_stock_e')),
    Rec('refuse', 'refuse', tr.s('r_refuse_t'), tr.s('r_refuse_b'), tr.s('r_refuse_e')),
    Rec('channel', 'channel', tr.s('r_channel_t'), tr.s('r_channel_b'), tr.s('r_channel_e')),
    Rec('staff', 'staff', tr.s('r_staff_t'), tr.s('r_staff_b'), tr.s('r_staff_e')),
  ];
}

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth;
        const gap = SizedBox(height: kGap, width: kGap);
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(st.tr.s('an_updated'), style: tBody(12.5, b.ink3)),
              const SizedBox(height: 10),
              _Savings(narrow: w < 760),
              gap,
              if (w >= 1000)
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 17, child: _RecsPanel()),
                    gap,
                    Expanded(
                      flex: 10,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_StockPanel(), gap, _RefusalsPanel()]),
                    ),
                  ],
                )
              else ...const [_RecsPanel(), gap, _StockPanel(), gap, _RefusalsPanel()],
              gap,
              const _HeatPanel(),
            ],
          ),
        );
      },
    );
  }
}

class _Savings extends StatelessWidget {
  const _Savings({required this.narrow});
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    final h = st.timeSavedHours;
    final salary = ((h * 1500 * 30) / 100).round() * 100;
    Widget cell(String label, Widget value, String note) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: tBody(13, b.ink2, weight: FontWeight.w500)),
              const SizedBox(height: 6),
              value,
              const SizedBox(height: 6),
              Text(note, style: tBody(12, b.ink3)),
            ],
          ),
        );
    final size = narrow ? 21.0 : 24.0;
    final cells = [
      cell(
        tr.s('sv_salary'),
        AnimatedNum(
          value: salary.toDouble(),
          builder: (v) => Text.rich(TextSpan(children: [
            TextSpan(text: fmtNum((v / 100).round() * 100), style: tDisplay(size, b.ink)),
            TextSpan(text: ' ${tr.s('sv_salary_u')}', style: tBody(13, b.ink3)),
          ])),
        ),
        tr.svSalaryNote(h),
      ),
      cell(tr.s('sv_speed'), Text(tr.s('sv_speed_v'), style: tDisplay(size, b.ink)), tr.s('sv_speed_n')),
      cell(tr.s('sv_lost'), Text(tr.s('sv_lost_v'), style: tDisplay(size, b.ink)), tr.s('sv_lost_n')),
    ];
    return Panel(
      padding: EdgeInsets.zero,
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: b.line),
                  cells[i],
                ],
              ],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cells.length; i++) ...[
                    if (i > 0) VerticalDivider(width: 1, color: b.line),
                    Expanded(child: cells[i]),
                  ],
                ],
              ),
            ),
    );
  }
}

class _RecsPanel extends StatelessWidget {
  const _RecsPanel();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    final recs = buildRecs(st);
    (Color, Color) tag(String kind) => switch (kind) {
          'demand' => (b.sun, b.sunSoft),
          'stock' => (b.danger, b.dangerSoft),
          'refuse' => (b.violet, b.violetSoft),
          'channel' => (b.accent, b.accentSoft),
          _ => (b.ok, b.okSoft),
        };
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHead(title: tr.s('recs'), hint: tr.s('recs_hint')),
          for (var i = 0; i < recs.length; i++) ...[
            if (i > 0) Divider(height: 28, color: b.line),
            Builder(builder: (context) {
              final r = recs[i];
              final (fg, bg) = tag(r.kind);
              final applied = st.applied.contains(r.id);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 13, color: fg),
                        const SizedBox(width: 5),
                        Text(tr.s('tag_${r.kind}'), style: tBody(11.5, fg, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(r.title, style: tBody(15.5, b.ink, weight: FontWeight.w600, height: 1.3)),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Text(r.body, style: tBody(13.5, b.ink2)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: '${tr.s('effect')}  ', style: tBody(12.5, b.ink3, weight: FontWeight.w500)),
                        TextSpan(text: r.effect, style: tMono(12.5, b.ok, weight: FontWeight.w600)),
                      ])),
                      applied
                          ? FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: b.okSoft,
                                foregroundColor: b.ok,
                                minimumSize: const Size(0, 36),
                              ),
                              onPressed: () => st.toggleRec(r.id),
                              icon: const Icon(Icons.check, size: 16),
                              label: Text(tr.s('applied')),
                            )
                          : OutlinedButton(
                              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
                              onPressed: () => st.toggleRec(r.id),
                              child: Text(tr.s('apply')),
                            ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _StockPanel extends StatelessWidget {
  const _StockPanel();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHead(title: tr.s('stock'), hint: tr.s('stock_hint')),
          for (var i = 0; i < st.stock.length; i++) ...[
            if (i > 0) Divider(height: 18, color: b.line),
            Builder(builder: (context) {
              final s = st.stock[i];
              final d = s.qty / s.daily;
              final lv = d < 1 ? 'crit' : (d < 3 ? 'warn' : 'ok');
              final color = switch (lv) { 'crit' => b.danger, 'warn' => b.warn, _ => b.ok };
              final unit = st.lang == 'kz' ? s.uKz : s.uRu;
              final q = s.dec ? dec1(s.qty) : '${s.qty.round()}';
              final dd = s.dec ? dec1(s.daily) : '${s.daily.round()}';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(st.lang == 'kz' ? s.kz : s.ru, style: tBody(14, b.ink, weight: FontWeight.w500))),
                      Text(tr.days(dec1(d)), style: tMono(12.5, color, weight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Track(value: d / 7, color: color, height: 5),
                  const SizedBox(height: 5),
                  Text('${tr.stockLeft(q, unit, dd)} · ${tr.s('lv_$lv')}', style: tBody(12, b.ink3)),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _RefusalsPanel extends StatelessWidget {
  const _RefusalsPanel();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    final reasons = tr.reasons;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHead(title: tr.s('refusals'), hint: tr.s('refusals_hint')),
          for (var i = 0; i < kRefusals.length; i++) ...[
            Row(
              children: [
                Expanded(child: Text(reasons[i], style: tBody(13.5, b.ink, weight: FontWeight.w500))),
                Text('${kRefusals[i]}%', style: tMono(13, b.ink, weight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Track(value: kRefusals[i] / kRefusals[0], color: i == 0 ? b.violet : b.lineStrong),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _HeatPanel extends StatelessWidget {
  const _HeatPanel();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    int peak(List<int> row) {
      var bi = 0;
      for (var i = 1; i < row.length; i++) {
        if (row[i] > row[bi]) bi = i;
      }
      return bi + 8;
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHead(title: tr.s('heat'), hint: tr.s('heat_hint')),
          Heatmap(
            rows: st.heat,
            current: st.hourIdx(st.now()),
            labels: {
              'coffee': tr.s('cat_coffee'),
              'dessert': tr.s('cat_dessert'),
              'bakery': tr.s('cat_bakery'),
              'beans': tr.s('cat_beans'),
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, size: 15, color: b.sun),
              const SizedBox(width: 8),
              Expanded(child: Text(tr.heatNote(peak(st.heat['dessert']!), peak(st.heat['coffee']!)), style: tBody(13, b.ink2))),
            ],
          ),
        ],
      ),
    );
  }
}
