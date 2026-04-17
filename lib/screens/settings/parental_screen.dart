import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/pin_gate.dart';

class ParentalScreen extends StatefulWidget {
  const ParentalScreen({super.key});

  @override
  State<ParentalScreen> createState() => _ParentalScreenState();
}

class _ParentalScreenState extends State<ParentalScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final hasPin = provider.hasPin;
    final lockedCats = provider.lockedCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('Parental Controls')),
      body: ListView(
        children: [
          // ── PIN section ────────────────────────────────────────────────
          _Section(title: 'PIN Protection'),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('Enable Parental Lock'),
            subtitle: Text(hasPin
                ? 'PIN is set — tap to change or disable'
                : 'Set a 4-digit PIN to protect content'),
            value: hasPin,
            activeThumbColor: UhvaColors.primary,
            onChanged: (v) async {
              if (v) {
                await _setNewPin(context, provider);
              } else {
                final ok = await showPinDialog(context,
                    correctPin: provider.pin!,
                    title: 'Enter current PIN to disable');
                if (ok && context.mounted) {
                  await provider.clearPin();
                }
              }
            },
          ),
          if (hasPin) ...[
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: const Text('Change PIN'),
              trailing: const Icon(Icons.chevron_right,
                  color: UhvaColors.onSurfaceHint),
              onTap: () async {
                final ok = await showPinDialog(context,
                    correctPin: provider.pin!,
                    title: 'Enter current PIN');
                if (ok && context.mounted) {
                  await _setNewPin(context, provider);
                }
              },
            ),
          ],

          const Divider(),

          // ── Locked categories ──────────────────────────────────────────
          if (hasPin) ...[
            _Section(title: 'Locked Categories'),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Selected categories will require PIN to access.',
                style:
                    TextStyle(fontSize: 12, color: UhvaColors.onSurfaceMuted),
              ),
            ),
            if (provider.liveCategories.isEmpty)
              const ListTile(
                title: Text('No categories loaded',
                    style: TextStyle(color: UhvaColors.onSurfaceMuted)),
              )
            else
              ...provider.liveCategories.map((cat) {
                final locked = lockedCats.contains(cat.categoryId);
                return CheckboxListTile(
                  title: Text(cat.categoryName,
                      style:
                          const TextStyle(color: UhvaColors.onBackground)),
                  value: locked,
                  activeThumbColor: UhvaColors.primary,
                  secondary: Icon(
                    locked ? Icons.lock : Icons.lock_open_outlined,
                    color: locked
                        ? UhvaColors.primary
                        : UhvaColors.onSurfaceMuted,
                    size: 20,
                  ),
                  onChanged: (_) async {
                    final newSet = Set<String>.from(lockedCats);
                    if (locked) {
                      newSet.remove(cat.categoryId);
                    } else {
                      newSet.add(cat.categoryId);
                    }
                    await provider.setLockedCategories(newSet);
                  },
                );
              }),
          ] else
            const ListTile(
              leading: Icon(Icons.info_outline, color: UhvaColors.onSurfaceMuted),
              title: Text('Enable a PIN first to lock categories',
                  style: TextStyle(
                      color: UhvaColors.onSurfaceMuted, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Future<void> _setNewPin(BuildContext context, AppProvider provider) async {
    final pin1 = await _enterNewPin(context, 'Set new PIN');
    if (pin1 == null || !context.mounted) return;
    final pin2 = await _enterNewPin(context, 'Confirm PIN');
    if (pin2 == null || !context.mounted) return;
    if (pin1 != pin2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match. Try again.')),
      );
      return;
    }
    await provider.setPin(pin1);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN saved successfully.')),
      );
    }
  }

  Future<String?> _enterNewPin(BuildContext context, String title) async {
    return showDialog<String>(
      context: context,
      builder: (_) => _NewPinDialog(title: title),
    );
  }
}

// ── New PIN Entry Dialog ───────────────────────────────────────────────────

class _NewPinDialog extends StatefulWidget {
  final String title;
  const _NewPinDialog({required this.title});

  @override
  State<_NewPinDialog> createState() => _NewPinDialogState();
}

class _NewPinDialogState extends State<_NewPinDialog> {
  String _entered = '';

  void _onDigit(String d) {
    if (_entered.length >= 4) return;
    setState(() => _entered += d);
    if (_entered.length == 4) {
      Navigator.pop(context, _entered);
    }
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: UhvaColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: UhvaColors.onBackground)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _entered.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? UhvaColors.primary : UhvaColors.surface,
                    border: Border.all(
                      color: filled ? UhvaColors.primary : UhvaColors.divider,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            _buildNumPad(),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: UhvaColors.onSurfaceMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumPad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: rows
          .map((row) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((d) {
                  if (d.isEmpty) return const SizedBox(width: 80, height: 56);
                  return GestureDetector(
                    onTap: () => d == '⌫' ? _onDelete() : _onDigit(d),
                    child: Container(
                      width: 72,
                      height: 52,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: UhvaColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(d,
                          style: TextStyle(
                            fontSize: d == '⌫' ? 18 : 20,
                            fontWeight: FontWeight.w500,
                            color: d == '⌫'
                                ? UhvaColors.onSurfaceMuted
                                : UhvaColors.onBackground,
                          )),
                    ),
                  );
                }).toList(),
              ))
          .toList(),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: UhvaColors.primary,
              letterSpacing: 1.2)),
    );
  }
}
