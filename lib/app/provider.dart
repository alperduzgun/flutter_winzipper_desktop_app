import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC Providers registry
/// Returns list of BLoC providers for the app
///
/// Note: CloudUploadCubit is created on-demand in CloudUploadDialog
/// to avoid keeping it in memory when not needed
List<BlocProvider> provider() {
  return [];
}
