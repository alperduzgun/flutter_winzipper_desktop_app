import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/config/api_options.dart';
import 'core/config/app_flavor.dart';

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env.staging');

  // Configure flavor
  AppFlavor(
    name: 'WinZipper [STG]',
    flavorType: FlavorType.staging,
    apiOptions: ApiOptions.staging(),
  );

  // Bootstrap and run app
  await bootstrap(() => const App());
}
