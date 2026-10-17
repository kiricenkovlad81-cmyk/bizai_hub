import 'dart:math';

import 'catalog.dart';
import 'types.dart';

/// Rule-based order parser for Russian and Kazakh messages.
/// Finds products and quantities, Taraz addresses, phone numbers,
/// delivery time, pickup and questions about opening hours.

final RegExp _phoneRe = RegExp(
    r'(?:\+\s?7|(?<!\d)8)[\s\-()]*(7\d{2})[\s\-()]*(\d{3})[\s\-]*(\d{2})[\s\-]*(\d{2})(?!\d)',
    unicode: true);
final RegExp _timeRe = RegExp(r'(\d{1,2})[:.](\d{2})(?:\s*-?\s*(?:ге|ға|қа|ке))?', unicode: true);
final RegExp _tomorrowRe = RegExp(r'(завтра|ертең)', unicode: true);
final RegExp _pickupRe = RegExp(r'самовывоз|сам заберу|заберу|заберем|алып кет|өзім ал|өзім кел', unicode: true);
final RegExp _hoursRe = RegExp(
    r'до скольки|часы работы|во сколько закрыва|режим работы|қашанға дейін|жұмыс уақыт|сағат нешеге',
    unicode: true);
final RegExp _dessertRe = RegExp(r'десерт|сладк|к чаю|тәтті|торт', unicode: true);
final RegExp _kzLetters = RegExp(r'[әғқңөұүһі]', unicode: true);
final RegExp _kzWords = RegExp(r'(салем|рахмет|керек|бар ма)', unicode: true);
final RegExp _cyr = RegExp(r'[а-я]', unicode: true);
final RegExp _tokSplit = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
final RegExp _digits3 = RegExp(r'^\d{1,3}$');
final RegExp _digits2 = RegExp(r'^\d{1,2}$');
final RegExp _xQty = RegExp(r'^[xх]\d{1,2}$', unicode: true);
final RegExp _unitTok = RegExp(r'^(шт|штук|штуки|дана|порци)', unicode: true);
final RegExp _houseRe = RegExp(r'^[^\d]{0,24}?(\d{1,4})(?![\d:])', unicode: true);
final RegExp _aptRe = RegExp(r'^\s*[,.]?\s*(?:(кв\.?|квартира|офис)\s*(\d{1,4})|(\d{1,4})\s*-?\s*пәтер)', unicode: true);

String norm(String s) => s.toLowerCase().replaceAll('ё', 'е');

String? detectLang(String text) {
  final s = norm(text);
  if (_kzLetters.hasMatch(s)) return 'kz';
  if (_kzWords.hasMatch(s)) return 'kz';
  return _cyr.hasMatch(s) ? 'ru' : null;
}

CatalogItem? _matchItem(String w) {
  for (final c in kCatalog) {
    if (c.ex.any((x) => w.startsWith(x))) continue;
    if (c.keys.any((k) => w.startsWith(k))) return c;
  }
  return null;
}

List<Item> parseItems(String s, String lang) {
  final toks = s.split(_tokSplit).where((t) => t.isNotEmpty).toList();
  final words = <String, int>{...kNumRu, if (lang == 'kz') ...kNumKz};
  final found = <String, int>{};
  final order = <String>[];
  int? pendN;
  var pendPos = -100;
  for (var i = 0; i < toks.length; i++) {
    final w = toks[i];
    int? n;
    if (_digits3.hasMatch(w)) {
      n = int.parse(w);
    } else if (words.containsKey(w)) {
      n = words[w];
    }
    if (n != null) {
      if (lang == 'kz' && (w == 'он' || w == 'жиырма') && i + 1 < toks.length && kKzUnits.containsKey(toks[i + 1])) {
        n = n + kKzUnits[toks[i + 1]]!;
        i++;
      }
      pendN = n;
      pendPos = i;
      continue;
    }
    final item = _matchItem(w);
    if (item == null) continue;
    int? q;
    if (pendN != null && i - pendPos <= 4) {
      q = pendN;
      pendN = null;
    }
    final nx = i + 1 < toks.length ? toks[i + 1] : null;
    if (q == null && nx != null && _xQty.hasMatch(nx)) q = int.parse(nx.substring(1));
    if (q == null && nx != null && _digits2.hasMatch(nx) && i + 2 < toks.length && _unitTok.hasMatch(toks[i + 2])) {
      q = int.parse(nx);
      i += 2;
    }
    if (q != null && item.pack > 0 && q >= item.pack) q = (q / item.pack).ceil();
    if (found.containsKey(item.id)) {
      if (q != null) found[item.id] = min(99, found[item.id]! + q);
    } else {
      found[item.id] = min(99, max(1, q ?? 1));
      order.add(item.id);
    }
  }
  return <Item>[for (final id in order) Item(id, found[id]!)];
}

