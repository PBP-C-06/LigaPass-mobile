// To parse this JSON data, do
//
//     final adminJournalistProfile = adminJournalistProfileFromJson(jsonString);

import 'dart:convert';

AdminJournalistProfile adminJournalistProfileFromJson(String str) => AdminJournalistProfile.fromJson(json.decode(str));

String adminJournalistProfileToJson(AdminJournalistProfile data) => json.encode(data.toJson());

class AdminJournalistProfile {
    String username;
    String profilePicture;
    int totalNews;
    int totalViews;

    AdminJournalistProfile({
        required this.username,
        required this.profilePicture,
        required this.totalNews,
        required this.totalViews,
    });

    factory AdminJournalistProfile.fromJson(Map<String, dynamic> json) => AdminJournalistProfile(
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