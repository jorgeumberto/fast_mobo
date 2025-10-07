// lib/src/injection_container.dart

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Features - Auth
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/check_auth_status.dart';
import 'features/auth/domain/usecases/do_login.dart';
import 'features/auth/domain/usecases/do_logout.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Features - Settings
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/repositories/settings_repository.dart';

// A instância do Service Locator
final sl = GetIt.instance;

Future<void> init() async {
  // =================================================================
  // Features
  // =================================================================

  // --- Auth Feature ---
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      doLogin: sl(),
      doLogout: sl(),
      checkAuthStatus: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => DoLogin(sl()));
  sl.registerLazySingleton(() => DoLogout(sl()));
  sl.registerLazySingleton(() => CheckAuthStatus(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(), // Adicionamos a dependência remota
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl(), settingsRepository: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );


  // --- Settings Feature ---
  // Repository
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sharedPreferences: sl()),
  );


  // =================================================================
  // External (Dependências de pacotes, etc.)
  // =================================================================
  
  sl.registerLazySingleton(() => http.Client());
  
  // Garante que SharedPreferences seja registrado apenas uma vez.
  if (!sl.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton(() => sharedPreferences);
  }
}