import 'package:bizai_hub/engine/catalog.dart';
import 'package:bizai_hub/engine/parser.dart';
import 'package:bizai_hub/engine/replies.dart';
import 'package:bizai_hub/engine/types.dart';
import 'package:flutter_test/flutter_test.dart';

String items(Analysis a) => a.items.map((i) => '${i.qty}×${i.id}').join(',');

void main() {
  group('Order parser', () {
    test('Kazakh text order with address and phone', () {
      final a = analyze(kTemplates.firstWhere((t) => t.id == 'k1').text, null, 'kz', null);
      expect(a.lang, 'kz');
      expect(items(a), '2×cap,1×cro');
      expect(a.address?.ru, 'мкр. Жайлау, 14');
      expect(a.phone, '+7 702 415 33 08');
      final o = buildOrder(a);
      expect(o.total, 4500);
      expect(decideStatus(o), St.kaspi);
    });

    test('Kazakh number words and street', () {
      final a = analyze(kTemplates.firstWhere((t) => t.id == 'k2').text, null, 'kz', null);
      expect(items(a), '3×lat,2×sam');
      expect(a.address?.ru, 'ул. Абая, 120');
    });

    test('Russian order with apartment', () {
      final a = analyze('Здравствуйте! Можно 2 рафа и чизкейк? Доставка на ул. Сулейменова 5, кв 18. +7 777 512 40 91', null, 'ru', null);
      expect(items(a), '2×raf,1×chz');
      expect(a.address?.kz, 'Сүлейменов көшесі, 5, 18-пәтер');
      expect(buildOrder(a).total, 6000);
    });

    test('Pickup with packs of baursaks and beans', () {
      final a = analyze('Добрый день! Для офиса нужно 2 кг кофе в зёрнах и 20 баурсаков. Самовывоз. Тел 8 708 117 03 55', null, 'ru', null);
      expect(a.pickup, isTrue);
      expect(items(a), '2×bean,2×bau');
      final o = buildOrder(a);
      expect(o.delivery, 0);
      expect(o.total, 26000);
    });

    test('Photo item with quantity after the noun', () {
      final a = analyze('Есть такой? Возьму 3 штуки. Айтеке би 45, 8 705 222 18 70', Attachment(type: AttType.photo, item: 'chz'), 'ru', null);
      expect(items(a), '3×chz');
    });

    test('Far district costs more, free delivery from 10 000', () {
      final far = buildOrder(analyze('Мына торт бар ма? Қарасу 7 үй, +7 747 220 19 54', Attachment(type: AttType.photo, item: 'med'), 'kz', null));
      expect(far.delivery, 1200);
      expect(far.total, 11000);
      final near = buildOrder(analyze('3 латте, Абая 10, +7 701 000 00 00', null, 'ru', null));
      expect(near.delivery, 800);
    });

    test('Time and tomorrow', () {
      final a = analyze('Нужен на завтра к 12:00. Толе би 52', Attachment(type: AttType.photo, item: 'med'), 'ru', null);
      expect(a.time?.text('ru'), 'завтра, 12:00');
    });

    test('Question without order asks to clarify', () {
      final a = analyze('Добрый вечер! До скольки работаете сегодня?', null, 'ru', null);
      expect(a.items, isEmpty);
      expect(a.asksHours, isTrue);
      expect(composeReply('ru', 'Анна', null, St.lead, a), contains('с 8:00 до 23:00'));
    });

    test('Money formatting', () {
      expect(money(175400), '175 400 ₸');
      expect(normPhone('87015551234'), '+7 701 555 12 34');
    });
  });
}
