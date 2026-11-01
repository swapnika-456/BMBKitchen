import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../models/order.dart';
import '../../pos/controllers/pos_order_controller.dart';

class OrderDetailSheet extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailSheet({super.key, required this.orderId});

  static Future<void> show(BuildContext context, String orderId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderDetailSheet(orderId: orderId),
    );
  }

  @override
  ConsumerState<OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends ConsumerState<OrderDetailSheet> {
  Order? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ref.read(activeOrdersProvider.notifier).getOrder(widget.orderId);
    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _order = res.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res.message.isNotEmpty ? res.message : 'Failed to load order details';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle & close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppColors.tandoor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      _order != null ? 'Order ${_order!.orderNo}' : 'Order Details (#46)',
                      style: AppText.h3,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.chilli),
                              ),
                              const SizedBox(height: 16),
                              BmbButton(label: 'Retry', onPressed: _loadOrder),
                            ],
                          ),
                        ),
                      )
                    : _buildContent(_order!),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Order order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order.orderNo}', style: AppText.h3),
                    Text(
                      '₹${order.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.tandoor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildChip(order.orderType.toUpperCase(), AppColors.inputFill, AppColors.ink),
                    _buildStatusChip(order.orderStatus),
                    _buildPaymentStatusChip(order.paymentStatus),
                    if (order.tableName != null && order.tableName!.isNotEmpty)
                      _buildChip('Table: ${order.tableName}', AppColors.blueSoft, AppColors.blue),
                  ],
                ),
                if (order.billNo != null && order.billNo!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Bill No: ${order.billNo}', style: AppText.caption.copyWith(fontWeight: FontWeight.bold)),
                ],
                if (order.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text('Created: ${order.createdAt!.toLocal().toString().split('.')[0]}',
                      style: AppText.caption.copyWith(color: AppColors.muted)),
                ],
                if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Payment Method: ${order.paymentMethod!.toUpperCase()}',
                      style: AppText.caption.copyWith(color: AppColors.muted)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Items section
          Text('Items (${order.items.length})', style: AppText.h3),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final item = order.items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                            if (item.notes.isNotEmpty)
                              Text('Note: ${item.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.muted)),
                            const SizedBox(height: 4),
                            _buildItemStatusChip(item.status),
                          ],
                        ),
                      ),
                      Text('₹${item.itemTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Bill calculations breakdown
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal', '₹${order.subTotal.toStringAsFixed(2)}'),
                if (order.serviceChargeAmount > 0)
                  _buildSummaryRow('Service Charge', '₹${order.serviceChargeAmount.toStringAsFixed(2)}'),
                if (order.taxAmount > 0)
                  _buildSummaryRow('Tax (${order.taxPercent}%)', '₹${order.taxAmount.toStringAsFixed(2)}'),
                if (order.discountAmount > 0)
                  _buildSummaryRow('Total Discounts', '-₹${order.discountAmount.toStringAsFixed(2)}', color: AppColors.leaf),
                const Divider(),
                _buildSummaryRow('Grand Total', '₹${order.grandTotal.toStringAsFixed(2)}', isBold: true, color: AppColors.tandoor),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppColors.ink)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppColors.ink)),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = AppColors.inputFill;
    Color text = AppColors.ink;
    switch (status.toLowerCase()) {
      case 'active':
        bg = AppColors.tandoorSoft;
        text = AppColors.tandoor;
        break;
      case 'completed':
        bg = AppColors.leafSoft;
        text = AppColors.leaf;
        break;
      case 'cancelled':
        bg = AppColors.chilliSoft;
        text = AppColors.chilli;
        break;
    }
    return _buildChip(status.toUpperCase(), bg, text);
  }

  Widget _buildPaymentStatusChip(String status) {
    Color bg = AppColors.inputFill;
    Color text = AppColors.ink;
    switch (status.toLowerCase()) {
      case 'paid':
        bg = AppColors.leafSoft;
        text = AppColors.leaf;
        break;
      case 'pending':
        bg = AppColors.amberSoft;
        text = AppColors.amber;
        break;
      case 'partially_paid':
        bg = AppColors.amberSoft;
        text = AppColors.amber;
        break;
    }
    return _buildChip(status.toUpperCase(), bg, text);
  }

  Widget _buildItemStatusChip(String status) {
    Color bg = AppColors.inputFill;
    Color text = AppColors.ink;
    switch (status.toLowerCase()) {
      case 'in_queue':
        bg = AppColors.amberSoft;
        text = AppColors.amber;
        break;
      case 'preparing':
        bg = AppColors.tandoorSoft;
        text = AppColors.tandoor;
        break;
      case 'ready':
        bg = AppColors.blueSoft;
        text = AppColors.blue;
        break;
      case 'served':
        bg = AppColors.leafSoft;
        text = AppColors.leaf;
        break;
      case 'cancelled':
        bg = AppColors.chilliSoft;
        text = AppColors.chilli;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
