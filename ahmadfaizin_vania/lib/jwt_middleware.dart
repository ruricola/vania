import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

const _secretKey = 'your_secret_key';

Middleware jwtAuthorization() {
  return (Handler handler) {
    return (Request request) async {
      final authorizationHeader = request.headers['Authorization'];

      if (authorizationHeader != null && authorizationHeader.startsWith('Bearer ')) {
        final token = authorizationHeader.substring(7);
        try {
          final decodedToken = JWT.verify(token, SecretKey(_secretKey));
          request = request.change(context: {'user': decodedToken.payload});
          return handler(request);
        } catch (e) {
          return Response.forbidden('Token is invalid or expired');
        }
      }

      // Proceed with the request if no token is provided (for routes that do not require a token)
      return handler(request);
    };
  };
}
