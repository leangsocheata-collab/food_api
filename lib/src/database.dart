import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart' show Db, DbCollection, ObjectId;

/// Reads `.env` (project root) first, then system environment.
class Env {
  static final Map<String, String> _v = {};
  static bool _loaded = false;

  static String get(String key, [String fallback = '']) {
    if (!_loaded) {
      _loaded = true;
      final f = File('.env');
      if (f.existsSync()) {
        for (final raw in f.readAsLinesSync()) {
          final line = raw.trim();
          final i = line.indexOf('=');
          if (line.isEmpty || line.startsWith('#') || i <= 0) continue;
          _v[line.substring(0, i).trim()] = line.substring(i + 1).trim();
        }
      }
    }
    return _v[key] ?? Platform.environment[key] ?? fallback;
  }
}

/// One shared MongoDB connection, opened on the first request.
class Database {
  static Db? _db;

  static String _uri() {
    final uri = Env.get('MONGO_URI', 'mongodb://127.0.0.1:27017');
    final name = Env.get('MONGO_DATABASE', 'food_delivery_db');
    if (RegExp(r'^mongodb(\+srv)?://[^/]+/[^?]+').hasMatch(uri)) return uri;
    final q = uri.indexOf('?');
    final base = (q == -1 ? uri : uri.substring(0, q)).replaceAll(RegExp(r'/+$'), '');
    return '$base/$name${q == -1 ? '' : uri.substring(q)}';
  }

  static Future<Db> get db async {
    final c = _db;
    if (c != null && c.isConnected) return c;
    final d = await Db.create(_uri());
    await d.open();
    _db = d;
    print('MongoDB connected');
    return d;
  }

  static Future<DbCollection> col(String n) async => (await db).collection(n);
  static Future<DbCollection> get users => col('users');
  static Future<DbCollection> get restaurants => col('restaurants');
  static Future<DbCollection> get foods => col('foods');
  static Future<DbCollection> get orders => col('orders');
  static Future<DbCollection> get payments => col('payments');
  static Future<DbCollection> get transactions => col('transactions');
}

// ---------- wallet helpers (money) ----------

/// Subtract money atomically. false = not enough balance.
Future<bool> debitWallet(ObjectId userId, double amount) async {
  final users = await Database.users;
  final r = await users.updateOne(
    {'_id': userId, 'walletBalance': {r'$gte': amount}},
    {r'$inc': {'walletBalance': -amount}},
  );
  return r.nModified == 1;
}

Future<void> creditWallet(ObjectId userId, double amount) async {
  final users = await Database.users;
  await users.updateOne({'_id': userId}, {r'$inc': {'walletBalance': amount}});
}

/// type: topup | transfer_out | transfer_in | order_payment | refund
Future<void> logTransaction(ObjectId userId, String type, double amount,
    {String? method, String? note, ObjectId? other, ObjectId? orderId}) async {
  final tx = await Database.transactions;
  await tx.insertOne({
    '_id': ObjectId(),
    'userId': userId,
    'type': type,
    'amount': amount,
    'method': method,
    'note': note,
    'counterpartyId': other,
    'orderId': orderId,
    'createdAt': DateTime.now().toUtc(),
  });
}
