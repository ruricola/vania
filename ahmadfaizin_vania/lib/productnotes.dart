import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'db.dart'; // Shared koneksi database

Router productNotesRoutes() {
  final router = Router();

  // GET semua productnotes
  router.get('/', (Request req) async {
    final conn = await connectDb();
    final results = await conn.query('SELECT * FROM productnotes');
    final productNotes = results
        .map((row) => {
              'note_id': row['note_id'],
              'prod_id': row['prod_id'],
              'note_date': row['note_date'].toString(),
              'note_text': row['note_text']
            })
        .toList();
    await conn.close();
    return Response.ok(jsonEncode(productNotes),
        headers: {'Content-Type': 'application/json'});
  });

  // GET productnote berdasarkan note_id
  router.get('/<id>', (Request req, String id) async {
    final conn = await connectDb();
    final results =
        await conn.query('SELECT * FROM productnotes WHERE note_id = ?', [id]);
    if (results.isEmpty) {
      await conn.close();
      return Response.notFound(jsonEncode({'error': 'Product note not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    final productNote = results
        .map((row) => {
              'note_id': row['note_id'],
              'prod_id': row['prod_id'],
              'note_date': row['note_date'].toString(),
              'note_text': row['note_text']
            })
        .first;
    await conn.close();
    return Response.ok(jsonEncode(productNote),
        headers: {'Content-Type': 'application/json'});
  });

  // POST productnote baru
  router.post('/', (Request req) async {
    final payload = jsonDecode(await req.readAsString());
    final conn = await connectDb();
    await conn.query(
        'INSERT INTO productnotes (note_id, prod_id, note_date, note_text) VALUES (?, ?, ?, ?)',
        [
          payload['note_id'],
          payload['prod_id'],
          payload['note_date'],
          payload['note_text']
        ]);
    await conn.close();
    return Response.ok(
        jsonEncode({'message': 'Product note added successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  // PUT (update) productnote
  router.put('/<id>', (Request req, String id) async {
    final payload = jsonDecode(await req.readAsString());
    final conn = await connectDb();
    final result = await conn.query(
        'UPDATE productnotes SET prod_id = ?, note_date = ?, note_text = ? WHERE note_id = ?',
        [payload['prod_id'], payload['note_date'], payload['note_text'], id]);
    await conn.close();
    if (result.affectedRows == 0) {
      return Response.notFound(jsonEncode({'error': 'Product note not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(
        jsonEncode({'message': 'Product note updated successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  // DELETE productnote
  router.delete('/<id>', (Request req, String id) async {
    final conn = await connectDb();
    final result =
        await conn.query('DELETE FROM productnotes WHERE note_id = ?', [id]);
    await conn.close();
    if (result.affectedRows == 0) {
      return Response.notFound(jsonEncode({'error': 'Product note not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(
        jsonEncode({'message': 'Product note deleted successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}
