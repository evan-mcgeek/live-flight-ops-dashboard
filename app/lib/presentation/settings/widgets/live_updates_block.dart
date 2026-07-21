import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/settings/live_update_mode.dart';
import '../../../main.dart';
import '../bloc/settings_bloc.dart';

// Must stay in sync with AircraftRemoteDataSource.allowedLiveIntervalSeconds.
const _allowedLiveIntervalSeconds = [1, 2, 5, 10, 30, 60, 120];

String _liveIntervalDuration(int seconds) =>
    seconds < 60 ? '${seconds}s' : '${seconds ~/ 60} min';

// Mode + interval are staged locally and only applied (persist + app restart) on Save.
class LiveUpdatesBlock extends StatefulWidget {
  const LiveUpdatesBlock({
    super.key,
    required this.appliedMode,
    required this.appliedInterval,
  });

  final LiveUpdateMode appliedMode;
  final int appliedInterval;

  @override
  State<LiveUpdatesBlock> createState() => _LiveUpdatesBlockState();
}

class _LiveUpdatesBlockState extends State<LiveUpdatesBlock> {
  late LiveUpdateMode _pendingMode = widget.appliedMode;
  late int _pendingInterval = widget.appliedInterval;

  // Cleared when the bloc emits — that's the signal persistence finished.
  bool _awaitingRestart = false;

  bool get _dirty =>
      _pendingMode != widget.appliedMode ||
      _pendingInterval != widget.appliedInterval;

  void _save(BuildContext context) {
    _awaitingRestart = true;
    context
        .read<SettingsBloc>()
        .add(LiveUpdateSettingsChanged(_pendingMode, _pendingInterval));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (!_awaitingRestart) return;
        _awaitingRestart = false;
        RestartWidget.restartApp(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.liveUpdates,
            style: AppTextStyles.sectionLabel(colors.textTertiary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.panel,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<LiveUpdateMode>(
                  segments: const [
                    ButtonSegment(
                      value: LiveUpdateMode.standard,
                      label: Text(AppStrings.modeStandard),
                    ),
                    ButtonSegment(
                      value: LiveUpdateMode.realtime,
                      label: Text(AppStrings.modeRealtime),
                    ),
                  ],
                  selected: {_pendingMode},
                  onSelectionChanged: (selection) =>
                      setState(() => _pendingMode = selection.first),
                ),
                const SizedBox(height: 14),
                Text(
                  _pendingMode == LiveUpdateMode.standard
                      ? AppStrings.modeStandardDescription
                      : AppStrings.modeRealtimeDescription,
                  style: AppTextStyles.caption(colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.updateInterval,
            style: AppTextStyles.sectionLabel(colors.textTertiary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.panel,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: _allowedLiveIntervalSeconds
                      .indexOf(_pendingInterval)
                      .toDouble(),
                  min: 0,
                  max: (_allowedLiveIntervalSeconds.length - 1).toDouble(),
                  divisions: _allowedLiveIntervalSeconds.length - 1,
                  onChanged: (index) => setState(
                    () => _pendingInterval =
                        _allowedLiveIntervalSeconds[index.round()],
                  ),
                ),
                Text(
                  'Every ${_liveIntervalDuration(_pendingInterval)}',
                  style: AppTextStyles.caption(colors.textSecondary),
                ),
              ],
            ),
          ),
          if (_dirty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _save(context),
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text(AppStrings.saveAndRestart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.accentInk,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
