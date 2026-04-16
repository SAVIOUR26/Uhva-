import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Wraps any widget behind a 4-digit PIN overlay.
/// If [pinRequired] is false the child is shown directly.
class PinGate extends StatefulWidget {
  final bool pinRequired;
  final String correctPin;
  final Widget child;
  final String? lockLabel;

  const PinGate({
    super.key,
    required this.pinRequired,
    required this.correctPin,
    required this.child,
    this.lockLabel,
  });

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> {
  bool _unlocked = false;
  String _entered = '';
  bool _error = false;

  void _onDigit(String d) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += d;
      _error = false;
    });
    if (_entered.length == 4) _validate();
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _validate() {
    if (_entered == widget.correctPin) {
      HapticFeedback.lightImpact();
      setState(() => _unlocked = true);
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _error = true;
        _entered = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pinRequired || _unlocked) return widget.child;
    return _PinEntryView(
      label: widget.lockLabel ?? 'Locked Content',
      entered: _entered,
      error: _error,
      onDigit: _onDigit,
      onDelete: _onDelete,
    );
  }
}

// ── PIN Entry View ─────────────────────────────────────────────────────────

class _PinEntryView extends StatelessWidget {
  final String label;
  final String entered;
  final bool error;
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _PinEntryView({
    required this.label,
    required this.entered,
    required this.error,
    required this.onDigit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UhvaColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline,
                    size: 52, color: UhvaColors.primary),
                const SizedBox(height: 20),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: UhvaColors.onBackground),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text('Enter your 4-digit PIN',
                    style: TextStyle(
                        fontSize: 13, color: UhvaColors.onSurfaceMuted)),
                const SizedBox(height: 32),
                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < entered.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: error
                            ? Colors.redAccent
                            : filled
                                ? UhvaColors.primary
                                : UhvaColors.surface,
                        border: Border.all(
                          color: error
                              ? Colors.redAccent
                              : filled
                                  ? UhvaColors.primary
                                  : UhvaColors.divider,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
                if (error)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('Incorrect PIN. Try again.',
                        style: TextStyle(
                            color: Colors.redAccent, fontSize: 12)),
                  ),
                const SizedBox(height: 36),
                // Number pad
                _NumPad(onDigit: onDigit, onDelete: onDelete),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Numpad ─────────────────────────────────────────────────────────────────

class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _NumPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
                  if (d.isEmpty) return const SizedBox(width: 88, height: 64);
                  return _NumKey(
                    label: d,
                    onTap: () =>
                        d == '⌫' ? onDelete() : onDigit(d),
                  );
                }).toList(),
              ))
          .toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NumKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 60,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: UhvaColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: label == '⌫' ? 20 : 22,
            fontWeight: FontWeight.w500,
            color: label == '⌫'
                ? UhvaColors.onSurfaceMuted
                : UhvaColors.onBackground,
          ),
        ),
      ),
    );
  }
}

// ── Standalone PIN dialog helper ───────────────────────────────────────────

/// Shows a modal PIN entry dialog. Returns true if correct PIN entered.
Future<bool> showPinDialog(BuildContext context,
    {required String correctPin, String title = 'Enter PIN'}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PinDialog(correctPin: correctPin, title: title),
  );
  return result ?? false;
}

class _PinDialog extends StatefulWidget {
  final String correctPin;
  final String title;

  const _PinDialog({required this.correctPin, required this.title});

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  String _entered = '';
  bool _error = false;

  void _onDigit(String d) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += d;
      _error = false;
    });
    if (_entered.length == 4) _validate();
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _validate() {
    if (_entered == widget.correctPin) {
      Navigator.pop(context, true);
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _error = true;
        _entered = '';
      });
    }
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
                    color: _error
                        ? Colors.redAccent
                        : filled
                            ? UhvaColors.primary
                            : UhvaColors.surface,
                    border: Border.all(
                      color: _error
                          ? Colors.redAccent
                          : filled
                              ? UhvaColors.primary
                              : UhvaColors.divider,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            if (_error)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Wrong PIN',
                    style: TextStyle(
                        color: Colors.redAccent, fontSize: 12)),
              ),
            const SizedBox(height: 20),
            _NumPad(onDigit: _onDigit, onDelete: _onDelete),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: UhvaColors.onSurfaceMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
