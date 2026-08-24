import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const _OfflineOverlay(),
      ],
    );
  }
}

class _OfflineOverlay extends StatelessWidget {
  const _OfflineOverlay();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityWrapper.of(context).isOnlineStream,
      initialData: true,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        if (isOnline) return const SizedBox.shrink();

        return Container(
          color: Colors.black87,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white.withValues(alpha: 0.9), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are offline. Some features may be limited.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ConnectivityWrapper extends InheritedWidget {
  final Stream<bool> isOnlineStream;
  final bool isOnline;

  const ConnectivityWrapper({
    super.key,
    required this.isOnlineStream,
    required this.isOnline,
    required super.child,
  });

  static ConnectivityWrapper of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ConnectivityWrapper>()!;
  }

  @override
  bool updateShouldNotify(ConnectivityWrapper old) {
    return isOnline != old.isOnline;
  }
}
