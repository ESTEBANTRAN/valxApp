import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/checker_provider.dart';
import '../utils/theme.dart';
import 'dart:async';

class DetailedStatsWidget extends StatefulWidget {
  const DetailedStatsWidget({super.key});

  @override
  State<DetailedStatsWidget> createState() => _DetailedStatsWidgetState();
}

class _DetailedStatsWidgetState extends State<DetailedStatsWidget> {
  StreamSubscription<Map<String, dynamic>>? _statsSubscription;
  Map<String, dynamic> _currentStats = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CheckerProvider>();
      _statsSubscription = provider.statsStream.listen((stats) {
        if (mounted) {
          setState(() {
            _currentStats = stats;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.accentColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estadísticas Detalladas',
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Estadísticas principales
        _buildMainStats(),

        const SizedBox(height: 16),

        // Estadísticas por región
        _buildRegionStats(),

        const SizedBox(height: 16),

        // Estadísticas por nivel
        _buildLevelStats(),

        const SizedBox(height: 16),

        // Estadísticas por skins
        _buildSkinStats(),
      ],
    );
  }

  Widget _buildMainStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen General',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Total',
                  value: _currentStats['totalAccounts']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Verificadas',
                  value: _currentStats['checkedAccounts']?.toString() ?? '0',
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Válidas',
                  value: _currentStats['validAccounts']?.toString() ?? '0',
                  color: AppTheme.successColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Baneadas',
                  value: _currentStats['bannedAccounts']?.toString() ?? '0',
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '2FA',
                  value: _currentStats['twoFactorAccounts']?.toString() ?? '0',
                  color: AppTheme.warningColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Credenciales Inválidas',
                  value: _currentStats['invalidCredentials']?.toString() ?? '0',
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegionStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por Región',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'EU',
                  value: _currentStats['euRegionCount']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'NA',
                  value: _currentStats['naRegionCount']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'AP',
                  value: _currentStats['apRegionCount']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'KR',
                  value: _currentStats['krRegionCount']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'LATAM',
                  value: _currentStats['latamRegionCount']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'BR',
                  value: _currentStats['brRegionCount']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por Nivel',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '1-10',
                  value: _currentStats['level1To10Count']?.toString() ?? '0',
                  color: AppTheme.infoColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: '10-20',
                  value: _currentStats['level10To20Count']?.toString() ?? '0',
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '20-30',
                  value: _currentStats['level20To30Count']?.toString() ?? '0',
                  color: AppTheme.infoColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: '30-40',
                  value: _currentStats['level30To40Count']?.toString() ?? '0',
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '40-50',
                  value: _currentStats['level40To50Count']?.toString() ?? '0',
                  color: AppTheme.infoColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: '50-100',
                  value: _currentStats['level50To100Count']?.toString() ?? '0',
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '100+',
                  value: _currentStats['level100PlusCount']?.toString() ?? '0',
                  color: AppTheme.infoColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Bloqueadas',
                  value: _currentStats['levelLockedCount']?.toString() ?? '0',
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkinStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por Skins',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Sin Skins',
                  value: _currentStats['noSkinsCount']?.toString() ?? '0',
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Con Skins',
                  value: _currentStats['skinnedCount']?.toString() ?? '0',
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '1-10',
                  value: _currentStats['skins1To10Count']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: '10-20',
                  value: _currentStats['skins10To20Count']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '20-30',
                  value: _currentStats['skins20To30Count']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: '30-40',
                  value: _currentStats['skins30To40Count']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '40-50',
                  value: _currentStats['skins40To50Count']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: '50-100',
                  value: _currentStats['skins50To100Count']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '100+',
                  value: _currentStats['skins100PlusCount']?.toString() ?? '0',
                  color: AppTheme.accentColor,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
