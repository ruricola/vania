import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'db.dart'; // Shared koneksi database

const secretKey = 'your_secret_key'; // Kunci rahasia JWT

Router setupAuthRoutes() {
  final router = Router();

  // Route untuk register user
  router.post('/register', (Request request) async {
    final requestData = jsonDecode(await request.readAsString());
    final username = requestData['username'];
    final password = requestData['password'];
    final email = requestData['email'];

    // Validasi input
    if ([username, password, email].any((element) => element == null)) {
      return _generateBadRequestResponse('Username, password, and email are required');
    }

    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    final connection = await connectDb();
    try {
      await connection.query(
          'INSERT INTO users (username, password, email) VALUES (?, ?, ?)',
          [username, hashedPassword, email]);
      await connection.close();
      return _generateSuccessResponse('User registered successfully');
    } catch (error) {
      await connection.close();
      return _generateErrorResponse('Registration failed', error);
    }
  });

  // Route untuk login user dan menghasilkan JWT
  router.post('/login', (Request request) async {
    final requestData = jsonDecode(await request.readAsString());
    final username = requestData['username'];
    final password = requestData['password'];

    if ([username, password].any((element) => element == null)) {
      return _generateBadRequestResponse('Username and password are required');
    }

    final connection = await connectDb();
    final results = await connection.query(
        'SELECT user_id, username, password FROM users WHERE username = ?',
        [username]);

    if (results.isEmpty) {
      await connection.close();
      return _generateUnauthorizedResponse('Invalid username or password');
    }

    final user = results.first;
    if (!BCrypt.checkpw(password, user['password'])) {
      await connection.close();
      return _generateUnauthorizedResponse('Invalid username or password');
    }

    final token = _generateJWT(user);

    await connection.close();
    return Response.ok(jsonEncode({'token': token}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}

Response _generateBadRequestResponse(String message) {
  return Response.badRequest(
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'}
  );
}

Response _generateSuccessResponse(String message) {
  return Response.ok(
    jsonEncode({'message': message}),
    headers: {'Content-Type': 'application/json'}
  );
}

Response _generateErrorResponse(String message, dynamic details) {
  return Response.internalServerError(
    body: jsonEncode({'error': message, 'details': details.toString()}),
    headers: {'Content-Type': 'application/json'}
  );
}

Response _generateUnauthorizedResponse(String message) {
  return Response.unauthorized(
    jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'}
  );
}

String _generateJWT(Map<String, dynamic> user) {
  final jwt = JWT({'id': user['user_id'], 'username': user['username']});
  return jwt.sign(SecretKey(secretKey), expiresIn: Duration(hours: 2));
}
