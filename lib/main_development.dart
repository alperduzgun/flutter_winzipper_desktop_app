import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/config/api_options.dart';
import 'core/config/app_flavor.dart';

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env.development');

  // Configure flavor
  AppFlavor(
    name: 'WinZipper [DEV]',
    flavorType: FlavorType.development,
    apiOptions: ApiOptions.development(),
  );

  // Bootstrap and run app
  await bootstrap(() => const App());
}
