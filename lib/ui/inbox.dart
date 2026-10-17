import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/catalog.dart';
import '../engine/parser.dart';
import '../engine/types.dart';
import '../state/app_state.dart';
import '../state/models.dart';
import '../theme.dart';
import 'charts.dart';
import 'widgets.dart';

/// AI Inbox: conversation list, chat with the AI's work, and the order card.
class InboxView extends StatelessWidget {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth;
        if (w >= 1180) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [SizedBox(width: 320, child: ConvList()), SizedBox(width: kGap), Expanded(child: DetailView(threePane: true))],
          );
        }
        if (w >= 700) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [SizedBox(width: 300, child: ConvList()), SizedBox(width: kGap), Expanded(child: DetailView(threePane: false))],
          );
        }
        if (st.mobileDetail && st.selected != null) return const DetailView(threePane: false, showBack: true);
        return const ConvList();
      },
    );
  }
}

class ConvList extends StatefulWidget {
  const ConvList({super.key});
  @override
  State<ConvList> createState() => _ConvListState();
}

class _ConvListState extends State<ConvList> {
  late final TextEditingController _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    final counts = <String, int>{'all': st.convs.length};
    for (final s in St.values) {
      counts[s.name] = st.convs.where((c) => c.status == s).length;
    }
    final list = st.visibleConvs;
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _q,
                  onChanged: st.setQuery,
                  style: tBody(14, b.ink),
                  decoration: InputDecoration(
                    hintText: tr.s('search'),
                    prefixIcon: Icon(Icons.search, size: 20, color: b.ink3),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final f in ['all', ...St.values.map((s) => s.name)]) ...[
                        _FilterChip(
                          label: f == 'all' ? tr.s('f_all') : tr.s('st_$f'),
                          count: counts[f] ?? 0,
                          active: st.filter == f,
                          onTap: () => st.setFilter(f),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: b.line),
          Expanded(
            child: list.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(tr.s('empty_list'), style: tBody(13, b.ink3))))
                : ListView.builder(
                    padding: const EdgeInsets.all(6),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _ConvTile(conv: list[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.count, required this.active, required this.onTap});
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    final fg = active ? b.surface : b.ink2;
    return Material(
      color: active ? b.ink : b.surface,
      shape: StadiumBorder(side: BorderSide(color: active ? b.ink : b.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: tBody(12.5, fg, weight: FontWeight.w500)),
              const SizedBox(width: 6),
              Text('$count', style: tMono(11, fg, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

String _preview(Conv c, AppState st) {
  final tr = st.tr;
  if (c.typing) return tr.s('typing');
  Msg? m;
  for (final x in c.msgs.reversed) {
    if (x.from == From.client || x.from == From.ai || x.from == From.op) {
      m = x;
      break;
    }
  }
  if (m == null) return '';
  final pre = m.from == From.ai ? tr.s('ai_prefix') : '';
  final att = m.att;
  if (att != null) {
    final label = switch (att.type) {
      AttType.voice => '${tr.s('voice')} ${att.dur ?? ''}',
      AttType.photo => tr.s('photo'),
      AttType.geo => tr.s('geo'),
      AttType.receipt => tr.s('receipt'),
    };
    return '$pre$label${m.text.isNotEmpty ? ': ${m.text}' : ''}'.replaceAll('\n', ' ');
  }
  return '$pre${m.text}'.replaceAll('\n', ' ');
}

IconData? _attIcon(Conv c) {
  for (final x in c.msgs.reversed) {
    if (x.from == From.client || x.from == From.ai || x.from == From.op) {
      final a = x.att;
      if (a == null) return null;
      return switch (a.type) {
        AttType.voice => Icons.mic_none,
        AttType.photo => Icons.image_outlined,
        AttType.geo => Icons.place_outlined,
        AttType.receipt => Icons.receipt_long_outlined,
      };
    }
  }
  return null;
}

class _ConvTile extends StatelessWidget {
  const _ConvTile({required this.conv});
  final Conv conv;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final c = conv;
    final active = st.sel == c.id;
    final icon = _attIcon(c);
    return Material(
      color: active ? b.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => st.openConv(c.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Avatar(name: c.name, ch: c.ch),
                  if (c.unread) Positioned(left: -9, top: 17, child: Dot(b.accent, size: 6)),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tBody(14, b.ink, weight: c.unread ? FontWeight.w700 : FontWeight.w600)),
                        ),
                        Text(hhmm(c.updatedAt), style: tMono(11.5, b.ink3)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (icon != null && !c.typing) ...[Icon(icon, size: 14, color: b.ink3), const SizedBox(width: 4)],
                        Expanded(
                          child: Text(
                            _preview(c, st),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: c.typing
                                ? tBody(13, b.accent).copyWith(fontStyle: FontStyle.italic)
                                : tBody(13, b.ink2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusPill(c.status, st.tr.s('st_${c.status.name}')),
                        const Spacer(),
                        if (c.order != null) Text(money(c.order!.total), style: tMono(12.5, b.ink, weight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailView extends StatelessWidget {
  const DetailView({super.key, required this.threePane, this.showBack = false});
  final bool threePane;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final c = st.selected;
    if (c == null) {
      return Panel(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, size: 36, color: b.accent),
                const SizedBox(height: 10),
                Text(st.tr.s('pick_conv'), style: tBody(16, b.ink, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(st.tr.s('pick_conv_sub'), textAlign: TextAlign.center, style: tBody(13.5, b.ink2)),
              ],
            ),
          ),
        ),
      );
    }
    final Widget body;
    if (threePane) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ChatPane(key: ValueKey('chat-${c.id}'), conv: c)),
          const SizedBox(width: kGap),
          SizedBox(width: 344, child: OrderPane(conv: c)),
        ],
      );
    } else {
      body = st.orderTab ? OrderPane(conv: c) : ChatPane(key: ValueKey('chat-${c.id}'), conv: c);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailHead(conv: c, showBack: showBack, showTabs: !threePane),
        const SizedBox(height: 10),
        Expanded(child: body),
      ],
    );
  }
}

class _DetailHead extends StatelessWidget {
  const _DetailHead({required this.conv, required this.showBack, required this.showTabs});
  final Conv conv;
  final bool showBack;
  final bool showTabs;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    final c = conv;
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (showBack)
                IconButton(
                  tooltip: tr.s('back'),
                  onPressed: st.closeDetail,
                  icon: Icon(Icons.arrow_back, color: b.ink2),
                ),
              Avatar(name: c.name, ch: c.ch),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tBody(15, b.ink, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(c.ch.label, style: tBody(12.5, b.ink3)),
                        Text(c.handle ?? c.contact ?? '', style: tMono(12, b.ink3)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(border: Border.all(color: b.lineStrong), borderRadius: BorderRadius.circular(5)),
                          child: Text(c.lang.toUpperCase(), style: tMono(10.5, b.ink2, weight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(c.status, tr.s('st_${c.status.name}')),
            ],
          ),
          if (showTabs) ...[
            const SizedBox(height: 10),
            Seg<bool>(
              expand: true,
              value: st.orderTab,
              onChanged: st.setOrderTab,
              options: [
                (false, tr.s('tab_chat')),
                (true, c.order == null ? tr.s('tab_order') : '${tr.s('tab_order')} · ${money(c.order!.total)}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ChatPane extends StatefulWidget {
  const ChatPane({super.key, required this.conv});
  final Conv conv;
  @override
  State<ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<ChatPane> {
  final ScrollController _sc = ScrollController();
  final TextEditingController _reply = TextEditingController();
  String _sig = '';
  bool _atBottom = true;

  @override
  void initState() {
    super.initState();
    _sc.addListener(() {
      if (!_sc.hasClients) return;
      final p = _sc.position;
      _atBottom = p.pixels >= p.maxScrollExtent - 80;
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    _reply.dispose();
    super.dispose();
  }

  void _scrollToEnd({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sc.hasClients) return;
      final target = _sc.position.maxScrollExtent;
      if (animate) {
        _sc.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      } else {
        _sc.jumpTo(target);
      }
    });
  }

  void _send(AppState st) {
    st.operatorReply(widget.conv, _reply.text);
    _reply.clear();
    _atBottom = true;
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final c = widget.conv;
    final steps = c.msgs.fold<int>(0, (a, m) => a + m.steps.length);
    final sig = '${c.msgs.length}:$steps:${c.typing}';
    if (sig != _sig) {
      final first = _sig.isEmpty;
      _sig = sig;
      if (first || _atBottom) _scrollToEnd(animate: !first);
    }
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: ColoredBox(
                color: b.surface2,
                child: LayoutBuilder(
                  builder: (context, cons) {
                    final maxW = min(520.0, cons.maxWidth * .84);
                    return ListView(
                      controller: _sc,
                      padding: const EdgeInsets.all(14),
                      children: [
                        for (final m in c.msgs)
                          Padding(
                            key: ObjectKey(m),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FadeIn(
                              enabled: DateTime.now().difference(m.born).inMilliseconds < 1500,
                              child: MessageView(msg: m, maxWidth: maxW),
                            ),
                          ),
                        if (c.typing) const Align(alignment: Alignment.centerLeft, child: _TypingBubble()),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Divider(height: 1, color: b.line),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _reply,
                    style: tBody(14, b.ink),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(st),
                    decoration: InputDecoration(hintText: st.tr.s('reply_ph')),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _send(st),
                  style: IconButton.styleFrom(
                    backgroundColor: b.accent,
                    foregroundColor: b.accentInk,
                    fixedSize: const Size(44, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: b.surface,
        border: Border.all(color: b.line),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: 0.25 + 0.75 * (0.5 + 0.5 * sin((_c.value * 2 * pi) - i * 0.9)),
                  child: Dot(b.ink3, size: 6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One item in the chat: client message, AI reply, operator reply, system event or AI processing card.
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.msg, required this.maxWidth});
  final Msg msg;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    final m = msg;
    final time = Text(hhmm(m.at), style: tMono(11.5, b.ink3));
    switch (m.from) {
      case From.client:
        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (m.att != null) ...[AttachmentView(att: m.att!), const SizedBox(height: 5)],
                if (m.text.isNotEmpty) _Bubble(text: m.text, color: b.surface, border: b.line, textColor: b.ink, mine: false),
                const SizedBox(height: 5),
                time,
              ],
            ),
          ),
        );
      case From.ai:
      case From.op:
        final ai = m.from == From.ai;
        return Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ai) ...[Icon(Icons.auto_awesome, size: 13, color: b.accent), const SizedBox(width: 5)],
                    Text('${ai ? tr.s('ai_label') : tr.s('op_label')} · ', style: tBody(11.5, b.ink3)),
                    time,
                  ],
                ),
                const SizedBox(height: 5),
                _Bubble(
                  text: m.text,
                  color: ai ? b.accentSoft : b.ink,
                  border: ai ? b.accentLine : b.ink,
                  textColor: ai ? b.ink : b.surface,
                  mine: true,
                ),
              ],
            ),
          ),
        );
      case From.sys:
        final (IconData icon, Color color) = switch (m.kind) {
          'invoice' => (Icons.receipt_long_outlined, b.warn),
          'paid' || 'paid_manual' => (Icons.check_circle_outline, b.ok),
          'courier' => (Icons.local_shipping_outlined, b.violet),
          _ => (Icons.inventory_2_outlined, b.violet),
        };
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: b.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: m.kind == 'paid' ? Color.lerp(b.line, b.ok, .45)! : b.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 7),
                Flexible(child: Text(tr.sysText(m), style: tBody(12, b.ink2))),
                const SizedBox(width: 7),
                Text(hhmm(m.at), style: tMono(11, b.ink3)),
              ],
            ),
          ),
        );
      case From.proc:
        return Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: min(380.0, maxWidth)),
            child: _ProcCard(msg: m),
          ),
        );
    }
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.color, required this.border, required this.textColor, required this.mine});
  final String text;
  final Color color;
  final Color border;
  final Color textColor;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: border),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(mine ? 14 : 4),
          topRight: Radius.circular(mine ? 4 : 14),
          bottomLeft: const Radius.circular(14),
          bottomRight: const Radius.circular(14),
        ),
      ),
      child: SelectableText(text, style: tBody(14, textColor, height: 1.48)),
    );
  }
}

