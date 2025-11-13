import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/cloud_upload_cubit.dart';
import '../data/service/cloud_service.dart';

/// BLoC Providers registry
/// Returns list of BLoC providers for the app
List<BlocProvider> provider() {
  return [
    BlocProvider<CloudUploadCubit>(
      create: (context) => CloudUploadCubit(context.read<ICloudService>()),
      lazy: false,
    ),
  ];
}
