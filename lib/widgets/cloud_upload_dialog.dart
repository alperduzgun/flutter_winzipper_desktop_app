library cloud_upload_dialog;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../cubits/cloud_upload_cubit.dart';
import '../services/cloud_upload_service.dart';

part 'cloud_upload_dialog_content.dart';
part 'cloud_upload_dialog_success.dart';
part 'cloud_upload_dialog_progress.dart';

/// Main dialog for cloud upload functionality
class CloudUploadDialog extends StatelessWidget {
  final String filePath;

  const CloudUploadDialog({
    Key? key,
    required this.filePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CloudUploadCubit(CloudUploadService())
        ..uploadFile(filePath),
      child: BlocBuilder<CloudUploadCubit, CloudUploadState>(
        builder: (context, state) {
          // Allow dismissal only in final states (success/failure)
          final canDismiss = state is CloudUploadSuccess ||
              state is CloudUploadFailure;

          return WillPopScope(
            onWillPop: () async => canDismiss,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const _CloudUploadDialogContent(),
            ),
          );
        },
      ),
    );
  }

  /// Show upload dialog
  static Future<void> show(BuildContext context, String filePath) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CloudUploadDialog(filePath: filePath),
    );
  }
}
