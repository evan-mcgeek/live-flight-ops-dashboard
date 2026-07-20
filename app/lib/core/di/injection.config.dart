// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flight_ops_app/core/di/register_module.dart' as _i529;
import 'package:flight_ops_app/data/remote/aircraft_remote_data_source.dart'
    as _i964;
import 'package:flight_ops_app/data/repositories/aircraft_repository_impl.dart'
    as _i523;
import 'package:flight_ops_app/data/settings/settings_repository_impl.dart'
    as _i761;
import 'package:flight_ops_app/data/signalr/aircraft_signalr_data_source.dart'
    as _i1001;
import 'package:flight_ops_app/domain/repositories/aircraft_repository.dart'
    as _i631;
import 'package:flight_ops_app/domain/repositories/settings_repository.dart'
    as _i568;
import 'package:flight_ops_app/presentation/active_region/bloc/active_region_bloc.dart'
    as _i844;
import 'package:flight_ops_app/presentation/detail/bloc/aircraft_detail_bloc.dart'
    as _i892;
import 'package:flight_ops_app/presentation/list/bloc/aircraft_list_bloc.dart'
    as _i25;
import 'package:flight_ops_app/presentation/map/bloc/map_bloc.dart' as _i290;
import 'package:flight_ops_app/presentation/settings/bloc/settings_bloc.dart'
    as _i775;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i568.SettingsRepository>(
      () => _i761.SettingsRepositoryImpl(gh<_i460.SharedPreferences>()),
    );
    gh.factory<String>(() => registerModule.hubUrl, instanceName: 'hubUrl');
    gh.lazySingleton<_i964.AircraftRemoteDataSource>(
      () => _i964.AircraftRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i1001.AircraftSignalRDataSource>(
      () =>
          _i1001.AircraftSignalRDataSource(gh<String>(instanceName: 'hubUrl')),
    );
    gh.lazySingleton<_i631.AircraftRepository>(
      () => _i523.AircraftRepositoryImpl(
        remote: gh<_i964.AircraftRemoteDataSource>(),
        signalR: gh<_i1001.AircraftSignalRDataSource>(),
        settings: gh<_i568.SettingsRepository>(),
      ),
    );
    gh.singleton<_i844.ActiveRegionBloc>(
      () => _i844.ActiveRegionBloc(gh<_i631.AircraftRepository>()),
      dispose: _i844.disposeActiveRegionBloc,
    );
    gh.singleton<_i775.SettingsBloc>(
      () => _i775.SettingsBloc(
        gh<_i568.SettingsRepository>(),
        gh<_i844.ActiveRegionBloc>(),
      ),
      dispose: _i775.disposeSettingsBloc,
    );
    gh.factoryParam<_i892.AircraftDetailBloc, String, dynamic>(
      (icao24, _) =>
          _i892.AircraftDetailBloc(gh<_i631.AircraftRepository>(), icao24),
    );
    gh.factory<_i25.AircraftListBloc>(
      () => _i25.AircraftListBloc(gh<_i844.ActiveRegionBloc>()),
    );
    gh.factory<_i290.MapBloc>(
      () => _i290.MapBloc(gh<_i844.ActiveRegionBloc>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i529.RegisterModule {}
