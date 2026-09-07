import 'package:flutter/material.dart';

import '../services/startup_service.dart';

class StartupToggle extends StatefulWidget {
  const StartupToggle({super.key});

  @override
  State<StartupToggle> createState() => _StartupToggleState();
}

class _StartupToggleState extends State<StartupToggle> {
  bool _runOnStartup = false;

  @override
  void initState() {
    super.initState();
    _checkStartupStatus();
  }

  Future<void> _checkStartupStatus() async {
    final isEnabled = await StartupService.isEnabled();
    if (mounted) {
      setState(() => _runOnStartup = isEnabled);
    }
  }

  Future<void> _handleStartupToggle(bool enable) async {
    await StartupService.toggleStartup(enable);
    if (mounted) {
      setState(() => _runOnStartup = enable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: .min,
      mainAxisAlignment: .center,
      children: [
        const Text('Launch on Startup'),
        const SizedBox(width: 8),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: _runOnStartup,
            onChanged: _handleStartupToggle,
            activeThumbColor: colorScheme.primary,
            materialTapTargetSize: .shrinkWrap,
          ),
        ),
      ],
    );
  }
}
