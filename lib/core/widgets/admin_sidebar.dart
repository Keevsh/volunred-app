import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isAdmin;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VolunRed',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        isAdmin ? 'Admin Panel' : 'Funcionario',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  index: 0,
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemSelected(0),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.folder_rounded,
                  label: 'Proyectos',
                  index: 1,
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemSelected(1),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.task_alt_rounded,
                  label: 'Tareas',
                  index: 2,
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemSelected(2),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.people_rounded,
                  label: 'Voluntarios',
                  index: 3,
                  isSelected: selectedIndex == 3,
                  onTap: () => onItemSelected(3),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.person_add_rounded,
                  label: 'Inscripciones',
                  index: 4,
                  isSelected: selectedIndex == 4,
                  onTap: () => onItemSelected(4),
                ),
                if (isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Divider(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ADMINISTRACIÓN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.people_outline_rounded,
                    label: 'Usuarios',
                    index: 5,
                    isSelected: selectedIndex == 5,
                    onTap: () => onItemSelected(5),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.business_rounded,
                    label: 'Organizaciones',
                    index: 6,
                    isSelected: selectedIndex == 6,
                    onTap: () => onItemSelected(6),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.category_rounded,
                    label: 'Categorías',
                    index: 7,
                    isSelected: selectedIndex == 7,
                    onTap: () => onItemSelected(7),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Divider(),
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  label: 'Configuración',
                  index: 8,
                  isSelected: selectedIndex == 8,
                  onTap: () => onItemSelected(8),
                ),
              ],
            ),
          ),

          // User Info & Logout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin User',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'admin@volunred.org',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () {
                    // Implementar logout
                  },
                  tooltip: 'Cerrar sesión',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.primary
                      : Colors.grey.shade700,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
