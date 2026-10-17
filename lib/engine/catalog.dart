import 'types.dart';

/// Menu of the demo business «Дәмді Кофе» (coffee shop & bakery in Taraz).
class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.ru,
    required this.kz,
    required this.price,
    required this.cat,
    required this.keys,
    this.ex = const <String>[],
    this.pack = 0,
  });

  final String id;
  final String ru;
  final String kz;
  final int price;
  final String cat;
  final List<String> keys;
  final List<String> ex;
  final int pack;

  String name(String lang) => lang == 'kz' ? kz : ru;
}

const List<CatalogItem> kCatalog = <CatalogItem>[
  CatalogItem(id: 'cap', ru: 'Капучино 0,3 л', kz: 'Капучино 0,3 л', price: 1300, cat: 'coffee', keys: ['капучино', 'капуч', 'cappuccino']),
  CatalogItem(id: 'lat', ru: 'Латте 0,4 л', kz: 'Латте 0,4 л', price: 1500, cat: 'coffee', keys: ['латте', 'латтэ', 'latte']),
  CatalogItem(id: 'raf', ru: 'Раф ванильный', kz: 'Ванильді раф', price: 1700, cat: 'coffee', keys: ['раф'], ex: ['рафинад']),
  CatalogItem(id: 'ame', ru: 'Американо', kz: 'Американо', price: 1000, cat: 'coffee', keys: ['американо', 'americano']),
  CatalogItem(id: 'cro', ru: 'Круассан с миндалём', kz: 'Бадамды круассан', price: 1100, cat: 'bakery', keys: ['круассан']),
  CatalogItem(id: 'sam', ru: 'Самса с говядиной', kz: 'Сиыр етінен самса', price: 700, cat: 'bakery', keys: ['самс'], ex: ['самсунг']),
  CatalogItem(id: 'bau', ru: 'Баурсаки, 10 шт', kz: 'Бауырсақ, 10 дана', price: 1500, cat: 'bakery', keys: ['баурсак', 'бауырсак', 'бауырсақ'], pack: 10),
  CatalogItem(id: 'chz', ru: 'Чизкейк Нью-Йорк', kz: 'Нью-Йорк чизкейкі', price: 1800, cat: 'dessert', keys: ['чизкейк', 'cheesecake']),
  CatalogItem(id: 'med', ru: 'Торт «Медовик», 1,2 кг', kz: '«Медовик» торты, 1,2 кг', price: 9800, cat: 'dessert', keys: ['медовик']),
  CatalogItem(id: 'bean', ru: 'Кофе в зёрнах, 1 кг', kz: 'Кофе дәні, 1 кг', price: 11500, cat: 'beans', keys: ['зерн', 'дән']),
];

final Map<String, CatalogItem> kP = <String, CatalogItem>{for (final c in kCatalog) c.id: c};

String nameOf(String id, String lang) => kP[id]?.name(lang) ?? id;

/// Streets and districts of Taraz the parser recognises (Russian and Kazakh spellings).
class Place {
  Place(this.re, this.ru, this.kz, this.lat, this.lng, {this.far = false})
      : rx = RegExp('(?<![\\p{L}])(?:$re)', unicode: true);

  final String re;
  final String ru;
  final String kz;
  final double lat;
  final double lng;
  final bool far;
  final RegExp rx;
}

final Map<String, Place> kPlaces = <String, Place>{
  'tole': Place(r'т[өо]ле\s*би', 'пр. Толе би', 'Төле би даңғылы', 42.8996, 71.3712),
  'abay': Place(r'аба[йя](?![\p{L}])', 'ул. Абая', 'Абай көшесі', 42.9041, 71.3807),
  'zhambyl': Place(r'жамбыла?', 'пр. Жамбыла', 'Жамбыл даңғылы', 42.8933, 71.3893),
  'kazybek': Place(r'[кқ]азыбек\s*би', 'ул. Казыбек би', 'Қазыбек би көшесі', 42.9012, 71.3601),
  'aiteke': Place(r'[аә]йтеке\s*би', 'ул. Айтеке би', 'Әйтеке би көшесі', 42.8968, 71.3655),
  'suleimen': Place(r'с[уү]лейменов', 'ул. Сулейменова', 'Сүлейменов көшесі', 42.8879, 71.3768),
  'zheltoksan': Place(r'желто[кқ]сан', 'ул. Желтоксан', 'Желтоқсан көшесі', 42.8951, 71.3934),
  'zhailau': Place(r'жайлау', 'мкр. Жайлау', 'Жайлау шағын ауданы', 42.8762, 71.4021),
  'karasu': Place(r'[кқ]арасу', 'мкр. Карасу', 'Қарасу шағын ауданы', 42.8574, 71.4290, far: true),
  'mynbulak': Place(r'мы[нң]б[уұ]ла[кқ]', 'мкр. Мынбулак', 'Мыңбұлақ шағын ауданы', 42.9135, 71.3488),
  'talas': Place(r'талас', 'мкр. Талас', 'Талас шағын ауданы', 42.9290, 71.4105, far: true),
};

