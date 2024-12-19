import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'db.dart';

Router initializeCustomerEndpoints() {
  final router = Router();

  // Menghapus data pelanggan berdasarkan ID
  router.delete('/<id>', (Request request, String id) async {
    final connection = await connectDb();
    final deleteResult = await connection.query(
      'DELETE FROM customers WHERE cust_id = ?', [id]
    );
    await connection.close();

    if (deleteResult.affectedRows == 0) {
      return _createErrorResponse('Customer not found');
    }

    return Response.ok(
      jsonEncode({'message': 'Customer deleted successfully'}),
      headers: {'Content-Type': 'application/json'}
    );
  });

  // Mendapatkan seluruh data pelanggan
  router.get('/', (Request request) async {
    final connection = await connectDb();
    final customerRecords = await connection.query('SELECT * FROM customers');
    final customerList = customerRecords.map((row) {
      return {
        'cust_id': row['cust_id'],
        'cust_name': row['cust_name'],
        'cust_address': row['cust_address'],
        'cust_city': row['cust_city'],
        'cust_state': row['cust_state'],
        'cust_zip': row['cust_zip'],
        'cust_country': row['cust_country'],
        'cust_telp': row['cust_telp']
      };
    }).toList();
    await connection.close();
    return Response.ok(
      jsonEncode(customerList),
      headers: {'Content-Type': 'application/json'}
    );
  });

  // Mendapatkan data pelanggan berdasarkan ID
  router.get('/<id>', (Request request, String id) async {
    final connection = await connectDb();
    final customerQuery = await connection.query(
      'SELECT * FROM customers WHERE cust_id = ?', [id]
    );

    if (customerQuery.isEmpty) {
      await connection.close();
      return _createErrorResponse('Customer not found');
    }

    final customer = customerQuery.first;
    final customerDetails = {
      'cust_id': customer['cust_id'],
      'cust_name': customer['cust_name'],
      'cust_address': customer['cust_address'],
      'cust_city': customer['cust_city'],
      'cust_state': customer['cust_state'],
      'cust_zip': customer['cust_zip'],
      'cust_country': customer['cust_country'],
      'cust_telp': customer['cust_telp']
    };

    await connection.close();
    return Response.ok(
      jsonEncode(customerDetails),
      headers: {'Content-Type': 'application/json'}
    );
  });

  // Memperbarui data pelanggan
  router.put('/<id>', (Request request, String id) async {
    final payload = jsonDecode(await request.readAsString());
    final connection = await connectDb();

    final updateResult = await connection.query(
      'UPDATE customers SET cust_name = ?, cust_address = ?, cust_city = ?, cust_state = ?, cust_zip = ?, cust_country = ?, cust_telp = ? WHERE cust_id = ?',
      [
        payload['cust_name'],
        payload['cust_address'],
        payload['cust_city'],
        payload['cust_state'],
        payload['cust_zip'],
        payload['cust_country'],
        payload['cust_telp'],
        id
      ]
    );
    await connection.close();

    if (updateResult.affectedRows == 0) {
      return _createErrorResponse('Customer not found');
    }

    return Response.ok(
      jsonEncode({'message': 'Customer updated successfully'}),
      headers: {'Content-Type': 'application/json'}
    );
  });

  // Menambahkan pelanggan baru
  router.post('/', (Request request) async {
    final payload = jsonDecode(await request.readAsString());
    final connection = await connectDb();

    await connection.query(
      'INSERT INTO customers (cust_id, cust_name, cust_address, cust_city, cust_state, cust_zip, cust_country, cust_telp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        payload['cust_id'],
        payload['cust_name'],
        payload['cust_address'],
        payload['cust_city'],
        payload['cust_state'],
        payload['cust_zip'],
        payload['cust_country'],
        payload['cust_telp']
      ]
    );
    await connection.close();
    return Response.ok(
      jsonEncode({'message': 'Customer added successfully'}),
      headers: {'Content-Type': 'application/json'}
    );
  });

  return router;
}

Response _createErrorResponse(String errorMessage) {
  return Response.notFound(
    jsonEncode({'error': errorMessage}),
    headers: {'Content-Type': 'application/json'}
  );
}
