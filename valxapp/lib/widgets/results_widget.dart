import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/checker_provider.dart';
import '../models/account.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class ResultsWidget extends StatefulWidget {
  const ResultsWidget({super.key});

  @override
  State<ResultsWidget> createState() => _ResultsWidgetState();
}

class _ResultsWidgetState extends State<ResultsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: AppTheme.primaryColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.accentColor,
            labelColor: AppTheme.accentColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            tabs: const [
              Tab(text: 'Válidas'),
              Tab(text: 'Baneadas'),
              Tab(text: 'Bloqueadas'),
              Tab(text: 'Errores'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _AccountsList(type: 'valid'),
              _AccountsList(type: 'banned'),
              _AccountsList(type: 'locked'),
              _AccountsList(type: 'error'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountsList extends StatelessWidget {
  final String type;

  const _AccountsList({required this.type});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckerProvider>(
      builder: (context, provider, child) {
        List<Account> accounts;
        String title;
        Color color;
        IconData icon;

        switch (type) {
          case 'valid':
            accounts = provider.validAccountsList;
            title = 'Cuentas Válidas';
            color = AppTheme.successColor;
            icon = Icons.check_circle;
            break;
          case 'banned':
            accounts = provider.bannedAccountsList;
            title = 'Cuentas Baneadas';
            color = AppTheme.errorColor;
            icon = Icons.block;
            break;
          case 'locked':
            accounts = provider.lockedAccountsList;
            title = 'Cuentas Bloqueadas';
            color = AppTheme.warningColor;
            icon = Icons.lock;
            break;
          case 'error':
            accounts = provider.errorAccountsList;
            title = 'Cuentas con Error';
            color = AppTheme.textSecondaryColor;
            icon = Icons.error;
            break;
          default:
            accounts = [];
            title = '';
            color = AppTheme.textSecondaryColor;
            icon = Icons.help;
        }

        if (accounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 64, color: color.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No hay $title',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los resultados aparecerán aquí después de la verificación',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '$title (${accounts.length})',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: color),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Exportar resultados
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar'),
                  ),
                ],
              ),
            ),

            // Lista de cuentas
            Expanded(
              child: ListView.builder(
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return _AccountCard(account: account, color: color);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final Color color;

  const _AccountCard({required this.account, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    account.username,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (account.level != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Nivel ${account.level}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            if (account.region != null) ...[
              const SizedBox(height: 4),
              Text(
                'Región: ${account.region!.toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],

            if (account.hasSkins == true) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.style, color: AppTheme.accentColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Tiene skins',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
            ],

            if (account.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                'Error: ${account.errorMessage}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.errorColor),
              ),
            ],

            if (account.lastChecked != null) ...[
              const SizedBox(height: 8),
              Text(
                'Verificado: ${_formatDateTime(account.lastChecked!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
