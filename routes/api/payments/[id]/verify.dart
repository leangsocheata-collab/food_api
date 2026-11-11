import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

/// POST  /api/payments/:id/verify {"transactionRef": "ABA-123"}
///        customer: "I sent the bank transfer, here is the transaction number"
/// PATCH /api/payments/:id/verify {"approved": true}
///        admin: bank transfer is real  (or: cash was received from the driver)
Future<Response> onRequest(RequestContext context, String id) async {
  final me = currentUser(context);
  if (me == null) return unauthorized();
  final oid = toOid(id);
  if (oid == null) return fail('Invalid id');
  final payments = await Database.payments;
  final orders = await Database.orders;
  final p = await payments.findOne({'_id': oid});
  final mine = p != null && (p['userId'] as ObjectId).toHexString() == me.id.toHexString();
  if (p == null || (!me.isAdmin && !mine)) return notFound('Payment');

  switch (context.request.method) {
    case HttpMethod.post:
      if (p['method'] != 'bank_transfer' || p['status'] != 'awaiting_transfer') {
        return fail('This payment is not waiting for a bank transfer');
      }
      final b = await readBody(context);
      final ref = (b['transactionRef'] ?? '').toString().trim();
      if (ref.isEmpty) return fail('transactionRef (bank transaction number) is required');
      await payments.updateOne({'_id': oid}, {
        r'$set': {'status': 'submitted', 'transactionRef': ref, 'submittedAt': now()}
      });
      return ok(await payments.findOne({'_id': oid}), message: 'Submitted, waiting for admin');

    case HttpMethod.patch:
      if (!me.isAdmin) return forbidden();
      final b = await readBody(context);
      final approved = b['approved'] == true;
      final waitingBank = p['method'] == 'bank_transfer' && p['status'] == 'submitted';
      final waitingCash = p['method'] == 'cash' && p['status'] == 'pending';
      if (!waitingBank && !waitingCash) return fail('Nothing to verify for this payment');

      if (approved) {
        await payments.updateOne({'_id': oid}, {r'$set': {'status': 'paid', 'paidAt': now()}});
        if (waitingBank) {
          await orders.updateOne({'_id': p['orderId']}, {r'$set': {'status': 'confirmed'}});
        }
      } else {
        // bank transfer rejected -> customer may submit again
        await payments.updateOne({'_id': oid}, {
          r'$set': {'status': 'awaiting_transfer', 'rejectedReason': b['reason'] ?? 'Transfer not found'}
        });
      }
      return ok(await payments.findOne({'_id': oid}), message: approved ? 'Payment approved' : 'Payment rejected');

    default:
      return notAllowed();
  }
}
