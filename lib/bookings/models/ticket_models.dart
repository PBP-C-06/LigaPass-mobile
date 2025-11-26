// To parse this JSON data, do
//
//     final ticket = ticketFromJson(jsonString);

import 'dart:convert';

List<Ticket> ticketFromJson(String str) =>
    List<Ticket>.from(json.decode(str).map((x) => Ticket.fromJson(x)));

String ticketToJson(List<Ticket> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Ticket {
  String model;
  String pk;
  Fields fields;

  Ticket({
    required this.model,
    required this.pk,
    required this.fields,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        model: json["model"],
        pk: json["pk"],
        fields: Fields.fromJson(json["fields"]),
      );

  Map<String, dynamic> toJson() => {
        "model": model,
        "pk": pk,
        "fields": fields.toJson(),
      };
}

class Fields {
  String booking;
  int ticketType;
  bool isUsed;
  DateTime generatedAt;

  Fields({
    required this.booking,
    required this.ticketType,
    required this.isUsed,
    required this.generatedAt,
  });

  factory Fields.fromJson(Map<String, dynamic> json) => Fields(
        booking: json["booking"],
        ticketType: json["ticket_type"],
        isUsed: json["is_used"],
        generatedAt: DateTime.parse(json["generated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "booking": booking,
        "ticket_type": ticketType,
        "is_used": isUsed,
        "generated_at": generatedAt.toIso8601String(),
      };
}
