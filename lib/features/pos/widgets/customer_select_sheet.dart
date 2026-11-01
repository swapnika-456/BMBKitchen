import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/paise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../mock/mock_state.dart';
import '../../../models/customer.dart';

class CustomerSelectSheet extends ConsumerStatefulWidget {
  final Customer? selectedCustomer;
  final Function(Customer customer) onSelectCustomer;

  const CustomerSelectSheet({
    super.key,
    this.selectedCustomer,
    required this.onSelectCustomer,
  });

  @override
  ConsumerState<CustomerSelectSheet> createState() =>
      _CustomerSelectSheetState();
}

class _CustomerSelectSheetState extends ConsumerState<CustomerSelectSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCreatingNew = false;

  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newPhoneController = TextEditingController();
  final TextEditingController _newAddrController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _newNameController.dispose();
    _newPhoneController.dispose();
    _newAddrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bmbState = ref.watch(bmbStateProvider);
    final query = _searchController.text.trim().toLowerCase();

    final filteredCustomers = bmbState.customers.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) || c.phone.contains(query);
    }).toList();

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.s20,
        right: AppSpacing.s20,
        top: AppSpacing.s16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AppSpacing.gapH16,

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isCreatingNew ? 'Add New Customer' : 'Select Customer',
                style: AppText.h2,
              ),
              IconButton(
                icon: Icon(
                  _isCreatingNew
                      ? Icons.close
                      : Icons.person_add_alt_1_outlined,
                ),
                tooltip: _isCreatingNew ? 'Cancel' : 'New Customer',
                onPressed: () {
                  setState(() => _isCreatingNew = !_isCreatingNew);
                },
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.line),

          if (_isCreatingNew) ...[
            TextField(
              controller: _newNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Full Name *',
                hintText: 'e.g. Meenakshi Sundaram',
              ),
            ),
            AppSpacing.gapH12,
            TextField(
              controller: _newPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (10 digits) *',
                hintText: 'e.g. 9840112345',
              ),
            ),
            AppSpacing.gapH12,
            TextField(
              controller: _newAddrController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address (Optional)',
                hintText: 'e.g. 14, 2nd Cross, Anna Nagar',
              ),
            ),
            AppSpacing.gapH20,
            BmbButton.primary(
              label: 'Save & Attach Customer',
              icon: const Icon(Icons.check, size: 18),
              onPressed: () {
                final name = _newNameController.text.trim();
                final phone = _newPhoneController.text.trim();
                if (name.isEmpty || phone.isEmpty) return;

                final newCustomer = Customer(
                  id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  phone: phone,
                  email: '',
                  addr: _newAddrController.text.trim(),
                  visits: 1,
                  spend: const Paise(0),
                  points: 0,
                  since: DateTime.now().toIso8601String().split('T').first,
                );

                // Add to state
                ref.read(bmbStateProvider.notifier).saveCustomer(newCustomer);
                widget.onSelectCustomer(newCustomer);
                Navigator.of(context).pop();
              },
            ),
          ] else ...[
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by phone number or name...',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.muted,
                ),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.paper,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.input),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.input),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
              ),
            ),
            AppSpacing.gapH16,
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: filteredCustomers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s24),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.person_search_outlined,
                              size: 40,
                              color: AppColors.muted,
                            ),
                            AppSpacing.gapH8,
                            Text(
                              'No customer found matching "$query"',
                              style: AppText.bodyMedium,
                            ),
                            AppSpacing.gapH12,
                            BmbButton.outline(
                              label: 'Create New Customer',
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                if (RegExp(r'^\d+$').hasMatch(query)) {
                                  _newPhoneController.text = query;
                                } else {
                                  _newNameController.text = query;
                                }
                                setState(() => _isCreatingNew = true);
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final cust = filteredCustomers[index];
                        final isSelected =
                            widget.selectedCustomer?.id == cust.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              widget.onSelectCustomer(cust);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            child: BmbCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              backgroundColor: isSelected
                                  ? AppColors.tandoorSoft
                                  : AppColors.card,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.tandoor
                                        .withValues(alpha: 0.15),
                                    child: Text(
                                      cust.name.isNotEmpty
                                          ? cust.name[0].toUpperCase()
                                          : 'C',
                                      style: AppText.h3.copyWith(
                                        color: AppColors.tandoor,
                                      ),
                                    ),
                                  ),
                                  AppSpacing.gapW12,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cust.name,
                                          style: AppText.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        AppSpacing.gapH4,
                                        Text(
                                          cust.phone,
                                          style: AppText.caption.copyWith(
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      BmbTag(
                                        label: '${cust.points} pts',
                                        variant: BmbTagVariant.amber,
                                        icon: const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: AppColors.amber,
                                        ),
                                      ),
                                      AppSpacing.gapH4,
                                      Text(
                                        '${cust.visits} visits · ${cust.spend.inr0}',
                                        style: AppText.caption.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
