import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../data/database.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

const _uuid = Uuid();

/// Create or rename a category. One sheet for both, because they ask for the
/// same three things: what it is called, what it looks like, and which colour
/// carries it everywhere else in the app.
///
/// Returns the category's id on save, so the capture sheet can select the
/// category the user just created instead of making them find it.
class CategoryEditSheet extends ConsumerStatefulWidget {
  const CategoryEditSheet({
    super.key,
    this.existing,
    this.kind = 'expense',
    this.parent,
  });

  /// Null to create, a row to edit.
  final Category? existing;

  /// Which side of the ledger a new category belongs to. Ignored when
  /// editing, since moving a category between expense and income would
  /// re-sign every posting already written against it.
  final String kind;

  /// When set, the new category is created as a child of this one: the second
  /// of the two levels plan/01-features.md allows.
  final Category? parent;

  @override
  ConsumerState<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<CategoryEditSheet> {
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late String _iconKey = widget.existing?.iconKey ?? widget.parent?.iconKey ?? 'category';
  late int _hueIndex = widget.existing?.hueIndex ?? widget.parent?.hueIndex ?? 0;
  late bool _asSubcategory = widget.parent != null;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (!_isEdit && widget.parent == null) {
      // Spread new categories across the eight hues instead of stacking every
      // one on the first, which would make the ranked list unreadable.
      ref.read(categoriesRepositoryProvider).watchAll().first.then((all) {
        if (!mounted) return;
        setState(() => _hueIndex = all.length % 8);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);

    final repo = ref.read(categoriesRepositoryProvider);
    String id;
    if (_isEdit) {
      id = widget.existing!.id;
      await repo.rename(id, name);
      await repo.setAppearance(id, iconKey: _iconKey, hueIndex: _hueIndex);
    } else {
      id = await repo.create(
        id: _uuid.v4(),
        name: name,
        kind: widget.parent?.kind ?? widget.kind,
        iconKey: _iconKey,
        hueIndex: _hueIndex,
        parentId: _asSubcategory ? widget.parent?.id : null,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;
    final parent = widget.parent;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: WudgetTokens.space4,
        right: WudgetTokens.space4,
        top: WudgetTokens.space4,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? 'Ubah kategori' : 'Kategori baru',
                style: text.titleLarge,
              ),
              const SizedBox(height: WudgetTokens.space4),
              Row(
                children: [
                  // The chip previews the choice live, so the icon and hue
                  // pickers below are read as "this is what it will look like"
                  // rather than two unrelated grids.
                  IconChip(
                    icon: categoryIcon(_iconKey),
                    background: tokens.tintFor(_hueIndex),
                    foreground: tokens.inkFor(_hueIndex),
                    size: WudgetTokens.categoryTile,
                  ),
                  const SizedBox(width: WudgetTokens.space3),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: !_isEdit,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Nama kategori'),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _save(),
                    ),
                  ),
                ],
              ),
              if (parent != null && !_isEdit) ...[
                const SizedBox(height: WudgetTokens.space3),
                SwitchListTile.adaptive(
                  value: _asSubcategory,
                  onChanged: (v) => setState(() => _asSubcategory = v),
                  contentPadding: EdgeInsets.zero,
                  title: Text('Sub dari ${parent.name}', style: text.titleSmall),
                  subtitle: Text(
                    'Belanjanya tetap dihitung sebagai ${parent.name}',
                    style: text.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: WudgetTokens.space4),
              const SectionLabel('Ikon'),
              _IconPicker(
                selected: _iconKey,
                hueIndex: _hueIndex,
                onSelected: (key) => setState(() => _iconKey = key),
              ),
              const SizedBox(height: WudgetTokens.space4),
              const SectionLabel('Warna'),
              _HuePicker(
                selected: _hueIndex,
                onSelected: (i) => setState(() => _hueIndex = i),
              ),
              const SizedBox(height: WudgetTokens.space5),
              FilledButton(
                onPressed: _nameController.text.trim().isEmpty || _saving ? null : _save,
                child: Text(_isEdit ? 'Simpan' : 'Tambah kategori'),
              ),
              const SizedBox(height: WudgetTokens.space4),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.selected,
    required this.hueIndex,
    required this.onSelected,
  });
  final String selected;
  final int hueIndex;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Wrap(
      spacing: WudgetTokens.space2,
      runSpacing: WudgetTokens.space2,
      children: [
        for (final key in pickableCategoryIcons)
          Semantics(
            selected: key == selected,
            button: true,
            label: key,
            excludeSemantics: true,
            child: Material(
              color: key == selected ? tokens.tintFor(hueIndex) : tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(WudgetTokens.radiusChip),
              child: InkWell(
                onTap: () => onSelected(key),
                borderRadius: BorderRadius.circular(WudgetTokens.radiusChip),
                child: Container(
                  width: WudgetTokens.minTapTarget,
                  height: WudgetTokens.minTapTarget,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(WudgetTokens.radiusChip),
                    border: Border.all(
                      color: key == selected ? tokens.hueFor(hueIndex) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    categoryIcon(key),
                    size: 20,
                    color: key == selected ? tokens.inkFor(hueIndex) : tokens.ink2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HuePicker extends StatelessWidget {
  const _HuePicker({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    return Row(
      children: [
        for (var i = 0; i < tokens.categoryHues.length; i++) ...[
          if (i > 0) const SizedBox(width: WudgetTokens.space2),
          Expanded(
            child: Semantics(
              selected: i == selected,
              button: true,
              label: 'Warna ${i + 1}',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onSelected(i),
                borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
                child: Container(
                  height: WudgetTokens.minTapTarget,
                  decoration: BoxDecoration(
                    color: tokens.hueFor(i),
                    borderRadius: BorderRadius.circular(WudgetTokens.radiusControl),
                  ),
                  // A tick, not just a ring: which swatch is chosen cannot be
                  // carried by colour alone when the swatches are the colours.
                  child: i == selected
                      ? Icon(Icons.check, size: 18, color: tokens.tintFor(i))
                      : null,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
