import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
import '../state/auth_notifier.dart';

class InactivityWatcher extends StatefulWidget {
  final AuthNotifier auth;
  final Widget child;
  final Duration timeout;
  final Duration warning;

  const InactivityWatcher({
    super.key,
    required this.auth,
    required this.child,
    this.timeout = inactivityTimeout,
    this.warning = inactivityWarning,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _ticker;
  DateTime _lastActivity = DateTime.now();
  int? _secondsLeft;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _ticker?.cancel();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    _activity();
    return false;
  }

  void _activity() {
    _lastActivity = DateTime.now();
    if (widget.auth.isAuthenticated) widget.auth.touchActivity();
    if (_secondsLeft != null) setState(() => _secondsLeft = null);
  }

  void _tick() {
    final auth = widget.auth;
    if (!auth.isAuthenticated) {
      _lastActivity = DateTime.now();
      if (_secondsLeft != null) setState(() => _secondsLeft = null);
      return;
    }
    final now = DateTime.now();
    final started = auth.loginAt;
    if (started != null && now.difference(started) > sessionMaxDuration) {
      auth.logout(reason: 'Время сеанса истекло, войдите снова.');
      return;
    }
    final idle = now.difference(_lastActivity);
    if (idle >= widget.timeout) {
      auth.logout(reason: 'Сеанс завершён из-за отсутствия активности.');
      return;
    }
    final left = widget.timeout - idle;
    final next = left <= widget.warning ? left.inSeconds + 1 : null;
    if (next != _secondsLeft) setState(() => _secondsLeft = next);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _activity(),
      onPointerMove: (_) => _activity(),
      onPointerSignal: (_) => _activity(),
      child: Stack(
        children: [
          widget.child,
          if (_secondsLeft != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 96,
              child: Center(
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Нет активности. Сеанс завершится через $_secondsLeft с',
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _activity,
                          child: const Text('Продолжить'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
