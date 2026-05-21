import 'package:flutter/material.dart';
import '../models/reddit_account.dart';

class AccountSheet extends StatelessWidget {
  final List<RedditAccount> accounts;
  final String? activeAccountId;
  final ValueChanged<String> onSwitchTo;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  const AccountSheet({
    super.key,
    required this.accounts,
    this.activeAccountId,
    required this.onSwitchTo,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Switch Account',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No saved accounts'),
            )
          else
            ...accounts.map((a) => _buildAccountTile(context, a)),
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.add)),
            title: const Text('Add Account'),
            onTap: onAdd,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, RedditAccount account) {
    final isActive = account.id == activeAccountId;
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          (account.displayName.isNotEmpty
                  ? account.displayName
                  : '?')
              .substring(0, 1)
              .toUpperCase(),
        ),
      ),
      title: Text(account.displayName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            const Icon(Icons.check, color: Colors.green, size: 20),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => _confirmDelete(context, account),
          ),
        ],
      ),
      onTap: isActive ? null : () => onSwitchTo(account.id),
    );
  }

  void _confirmDelete(BuildContext context, RedditAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Account'),
        content: Text('Remove "${account.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete(account.id);
            },
            child:
                const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
