import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/i18n.dart';
import '../state/models.dart';
import '../theme.dart';
import 'widgets.dart';

/// Bottom sheet on phones, dialog on wide screens.
Future<void> showAdaptiveSheet(BuildContext context, WidgetBuilder builder) {
  final b = Biz.of(context);
  final w = MediaQuery.sizeOf(context).width;
  if (w < 700) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: b.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: builder(ctx),
        ),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: b.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: builder(ctx)),
      ),
    ),
  );
}

class _SheetHead extends StatelessWidget {
  const _SheetHead({required this.title, this.hint});
  final String title;
  final String? hint;
  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: tBody(17, b.ink, weight: FontWeight.w700))),
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.close, color: b.ink2),
            ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint!, style: tBody(13, b.ink2)),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: tBody(12, b.ink3, weight: FontWeight.w600)),
    );
  }
}

// ---------------- simulator ----------------

Future<void> showSimulatorSheet(BuildContext context) {
  final st = AppScope.of(context);
  return showAdaptiveSheet(
    context,
    (ctx) => AnimatedBuilder(
      animation: st,
      builder: (ctx, _) => _SimulatorBody(st: st, hostContext: context),
    ),
  );
}

class _SimulatorBody extends StatelessWidget {
  const _SimulatorBody({required this.st, required this.hostContext});
  final AppState st;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final b = Biz.of(context);
    final tr = st.tr;
    Widget chButton(Ch ch) => Expanded(
          child: Material(
            color: b.surface2,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).pop();
                st.simulate(ch: ch);
              },
              child: Ink(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: b.line)),
                child: Column(
                  children: [
                    ChannelChip(ch, big: true),
                    const SizedBox(height: 8),
                    Text(ch.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: tBody(12.5, b.ink, weight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHead(title: tr.s('sim_title'), hint: tr.s('sim_hint')),
        const SizedBox(height: 16),
        _Label(tr.s('sim_lang')),
        Seg<String>(
          value: st.simLang,
          expand: true,
          onChanged: st.setSimLang,
          options: [('any', tr.s('any')), ('ru', 'Русский'), ('kz', 'Қазақша')],
        ),
        const SizedBox(height: 16),
        _Label(tr.s('sim_from')),
        Row(children: [chButton(Ch.ig), const SizedBox(width: 8), chButton(Ch.tg), const SizedBox(width: 8), chButton(Ch.wa)]),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).pop();
              showCustomMessageSheet(hostContext);
            },
            child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: b.lineStrong)),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: b.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr.s('custom'), style: tBody(14, b.ink, weight: FontWeight.w600)),
                        Text(tr.s('custom_d'), style: tBody(12, b.ink3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Divider(color: b.line, height: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr.s('auto'), style: tBody(14, b.ink, weight: FontWeight.w600)),
                  Text(tr.s('auto_d'), style: tBody(12, b.ink3)),
                ],
              ),
            ),
            Switch(value: st.auto, onChanged: st.setAuto),
          ],
        ),
      ],
    );
  }
}

// ---------------- custom message ----------------

Future<void> showCustomMessageSheet(BuildContext context) {
  final st = AppScope.of(context);
  return showAdaptiveSheet(context, (ctx) => _CustomMessageBody(st: st));
}

class _CustomMessageBody extends StatefulWidget {
  const _CustomMessageBody({required this.st});
  final AppState st;
  @override
  State<_CustomMessageBody> createState() => _CustomMessageBodyState();
}

