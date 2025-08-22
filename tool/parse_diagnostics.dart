// Parse DIAG lines from api_diagnostics.dart output and build a summary mapping.
// Run: flutter pub run tool/parse_diagnostics.dart < diag.log
import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final lines = await stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .toList();
  final entries = <Map<String, dynamic>>[];
  for (final line in lines) {
    final idx = line.indexOf('DIAG:');
    if (idx == -1) continue;
    final jsonPart = line.substring(idx + 5).trim();
    try {
      final map = json.decode(jsonPart) as Map<String, dynamic>;
      entries.add(map);
    } catch (_) {}
  }
  // Group by phase
  final byPhase = <String, List<Map<String, dynamic>>>{};
  for (final e in entries) {
    final phase = e['phase']?.toString() ?? 'unknown';
    byPhase.putIfAbsent(phase, () => []).add(e);
  }
  // Build logical metric mapping from keyParamOneDay + pagingOneDayValue
  final logicalMap = <String, dynamic>{};
  for (final e in byPhase['keyParamOneDay'] ?? []) {
    final logical = e['logical'];
    if (logical == null) continue;
    logicalMap[logical] = {
      'oneDayLatest': e['latest'],
      'apiParam': e['apiParam'],
      'count': e['count'],
      'ts': e['ts'],
      'err': e['err'],
      'desc': e['desc']
    };
  }
  // Attach paging fallbacks if present
  for (final e in byPhase['pagingOneDayValue'] ?? []) {
    final title = e['title'];
    if (title == null) continue;
    // Attempt naive title -> logical mapping heuristics
    String logical;
    final t = title.toString().toLowerCase();
    if (t.contains('pv')) {
      logical = 'PV_OUTPUT_POWER';
    } else if (t.contains('load')) {
      logical = 'LOAD_POWER';
    } else if (t.contains('grid')) {
      logical = 'GRID_POWER';
    } else if (t.contains('soc') || t.contains('battery')) {
      logical = 'BATTERY_SOC';
    } else {
      continue; // skip unrecognized
    }
    final existing = logicalMap[logical] as Map<String, dynamic>?;
    if (existing == null || (existing['oneDayLatest'] == null)) {
      logicalMap[logical] = {
        'oneDayLatest': e['latest'],
        'apiParam': 'paging:$title',
        'count': 1,
        'ts': null,
        'err': 0,
        'desc': 'PAGING_ONLY'
      };
    } else {
      existing['pagingLatest'] = e['latest'];
      existing['pagingTitle'] = title;
    }
  }

  final summary = {
    'phases': byPhase.map((k, v) => MapEntry(k, v.length)),
    'logicalMetrics': logicalMap,
  };
  stdout.writeln(jsonEncode(summary));
}
