import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/http.dart';

Response onRequest(RequestContext context) =>
    ok({'name': 'Food Delivery API', 'health': '/api/health'});
