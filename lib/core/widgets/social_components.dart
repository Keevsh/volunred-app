import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

/// Componentes de UI estilo Red Social
class SocialComponents {
  /// Avatar circular con gradiente (estilo Instagram Stories)
  static Widget gradientAvatar({
    required String? name,
    double size = 56,
    List<Color>? gradient,
    Widget? child,
    VoidCallback? onTap,
  }) {
    final colors = gradient ?? 
        AppColors.avatarGradients[
          (name?.hashCode ?? 0).abs() % AppColors.avatarGradients.length
        ];
    
    final initials = name != null && name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : '?';
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: child ??
              Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: colors[0],
                  ),
                ),
              ),
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
  }) {
    final initials = name != null && name.isNotEmpty
        ? (name.split(' ').length > 1
            ? '${name.split(' ')[0][0]}${name.split(' ')[1][0]}'
            : name.substring(0, 1))
            .toUpperCase()
        : '?';
    
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? AppColors.primary.withOpacity(0.1),
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
      child: imageUrl == null
          ? Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }

  /// Header de post estilo Instagram/Facebook
  static Widget postHeader({
    required String userName,
    String? userAvatar,
    String? timeAgo,
    VoidCallback? onMorePressed,
    VoidCallback? onUserTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingMedium,
        vertical: AppStyles.spacingSmall,
      ),
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
          const SizedBox(width: AppStyles.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onUserTap,
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppStyles.fontSizeBody,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (timeAgo != null)
                  Text(
                    timeAgo,
                    style: const TextStyle(
                      fontSize: AppStyles.fontSizeSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (onMorePressed != null)
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: onMorePressed,
              color: AppColors.textPrimary,
            ),
        ],
      ),
    );
  }

  /// Barra de interacciones estilo Instagram
  static Widget interactionBar({
    required bool isLiked,
    required int likesCount,
    required int commentsCount,
    VoidCallback? onLike,
    VoidCallback? onComment,
    VoidCallback? onShare,
    VoidCallback? onSave,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingMedium,
        vertical: AppStyles.spacingSmall,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? AppColors.likeRed : AppColors.textPrimary,
              size: 28,
            ),
            onPressed: onLike,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              size: 26,
            ),
            onPressed: onComment,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.send_outlined,
              size: 24,
            ),
            onPressed: onShare,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.bookmark_border,
              size: 26,
            ),
            onPressed: onSave,
          ),
        ],
      ),
    );
  }

  /// Sección de likes y descripción estilo Instagram
  static Widget postFooter({
    required int likesCount,
    String? description,
    String? authorName,
    List<String>? comments,
    VoidCallback? onViewComments,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (likesCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppStyles.spacingSmall),
              child: Text(
                '$likesCount me gusta',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: AppStyles.fontSizeBody,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          if (description != null && description.isNotEmpty) ...[
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: AppStyles.fontSizeBody,
                  color: AppColors.textPrimary,
                ),
                children: [
                  if (authorName != null) ...[
                    TextSpan(
                      text: '$authorName ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                  TextSpan(text: description),
                ],
              ),
            ),
            const SizedBox(height: AppStyles.spacingSmall),
          ],
          if (comments != null && comments.isNotEmpty)
            TextButton(
              onPressed: onViewComments,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ver ${comments.length} comentarios',
                style: const TextStyle(
                  fontSize: AppStyles.fontSizeSmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Card de post estilo Instagram/Facebook
  static Widget postCard({
    required String userName,
    String? userAvatar,
    String? timeAgo,
    String? imageUrl,
    String? description,
    int likesCount = 0,
    int commentsCount = 0,
    bool isLiked = false,
    VoidCallback? onLike,
    VoidCallback? onComment,
    VoidCallback? onShare,
    VoidCallback? onUserTap,
    Widget? customContent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          postHeader(
            userName: userName,
            userAvatar: userAvatar,
            timeAgo: timeAgo,
            onUserTap: onUserTap,
          ),
          
          // Imagen o contenido
          if (imageUrl != null)
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else if (customContent != null)
            customContent,
          
          // Barra de interacciones
          interactionBar(
            isLiked: isLiked,
            likesCount: likesCount,
            commentsCount: commentsCount,
            onLike: onLike,
            onComment: onComment,
            onShare: onShare,
          ),
          
          // Footer con likes y descripción
          postFooter(
            likesCount: likesCount,
            description: description,
            authorName: userName,
          ),
          
          const SizedBox(height: AppStyles.spacingMedium),
        ],
      ),
    );
  }

  /// Card de historia/story estilo Instagram
  static Widget storyCard({
    required String userName,
    String? userAvatar,
    bool isViewed = false,
    bool isAddStory = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: AppStyles.spacingMedium),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isAddStory
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isViewed
                                ? [AppColors.border, AppColors.borderLight]
                                : AppColors.avatarGradients[
                                    userName.hashCode.abs() %
                                        AppColors.avatarGradients.length
                                  ],
                          ),
                    color: isAddStory ? AppColors.backgroundLight : null,
                    border: Border.all(
                      color: isAddStory
                          ? AppColors.border
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: isAddStory
                        ? const Icon(
                            Icons.add,
                            color: AppColors.primary,
                            size: 32,
                          )
                        : circleAvatar(
                            name: userName,
                            imageUrl: userAvatar,
                            size: 70,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingSmall),
            Text(
              isAddStory ? 'Tu historia' : userName,
              style: TextStyle(
                fontSize: AppStyles.fontSizeSmall,
                color: AppColors.textPrimary,
                fontWeight: isAddStory ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Sección de historias/stories horizontal
  static Widget storiesSection({
    required List<Map<String, dynamic>> stories,
    VoidCallback? onAddStory,
  }) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: AppStyles.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingMedium),
        itemCount: stories.length + (onAddStory != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (onAddStory != null && index == 0) {
            return storyCard(
              userName: 'Tu historia',
              isAddStory: true,
              onTap: onAddStory,
            );
          }
          final storyIndex = onAddStory != null ? index - 1 : index;
          final story = stories[storyIndex];
          return storyCard(
            userName: story['userName'] ?? 'Usuario',
            userAvatar: story['userAvatar'],
            isViewed: story['isViewed'] ?? false,
            onTap: story['onTap'],
          );
        },
      ),
    );
  }

  /// Card de proyecto estilo post de red social
  static Widget projectPostCard({
    required String projectName,
    required String organizationName,
    String? organizationAvatar,
    String? imageUrl,
    String? description,
    String? location,
    String? date,
    int volunteersCount = 0,
    VoidCallback? onTap,
    VoidCallback? onLike,
    VoidCallback? onApply,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          postHeader(
            userName: organizationName,
            userAvatar: organizationAvatar,
            timeAgo: date,
            onUserTap: onTap,
          ),
          
          // Contenido del proyecto
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(AppStyles.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectName,
                  style: const TextStyle(
                    fontSize: AppStyles.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: AppStyles.spacingSmall),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: AppStyles.fontSizeBody,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (location != null) ...[
                  const SizedBox(height: AppStyles.spacingSmall),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: AppStyles.fontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (volunteersCount > 0) ...[
                  const SizedBox(height: AppStyles.spacingSmall),
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$volunteersCount voluntarios',
                        style: const TextStyle(
                          fontSize: AppStyles.fontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Barra de acciones
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingMedium),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Icons.how_to_reg, size: 20),
                    label: const Text('Aplicar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border, size: 22),
                  onPressed: onLike,
                  color: AppColors.textPrimary,
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 22),
                  onPressed: () {},
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

