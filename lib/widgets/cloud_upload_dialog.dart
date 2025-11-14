library cloud_upload_dialog;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../cubits/cloud_upload_cubit.dart';
import '../cubits/cloud_upload_state.dart';
import '../data/service/cloud_service.dart';

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
      create: (context) => CloudUploadCubit(context.read<ICloudService>())
        ..uploadFile(filePath),
      child: BlocBuilder<CloudUploadCubit, CloudUploadState>(
        builder: (context, state) {
          // Allow dismissal only in final states (success/failure)
          final canDismiss = state is CloudUploadSuccess ||
              state is CloudUploadFailure;

          return WillPopScope(
            onWillPop: () async => canDismiss,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: const _CloudUploadDialogContent(),
                  ),
                ),
              ),
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
