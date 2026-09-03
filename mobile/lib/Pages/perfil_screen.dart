import 'package:flutter/material.dart';
import '../Services/app_controller.dart';
import '../Themes/app_theme.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _telefonoCtrl;

  @override
  void initState() {
    super.initState();
    final user = widget.controller.currentUser;
    _nombreCtrl = TextEditingController(text: user?.nombre ?? '');
    _apellidosCtrl = TextEditingController(text: user?.apellidos ?? '');
    _telefonoCtrl = TextEditingController(text: user?.telefono ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Funcionalidad de editar residente comentada temporalmente
    /*
    if (!_formKey.currentState!.validate()) return;
    
    await widget.controller.completarPerfil(
      _nombreCtrl.text,
      _apellidosCtrl.text,
      _telefonoCtrl.text,
    );
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Actualizar Datos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const FieldLabel(text: 'Nombre'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: AppTheme.inputDecoration('Ej. Juan Carlos'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel(text: 'Apellidos'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _apellidosCtrl,
                      decoration: AppTheme.inputDecoration('Ej. Pérez'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel(text: 'Teléfono'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _telefonoCtrl,
                      decoration: AppTheme.inputDecoration('Ej. 4421234567'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 32),
                    ListenableBuilder(
                      listenable: widget.controller,
                      builder: (context, _) {
                        return ElevatedButton(
                          onPressed: widget.controller.isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: widget.controller.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Guardar Cambios'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
    );
  }
}
