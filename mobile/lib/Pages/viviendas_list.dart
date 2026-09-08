import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../Services/app_controller.dart';
import 'vivienda_detalle_screen.dart';

class ViviendasListScreen extends StatefulWidget {
  const ViviendasListScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ViviendasListScreen> createState() => _ViviendasListScreenState();
}

class _ViviendasListScreenState extends State<ViviendasListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _viviendas = [];

  @override
  void initState() {
    super.initState();
    _fetchViviendas();
  }

  Future<void> _fetchViviendas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await widget.controller.httpClient.get(
        Uri.parse(
          '${dotenv.env['API_BASE_URL_VIVIENDAS'] ?? ''}/api/Viviendas',
        ),
        headers: {'Authorization': 'Bearer ${widget.controller.accessToken}'},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          _viviendas = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          _viviendas = decoded['data'];
        } else {
          _viviendas = [];
        }
      } else {
        _errorMessage = 'Error de conexión';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVivienda(int id) async {
    try {
      final response = await widget.controller.httpClient.delete(
        Uri.parse(
          '${dotenv.env['API_BASE_URL_VIVIENDAS'] ?? ''}/api/Viviendas/$id',
        ),
        headers: {'Authorization': 'Bearer ${widget.controller.accessToken}'},
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        widget.controller.notifyToast(
          'Vivienda eliminada correctamente',
          success: true,
        );
        _fetchViviendas();
      } else {
        widget.controller.notifyToast(
          'No se pudo eliminar la vivienda',
          success: false,
        );
      }
    } catch (e) {
      widget.controller.notifyToast('Error de red', success: false);
    }
  }

  void _showFormDialog({Map<String, dynamic>? vivienda}) {
    final bool isEdit = vivienda != null;
    final formKey = GlobalKey<FormState>();
    final numeroCasaController = TextEditingController(
      text: isEdit ? vivienda['numeroCasa'] : '',
    );
    final tipoController = TextEditingController(
      text: isEdit ? vivienda['tipo'] : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Editar Vivienda' : 'Nueva Vivienda'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: numeroCasaController,
                  decoration: const InputDecoration(
                    labelText: 'Número de Casa',
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: tipoController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo (Opcional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final payload = {
                    'numeroCasa': numeroCasaController.text.trim(),
                    'tipo': tipoController.text.trim(),
                  };

                  final url = isEdit
                      ? '${dotenv.env['API_BASE_URL_VIVIENDAS'] ?? ''}/api/Viviendas/${vivienda['id']}'
                      : '${dotenv.env['API_BASE_URL_VIVIENDAS'] ?? ''}/api/Viviendas';

                  try {
                    http.Response res;
                    if (isEdit) {
                      res = await widget.controller.httpClient.put(
                        Uri.parse(url),
                        headers: {
                          'Authorization':
                              'Bearer ${widget.controller.accessToken}',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode(payload),
                      );
                    } else {
                      res = await widget.controller.httpClient.post(
                        Uri.parse(url),
                        headers: {
                          'Authorization':
                              'Bearer ${widget.controller.accessToken}',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode(payload),
                      );
                    }

                    if (res.statusCode >= 200 && res.statusCode < 300) {
                      widget.controller.notifyToast(
                        isEdit
                            ? 'Actualizado correctamente'
                            : 'Creado correctamente',
                        success: true,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      _fetchViviendas();
                    } else {
                      widget.controller.notifyToast(
                        'Error al guardar',
                        success: false,
                      );
                    }
                  } catch (e) {
                    widget.controller.notifyToast(
                      'Error de red',
                      success: false,
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestión de Viviendas',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchViviendas,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _viviendas.length,
              itemBuilder: (context, index) {
                final v = _viviendas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViviendaDetalleScreen(
                            controller: widget.controller,
                            vivienda: v,
                            onChanged: _fetchViviendas,
                          ),
                        ),
                      );
                    },
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEEF2FF),
                      child: Icon(Icons.home_rounded, color: Color(0xFF111C99)),
                    ),
                    title: Text(
                      v['numeroCasa'] ?? 'S/N',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      v['tipo'] != null && (v['tipo'] as String).isNotEmpty
                          ? v['tipo']
                          : 'Vivienda Residencial',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF111C99),
                            size: 20,
                          ),
                          tooltip: 'Editar',
                          onPressed: () => _showFormDialog(vivienda: v),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          tooltip: 'Eliminar',
                          onPressed: () => _deleteVivienda(v['id']),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: const Color(0xFF0F172A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
