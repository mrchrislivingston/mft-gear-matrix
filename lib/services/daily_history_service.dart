import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'fitr_score_entry.dart';
import 'fitr_workout_classifier.dart';

Future<void> createDailyHistoryTables(DatabaseExecutor db) async {
  await db.execute('''CREATE TABLE IF NOT EXISTS daily_history_links (
    piece_id TEXT NOT NULL, slot TEXT NOT NULL, kind TEXT NOT NULL,
    target_id INTEGER NOT NULL, PRIMARY KEY(piece_id, slot))''');
  await db.execute('''CREATE TABLE IF NOT EXISTS daily_lift_history (
    piece_id TEXT PRIMARY KEY, workout_date TEXT NOT NULL, lift TEXT NOT NULL,
    prescription TEXT NOT NULL, score_entry_json TEXT NOT NULL,
    result TEXT NOT NULL, notes TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE IF NOT EXISTS daily_history_status (
    piece_id TEXT PRIMARY KEY, message TEXT NOT NULL, title TEXT NOT NULL, description TEXT NOT NULL)''');
}

String _normal(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
String _clock(num seconds) => '${seconds.round() ~/ 60}:${(seconds.round() % 60).toString().padLeft(2, '0')}';
String _number(num n) => n.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

/// All writes use the caller's transaction. Only records owned by a piece
/// are updated or removed; manual/historical records are never adopted.
class DailyHistoryService {
  static Future<void> rebuild(DatabaseExecutor db) async {
    final rows = await db.query('fitr_pieces', columns: ['id']);
    for (final row in rows) { await sync(db, row['id'] as String); }
  }

  static Future<void> sync(DatabaseExecutor db, String id) async {
    final rows = await db.rawQuery('''SELECT p.*, d.workout_date FROM fitr_pieces p
      JOIN fitr_days d ON d.id=p.day_id WHERE p.id=?''', [id]);
    if (rows.isEmpty) return;
    final row = Map<String,Object?>.from(rows.single);
    final saved = await db.query('daily_history_status',where:'piece_id=?',whereArgs:[id]);
    if(saved.isNotEmpty && saved.single['message']!='') {
      row['title']=saved.single['title']; row['description']=saved.single['description'];
    }
    final kept = <String>{};
    var message = '';
    final result = row['result'] as String;
    final notes = row['notes'] as String;
    final encoded = row['score_entry_json'] as String;
    final description = row['description'] as String;
    final title = row['title'] as String;
    final hasEntry = result.trim().isNotEmpty || notes.trim().isNotEmpty || encoded.isNotEmpty;
    await db.delete('daily_lift_history', where:'piece_id=?', whereArgs:[id]);
    if (hasEntry) {
      final isLift = RegExp(r'^Lift\s+\d', caseSensitive:false).hasMatch(title);
      if (isLift) {
        await db.insert('daily_lift_history', {
          'piece_id':id, 'workout_date':row['workout_date'],
          'lift':description.split('\n').first.trim(), 'prescription':description,
          'score_entry_json':encoded, 'result':result, 'notes':notes,
        }, conflictAlgorithm:ConflictAlgorithm.replace);
        message = 'Saved to lift history';
      }
      Map? entry;
      try { final value = encoded.isEmpty ? null : jsonDecode(encoded); if(value is Map) entry=value; }
      on FormatException { /* Keep original text available for review. */ }
      final raw = entry?['spec'];
      final values = entry?['values'];
      final spec = raw is Map ? FitrScoreSpec(Map<String,dynamic>.from(raw)) : null;
      final valid = spec != null && spec.supported && values is List &&
        values.length == spec.count && values.every((v)=>v is String && spec.validate(v)==null) &&
        entry?['unit'] == spec.unit && values.any((v)=>(v as String).trim().isNotEmpty);
      final isAccessory=RegExp(r'^Accessory(?:\s|$)',caseSensitive:false).hasMatch(title);
      final classification = classifyFitrSection({'title':title,'description':description});
      if(isAccessory) {
        message='Session log saved';
      } else if(classification?['status']=='CANDIDATE' && classification?['type']=='Z2') {
        message=await _z2(db,row,classification!,entry,kept);
      } else if (valid) {
        final scores = List<String>.from(values);
        if (classification?['status']=='CANDIDATE' &&
            const ['GEAR','MIXED_GEAR'].contains(classification?['type'])) {
          message = await _gear(db,row,classification!,spec,scores,kept);
        } else if (detectFitrGear('$title\n$description') != null) {
          message = 'Review: gear timing or modality could not be matched';
        } else {
          final benchmark = await _benchmark(db,row,spec,scores,kept);
          if (benchmark != null) message=benchmark;
        }
      }
      if (message.isEmpty) message=encoded.isEmpty && result.trim().toLowerCase()=='skipped'
        ? 'Skipped — no history score' : 'Review: result saved; no automatic history match';
    }
    final links=await db.query('daily_history_links',where:'piece_id=?',whereArgs:[id]);
    for(final link in links) {
      if(kept.contains(link['slot'])) continue;
      final table=link['kind']=='workout'?'workouts':'benchmark_attempts';
      if(table=='workouts') {
        final intervals=await db.query('workout_intervals',where:'workout_id=?',whereArgs:[link['target_id']]);
        for(final interval in intervals) { await db.delete('interval_metrics',where:'interval_id=?',whereArgs:[interval['id']]); }
        await db.delete('workout_intervals',where:'workout_id=?',whereArgs:[link['target_id']]);
      }
      await db.delete(table,where:'id=?',whereArgs:[link['target_id']]);
      await db.delete('daily_history_links',where:'piece_id=? AND slot=?',whereArgs:[id,link['slot']]);
    }
    await db.insert('daily_history_status',{'piece_id':id,'message':message,'title':title,'description':description},conflictAlgorithm:ConflictAlgorithm.replace);
  }

  static Future<int> _upsert(DatabaseExecutor db, String piece, String slot,
      String kind, Map<String,Object?> data, Set<String> kept) async {
    final table=kind=='workout'?'workouts':'benchmark_attempts';
    final links=await db.query('daily_history_links',where:'piece_id=? AND slot=?',whereArgs:[piece,slot]);
    int? target=links.isEmpty?null:links.single['target_id'] as int;
    if(target!=null && await db.update(table,data,where:'id=?',whereArgs:[target])==0) target=null;
    target ??= await db.insert(table,data);
    await db.insert('daily_history_links',{'piece_id':piece,'slot':slot,'kind':kind,'target_id':target},conflictAlgorithm:ConflictAlgorithm.replace);
    kept.add(slot);
    return target;
  }

  static Future<String> _z2(DatabaseExecutor db, Map<String,Object?> row,
      Map<String,Object?> c, Map? entry, Set<String> kept) async {
    final actual=entry?['actual'] is Map ? entry!['actual'] as Map : const {};
    final legacy=RegExp(r'^\s*([\d,]+(?:\.\d+)?)\s*m\s+in\s+(\d+(?:\.\d+)?)\s*min(?:utes)?\s*$',caseSensitive:false)
      .firstMatch(row['result'] as String);
    final duration=actual['minutes']?.toString() ?? legacy?.group(2) ?? '';
    final minutes=double.tryParse(duration);
    if(minutes==null || !minutes.isFinite || minutes<=0) return 'Review: enter actual Z2 duration in Results / notes';
    const modalities={'Run':'run','AssaultRunner':'assaultRunner','Row':'row','Ski':'ski','C2 Bike':'bikeErg','Echo Bike':'echo'};
    final modality=modalities[actual['modality'] ?? c['modality']];
    if(modality==null) return 'Review: select the actual Z2 machine';
    final owned=await db.query('daily_history_links',where:'piece_id=? AND slot=?',whereArgs:[row['id'],'z2']);
    final existing=await db.query('workouts',where:'prescription_id=? AND modality=? AND substr(workout_date,1,10)=?',whereArgs:['Z2',modality,(row['workout_date'] as String).substring(0,10)]);
    if(existing.any((w)=>owned.isEmpty || w['id']!=owned.single['target_id'])) return 'Review: Z2 session already exists on this date';
    final metrics=<String,String>{};
    final meters=double.tryParse(actual['meters']?.toString() ?? legacy?.group(1)?.replaceAll(',','') ?? '');
    if(meters!=null && meters.isFinite && meters>0) {
      metrics['distance']=modality=='run'?(meters/1609.344).toStringAsFixed(5):_number(meters);
      final scale=const {'run':1609.344,'assaultRunner':1609.344,'row':500.0,'ski':500.0,'bikeErg':1000.0}[modality];
      if(scale!=null) metrics['primaryMetric']=_clock(minutes*60*scale/meters);
    }
    final hr=double.tryParse(actual['heart_rate']?.toString() ?? '');
    if(hr!=null && hr.isFinite && hr>0) metrics['heartRate']=_number(hr);
    final spec=entry?['spec']; final values=entry?['values'];
    final watts=spec is Map && spec['measure']=='watts' && values is List && values.length==1
      ? double.tryParse(values.single.toString()) : null;
    final wattSource=actual['watts_source']?.toString() ?? 'Unspecified';
    if(watts!=null && watts.isFinite && watts>=0) metrics['watts']=_number(watts);
    final target=await _upsert(db,row['id'] as String,'z2','workout',{
      'prescription_id':'Z2','modality':modality,'workout_date':row['workout_date'],
      'source_workbook':'Training Week','program_day':row['id'],
      'duration':_clock(minutes*60),'work_duration':'','interval_count':1,
      'notes':[row['result'],row['notes'],if(watts!=null) 'Watts source: $wattSource',
        'Actual working duration; warm-up/cool-down not inferred. Edit in Training Week.'].where((s)=>s!='').join('\n'),
    },kept);
    final old=await db.query('workout_intervals',where:'workout_id=?',whereArgs:[target]);
    for(final i in old) { await db.delete('interval_metrics',where:'interval_id=?',whereArgs:[i['id']]); }
    await db.delete('workout_intervals',where:'workout_id=?',whereArgs:[target]);
    final interval=await db.insert('workout_intervals',{'workout_id':target,'interval_number':1});
    for(final m in metrics.entries) { await db.insert('interval_metrics',{'interval_id':interval,'metric':m.key,'value':m.value}); }
    return 'Linked to Z2 history${watts==null?'':' • watts: ${wattSource.toLowerCase()}'}';
  }

  static Future<String> _gear(DatabaseExecutor db, Map<String,Object?> row,
      Map<String,Object?> c, FitrScoreSpec spec, List<String> scores, Set<String> kept) async {
    if(!const ['distance','watts','calories'].contains(spec.measure)) return 'Review: gear score needs distance, watts, or calories';
    final steps=<Map<String,Object?>>[];
    if(c['type']=='GEAR') {
      for(var i=0;i<(c['rounds'] as int);i++) {
        steps.add({'prescription':c['prescription'],'modality':c['modality'],'seconds':c['work_seconds']});
      }
    } else {
      for(final s in c['steps'] as List) {
        if((s as Map)['kind']=='work') steps.add(Map<String,Object?>.from(s));
      }
    }
    if(steps.any((s)=>s['seconds'] is! int || (s['seconds'] as int)<=0)) return 'Review: invalid work duration';
    if(steps.length!=scores.length) return 'Review: score count does not match work intervals; no total split into rounds';
    const modalities={'Run':'run','AssaultRunner':'assaultRunner','Row':'row','Ski':'ski','C2 Bike':'bikeErg','Echo Bike':'echo'};
    if(steps.any((s)=>!modalities.containsKey(s['modality']))) return 'Review: unknown modality';
    final groups=<String,List<int>>{};
    for(var i=0;i<steps.length;i++) {
      final s=steps[i];
      final key='${s['prescription']}:${s['modality']}:${s['seconds']}';
      groups.putIfAbsent(key,()=>[]).add(i);
    }
    final owned=await db.query('daily_history_links',where:'piece_id=? AND kind=?',whereArgs:[row['id'],'workout']);
    for(final group in groups.values) {
      final s=steps[group.first];
      final same=await db.query('workouts',where:'prescription_id=? AND modality=? AND substr(workout_date,1,10)=?',
        whereArgs:[s['prescription'],modalities[s['modality']],(row['workout_date'] as String).substring(0,10)]);
      if(same.any((w)=>!owned.any((l)=>l['target_id']==w['id']))) return 'Review: matching gear session already exists on this date';
    }
    for(final group in groups.entries) {
      if(!group.value.any((i)=>scores[i].trim().isNotEmpty)) continue;
      final first=steps[group.value.first];
      final modality=modalities[first['modality']]!;
      final seconds=first['seconds'] as int;
      final target=await _upsert(db,row['id'] as String,'gear:${group.key}','workout',{
        'prescription_id':first['prescription'],'modality':modality,'workout_date':row['workout_date'],
        'source_workbook':'Training Week','program_day':row['id'],
        'work_duration':_clock(seconds),'interval_count':group.value.length,
        'notes':[row['result'],row['notes'],'Linked to Training Week; edit results there.'].where((s)=>s!='').join('\n'),
      },kept);
      // Explicit deletion also works in test databases with foreign keys disabled.
      final old=await db.query('workout_intervals',where:'workout_id=?',whereArgs:[target]);
      for(final interval in old) { await db.delete('interval_metrics',where:'interval_id=?',whereArgs:[interval['id']]); }
      await db.delete('workout_intervals',where:'workout_id=?',whereArgs:[target]);
      for(var j=0;j<group.value.length;j++) {
        final i=group.value[j];
        if(scores[i].trim().isEmpty) continue;
        final interval=await db.insert('workout_intervals',{'workout_id':target,'interval_number':j+1});
        final n=double.parse(scores[i]);
        final metrics=<String,String>{spec.measure:spec.measure=='distance'&&modality=='run'? (n/1609.344).toStringAsFixed(5):scores[i]};
        if(spec.measure=='distance' && n>0 && modality!='echo') {
          final scale=const {'run':1609.344,'assaultRunner':1609.344,'row':500.0,'ski':500.0,'bikeErg':1000.0}[modality]!;
          metrics['primaryMetric']=_clock(seconds*scale/n);
        }
        for(final metric in metrics.entries) {
          await db.insert('interval_metrics',{'interval_id':interval,'metric':metric.key,'value':metric.value});
        }
      }
    }
    return 'Linked to gear history';
  }

  static Future<String?> _benchmark(DatabaseExecutor db, Map<String,Object?> row,
      FitrScoreSpec spec,List<String> scores,Set<String> kept) async {
    // Exact names only: no matching a benchmark mentioned in warm-up notes.
    final names={_normal(row['title'] as String),_normal((row['description'] as String).split('\n').first)};
    final tables=await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='benchmarks'");
    if(tables.isEmpty) return null;
    final matches=(await db.query('benchmarks')).where((b)=>names.contains(_normal(b['name'] as String))).toList();
    if(matches.length!=1) return null;
    final b=matches.single;
    if(scores.any((v)=>v.trim().isEmpty)) return 'Review: benchmark has incomplete scores';
    String? score;
    final type=b['score_type'];
    if(type=='maxWeight') {
      // A benchmark title alone is insufficient when the body prescribes reps.
      final body=_normal(row['description'] as String);
      final repWork=RegExp(r'\b\d+\s*[x×]\s*[2-9]\d*\b',caseSensitive:false).hasMatch(row['description'] as String);
      if(spec.measure!='weight' || !RegExp(r'\b1\s*rm\b|\b1 rep max\b').hasMatch(body) || repWork || body.contains('amrap')) {
        return 'Review: confirm an actual 1RM attempt';
      }
      score=_number(scores.map(double.parse).reduce((a,b)=>a>b?a:b));
    } else if(scores.length==1) {
      const measureFor={'forTime':'time','roundsReps':'round_reps','totalCalories':'calories','averageWatts':'watts','totalReps':'reps','totalDistance':'distance'};
      if(measureFor[type]==spec.measure) score=scores.single;
    }
    if(score==null) return 'Review: benchmark scoring needs confirmation';
    // Avoid creating a second copy of a manually logged attempt on the same day.
    final owned=await db.query('daily_history_links',where:'piece_id=? AND slot=?',whereArgs:[row['id'],'benchmark']);
    final existing=await db.query('benchmark_attempts',where:'benchmark_id=? AND substr(attempt_date,1,10)=?',whereArgs:[b['id'],(row['workout_date'] as String).substring(0,10)]);
    if(existing.any((a)=>owned.isEmpty || a['id']!=owned.single['target_id'])) return 'Review: benchmark already has an attempt on this date';
    await _upsert(db,row['id'] as String,'benchmark','benchmark',{
      'benchmark_id':b['id'],'attempt_date':row['workout_date'],'score':score,
      'source_workbook':'Training Week','program_day':row['id'],
      'details':row['description'],'notes':[row['result'],row['notes']].where((s)=>s!='').join('\n'),
    },kept);
    return 'Linked to benchmark history';
  }
}
