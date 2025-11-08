import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

/// Componentes de UI estilo Red Social Moderna
/// Diseño inspirado en Instagram, Twitter, Facebook
class SocialComponents {
  // ==================== AVATARES ====================
  
  /// Avatar con gradiente (estilo Instagram Stories)
  static Widget gradientAvatar({
    required String? name,
    String? imageUrl,
    double size = 56,
    List<Color>? gradient,
    bool hasStory = false,
    VoidCallback? onTap,
  }) {
    final colors = gradient ?? AppColors.getAvatarGradientByName(name ?? 'user');
    final initials = _getInitials(name);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasStory 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                )
              : null,
          color: hasStory ? null : AppColors.border,
          boxShadow: hasStory ? [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        padding: EdgeInsets.all(hasStory ? 3 : 0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: size * 0.35,
                      fontWeight: AppStyles.fontWeightBold,
                      color: hasStory ? colors[0] : AppColors.textSecondary,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
  
  /// Avatar simple circular
  static Widget circleAvatar({
    required String? name,
    String? imageUrl,
    double size = 40,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    final initials = _getInitials(name);
    
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: backgroundColor ?? AppColors.primary.withOpacity(0.1),
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
        child: imageUrl == null
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: size * 0.35,
                  fontWeight: AppStyles.fontWeightSemiBold,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
    );
  }
  
  // ==================== SECCIÓN DE STORIES ====================
  
  /// Sección de stories horizontal (estilo Instagram)
  static Widget storiesSection({
    required List<Map<String, dynamic>> stories,
    double height = 100,
    VoidCallback? onAddStory,
  }) {
    final itemCount = stories.length + (onAddStory != null ? 1 : 0);
    
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingMedium),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Primer item: botón para agregar historia
          if (onAddStory != null && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: AppStyles.spacingMedium),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: onAddStory,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.border,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.textSecondary,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacingXSmall),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'Tu historia',
                      style: AppStyles.textCaption,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Stories normales
          final storyIndex = onAddStory != null ? index - 1 : index;
          final story = stories[storyIndex];
          return Padding(
            padding: const EdgeInsets.only(right: AppStyles.spacingMedium),
            child: Column(
              children: [
                gradientAvatar(
                  name: story['name'],
                  imageUrl: story['avatar'],
                  size: 64,
                  hasStory: story['hasStory'] ?? false,
                  onTap: story['onTap'],
                ),
                const SizedBox(height: AppStyles.spacingXSmall),
                SizedBox(
                  width: 70,
                  child: Text(
                    story['name'] ?? '',
                    style: AppStyles.textCaption,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // ==================== POSTS / CARDS ====================
  
  /// Post card completo estilo Instagram
  static Widget postCard({
    required String userName,
    String? userAvatar,
    String? timeAgo,
    String? location,
    String? description,
    String? imageUrl,
    Widget? customContent,
    int likesCount = 0,
    int commentsCount = 0,
    bool isLiked = false,
    bool isSaved = false,
    VoidCallback? onLike,
    VoidCallback? onComment,
    VoidCallback? onShare,
    VoidCallback? onSave,
    VoidCallback? onUserTap,
    VoidCallback? onPostTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingMedium),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del post
          postHeader(
            userName: userName,
            userAvatar: userAvatar,
            timeAgo: timeAgo,
            location: location,
            onUserTap: onUserTap,
          ),
          
          // Contenido (imagen o custom)
          if (imageUrl != null)
            GestureDetector(
              onTap: onPostTap,
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 400,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 400,
                    color: AppColors.backgroundAlt,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 64, color: AppColors.textSecondary),
                    ),
                  );
                },
              ),
            )
          else if (customContent != null)
            GestureDetector(
              onTap: onPostTap,
              child: customContent,
            ),
          
          // Barra de interacciones
          interactionBar(
            likesCount: likesCount,
            commentsCount: commentsCount,
            isLiked: isLiked,
            isSaved: isSaved,
            onLike: onLike,
            onComment: onComment,
            onShare: onShare,
            onSave: onSave,
          ),
          
          // Descripción
          if (description != null && description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppStyles.spacingNormal,
                AppStyles.spacingXSmall,
                AppStyles.spacingNormal,
                AppStyles.spacingMedium,
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$userName ',
                      style: AppStyles.textBodyBold,
                    ),
                    TextSpan(
                      text: description,
                      style: AppStyles.textBody,
                    ),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
  
  /// Header de post (usuario + ubicación + menú)
  static Widget postHeader({
    required String userName,
    String? userAvatar,
    String? timeAgo,
    String? location,
    VoidCallback? onUserTap,
    VoidCallback? onMenuTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppStyles.spacingMedium),
      child: Row(
        children: [
          GestureDetector(
            onTap: onUserTap,
            child: circleAvatar(
              name: userName,
              imageUrl: userAvatar,
              size: 40,
            ),
          ),
          const SizedBox(width: AppStyles.spacingMedium),
          Expanded(
            child: GestureDetector(
              onTap: onUserTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: AppStyles.textBodyBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location != null || timeAgo != null)
                    Text(
                      [location, timeAgo].where((e) => e != null).join(' • '),
                      style: AppStyles.textCaption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            iconSize: AppStyles.iconSizeMedium,
            color: AppColors.iconSecondary,
            onPressed: onMenuTap,
          ),
        ],
      ),
    );
  }
  
  /// Barra de interacciones (like, comment, share, save)
  static Widget interactionBar({
    int likesCount = 0,
    int commentsCount = 0,
    bool isLiked = false,
    bool isSaved = false,
    VoidCallback? onLike,
    VoidCallback? onComment,
    VoidCallback? onShare,
    VoidCallback? onSave,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingSmall,
        vertical: AppStyles.spacingXSmall,
      ),
      child: Row(
        children: [
          // Like
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? AppColors.like : AppColors.iconPrimary,
            ),
            iconSize: AppStyles.iconSizeLarge,
            onPressed: onLike,
            padding: const EdgeInsets.all(AppStyles.spacingSmall),
            constraints: const BoxConstraints(),
          ),
          if (likesCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: AppStyles.spacingXSmall),
              child: Text(
                _formatCount(likesCount),
                style: AppStyles.textSecondary,
              ),
            ),
          const SizedBox(width: AppStyles.spacingMedium),
          
          // Comment
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            color: AppColors.iconPrimary,
            iconSize: AppStyles.iconSizeLarge,
            onPressed: onComment,
            padding: const EdgeInsets.all(AppStyles.spacingSmall),
            constraints: const BoxConstraints(),
          ),
          if (commentsCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: AppStyles.spacingXSmall),
              child: Text(
                _formatCount(commentsCount),
                style: AppStyles.textSecondary,
              ),
            ),
          const SizedBox(width: AppStyles.spacingMedium),
          
