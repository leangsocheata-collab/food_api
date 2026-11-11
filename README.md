# Food Delivery API (lite) — Dart Frog + MongoDB + Postman

## 1. Install (one time)
1. Dart SDK 3.3+ — https://dart.dev/get-dart  (check: `dart --version`)
2. MongoDB Community Server + Compass — https://www.mongodb.com/try/download/community (default install; runs on port 27017)
3. Dart Frog CLI: `dart pub global activate dart_frog_cli`
   Windows: if `dart_frog` is not recognized, add `%LOCALAPPDATA%\Pub\Cache\bin` to PATH and reopen the terminal.
4. Postman — https://www.postman.com/downloads/

## 2. Run (terminal in the folder with pubspec.yaml)
```
dart pub get
dart run bin/seed.dart
dart_frog dev
```
Server: http://localhost:8080

## 3. See the result
- Browser: http://localhost:8080/api/health  and  http://localhost:8080/api/foods
- MongoDB Compass: `mongodb://127.0.0.1:27017` → `food_delivery_db`
- Postman: Import `postman/Food_Delivery_API.postman_collection.json`, run folders 0 → 6 in order.
Admin: admin@eatfood.com / Admin@123      Flutter emulator URL: http://10.0.2.2:8080

## Files (folder = URL)
| File | URL |
|---|---|
| routes/api/auth/register, login, me | /api/auth/... |
| routes/api/restaurants/index, [id] | /api/restaurants, /api/restaurants/:id |
| routes/api/foods/index, [id] | /api/foods, /api/foods/:id |
| routes/api/orders/index, [id] | /api/orders, /api/orders/:id |
| routes/api/payments/index, [id], [id]/verify | /api/payments, /api/payments/:id, /api/payments/:id/verify |
| routes/api/wallet/index, top-up, transactions, transfer | /api/wallet/... |
| routes/_middleware.dart | runs before every route |
Shared code: lib/src/database.dart (env + MongoDB + wallet money), auth.dart (JWT), http.dart (responses).

## Payments (teacher requirement)
- **Cash**: order with `paymentMethod: "cash"` → admin sets order `delivered` → payment becomes `paid`
  (or admin `PATCH /api/payments/:id/verify {"approved": true}`).
- **Bank transfer** (ABA / ACLEDA / WING): order returns the bank account + reference →
  customer `POST /api/payments/:id/verify {"transactionRef": "..."}` → admin `PATCH .../verify {"approved": true}`.
- **Transfer money**: `POST /api/wallet/transfer {"to": phone/email, "amount": 10}`. Add money: `POST /api/wallet/top-up` (demo, instant).
- **Wallet payment**: `paymentMethod: "wallet"`; cancelling the order refunds the wallet.

## Troubleshooting
| Problem | Fix |
|---|---|
| dart_frog not recognized | add `%LOCALAPPDATA%\Pub\Cache\bin` to PATH |
| connection refused | start MongoDB: Windows → Services → MongoDB Server → Start |
| port in use | `dart_frog dev --port 8081` |
| 401 in Postman | run Login first (token is saved automatically) |
| empty foods | run `dart run bin/seed.dart` |
