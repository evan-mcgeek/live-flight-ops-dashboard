import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  @Named(hubUrlToken)
  String get hubUrl => ApiConfig.hubUrl;

  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
