import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/spacing.dart';

class LifecycleItem<T> {
  final T data;
  final String title;
  final String subtitle;
  final bool isActive;

  LifecycleItem({
    required this.data,
    required this.title,
    required this.subtitle,
    required this.isActive,
  });
}

class LifecycleListView<T> extends StatelessWidget {
  final String title;
  final List<LifecycleItem<T>> items;
  final bool showInactive;
  final VoidCallback onToggleView;
  final VoidCallback onCreate;
  final void Function(T item) onEdit;
  final void Function(T item) onDeactivate;
  final void Function(T item) onRestore;
  final void Function(T item) onHardDelete;
  final bool canHardDelete;

  const LifecycleListView({
    super.key,
    required this.title,
    required this.items,
    required this.showInactive,
    required this.onToggleView,
    required this.onCreate,
    required this.onEdit,
    required this.onDeactivate,
    required this.onRestore,
    required this.onHardDelete,
    this.canHardDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            Text(
              showInactive ? 'Inactive $title' : 'Active $title',
              style: AppText.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: onToggleView,
                  child: Text(showInactive ? 'View Active' : 'View Inactive'),
                ),
                ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('New $title'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tandoor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        AppSpacing.gapHMd,
        Expanded(
          child: items.isEmpty
              ? Center(child: Text('No items found.', style: AppText.body))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.title, style: AppText.bodyStrong),
                      subtitle: Text(item.subtitle, style: AppText.caption),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.isActive)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => onEdit(item.data),
                              tooltip: 'Edit',
                            ),
                          if (item.isActive)
                            IconButton(
                              icon: const Icon(
                                Icons.block,
                                size: 20,
                                color: AppColors.chilli,
                              ),
                              onPressed: () => onDeactivate(item.data),
                              tooltip: 'Deactivate',
                            ),
                          if (!item.isActive)
                            IconButton(
                              icon: const Icon(
                                Icons.restore,
                                size: 20,
                                color: AppColors.leaf,
                              ),
                              onPressed: () => onRestore(item.data),
                              tooltip: 'Restore',
                            ),
                          if (!item.isActive && canHardDelete)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_forever,
                                size: 20,
                                color: AppColors.chilli,
                              ),
                              onPressed: () => onHardDelete(item.data),
                              tooltip: 'Permanently Delete',
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
