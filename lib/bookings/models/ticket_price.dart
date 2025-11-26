/// Model untuk TicketPrice dari Django
class TicketPrice {
  final int id;
  final String matchId;
  final String seatCategory;
  final double price;
  final int quantityAvailable;

  TicketPrice({
    required this.id,
    required this.matchId,
    required this.seatCategory,
    required this.price,
    required this.quantityAvailable,
  });

  factory TicketPrice.fromJson(Map<String, dynamic> json) {
    return TicketPrice(
      id: json['id'] ?? 0,
      matchId: json['match_id']?.toString() ?? '',
      seatCategory: json['seat_category'] ?? '',
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
      quantityAvailable: json['quantity_available'] ?? 0,
    );
  }

  /// Fitur berdasarkan kategori kursi
  List<String> get features {
    switch (seatCategory.toUpperCase()) {
      case 'VVIP':
        return [
          '✨ VIP Lounge Access',
          '🍽 Premium Dining',
          '👀 Best View',
          '🤝 Meet & Greet',
        ];
      case 'VIP':
        return [
          '🥂 Complimentary Drinks',
          '🎉 Great View',
          '⚡ Fast Entry',
          '🪑 Premium Seating',
        ];
      default:
        return [
          '🪑 Standard Seating',
          '🌟 Good View',
          '🎵 Stadium Atmosphere',
          '💰 Affordable Pricing',
        ];
    }
  }
}