class _ProcCard extends StatelessWidget {
  const _ProcCard({required this.msg});
  final Msg msg;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: b.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: b.accentLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (msg.done) Icon(Icons.auto_awesome, size: 15, color: b.accent) else const Spinner(),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  msg.done ? tr.procDone(msg.secs) : tr.s('proc_run'),
                  style: tBody(12.5, b.accent, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final s in msg.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: Center(
                      child: switch (s.state) {
                        'run' => const Spinner(),
                        'warn' => Icon(Icons.warning_amber_rounded, size: 15, color: b.warn),
                        _ => Icon(Icons.check, size: 15, color: b.ok),
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tr.step(s), style: tBody(12.5, s.state == 'run' ? b.ink : b.ink2))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Voice message with transcript, product photo, geolocation or receipt — each with what the AI recognised.
class AttachmentView extends StatelessWidget {
  const AttachmentView({super.key, required this.att});
  final Attachment att;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    final Widget top;
    final IconData recIcon;
    final String recLabel;
    final Widget recBody;
    switch (att.type) {
      case AttType.voice:
        top = Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: b.accent, shape: BoxShape.circle),
                child: Icon(Icons.play_arrow_rounded, color: b.accentInk, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final h in att.bars)
                          Container(
                            width: 3,
                            height: h.toDouble(),
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(color: b.accentLine, borderRadius: BorderRadius.circular(2)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(att.dur ?? '', style: tMono(12, b.ink3)),
            ],
          ),
        );
        recIcon = Icons.auto_awesome;
        recLabel = tr.s('voice_rec');
        recBody = Text(att.transcript ?? '', style: tBody(13, b.ink));
      case AttType.photo:
        top = Container(height: 150, color: b.sunken, alignment: Alignment.center, child: ItemIllustration(item: att.item ?? ''));
        recIcon = Icons.auto_awesome;
        recLabel = tr.s('photo_rec');
        recBody = Text.rich(TextSpan(style: tBody(13, b.ink), children: [
          TextSpan(text: nameOf(att.item ?? '', st.lang), style: tBody(13, b.ink, weight: FontWeight.w600)),
          TextSpan(text: ' · ${tr.s('conf')} ${(att.conf * 100).round()}%'),
        ]));
      case AttType.geo:
        final pl = kPlaces[att.place];
        final hn = int.tryParse(att.house ?? '') ?? 1;
        final lat = ((pl?.lat ?? 42.9) + hn * .00021).toStringAsFixed(4);
        final lng = ((pl?.lng ?? 71.37) - hn * .00017).toStringAsFixed(4);
        top = const MiniMap();
        recIcon = Icons.place_outlined;
        recLabel = tr.s('geo_rec');
        recBody = Text.rich(TextSpan(style: tBody(13, b.ink), children: [
          TextSpan(text: '$lat, $lng', style: tMono(12, b.ink2)),
          const TextSpan(text: '  →  '),
          TextSpan(
            text: '${pl == null ? '' : (st.lang == 'kz' ? pl.kz : pl.ru)}, ${att.house ?? ''}',
            style: tBody(13, b.ink, weight: FontWeight.w600),
          ),
        ]));
      case AttType.receipt:
        top = Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 48,
                decoration: BoxDecoration(color: b.surface2, borderRadius: BorderRadius.circular(6), border: Border.all(color: b.line)),
                child: Icon(Icons.receipt_long_outlined, color: b.ink3),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.s('receipt'), style: tBody(13, b.ink, weight: FontWeight.w600)),
                    Text('IMG_${(att.amount ?? 0) % 10000}.jpg', style: tMono(11.5, b.ink3)),
                  ],
                ),
              ),
            ],
          ),
        );
        recIcon = Icons.auto_awesome;
        recLabel = tr.s('receipt_rec');
        recBody = Text(tr.receiptVal(att.amount ?? 0), style: tBody(13, b.ink));
    }
    return Container(
      width: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: b.surface,
        border: Border.all(color: b.line),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          top,
          Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
            decoration: BoxDecoration(color: b.surface2, border: Border(top: BorderSide(color: b.lineStrong.withAlpha(140)))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(recIcon, size: 13, color: b.accent),
                    const SizedBox(width: 6),
                    Flexible(child: Text(recLabel, style: tBody(11.5, b.accent, weight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 3),
                recBody,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Order card the AI filled in, with the owner's next action.
class OrderPane extends StatelessWidget {
  const OrderPane({super.key, required this.conv});
  final Conv conv;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    final tr = st.tr;
    final c = conv;
    final o = c.order;
    final a = c.analysis;
    if (o == null) {
      return Panel(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: b.accentSoft, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.inventory_2_outlined, color: b.accent),
              ),
              const SizedBox(height: 12),
              Text(tr.s('no_order_t'), style: tBody(15, b.ink, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(tr.s('no_order_d'), style: tBody(13, b.ink2)),
              if (a?.summary != null) ...[const SizedBox(height: 14), _AiSummary(text: a!.summary!.of(st.lang))],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: c.busy ? null : () => st.followUp(c),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(tr.s('act_follow')),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pickup = o.pickup;
    final int base = switch (c.status) { St.lead => 0, St.kaspi => 1, St.paid => 2, St.courier => 3 };
    final si = base + (c.handed ? 1 : 0);
    final labels = ['sts_lead', 'sts_kaspi', 'sts_paid', pickup ? 'sts_pickup' : 'sts_courier'];

    Widget kv(String k, Widget v) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 118, child: Text(k, style: tBody(13, b.ink3))),
              Expanded(child: v),
            ],
          ),
        );
    Widget miss() => Text(tr.s('not_set'), style: tBody(13, b.warn, weight: FontWeight.w600));
    final valStyle = tBody(13, b.ink, weight: FontWeight.w500);

    final List<Widget> actions;
    switch (c.status) {
      case St.lead:
        actions = [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: o.phone == null ? null : () => st.sendInvoice(c),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: Text(tr.s('act_invoice')),
            ),
          ),
          if (o.phone == null) ...[
            const SizedBox(height: 6),
            Text(tr.s('no_phone'), textAlign: TextAlign.center, style: tBody(12, b.ink3)),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: c.busy ? null : () => st.followUp(c),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(tr.s('act_follow')),
            ),
          ),
        ];
      case St.kaspi:
        actions = [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: b.ok, foregroundColor: b.surface),
              onPressed: () => st.confirmPaid(c),
              icon: const Icon(Icons.check, size: 18),
              label: Text(tr.s('act_paid')),
            ),
          ),
          const SizedBox(height: 6),
          Text(tr.s('wait_pay'), textAlign: TextAlign.center, style: tBody(12, b.ink3)),
        ];
      case St.paid:
        if (!pickup) {
          actions = [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => st.toCourier(c),
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: Text(tr.s('act_courier')),
              ),
            ),
          ];
        } else if (c.handed) {
          actions = [_DoneChip(icon: Icons.check, text: tr.s('done_handed'))];
        } else {
          actions = [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => st.handOver(c),
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                label: Text(tr.s('act_handed')),
              ),
            ),
          ];
        }
      case St.courier:
        actions = [_DoneChip(icon: Icons.local_shipping_outlined, text: tr.s('done_courier'))];
    }

    return Panel(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.no, style: tMono(16, b.ink, weight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 13, color: b.accent),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              o.engine == 'claude' ? tr.s('order_auto_claude') : tr.s('order_auto'),
                              style: tBody(12, b.ink3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                StatusPill(c.status, tr.s('st_${c.status.name}')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(color: i <= si ? b.accent : b.sunken, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr.s(labels[i]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tBody(11, i == si ? b.accent : (i < si ? b.ink2 : b.ink3), weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _AiSummary(text: o.summary.of(st.lang)),
            const SizedBox(height: 16),
            Text(tr.s('col_item'), style: tBody(11.5, b.ink3, weight: FontWeight.w600).copyWith(letterSpacing: .5)),
            const SizedBox(height: 4),
            if (o.receiptOnly)
              _LineRow(name: tr.s('receipt_line'), qty: 'Kaspi', sum: money(o.total))
            else
              for (final l in o.lines) _LineRow(name: nameOf(l.id, st.lang), qty: '${l.qty} × ${money(l.price)}', sum: money(l.sum)),
            if (!o.receiptOnly) _SumRow(label: tr.s('subtotal'), value: money(o.subtotal)),
            if (!o.pickup)
              _SumRow(
                label: '${tr.s('delivery')}${o.far ? ' · ${tr.s('far_zone')}' : ''}',
                value: o.delivery > 0 ? money(o.delivery) : tr.s('free'),
              ),
            const SizedBox(height: 10),
            Container(height: 2, color: b.ink),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text(tr.s('total'), style: tBody(14, b.ink, weight: FontWeight.w600))),
                AnimatedNum(
                  value: o.total.toDouble(),
                  builder: (v) => Text(money(v), style: tDisplay(24, b.ink)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            kv(
              pickup ? tr.s('k_pickup') : tr.s('k_address'),
              pickup
                  ? Text(tr.s('pickup_addr'), style: valStyle)
                  : (o.address == null
                      ? miss()
                      : Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(o.address!.of(st.lang), style: valStyle),
                            if (o.geo != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(color: b.accentSoft, borderRadius: BorderRadius.circular(4)),
                                child: Text('GPS', style: tMono(10, b.accent, weight: FontWeight.w600)),
                              ),
                          ],
                        )),
            ),
            kv(
              tr.s('k_phone'),
              o.phone == null
                  ? miss()
                  : Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        SelectableText(o.phone!, style: tMono(13, b.ink, weight: FontWeight.w500)),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: o.phone!));
                            st.plainToast(tr.s('copied'));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(tr.s('copy'), style: tBody(12.5, b.accent, weight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
            ),
            kv(tr.s('k_when'), Text(o.time?.text(st.lang) ?? tr.s('asap'), style: valStyle)),
            kv(tr.s('k_pay'), Text(tr.s('pay_kaspi'), style: valStyle)),
            if (c.courier != null) kv(tr.s('k_courier'), Text('${c.courier} · ~${o.eta - 10} мин', style: valStyle)),
            kv(tr.s('k_lang'), Text(c.lang == 'kz' ? tr.s('lang_kz') : tr.s('lang_ru'), style: valStyle)),
            const SizedBox(height: 8),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _AiSummary extends StatelessWidget {
  const _AiSummary({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final b = Biz.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: b.sunSoft, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 16, color: b.sun),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(st.tr.s('ai_summary'), style: tBody(12, b.ink3)),
                const SizedBox(height: 2),
                Text(text, style: tBody(13, b.ink, weight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.name, required this.qty, required this.sum});
  final String name;
  final String qty;
  final String sum;
  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: b.line))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: tBody(13.5, b.ink, weight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(qty, style: tMono(12, b.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(sum, style: tMono(13, b.ink, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: tBody(13, b.ink2))),
          Text(value, style: tMono(13, b.ink2)),
        ],
      ),
    );
  }
}

class _DoneChip extends StatelessWidget {
  const _DoneChip({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(color: b.violetSoft, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: b.violet),
          const SizedBox(width: 8),
          Text(text, style: tBody(14, b.violet, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}
