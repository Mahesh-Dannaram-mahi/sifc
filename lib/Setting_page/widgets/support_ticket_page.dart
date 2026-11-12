import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../services/storage_service.dart';
import '../../services/user_service.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';
import 'help_center_page.dart';

// ---------- Ticket Models ----------
class SupportTicket {
  final String id;
  final String ticketNumber;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String subject;
  final String message;
  final String category;
  final String status;
  final String priority;
  final String agent;
  final String team;
  final String slaLevel;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? responseTarget;
  final DateTime? resolutionTarget;
  final List<TicketReply>? replies;

  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.subject,
    required this.message,
    required this.category,
    required this.status,
    required this.priority,
    required this.agent,
    required this.team,
    required this.slaLevel,
    required this.createdAt,
    this.updatedAt,
    this.responseTarget,
    this.resolutionTarget,
    this.replies,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final ticketNumber = json['ticket_number']?.toString() ?? '';
    final rawDescription = json['message'] ?? json['description'] ?? '';
    final createdAtText = json['created_at']?.toString() ?? '';
    final updatedAtText = json['updated_at']?.toString();

    return SupportTicket(
      id: json['id']?.toString() ?? ticketNumber,
      ticketNumber: ticketNumber,
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      subject: json['subject']?.toString() ?? 'Support request',
      message: _plainText(rawDescription.toString()),
      category:
          json['category']?.toString() ??
          json['ticket_type']?.toString() ??
          'general',
      status: _normalizeStatus(json['status']?.toString() ?? 'open'),
      priority: json['priority']?.toString() ?? 'medium',
      agent: json['agent']?.toString() ?? '',
      team: json['team']?.toString() ?? '',
      slaLevel: json['sla_level']?.toString() ?? '',
      createdAt: DateTime.tryParse(createdAtText) ?? DateTime.now(),
      updatedAt: updatedAtText == null
          ? null
          : DateTime.tryParse(updatedAtText),
      responseTarget: DateTime.tryParse(
        json['sla_responsetarget']?.toString() ?? '',
      ),
      resolutionTarget: DateTime.tryParse(
        json['sla_resolutiontarget']?.toString() ?? '',
      ),
      replies: json['replies'] != null
          ? (json['replies'] as List)
                .map((r) => TicketReply.fromJson(r))
                .toList()
          : null,
    );
  }

  static String _normalizeStatus(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('-', ' ');
    switch (normalized) {
      case 'in process':
      case 'in progress':
      case 'progress':
        return 'in_progress';
      case 'pending':
      case 'pending actions':
        return 'pending';
      case 'close':
        return 'closed';
      default:
        return normalized.replaceAll(' ', '_');
    }
  }

  static String _plainText(String value) {
    var text = value
        .replaceAll(
          RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'</p>|</div>|</tr>|</li>|</h[1-6]>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    text = text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .join('\n');

    if (text.length > 1200) {
      return '${text.substring(0, 1200).trim()}...';
    }
    return text;
  }
}

class TicketReply {
  final String id;
  final String message;
  final String senderType;
  final DateTime createdAt;

