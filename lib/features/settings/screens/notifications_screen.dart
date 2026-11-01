import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/bmb_button.dart';
import '../../../core/widgets/bmb_card.dart';
import '../../../core/widgets/bmb_empty_state.dart';
import '../../../core/widgets/bmb_screen_header.dart';
import '../../../models/app_notification.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/controllers/notification_controller.dart';

const List<String> kNotificationEventKeys = [
  'all',
  'billShare',
  'orderReady',
  'lowStock',
  'dayClosing',
  'newOnline',
  'offerBlast',
  'general',
];

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final isPrivileged = user != null &&
        (user.role == 'owner' || user.role == 'admin' || user.role == 'cto');

    final notifAsync = ref.watch(notificationControllerProvider);
    final notifier = ref.read(notificationControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: notifAsync.when(
        loading: () => _buildLoadingSkeleton(),
        error: (err, stack) => _buildErrorState(err.toString(), notifier),
        data: (notifState) {
          final displayed = notifState.displayedNotifications;
          final unreadCount = notifState.unreadCount;

          return RefreshIndicator(
            color: AppColors.tandoor,
            onRefresh: () => notifier.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Gap.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Screen Header
                  BmbScreenHeader(
                    title: 'Notifications',
                    subtitle: unreadCount > 0
                        ? '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}'
                        : 'System alerts and messages',
                    trailing: isPrivileged
                        ? SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(
                                value: 0,
                                label: Text('Inbox'),
                                icon: Icon(Icons.inbox_outlined, size: 16),
                              ),
                              ButtonSegment(
                                value: 1,
                                label: Text('Settings'),
                                icon: Icon(Icons.settings_outlined, size: 16),
                              ),
                            ],
                            selected: {notifState.activeTab},
                            onSelectionChanged: (val) {
                              notifier.setActiveTab(val.first);
                            },
                          )
                        : null,
                  ),
                  const SizedBox(height: Gap.md),

                  // Messages banners
                  if (notifState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tandoorSoft,
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        border: Border.all(
                          color: AppColors.tandoor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 18,
                            color: AppColors.tandoor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notifState.errorMessage!,
                              style: AppText.caption.copyWith(
                                color: AppColors.tandoor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                  ],

                  if (notifState.successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.leafSoft,
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        border: Border.all(
                          color: AppColors.leaf.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: AppColors.leaf,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notifState.successMessage!,
                              style: AppText.caption.copyWith(
                                color: AppColors.leaf,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                  ],

                  // Tab View
                  if (notifState.activeTab == 0 || !isPrivileged)
                    _buildInboxTab(
                      context,
                      notifState,
                      displayed,
                      notifier,
                      user?.id ?? '',
                    )
                  else
                    _buildSettingsTab(context, notifState, notifier),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // INBOX TAB
  // ===========================================================================

  Widget _buildInboxTab(
    BuildContext context,
    NotificationState state,
    List<AppNotification> displayed,
    NotificationController notifier,
    String currentUserId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter & Search bar
        BmbCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search input
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by title, message, event, entity...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.muted,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            notifier.setSearchQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  filled: true,
                  fillColor: AppColors.inputFill,
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (val) {
                  notifier.setSearchQuery(val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),

              // Filter Controls: Unread Only & Event Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('Unread only'),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: state.unreadOnly
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: state.unreadOnly ? Colors.white : AppColors.ink,
                    ),
                    selected: state.unreadOnly,
                    selectedColor: AppColors.tandoor,
                    backgroundColor: AppColors.inputFill,
                    onSelected: (val) => notifier.setUnreadOnly(val),
                  ),
                  const SizedBox(width: 4),
                  ...kNotificationEventKeys.map((key) {
                    final isSelected =
                        (state.eventFilter == null && key == 'all') ||
                        (state.eventFilter == key);
                    return ChoiceChip(
                      label: Text(_formatEventLabel(key)),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.ink,
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.tandoor,
                      backgroundColor: AppColors.inputFill,
                      onSelected: (_) => notifier.setEventFilter(key),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),

        // Notifications List or Empty state
        if (displayed.isEmpty)
          BmbCard(
            child: Padding(
              padding: const EdgeInsets.all(Gap.xxl),
              child: BmbEmptyState(
                icon: const Icon(
                  Icons.notifications_off_outlined,
                  size: 40,
                  color: AppColors.muted,
                ),
                title: state.unreadOnly
                    ? 'No unread notifications'
                    : 'No notifications found',
                description: state.unreadOnly
                    ? 'All alerts have been read. Switch off "Unread only" to view past history.'
                    : 'No notifications exist in this outlet. System alerts will appear here as orders, low stock, or day closing events trigger.',
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayed.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notif = displayed[index];
              return _buildNotificationCard(
                context,
                notif,
                currentUserId,
                notifier,
              );
            },
          ),
      ],
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notif,
    String currentUserId,
    NotificationController notifier,
  ) {
    final isRead = currentUserId.isNotEmpty
        ? notif.isReadBy(currentUserId)
        : notif.read;
    final relativeTime = _formatRelativeTime(notif.createdAt);

    return BmbCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        notifier.viewAndMarkRead(notif);
        _showNotificationDetail(context, notif);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Unread indicator, Title, Relative Time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isRead) ...[
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.tandoor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  notif.title.isNotEmpty
                      ? notif.title
                      : _formatEventLabel(notif.eventKey),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (relativeTime.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  relativeTime,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Message Body
          Text(
            notif.message,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: isRead ? AppColors.muted : AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),

          // Chips & Entity Footer
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildEventBadge(notif.eventKey),
              if (notif.relatedEntityType != null &&
                  notif.relatedEntityType!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    '${notif.relatedEntityType}${notif.relatedEntityId != null ? ' (#${notif.relatedEntityId})' : ''}',
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationDetail(
    BuildContext context,
    AppNotification notif,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notif.title.isNotEmpty
                          ? notif.title
                          : _formatEventLabel(notif.eventKey),
                      style: AppText.h3,
                    ),
                  ),
                  _buildEventBadge(notif.eventKey),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  notif.message,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),

              if (notif.relatedEntityType != null &&
                  notif.relatedEntityType!.isNotEmpty)
                _buildDetailRow('Related Entity', notif.relatedEntityType!),
              if (notif.relatedEntityId != null &&
                  notif.relatedEntityId!.isNotEmpty)
                _buildDetailRow('Entity ID', notif.relatedEntityId!),
              if (notif.createdAt != null)
                _buildDetailRow(
                  'Created At',
                  notif.createdAt!.toIso8601String().substring(0, 16),
                ),
              _buildDetailRow(
                'Read Count',
                '${notif.readBy.length} user(s)',
              ),
              const SizedBox(height: 20),

              BmbButton(
                label: 'Close',
                variant: BmbButtonVariant.outline,
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SETTINGS TAB
  // ===========================================================================

  Widget _buildSettingsTab(
    BuildContext context,
    NotificationState state,
    NotificationController notifier,
  ) {
    // If settings were not found (404), offer the user to initialize them (#167)
    if (state.settingsNotFound || state.settings == null) {
      return BmbCard(
        padding: const EdgeInsets.all(Gap.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.amberSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 36,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(height: Gap.md),
            Text('Set up notifications', style: AppText.h3),
            const SizedBox(height: Gap.sm),
            const Text(
              'Notification settings have not been initialized for this organization yet. Initialize default settings to enable delivery channels and event triggers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: Gap.lg),
            BmbButton(
              label: state.isSettingUp
                  ? 'Configuring...'
                  : 'Set up notifications',
              icon: const Icon(Icons.check, size: 18),
              variant: BmbButtonVariant.primary,
              onPressed: state.isSettingUp ? null : () => notifier.setupSettings(),
            ),
          ],
        ),
      );
    }

    final settings = state.settings!;
    final channels = settings.channels;
    final events = settings.events;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Integration note banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(AppRadii.input),
            border: Border.all(
              color: AppColors.blue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'These switches control which notifications are enabled. Delivery depends on the integrations connected.',
                  style: AppText.caption.copyWith(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),

        // Delivery Channels Card
        BmbCard(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 20,
                    color: AppColors.tandoor,
                  ),
                  const SizedBox(width: 8),
                  Text('Channels', style: AppText.h3),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Enable or disable message dispatch channels for customer and staff alerts.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const Divider(height: Gap.lg),
              _buildChannelSwitch(
                title: 'WhatsApp',
                subtitle: 'Send transaction and status messages via WhatsApp API',
                icon: Icons.chat_bubble_outline,
                value: channels.whatsapp,
                onChanged: (val) => notifier.updateChannel('whatsapp', val),
              ),
              const Divider(height: 1),
              _buildChannelSwitch(
                title: 'SMS',
                subtitle: 'Send SMS alerts via integrated telecom SMS gateway',
                icon: Icons.sms_outlined,
                value: channels.sms,
                onChanged: (val) => notifier.updateChannel('sms', val),
              ),
              const Divider(height: 1),
              _buildChannelSwitch(
                title: 'Email',
                subtitle: 'Send receipt summaries, invoices, and system alerts via Email',
                icon: Icons.email_outlined,
                value: channels.email,
                onChanged: (val) => notifier.updateChannel('email', val),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),

        // Event Triggers Card
        BmbCard(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bolt_outlined,
                    size: 20,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 8),
                  Text('Event Triggers', style: AppText.h3),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Configure which operational kitchen and POS events fire automated alerts.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const Divider(height: Gap.lg),
              _buildEventSwitch(
                title: 'Bill Share (billShare)',
                subtitle: 'Send receipt or bill copy link when order is billed',
                value: events.billShare,
                onChanged: (val) => notifier.updateEvent('billShare', val),
              ),
              const Divider(height: 1),
              _buildEventSwitch(
                title: 'Order Ready (orderReady)',
                subtitle: 'Notify customer or waiter when kitchen marks order as prepared',
                value: events.orderReady,
                onChanged: (val) => notifier.updateEvent('orderReady', val),
              ),
              const Divider(height: 1),
              _buildEventSwitch(
                title: 'Low Stock Alert (lowStock)',
                subtitle: 'Alert kitchen managers when raw ingredients reach reorder point',
                value: events.lowStock,
                onChanged: (val) => notifier.updateEvent('lowStock', val),
              ),
              const Divider(height: 1),
              _buildEventSwitch(
                title: 'Day Closing Report (dayClosing)',
                subtitle: 'Send day closing summary report with cash breakdown & variance',
                value: events.dayClosing,
                onChanged: (val) => notifier.updateEvent('dayClosing', val),
              ),
              const Divider(height: 1),
              _buildEventSwitch(
                title: 'New Online Order (newOnline)',
                subtitle: 'Instant notification on new Zomato, Swiggy, or web delivery orders',
                value: events.newOnline,
                onChanged: (val) => notifier.updateEvent('newOnline', val),
              ),
              const Divider(height: 1),
              _buildEventSwitch(
                title: 'Offer Blast (offerBlast)',
                subtitle: 'Broadcast promotional marketing campaigns to registered customer loyalty list',
                value: events.offerBlast,
                onChanged: (val) => notifier.updateEvent('offerBlast', val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: value ? AppColors.tandoor : AppColors.muted),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      activeThumbColor: AppColors.tandoor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildEventSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      activeThumbColor: AppColors.tandoor,
      contentPadding: EdgeInsets.zero,
    );
  }

  // ===========================================================================
  // HELPERS & BADGES
  // ===========================================================================

  Widget _buildEventBadge(String eventKey) {
    Color bg;
    Color fg;
    IconData icon;

    switch (eventKey) {
      case 'lowStock':
        bg = AppColors.amberSoft;
        fg = AppColors.amber;
        icon = Icons.inventory_2_outlined;
        break;
      case 'orderReady':
        bg = AppColors.leafSoft;
        fg = AppColors.leaf;
        icon = Icons.check_circle_outline;
        break;
      case 'dayClosing':
        bg = AppColors.plumSoft;
        fg = AppColors.plum;
        icon = Icons.lock_clock_outlined;
        break;
      case 'newOnline':
        bg = AppColors.blueSoft;
        fg = AppColors.blue;
        icon = Icons.language_outlined;
        break;
      case 'billShare':
        bg = const Color(0xFFE0F2F1); // Teal soft
        fg = const Color(0xFF00796B); // Teal dark
        icon = Icons.receipt_long_outlined;
        break;
      case 'offerBlast':
        bg = AppColors.tandoorSoft;
        fg = AppColors.tandoor;
        icon = Icons.local_offer_outlined;
        break;
      default:
        bg = AppColors.inputFill;
        fg = AppColors.muted;
        icon = Icons.notifications_none_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            _formatEventLabel(eventKey),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventLabel(String key) {
    switch (key) {
      case 'all':
        return 'All';
      case 'billShare':
        return 'Bill Share';
      case 'orderReady':
        return 'Order Ready';
      case 'lowStock':
        return 'Low Stock';
      case 'dayClosing':
        return 'Day Closing';
      case 'newOnline':
        return 'New Online';
      case 'offerBlast':
        return 'Offer Blast';
      default:
        return key.isNotEmpty ? key : 'General';
    }
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadingSkeleton() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.tandoor),
    );
  }

  Widget _buildErrorState(String message, NotificationController notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.tandoor),
            const SizedBox(height: Gap.md),
            Text('Failed to load notifications', style: AppText.h3),
            const SizedBox(height: Gap.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: Gap.lg),
            BmbButton(
              label: 'Retry',
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => notifier.refresh(),
            ),
          ],
        ),
      ),
    );
  }
}
