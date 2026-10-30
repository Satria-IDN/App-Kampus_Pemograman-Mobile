import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_model.dart';

class RoomRemoteDataSource {
  final SupabaseClient _db;
  RoomRemoteDataSource([SupabaseClient? db]) : _db = db ?? Supabase.instance.client;

  Future<List<RoomModel>> fetchRooms({bool onlyActive = false}) async {
    var query = _db.from('rooms').select();
    if (onlyActive) {
      query = query.eq('is_active', true);
    }
    final rows = await query.order('room_name');
    return rows.map<RoomModel>((r) => RoomModel.fromJson(r)).toList();
  }

  Future<void> upsert(RoomModel room) async {
    try {
      if (room.id == null) {
        await _db.from('rooms').insert(room.toJson());
      } else {
        await _db.from('rooms').update(room.toJson()).eq('id', room.id!);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw 'Nama ruangan sudah dipakai.';
      throw e.message;
    }
  }

  Future<void> setActive(String id, bool value) async {
    try {
      await _db.from('rooms').update({'is_active': value}).eq('id', id);
    } on PostgrestException catch (e) {
      throw e.message;
    }
  }
}
