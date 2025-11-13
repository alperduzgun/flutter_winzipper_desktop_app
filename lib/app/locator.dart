import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/manager/remote/http_client.dart';
import '../core/manager/storage/hive_client.dart';
import '../core/manager/storage/secure_storage_client.dart';
import '../core/manager/storage/shared_client.dart';
import '../data/repo/cloud_repo.dart';
import '../data/service/cloud_service.dart';
import '../data/service/archive_service.dart';

/// Dependency injection setup
/// Returns list of repository providers
Future<List<RepositoryProvider<dynamic>>> locator() async {
  // Initialize storage
  final hiveBox = await Hive.openBox<dynamic>('winzipper');
  final sharedPrefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  return [
    // Storage Clients
    RepositoryProvider<HiveClient>(
      create: (context) => HiveClient(hiveBox),
    ),
    RepositoryProvider<SharedClient>(
      create: (context) => SharedClient(sharedPrefs),
    ),
    RepositoryProvider<SecureStorageClient>(
      create: (context) => const SecureStorageClient(secureStorage),
    ),

    // HTTP Client
    RepositoryProvider<HttpClient>(
      create: (context) => HttpClient(),
    ),

    // Repositories
    RepositoryProvider<ICloudRepo>(
      create: (context) => CloudRepo(),
    ),

    // Services
    RepositoryProvider<ICloudService>(
      create: (context) => CloudService(context.read<ICloudRepo>()),
    ),
    RepositoryProvider<IArchiveService>(
      create: (context) => ArchiveService(),
    ),
  ];
}
