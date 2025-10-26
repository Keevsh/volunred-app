import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/theme/theme.dart';

class ExperienciasPage extends StatefulWidget {
  const ExperienciasPage({super.key});

  @override
  State<ExperienciasPage> createState() => _ExperienciasPageState();
}

class _ExperienciasPageState extends State<ExperienciasPage> {
  final _formKey = GlobalKey<FormState>();
  final _organizacionController = TextEditingController();
  final _areaController = TextEditingController();
  final _descripcionController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _esActual = false;
  bool _isLoading = false;

  // Simulación de experiencias guardadas
  final List<Map<String, dynamic>> _experiencias = [];

  @override
  void dispose() {
    _organizacionController.dispose();
    _areaController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _selectFechaInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaInicio) {
      setState(() {
        _fechaInicio = picked;
      });
    }
  }

  Future<void> _selectFechaFin(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaFin) {
      setState(() {
        _fechaFin = picked;
      });
    }
  }

  void _handleAgregarExperiencia() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaInicio == null) {
      AppWidgets.showStyledSnackBar(
        context: context,
        message: 'Selecciona una fecha de inicio',
        isError: true,
      );
      return;
    }

    if (!_esActual && _fechaFin == null) {
      AppWidgets.showStyledSnackBar(
        context: context,
        message: 'Selecciona una fecha de fin o marca como "Actual"',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulación de llamada a API
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _experiencias.add({
        'organizacion': _organizacionController.text,
        'area': _areaController.text,
        'descripcion': _descripcionController.text,
        'fechaInicio': _fechaInicio,
        'fechaFin': _esActual ? null : _fechaFin,
        'esActual': _esActual,
      });
      _isLoading = false;
    });

    // Limpiar formulario
    _formKey.currentState!.reset();
    _organizacionController.clear();
    _areaController.clear();
    _descripcionController.clear();
    _fechaInicio = null;
    _fechaFin = null;
    _esActual = false;

    AppWidgets.showStyledSnackBar(
      context: context,
      message: '¡Experiencia agregada exitosamente!',
      isError: false,
    );
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppStyles.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormulario(),
                    if (_experiencias.isNotEmpty) ...[
                      const SizedBox(height: AppStyles.spacingXLarge),
                      _buildListaExperiencias(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyles.spacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          AppWidgets.decorativeIcon(
            icon: Icons.history_edu,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(width: AppStyles.spacingMedium),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Experiencias',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppStyles.fontSizeHeader,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Registra tu trayectoria de voluntariado',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: AppStyles.fontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Modular.to.pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agregar Nueva Experiencia',
            style: TextStyle(
              fontSize: AppStyles.fontSizeTitle,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppStyles.spacingMedium),
          AppWidgets.styledTextField(
            controller: _organizacionController,
            label: 'Organización',
            hint: 'Ej: Fundación Ayuda Social',
            prefixIcon: Icons.business_outlined,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Este campo es requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: AppStyles.spacingMedium),
          AppWidgets.styledTextField(
            controller: _areaController,
            label: 'Área (opcional)',
            hint: 'Ej: Educación, Medio Ambiente, Salud',
            prefixIcon: Icons.category_outlined,
            enabled: !_isLoading,
          ),
          const SizedBox(height: AppStyles.spacingMedium),
          TextFormField(
            controller: _descripcionController,
            maxLines: 4,
            maxLength: 500,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Descripción (opcional)',
              hintText:
                  'Describe tus responsabilidades y logros en esta experiencia...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.description_outlined),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
              ),
              filled: true,
              fillColor: AppColors.cardBackground,
            ),
          ),
          const SizedBox(height: AppStyles.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Fecha de Inicio',
                  date: _fechaInicio,
                  onTap: () => _selectFechaInicio(context),
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(width: AppStyles.spacingMedium),
              Expanded(
                child: _buildDateField(
                  label: _esActual ? 'Actual' : 'Fecha de Fin',
                  date: _esActual ? null : _fechaFin,
                  onTap: _esActual ? null : () => _selectFechaFin(context),
                  enabled: !_isLoading && !_esActual,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingMedium),
          CheckboxListTile(
            value: _esActual,
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _esActual = value ?? false;
                      if (_esActual) _fechaFin = null;
                    });
                  },
            title: const Text('Trabajo actualmente aquí'),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
            ),
            tileColor: AppColors.cardBackground,
          ),
          const SizedBox(height: AppStyles.spacingLarge),
          AppWidgets.gradientButton(
            text: 'Agregar Experiencia',
            onPressed: _handleAgregarExperiencia,
            icon: Icons.add_circle_outline,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spacingMedium),
        decoration: BoxDecoration(
          color: enabled ? AppColors.cardBackground : AppColors.borderLight,
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppStyles.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: enabled ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: AppStyles.spacingSmall),
                Text(
                  date != null ? _formatearFecha(date) : 'Seleccionar',
                  style: TextStyle(
                    fontSize: AppStyles.fontSizeBody,
                    color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaExperiencias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis Experiencias',
          style: TextStyle(
            fontSize: AppStyles.fontSizeTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _experiencias.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppStyles.spacingMedium),
          itemBuilder: (context, index) {
            final experiencia = _experiencias[index];
            return _buildExperienciaCard(experiencia, index);
          },
        ),
      ],
    );
  }

  Widget _buildExperienciaCard(Map<String, dynamic> experiencia, int index) {
    final fechaInicio = experiencia['fechaInicio'] as DateTime;
    final fechaFin = experiencia['fechaFin'] as DateTime?;
    final esActual = experiencia['esActual'] as bool;

    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingSmall),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
                ),
                child: Icon(
                  Icons.business,
                  color: AppColors.primary,
                  size: AppStyles.iconSizeMedium,
                ),
              ),
              const SizedBox(width: AppStyles.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experiencia['organizacion'],
                      style: const TextStyle(
                        fontSize: AppStyles.fontSizeBody,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (experiencia['area'].isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        experiencia['area'],
                        style: TextStyle(
                          fontSize: AppStyles.fontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatearFecha(fechaInicio)} - ${esActual ? 'Actual' : _formatearFecha(fechaFin!)}',
                          style: TextStyle(
                            fontSize: AppStyles.fontSizeSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _experiencias.removeAt(index);
                  });
                  AppWidgets.showStyledSnackBar(
                    context: context,
                    message: 'Experiencia eliminada',
                    isError: false,
                  );
                },
                icon: Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ),
          if (experiencia['descripcion'].isNotEmpty) ...[
            const SizedBox(height: AppStyles.spacingMedium),
            Text(
              experiencia['descripcion'],
              style: TextStyle(
                fontSize: AppStyles.fontSizeSmall,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
