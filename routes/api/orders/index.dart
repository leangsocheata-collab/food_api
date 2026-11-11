import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where;

/// GET  /api/orders?status=active|past   (admin sees all orders)
/// POST /api/orders  -> place an order and choose how to pay: cash | wallet | bank_transfer
/// {
///   "items": [ {"foodId": "...", "qty": 2} ],
///   "paymentMethod": "cash",            // cash | wallet | bank_transfer
///   "bankName": "ABA",                  // only for bank_transfer: ABA | ACLEDA | WING
///   "address": "Home BKK1 st124"
/// }
Future<Response> onRequest(RequestContext context) async {
  final me = currentUser(context);
  if (me == null) return unauthorized();
  final orders = await Database.orders;

  if (context.request.method == HttpMethod.get) {
    final tab = context.request.uri.queryParameters['status'];
    final s = me.isAdmin ? where : where.eq('userId', me.id);
    if (tab == 'active') s.oneFrom('status', ['pending_payment', 'confirmed', 'preparing', 'delivering']);
    if (tab == 'past') s.oneFrom('status', ['delivered', 'cancelled']);
    return ok(await orders.find(s.sortBy('createdAt', descending: true).limit(100)).toList());
  }
  if (context.request.method != HttpMethod.post) return notAllowed();

  final b = await readBody(context);
  final method = (b['paymentMethod'] ?? '').toString();
  if (!['cash', 'wallet', 'bank_transfer'].contains(method)) {
    return fail('paymentMethod must be cash, wallet or bank_transfer');
  }
  final address = (b['address'] ?? '').toString().trim();
  if (address.isEmpty) return fail('address is required');
  final rawItems = b['items'];
  if (rawItems is! List || rawItems.isEmpty) return fail('items cannot be empty');

  // price comes from the database, never from the client
  final foods = await Database.foods;
  final items = <Map<String, dynamic>>[];
  var subtotal = 0.0;
  for (final raw in rawItems) {
    if (raw is! Map) return fail('Invalid item');
    final fid = toOid(raw['foodId']?.toString());
    final qty = raw['qty'] is num ? (raw['qty'] as num).toInt() : 1;
    if (fid == null || qty < 1) return fail('Each item needs foodId and qty >= 1');
    final food = await foods.findOne({'_id': fid});
    if (food == null || food['available'] == false) return fail('Food not available: ${raw['foodId']}');
    final price = (food['price'] as num).toDouble();
    subtotal += price * qty;
    items.add({'foodId': fid, 'name': food['name'], 'price': price, 'qty': qty});
  }
  final deliveryFee = double.tryParse(Env.get('DELIVERY_FEE', '0')) ?? 0;
  final total = round2(subtotal + deliveryFee);

  final orderId = ObjectId();
  final paymentId = ObjectId();
  final orderNumber = 'EF${DateTime.now().millisecondsSinceEpoch % 10000000}';
  var orderStatus = 'confirmed';
  final payment = <String, dynamic>{
    '_id': paymentId,
    'orderId': orderId,
    'userId': me.id,
    'method': method,
    'amount': total,
    'createdAt': now(),
  };

  switch (method) {
    case 'cash':
      payment['status'] = 'pending'; // driver collects cash on delivery
      payment['note'] = 'Pay cash to the driver on delivery';
    case 'wallet':
      if (!await debitWallet(me.id, total)) return fail('Insufficient wallet balance', status: 402);
      await logTransaction(me.id, 'order_payment', total,
          method: 'wallet', orderId: orderId, note: 'Order $orderNumber');
      payment['status'] = 'paid';
      payment['paidAt'] = now();
    default: // bank_transfer
      final bank = (b['bankName'] ?? '').toString().toUpperCase();
      if (!['ABA', 'ACLEDA', 'WING'].contains(bank)) return fail('bankName must be ABA, ACLEDA or WING');
      orderStatus = 'pending_payment';
      payment['status'] = 'awaiting_transfer';
      payment['bankName'] = bank;
      payment['reference'] = orderNumber; // write this in the bank transfer note
      payment['transferTo'] = {
        'account': Env.get('${bank}_ACCOUNT'),
        'name': Env.get('ACCOUNT_NAME'),
        'amount': total,
      };
  }

  final order = {
    '_id': orderId,
    'orderNumber': orderNumber,
    'userId': me.id,
    'items': items,
    'subtotal': round2(subtotal),
    'deliveryFee': deliveryFee,
    'total': total,
    'address': address,
    'paymentMethod': method,
    'paymentId': paymentId,
    'status': orderStatus,
    'createdAt': now(),
  };
  await orders.insertOne(order);
  await (await Database.payments).insertOne(payment);
  return ok({...order, 'payment': payment}, message: 'Order placed', status: 201);
}
