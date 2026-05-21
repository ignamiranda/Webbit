import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:webbit/models/reddit_account.dart';
import 'package:webbit/services/account_manager.dart';

void main() {
  late Directory tempDir;
  late String storagePath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('webbit_test_');
    storagePath = '${tempDir.path}/accounts.json';
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('AccountManager', () {
    test('starts with no accounts', () async {
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      expect(manager.accounts, isEmpty);
      expect(manager.lastActiveId, isNull);
    });

    test('persists accounts across instances', () async {
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      await manager.addAccount('Test User', [], username: 'testuser');
      expect(manager.accounts, hasLength(1));

      final manager2 = AccountManager(storagePath: storagePath);
      await manager2.initialize();
      expect(manager2.accounts, hasLength(1));
      expect(manager2.accounts.first.displayName, 'Test User');
      expect(manager2.accounts.first.username, 'testuser');
    });

    test('addAccount sets the new account as active', () async {
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      await manager.addAccount('Alice', []);
      expect(manager.lastActiveId, manager.accounts.first.id);
    });

    test('removeAccount removes the account', () async {
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      await manager.addAccount('Alice', []);
      await manager.addAccount('Bob', []);
      expect(manager.accounts, hasLength(2));

      final aliceId = manager.accounts.first.id;
      await manager.removeAccount(aliceId);
      expect(manager.accounts, hasLength(1));
      expect(manager.accounts.first.displayName, 'Bob');
    });

    test('removeAccount updates lastActiveId when active is removed', () async {
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      await manager.addAccount('Alice', []);
      await manager.addAccount('Bob', []);
      final bobId = manager.accounts.firstWhere((a) => a.displayName == 'Bob').id;
      expect(manager.lastActiveId, bobId);

      await manager.removeAccount(bobId);
      expect(manager.lastActiveId, isNot(bobId));
      expect(manager.lastActiveId, manager.accounts.first.id);
    });

    test('removeAccount clears lastActiveId when last account removed', () async {
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      await manager.addAccount('Alice', []);
      await manager.removeAccount(manager.accounts.first.id);
      expect(manager.lastActiveId, isNull);
    });

    test('findById returns correct account', () async {
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      await manager.addAccount('Alice', []);
      final id = manager.accounts.first.id;
      final found = manager.findById(id);
      expect(found, isNotNull);
      expect(found!.displayName, 'Alice');
    });

    test('findById returns null for missing id', () async {
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      expect(manager.findById('nonexistent'), isNull);
    });

    test('lastActiveAccountId returns null when no accounts', () async {
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      final id = await manager.lastActiveAccountId();
      expect(id, isNull);
    });

    test('lastActiveAccountId returns active id when accounts exist', () async {
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      await manager.addAccount('Alice', []);
      final id = await manager.lastActiveAccountId();
      expect(id, isNotNull);
      expect(id, manager.accounts.first.id);
    });

    test('markActive updates lastUsedAt and lastActiveId', () async {
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      await manager.addAccount('Alice', []);
      await manager.addAccount('Bob', []);

      final aliceId = manager.accounts.first.id;
      final bobId = manager.accounts.last.id;
      expect(manager.lastActiveId, bobId);

      await manager.markActive(aliceId);
      expect(manager.lastActiveId, aliceId);
    });

    test('markActive persists across instances', () async {
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      await manager.addAccount('Alice', []);
      await manager.addAccount('Bob', []);
      final aliceId = manager.accounts.first.id;
      await manager.markActive(aliceId);

      final manager2 = AccountManager(storagePath: storagePath);
      await manager2.initialize();
      expect(manager2.lastActiveId, aliceId);
    });

    test('handles corrupted JSON gracefully', () async {
      File(storagePath).writeAsStringSync('not valid json');
      final manager = AccountManager(storagePath: storagePath);
      await manager.initialize();
      expect(manager.accounts, isEmpty);
      expect(manager.lastActiveId, isNull);
    });
  });

  group('RedditAccount serialization', () {
    test('round-trips through JSON', () {
      final account = RedditAccount(
        id: '123',
        displayName: 'Test',
        username: 'testuser',
        createdAt: DateTime(2024, 1, 1),
        lastUsedAt: DateTime(2024, 6, 15),
        cookies: [],
      );
      final json = account.toJson();
      final restored = RedditAccount.fromJson(json);
      expect(restored.id, '123');
      expect(restored.displayName, 'Test');
      expect(restored.username, 'testuser');
      expect(restored.cookies, isEmpty);
    });

    test('handles null username', () {
      final account = RedditAccount(
        id: '456',
        displayName: 'No Username',
        createdAt: DateTime(2024, 1, 1),
        lastUsedAt: DateTime(2024, 6, 15),
        cookies: [],
      );
      final json = account.toJson();
      final restored = RedditAccount.fromJson(json);
      expect(restored.username, isNull);
    });
  });
}