  TicketReply({
    required this.id,
    required this.message,
    required this.senderType,
    required this.createdAt,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    return TicketReply(
      id: json['id']?.toString() ?? '',
      message: json['message'] ?? '',
      senderType: json['sender_type'] ?? 'support',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// ---------- Ticket Service ----------
class TicketService {
  static Future<String?> resolveUserPhone() async {
    String? phoneNumber = await StorageService.getUserPhone();
    phoneNumber ??= (await SharedPreferences.getInstance()).getString(
      'user_phone',
    );
    phoneNumber ??= await UserService.getUserPhone();
    return phoneNumber?.replaceAll(RegExp(r'\D'), '');
  }

  static Future<List<SupportTicket>> fetchUserTickets(
    String phoneNumber,
  ) async {
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (normalizedPhone.isEmpty) {
      throw Exception('Phone number not found for this account');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/service-desk/user-tickets',
      ).replace(queryParameters: {'phone_number': normalizedPhone}),
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Ticket API failed: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['success'] != true) {
      throw Exception('Ticket API returned unsuccessful response');
    }

    final List<dynamic> ticketsJson = data['data'] ?? data['tickets'] ?? [];
    return ticketsJson
        .map((json) => SupportTicket.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
}

// ---------- Main Support Ticket Page ----------
class SupportTicketPage extends StatefulWidget {
  const SupportTicketPage({super.key});

  @override
  State<SupportTicketPage> createState() => _SupportTicketPageState();
}

class _SupportTicketPageState extends State<SupportTicketPage>
    with SingleTickerProviderStateMixin {
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String? _phoneNumber;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadTickets();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final phoneNumber = await TicketService.resolveUserPhone();
      if (phoneNumber == null || phoneNumber.isEmpty) {
        throw Exception('Phone number not found. Please login again.');
      }

      final tickets = await TicketService.fetchUserTickets(phoneNumber);
      setState(() {
        _phoneNumber = phoneNumber;
        _tickets = tickets;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _tickets = [];
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _animationController.forward();
    }
  }

  List<SupportTicket> get _filteredTickets {
    if (_selectedFilter == 'all') return _tickets;
    return _tickets
        .where((ticket) => ticket.status == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _animationController,
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
            ? _buildErrorState()
            : Column(
                children: [
                  _buildSummaryHeader(),
                  _buildFilterChips(),
                  Expanded(
                    child: _filteredTickets.isEmpty
                        ? _buildEmptyState()
                        : _buildTicketsList(),
                  ),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = context.siporaTheme;
    final avatarSize = ResponsiveConstants.getAvatarSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context) - 2;

    return AppBar(
      backgroundColor: theme.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: theme.border),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: theme.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: iconSize - 7,
                color: theme.textDark,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'My Support Tickets',
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w700,
          color: theme.textDark,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _loadTickets,
          icon: Icon(Icons.refresh_rounded, color: theme.textDark),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    final theme = context.siporaTheme;
    final openCount = _tickets.where((t) => t.status == 'open').length;
    final progressCount = _tickets
        .where((t) => t.status == 'in_progress' || t.status == 'pending')
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.greenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              color: theme.greenDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_tickets.length} tickets',
                  style: TextStyle(
                    fontSize: ResponsiveConstants.getTitleFontSize(context) - 4,
                    fontWeight: FontWeight.w800,
                    color: theme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _phoneNumber == null ? '' : 'Linked to $_phoneNumber',
                  style: TextStyle(
                    fontSize: ResponsiveConstants.getFontSize(context) - 2,
                    color: theme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _buildTinyMetric('Open', openCount),
          const SizedBox(width: 8),
          _buildTinyMetric('Active', progressCount),
        ],
      ),
    );
  }

  Widget _buildTinyMetric(String label, int count) {
    final theme = context.siporaTheme;

    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: theme.textDark,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveConstants.getFontSize(context) - 4,
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All Tickets'),
            const SizedBox(width: 8),
            _buildFilterChip('open', 'Open'),
            const SizedBox(width: 8),
            _buildFilterChip('in_progress', 'In Progress'),
            const SizedBox(width: 8),
            _buildFilterChip('pending', 'Pending'),
            const SizedBox(width: 8),
            _buildFilterChip('resolved', 'Resolved'),
            const SizedBox(width: 8),
            _buildFilterChip('closed', 'Closed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final theme = context.siporaTheme;
    final isSelected = _selectedFilter == value;
    final fontSize = ResponsiveConstants.getFontSize(context) - 1;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: theme.white,
      selectedColor: theme.greenBg,
      labelStyle: TextStyle(
        color: isSelected ? theme.greenDark : theme.textDark,
      ),
      side: BorderSide(color: isSelected ? theme.greenDark : theme.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildLoadingState() {
    final theme = context.siporaTheme;

    return Center(child: CircularProgressIndicator(color: theme.greenDark));
  }

  Widget _buildErrorState() {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(80),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 46,
                color: theme.red,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Could not load tickets',
              style: TextStyle(
                fontSize: ResponsiveConstants.getTitleFontSize(context) - 4,
                fontWeight: FontWeight.w800,
                color: theme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize - 1,
                color: theme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _loadTickets,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.greenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context) - 4;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.greenBg,
                borderRadius: BorderRadius.circular(80),
              ),
              child: Icon(
                Icons.support_agent_rounded,
                size: 48,
                color: theme.greenDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Support Tickets',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: theme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t created any support tickets yet.\nCreate your first ticket to get help.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize - 1,
                color: theme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const HelpCenterPage(),
                  ),
                  (route) => route.isFirst,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.greenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create Support Ticket',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredTickets.length,
      itemBuilder: (context, index) {
        final ticket = _filteredTickets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildTicketCard(ticket),
        );
      },
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context) - 4;

    return Container(
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showTicketDetails(ticket),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Ticket #${ticket.ticketNumber}',
                        style: TextStyle(
                          fontSize: fontSize - 1,
                          fontWeight: FontWeight.w600,
                          color: theme.greenDark,
                        ),
                      ),
                    ),
                    _buildStatusBadge(ticket.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ticket.subject,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: theme.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  ticket.message,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: theme.textMuted,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildInfoChip(
                      Icons.category_outlined,
                      _getCategoryDisplayName(ticket.category),
                    ),
                    _buildInfoChip(
                      Icons.flag_outlined,
                      _titleCase(ticket.priority),
                    ),
                    if (ticket.agent.isNotEmpty)
                      _buildInfoChip(Icons.support_agent_rounded, ticket.agent),
                    _buildInfoChip(
                      Icons.schedule_rounded,
                      _formatDate(ticket.createdAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context) - 3;

    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'open':
        backgroundColor = theme.greenBg;
        textColor = theme.greenDark;
        displayText = 'Open';
        break;
      case 'in_progress':
        backgroundColor = SiporaTheme.goldBg;
        textColor = SiporaTheme.goldText;
        displayText = 'In Progress';
        break;
      case 'pending':
        backgroundColor = SiporaTheme.goldBg;
        textColor = SiporaTheme.goldText;
        displayText = 'Pending';
        break;
      case 'resolved':
        backgroundColor = SiporaTheme.greenBg;
        textColor = theme.greenDark;
        displayText = 'Resolved';
        break;
      case 'closed':
        backgroundColor = theme.border.withValues(alpha: 0.3);
        textColor = theme.textMuted;
        displayText = 'Closed';
        break;
      default:
        backgroundColor = theme.greenBg;
        textColor = theme.greenDark;
        displayText = _titleCase(status);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context) - 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.cream,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.textMuted),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: theme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showTicketDetails(SupportTicket ticket) {
    final theme = context.siporaTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.cream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildSheetHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTicketHeader(ticket),
                    const SizedBox(height: 20),
                    _buildTicketMessages(ticket),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    final theme = context.siporaTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketHeader(SupportTicket ticket) {
    final theme = context.siporaTheme;
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context) - 4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ticket #${ticket.ticketNumber}',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: theme.greenDark,
                ),
              ),
              _buildStatusBadge(ticket.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ticket.subject,
            style: TextStyle(
              fontSize: titleFontSize + 2,
              fontWeight: FontWeight.bold,
              color: theme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.category_outlined,
                _getCategoryDisplayName(ticket.category),
              ),
              _buildInfoChip(Icons.flag_outlined, _titleCase(ticket.priority)),
              if (ticket.agent.isNotEmpty)
                _buildInfoChip(Icons.support_agent_rounded, ticket.agent),
              if (ticket.slaLevel.isNotEmpty)
                _buildInfoChip(
                  Icons.timer_outlined,
                  'SLA ${_titleCase(ticket.slaLevel)}',
                ),
              _buildInfoChip(
                Icons.calendar_today_outlined,
                'Created ${_formatDate(ticket.createdAt)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketMessages(SupportTicket ticket) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context) - 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ticket Details',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: theme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.greenBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: theme.greenDark,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'You',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.textDark,
                      fontSize: fontSize - 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: TextStyle(
                      fontSize: fontSize - 3,
                      color: theme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.message,
                style: TextStyle(
                  fontSize: fontSize - 2,
                  color: theme.textDark,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (ticket.replies != null && ticket.replies!.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...ticket.replies!.map((reply) => _buildReplyMessage(reply)),
        ],
        const SizedBox(height: 12),
        _buildSlaDetails(ticket),
      ],
    );
  }

  Widget _buildSlaDetails(SupportTicket ticket) {
    final theme = context.siporaTheme;

    if (ticket.responseTarget == null &&
        ticket.resolutionTarget == null &&
        ticket.team.isEmpty &&
        ticket.email.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Info',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.textDark,
              fontSize: ResponsiveConstants.getFontSize(context) - 1,
            ),
          ),
          const SizedBox(height: 10),
          if (ticket.email.isNotEmpty)
            _buildDetailRow(Icons.email_outlined, 'Email', ticket.email),
          if (ticket.team.isNotEmpty)
            _buildDetailRow(Icons.groups_outlined, 'Team', ticket.team),
          if (ticket.responseTarget != null)
            _buildDetailRow(
              Icons.av_timer_rounded,
              'Response target',
              _formatFullDate(ticket.responseTarget!),
            ),
          if (ticket.resolutionTarget != null)
            _buildDetailRow(
              Icons.task_alt_rounded,
              'Resolution target',
              _formatFullDate(ticket.resolutionTarget!),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final theme = context.siporaTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context) - 3,
                color: theme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context) - 3,
                color: theme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyMessage(TicketReply reply) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final isSupport = reply.senderType == 'support';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSupport ? theme.greenBg : theme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSupport ? theme.greenDark : theme.greenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSupport ? Icons.support_agent : Icons.person_outline,
                  color: isSupport ? Colors.white : theme.greenDark,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isSupport ? 'Support Team' : 'You',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.textDark,
                  fontSize: fontSize - 1,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(reply.createdAt),
                style: TextStyle(
                  fontSize: fontSize - 3,
                  color: theme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reply.message,
            style: TextStyle(
              fontSize: fontSize - 2,
              color: theme.textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return 'General';
      case 'technical':
        return 'Technical';
      case 'billing':
        return 'Billing';
      case 'feature':
        return 'Feature Request';
      default:
        return _titleCase(category);
    }
  }

  String _titleCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFullDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
