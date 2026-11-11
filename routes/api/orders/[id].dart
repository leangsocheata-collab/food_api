import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

const _statuses = ['confirmed', 'preparing', 'delivering', 'delivered', 'cancelled'];

/// GET   /api/orders/:id                  order + its payment
/// PATCH /api/orders/:id {"status": "cancelled"}   customer can only cancel;
///        admin can set confirmed | preparing | delivering | delivered | cancelled
Future<Response> onRequest(RequestContext context, String id) async {
  final me = currentUser(context);
  if (me == null) return unauthorized();
  final oid = toOid(id);
  if (oid == null) return fail('Invalid id');
  final orders = await Database.orders;
  final payments = await Database.payments;

  final o = await orders.findOne({'_id': oid});
  final mine = o != null && (o['userId'] as ObjectId).toHexString() == me.id.toHexString();
  if (o == null || (!me.isAdmin && !mine)) return notFound('Order');

  switch (context.request.method) {
    case HttpMethod.get:
      return ok({...o, 'payment': await payments.findOne({'_id': o['paymentId']})});

    case HttpMethod.patch:
      final b = await readBody(context);
      final status = (b['status'] ?? '').toString();
      if (!_statuses.contains(status)) return fail('status must be one of ${_statuses.join(', ')}');
      if (!me.isAdmin && status != 'cancelled') return fail('You can only cancel your order', status: 403);
      if (o['status'] == 'pending_payment' && status != 'cancelled') {
        return fail('Verify the bank transfer first');
      }
      if (status == 'cancelled' && !['pending_payment', 'confirmed'].contains(o['status'])) {
        return fail('Order can no longer be cancelled');
      }

      final pay = await payments.findOne({'_id': o['paymentId']});
      if (pay != null) {
        final set = <String, dynamic>{};
        if (status == 'delivered' && pay['method'] == 'cash' && pay['status'] == 'pending') {
          set['status'] = 'paid'; // driver collected the cash
          set['paidAt'] = now();
        }
        if (status == 'cancelled' && pay['method'] == 'wallet' && pay['status'] == 'paid') {
          final amount = (pay['amount'] as num).toDouble();
          await creditWallet(o['userId'] as ObjectId, amount);
          await logTransaction(o['userId'] as ObjectId, 'refund', amount,
              method: 'wallet', orderId: oid, note: 'Refund ${o['orderNumber']}');
          set['status'] = 'refunded';
        }
        if (set.isNotEmpty) await payments.updateOne({'_id': pay['_id']}, {r'$set': set});
      }
      await orders.updateOne({'_id': oid}, {r'$set': {'status': status}});
      return ok(await orders.findOne({'_id': oid}), message: 'Order $status');

    default:
      return notAllowed();
  }
}