const Map<String, int> kNumRu = <String, int>{
  'один': 1, 'одну': 1, 'одна': 1, 'одно': 1, 'два': 2, 'две': 2, 'пару': 2, 'пара': 2, 'три': 3, 'четыре': 4,
  'пять': 5, 'шесть': 6, 'семь': 7, 'восемь': 8, 'девять': 9, 'десять': 10, 'двенадцать': 12, 'пятнадцать': 15, 'двадцать': 20,
};
const Map<String, int> kNumKz = <String, int>{
  'бір': 1, 'екі': 2, 'үш': 3, 'төрт': 4, 'бес': 5, 'алты': 6, 'жеті': 7, 'сегіз': 8, 'тоғыз': 9, 'он': 10, 'жиырма': 20,
};
const Map<String, int> kKzUnits = <String, int>{
  'бір': 1, 'екі': 2, 'үш': 3, 'төрт': 4, 'бес': 5, 'алты': 6, 'жеті': 7, 'сегіз': 8, 'тоғыз': 9,
};

/// A message the simulator can "send" as a client.
class Tpl {
  Tpl(this.id, this.lang, this.text, {this.att, this.faq = false});
  final String id;
  final String lang;
  final String text;
  final Attachment? att;
  final bool faq;
}

final List<Tpl> kTemplates = <Tpl>[
  Tpl('k1', 'kz', 'Сәлеметсіз бе! 2 капучино және 1 круассан алғым келеді. Жайлау шағын ауданы, 14 үй. Тел: +7 702 415 33 08'),
  Tpl('k2', 'kz', 'Сәлеметсіз бе, үш латте мен екі самса керек еді. Абай көшесі 120, кеңсеге жеткізіңізші. Нөмірім 8 705 331 72 40',
      att: Attachment(type: AttType.voice, dur: '0:09')),
  Tpl('k3', 'kz', 'Мына торт бар ма? Біреуін алайын. Қарасу 7 үй, +7 747 220 19 54',
      att: Attachment(type: AttType.photo, item: 'med', conf: 0.94)),
  Tpl('k4', 'kz', 'Екі раф пен бір чизкейк, мына жерге жеткізіп беріңізші. 8 701 284 90 36',
      att: Attachment(type: AttType.geo, place: 'mynbulak', house: '23')),
  Tpl('k5', 'kz', 'Қайырлы күн! Кеңсеге 12 американо және 12 круассан керек, сағат 15:00-ге. Қазыбек би көшесі 30. +7 701 908 66 12'),
  Tpl('k6', 'kz', 'Сәлем! 20 бауырсақ пен 1 кг кофе дәнін өзім келіп алып кетемін. 8 778 650 21 17'),
  Tpl('k8', 'kz', 'Салем, 3 раф және 1 медовик керек, Жамбыл даңғылы 101, 34-пәтер. 8 776 410 52 33'),
  Tpl('k7', 'kz', 'Сәлеметсіз бе, бүгін қашанға дейін жұмыс істейсіздер? Бір десерт алғым келеді', faq: true),
  Tpl('r1', 'ru', 'Здравствуйте! Можно 2 рафа и чизкейк? Доставка на ул. Сулейменова 5, кв 18. +7 777 512 40 91'),
  Tpl('r2', 'ru', 'Добрый вечер, хочу заказать три капучино и пять самсы, микрорайон Мынбулак, дом 9. Мой номер 8 701 345 88 22',
      att: Attachment(type: AttType.voice, dur: '0:11')),
  Tpl('r3', 'ru', 'Вот этот торт есть? Нужен на завтра к 12:00. Толе би 52, +7 707 118 40 06',
      att: Attachment(type: AttType.photo, item: 'med', conf: 0.96)),
  Tpl('r4', 'ru', 'Хочу 2 латте и круассан, вот геолокация. 8 702 774 15 30',
      att: Attachment(type: AttType.geo, place: 'zhailau', house: '31')),
  Tpl('r5', 'ru', 'Добрый день! Для офиса нужно 2 кг кофе в зёрнах и 20 баурсаков. Самовывоз. Тел 8 708 117 03 55'),
  Tpl('r7', 'ru', 'Есть такой? Возьму 3 штуки. Айтеке би 45, 8 705 222 18 70',
      att: Attachment(type: AttType.photo, item: 'chz', conf: 0.91)),
  Tpl('r8', 'ru', 'Добрый день! 4 капучино и 4 самсы в сервисный центр на Казыбек би 155. 8 705 640 18 70'),
  Tpl('r6', 'ru', 'Добрый вечер! До скольки работаете сегодня? Хочется чего-нибудь к чаю', faq: true),
];

