/// Data types shared by the order engine and the app state.
library;

/// Order status shown everywhere in the app.
enum St { lead, kaspi, paid, courier }

/// A pair of strings: Russian and Kazakh.
class Bi {
  const Bi(this.ru, this.kz);
  final String ru;
  final String kz;
  String of(String lang) => lang == 'kz' ? kz : ru;
}

class Item {
  const Item(this.id, this.qty);
  final String id;
  final int qty;
}

class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

class TimeWish {
  const TimeWish({this.hm, this.tomorrow = false, this.raw});
  final String? hm;
  final bool tomorrow;
  final String? raw;

  String text(String lang) {
    if (raw != null) return raw!;
    final prefix = tomorrow ? (lang == 'kz' ? 'ертең, ' : 'завтра, ') : '';
    return '$prefix${hm ?? ''}';
  }
}

enum AttType { voice, photo, geo, receipt }

/// Something a client sent besides text: voice message, photo, geolocation or a receipt.
class Attachment {
  Attachment({
    required this.type,
    this.dur,
    this.item,
    this.conf = 0.94,
    this.place,
    this.house,
    this.transcript,
    List<int>? bars,
    this.amount,
    this.desc,
  }) : bars = bars ?? const <int>[];

  final AttType type;
  final String? dur;
  final String? item;
  final double conf;
  final String? place;
  final String? house;
  String? transcript;
  List<int> bars;
  int? amount;
  String? desc;

  Attachment copy() => Attachment(
        type: type,
        dur: dur,
        item: item,
        conf: conf,
        place: place,
        house: house,
        transcript: transcript,
        bars: bars,
        amount: amount,
        desc: desc,
      );
}

/// What the AI understood from a client message.
class Analysis {
  Analysis({
    required this.lang,
    required this.items,
    this.address,
    this.far = false,
    this.pickup = false,
    this.phone,
    this.time,
    this.geo,
    this.asksHours = false,
    this.wantsDessert = false,
    this.photoItem,
    this.receipt,
    this.engine = 'local',
    this.summary,
    this.photoDesc,
  });

  String lang;
  List<Item> items;
  Bi? address;
  bool far;
  bool pickup;
  String? phone;
  TimeWish? time;
  GeoPoint? geo;
  bool asksHours;
  bool wantsDessert;
  String? photoItem;
  int? receipt;
  String engine;
  Bi? summary;
  String? photoDesc;

  Analysis copy() => Analysis(
        lang: lang,
        items: List<Item>.of(items),
        address: address,
        far: far,
        pickup: pickup,
        phone: phone,
        time: time,
        geo: geo,
        asksHours: asksHours,
        wantsDessert: wantsDessert,
        photoItem: photoItem,
        receipt: receipt,
        engine: engine,
        summary: summary,
        photoDesc: photoDesc,
      );
}

class OrderLine {
  const OrderLine(this.id, this.qty, this.price);
  final String id;
  final int qty;
  final int price;
  int get sum => qty * price;
}

class Order {
  Order({
    required this.lines,
    required this.subtotal,
    required this.delivery,
    required this.total,
    required this.pickup,
    required this.summary,
    this.address,
    this.far = false,
    this.phone,
    this.time,
    this.geo,
    this.eta = 35,
    this.engine = 'local',
    this.receiptOnly = false,
    this.no = '',
  });

  final List<OrderLine> lines;
  final int subtotal;
  final int delivery;
  final int total;
  final bool pickup;
  final Bi summary;
  final Bi? address;
  final bool far;
  final String? phone;
  final TimeWish? time;
  final GeoPoint? geo;
  final int eta;
  final String engine;
  final bool receiptOnly;
  String no;
}
