import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

/// POST /api/wallet/transfer {"to": "phone or email", "amount": 10, "note": "lunch"}
/// = TRANSFER MONEY from my wallet to another user.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) return notAllowed();
  final me = currentUser(context);
  if (me == null) return unauthorized();
  final b = await readBody(context);
  final amount = toDouble(b['amount']);
  final to = (b['to'] ?? '').toString().trim().toLowerCase();
  if (amount == null || amount <= 0) return fail('amount must be greater than 0');
  if (to.isEmpty) return fail('"to" (phone or email of receiver) is required');

  final users = await Database.users;
  final receiver = await users.findOne({
    r'$or': [
      {'phone': to},
      {'email': to},
    ]
  });
  if (receiver == null) return notFound('Receiver');
  final rid = receiver['_id'] as ObjectId;
  if (rid.toHexString() == me.id.toHexString()) return fail('You cannot transfer to yourself');

  final amt = round2(amount);
  if (!await debitWallet(me.id, amt)) return fail('Insufficient wallet balance', status: 402);
  try {
    await creditWallet(rid, amt);
  } catch (_) {
    await creditWallet(me.id, amt); // give the money back
    return fail('Transfer failed, money returned', status: 500);
  }
  final note = b['note']?.toString();
  await logTransaction(me.id, 'transfer_out', amt, method: 'wallet', other: rid, note: note);
  await logTransaction(rid, 'transfer_in', amt, method: 'wallet', other: me.id, note: note);
  return ok({'amount': amt, 'to': receiver['name']}, message: 'Transfer successful');
}
