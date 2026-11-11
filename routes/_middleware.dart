import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';

const _cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
};

/// Runs before EVERY route: log, CORS, connect MongoDB, catch errors.
Handler middleware(Handler handler) => handler.use(requestLogger()).use(_base());

Middleware _base() => (handler) => (context) async {
      if (context.request.method == HttpMethod.options) {
        return Response(statusCode: 204, headers: _cors);
      }
      try {
        await Database.db;
        final res = await handler(context);
        return res.copyWith(headers: {...res.headers, ..._cors});
      } catch (e, st) {
        print('ERROR: $e\n$st');
        return fail('Server error: $e', status: 500).copyWith(headers: _cors);
      }
    };
