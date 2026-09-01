import '../Themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../Services/app_controller.dart';
import '../Widgets/field_label.dart';
import '../Widgets/header_bar.dart';
import '../Models/api_exceptions.dart';
import '../main.dart';

class ResidentesFormScreen extends StatefulWidget {
  const ResidentesFormScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ResidentesFormScreen> createState() => _ResidentesFormScreenState();
}

class _ResidentesFormScreenState extends State<ResidentesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _showPassword = false;

  void _generatePassword() {
    _passwordCtrl.text =
        'Hav${DateTime.now().millisecondsSinceEpoch % 10000}!a';
    setState(() => _showPassword = true);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'nombre': _nombreCtrl.text,
        'apellidos': _apellidosCtrl.text,
        'telefono': _telefonoCtrl.text,
        'email': _emailCtrl.text,
        'password': _passwordCtrl.text,
        'rol': 'residente',
      };

      final response = await widget.controller.httpClient.post(
        Uri.parse('${dotenv.env['API_BASE_URL'] ?? ''}/api/auth/register'),
        headers: {
          'Authorization': 'Bearer ${widget.controller.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        widget.controller.notifyToast(
          'Residente registrado correctamente',
          success: true,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        _errorMessage = 'Error al guardar (Status: ${response.statusCode})';
        try {
          final err = jsonDecode(response.body);
          if (err['message'] != null) _errorMessage = err['message'];
        } catch (_) {}
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Registrar Residente',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_errorMessage != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        border: Border.all(
                                          color: const Color(0xFFFECACA),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Color(0xFFB91C1C),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  const FieldLabel(text: 'Nombre'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nombreCtrl,
                                    decoration: AppTheme.inputDecoration(
                                      'Ej. Juan Carlos',
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  const FieldLabel(text: 'Apellidos'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _apellidosCtrl,
                                    decoration: AppTheme.inputDecoration('Ej. Pérez'),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  const FieldLabel(text: 'Teléfono'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _telefonoCtrl,
                                    decoration: AppTheme.inputDecoration(
                                      'Ej. 4421234567',
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  const FieldLabel(text: 'Correo Electrónico'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    decoration: AppTheme.inputDecoration(
                                      'residente@haven.com',
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const FieldLabel(text: 'Contraseña'),
                                      TextButton.icon(
                                        onPressed: _generatePassword,
                                        icon: const Icon(
                                          Icons.password,
                                          size: 16,
                                        ),
                                        label: const Text('Generar'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF4F46E5,
                                          ),
                                          backgroundColor: const Color(
                                            0xFFEEF2FF,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordCtrl,
                                    obscureText: !_showPassword,
                                    decoration: AppTheme.inputDecoration(
                                      'Mínimo 8 caracteres',
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                  const SizedBox(height: 32),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Cancelar',
                                            style: TextStyle(
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isSubmitting
                                              ? null
                                              : _submit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF0F172A,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: _isSubmitting
                                              ? const CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                              : const Text('Guardar Residente'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }
}

// ==========================================
// RESIDENTE SCREEN
// ==========================================

