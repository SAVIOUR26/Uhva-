import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/uhva_logo.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Account
          _Section(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user?.username ?? '—'),
            subtitle: const Text('Username'),
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(user?.serverUrl ?? '—',
                overflow: TextOverflow.ellipsis),
            subtitle: const Text('Server'),
          ),
          if (user?.expiryDate != null)
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_formatExpiry(user!.expiryDate!)),
              subtitle: const Text('Subscription expiry'),
            ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out', style: TextStyle(color: Colors.red)),
            onTap: () {
              provider.logout();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),

          const Divider(),
          _Section(title: 'Playback'),
          ListTile(
            leading: const Icon(Icons.hd_outlined),
            title: const Text('Stream quality'),
            subtitle: const Text('Auto (recommended)'),
            trailing: const Icon(Icons.chevron_right,
                color: UhvaColors.onSurfaceHint),
          ),
          ListTile(
            leading: const Icon(Icons.buffer),
            title: const Text('Buffer size'),
            subtitle: const Text('Medium (10s)'),
            trailing: const Icon(Icons.chevron_right,
                color: UhvaColors.onSurfaceHint),
          ),

          const Divider(),
          _Section(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('UHVA Player'),
            subtitle: Text('Version 1.0.0'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: UhvaLogo(size: 36)),
          ),
        ],
      ),
    );
  }

  String _formatExpiry(String ts) {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(ts) * 1000);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return ts;
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: UhvaColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
