import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppErrorBoundary extends ConsumerWidget {
  final Widget child;

  const AppErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Overlay(
      initialEntries: [
        OverlayEntry(builder: (context) => ErrorBoundaryWidget(child: child)),
      ],
    );
  }
}

class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;

  const ErrorBoundaryWidget({super.key, required this.child});

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorOverlay(error: _error!, stackTrace: _stackTrace);
    }
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
    };
  }

  @override
  void dispose() {
    FlutterError.onError = FlutterError.presentError;
    super.dispose();
  }
}

class ErrorOverlay extends StatefulWidget {
  final Object error;
  final StackTrace? stackTrace;

  const ErrorOverlay({super.key, required this.error, this.stackTrace});

  @override
  State<ErrorOverlay> createState() => _ErrorOverlayState();
}

class _ErrorOverlayState extends State<ErrorOverlay> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  SystemNavigator.pop();
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
