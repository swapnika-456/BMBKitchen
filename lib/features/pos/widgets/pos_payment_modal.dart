import 'package:flutter/material.dart';
import '../../../core/money/paise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_tag.dart';
import '../../../models/payment_record.dart';

class PosPaymentModal extends StatefulWidget {
  final Paise totalDue;
  final String orderTitle;
  final Function(List<PaymentRecord> payments, Paise change) onSettle;

  const PosPaymentModal({
    super.key,
    required this.totalDue,
    required this.orderTitle,
    required this.onSettle,
  });

  @override
  State<PosPaymentModal> createState() => _PosPaymentModalState();
}

class _PosPaymentModalState extends State<PosPaymentModal> {
  PaymentMode _selectedPrimaryMode = PaymentMode.upi;
  final List<PaymentRecord> _splits = [];
  bool _isSplitMode = false;

  // For cash tender calculation
  final TextEditingController _cashTenderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cashTenderController.text = widget.totalDue.toRupees.toInt().toString();
  }

  @override
  void dispose() {
    _cashTenderController.dispose();
    super.dispose();
  }

  Paise get _currentTender {
    final parsed = int.tryParse(_cashTenderController.text.trim()) ?? 0;
    return Paise.fromRupees(parsed);
  }

  Paise get _currentChange {
    if (_currentTender > widget.totalDue) {
      return _currentTender - widget.totalDue;
    }
    return const Paise(0);
  }

  Paise get _totalSplitPaid {
    var sum = const Paise(0);
    for (final s in _splits) {
      sum = sum + s.amount;
    }
    return sum;
  }

  Paise get _splitRemaining {
    if (widget.totalDue > _totalSplitPaid) {
      return widget.totalDue - _totalSplitPaid;
    }
    return const Paise(0);
  }

  void _addSplitLine(PaymentMode mode, Paise amount) {
    if (amount <= const Paise(0)) return;
    setState(() {
      _splits.add(PaymentRecord(mode: mode, amount: amount));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCash = !_isSplitMode && _selectedPrimaryMode == PaymentMode.cash;
    final canSettle =
        !_isSplitMode || (_isSplitMode && _splitRemaining == const Paise(0));

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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Collect Payment', style: AppText.h2),
                  AppSpacing.gapH4,
                  Text(widget.orderTitle, style: AppText.caption),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TOTAL DUE', style: AppText.sectionLabel),
                  Text(
                    widget.totalDue.inr0,
                    style: AppText.h1.copyWith(
                      color: AppColors.tandoor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.line),

          // Single mode vs Split mode toggle
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Single Payment')),
                  selected: !_isSplitMode,
                  onSelected: (_) => setState(() => _isSplitMode = false),
                  selectedColor: AppColors.tandoorSoft,
                  backgroundColor: AppColors.paper,
                  labelStyle: AppText.bodyMedium.copyWith(
                    color: !_isSplitMode ? AppColors.tandoor : AppColors.ink,
                    fontWeight: !_isSplitMode
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.pillRadius,
                    side: BorderSide(
                      color: !_isSplitMode ? AppColors.tandoor : AppColors.line,
                    ),
                  ),
                  showCheckmark: false,
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Split Payment')),
                  selected: _isSplitMode,
                  onSelected: (_) {
                    setState(() {
                      _isSplitMode = true;
                      if (_splits.isEmpty) {
                        // Prepopulate first half in UPI
                        final half = (widget.totalDue / 2)
                            .roundToRupee()
                            .rounded;
                        _splits.add(
                          PaymentRecord(mode: PaymentMode.upi, amount: half),
                        );
                      }
                    });
                  },
                  selectedColor: AppColors.tandoorSoft,
                  backgroundColor: AppColors.paper,
                  labelStyle: AppText.bodyMedium.copyWith(
                    color: _isSplitMode ? AppColors.tandoor : AppColors.ink,
                    fontWeight: _isSplitMode
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.pillRadius,
                    side: BorderSide(
                      color: _isSplitMode ? AppColors.tandoor : AppColors.line,
                    ),
                  ),
                  showCheckmark: false,
                ),
              ),
            ],
          ),
          AppSpacing.gapH20,

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.48,
            ),
            child: SingleChildScrollView(
              child: !_isSplitMode
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT PAYMENT MODE',
                          style: AppText.sectionLabel,
                        ),
                        AppSpacing.gapH12,
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: PaymentMode.values.map((mode) {
                            final isSel = _selectedPrimaryMode == mode;
                            IconData icon;
                            switch (mode) {
                              case PaymentMode.upi:
                                icon = Icons.qr_code_2;
                                break;
                              case PaymentMode.cash:
                                icon = Icons.payments_outlined;
                                break;
                              case PaymentMode.card:
                                icon = Icons.credit_card;
                                break;
                              case PaymentMode.credit:
                                icon = Icons.account_balance_wallet_outlined;
                                break;
                              case PaymentMode.online:
                                icon = Icons.language;
                                break;
                            }

                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedPrimaryMode = mode),
                              borderRadius: BorderRadius.circular(
                                AppRadii.card,
                              ),
                              child: Container(
                                width:
                                    (MediaQuery.of(context).size.width - 64) /
                                    3,
                                constraints: const BoxConstraints(
                                  minWidth: 100,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? AppColors.tandoorSoft
                                      : AppColors.card,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.card,
                                  ),
                                  border: Border.all(
                                    color: isSel
                                        ? AppColors.tandoor
                                        : AppColors.line,
                                    width: isSel ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      icon,
                                      size: 28,
                                      color: isSel
                                          ? AppColors.tandoor
                                          : AppColors.muted,
                                    ),
                                    AppSpacing.gapH8,
                                    Text(
                                      mode.label,
                                      style: AppText.bodyMedium.copyWith(
                                        fontWeight: isSel
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSel
                                            ? AppColors.tandoor
                                            : AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        AppSpacing.gapH20,

                        // Cash Tender and Change Calculator
                        if (isCash) ...[
                          BmbCard(
                            backgroundColor: AppColors.paper,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'CASH TENDERED',
                                      style: AppText.sectionLabel,
                                    ),
                                    if (_currentChange > const Paise(0))
                                      BmbTag(
                                        label: 'Change: ${_currentChange.inr0}',
                                        variant: BmbTagVariant.green,
                                        icon: const Icon(
                                          Icons.currency_rupee,
                                          size: 12,
                                          color: AppColors.leaf,
                                        ),
                                      ),
                                  ],
                                ),
                                AppSpacing.gapH8,
                                TextField(
                                  controller: _cashTenderController,
                                  keyboardType: TextInputType.number,
                                  style: AppText.h2.copyWith(
                                    color: AppColors.ink,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.currency_rupee,
                                      color: AppColors.muted,
                                    ),
                                    hintText: 'Enter cash received',
                                  ),
                                ),
                                AppSpacing.gapH12,
                                Wrap(
                                  spacing: 8,
                                  children:
                                      [
                                            widget.totalDue.toRupees.toInt(),
                                            500,
                                            1000,
                                            2000,
                                          ]
                                          .where(
                                            (amt) =>
                                                amt >=
                                                    widget.totalDue.toRupees
                                                        .toInt() ||
                                                amt ==
                                                    widget.totalDue.toRupees
                                                        .toInt(),
                                          )
                                          .toSet()
                                          .map((amt) {
                                            return ActionChip(
                                              label: Text('₹$amt'),
                                              labelStyle: AppText.bodyMedium
                                                  .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              backgroundColor: AppColors.card,
                                              onPressed: () {
                                                setState(() {
                                                  _cashTenderController.text =
                                                      amt.toString();
                                                });
                                              },
                                            );
                                          })
                                          .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SPLIT ENTRIES', style: AppText.sectionLabel),
                            Text(
                              _splitRemaining == const Paise(0)
                                  ? 'Fully Covered'
                                  : 'Remaining: ${_splitRemaining.inr0}',
                              style: AppText.caption.copyWith(
                                color: _splitRemaining == const Paise(0)
                                    ? AppColors.leaf
                                    : AppColors.chilli,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapH12,

                        // Current split list
                        ..._splits.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final rec = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(
                                AppRadii.card,
                              ),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              children: [
                                BmbTag(
                                  label: rec.mode.label,
                                  variant: BmbTagVariant.blue,
                                ),
                                AppSpacing.gapW12,
                                Expanded(
                                  child: Text(
                                    rec.amount.inr0,
                                    style: AppText.priceBold.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: AppColors.chilli,
                                  ),
                                  onPressed: () {
                                    setState(() => _splits.removeAt(idx));
                                  },
                                ),
                              ],
                            ),
                          );
                        }),

                        if (_splitRemaining > const Paise(0)) ...[
                          AppSpacing.gapH12,
                          Text(
                            'ADD NEXT SPLIT PORTION',
                            style: AppText.sectionLabel,
                          ),
                          AppSpacing.gapH8,
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: PaymentMode.values.map((mode) {
                              return ActionChip(
                                avatar: const Icon(Icons.add, size: 16),
                                label: Text(
                                  '${mode.label} (${_splitRemaining.inr0})',
                                ),
                                onPressed: () {
                                  _addSplitLine(mode, _splitRemaining);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          AppSpacing.gapH24,

          // Settle button
          Row(
            children: [
              Expanded(
                child: BmbButton(
                  label: 'Settle Bill · ${widget.totalDue.inr0}',
                  icon: const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Colors.white,
                  ),
                  variant: BmbButtonVariant.green,
                  size: BmbButtonSize.lg,
                  onPressed: canSettle
                      ? () {
                          List<PaymentRecord> payments;
                          Paise change = const Paise(0);

                          if (!_isSplitMode) {
                            payments = [
                              PaymentRecord(
                                mode: _selectedPrimaryMode,
                                amount: widget.totalDue,
                              ),
                            ];
                            if (_selectedPrimaryMode == PaymentMode.cash) {
                              change = _currentChange;
                            }
                          } else {
                            payments = List.from(_splits);
                          }

                          widget.onSettle(payments, change);
                          Navigator.of(context).pop();
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
