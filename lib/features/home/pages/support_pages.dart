import 'package:flutter/material.dart';

/// Páginas de soporte: Configuración, Centro de Ayuda y Sobre la App.
/// Se alimentan de listas de datos para evitar texto duro y permitir ajustes rápidos.

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  bool _notifPush = true;
  bool _notifEmail = false;
  bool _modoAhorroDatos = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ajustesRapidos = [
      _ToggleItem(
        title: 'Notificaciones push',
        subtitle: 'Alertas sobre tareas, inscripciones y mensajes',
        value: _notifPush,
        onChanged: (v) => setState(() => _notifPush = v),
      ),
      _ToggleItem(
        title: 'Resúmenes por email',
        subtitle: 'Un correo semanal con tu actividad y próximos eventos',
        value: _notifEmail,
        onChanged: (v) => setState(() => _notifEmail = v),
      ),
      _ToggleItem(
        title: 'Ahorro de datos',
        subtitle: 'Reduce carga de imágenes en conexiones móviles',
        value: _modoAhorroDatos,
        onChanged: (v) => setState(() => _modoAhorroDatos = v),
      ),
    ];

    final privacidad = [
      _ActionItem(
        icon: Icons.lock_outline,
        title: 'Privacidad del perfil',
        subtitle: 'Controla quién puede ver tu información básica',
        onTap: () {},
      ),
      _ActionItem(
        icon: Icons.shield_moon_outlined,
        title: 'Modo discreto',
        subtitle: 'Oculta tu actividad reciente al explorar',
        onTap: () {},
      ),
    ];

    final accesibilidad = [
      _ActionItem(
        icon: Icons.format_size,
        title: 'Tamaño de fuente',
        subtitle: 'Pequeño, mediano o grande',
        onTap: () {},
      ),
      _ActionItem(
        icon: Icons.contrast,
        title: 'Contraste y color',
        subtitle: 'Mejora legibilidad en exteriores',
        onTap: () {},
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F9FC), Color(0xFFFFFFFF)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _SectionHeader(
              title: 'Preferencias',
              subtitle: 'Configura cómo quieres que te avisemos',
            ),
            ...ajustesRapidos.map((item) => _SettingCard(
                  child: SwitchListTile.adaptive(
                    title: Text(item.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    subtitle: Text(item.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                    value: item.value,
                    onChanged: item.onChanged,
                  ),
                )),
            const SizedBox(height: 12),
            _SectionHeader(
              title: 'Privacidad',
              subtitle: 'Control sobre tu presencia en la plataforma',
            ),
            ...privacidad.map((item) => _SettingCard(child: _ActionTile(item: item))),
            const SizedBox(height: 12),
            _SectionHeader(
              title: 'Accesibilidad',
              subtitle: 'Personaliza la lectura y el contraste',
            ),
            ...accesibilidad.map((item) => _SettingCard(child: _ActionTile(item: item))),
          ],
        ),
      ),
    );
  }
}

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      _FaqItem(
        question: '¿Cómo me inscribo en una organización?',
        answer: 'Explora organizaciones, entra en la ficha y toca "Solicitar inscribirme". Recibirás un estado pendiente y la organización aprobará o rechazará.',
      ),
      _FaqItem(
        question: '¿Dónde veo mis tareas asignadas?',
        answer: 'En Mi Actividad ahora tienes la sección "Mis Tareas" con estado Pendiente, En progreso y Completadas.',
      ),
      _FaqItem(
        question: '¿Puedo cancelar mi participación en un proyecto?',
        answer: 'Sí. En la ficha del proyecto ve a tus participaciones y selecciona la opción de cancelar. Notificaremos a la organización.',
      ),
      _FaqItem(
        question: '¿Cómo contacto soporte?',
        answer: 'Envía un correo a soporte@volunred.app o abre un ticket desde esta pantalla.',
      ),
    ];

    final contactos = [
      _ActionItem(
        icon: Icons.mail_outline,
        title: 'Correo de soporte',
        subtitle: 'soporte@volunred.app',
        onTap: () {},
      ),
      _ActionItem(
        icon: Icons.chat_bubble_outline,
        title: 'Chat de ayuda',
        subtitle: 'Disponible 9:00 - 18:00',
        onTap: () {},
      ),
      _ActionItem(
        icon: Icons.article_outlined,
        title: 'Guía rápida',
        subtitle: 'Primeros pasos para voluntarios y organizaciones',
        onTap: () {},
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Ayuda'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F9FC), Color(0xFFFFFFFF)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _HighlightCard(
              title: '¿Necesitas ayuda?',
              subtitle: 'Encuentra respuestas rápidas o contáctanos directamente.',
              icon: Icons.support_agent,
            ),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Preguntas frecuentes', subtitle: 'Información clave para usar la app'),
            ...faqs.map((item) => _FaqTile(item: item)),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Contáctanos', subtitle: 'Estamos para ayudarte'),
            ...contactos.map((item) => _SettingCard(child: _ActionTile(item: item))),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final valores = [
      'Conectar voluntarios con causas reales',
      'Dar transparencia al avance de proyectos',
      'Reconocer el impacto con métricas y badges',
    ];

    final links = [
      _ActionItem(icon: Icons.shield_outlined, title: 'Política de privacidad', subtitle: 'Cómo cuidamos tus datos', onTap: () {}),
      _ActionItem(icon: Icons.description_outlined, title: 'Términos y condiciones', subtitle: 'Normas de uso de la plataforma', onTap: () {}),
      _ActionItem(icon: Icons.verified_user_outlined, title: 'Código de conducta', subtitle: 'Respeto y seguridad para la comunidad', onTap: () {}),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre la App'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F9FC), Color(0xFFFFFFFF)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _HighlightCard(
              title: 'VolunRed App',
              subtitle: 'v1.0.0 · Conectando voluntarios y organizaciones',
              icon: Icons.favorite_outline,
            ),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Nuestra misión', subtitle: 'Lo que nos mueve'),
            _SettingCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Facilitar la colaboración entre personas y organizaciones, con herramientas claras para gestionar tareas, progreso y reconocimiento.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 12),
                    ...valores.map(
                      (v) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                v,
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Documentos', subtitle: 'Consulta la letra pequeña'),
            ...links.map((item) => _SettingCard(child: _ActionTile(item: item))),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _HighlightCard({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final _ActionItem item;
  const _ActionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFE8F1FB),
        child: Icon(item.icon, color: const Color(0xFF1976D2)),
      ),
      title: Text(item.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Text(item.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: item.onTap,
    );
  }
}

class _FaqTile extends StatelessWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: const Icon(Icons.help_outline, color: Color(0xFF1976D2)),
          title: Text(item.question, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.answer,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleItem {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  _ToggleItem({required this.title, required this.subtitle, required this.value, required this.onChanged});
}

class _ActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _ActionItem({required this.icon, required this.title, required this.subtitle, required this.onTap});
}

class _FaqItem {
  final String question;
  final String answer;
  _FaqItem({required this.question, required this.answer});
}