class _CustomMessageBodyState extends State<_CustomMessageBody> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _text = TextEditingController();
  Ch _ch = Ch.ig;
  bool _error = false;

  @override
  void dispose() {
    _name.dispose();
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = true);
      return;
    }
    Navigator.of(context).pop();
    widget.st.submitCustom(text: text, name: _name.text, ch: _ch);
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final b = Biz.of(context);
    final tr = st.tr;
    final live = st.hasClaude && st.useClaude;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHead(title: tr.s('cmp_title')),
        const SizedBox(height: 14),
        _Label(tr.s('cmp_channel')),
        Seg<Ch>(
          value: _ch,
          expand: true,
          onChanged: (v) => setState(() => _ch = v),
          options: [for (final c in Ch.values) (c, c.label)],
        ),
        const SizedBox(height: 14),
        _Label(tr.s('cmp_name')),
        TextField(controller: _name, style: tBody(14, b.ink), decoration: InputDecoration(hintText: tr.s('cmp_name_ph'))),
        const SizedBox(height: 14),
        _Label(tr.s('cmp_text')),
        TextField(
          controller: _text,
          minLines: 3,
          maxLines: 6,
          style: tBody(14, b.ink),
          onChanged: (_) {
            if (_error) setState(() => _error = false);
          },
          decoration: InputDecoration(hintText: tr.s('cmp_text_ph')),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final ex in Tr.examples)
              ActionChip(
                label: Text(ex[0], style: tBody(12, b.ink2, weight: FontWeight.w500)),
                backgroundColor: b.surface,
                side: BorderSide(color: b.line),
                shape: const StadiumBorder(),
                onPressed: () => setState(() {
                  _text.text = ex[1];
                  _error = false;
                }),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: live ? b.sunSoft : b.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: live ? Color.lerp(b.line, b.sun, .35)! : b.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, size: 18, color: live ? b.sun : b.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(live ? tr.s('cmp_live') : tr.s('cmp_local'), style: tBody(13, b.ink, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(live ? tr.s('cmp_live_d') : tr.s('cmp_local_d'), style: tBody(12.5, b.ink2)),
                  ],
                ),
              ),
              if (st.hasClaude)
                Switch(
                  value: st.useClaude,
                  onChanged: (v) => setState(() => st.setClaude(enabled: v)),
                ),
            ],
          ),
        ),
        if (_error) ...[
          const SizedBox(height: 10),
          Text(tr.s('cmp_need'), style: tBody(12.5, b.danger, weight: FontWeight.w600)),
        ],
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr.s('cancel'))),
            FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.send_rounded, size: 18), label: Text(tr.s('cmp_submit'))),
          ],
        ),
      ],
    );
  }
}

// ---------------- settings ----------------

Future<void> showSettingsSheet(BuildContext context) {
  final st = AppScope.of(context);
  return showAdaptiveSheet(context, (ctx) => _SettingsBody(st: st));
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody({required this.st});
  final AppState st;
  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  late final TextEditingController _key = TextEditingController(text: widget.st.apiKey);
  late final TextEditingController _model = TextEditingController(text: widget.st.model);
  bool _show = false;

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.st;
    final b = Biz.of(context);
    final tr = st.tr;
    return AnimatedBuilder(
      animation: Listenable.merge([st, st.themeMode]),
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHead(title: tr.s('settings')),
          const SizedBox(height: 14),
          _Label(tr.s('interface_lang')),
          Seg<String>(
            value: st.lang,
            expand: true,
            onChanged: st.setLang,
            options: const [('ru', 'Русский'), ('kz', 'Қазақша')],
          ),
          const SizedBox(height: 14),
          _Label(tr.s('theme')),
          Seg<ThemeMode>(
            value: st.themeMode.value,
            expand: true,
            onChanged: (v) => st.themeMode.value = v,
            options: [
              (ThemeMode.system, tr.s('theme_system')),
              (ThemeMode.light, tr.s('theme_light')),
              (ThemeMode.dark, tr.s('theme_dark')),
            ],
          ),
          const SizedBox(height: 18),
          _Label(tr.s('claude_key')),
          TextField(
            controller: _key,
            obscureText: !_show,
            autocorrect: false,
            enableSuggestions: false,
            style: tMono(13, b.ink),
            onChanged: (v) => st.setClaude(key: v),
            decoration: InputDecoration(
              hintText: 'sk-ant-…',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _show = !_show),
                icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: b.ink3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Label(tr.s('claude_model')),
          TextField(
            controller: _model,
            autocorrect: false,
            style: tMono(13, b.ink),
            onChanged: (v) => st.setClaude(modelId: v),
          ),
          const SizedBox(height: 8),
          Text(tr.s('claude_note'), style: tBody(12, b.ink3)),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  st.resetDemo();
                },
                icon: Icon(Icons.refresh, size: 18, color: b.ink2),
                label: Text(tr.s('reset'), style: tBody(13, b.ink2, weight: FontWeight.w500)),
              ),
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr.s('done'))),
            ],
          ),
        ],
      ),
    );
  }
}
