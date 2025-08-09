import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Configuración del Checker
            _buildSection(
              title: 'Configuración del Checker',
              icon: Icons.settings,
              children: [
                _buildSwitchTile(
                  title: 'Verificación automática',
                  subtitle:
                      'Iniciar verificación automáticamente al cargar cuentas',
                  value: false,
                  onChanged: (value) {},
                ),
                _buildSwitchTile(
                  title: 'Guardar resultados',
                  subtitle: 'Guardar resultados en archivos locales',
                  value: true,
                  onChanged: (value) {},
                ),
                _buildSwitchTile(
                  title: 'Mostrar progreso detallado',
                  subtitle: 'Mostrar información detallada del progreso',
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Configuración de la Interfaz
            _buildSection(
              title: 'Interfaz de Usuario',
              icon: Icons.palette,
              children: [
                _buildSwitchTile(
                  title: 'Modo oscuro',
                  subtitle: 'Usar tema oscuro en la aplicación',
                  value: false,
                  onChanged: (value) {},
                ),
                _buildSwitchTile(
                  title: 'Animaciones',
                  subtitle: 'Mostrar animaciones en la interfaz',
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Configuración de Exportación
            _buildSection(
              title: 'Exportación',
              icon: Icons.download,
              children: [
                _buildSwitchTile(
                  title: 'Exportar automáticamente',
                  subtitle: 'Exportar resultados al completar verificación',
                  value: false,
                  onChanged: (value) {},
                ),
                _buildSwitchTile(
                  title: 'Formato CSV',
                  subtitle: 'Usar formato CSV para exportación',
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Botones de acción
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuración restablecida'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              icon: const Icon(Icons.restore),
              label: const Text('Restablecer Configuración'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuración exportada'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              icon: const Icon(Icons.upload),
              label: const Text('Exportar Configuración'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.accentColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }
}