int? _unitQty(String s, String lang) {
  final words = <String, int>{...kNumRu, if (lang == 'kz') ...kNumKz};
  final alt = words.keys.join('|');
  final m = RegExp('(?<![\\p{L}\\p{N}])(\\d{1,2}|$alt)\\s*(?:штук|шт|дана|порци)', unicode: true).firstMatch(s);
  if (m == null) return null;
  final v = m[1]!;
  return int.tryParse(v) ?? words[v];
}

Analysis analyze(String text, Attachment? att, String hintLang, String? contactPhone) {
  var s = ' ${norm(text)} ';
  final lang = detectLang(text) ?? hintLang;

  String? phone;
  s = s.replaceAllMapped(_phoneRe, (m) {
    phone ??= '+7 ${m[1]} ${m[2]} ${m[3]} ${m[4]}';
    return ' ';
  });

  String? hm;
  s = s.replaceAllMapped(_timeRe, (m) {
    final hh = int.parse(m[1]!);
    final mi = int.parse(m[2]!);
    if (hm == null && hh <= 23 && mi < 60) {
      hm = '${hh.toString().padLeft(2, '0')}:${m[2]}';
      return ' ';
    }
    return m[0]!;
  });
  final TimeWish? time = hm == null ? null : TimeWish(hm: hm, tomorrow: _tomorrowRe.hasMatch(s));

  Bi? address;
  var far = false;
  GeoPoint? geo;
  if (att != null && att.type == AttType.geo && att.place != null && kPlaces.containsKey(att.place)) {
    final pl = kPlaces[att.place]!;
    address = Bi('${pl.ru}, ${att.house}', '${pl.kz}, ${att.house}');
    far = pl.far;
    geo = GeoPoint(pl.lat, pl.lng);
  } else {
    Place? bestPl;
    RegExpMatch? bestM;
    for (final pl in kPlaces.values) {
      final m = pl.rx.firstMatch(s);
      if (m != null && (bestM == null || m.start < bestM.start)) {
        bestM = m;
        bestPl = pl;
      }
    }
    if (bestM != null && bestPl != null) {
      final start = bestM.start;
      var end = bestM.end;
      String? house;
      String? apt;
      var office = false;
      final hmm = _houseRe.firstMatch(s.substring(end));
      if (hmm != null) {
        house = hmm[1];
        end += hmm[0]!.length;
        final am = _aptRe.firstMatch(s.substring(end));
        if (am != null) {
          apt = am[2] ?? am[3];
          office = am[1] == 'офис';
          end += am[0]!.length;
        }
      }
      final h = house == null ? '' : ', $house';
      final aRu = apt == null ? '' : (office ? ', офис $apt' : ', кв. $apt');
      final aKz = apt == null ? '' : (office ? ', $apt-кеңсе' : ', $apt-пәтер');
      address = Bi('${bestPl.ru}$h$aRu', '${bestPl.kz}$h$aKz');
      far = bestPl.far;
      s = '${s.substring(0, start)} ${s.substring(end)}';
    }
  }

  final pickup = _pickupRe.hasMatch(s);
  final items = parseItems(s, lang);
  String? photoItem;
  if (att != null && att.type == AttType.photo && att.item != null && kP.containsKey(att.item)) {
    photoItem = att.item;
    if (!items.any((i) => i.id == att.item)) {
      items.insert(0, Item(att.item!, min(99, _unitQty(s, lang) ?? 1)));
    }
  }
  return Analysis(
    lang: lang,
    items: items,
    address: address,
    far: pickup ? false : far,
    pickup: pickup,
    phone: phone ?? contactPhone,
    time: time,
    geo: geo,
    asksHours: _hoursRe.hasMatch(s),
    wantsDessert: _dessertRe.hasMatch(s),
    photoItem: photoItem,
  );
}

