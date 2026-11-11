import 'dart:io';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

/// Run once:  dart run bin/seed.dart
Future<void> main() async {
  final now = DateTime.now().toUtc();
  final resCol = await Database.restaurants;
  final foodCol = await Database.foods;
  await resCol.drop();
  await foodCol.drop();

  final ids = <String, ObjectId>{};
  for (final r in [
    ['Khmer Home Kitchen', 'khmer-food', 4.8],
    ['Noodle House', 'noodles', 4.6],
    ['Napoli Pizza', 'pizza', 4.5],
    ['Smash Burger Bar', 'burgers', 4.7],
    ['Sakura Sushi', 'sushi', 4.9],
  ]) {
    final id = ObjectId();
    ids[r[1] as String] = id;
    await resCol.insertOne({'_id': id, 'name': r[0], 'cuisine': r[1], 'address': 'Phnom Penh', 'rating': r[2], 'createdAt': now});
  }

  final foods = [
    ['Kuy Teav', 3.20, 'khmer-food'], ['Amok Trey', 4.50, 'khmer-food'],
    ['Nom Banh Chok', 2.75, 'khmer-food'], ['Bai Sach Chrouk', 2.20, 'khmer-food'],
    ['Samlor Machu Trey', 2.80, 'khmer-food'], ['Cha Kdam', 4.50, 'khmer-food'],
    ['Lort Cha', 3.50, 'noodles'], ['Buldak Spicy Noodles', 2.90, 'noodles'],
    ['Cheese Spaghetti', 4.20, 'noodles'], ['Jajangmyeong Noodles', 4.90, 'noodles'],
    ['Double Pepperoni Overload', 11.50, 'pizza'], ['Classic Margherita', 9.90, 'pizza'],
    ['Smoky BBQ Chicken Pizza', 12.20, 'pizza'], ['Smoked Bacon Avocado Burger', 9.80, 'burgers'],
    ['Swiss Truffle Mushroom Burger', 10.50, 'burgers'], ['Fried Chicken', 2.50, 'burgers'],
    ['Nigiri Combo', 14.80, 'sushi'], ['Dragon Roll', 11.50, 'sushi'], ['Sashimi Platter', 16.90, 'sushi'],
  ];
  for (final f in foods) {
    await foodCol.insertOne({
      '_id': ObjectId(), 'name': f[0], 'description': '${f[0]} - fresh and delicious', 'price': f[1],
      'category': f[2], 'restaurantId': ids[f[2]], 'available': true, 'createdAt': now,
    });
  }

  final users = await Database.users;
  if (await users.findOne({'email': 'admin@eatfood.com'}) == null) {
    await users.insertOne({
      '_id': ObjectId(), 'name': 'Admin', 'email': 'admin@eatfood.com', 'phone': '000000000',
      'passwordHash': DBCrypt().hashpw('Admin@123', DBCrypt().gensalt()),
      'role': 'admin', 'walletBalance': 0.0, 'createdAt': now,
    });
  }
  print('Seed done: 5 restaurants, ${foods.length} foods, admin user');
  print('Admin login: admin@eatfood.com / Admin@123');
  exit(0);
}
