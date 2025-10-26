import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_widgets.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'image': '🤝',
      'title': 'Conecta con Causas',
      'subtitle': 'Encuentra oportunidades de voluntariado que se alineen con tus intereses',
    },
    {
      'image': '🌍',
      'title': 'Haz la Diferencia',
      'subtitle': 'Únete a proyectos que transforman comunidades y el medio ambiente',
    },
    {
      'image': '👥',
      'title': 'Crece y Aprende',
      'subtitle': 'Desarrolla nuevas habilidades mientras ayudas a otros',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Carrusel de imágenes/contenido
                  SizedBox(
                    height: size.height * 0.4,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        return _buildSlide(_slides[index], size);
                      },
                    ),
                  ),

                  // Indicadores de página
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? colorScheme.primary
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Descripción principal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Text(
                          'VolunRed',
                          style: TextStyle(
                            fontSize: AppStyles.fontSizeHeader,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: AppStyles.spacingMedium),
                        Text(
                          'Una plataforma creada para fortalecer el voluntariado en Bolivia. Descubre proyectos, organiza tus actividades y trabaja en equipo por un futuro más solidario.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppStyles.fontSizeNormal,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Botones de acción
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Botón Login
                        SizedBox(
                          width: double.infinity,
                          height: AppStyles.buttonHeightLarge,
                          child: ElevatedButton(
                            onPressed: () {
                              Modular.to.navigate('/auth/');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppStyles.borderRadiusMediumAll,
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: AppStyles.fontSizeBody,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: AppStyles.spacingSmall),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(AppStyles.opacityMedium),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    size: AppStyles.iconSizeSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppStyles.spacingMedium),

                        // Botón Registrarse
                        SizedBox(
                          width: double.infinity,
                          height: AppStyles.buttonHeightLarge,
                          child: OutlinedButton(
                            onPressed: () {
                              Modular.to.navigate('/auth/register');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppStyles.borderRadiusMediumAll,
                              ),
                            ),
                            child: const Text(
                              'Registrarse',
                              style: TextStyle(
                                fontSize: AppStyles.fontSizeBody,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(Map<String, String> slide, Size size) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Contenedor de imagen con diseño tipo collage
          Container(
            height: size.height * 0.35,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: AppStyles.borderRadiusLargeAll,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.cardGradientLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(AppStyles.opacityLight),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Emoji grande centrado
                Center(
                  child: Text(
                    slide['image']!,
                    style: const TextStyle(
                      fontSize: 120,
                    ),
                  ),
                ),
                // Decoraciones
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(AppStyles.opacityHigh),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(AppStyles.opacityLight),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: AppColors.iconRed,
                      size: AppStyles.iconSizeMedium,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(AppStyles.opacityHigh),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(AppStyles.opacityLight),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      color: AppColors.iconAmber,
                      size: AppStyles.iconSizeMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Título del slide
          Text(
            slide['title']!,
            style: const TextStyle(
              fontSize: AppStyles.fontSizeTitle,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppStyles.spacingMedium),

          // Subtítulo
          Text(
            slide['subtitle']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppStyles.fontSizeNormal,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
