import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'db.dart'; // Impor koneksi database

Router vendorsRoutes() {
  final router = Router();

  // GET semua vendors
  router.get('/', (Request req) async {
    final conn = await connectDb(); // Koneksi database dari database.dart
    final results = await conn.query('SELECT * FROM vendors');
    final vendors = results
        .map((row) => {
              'vend_id': row['vend_id'],
              'vend_name': row['vend_name'],
              'vend_address': row['vend_address'],
              'vend_kota': row['vend_kota'],
              'vend_state': row['vend_state'],
              'vend_zip': row['vend_zip'],
              'vend_country': row['vend_country']
            })
        .toList();
    await conn.close();
    return Response.ok(jsonEncode(vendors),
        headers: {'Content-Type': 'application/json'});
  });

  // GET vendor berdasarkan ID
  router.get('/<id>', (Request req, String id) async {
    final conn = await connectDb();
    final results =
        await conn.query('SELECT * FROM vendors WHERE vend_id = ?', [id]);
    if (results.isEmpty) {
      await conn.close();
      return Response.notFound(jsonEncode({'error': 'Vendor not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    final vendor = results
        .map((row) => {
              'vend_id': row['vend_id'],
              'vend_name': row['vend_name'],
              'vend_address': row['vend_address'],
              'vend_kota': row['vend_kota'],
              'vend_state': row['vend_state'],
              'vend_zip': row['vend_zip'],
              'vend_country': row['vend_country']
            })
        .first;
    await conn.close();
    return Response.ok(jsonEncode(vendor),
        headers: {'Content-Type': 'application/json'});
  });

  // POST vendor baru
  router.post('/', (Request req) async {
    final payload = jsonDecode(await req.readAsString());
    final conn = await connectDb();
    await conn.query(
        'INSERT INTO vendors (vend_id, vend_name, vend_address, vend_kota, vend_state, vend_zip, vend_country) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          payload['vend_id'],
          payload['vend_name'],
          payload['vend_address'],
          payload['vend_kota'],
          payload['vend_state'],
          payload['vend_zip'],
          payload['vend_country']
        ]);
    await conn.close();
    return Response.ok(jsonEncode({'message': 'Vendor added successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  // PUT (update) vendor
  router.put('/<id>', (Request req, String id) async {
    final payload = jsonDecode(await req.readAsString());
    final conn = await connectDb();
    final result = await conn.query(
        'UPDATE vendors SET vend_name = ?, vend_address = ?, vend_kota = ?, vend_state = ?, vend_zip = ?, vend_country = ? WHERE vend_id = ?',
        [
          payload['vend_name'],
          payload['vend_address'],
          payload['vend_kota'],
          payload['vend_state'],
          payload['vend_zip'],
          payload['vend_country'],
          id
        ]);
    await conn.close();
    if (result.affectedRows == 0) {
      return Response.notFound(jsonEncode({'error': 'Vendor not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(jsonEncode({'message': 'Vendor updated successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  // DELETE vendor
  router.delete('/<id>', (Request req, String id) async {
    final conn = await connectDb();
    final result =
        await conn.query('DELETE FROM vendors WHERE vend_id = ?', [id]);
    await conn.close();
    if (result.affectedRows == 0) {
      return Response.notFound(jsonEncode({'error': 'Vendor not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(jsonEncode({'message': 'Vendor deleted successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}
