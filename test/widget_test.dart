import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webbit/adblock/adblock_engine.dart';
import 'package:webbit/models/reddit_account.dart';
import 'package:webbit/screens/account_sheet.dart';

void main() {
  group('AdblockEngine', () {
    test('shouldBlock returns false for main frame content', () {
      final engine = AdblockEngine();
      expect(engine.shouldBlock('https://www.reddit.com'), false);
    });

    test('shouldBlock blocks font extensions', () {
      final engine = AdblockEngine();
      expect(engine.shouldBlock('https://fonts.gstatic.com/s/roboto/v18/KFOmCnqEu92Fr1Mu4mxP.ttf'), true);
      expect(engine.shouldBlock('https://example.com/font.woff2'), true);
      expect(engine.shouldBlock('https://example.com/font.woff'), true);
    });

    test('shouldBlock blocks hardcoded tracking domains', () {
      final engine = AdblockEngine();
      expect(engine.shouldBlock('https://pixel.redditmedia.com/track'), true);
      expect(engine.shouldBlock('https://out.reddit.com/t'), true);
    });

    test('shouldBlock allows normal sub-resources', () {
      final engine = AdblockEngine();
      expect(engine.shouldBlock('https://www.redditstatic.com/icon.png'), false);
      expect(engine.shouldBlock('https://i.redd.it/abc123.jpg'), false);
    });

    test('domain matching checks parent domains', () {
      final engine = AdblockEngine();
      expect(engine.shouldBlock('https://fonts.googleapis.com/css2'), true);
      expect(engine.shouldBlock('https://sub.fonts.googleapis.com/foo'), true);
    });
  });

  group('AccountSheet', () {
    Widget buildSheet({
      List<RedditAccount> accounts = const [],
      String? activeId,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AccountSheet(
            accounts: accounts,
            activeAccountId: activeId,
            onSwitchTo: (_) {},
            onAdd: () {},
            onDelete: (_) {},
          ),
        ),
      );
    }

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(buildSheet());
      expect(find.text('No saved accounts'), findsOneWidget);
      expect(find.text('Add Account'), findsOneWidget);
    });

    testWidgets('shows accounts list', (tester) async {
      final accounts = [
        RedditAccount(
          id: '1',
          displayName: 'Alice',
          username: 'alice',
          createdAt: DateTime(2024, 1, 1),
          lastUsedAt: DateTime(2024, 6, 15),
          cookies: [],
        ),
        RedditAccount(
          id: '2',
          displayName: 'Bob',
          username: 'bob',
          createdAt: DateTime(2024, 2, 1),
          lastUsedAt: DateTime(2024, 6, 15),
          cookies: [],
        ),
      ];
      await tester.pumpWidget(buildSheet(accounts: accounts));
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('highlights active account with checkmark', (tester) async {
      final accounts = [
        RedditAccount(
          id: '1',
          displayName: 'Alice',
          createdAt: DateTime(2024, 1, 1),
          lastUsedAt: DateTime(2024, 6, 15),
          cookies: [],
        ),
        RedditAccount(
          id: '2',
          displayName: 'Bob',
          createdAt: DateTime(2024, 2, 1),
          lastUsedAt: DateTime(2024, 6, 15),
          cookies: [],
        ),
      ];
      await tester.pumpWidget(buildSheet(accounts: accounts, activeId: '1'));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('calls onAdd when Add Account tapped', (tester) async {
      var added = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AccountSheet(
            accounts: const [],
            activeAccountId: null,
            onSwitchTo: (_) {},
            onAdd: () => added = true,
            onDelete: (_) {},
          ),
        ),
      ));
      await tester.tap(find.text('Add Account'));
      expect(added, isTrue);
    });

    testWidgets('calls onSwitchTo when account tapped', (tester) async {
      String? switchedTo;
      final accounts = [
        RedditAccount(
          id: '1',
          displayName: 'Alice',
          createdAt: DateTime(2024, 1, 1),
          lastUsedAt: DateTime(2024, 6, 15),
          cookies: [],
        ),
      ];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AccountSheet(
            accounts: accounts,
            activeAccountId: null,
            onSwitchTo: (id) => switchedTo = id,
            onAdd: () {},
            onDelete: (_) {},
          ),
        ),
      ));
      await tester.tap(find.text('Alice'));
      expect(switchedTo, '1');
    });
  });
}
