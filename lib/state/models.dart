import 'dart:async';

import '../engine/types.dart';

enum Ch { ig, tg, wa }

extension ChX on Ch {
  String get label => switch (this) { Ch.ig => 'Instagram', Ch.tg => 'Telegram', Ch.wa => 'WhatsApp' };
  String get short => switch (this) { Ch.ig => 'IG', Ch.tg => 'TG', Ch.wa => 'WA' };
}

enum From { client, ai, op, sys, proc }

/// One step of the AI processing card in a chat.
class ProcStep {
  ProcStep(this.k, this.a, this.state);
  String k;
  final List<Object> a;
  String state; // run | ok | warn
}

class Msg {
  Msg({
    required this.from,
    required this.at,
    this.text = '',
    this.att,
    this.kind,
    this.amount,
    this.no,
    this.courier,
    this.eta,
    List<ProcStep>? steps,
    this.done = false,
    this.secs = 0,
  })  : steps = steps ?? <ProcStep>[],
        born = DateTime.now();

  final From from;
  DateTime at;
  String text;
  Attachment? att;
  final String? kind; // sys: invoice | paid | paid_manual | courier | handed
  final int? amount;
  final String? no;
  final String? courier;
  final int? eta;
  final List<ProcStep> steps;
  bool done;
  double secs;

  /// Real creation time, used to fade in only new messages.
  final DateTime born;
}

class Conv {
  Conv({
    required this.id,
    required this.ch,
    required this.lang,
    required this.name,
    this.handle,
    this.contact,
    required this.createdAt,
  }) : updatedAt = createdAt;

  final String id;
  final Ch ch;
  String lang;
  final String name;
  final String? handle;
  final String? contact;
  final DateTime createdAt;
  DateTime updatedAt;
  St status = St.lead;
  final List<Msg> msgs = <Msg>[];
  Order? order;
  Analysis? analysis;
  bool unread = false;
  bool typing = false;
  bool counted = false;
  bool opTouched = false;
  bool handed = false;
  bool busy = false;
  String? courier;
}

class FeedEvent {
  FeedEvent(this.type, this.p, this.at, this.convId);
  final String type; // new | invoice | paid | courier | clarify | rec | handed
  final Map<String, Object> p;
  final DateTime at;
  final String? convId;
}

class StockItem {
  StockItem(this.id, this.ru, this.kz, this.uRu, this.uKz, this.qty, this.daily, this.dec);
  final String id;
  final String ru;
  final String kz;
  final String uRu;
  final String uKz;
  double qty;
  final double daily;
  final bool dec;
}

class Metrics {
  int rev = 142300;
  int dialogs = 50;
  int paid = 30;
  int ai = 39;
  int noOp = 31;
}

class ChStat {
  ChStat(this.d, this.r);
  int d;
  int r;
}

class ToastData {
  ToastData({required this.id, this.convId, required this.stage, this.text, this.err = false, this.msg});
  final int id;
  final String? convId;
  String stage; // new | parsing | invoiced | paid | clarify | plain
  final String? text;
  final bool err;
  final Msg? msg;
  Timer? timer;
}
