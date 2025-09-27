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
    // Handle multiple legacy key variants gracefully
    String pick(List<String> keys, {String fallback = '0'}) {
      for (final k in keys) {
        final v = json[k];
        if (v != null && v.toString().isNotEmpty) return v.toString();
      }
      return fallback;
    }

    final profit = pick([
      'profit',
      'profitAll',
      'money',
      'income',
      'sumProfit',
      'todayProfit',
    ], fallback: '0.0');
    final currency = pick([
      'currency',
      'profitUnit',
      'currencyUnit',
      'money_unit',
      'unit',
    ], fallback: '');
    final energy = pick([
      'energy',
      'generation',
      'power',
      'kwh',
    ], fallback: '0.0000');
    final co2 = pick(['co2', 'co2Reduce', 'co2_reduction'], fallback: '0.0000');
    final so2 = pick(['so2', 'so2Reduce', 'so2_reduction'], fallback: '0.0000');
    final coal = pick(['coal', 'coalSave', 'coal_saving'], fallback: '0.0000');

    return ProfitStatistic(
      co2: co2,
      so2: so2,
      coal: coal,
      profit: profit,
      energy: energy,
      currency: currency,
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
