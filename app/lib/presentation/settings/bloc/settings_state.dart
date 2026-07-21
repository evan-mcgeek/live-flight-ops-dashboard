part of 'settings_bloc.dart';

// The OpenSky connection health shown in Settings' "Connection" row — kept as its
// own sealed type since it's orthogonal to the always-present settings values below.
sealed class ConnectionStatus extends Equatable {
  const ConnectionStatus();

  @override
  List<Object?> get props => [];
}

class ConnectionConnecting extends ConnectionStatus {
  const ConnectionConnecting();
}

class ConnectionConnected extends ConnectionStatus {
  const ConnectionConnected();
}

class ConnectionError extends ConnectionStatus {
  const ConnectionError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class SettingsState extends Equatable {
  const SettingsState({
    required this.liveUpdateMode,
    required this.themeMode,
    required this.liveInterval,
    this.connectionStatus = const ConnectionConnecting(),
  });

  final LiveUpdateMode liveUpdateMode;
  final AppThemeMode themeMode;
  final int liveInterval;
  final ConnectionStatus connectionStatus;

  SettingsState copyWith({
    LiveUpdateMode? liveUpdateMode,
    AppThemeMode? themeMode,
    int? liveInterval,
    ConnectionStatus? connectionStatus,
  }) {
    return SettingsState(
      liveUpdateMode: liveUpdateMode ?? this.liveUpdateMode,
      themeMode: themeMode ?? this.themeMode,
      liveInterval: liveInterval ?? this.liveInterval,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }

  @override
  List<Object?> get props => [
    liveUpdateMode,
    themeMode,
    liveInterval,
    connectionStatus,
  ];
}
