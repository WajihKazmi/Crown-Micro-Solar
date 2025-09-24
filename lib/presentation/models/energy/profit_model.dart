class ProfitStatistic {
  final String co2;
  final String so2;
  final String coal;
  final String profit;
  final String energy;
  final String currency;

  ProfitStatistic({
    required this.co2,
    required this.so2,
    required this.coal,
    required this.profit,
    required this.energy,
    required this.currency,
  });

  factory ProfitStatistic.fromJson(Map<String, dynamic> json) {
    return ProfitStatistic(
      co2: json['co2']?.toString() ?? '0.0000',
      so2: json['so2']?.toString() ?? '0.0000',
      coal: json['coal']?.toString() ?? '0.0000',
      profit: json['profit']?.toString() ?? '0.0',
      energy: json['energy']?.toString() ?? '0.0000',
      currency: json['currency']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'co2': co2,
      'so2': so2,
      'coal': coal,
      'profit': profit,
      'energy': energy,
      'currency': currency,
    };
  }
}