          // Share
          IconButton(
            icon: const Icon(Icons.send_outlined),
            color: AppColors.iconPrimary,
            iconSize: AppStyles.iconSizeLarge,
            onPressed: onShare,
            padding: const EdgeInsets.all(AppStyles.spacingSmall),
            constraints: const BoxConstraints(),
          ),
          
          const Spacer(),
          
          // Save
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? AppColors.primary : AppColors.iconPrimary,
            ),
            iconSize: AppStyles.iconSizeLarge,
            onPressed: onSave,
            padding: const EdgeInsets.all(AppStyles.spacingSmall),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
  
  /// Post card de proyecto (diseñado para proyectos de voluntariado)
  static Widget projectPostCard({
    required String projectName,
    required String organizationName,
    String? organizationAvatar,
    String? imageUrl,
    String? description,
    String? location,
    String? date,
    int volunteersCount = 0,
    List<String>? tags,
    VoidCallback? onTap,
    VoidCallback? onLike,
    VoidCallback? onApply,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppStyles.spacingMedium),
        decoration: AppStyles.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con organización
            postHeader(
              userName: organizationName,
              userAvatar: organizationAvatar,
              onUserTap: onTap,
            ),
            
            // Imagen del proyecto
            if (imageUrl != null)
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: AppStyles.primaryGradient,
                    ),
                    child: const Center(
                      child: Icon(Icons.volunteer_activism, size: 80, color: Colors.white),
                    ),
                  );
                },
              )
            else
              Container(
                height: 250,
                decoration: BoxDecoration(
                  gradient: AppStyles.primaryGradient,
                ),
                child: const Center(
                  child: Icon(Icons.volunteer_activism, size: 80, color: Colors.white),
                ),
              ),
            
            // Información del proyecto
            Padding(
              padding: const EdgeInsets.all(AppStyles.spacingNormal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del proyecto
                  Text(
                    projectName,
                    style: AppStyles.textSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppStyles.spacingSmall),
                  
                  // Descripción
                  if (description != null && description.isNotEmpty)
                    Text(
                      description,
                      style: AppStyles.textBody,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: AppStyles.spacingMedium),
                  
                  // Detalles (ubicación, fecha, voluntarios)
                  Wrap(
                    spacing: AppStyles.spacingMedium,
                    runSpacing: AppStyles.spacingSmall,
                    children: [
                      if (location != null)
                        _buildInfoChip(Icons.location_on, location),
                      if (date != null)
                        _buildInfoChip(Icons.calendar_today, date),
                      if (volunteersCount > 0)
                        _buildInfoChip(Icons.people, '$volunteersCount voluntarios'),
                    ],
                  ),
                  
                  // Tags
                  if (tags != null && tags.isNotEmpty) ...[
                    const SizedBox(height: AppStyles.spacingMedium),
                    Wrap(
                      spacing: AppStyles.spacingSmall,
                      runSpacing: AppStyles.spacingSmall,
                      children: tags.map((tag) => _buildTag(tag)).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: AppStyles.spacingMedium),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onApply,
                          style: AppStyles.primaryButtonStyle,
                          child: const Text('Postularme'),
                        ),
                      ),
                      const SizedBox(width: AppStyles.spacingMedium),
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        iconSize: AppStyles.iconSizeMedium,
                        color: AppColors.like,
                        onPressed: onLike,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ==================== BOTONES Y ACCIONES ====================
  
  /// Botón primario con gradiente
  static Widget gradientButton({
    required String text,
    required VoidCallback onPressed,
    List<Color>? gradient,
    double height = AppStyles.buttonHeightMedium,
    bool isLoading = false,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient ?? AppColors.primaryGradient,
        ),
        borderRadius: AppStyles.radiusSmall,
        boxShadow: [AppColors.shadowSmall],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.radiusSmall,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: AppStyles.textButton.copyWith(color: AppColors.textLight),
              ),
      ),
    );
  }
  
  /// Botón de acción flotante (FAB moderno)
  static Widget actionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? iconColor,
    double size = 56,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: backgroundColor != null
            ? null
            : AppStyles.primaryGradient,
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [AppColors.shadowMedium],
      ),
      child: IconButton(
        icon: Icon(icon),
        iconSize: size * 0.5,
        color: iconColor ?? AppColors.textLight,
        onPressed: onPressed,
      ),
    );
  }
  
  // ==================== HELPERS PRIVADOS ====================
  
  static String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
  
  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
  
  static Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppStyles.iconSizeSmall, color: AppColors.textSecondary),
        const SizedBox(width: AppStyles.spacingXSmall),
        Text(text, style: AppStyles.textCaption),
      ],
    );
  }
  
  static Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingMedium,
        vertical: AppStyles.spacingXSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: AppStyles.radiusSmall,
      ),
      child: Text(
        tag,
        style: AppStyles.textCaption.copyWith(
          color: AppColors.primary,
          fontWeight: AppStyles.fontWeightMedium,
        ),
      ),
    );
  }
}
