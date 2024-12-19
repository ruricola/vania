import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'db.dart'; // Impor file database

Router routesForOrders() {
  final router = Router();

  // DELETE order berdasarkan order_num
  router.delete('/orders/<order_num>', (Request req, String order_num) async {
    final conn = await connectDb();
    final deletionResult =
        await conn.query('DELETE FROM orders WHERE order_num = ?', [order_num]);
    await conn.close();

    if (deletionResult.affectedRows == 0) {
      return Response.notFound(
          jsonEncode({'error': 'Order not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(
        jsonEncode({'message': 'Order deleted successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  // PUT (update) order berdasarkan order_num
  router.put('/orders/<order_num>', (Request req, String order_num) async {
    final payload = jsonDecode(await req.readAsString());
    final conn = await connectDb();

    final updateResult = await conn.query(
        'UPDATE orders SET order_date = ?, cust_id = ? WHERE order_num = ?',
        [payload['order_date'], payload['cust_id'], order_num]);
    await conn.close();

    if (updateResult.affectedRows == 0) {
      return Response.notFound(
          jsonEncode({'error': 'Order not found'}),
          headers: {'Content-Type': 'application/json'});
    }
    return Response.ok(
        jsonEncode({'message': 'Order updated successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  // POST order baru
  router.post('/orders', (Request req) async {
    final payload = jsonDecode(await req.readAsString());
    final conn = await connectDb();

    await conn.query(
        'INSERT INTO orders (order_num, order_date, cust_id) VALUES (?, ?, ?)',
        [payload['order_num'], payload['order_date'], payload['cust_id']]);
    await conn.close();
    return Response.ok(
        jsonEncode({'message': 'Order added successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  // GET order berdasarkan order_num
  router.get('/orders/<order_num>', (Request req, String order_num) async {
    final conn = await connectDb();
    final results =
        await conn.query('SELECT * FROM orders WHERE order_num = ?', [order_num]);

    if (results.isEmpty) {
      return Response.notFound(
          jsonEncode({'error': 'Order not found'}),
          headers: {'Content-Type': 'application/json'});
    }

    final order = results.first;
    final orderDetails = {
      'order_num': order['order_num'],
      'order_date': order['order_date'].toString(),
      'cust_id': order['cust_id']
    };
    await conn.close();
    return Response.ok(jsonEncode(orderDetails),
        headers: {'Content-Type': 'application/json'});
  });

  // GET semua orders
  router.get('/orders', (Request req) async {
    final conn = await connectDb();
    final results = await conn.query('SELECT * FROM orders');

    final allOrders = results.map((row) {
      return {
        'order_num': row['order_num'],
        'order_date': row['order_date'].toString(),
        'cust_id': row['cust_id']
      };
    }).toList();

    await conn.close();
    return Response.ok(jsonEncode(allOrders),
        headers: {'Content-Type': 'application/json'});
  });


  return router;
}
