// To parse this JSON data, do
//
//     final booking = bookingFromJson(jsonString);

import 'dart:convert';

List<Booking> bookingFromJson(String str) => List<Booking>.from(json.decode(str).map((x) => Booking.fromJson(x)));

String bookingToJson(List<Booking> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Booking {
    String model;
    String pk;
    Fields fields;

    Booking({
        required this.model,
        required this.pk,
        required this.fields,
    });

    factory Booking.fromJson(Map<String, dynamic> json) => Booking(
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
    String midtransOrderId;
    dynamic midtransActions;
    String user;
    String status;
    String totalPrice;
    DateTime createdAt;
    DateTime updatedAt;

    Fields({
        required this.midtransOrderId,
        required this.midtransActions,
        required this.user,
        required this.status,
        required this.totalPrice,
        required this.createdAt,
        required this.updatedAt,
    });

    factory Fields.fromJson(Map<String, dynamic> json) => Fields(
        midtransOrderId: json["midtrans_order_id"],
        midtransActions: json["midtrans_actions"],
        user: json["user"],
        status: json["status"],
        totalPrice: json["total_price"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
    );

    Map<String, dynamic> toJson() => {
        "midtrans_order_id": midtransOrderId,
        "midtrans_actions": midtransActions,
        "user": user,
        "status": status,
        "total_price": totalPrice,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
    };
}
