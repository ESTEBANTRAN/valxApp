import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/checker_provider.dart';
import '../widgets/account_input_widget.dart';
import '../widgets/checker_controls_widget.dart';
import '../widgets/results_widget.dart';
import '../widgets/detailed_stats_widget.dart';
import '../utils/theme.dart';
import 'settings_screen.dart';
import 'auth_webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/valx_icon.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 12),
            const Text(
              'ValX Checker',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          // Botón de login manual
          IconButton(
            icon: const Icon(Icons.login, color: Colors.white),
            onPressed: () async {
              final navigatorContext = context;
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AuthWebViewScreen(),
                ),
              );
              
              if (result == true && navigatorContext.mounted) {
                ScaffoldMessenger.of(navigatorContext).showSnackBar(
                  const SnackBar(
                    content: Text('¡Login manual completado! Ahora puedes usar el checker.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            tooltip: 'Login Manual de Riot Games',
          ),
          // Botón de configuración
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Configuración',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.input), text: 'Cuentas'),
            Tab(icon: Icon(Icons.play_arrow), text: 'Checker'),
            Tab(icon: Icon(Icons.list), text: 'Resultados'),
            Tab(icon: Icon(Icons.analytics), text: 'Estadísticas'),
            Tab(icon: Icon(Icons.details), text: 'Detalladas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AccountInputWidget(),
          CheckerControlsWidget(),
          ResultsWidget(),
          DetailedStatsWidget(),
          _DetailedStatsTab(),
        ],
      ),
    );
  }
}

class _DetailedStatsTab extends StatelessWidget {
  const _DetailedStatsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckerProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estadísticas Detalladas en Tiempo Real',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildStatSection(
                        'Regiones',
                        {
                          'NA': provider.regionStats['na'] ?? 0,
                          'EU': provider.regionStats['eu'] ?? 0,
                          'AP': provider.regionStats['ap'] ?? 0,
                          'BR': provider.regionStats['br'] ?? 0,
                          'KR': provider.regionStats['kr'] ?? 0,
                          'LATAM': provider.regionStats['latam'] ?? 0,
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildStatSection(
                        'Niveles',
                        {
                          '1-10': provider.levelStats['1-10'] ?? 0,
                          '10-20': provider.levelStats['10-20'] ?? 0,
                          '20-30': provider.levelStats['20-30'] ?? 0,
                          '30-40': provider.levelStats['30-40'] ?? 0,
                          '40-50': provider.levelStats['40-50'] ?? 0,
                          '50-100': provider.levelStats['50-100'] ?? 0,
                          '100+': provider.levelStats['100+'] ?? 0,
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildStatSection(
                        'Skins',
                        {
                          'Con Skins': provider.skinStats['with_skins'] ?? 0,
                          'Sin Skins': provider.skinStats['without_skins'] ?? 0,
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatSection(String title, Map<String, int> stats) {
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
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...stats.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
