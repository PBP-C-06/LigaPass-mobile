// To parse this JSON data, do
//
//     final bookingItem = bookingItemFromJson(jsonString);

import 'dart:convert';

List<BookingItem> bookingItemFromJson(String str) => List<BookingItem>.from(json.decode(str).map((x) => BookingItem.fromJson(x)));

String bookingItemToJson(List<BookingItem> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class BookingItem {
    String model;
    int pk;
    Fields fields;

    BookingItem({
        required this.model,
        required this.pk,
        required this.fields,
    });

    factory BookingItem.fromJson(Map<String, dynamic> json) => BookingItem(
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
    int quantity;

    Fields({
        required this.booking,
        required this.ticketType,
        required this.quantity,
    });

    factory Fields.fromJson(Map<String, dynamic> json) => Fields(
        booking: json["booking"],
        ticketType: json["ticket_type"],
        quantity: json["quantity"],
    );

    Map<String, dynamic> toJson() => {
        "booking": booking,
        "ticket_type": ticketType,
        "quantity": quantity,
    };
}
