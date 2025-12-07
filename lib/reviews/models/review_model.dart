import 'dart:convert';

ReviewEntry reviewEntryFromJson(String str) => ReviewEntry.fromJson(json.decode(str));

String reviewEntryToJson(ReviewEntry data) => json.encode(data.toJson());

class ReviewEntry {
    bool ok;
    MyReview myReview;
    List<dynamic> reviews;
    int averageRating;
    bool hasTicket;
    bool canReview;

    ReviewEntry({
        required this.ok,
        required this.myReview,
        required this.reviews,
        required this.averageRating,
        required this.hasTicket,
        required this.canReview,
    });

    factory ReviewEntry.fromJson(Map<String, dynamic> json) => ReviewEntry(
        ok: json["ok"],
        myReview: MyReview.fromJson(json["my_review"]),
        reviews: List<dynamic>.from(json["reviews"].map((x) => x)),
        averageRating: json["average_rating"],
        hasTicket: json["has_ticket"],
        canReview: json["can_review"],
    );

    Map<String, dynamic> toJson() => {
        "ok": ok,
        "my_review": myReview.toJson(),
        "reviews": List<dynamic>.from(reviews.map((x) => x)),
        "average_rating": averageRating,
        "has_ticket": hasTicket,
        "can_review": canReview,
    };
}

class MyReview {
    int id;
    int rating;
    String comment;
    dynamic sentiment;
    DateTime createdAt;
    DateTime updatedAt;
    Reply reply;

    MyReview({
        required this.id,
        required this.rating,
        required this.comment,
        this.sentiment,
        required this.createdAt,
        required this.updatedAt,
        required this.reply,
    });

    factory MyReview.fromJson(Map<String, dynamic> json) => MyReview(
        id: json["id"],
        rating: json["rating"],
        comment: json["comment"],
        sentiment: json["sentiment"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        reply: Reply.fromJson(json["reply"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "rating": rating,
        "comment": comment,
        "sentiment": sentiment,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "reply": reply.toJson(),
    };
}

class Reply {
    String admin;
    String replyText;
    DateTime createdAt;

    Reply({
        required this.admin,
        required this.replyText,
        required this.createdAt,
    });

    factory Reply.fromJson(Map<String, dynamic> json) => Reply(
        admin: json["admin"],
        replyText: json["reply_text"],
        createdAt: DateTime.parse(json["created_at"]),
    );

    Map<String, dynamic> toJson() => {
        "admin": admin,
        "reply_text": replyText,
        "created_at": createdAt.toIso8601String(),
    };
}
