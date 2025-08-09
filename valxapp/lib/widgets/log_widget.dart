import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/checker_provider.dart';
import '../utils/theme.dart';

class LogWidget extends StatefulWidget {
  const LogWidget({super.key});

  @override
  State<LogWidget> createState() => _LogWidgetState();
}

class _LogWidgetState extends State<LogWidget> {
  final List<String> _logMessages = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CheckerProvider>();
      provider.logStream.listen((message) {
        setState(() {
          _logMessages.add(message);
          if (_logMessages.length > 1000) {
            _logMessages.removeAt(0);
          }
        });

        if (_autoScroll && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
              Icon(Icons.list_alt, color: AppTheme.accentColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Log de Actividad',
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: _autoScroll,
                    onChanged: (value) {
                      setState(() {
                        _autoScroll = value;
                      });
                    },
                    activeColor: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Auto-scroll',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _logMessages.isNotEmpty ? _clearLog : null,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar'),
              ),
            ],
          ),
        ),

        // Log messages
        Expanded(
          child: _logMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 64,
                        color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay mensajes de log',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.textSecondaryColor.withValues(
                                alpha: 0.5,
                              ),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Los mensajes aparecerán aquí durante la verificación',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _logMessages.length,
                  itemBuilder: (context, index) {
                    final message = _logMessages[index];
                    return _LogMessage(message: message);
                  },
                ),
        ),
      ],
    );
  }

  void _clearLog() {
    setState(() {
      _logMessages.clear();
    });
  }
}

class _LogMessage extends StatelessWidget {
  final String message;

  const _LogMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    Color messageColor = AppTheme.textPrimaryColor;
    IconData? icon;

    // Determinar color e icono basado en el contenido del mensaje
    if (message.toLowerCase().contains('error')) {
      messageColor = AppTheme.errorColor;
      icon = Icons.error;
    } else if (message.toLowerCase().contains('verificada')) {
      if (message.toLowerCase().contains('valid')) {
        messageColor = AppTheme.successColor;
        icon = Icons.check_circle;
      } else if (message.toLowerCase().contains('banned')) {
        messageColor = AppTheme.errorColor;
        icon = Icons.block;
      } else if (message.toLowerCase().contains('locked')) {
        messageColor = AppTheme.warningColor;
        icon = Icons.lock;
      } else {
        messageColor = AppTheme.textSecondaryColor;
        icon = Icons.help;
      }
    } else if (message.toLowerCase().contains('iniciando')) {
      messageColor = AppTheme.accentColor;
      icon = Icons.play_arrow;
    } else if (message.toLowerCase().contains('completada')) {
      messageColor = AppTheme.successColor;
      icon = Icons.done;
    } else if (message.toLowerCase().contains('cargadas')) {
      messageColor = AppTheme.infoColor;
      icon = Icons.file_upload;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: messageColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: messageColor, size: 16),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: messageColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
