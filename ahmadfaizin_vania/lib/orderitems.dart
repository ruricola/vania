import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'db.dart'; // Database connection from database.dart

Router manageOrderItems() {
  final router = Router();

  // Endpoint untuk mengupdate order item
  router.put('/orderitems/<id>', (Request request, String id) async {
    final updatedData = jsonDecode(await request.readAsString());
    final dbConnection = await connectDb();
    
    final updateResult = await dbConnection.query(
        'UPDATE orderitems SET order_num = ?, prod_id = ?, quantity = ?, size = ? WHERE order_item = ?',
        [
          updatedData['order_num'],
          updatedData['prod_id'],
          updatedData['quantity'],
          updatedData['size'],
          id
        ]);
    
    await dbConnection.close();
    
    if (updateResult.affectedRows == 0) {
      return Response.notFound(
          jsonEncode({'error': 'No order item found with the given ID'}), 
          headers: {'Content-Type': 'application/json'});
    }
    
    return Response.ok(
        jsonEncode({'message': 'Order item updated successfully'}),
        headers: {'Content-Type': 'application/json'});
  });

  // Endpoint untuk mendapatkan order item berdasarkan ID
  router.get('/orderitems/<id>', (Request request, String id) async {
    final dbConnection = await connectDb();
    final queryResult = await dbConnection.query(
        'SELECT * FROM orderitems WHERE order_item = ?', [id]);
    
    if (queryResult.isEmpty) {
      await dbConnection.close();
      return Response.notFound(
          jsonEncode({'error': 'Order item with the given ID not found'}), 
          headers: {'Content-Type': 'application/json'});
    }
    
    final orderItemData = queryResult.first;
    final orderItem = {
      'order_item': orderItemData['order_item'],
      'order_num': orderItemData['order_num'],
      'prod_id': orderItemData['prod_id'],
      'quantity': orderItemData['quantity'],
      'size': orderItemData['size']
    };
    
    await dbConnection.close();
    return Response.ok(jsonEncode(orderItem),
        headers: {'Content-Type': 'application/json'});
  });

  // Endpoint untuk mendapatkan semua order items
  router.get('/orderitems', (Request request) async {
    final dbConnection = await connectDb();
    final resultSet = await dbConnection.query('SELECT * FROM orderitems');
    final orderItemsList = resultSet.map((row) {
      return {
        'order_item': row['order_item'],
        'order_num': row['order_num'],
        'prod_id': row['prod_id'],
        'quantity': row['quantity'],
        'size': row['size']
      };
    }).toList();
    await dbConnection.close();
    return Response.ok(jsonEncode(orderItemsList),
        headers: {'Content-Type': 'application/json'});
  });

  // Endpoint untuk menambahkan order item baru
  router.post('/orderitems', (Request request) async {
    final requestData = jsonDecode(await request.readAsString());
    final dbConnection = await connectDb();

    await dbConnection.query(
        'INSERT INTO orderitems (order_item, order_num, prod_id, quantity, size) VALUES (?, ?, ?, ?, ?)',
        [
          requestData['order_item'],
          requestData['order_num'],
          requestData['prod_id'],
          requestData['quantity'],
          requestData['size']
        ]);
    
    await dbConnection.close();
    return Response.ok(
        jsonEncode({'message': 'New order item successfully added'}),
        headers: {'Content-Type': 'application/json'});
  });

  // Endpoint untuk menghapus order item berdasarkan ID
  router.delete('/orderitems/<id>', (Request request, String id) async {
    final dbConnection = await connectDb();
    
    final deleteResult = await dbConnection.query(
        'DELETE FROM orderitems WHERE order_item = ?', [id]);
    
    await dbConnection.close();
    
    if (deleteResult.affectedRows == 0) {
      return Response.notFound(
          jsonEncode({'error': 'Order item not found to delete'}),
          headers: {'Content-Type': 'application/json'});
    }
    
    return Response.ok(
        jsonEncode({'message': 'Order item successfully deleted'}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}
