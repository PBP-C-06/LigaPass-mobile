// To parse this JSON data, do
//
//     final profile = profileFromJson(jsonString);

import 'dart:convert';

Profile profileFromJson(String str) => Profile.fromJson(json.decode(str));

String profileToJson(Profile data) => json.encode(data.toJson());

class Profile {
    String username;
    String profilePicture;
    int totalNews;
    int totalViews;

    Profile({
        required this.username,
        required this.profilePicture,
        required this.totalNews,
        required this.totalViews,
    });

    factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        username: json["username"],
        profilePicture: json["profile_picture"],
        totalNews: json["total_news"],
        totalViews: json["total_views"],
    );

    Map<String, dynamic> toJson() => {
        "username": username,
        "profile_picture": profilePicture,
        "total_news": totalNews,
        "total_views": totalViews,
    };
}
