import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/client.dart';
import '../../repositories/client_repository.dart';
import '../../utils/validators.dart';
import '../../widgets/entity_form_scaffold.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, required this.id});

  final String id;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _phoneController = TextEditingController();
  Client? _client;
  bool _loading = true;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final client = await context.read<ClientRepository>().findById(widget.id);
    if (!mounted) return;
    setState(() {
      _client = client;
      _phoneController.text = client?.phone ?? '';
      _loading = false;
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _handleSubmit() async {
    final client = _client;
    if (client == null) return;
    await context.read<ClientRepository>().update(
      client.copyWith(phone: _phoneController.text.trim()),
    );
    if (!mounted) return;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Изменить покупателя')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return EntityFormScaffold(
      title: 'Изменить покупателя',
      isDirty: _dirty,
      onSave: _handleSubmit,
      fields: [
        Text('ФИО: ${_client?.fullName ?? '—'}'),
        Text('Почта: ${_client?.email ?? '—'}'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Телефон',
            border: OutlineInputBorder(),
          ),
          validator: Validators.combine([
            Validators.required(),
            Validators.lengthRange(5, 20),
          ]),
          onChanged: (_) => _markDirty(),
        ),
      ],
    );
  }
}
