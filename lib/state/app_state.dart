import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/catalog.dart';
import '../engine/claude_client.dart';
import '../engine/parser.dart';
import '../engine/replies.dart';
import '../engine/types.dart';
import 'i18n.dart';
import 'models.dart';

enum AppView { dashboard, inbox, analytics }

/// How one simulated conversation should play out.
class FlowOpt {
  const FlowOpt({this.engine = 'local', this.pay = true, this.autoFollow = false, this.focus = false, this.merge = false});
  final String engine; // local | claude
  final bool pay;
  final bool autoFollow;
  final bool focus;
  final bool merge;

  FlowOpt copyWith({bool? pay, bool? autoFollow, bool? merge}) => FlowOpt(
        engine: engine,
        pay: pay ?? this.pay,
        autoFollow: autoFollow ?? this.autoFollow,
        focus: focus,
        merge: merge ?? this.merge,
      );
}

const List<int> _hourWeights = [6, 9, 8, 6, 9, 10, 8, 6, 6, 7, 9, 10, 8, 5, 3];
const Map<String, List<int>> _heat0 = {
  'coffee': [42, 58, 61, 44, 38, 47, 52, 40, 36, 33, 30, 26, 22, 15, 8],
  'dessert': [4, 6, 9, 10, 14, 18, 15, 12, 14, 18, 31, 46, 52, 44, 25],
  'bakery': [30, 41, 35, 28, 34, 31, 20, 16, 14, 12, 10, 9, 6, 4, 2],
  'beans': [2, 5, 8, 9, 7, 6, 5, 6, 4, 3, 2, 1, 1, 0, 0],
};
const Map<String, Map<String, double>> _use = {
  'cap': {'beans': .018, 'milk': .18, 'cups': 1},
  'lat': {'beans': .018, 'milk': .25, 'cups': 1},
  'raf': {'beans': .018, 'milk': .2, 'cups': 1, 'syrup': .02},
  'ame': {'beans': .018, 'cups': 1},
  'cro': {'cro': 1},
  'med': {'med': 1},
  'bean': {'beans': 1},
};
const List<String> _couriers = ['Ерлан', 'Данияр', 'Самат', 'Әли'];
const List<int> kRefusals = [41, 23, 18, 11, 7];

class AppState extends ChangeNotifier {
  AppState() {
    final d = DateTime.now();
    _realStart = d;
    _demoStart = (d.hour >= 10 && d.hour < 21) ? d : DateTime(d.year, d.month, d.day, 14, 20);
  }

  final Random _rnd = Random();
  late final DateTime _realStart;
  late final DateTime _demoStart;

  // ---------- ui ----------
  String lang = 'ru';
  Tr get tr => Tr(lang);
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  AppView view = AppView.dashboard;
  String? sel;
  String filter = 'all';
  String query = '';
  bool orderTab = false;
  bool mobileDetail = false;
  String simLang = 'any';
  bool auto = false;

  // ---------- data ----------
  List<Conv> convs = <Conv>[];
  Metrics m = Metrics();
  int revYesterday = 1;
  List<int> hourly = List<int>.filled(15, 0);
  Map<Ch, ChStat> chStats = <Ch, ChStat>{};
  List<FeedEvent> feed = <FeedEvent>[];
  Map<String, List<int>> heat = <String, List<int>>{};
  List<StockItem> stock = <StockItem>[];
  Set<String> applied = <String>{};
  final List<ToastData> toasts = <ToastData>[];

  // ---------- live AI ----------
  String apiKey = const String.fromEnvironment('CLAUDE_API_KEY');
  String model = 'claude-haiku-5-5';
  bool useClaude = true;
  bool get hasClaude => apiKey.trim().isNotEmpty;

  int _seq = 1040;
  int _convSeq = 0;
  int _toastSeq = 0;
  int _epoch = 0;
  Timer? _autoTimer;
  final List<String> _recent = <String>[];

  // ---------- clock: demo day keeps realistic opening hours ----------
  DateTime now() => _demoStart.add(DateTime.now().difference(_realStart));
  DateTime _minsAgo(num m) => _demoStart.subtract(Duration(seconds: (m * 60).round()));
  static DateTime _addMin(DateTime d, num m) => d.add(Duration(seconds: (m * 60).round()));
  int hourIdx(DateTime d) => (d.hour - 8).clamp(0, 14).toInt();

