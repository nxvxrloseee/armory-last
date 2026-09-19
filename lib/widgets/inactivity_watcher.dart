import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  const InactivityWatcher({
    super.key,
    required this.timeout,
    required this.warnBefore,
    required this.enabled,
    required this.onWarn,
    required this.onTimeout,
    required this.child,
  });

  final Duration timeout;
  final Duration warnBefore;
  final bool enabled;
  final VoidCallback onWarn;
  final VoidCallback onTimeout;
  final Widget child;

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _warnTimer;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  @override
  void didUpdateWidget(covariant InactivityWatcher old) {
    super.didUpdateWidget(old);
    if (widget.enabled != old.enabled) _restart();
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _restart() {
    _warnTimer?.cancel();
    _timeoutTimer?.cancel();
    if (!widget.enabled) return;
    final warnAt = widget.timeout - widget.warnBefore;
    _warnTimer = Timer(
      warnAt.isNegative ? Duration.zero : warnAt,
      widget.onWarn,
    );
    _timeoutTimer = Timer(widget.timeout, widget.onTimeout);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _warnTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: widget.child,
    );
  }
}
