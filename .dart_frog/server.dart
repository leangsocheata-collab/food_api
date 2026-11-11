// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/index.dart' as index;
import '../routes/api/health.dart' as api_health;
import '../routes/api/wallet/transfer.dart' as api_wallet_transfer;
import '../routes/api/wallet/transactions.dart' as api_wallet_transactions;
import '../routes/api/wallet/top-up.dart' as api_wallet_top_up;
import '../routes/api/wallet/index.dart' as api_wallet_index;
import '../routes/api/restaurants/index.dart' as api_restaurants_index;
import '../routes/api/restaurants/[id].dart' as api_restaurants_$id;
import '../routes/api/payments/index.dart' as api_payments_index;
import '../routes/api/payments/[id]/verify.dart' as api_payments_$id_verify;
import '../routes/api/payments/[id]/index.dart' as api_payments_$id_index;
import '../routes/api/orders/index.dart' as api_orders_index;
import '../routes/api/orders/[id].dart' as api_orders_$id;
import '../routes/api/foods/index.dart' as api_foods_index;
import '../routes/api/foods/[id].dart' as api_foods_$id;
import '../routes/api/auth/register.dart' as api_auth_register;
import '../routes/api/auth/me.dart' as api_auth_me;
import '../routes/api/auth/login.dart' as api_auth_login;

import '../routes/_middleware.dart' as middleware;

void main() async {
  final address = InternetAddress.tryParse('') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(buildRootHandler()).handler;
  return serve(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline().addMiddleware(middleware.middleware);
  final router = Router()
    ..mount('/', (context) => buildHandler()(context))
    ..mount('/api', (context) => buildApiHandler()(context))
    ..mount('/api/wallet', (context) => buildApiWalletHandler()(context))
    ..mount('/api/restaurants', (context) => buildApiRestaurantsHandler()(context))
    ..mount('/api/payments', (context) => buildApiPaymentsHandler()(context))
    ..mount('/api/payments/<id>', (context,id,) => buildApiPayments$idHandler(id,)(context))
    ..mount('/api/orders', (context) => buildApiOrdersHandler()(context))
    ..mount('/api/foods', (context) => buildApiFoodsHandler()(context))
    ..mount('/api/auth', (context) => buildApiAuthHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/health', (context) => api_health.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiWalletHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/top-up', (context) => api_wallet_top_up.onRequest(context,))..all('/transactions', (context) => api_wallet_transactions.onRequest(context,))..all('/transfer', (context) => api_wallet_transfer.onRequest(context,))..all('/', (context) => api_wallet_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiRestaurantsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<id>', (context,id,) => api_restaurants_$id.onRequest(context,id,))..all('/', (context) => api_restaurants_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiPaymentsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => api_payments_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiPayments$idHandler(String id,) {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/verify', (context) => api_payments_$id_verify.onRequest(context,id,))..all('/', (context) => api_payments_$id_index.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildApiOrdersHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<id>', (context,id,) => api_orders_$id.onRequest(context,id,))..all('/', (context) => api_orders_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiFoodsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/<id>', (context,id,) => api_foods_$id.onRequest(context,id,))..all('/', (context) => api_foods_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildApiAuthHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/login', (context) => api_auth_login.onRequest(context,))..all('/me', (context) => api_auth_me.onRequest(context,))..all('/register', (context) => api_auth_register.onRequest(context,));
  return pipeline.addHandler(router);
}

