// lib/screens/lock_screen.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/note_model.dart';

/// Full-screen PIN pad for locking / unlocking notes.
/// Pass [isSettingPin: true] when first locking a note (two-step confirm).
/// Pass [isSettingPin: false] (default) to verify an existing PIN.
/// [onUnlocked] receives the new hash when setting, or null when verifying.
class LockScreen extends StatefulWidget {
  final NoteModel note;
  final ValueChanged<String?> onUnlocked;
  final bool isSettingPin;

  const LockScreen({
    super.key,
    required this.note,
    required this.onUnlocked,
    this.isSettingPin = false,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final List<int> _digits = [];
  String? _firstPin;
  bool _isConfirming = false;
  bool _error = false;

  late AnimationController _shakeCtrl;

  static const int _len = 4;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String _hash(String pin) =>
      sha256.convert(utf8.encode(pin)).toString();

  void _tap(int d) {
    if (_digits.length >= _len) return;
    HapticFeedback.lightImpact();
    setState(() { _digits.add(d); _error = false; });
    if (_digits.length == _len) _process();
  }

  void _del() {
    if (_digits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _digits.removeLast());
  }

  Future<void> _process() async {
    final pin = _digits.join();
    await Future.delayed(const Duration(milliseconds: 80));

    if (widget.isSettingPin) {
      if (!_isConfirming) {
        setState(() { _firstPin = pin; _digits.clear(); _isConfirming = true; });
      } else {
        if (pin == _firstPin) {
          widget.onUnlocked(_hash(pin));
        } else {
          _fail();
        }
      }
    } else {
      if (_hash(pin) == widget.note.lockHash) {
        widget.onUnlocked(null);
      } else {
        _fail();
      }
    }
  }

  void _fail() {
    HapticFeedback.heavyImpact();
    setState(() { _error = true; _digits.clear(); _isConfirming = false; });
    _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reset());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final headline = widget.isSettingPin
        ? (_isConfirming ? 'Confirm PIN' : 'Set a PIN')
        : 'Enter PIN';
    final sub = _error
        ? (_isConfirming ? 'PINs don\'t match' : 'Incorrect PIN')
        : (widget.isSettingPin && !_isConfirming
            ? 'Choose a 4-digit PIN'
            : widget.isSettingPin
                ? 'Re-enter your PIN'
                : 'Enter your PIN to unlock');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Icon
            Icon(Icons.lock_rounded, size: 48, color: t.colorScheme.primary)
                .animate()
                .scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),

            // Headline
            Text(headline, style: t.textTheme.headlineSmall)
                .animate()
                .fadeIn(delay: 100.ms),
            const SizedBox(height: 8),

            // Subtitle / error
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                sub,
                key: ValueKey(sub),
                style: t.textTheme.bodySmall?.copyWith(
                  color: _error
                      ? t.colorScheme.error
                      : t.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeCtrl,
              builder: (_, child) {
                final v = _shakeCtrl.value;
                final x = _error
                    ? 14.0 * (v < 0.5 ? v * 2 : (1 - v) * 2) * (v < 0.25 || (v > 0.5 && v < 0.75) ? 1 : -1)
                    : 0.0;
                return Transform.translate(offset: Offset(x, 0), child: child);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_len, (i) {
                  final filled = i < _digits.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? (_error ? t.colorScheme.error : t.colorScheme.primary)
                          : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? (_error ? t.colorScheme.error : t.colorScheme.primary)
                            : t.colorScheme.onSurface.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(),

            // Dial pad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Column(
                children: [
                  for (final row in [[1,2,3],[4,5,6],[7,8,9]])
                    _DialRow(digits: row, onTap: _tap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 72, height: 72),
                      _DialKey(digit: 0, onTap: () => _tap(0)),
                      SizedBox(
                        width: 72, height: 72,
                        child: IconButton(
                          onPressed: _del,
                          icon: Icon(Icons.backspace_outlined,
                            color: t.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DialRow extends StatelessWidget {
  final List<int> digits;
  final ValueChanged<int> onTap;
  const _DialRow({required this.digits, required this.onTap});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: digits.map((d) => _DialKey(digit: d, onTap: () => onTap(d))).toList(),
  );
}

class _DialKey extends StatefulWidget {
  final int digit;
  final VoidCallback onTap;
  const _DialKey({required this.digit, required this.onTap});

  @override
  State<_DialKey> createState() => _DialKeyState();
}

class _DialKeyState extends State<_DialKey> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this, duration: 80.ms, reverseDuration: 200.ms,
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.88)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 72, height: 72,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.colorScheme.surfaceVariant.withOpacity(0.5),
          ),
          alignment: Alignment.center,
          child: Text('${widget.digit}',
              style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
