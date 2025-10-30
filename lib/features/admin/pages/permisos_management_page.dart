import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';

class PermisosManagementPage extends StatelessWidget {
  const PermisosManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Gestión de Permisos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.spacingXLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 80,
                color: Colors.orange.withOpacity(0.3),
              ),
              const SizedBox(height: AppStyles.spacingLarge),
              const Text(
                'Gestión de Permisos',
                style: TextStyle(
                  fontSize: AppStyles.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              Text(
                'Página en construcción',
                style: TextStyle(
                  fontSize: AppStyles.fontSizeBody,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppStyles.spacingSmall),
              Text(
                'Aquí podrás asignar permisos a roles',
                style: TextStyle(
                  fontSize: AppStyles.fontSizeMedium,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