  Conv? get selected {
    for (final c in convs) {
      if (c.id == sel) return c;
    }
    return null;
  }

  Conv? convById(String? id) {
    if (id == null) return null;
    for (final c in convs) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _n() => notifyListeners();

  T _pick<T>(List<T> list) => list[_rnd.nextInt(list.length)];

  String randPhone() {
    const prefixes = ['701', '702', '705', '707', '708', '747', '771', '775', '777', '778'];
    String two() => (10 + _rnd.nextInt(90)).toString();
    return '+7 ${_pick(prefixes)} ${100 + _rnd.nextInt(900)} ${two()} ${two()}';
  }

  String _nextNo() => 'ДК-${++_seq}';

  // ---------- boot / reset ----------
  void boot() {
    _fresh();
    _seed();
    _n();
  }

  void resetDemo() {
    _epoch++;
    _autoTimer?.cancel();
    _autoTimer = null;
    for (final t in toasts) {
      t.timer?.cancel();
    }
    toasts.clear();
    auto = false;
    _fresh();
    _seed();
    _n();
  }

  void _fresh() {
    convs = <Conv>[];
    m = Metrics();
    hourly = List<int>.filled(15, 0);
    chStats = {Ch.ig: ChStat(18, 46800), Ch.tg: ChStat(10, 26600), Ch.wa: ChStat(22, 68900)};
    feed = <FeedEvent>[];
    heat = {for (final e in _heat0.entries) e.key: List<int>.of(e.value)};
    stock = <StockItem>[
      StockItem('beans', 'Кофе в зёрнах', 'Кофе дәні', 'кг', 'кг', 9.8, 4.1, true),
      StockItem('cro', 'Круассаны', 'Круассандар', 'шт', 'дана', 34, 41, false),
      StockItem('med', 'Торт «Медовик»', '«Медовик» торты', 'шт', 'дана', 3, 2.6, false),
      StockItem('milk', 'Молоко 3,2%', 'Сүт 3,2%', 'л', 'л', 26, 14.5, true),
      StockItem('cups', 'Стаканы 0,4 л', 'Стақандар 0,4 л', 'шт', 'дана', 420, 95, false),
      StockItem('syrup', 'Сироп ванильный', 'Ванильді шәрбат', 'л', 'л', 1.8, .35, true),
    ];
    applied = <String>{};
    sel = null;
    filter = 'all';
    query = '';
    orderTab = false;
    mobileDetail = false;
    _seq = 1040;
    _recent.clear();
  }

  Attachment? _attFrom(Attachment? spec, String text) {
    if (spec == null) return null;
    final a = spec.copy();
    if (a.type == AttType.voice) {
      a.transcript = text;
      a.bars = _bars(text);
    }
    return a;
  }

  List<int> _bars(String seed) {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    final out = <int>[];
    for (var i = 0; i < 34; i++) {
      h = (h * 1103515245 + 12345) & 0x7fffffff;
      out.add(5 + (h % 21));
    }
    return out;
  }

  void _seed() {
    final cur = now();
    final ci = hourIdx(cur);
    final w = <double>[
      for (var i = 0; i < 15; i++)
        i < ci ? _hourWeights[i].toDouble() : (i == ci ? _hourWeights[i] * max(.15, cur.minute / 60) : 0.0),
    ];
    final total = w.fold<double>(0, (a, b) => a + b);
    var acc = 0;
    for (var i = 0; i < 15; i++) {
      final v = total == 0 ? 0 : ((m.rev * w[i] / total) / 100).round() * 100;
      hourly[i] = v;
      acc += v;
    }
    hourly[max(0, ci - 1)] += m.rev - acc;

    for (final sd in kSeeds) {
      final at = _minsAgo(sd.ago);
      final ch = Ch.values.byName(sd.ch);
      final c = Conv(
        id: 'c${++_convSeq}',
        ch: ch,
        lang: sd.lang,
        name: sd.name,
        handle: sd.handle,
        contact: ch == Ch.wa ? (sd.contact ?? randPhone()) : null,
        createdAt: at,
      );
      final att = _attFrom(sd.att, sd.text);
      c.msgs.add(Msg(from: From.client, at: at, text: att?.type == AttType.voice ? '' : sd.text, att: att));
      final a = analyze(sd.text, sd.att, sd.lang, c.contact);
      a.summary = summarize(a);
      final o = a.items.isEmpty ? null : buildOrder(a);
      if (o != null) o.no = _nextNo();
      final st = decideStatus(o);
      c.analysis = a;
      c.order = o;
      c.counted = true;
      final steps = <ProcStep>[ProcStep('s_lang', [a.lang], 'ok')];
      if (att?.type == AttType.voice) steps.add(ProcStep('s_voice', [], 'ok'));
      if (a.geo != null) steps.add(ProcStep('s_geo', [], 'ok'));
      if (a.photoItem != null) steps.add(ProcStep('s_photo_item', [a.photoItem!], 'ok'));
      steps.add(ProcStep('s_items', [o?.lines.length ?? 0], 'ok'));
      if (o != null) steps.add(ProcStep('s_sum', [o.total], 'ok'));
      steps.add(ProcStep(st == St.kaspi ? 's_invoice' : 's_clarify', [], 'ok'));
      c.msgs.add(Msg(from: From.proc, at: _addMin(at, .1), steps: steps, done: true, secs: 1.8 + _rnd.nextDouble() * 1.4));
      c.msgs.add(Msg(from: From.ai, at: _addMin(at, .15), text: composeReply(c.lang, c.name, o, st, a)));
      m.dialogs++;
      m.ai++;
      m.noOp++;
      chStats[ch]!.d++;
      _feed('new', {'name': c.name, 'ch': ch.label}, at, c.id);
      c.status = st;
      if (st == St.kaspi && o != null) {
        c.msgs.add(Msg(from: From.sys, kind: 'invoice', at: _addMin(at, .2), amount: o.total, no: o.no));
        _feed('invoice', {'sum': o.total, 'no': o.no}, _addMin(at, .2), c.id);
        if (sd.status == 'paid' || sd.status == 'courier') {
          final pa = _addMin(at, 3);
          c.msgs.add(Msg(from: From.client, at: pa, text: receiptCaption(c.lang), att: Attachment(type: AttType.receipt, amount: o.total)));
          c.msgs.add(Msg(from: From.sys, kind: 'paid', at: _addMin(at, 3.2), amount: o.total));
          c.msgs.add(Msg(from: From.ai, at: _addMin(at, 3.25), text: paidReply(c.lang, o)));
          c.status = St.paid;
          _applyPaid(c, o.total, _addMin(at, 3.2));
          if (sd.status == 'courier' && !o.pickup) {
            final ca = _addMin(at, 9);
            c.courier = _pick<String>(_couriers);
            c.status = St.courier;
            c.msgs.add(Msg(from: From.sys, kind: 'courier', at: ca, courier: c.courier, eta: o.eta));
            c.msgs.add(Msg(from: From.ai, at: _addMin(ca, .1), text: courierReply(c.lang, c.courier!, o.eta - 10)));
            _feed('courier', {'no': o.no, 'c': c.courier!}, ca, c.id);
          }
        }
      } else {
        _feed('clarify', {'name': c.name}, _addMin(at, .2), c.id);
      }
      c.updatedAt = c.msgs.last.at;
      c.unread = sd.unread;
      convs.add(c);
    }
    convs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    feed.sort((a, b) => b.at.compareTo(a.at));
    revYesterday = (m.rev / 1.14).round();
  }

  // ---------- bookkeeping ----------
  void _feed(String type, Map<String, Object> p, DateTime at, String? convId) {
    feed.insert(0, FeedEvent(type, p, at, convId));
    if (feed.length > 40) feed.removeRange(40, feed.length);
  }

  void _applyPaid(Conv c, int amount, DateTime at) {
    m.paid++;
    m.rev += amount;
    hourly[hourIdx(at)] += amount;
    chStats[c.ch]!.r += amount;
    final o = c.order;
    if (o != null) {
      for (final l in o.lines) {
        final u = _use[l.id];
        if (u == null) continue;
        u.forEach((k, v) {
          for (final s in stock) {
            if (s.id == k) s.qty = max(0.0, s.qty - v * l.qty);
          }
        });
      }
    }
    _feed('paid', {'sum': amount, 'no': o?.no ?? ''}, at, c.id);
  }

  void _heatAdd(List<Item> items, DateTime at) {
    final i = hourIdx(at);
    for (final it in items) {
      final cat = kP[it.id]?.cat;
      final row = cat == null ? null : heat[cat];
      if (row != null) row[i] += 1;
    }
  }

  bool _isOpen(Conv c) => view == AppView.inbox && sel == c.id;

  Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  // ---------- simulation ----------
  List<String> _pickName(String l) {
    final used = convs.map((c) => c.name).toSet();
    final pool = kNames[l]!.where((n) => !used.contains(n[0])).toList();
    return _pick(pool.isEmpty ? kNames[l]! : pool);
  }

  /// One click on «Симулировать обращение».
  void simulate({Ch? ch, bool isAuto = false, bool? focus}) {
    final Ch channel = ch ?? (isAuto ? _pick<Ch>(Ch.values) : _pick<Ch>(const [Ch.ig, Ch.tg]));
    final pool = kTemplates.where((t) => (simLang == 'any' || t.lang == simLang) && (isAuto || !t.faq)).toList();
    var cand = pool.where((t) => !_recent.contains(t.id)).toList();
    if (cand.isEmpty) cand = pool;
    final tpl = _pick(cand);
    _recent.add(tpl.id);
    if (_recent.length > 6) _recent.removeAt(0);
    final nm = _pickName(tpl.lang);
    final c = Conv(
      id: 'c${++_convSeq}',
      ch: channel,
      lang: tpl.lang,
      name: nm[0],
      handle: channel == Ch.wa ? null : nm[1],
      contact: channel == Ch.wa ? randPhone() : null,
      createdAt: now(),
    );
    final att = _attFrom(tpl.att, tpl.text);
    final msg = Msg(from: From.client, at: now(), text: att?.type == AttType.voice ? '' : tpl.text, att: att);
    _startConversation(
      c,
      msg,
      FlowOpt(pay: isAuto ? _rnd.nextDouble() < .8 : true, autoFollow: isAuto, focus: focus ?? view == AppView.inbox),
    );
  }

  /// A message typed by hand in «Своё сообщение».
  void submitCustom({required String text, required String name, required Ch ch}) {
    final l = detectLang(text) ?? lang;
    final nm = name.trim().isEmpty ? _pickName(l)[0] : name.trim();
    final handle = '@${nm.toLowerCase().replaceAll(RegExp(r'\s+'), '.').replaceAll(RegExp(r'[^\p{L}\p{N}._]', unicode: true), '')}';
    final c = Conv(
      id: 'c${++_convSeq}',
      ch: ch,
      lang: l,
      name: nm,
      handle: ch == Ch.wa ? null : (handle.length > 19 ? handle.substring(0, 19) : handle),
      contact: ch == Ch.wa ? randPhone() : null,
      createdAt: now(),
    );
    final msg = Msg(from: From.client, at: now(), text: text);
    _startConversation(c, msg, FlowOpt(engine: (hasClaude && useClaude) ? 'claude' : 'local', focus: true));
  }

  Future<void> _startConversation(Conv c, Msg msg, FlowOpt opt) async {
    final ep = _epoch;
    c.typing = true;
    c.busy = true;
    c.updatedAt = now();
    convs.insert(0, c);
    m.dialogs++;
    chStats[c.ch]!.d++;
    _feed('new', {'name': c.name, 'ch': c.ch.label}, now(), c.id);
    _toastFor(c, msg);
    if (opt.focus) openConv(c.id, keepTab: true);
    _n();
    await _wait(700);
    if (ep != _epoch) return;
    c.typing = false;
    msg.at = now();
    c.msgs.add(msg);
    c.updatedAt = now();
    if (!_isOpen(c)) c.unread = true;
    _n();
    await _wait(350);
    if (ep != _epoch) return;
    await _process(c, opt);
  }

  Future<void> _process(Conv c, FlowOpt opt) async {
    final ep = _epoch;
    final sw = Stopwatch()..start();
    c.busy = true;
    Msg? last;
    for (final x in c.msgs.reversed) {
      if (x.from == From.client) {
        last = x;
        break;
      }
    }
    if (last == null) return;
    final att = last.att;
    final text = att?.type == AttType.voice ? (att?.transcript ?? '') : last.text;
    var a = analyze(text, att, c.lang, c.contact);
    final prev = c.analysis;
    if (opt.merge && prev != null) a = mergeAnalysis(prev, a);

    final proc = Msg(from: From.proc, at: now());
    c.msgs.add(proc);
    _toastStage(c, 'parsing');
    _n();

    Future<bool> step(String k, List<Object> args, [int ms = 430]) async {
      final s = ProcStep(k, args, 'run');
      proc.steps.add(s);
      _n();
      await _wait(ms);
      if (ep != _epoch) return false;
      s.state = 'ok';
      _n();
      return true;
    }

    if (!await step('s_lang', [a.lang])) return;
    c.lang = a.lang;
    if (att?.type == AttType.voice && !await step('s_voice', [])) return;
    if (att?.type == AttType.geo && !await step('s_geo', [])) return;
    if (att?.type == AttType.photo && att?.item != null && !await step('s_photo_item', [att!.item!])) return;

    if (opt.engine == 'claude' && hasClaude) {
      final s = ProcStep('s_claude', [], 'run');
      proc.steps.add(s);
      _n();
      try {
        final r = await ClaudeClient(apiKey: apiKey.trim(), model: model.trim()).parseOrder(text);
        if (ep != _epoch) return;
        a = fromClaude(r, a);
        if (opt.merge && prev != null) a = mergeAnalysis(prev, a)..engine = 'claude';
        s.state = 'ok';
        c.lang = a.lang;
      } catch (e) {
        if (ep != _epoch) return;
        s.state = 'warn';
        s.k = 's_claude_fail';
        plainToast(e.toString(), err: true);
      }
      _n();
    }
    if (a.summary == null || a.engine != 'claude') a.summary = summarize(a);

    final hadItems = c.order != null && c.order!.lines.isNotEmpty;
    final o = a.items.isEmpty ? null : buildOrder(a);
    if (o != null) o.no = (c.order != null && c.order!.no.isNotEmpty) ? c.order!.no : _nextNo();
    c.analysis = a;
    c.order = o;
    if (!await step('s_items', [o?.lines.length ?? 0])) return;
    if (o != null && !await step('s_sum', [o.total])) return;
    final st = decideStatus(o);
    if (!await step(st == St.kaspi ? 's_invoice' : 's_clarify', [], 300)) return;
    proc.done = true;
    proc.secs = sw.elapsedMilliseconds / 1000;
    c.status = st;
    c.msgs.add(Msg(from: From.ai, at: now(), text: composeReply(c.lang, c.name, o, st, a)));
    if (!c.counted) {
      c.counted = true;
      m.ai++;
      m.noOp++;
    }
    if (o != null && !hadItems) _heatAdd(a.items, now());
    if (st == St.kaspi && o != null) {
      c.msgs.add(Msg(from: From.sys, kind: 'invoice', at: now(), amount: o.total, no: o.no));
      _feed('invoice', {'sum': o.total, 'no': o.no}, now(), c.id);
      _toastStage(c, 'invoiced');
    } else {
      _feed('clarify', {'name': c.name}, now(), c.id);
      _toastStage(c, 'clarify');
    }
    c.updatedAt = now();
    c.busy = false;
    if (!_isOpen(c)) c.unread = true;
    _n();
    if (st == St.kaspi && opt.pay) {
      _schedulePayment(c, opt);
    } else if (st == St.lead && opt.autoFollow && _rnd.nextDouble() < .75) {
      await _wait(4200);
      if (ep != _epoch) return;
      await followUp(c, pay: _rnd.nextDouble() < .85, isAuto: true);
    }
  }

  Future<void> _schedulePayment(Conv c, FlowOpt opt) async {
    final ep = _epoch;
    await _wait(3600 + _rnd.nextInt(1800));
    if (ep != _epoch || c.status != St.kaspi) return;
    final o = c.order;
    if (o == null) return;
    c.msgs.add(Msg(from: From.client, at: now(), text: receiptCaption(c.lang), att: Attachment(type: AttType.receipt, amount: o.total)));
    c.updatedAt = now();
    if (!_isOpen(c)) c.unread = true;
    _n();
    await _wait(1000);
    if (ep != _epoch || c.status != St.kaspi) return;
    confirmPaid(c, viaReceipt: true);
    if (opt.autoFollow && !o.pickup) {
      await _wait(5000);
      if (ep != _epoch || c.status != St.paid) return;
      toCourier(c);
    }
  }

  // ---------- owner actions ----------
  void confirmPaid(Conv c, {bool viaReceipt = false}) {
    final o = c.order;
    if (o == null || (c.status != St.kaspi && c.status != St.lead)) return;
    c.status = St.paid;
    c.msgs.add(Msg(from: From.sys, kind: viaReceipt ? 'paid' : 'paid_manual', at: now(), amount: o.total));
    c.msgs.add(Msg(from: From.ai, at: now(), text: paidReply(c.lang, o)));
    _applyPaid(c, o.total, now());
    c.updatedAt = now();
    _toastStage(c, 'paid');
    _n();
  }

  void toCourier(Conv c) {
    final o = c.order;
    if (o == null || c.status != St.paid || o.pickup) return;
    c.courier = _pick<String>(_couriers);
    c.status = St.courier;
    c.msgs.add(Msg(from: From.sys, kind: 'courier', at: now(), courier: c.courier, eta: o.eta));
    c.msgs.add(Msg(from: From.ai, at: now(), text: courierReply(c.lang, c.courier!, o.eta - 10)));
    _feed('courier', {'no': o.no, 'c': c.courier!}, now(), c.id);
    c.updatedAt = now();
    _n();
  }

  void handOver(Conv c) {
    final o = c.order;
    if (o == null || c.status != St.paid) return;
    c.handed = true;
    c.msgs.add(Msg(from: From.sys, kind: 'handed', at: now()));
    _feed('handed', {'no': o.no}, now(), c.id);
    c.updatedAt = now();
    _n();
  }

  void sendInvoice(Conv c) {
    final o = c.order;
    if (o == null || c.status != St.lead) return;
    if (o.phone == null) {
      plainToast(tr.s('no_phone'), err: true);
      return;
    }
    c.status = St.kaspi;
    c.msgs.add(Msg(from: From.sys, kind: 'invoice', at: now(), amount: o.total, no: o.no));
    c.msgs.add(Msg(from: From.ai, at: now(), text: invoiceReply(c.lang, o)));
    _feed('invoice', {'sum': o.total, 'no': o.no}, now(), c.id);
    c.updatedAt = now();
    _n();
    _schedulePayment(c, const FlowOpt());
  }

  Future<void> followUp(Conv c, {bool pay = true, bool isAuto = false}) async {
    if (c.status != St.lead || c.busy) return;
    final ep = _epoch;
    final a = c.analysis;
    final String need;
    if (a == null || a.items.isEmpty) {
      need = 'items';
    } else if (a.address == null && !a.pickup && a.phone == null) {
      need = 'both';
    } else if (a.phone == null) {
      need = 'phone';
    } else {
      need = 'address';
    }
    c.busy = true;
    c.msgs.add(Msg(from: From.client, at: now(), text: followUpText(c.lang, need, randPhone())));
    c.updatedAt = now();
    if (!_isOpen(c)) c.unread = true;
    _n();
    await _wait(450);
    if (ep != _epoch) return;
    await _process(c, FlowOpt(merge: true, pay: pay, autoFollow: isAuto));
  }

  void operatorReply(Conv c, String text) {
    final v = text.trim();
    if (v.isEmpty) return;
    c.msgs.add(Msg(from: From.op, at: now(), text: v));
    c.updatedAt = now();
    if (!c.opTouched) {
      c.opTouched = true;
      m.noOp = max(0, m.noOp - 1);
    }
    _n();
  }

  void toggleRec(String id) {
    if (applied.contains(id)) {
      applied.remove(id);
    } else {
      applied.add(id);
      _feed('rec', {'id': id}, now(), null);
    }
    _n();
  }

  // ---------- auto-flow (local engine only) ----------
  void setAuto(bool on) {
    auto = on;
    _autoTimer?.cancel();
    _autoTimer = null;
    if (on) {
      _autoTick();
      _autoTimer = Timer.periodic(const Duration(seconds: 7), (_) => _autoTick());
    }
    _n();
  }

  void _autoTick() {
    if (!auto) return;
    final busy = convs.where((c) => c.busy || c.typing).length;
    if (busy < 3) simulate(isAuto: true, focus: false);
  }

  // ---------- navigation ----------
  void setView(AppView v) {
    view = v;
    if (v == AppView.inbox) mobileDetail = false;
    _n();
  }

  void openConv(String id, {bool keepTab = false}) {
    final c = convById(id);
    if (c == null) return;
    sel = id;
    c.unread = false;
    view = AppView.inbox;
    mobileDetail = true;
    if (!keepTab) orderTab = false;
    if (filter != 'all' && filter != c.status.name) filter = 'all';
    _n();
  }

  void closeDetail() {
    mobileDetail = false;
    _n();
  }

  void setOrderTab(bool v) {
    orderTab = v;
    _n();
  }

  void setFilter(String f) {
    filter = f;
    _n();
  }

  void setQuery(String q) {
    query = q;
    _n();
  }

  void setLang(String l) {
    lang = l;
    _n();
  }

  void setSimLang(String l) {
    simLang = l;
    _n();
  }

  void setClaude({String? key, String? modelId, bool? enabled}) {
    if (key != null) apiKey = key;
    if (modelId != null && modelId.trim().isNotEmpty) model = modelId.trim();
    if (enabled != null) useClaude = enabled;
    _n();
  }

  List<Conv> get visibleConvs {
    final q = query.trim().toLowerCase();
    return convs.where((c) {
      if (filter != 'all' && c.status.name != filter) return false;
      if (q.isEmpty) return true;
      final hay = '${c.name} ${c.handle ?? ''} ${c.contact ?? ''} ${c.order?.phone ?? ''}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  int get unreadCount => convs.where((c) => c.unread).length;

  // ---------- toasts ----------
  void _toastFor(Conv c, Msg msg) {
    final t = ToastData(id: ++_toastSeq, convId: c.id, stage: 'new', msg: msg);
    toasts.insert(0, t);
    while (toasts.length > 3) {
      toasts.removeLast().timer?.cancel();
    }
    _armToast(t);
  }

  void _toastStage(Conv c, String stage) {
    ToastData? t;
    for (final x in toasts) {
      if (x.convId == c.id) t = x;
    }
    if (t == null) return;
    t.stage = stage;
    _armToast(t);
  }

  void _armToast(ToastData t) {
    t.timer?.cancel();
    final ms = switch (t.stage) {
      'new' || 'parsing' => 16000,
      'invoiced' => 9500,
      'paid' => 4500,
      'clarify' => 5500,
      _ => 3200,
    };
    t.timer = Timer(Duration(milliseconds: ms), () => dismissToast(t.id));
  }

  void plainToast(String text, {bool err = false}) {
    final t = ToastData(id: ++_toastSeq, stage: 'plain', text: text, err: err);
    toasts.insert(0, t);
    while (toasts.length > 3) {
      toasts.removeLast().timer?.cancel();
    }
    _armToast(t);
    _n();
  }

  void dismissToast(int id) {
    toasts.removeWhere((t) {
      if (t.id == id) {
        t.timer?.cancel();
        return true;
      }
      return false;
    });
    _n();
  }

  void openFromToast(ToastData t) {
    final id = t.convId;
    dismissToast(t.id);
    if (id != null) openConv(id);
  }

  // ---------- analytics helpers ----------
  double get timeSavedHours => m.ai * 6 / 60;
  int get conversionPct => m.dialogs == 0 ? 0 : (m.paid / m.dialogs * 100).round();
  int get noOpPct => m.ai == 0 ? 0 : (m.noOp / m.ai * 100).round();
  int get revDeltaPct => ((m.rev / revYesterday - 1) * 100).round();

  int get dessertEveningPct {
    int sumAt(String k) => [11, 12, 13, 14].fold<int>(0, (x, i) => x + heat[k]![i]);
    final all = ['coffee', 'dessert', 'bakery', 'beans'].fold<int>(0, (x, k) => x + sumAt(k));
    return all == 0 ? 0 : (sumAt('dessert') / all * 100).round();
  }

  StockItem stockById(String id) => stock.firstWhere((s) => s.id == id);

  @override
  void dispose() {
    _autoTimer?.cancel();
    for (final t in toasts) {
      t.timer?.cancel();
    }
    themeMode.dispose();
    super.dispose();
  }
}

/// Gives every widget access to the [AppState].
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.state, required super.child});
  final AppState state;

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.state;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.state != state;
}
