import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/fitr_score_entry.dart';

class DailyHistoryScreen extends StatefulWidget {
  const DailyHistoryScreen({super.key});
  @override
  State<DailyHistoryScreen> createState() => _DailyHistoryScreenState();
}
class _DailyHistoryScreenState extends State<DailyHistoryScreen> {
  late final Future<List<Map<String,Object?>>> _rows = _load();
  String _filter='All';
  Future<List<Map<String,Object?>>> _load() async {
    final db=await DatabaseService.instance.database;
    return db.rawQuery('''SELECT p.*, d.workout_date, h.message, h.description AS recorded_prescription, l.lift
      FROM daily_history_status h JOIN fitr_pieces p ON p.id=h.piece_id
      JOIN fitr_days d ON d.id=p.day_id
      LEFT JOIN daily_lift_history l ON l.piece_id=p.id
      WHERE h.message != '' ORDER BY d.workout_date DESC,p.position''');
  }
  String _scores(String text) {
    try {
      final entry=jsonDecode(text) as Map;
      return FitrScoreSpec(Map<String,dynamic>.from(entry['spec'] as Map))
        .summarize(List<String>.from(entry['values'] as List));
    } catch (_) { return text; }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:const Text('Training progress')),
    body:Column(children:[
      Padding(padding:const EdgeInsets.all(12), child:Wrap(spacing:8,children:[
        for(final label in ['All','Lifts','Z2','Needs review']) ChoiceChip(label:Text(label),
          selected:_filter==label,onSelected:(_)=>setState(()=>_filter=label)),
      ])),
      const Padding(padding:EdgeInsets.symmetric(horizontal:16),child:Text(
        'Edit results in Training Week. Linked gear and benchmark entries also appear in their existing histories.')),
      Expanded(child:FutureBuilder<List<Map<String,Object?>>>(future:_rows,builder:(context,snapshot){
        if(snapshot.hasError) return Center(child:Text('Could not load progress: ${snapshot.error}'));
        if(!snapshot.hasData) return const Center(child:CircularProgressIndicator());
        final rows=snapshot.data!.where((r)=>_filter=='All'||(_filter=='Lifts'?r['lift']!=null:_filter=='Z2'?(r['message'] as String).startsWith('Linked to Z2'):(r['message'] as String).startsWith('Review:'))).toList();
        if(rows.isEmpty) return const Center(child:Text('No entries in this view yet.'));
        return ListView.builder(itemCount:rows.length,itemBuilder:(context,i){
          final r=rows[i];
          return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:ExpansionTile(
            title:Text('${r['workout_date']} • ${r['lift'] ?? r['title']}'),
            subtitle:Text(r['message'] as String),
            children:[Padding(padding:const EdgeInsets.all(16),child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,children:[
                if(r['score_entry_json']!='') SelectableText(_scores(r['score_entry_json'] as String)),
                if(r['result']!='') SelectableText('Result: ${r['result']}'),
                if(r['notes']!='') SelectableText('Notes: ${r['notes']}'),
                const SizedBox(height:12),SelectableText(r['recorded_prescription'] as String),
              ]))],
          ));
        });
      })),
    ]),
  );
}
