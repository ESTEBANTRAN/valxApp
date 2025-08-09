import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/checker_provider.dart';
import '../utils/theme.dart';
import '../screens/settings_screen.dart';

class CheckerControlsWidget extends StatelessWidget {
  const CheckerControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controles del Checker',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            Consumer<CheckerProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    // Botones principales
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                provider.totalAccounts > 0 &&
                                    !provider.isRunning
                                ? provider.startChecking
                                : null,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Iniciar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: provider.isRunning && !provider.isPaused
                                ? provider.pauseChecking
                                : null,
                            icon: const Icon(Icons.pause),
                            label: const Text('Pausar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warningColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: provider.isRunning
                                ? provider.stopChecking
                                : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('Detener'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Botones adicionales
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: provider.isRunning && provider.isPaused
                                ? provider.resumeChecking
                                : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reanudar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Config'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Información de estado
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _StatusRow(
                            label: 'Estado',
                            value: provider.isRunning
                                ? (provider.isPaused ? 'Pausado' : 'Ejecutando')
                                : 'Detenido',
                            color: provider.isRunning
                                ? (provider.isPaused
                                      ? AppTheme.warningColor
                                      : AppTheme.successColor)
                                : AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(height: 8),
                          _StatusRow(
                            label: 'Progreso',
                            value: provider.totalAccounts > 0
                                ? '${provider.checkedAccounts}/${provider.totalAccounts}'
                                : '0/0',
                            color: AppTheme.accentColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryColor),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
