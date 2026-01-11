import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app/services/database_service.dart';
import 'package:app/models/user_model.dart';

void main() {
  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Use in-memory database for speed and isolation
    // But DatabaseService uses getDatabasesPath().
    // We can't easily mock the path unless we change DatabaseService or mock getDatabasesPath (hard).
    // So we'll stick to file but delete it.
    // Actually, sqflite_common_ffi supports inMemoryDatabasePath under the hood if we can pass it.
    // But DatabaseService hardcodes 'tasks.db'.

    // We will delete the DB file.
    // To do that we need path package or just rely on overwrite?
    // Let's rely on cleaning up content using DELETE query maybe?
  });

  test('DatabaseService User CRUD', () async {
    final service = DatabaseService();
    // Re-init / clean
    final db = await service.database;
    await db.delete('users');

    final user = User(id: '123', email: 'test@unit.com', password: 'pass');

    // Register
    await service.registerUser(user);

    // Login Success
    final loggedIn = await service.loginUser('test@unit.com', 'pass');
    expect(loggedIn, isNotNull);
    expect(loggedIn!.email, 'test@unit.com');

    // Login Fail
    final failedLogin = await service.loginUser('test@unit.com', 'wrong');
    expect(failedLogin, isNull);

    // Duplicate Register
    try {
      await service.registerUser(user);
      fail('Should throw exception');
    } catch (e) {
      expect(e.toString(), contains('Email already exists'));
    }
  });
}
