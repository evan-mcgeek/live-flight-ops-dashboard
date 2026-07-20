import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_strings.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/settings/live_update_mode.dart';
import 'bloc/settings_bloc.dart';
import 'widgets/connection_indicator.dart';
import 'widgets/live_updates_block.dart';

String _liveIntervalDuration(int seconds) =>
    seconds < 60 ? '${seconds}s' : '${seconds ~/ 60} min';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<SettingsBloc>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  AppStrings.settingsTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 22),
                LiveUpdatesBlock(
                  appliedMode: state.liveUpdateMode,
                  appliedInterval: state.liveInterval,
                ),
                const SizedBox(height: 26),
                Text(
                  AppStrings.appearance,
                  style: AppTextStyles.sectionLabel(colors.textTertiary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: colors.panel,
                    border: Border.all(color: colors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(AppStrings.theme),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text(AppStrings.themeDark),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text(AppStrings.themeLight),
                          ),
                        ],
                        selected: {state.themeMode},
                        onSelectionChanged: (selection) => context
                            .read<SettingsBloc>()
                            .add(ThemeModeChanged(selection.first)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  AppStrings.dataSource,
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.connection,
                            style: AppTextStyles.body(colors.textSecondary),
                          ),
                          ConnectionIndicator(state: state),
                        ],
                      ),
                      Divider(color: colors.line),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.snapshotInterval,
                            style: AppTextStyles.body(colors.textSecondary),
                          ),
                          Text(
                            state.liveUpdateMode == LiveUpdateMode.standard
                                ? '${_liveIntervalDuration(state.liveInterval)} poll'
                                : AppStrings.pushLive,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
