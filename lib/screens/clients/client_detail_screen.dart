import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/client.dart';
import '../../models/license.dart';
import '../../models/role.dart';
import '../../repositories/client_repository.dart';
import '../../repositories/license_repository.dart';
import '../../state/auth_notifier.dart';
import '../../utils/validators.dart';
import '../../widgets/confirm_dialog.dart';

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  Client? _client;
  License? _license;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final client = await context.read<ClientRepository>().findById(widget.id);
    if (!mounted) return;
    final license = client == null
        ? null
        : await context.read<LicenseRepository>().findByClientId(client.id);
    if (!mounted) return;
    setState(() {
      _client = client;
      _license = license;
      _loading = false;
    });
  }

  Future<void> _handleSoftDelete(Client c) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить запись?',
      message: 'Логическое удаление: запись скроется из списка, её можно восстановить.',
    );
    if (!ok || !mounted) return;
    await context.read<ClientRepository>().softDelete(c.id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleRestore(Client c) async {
    await context.read<ClientRepository>().restore(c.id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _handleHardDelete(Client c) async {
    final ok = await confirmDialog(
      context,
      title: 'Удалить безвозвратно?',
      message: 'Физическое удаление нельзя отменить.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!ok || !mounted) return;
    await context.read<ClientRepository>().hardDelete(c.id);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _issueOrEditLicense(Client c) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _LicenseDialog(clientId: c.id, existing: _license),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = _client;
    final isStaff = context.watch<AuthNotifier>().has(Role.seller);
    return Scaffold(
      appBar: AppBar(title: Text(c?.fullName ?? 'Покупатель')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : c == null
          ? Center(child: Text('Запись №${widget.id} не найдена'))
          : _buildContent(context, c, isStaff),
    );
  }

  Widget _buildContent(BuildContext context, Client c, bool isStaff) {
    final license = _license;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.isDeleted)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.red.withValues(alpha: 0.1),
                child: const Text(
                  'Эта запись удалена',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            _row('Имя', c.fullName),
            _row('Почта', c.email),
            _row('Телефон', c.phone),
            const SizedBox(height: 16),
            Text(
              'Лицензия на оружие',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (license == null)
              const Text('Лицензия не выписана')
            else ...[
              _row('Тип', license.typeLabel),
              _row('Номер', license.number),
              _row('Выдана', _formatDate(license.issuedAt)),
              _row('Действует до', _formatDate(license.expiresAt)),
              if (license.isExpired)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.orange.withValues(alpha: 0.15),
                    child: const Text(
                      'Срок действия лицензии истёк',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ),
            ],
            if (isStaff)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () => _issueOrEditLicense(c),
                  icon: const Icon(Icons.badge_outlined),
                  label: Text(license == null ? 'Выписать лицензию' : 'Изменить лицензию'),
                ),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: [
                if (isStaff) ...[
                  if (!c.isDeleted)
                    OutlinedButton.icon(
                      onPressed: () => context.push<bool>('/clients/${c.id}/edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Изменить телефон'),
                    ),
                  if (!c.isDeleted)
                    OutlinedButton.icon(
                      onPressed: () => _handleSoftDelete(c),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Удалить'),
                    ),
                  if (c.isDeleted)
                    OutlinedButton.icon(
                      onPressed: () => _handleRestore(c),
                      icon: const Icon(Icons.restore),
                      label: const Text('Восстановить'),
                    ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => _handleHardDelete(c),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Удалить навсегда'),
                  ),
                ],
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Назад к списку'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _LicenseDialog extends StatefulWidget {
  const _LicenseDialog({required this.clientId, this.existing});

  final String clientId;
  final License? existing;

  @override
  State<_LicenseDialog> createState() => _LicenseDialogState();
}

class _LicenseDialogState extends State<_LicenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  String _type = 'other';
  DateTime? _issuedAt;
  DateTime? _expiresAt;
  String? _numberServerError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _numberController.text = existing.number;
      _type = existing.type;
      _issuedAt = existing.issuedAt;
      _expiresAt = existing.expiresAt;
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isIssued}) async {
    final now = DateTime.now();
    final firstDate = isIssued
        ? DateTime(1990)
        : (_issuedAt?.add(const Duration(days: 1)) ?? DateTime(1990));
    final picked = await showDatePicker(
      context: context,
      initialDate: (isIssued ? _issuedAt : _expiresAt) ?? now,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) return;
    setState(() {
      if (isIssued) {
        _issuedAt = picked;
        if (_expiresAt != null && !_expiresAt!.isAfter(picked)) {
          _expiresAt = null;
        }
      } else {
        _expiresAt = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repository = context.read<LicenseRepository>();
    final existing = widget.existing;
    try {
      if (existing == null) {
        await repository.create(
          License(
            id: '',
            clientId: widget.clientId,
            number: _numberController.text.trim(),
            type: _type,
            issuedAt: _issuedAt!,
            expiresAt: _expiresAt!,
          ),
        );
      } else {
        await repository.update(
          existing.copyWith(
            number: _numberController.text.trim(),
            type: _type,
            issuedAt: _issuedAt,
            expiresAt: _expiresAt,
          ),
        );
      }
    } on Exception catch (e) {
      setState(() {
        _numberServerError = e.toString();
        _saving = false;
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Выписать лицензию' : 'Изменить лицензию'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _numberController,
              decoration: InputDecoration(
                labelText: 'Номер лицензии',
                border: const OutlineInputBorder(),
                errorText: _numberServerError,
              ),
              validator: Validators.combine([
                Validators.required(),
                Validators.lengthRange(3, 50),
              ]),
              onChanged: (_) {
                if (_numberServerError != null) {
                  setState(() => _numberServerError = null);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Тип',
                border: OutlineInputBorder(),
              ),
              items: License.typeLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? 'other'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_issuedAt == null ? 'Дата выдачи' : _formatDate(_issuedAt!)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(isIssued: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_expiresAt == null ? 'Действует до' : _formatDate(_expiresAt!)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(isIssued: false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: (_issuedAt == null || _expiresAt == null || _saving)
              ? null
              : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
