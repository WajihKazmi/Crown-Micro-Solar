import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';

/// ViewModel that resolves a set of logical metrics for a single device once (on demand)
/// and exposes results for summary cards / graphs.
class MetricAggregatorViewModel extends ChangeNotifier {
  final DeviceRepository _deviceRepository;
  final String sn;
  final String pn;
  final int devcode;
  final int devaddr;

  MetricAggregatorViewModel({
    required DeviceRepository deviceRepository,
    required this.sn,
    required this.pn,
    required this.devcode,
    required this.devaddr,
  }) : _deviceRepository = deviceRepository;

  final Map<String, MetricResolutionResult> _results = {};
  bool _loading = false;
  String? _error;
  DateTime? _lastUpdated;

  bool get isLoading => _loading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  Map<String, MetricResolutionResult> get results => Map.unmodifiable(_results);

  /// Resolve a set of logical metrics (e.g. for summary cards)
  Future<void> resolveMetrics(List<String> logicalMetrics,
      {String? date}) async {
    if (_loading) return; // simple re-entrancy guard
    _loading = true;
    _error = null;
    notifyListeners();
    final targetDate =
        date ?? DateTime.now().toIso8601String().substring(0, 10);
    try {
      final futures = <Future<MetricResolutionResult>>[];
      for (final m in logicalMetrics) {
        futures.add(_deviceRepository.resolveMetricOneDay(
          logicalMetric: m,
          sn: sn,
          pn: pn,
          devcode: devcode,
          devaddr: devaddr,
          date: targetDate,
        ));
      }
      final resolved = await Future.wait(futures);
      for (final r in resolved) {
        _results[r.logicalMetric] = r;
      }
      _lastUpdated = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  MetricResolutionResult? metric(String logical) => _results[logical];
}
