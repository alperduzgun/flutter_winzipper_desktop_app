import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/config/api_options.dart';
import 'core/config/app_flavor.dart';

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env.production');

  // Configure flavor
  AppFlavor(
    name: 'WinZipper',
    flavorType: FlavorType.production,
    apiOptions: ApiOptions.production(),
  );

  // Bootstrap and run app
  await bootstrap(() => const App());
}