/// Conversations that already happened today when the app opens.
class Seed {
  Seed({
    required this.ago,
    required this.ch,
    required this.lang,
    required this.name,
    required this.status,
    required this.text,
    this.handle,
    this.contact,
    this.att,
    this.unread = false,
  });

  final int ago;
  final String ch;
  final String lang;
  final String name;
  final String? handle;
  final String? contact;
  final String status;
  final String text;
  final Attachment? att;
  final bool unread;
}

final List<Seed> kSeeds = <Seed>[
  Seed(ago: 72, ch: 'tg', lang: 'kz', name: 'Мадина Әлібекова', handle: '@madina_alibek', status: 'courier',
      text: 'Сәлеметсіз бе, 5 капучино және 5 круассан керек. Сүлейменов көшесі 12, 8 705 600 41 29'),
  Seed(ago: 58, ch: 'ig', lang: 'ru', name: 'Алина Фёдорова', handle: '@alina.fx', status: 'paid',
      text: 'Привет! Чизкейк и раф на Жамбыла 140, кв 52. 8 777 093 11 47'),
  Seed(ago: 48, ch: 'wa', lang: 'ru', name: 'Тимур Ким', contact: '+7 701 220 54 18', status: 'courier',
      text: 'Добрый день! 2 американо и 2 круассана на Айтеке би 17, офис 3.'),
  Seed(ago: 35, ch: 'wa', lang: 'ru', name: 'Руслан Ахметов', contact: '+7 707 340 18 92', status: 'paid',
      att: Attachment(type: AttType.geo, place: 'karasu', house: '5'), text: '3 латте и 3 самсы, вот точка'),
  Seed(ago: 22, ch: 'ig', lang: 'kz', name: 'Гүлнұр Сапарова', handle: '@gulnur.design', status: 'paid',
      att: Attachment(type: AttType.photo, item: 'chz', conf: 0.93),
      text: 'Осы чизкейктен 2 дана бар ма? Желтоқсан көшесі 44. 8 747 301 66 90'),
  Seed(ago: 15, ch: 'wa', lang: 'kz', name: 'Дана Жұмабекова', contact: '+7 701 552 47 03', status: 'kaspi',
      text: 'Сәлеметсіз бе, 2 кг кофе дәні керек, өзім алып кетемін'),
  Seed(ago: 9, ch: 'tg', lang: 'kz', name: 'Арман Тілеуов', handle: '@arman_t', status: 'kaspi', unread: true,
      att: Attachment(type: AttType.voice, dur: '0:07'),
      text: 'Сәлем, бір медовик торты мен екі раф керек, Төле би даңғылы 88. Нөмірім 8 700 455 12 63'),
  Seed(ago: 4, ch: 'ig', lang: 'ru', name: 'Ольга Петренко', handle: '@olga.petrenko', status: 'new', unread: true,
      text: 'Здравствуйте, а медовик сегодня есть? Сколько стоит?'),
];

const Map<String, List<List<String>>> kNames = <String, List<List<String>>>{
  'kz': [
    ['Айгерім Сейтқали', '@aigerim.st'], ['Нұрлан Әбдіров', '@nurlan_ab'], ['Әсем Тұрсынова', '@asem.tursyn'],
    ['Ерасыл Бекұлы', '@erasyl.b'], ['Жанар Омарова', '@zhanar_om'], ['Бекзат Нұрғали', '@bekzat.ng'],
    ['Аружан Қалиева', '@aruzhan.k'], ['Дәурен Сәрсенов', '@dauren_s'],
  ],
  'ru': [
    ['Анна Ли', '@anna.lee.tz'], ['Денис Ковалёв', '@den_koval'], ['Ксения Пак', '@ksu.pak'],
    ['Артём Сидоров', '@artem_sid'], ['Виктория Ким', '@vika.kim'], ['Игорь Мельник', '@igor_melnik'],
    ['Елена Шмидт', '@lena.schmidt'], ['Максим Цой', '@max.tsoi'],
  ],
};
