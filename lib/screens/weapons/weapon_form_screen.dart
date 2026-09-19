import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/designer.dart';
import '../../models/manufacturer.dart';
import '../../models/weapon.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/designer_repository.dart';
import '../../repositories/manufacturer_repository.dart';
import '../../repositories/repository_exceptions.dart';
import '../../repositories/weapon_repository.dart';
import '../../utils/validators.dart';
import '../../widgets/entity_form_scaffold.dart';
import '../../widgets/multi_select_field.dart';

class WeaponFormScreen extends StatefulWidget {
  const WeaponFormScreen({super.key, this.id});

  final String? id;
  bool get isEditing => id != null;

  @override
  State<WeaponFormScreen> createState() => _WeaponFormScreenState();
}

class _WeaponFormScreenState extends State<WeaponFormScreen> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _yearController = TextEditingController();
  final _caliberController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockTotalController = TextEditingController();
  final _stockAvailableController = TextEditingController();

  List<Manufacturer> _manufacturers = [];
  List<Category> _categories = [];
  List<Designer> _designers = [];
  String? _manufacturerId;
  List<String> _categoryIds = [];
  List<String> _designerIds = [];

  bool _loading = true;
  bool _dirty = false;
  String? _skuServerError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _yearController.dispose();
    _caliberController.dispose();
    _priceController.dispose();
    _stockTotalController.dispose();
    _stockAvailableController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final manufacturerRepository = context.read<ManufacturerRepository>();
    final categoryRepository = context.read<CategoryRepository>();
    final designerRepository = context.read<DesignerRepository>();
    final weaponRepository = context.read<WeaponRepository>();

    final manufacturers = await manufacturerRepository.listAll();
    final categories = await categoryRepository.listAll();
    final designers = await designerRepository.listAll();
    final weapon = widget.isEditing
        ? await weaponRepository.findById(widget.id!)
        : null;
    if (!mounted) return;
    setState(() {
      _manufacturers = manufacturers;
      _categories = categories;
      _designers = designers;
      if (weapon != null) {
        _nameController.text = weapon.name;
        _skuController.text = weapon.sku;
        _yearController.text = '${weapon.year}';
        _caliberController.text = weapon.caliber;
        _priceController.text = '${weapon.price}';
        _stockTotalController.text = '${weapon.stockTotal}';
        _stockAvailableController.text = '${weapon.stockAvailable}';
        _manufacturerId = weapon.manufacturerId;
        _categoryIds = [...weapon.categoryIds];
        _designerIds = [...weapon.designerIds];
      }
      _loading = false;
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _handleSubmit() async {
    final draft = Weapon(
      id: widget.id ?? '',
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      caliber: _caliberController.text.trim(),
      manufacturerId: _manufacturerId!,
      categoryIds: _categoryIds,
      designerIds: _designerIds,
      price: int.parse(_priceController.text.trim()),
      stockTotal: int.parse(_stockTotalController.text.trim()),
      stockAvailable: int.parse(_stockAvailableController.text.trim()),
    );
    final repository = context.read<WeaponRepository>();
    try {
      if (widget.isEditing) {
        await repository.update(draft);
      } else {
        await repository.create(draft);
      }
    } on UniqueConstraintException catch (e) {
      setState(() => _skuServerError = e.message);
      return;
    }
    if (!mounted) return;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Изменить оружие' : 'Новое оружие'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return EntityFormScaffold(
      title: widget.isEditing ? 'Изменить оружие' : 'Новое оружие',
      isDirty: _dirty,
      onSave: _handleSubmit,
      fields: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
          ),
          validator: Validators.combine([
            Validators.required(),
            Validators.maxLength(120),
          ]),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _skuController,
          decoration: InputDecoration(
            labelText: 'Артикул (SKU)',
            border: const OutlineInputBorder(),
            errorText: _skuServerError,
          ),
          validator: Validators.combine([
            Validators.required(),
            Validators.lengthRange(3, 40),
          ]),
          onChanged: (_) {
            if (_skuServerError != null) setState(() => _skuServerError = null);
            _markDirty();
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final year = TextFormField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Год выпуска',
                border: OutlineInputBorder(),
              ),
              validator: Validators.intRange(min: 1870, max: 2100),
              onChanged: (_) => _markDirty(),
            );
            final caliber = TextFormField(
              controller: _caliberController,
              decoration: const InputDecoration(
                labelText: 'Калибр',
                border: OutlineInputBorder(),
              ),
              validator: Validators.combine([
                Validators.required(),
                Validators.maxLength(30),
              ]),
              onChanged: (_) => _markDirty(),
            );
            if (constraints.maxWidth < 360) {
              return Column(
                children: [year, const SizedBox(height: 16), caliber],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: year),
                const SizedBox(width: 16),
                Expanded(child: caliber),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _manufacturerId,
          decoration: const InputDecoration(
            labelText: 'Производитель',
            border: OutlineInputBorder(),
          ),
          items: _manufacturers
              .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
              .toList(),
          onChanged: (value) {
            setState(() => _manufacturerId = value);
            _markDirty();
          },
          validator: (value) => value == null ? 'Выберите производителя' : null,
        ),
        const SizedBox(height: 16),
        MultiSelectField(
          label: 'Категории',
          options: [for (final c in _categories) (c.id, c.name)],
          initialValue: _categoryIds,
          validator: Validators.nonEmptySelection,
          onChanged: (value) {
            _categoryIds = value;
            _markDirty();
          },
        ),
        const SizedBox(height: 16),
        MultiSelectField(
          label: 'Конструкторы',
          options: [for (final d in _designers) (d.id, d.fullName)],
          initialValue: _designerIds,
          validator: Validators.nonEmptySelection,
          onChanged: (value) {
            _designerIds = value;
            _markDirty();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Цена, ₽',
            border: OutlineInputBorder(),
          ),
          validator: Validators.positiveInt(),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stockTotal = TextFormField(
              controller: _stockTotalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Всего на складе',
                border: OutlineInputBorder(),
              ),
              validator: Validators.positiveInt(),
              onChanged: (_) => _markDirty(),
            );
            final stockAvailable = TextFormField(
              controller: _stockAvailableController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Доступно на складе',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final n = int.tryParse(value?.trim() ?? '');
                if (n == null || n < 0) return 'Введите неотрицательное число';
                final total = int.tryParse(_stockTotalController.text.trim());
                if (total != null && n > total) {
                  return 'Не больше остатка «Всего на складе» ($total)';
                }
                return null;
              },
              onChanged: (_) => _markDirty(),
            );
            if (constraints.maxWidth < 360) {
              return Column(
                children: [
                  stockTotal,
                  const SizedBox(height: 16),
                  stockAvailable,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: stockTotal),
                const SizedBox(width: 16),
                Expanded(child: stockAvailable),
              ],
            );
          },
        ),
      ],
    );
  }
}
