import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/database.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import 'category_edit_sheet.dart';

/// The category list: add, rename, and change how one looks. Subcategories sit
/// under their parent, because the two-level structure is the whole point of
/// having them (plan/01-features.md).
///
/// Nothing here deletes. A category with transactions written against it
/// cannot simply vanish, and deciding what happens to those transactions is a
/// separate piece of work, not a trash icon.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        actions: [
          IconButton(
            tooltip: 'Kategori baru',
            icon: const Icon(Icons.add),
            onPressed: () => _edit(context, kind: 'expense'),
          ),
          const SizedBox(width: WudgetTokens.space1),
        ],
      ),
      body: StreamBuilder<List<Category>>(
        stream: ref.watch(categoriesRepositoryProvider).watchAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final children = <String, List<Category>>{};
          for (final c in all.where((c) => c.parentId != null)) {
            children.putIfAbsent(c.parentId!, () => []).add(c);
          }

          Widget section(String kind, String label) {
            final parents = all.where((c) => c.kind == kind && c.parentId == null).toList();
            if (parents.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionLabel(label),
                CardGroup(
                  children: [
                    for (final parent in parents)
                      _CategoryRowTile(
                        category: parent,
                        subcategories: children[parent.id] ?? const [],
                        onEdit: (c) => _edit(context, existing: c),
                        onAddChild: (c) => _edit(context, parent: c),
                      ),
                  ],
                ),
                const SizedBox(height: WudgetTokens.space5),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              WudgetTokens.space4,
              0,
              WudgetTokens.space4,
              WudgetTokens.space6,
            ),
            children: [
              section('expense', 'Pengeluaran'),
              section('income', 'Pemasukan'),
              WudgetCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: tokens.ink2),
                    const SizedBox(width: WudgetTokens.space3),
                    Expanded(
                      child: Text(
                        'Ketuk kategori untuk ubah nama, ikon, atau warnanya. '
                        'Catatan lama ikut berubah, karena yang tersimpan kategorinya, bukan namanya.',
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(
    BuildContext context, {
    Category? existing,
    Category? parent,
    String kind = 'expense',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryEditSheet(existing: existing, parent: parent, kind: kind),
    );
  }
}

class _CategoryRowTile extends StatelessWidget {
  const _CategoryRowTile({
    required this.category,
    required this.subcategories,
    required this.onEdit,
    required this.onAddChild,
  });
  final Category category;
  final List<Category> subcategories;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onAddChild;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<WudgetTokens>()!;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardRow(
          leading: IconChip(
            icon: categoryIcon(category.iconKey),
            background: tokens.tintFor(category.hueIndex),
            foreground: tokens.inkFor(category.hueIndex),
          ),
          title: category.name,
          subtitle: subcategories.isEmpty
              ? null
              : subcategories.map((c) => c.name).join(', '),
          trailing: IconButton(
            tooltip: 'Tambah sub-kategori',
            icon: Icon(Icons.add, size: 20, color: tokens.ink2),
            onPressed: () => onAddChild(category),
          ),
          onTap: () => onEdit(category),
        ),
        // Subcategories are named on the parent's detail line rather than
        // given rows of their own: they are a refinement of one category, and
        // a flat list of thirty rows would hide that.
        if (subcategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              64,
              0,
              WudgetTokens.space3,
              WudgetTokens.space2,
            ),
            child: Wrap(
              spacing: WudgetTokens.space2,
              runSpacing: WudgetTokens.space2,
              children: [
                for (final child in subcategories)
                  ActionChip(
                    label: Text(child.name, style: text.labelSmall),
                    onPressed: () => onEdit(child),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
