import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'db.dart';

Router productsRoutes() {
  final router = Router();

  // GET semua products
  router.get('/', (Request req) async {
    final conn = await connectDb();
    final results = await conn.query('SELECT * FROM products');
    final products = results
        .map((row) => {
              'prod_id': row['prod_id'],
              'vend_id': row['vend_id'],
              'prod_name': row['prod_name'],
              'prod_price': row['prod_price'],
              'prod_desc': row['prod_desc'],
            })
        .toList();
    await conn.close();
    return Response.ok(jsonEncode(products),
        headers: {'Content-Type': 'application/json'});
  });

  // GET product berdasarkan ID
  router.get('/<id>', (Request req, String id) async {
    final conn = await connectDb();
    final results =
        await conn.query('SELECT * FROM products WHERE prod_id = ?', [id]);
    if (results.isEmpty) {
      return Response.notFound(jsonEncode({'error': 'Product not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    final product = results
        .map((row) => {
              'prod_id': row['prod_id'],
              'vend_id': row['vend_id'],
              'prod_name': row['prod_name'],
              'prod_price': row['prod_price'],
              'prod_desc': row['prod_desc'],
            })
        .first;
    await conn.close();
    return Response.ok(jsonEncode(product),
        headers: {'Content-Type': 'application/json'});
  });

  // POST product baru
  router.post('/', (Request req) async {
    final payload = jsonDecode(await req.readAsString());
    final conn = await connectDb();
    await conn.query(
        'INSERT INTO products (prod_id, vend_id, prod_name, prod_price, prod_desc) VALUES (?, ?, ?, ?, ?)',
        [
          payload['prod_id'],
          payload['vend_id'],
          payload['prod_name'],
          payload['prod_price'],
          payload['prod_desc']
        ]);
    await conn.close();
    return Response.ok(jsonEncode({'message': 'Product added successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  // PUT (update) product
  router.put('/<id>', (Request req, String id) async {
    final payload = jsonDecode(await req.readAsString());
    final conn = await connectDb();
    final result = await conn.query(
        'UPDATE products SET vend_id = ?, prod_name = ?, prod_price = ?, prod_desc = ? WHERE prod_id = ?',
        [
          payload['vend_id'],
          payload['prod_name'],
          payload['prod_price'],
          payload['prod_desc'],
          id
        ]);
    await conn.close();
    if (result.affectedRows == 0) {
      return Response.notFound(jsonEncode({'error': 'Product not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(jsonEncode({'message': 'Product updated successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  // DELETE product
  router.delete('/<id>', (Request req, String id) async {
    final conn = await connectDb();
    final result =
        await conn.query('DELETE FROM products WHERE prod_id = ?', [id]);
    await conn.close();
    if (result.affectedRows == 0) {
      return Response.notFound(jsonEncode({'error': 'Product not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(jsonEncode({'message': 'Product deleted successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}
