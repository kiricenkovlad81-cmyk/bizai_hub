import 'catalog.dart';
import 'parser.dart';
import 'types.dart';

/// Texts the AI assistant sends to clients, in the client's language.

String _firstName(String n) {
  final parts = n.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? n : parts.first.replaceFirst('@', '');
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String composeReply(String lang, String name, Order? o, St status, Analysis? a) {
  final kz = lang == 'kz';
  final nm = _firstName(name);
  final hi = kz ? 'Сәлеметсіз бе, $nm!' : 'Здравствуйте, $nm!';
  if (o == null || o.lines.isEmpty) {
    final sb = StringBuffer(hi);
    if (a != null && a.asksHours) {
      sb.write(kz ? ' Біз күн сайын 8:00-ден 23:00-ге дейін жұмыс істейміз.' : ' Работаем ежедневно с 8:00 до 23:00.');
    }
    final sug = (a != null && a.wantsDessert) ? const ['med', 'chz', 'bau'] : const ['raf', 'chz', 'bau'];
    final lst = sug.map((id) => '${nameOf(id, lang)} — ${money(kP[id]!.price)}').join('; ');
    sb.write(kz ? '\nБүгін жиі алатындары: $lst. Не дайындайық?' : '\nСегодня чаще всего берут: $lst. Что приготовить?');
    sb.write(kz ? '\nТараз бойынша жеткізу — 800 ₸, 10 000 ₸-ден бастап тегін.' : '\nДоставка по Таразу — 800 ₸, от 10 000 ₸ бесплатно.');
    return sb.toString();
  }
  final list = o.lines.map((l) => '• ${l.qty} × ${nameOf(l.id, lang)} — ${money(l.sum)}').join('\n');
  final sb = StringBuffer();
  if (status == St.kaspi) {
    sb.write(kz ? '$hi Тапсырысыңыз қабылданды:' : '$hi Заказ принят:');
  } else {
    sb.write(kz ? '$hi Алдын ала есеп:' : '$hi Предварительный расчёт:');
  }
  sb.write('\n$list');
  if (!o.pickup) {
    final d = o.delivery > 0 ? money(o.delivery) : (kz ? 'тегін' : 'бесплатно');
    sb.write(kz ? '\nЖеткізу: $d' : '\nДоставка: $d');
  }
  sb.write(kz ? '\nЖиыны: ${money(o.total)}' : '\nИтого: ${money(o.total)}');
  if (status == St.kaspi) {
    if (o.pickup) {
      sb.write(kz
          ? '\nKaspi шоты ${o.phone} нөміріне жіберілді. Төлемнен кейін 15 минутта дайын болады — Төле би даңғылы, 61.'
          : '\nСчёт Kaspi отправлен на ${o.phone}. Заказ будет готов через 15 минут после оплаты — пр. Толе би, 61.');
    } else {
      final addr = o.address?.of(lang) ?? '';
      sb.write(kz
          ? '\nKaspi шоты ${o.phone} нөміріне жіберілді. Төлемнен кейін курьер шамамен ${o.eta} минутта $addr мекенжайына жеткізеді.'
          : '\nСчёт Kaspi отправлен на ${o.phone}. После оплаты курьер привезёт заказ на $addr примерно за ${o.eta} минут.');
    }
    if (o.time != null) {
      sb.write(kz
          ? '\nУақыт бойынша тілегіңіз ескерілді: ${o.time!.text('kz')}.'
          : '\nПожелание по времени учтено: ${o.time!.text('ru')}.');
    }
  } else {
    final needAddr = !o.pickup && o.address == null;
    final needPhone = o.phone == null;
    final p = <String>[];
    if (kz) {
      if (needAddr) p.add('жеткізу мекенжайын жазыңыз немесе геолокация жіберіңіз');
      if (needPhone) p.add('Kaspi-ге тіркелген нөміріңізді көрсетіңіз');
      sb.write('\n${_cap(p.join(', '))} — шотты бірден жіберемін.');
    } else {
      if (needAddr) p.add('напишите адрес доставки или отправьте геолокацию');
      if (needPhone) p.add('укажите номер, привязанный к Kaspi');
      sb.write('\n${_cap(p.join(' и '))} — сразу пришлю счёт.');
    }
  }
  return sb.toString();
}

String paidReply(String lang, Order o) {
  final kz = lang == 'kz';
  if (o.receiptOnly) {
    return kz
        ? 'Рақмет! ${money(o.total)} төлем қабылданды. Нені төлегеніңізді жазыңызшы — тексеріп, тапсырысты жұмысқа беремін.'
        : 'Спасибо! Оплата ${money(o.total)} получена. Напишите, пожалуйста, что именно оплачено — сверю и передам заказ в работу.';
  }
  if (o.pickup) {
    return kz
        ? '${money(o.total)} төлем қабылданды, рақмет! ${o.no} тапсырысы 15 минутта дайын болады, Төле би даңғылы, 61 мекенжайында күтеміз.'
        : 'Оплата ${money(o.total)} получена, спасибо! Заказ ${o.no} будет готов через 15 минут, ждём вас на пр. Толе би, 61.';
  }
  return kz
      ? '${money(o.total)} төлем қабылданды, рақмет! ${o.no} тапсырысын дайындап жатырмыз.'
      : 'Оплата ${money(o.total)} получена, спасибо! Уже готовим заказ ${o.no}.';
}

String courierReply(String lang, String courier, int eta) => lang == 'kz'
    ? 'Курьер $courier жолға шықты, шамамен $eta минутта жетеді.'
    : 'Курьер $courier уже выехал, будет у вас примерно через $eta минут.';

String invoiceReply(String lang, Order o) => lang == 'kz'
    ? '${money(o.total)} сомасына Kaspi шоты ${o.phone} нөміріне жіберілді.'
    : 'Счёт Kaspi на ${money(o.total)} отправлен на номер ${o.phone}.';

String receiptCaption(String lang) => lang == 'kz' ? 'Төледім, міне түбіртек' : 'Оплачено, вот чек';

/// What a client answers when the AI asks for missing details (used by the simulator).
String followUpText(String lang, String need, String phone) {
  final kz = lang == 'kz';
  switch (need) {
    case 'items':
      return kz
          ? 'Онда 1 медовик пен 2 раф алайын. Жайлау шағын ауданы, 8 үй. $phone'
          : 'Тогда медовик и 2 рафа. Абая 45, кв 12. $phone';
    case 'both':
      return kz ? 'Абай көшесі 45, 12-пәтер. Нөмірім $phone' : 'Абая 45, кв 12. Номер $phone';
    case 'phone':
      return kz ? 'Нөмірім $phone' : 'Номер для Kaspi: $phone';
    default:
      return kz ? 'Абай көшесі 45, 12-пәтер' : 'Абая 45, кв 12';
  }
}
