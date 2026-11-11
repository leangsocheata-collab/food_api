import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';

/// POST /api/wallet/top-up {"amount": 50, "method": "cash"}
/// DEMO top-up: money is added instantly (a real app would wait for a payment gateway).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) return notAllowed();
  final me = currentUser(context);
  if (me == null) return unauthorized();
  final b = await readBody(context);
  final amount = toDouble(b['amount']);
  if (amount == null || amount <= 0 || amount > 5000) return fail('amount must be between 0.01 and 5000');
  final amt = round2(amount);
  await creditWallet(me.id, amt);
  await logTransaction(me.id, 'topup', amt, method: (b['method'] ?? 'cash').toString());
  final user = await (await Database.users).findOne({'_id': me.id});
  return ok({'balance': user?['walletBalance']}, message: 'Wallet topped up', status: 201);
}
