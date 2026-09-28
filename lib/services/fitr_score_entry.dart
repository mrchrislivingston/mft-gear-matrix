import 'dart:convert';

class FitrScoreSpec {
  final Map<String, dynamic> raw;
  const FitrScoreSpec(this.raw);
  String get measure => raw['measure']?.toString() ?? '';
  int get count => raw['count_sub_value'] is num ? (raw['count_sub_value'] as num).toInt() : 1;
  bool get supported => const {'weight','time','watts','distance','reps','calories','round_reps'}.contains(measure) && count > 0 && count <= 100 && const {null, 'best', 'sum_all'}.contains(raw['custom_type']);
  String get unit => switch (measure) {
    'weight' => 'lb', 'time' => 'mm:ss', 'distance' => 'm', 'round_reps' => 'rounds + reps', _ => measure,
  };
  String get aggregation => switch (raw['custom_type']) { 'best' => 'Best entry', 'sum_all' => 'Sum of entries', _ => 'Single score' };
  String get signature => jsonEncode([measure, count, raw['custom_type'], raw['direction'], raw['id']]);
  static FitrScoreSpec? fromMetadata(Map<String, dynamic> metadata) {
    final raw = metadata['score_score'];
    return raw is Map ? FitrScoreSpec(Map<String, dynamic>.from(raw)) : null;
  }
  String? validate(String value) {
    if (value.trim().isEmpty) return null; // Incomplete sessions can be saved.
    if (measure == 'time') return RegExp(r'^\d+:[0-5]\d(?:\.\d+)?$').hasMatch(value.trim()) ? null : 'Use minutes:seconds (e.g. 1:35).';
    if (measure == 'round_reps') return RegExp(r'^\d+\s*\+\s*\d+$').hasMatch(value.trim()) ? null : 'Use rounds + reps (e.g. 5 + 12).';
    final number = double.tryParse(value.trim());
    if (number == null || !number.isFinite || number < 0) return 'Enter a nonnegative number.';
    if (measure == 'reps' && number != number.roundToDouble()) return 'Enter whole reps.';
    return null;
  }
  String summarize(List<String> values) {
    final entered = values.where((v) => v.trim().isNotEmpty).length;
    final detail = [for (var i=0;i<values.length;i++) if(values[i].trim().isNotEmpty) '${i+1}: ${values[i]} $unit'].join(' • ');
    if (entered != count || measure == 'round_reps') return '$entered/$count entries • $detail';
    final nums = values.map((v) {
      if (measure == 'time') { final p=v.split(':'); return double.parse(p[0])*60+double.parse(p[1]); }
      return double.parse(v);
    }).toList();
    final type = raw['custom_type'];
    double? total;
    if (type == 'sum_all') total = nums.reduce((a,b)=>a+b);
    if (type == 'best') total = nums.reduce((a,b)=>raw['direction']=='descending' ? (a<b?a:b) : (a>b?a:b));
    if (total == null) return detail;
    final display = measure == 'time'
      ? '${total~/60}:${(total%60).toStringAsFixed(2).padLeft(5,'0')}'
      : total.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'),'');
    return '$aggregation: $display $unit\n$detail';
  }
}
