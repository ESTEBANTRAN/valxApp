import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/checker_provider.dart';
import '../utils/theme.dart';

class AccountInputWidget extends StatefulWidget {
  const AccountInputWidget({super.key});

  @override
  State<AccountInputWidget> createState() => _AccountInputWidgetState();
}

class _AccountInputWidgetState extends State<AccountInputWidget> {
  final TextEditingController _accountsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _accountsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cargar Cuentas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Opciones de carga
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Cargar Archivo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showTextInputDialog,
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Pegar Texto'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Información de cuentas cargadas
            Consumer<CheckerProvider>(
              builder: (context, provider, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_circle,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.totalAccounts > 0
                              ? '${provider.totalAccounts} cuentas cargadas'
                              : 'No hay cuentas cargadas',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (provider.totalAccounts > 0)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            provider.clearAccounts();
                          },
                          tooltip: 'Limpiar cuentas',
                        ),
                    ],
                  ),
                );
              },
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      setState(() => _isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          final provider = context.read<CheckerProvider>();
          await provider.loadAccountsFromFile(file.path!);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${provider.totalAccounts} cuentas cargadas'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando archivo: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showTextInputDialog() async {
    final textController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pegar Cuentas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pega las cuentas en formato usuario:contraseña (una por línea)',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'usuario1:contraseña1\nusuario2:contraseña2\n...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();

                try {
                  setState(() => _isLoading = true);

                  final provider = context.read<CheckerProvider>();
                  await provider.loadAccountsFromText(textController.text);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${provider.totalAccounts} cuentas cargadas',
                        ),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error cargando cuentas: $e'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              }
            },
            child: const Text('Cargar'),
          ),
        ],
      ),
    );
  }
}