/// Combines what the client said earlier with a follow-up message.
Analysis mergeAnalysis(Analysis a, Analysis b) {
  final r = a.copy();
  if (r.items.isEmpty) r.items = b.items;
  if (r.address == null) {
    r.address = b.address;
    r.far = b.far;
    r.geo = b.geo;
  }
  r.pickup = a.pickup || b.pickup;
  r.phone = a.phone ?? b.phone;
  r.time = a.time ?? b.time;
  r.asksHours = false;
  r.summary = null;
  return r;
}

Bi summarize(Analysis a) {
  if (a.items.isEmpty) {
    if (a.receipt != null) {
      return Bi('Чек об оплате на ${money(a.receipt!)}', '${money(a.receipt!)} сомасына төлем түбіртегі');
    }
    return a.asksHours
        ? const Bi('Спрашивает часы работы и что есть в меню', 'Жұмыс уақыты мен мәзірді сұрайды')
        : const Bi('Интересуется меню, заказ ещё не выбран', 'Мәзірге қызығады, тапсырыс әлі таңдалмаған');
  }
  String list(String l) => a.items.map((i) => '${i.qty} × ${nameOf(i.id, l)}').join(', ');
  return Bi(
    (a.pickup ? 'Самовывоз: ' : 'Доставка: ') + list('ru'),
    (a.pickup ? 'Өзі алып кетеді: ' : 'Жеткізу: ') + list('kz'),
  );
}

Order buildOrder(Analysis a) {
  final lines = <OrderLine>[for (final i in a.items) OrderLine(i.id, i.qty, kP[i.id]!.price)];
  final subtotal = lines.fold<int>(0, (x, l) => x + l.sum);
  final pickup = a.pickup;
  final delivery = (lines.isEmpty || pickup || subtotal >= 10000) ? 0 : (a.far ? 1200 : 800);
  return Order(
    lines: lines,
    subtotal: subtotal,
    delivery: delivery,
    total: subtotal + delivery,
    pickup: pickup,
    address: a.address,
    far: a.far,
    phone: a.phone,
    time: a.time,
    geo: a.geo,
    eta: a.far ? 50 : 35,
    summary: a.summary ?? summarize(a),
    engine: a.engine,
  );
}

St decideStatus(Order? o) {
  if (o == null || o.lines.isEmpty) return St.lead;
  return ((o.pickup || o.address != null) && o.phone != null) ? St.kaspi : St.lead;
}

String? normPhone(Object? v) {
  final d = (v ?? '').toString().replaceAll(RegExp(r'\D'), '');
  String? x;
  if (d.length == 11 && (d[0] == '7' || d[0] == '8')) {
    x = d.substring(1);
  } else if (d.length == 10 && d[0] == '7') {
    x = d;
  }
  if (x == null) return null;
  return '+7 ${x.substring(0, 3)} ${x.substring(3, 6)} ${x.substring(6, 8)} ${x.substring(8, 10)}';
}

/// "175 400" with non-breaking spaces between groups.
String fmtNum(num n) {
  final v = n.round();
  final neg = v < 0;
  final digits = v.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return '${neg ? '−' : ''}$buf';
}

String money(num n) => '${fmtNum(n)} ₸';

String dec1(num n) => ((n * 10).round() / 10).toStringAsFixed(1).replaceAll('.', ',');
