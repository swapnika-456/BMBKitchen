import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_skeleton.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../models/payment.dart';
import '../../../services/api/payment_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

class PaymentDetailSheet extends ConsumerStatefulWidget {
  final String paymentId;

  const PaymentDetailSheet({super.key, required this.paymentId});

  static Future<void> show(BuildContext context, String paymentId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentDetailSheet(paymentId: paymentId),
    );
  }

  @override
  ConsumerState<PaymentDetailSheet> createState() => _PaymentDetailSheetState();
}

class _PaymentDetailSheetState extends ConsumerState<PaymentDetailSheet> {
  PaymentDetail? _payment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = ref.read(authControllerProvider).value ?? await ref.read(authControllerProvider.future);
    if (user == null || user.organizationId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'User session expired';
      });
      return;
    }

    final api = ref.read(paymentApiServiceProvider);
    final response = await api.getPaymentDetail(user.organizationId, widget.paymentId);

    if (mounted) {
      if (response.success && response.data != null) {
        setState(() {
          _payment = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message.isNotEmpty ? response.message : 'Failed to load payment detail';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _payment != null ? 'Payment #${_payment!.orderNo}' : 'Payment Receipt (#128)',
                        style: AppText.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_payment?.billNo != null && _payment!.billNo!.isNotEmpty)
                        Text(
                          'Bill: ${_payment!.billNo}',
                          style: AppText.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.leaf),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            BmbSkeleton(width: double.infinity, height: 60),
            SizedBox(height: 12),
            BmbSkeleton(width: double.infinity, height: 120),
            SizedBox(height: 12),
            BmbSkeleton(width: double.infinity, height: 80),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.chilli),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.chilli)),
              const SizedBox(height: 16),
              BmbButton(label: 'Retry', onPressed: _fetchDetail),
            ],
          ),
        ),
      );
    }

    final p = _payment!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Transaction Info Card
        BmbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.leafSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.paymentMethod.toUpperCase(),
                          style: const TextStyle(color: AppColors.leaf, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.orderType.toUpperCase(),
                          style: const TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (p.paidAt != null)
                    Text(
                      '${p.paidAt!.year}-${p.paidAt!.month.toString().padLeft(2, '0')}-${p.paidAt!.day.toString().padLeft(2, '0')} ${p.paidAt!.hour.toString().padLeft(2, '0')}:${p.paidAt!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                ],
              ),
              if (p.outletName != null && p.outletName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Outlet: ${p.outletName} (${p.outletCode ?? ""})', style: AppText.caption),
              ],
              if (p.tableName != null && p.tableName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Table: ${p.tableName}', style: AppText.caption),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Items Breakdown
        if (p.items.isNotEmpty) ...[
          Text('Ordered Items (${p.items.length})', style: AppText.h3),
          const SizedBox(height: 8),
          BmbCard(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: p.items.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final item = p.items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.quantity}x ${item.name}', style: AppText.body.copyWith(fontWeight: FontWeight.bold)),
                            if (item.notes.isNotEmpty)
                              Text(item.notes, style: AppText.caption.copyWith(color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Text('₹${item.itemTotal.toStringAsFixed(0)}', style: AppText.body.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Financial Breakdown Card
        BmbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBillRow('Subtotal', '₹${p.subTotal.toStringAsFixed(2)}'),
              if (p.discountAmount > 0)
                _buildBillRow('Discount', '-₹${p.discountAmount.toStringAsFixed(2)}', valueColor: AppColors.leaf),
              if (p.taxAmount > 0)
                _buildBillRow('GST (${p.taxPercent.toStringAsFixed(0)}%)', '₹${p.taxAmount.toStringAsFixed(2)}'),
              const Divider(height: 16),
              _buildBillRow('Grand Total', '₹${p.grandTotal.toStringAsFixed(2)}', isBold: true, valueColor: AppColors.tandoor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppColors.ink)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor ?? AppColors.ink)),
        ],
      ),
    );
  }
}
