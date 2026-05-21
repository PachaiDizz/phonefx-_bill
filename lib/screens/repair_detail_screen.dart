import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../models/repair_record.dart';
import '../services/pdf_service.dart';
import '../services/database_helper.dart';
import 'add_repair_screen.dart';

class RepairDetailScreen extends StatefulWidget {
  final RepairRecord repair;

  const RepairDetailScreen({super.key, required this.repair});

  @override
  State<RepairDetailScreen> createState() => _RepairDetailScreenState();
}

class _RepairDetailScreenState extends State<RepairDetailScreen> {
  late RepairRecord _repair;

  // Warranty void local state
  late List<String> _selectedVoidConditions;

  // Checklist local state
  // true = pass, false = fail, null = not checked
  late Map<String, bool?> _checklistBefore;
  late Map<String, bool?> _checklistAfter;

  @override
  void initState() {
    super.initState();
    _repair = widget.repair;

    // Load existing warranty void selections (default = all selected)
    if (_repair.warrantyVoidConditions.isEmpty) {
      _selectedVoidConditions = List.from(DeviceIssues.warrantyVoidConditions);
    } else {
      _selectedVoidConditions = List.from(_repair.warrantyVoidConditions);
    }

    // Load existing checklist state
    final checklistItems = DeviceChecklist.getChecklistForDeviceType(
      _repair.deviceType,
    );

    _checklistBefore = {
      for (final item in checklistItems)
        item: _repair.checklistBefore.containsKey(item)
            ? (_repair.checklistBefore[item] == 'pass' ? true : false)
            : null,
    };
    _checklistAfter = {
      for (final item in checklistItems)
        item: _repair.checklistAfter.containsKey(item)
            ? (_repair.checklistAfter[item] == 'pass' ? true : false)
            : null,
    };
  }

  /// Saves warranty void + checklist back to DB
  Future<void> _saveChanges() async {
    final updatedBefore = {
      for (final e in _checklistBefore.entries)
        if (e.value != null) e.key: e.value! ? 'pass' : 'fail',
    };
    final updatedAfter = {
      for (final e in _checklistAfter.entries)
        if (e.value != null) e.key: e.value! ? 'pass' : 'fail',
    };

    final updated = _repair.copyWith(
      warrantyVoidConditions: _selectedVoidConditions,
      checklistBefore: updatedBefore,
      checklistAfter: updatedAfter,
    );

    await DatabaseHelper.instance.updateRepair(updated);
    setState(() => _repair = updated);
  }



  Future<void> _generatePdf(BuildContext context) async {
    await _saveChanges();

    try {
      final file = await PdfService.generatePdf(_repair);

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PDF Generated!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bill for ${_repair.customerName}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                            label: const Text('Close'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Share.shareXFiles([
                                XFile(file.path),
                              ], text: 'PhoneFX+ Bill for ${_repair.customerName}');
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          OpenFilex.open(file.path);
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Open PDF File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(
      symbol: 'RM ',
      decimalDigits: 2,
    );
    final isWarrantyValid = _repair.warrantyExpiryDate.isAfter(DateTime.now());
    final daysLeft = _repair.warrantyExpiryDate
        .difference(DateTime.now())
        .inDays;

    IconData deviceIcon;
    Color deviceColor;
    switch (_repair.deviceType) {
      case 'Phone':
        deviceIcon = Icons.phone_android;
        deviceColor = const Color(0xFF10B981);
        break;
      case 'Laptop':
        deviceIcon = Icons.laptop;
        deviceColor = const Color(0xFF8B5CF6);
        break;
      case 'PC':
        deviceIcon = Icons.desktop_windows;
        deviceColor = const Color(0xFFF97316);
        break;
      default:
        deviceIcon = Icons.devices;
        deviceColor = Colors.grey;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: deviceColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddRepairScreen(repair: _repair),
                    ),
                  ).then((_) => Navigator.pop(context));
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [deviceColor, deviceColor.withValues(alpha: 0.8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                deviceIcon,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _repair.customerName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _repair.deviceType,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _repair.deviceModel,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoCard(
                    title: 'Repair Information',
                    icon: Icons.calendar_today,
                    iconColor: const Color(0xFF2563EB),
                    children: [
                      _buildInfoRow(
                        'Repair Date',
                        dateFormat.format(_repair.repairDate),
                      ),
                      _buildInfoRow(
                        'Created At',
                        dateFormat.format(_repair.createdAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildChecklistCard(
                    title: 'Before Repair Checklist',
                    subtitle: 'Test device condition BEFORE repair',
                    icon: Icons.fact_check_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    checklist: _checklistBefore,
                    onChanged: (item, value) {
                      setState(() => _checklistBefore[item] = value);
                      _saveChanges();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildIssuesCard(_repair),
                  const SizedBox(height: 16),
                  _buildWarrantyCard(isWarrantyValid, daysLeft, dateFormat),
                  const SizedBox(height: 16),
                  _buildWarrantyVoidCard(),
                  const SizedBox(height: 16),
                  _buildChecklistCard(
                    title: 'After Repair Checklist',
                    subtitle: 'Verify device is working AFTER repair',
                    icon: Icons.task_alt,
                    iconColor: const Color(0xFF10B981),
                    checklist: _checklistAfter,
                    onChanged: (item, value) {
                      setState(() => _checklistAfter[item] = value);
                      _saveChanges();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTotalAmountCard(currencyFormat),
                  const SizedBox(height: 24),
                  _buildGeneratePdfButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // REUSABLE CARD WRAPPER

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ISSUES CARD

  Widget _buildIssuesCard(RepairRecord repair) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.build,
                    color: Color(0xFFF97316),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Issues Repaired',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...repair.issues.map(
              (issue) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[100]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(issue, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            if (repair.customIssue != null && repair.customIssue!.isNotEmpty && !repair.issues.contains(repair.customIssue))
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.orange[600], size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custom Issue:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            repair.customIssue!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // WARRANTY CARD (Fixed Overflow)
  Widget _buildWarrantyCard(
    bool isWarrantyValid,
    int daysLeft,
    DateFormat dateFormat,
  ) {
    Color statusColor;
    IconData statusIcon;

    if (isWarrantyValid) {
      if (daysLeft <= 7) {
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber;
      } else {
        statusColor = Colors.green;
        statusIcon = Icons.verified_user;
      }
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Warranty Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Warranty Period', _repair.warrantyPeriod),
            _buildInfoRow(
              'Valid Until',
              dateFormat.format(_repair.warrantyExpiryDate),
              valueColor: statusColor,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isWarrantyValid
                          ? daysLeft <= 7
                                ? 'Expiring in $daysLeft days'
                                : 'Warranty Active'
                          : 'Warranty Expired',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WARRANTY VOID CARD (interactive, selectable with completion indicator)
  Widget _buildWarrantyVoidCard() {
    final allSelected =
        _selectedVoidConditions.length ==
        DeviceIssues.warrantyVoidConditions.length;
    final isReviewed =
        _selectedVoidConditions.isNotEmpty ||
        _selectedVoidConditions.length <
            DeviceIssues.warrantyVoidConditions.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isReviewed
            ? Border.all(color: Colors.green.shade300, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with completion badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.gpp_bad, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Warranty Void Conditions',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isReviewed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Reviewed',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const Text(
                        'Select conditions that apply to this repair',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Select All / Deselect All
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedVoidConditions.length} of ${DeviceIssues.warrantyVoidConditions.length} selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (allSelected) {
                        _selectedVoidConditions.clear();
                      } else {
                        _selectedVoidConditions = List.from(
                          DeviceIssues.warrantyVoidConditions,
                        );
                      }
                    });
                    _saveChanges();
                  },
                  icon: Icon(
                    allSelected ? Icons.deselect : Icons.select_all,
                    size: 16,
                  ),
                  label: Text(
                    allSelected ? 'Deselect All' : 'Select All',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),

            const Divider(height: 16),

            // Condition list
            ...DeviceIssues.warrantyVoidConditions.map((condition) {
              final isSelected = _selectedVoidConditions.contains(condition);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedVoidConditions.remove(condition);
                    } else {
                      _selectedVoidConditions.add(condition);
                    }
                  });
                  _saveChanges();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.red.withValues(alpha: 0.07)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.red.withValues(alpha: 0.4)
                          : Colors.grey[200]!,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          key: ValueKey(isSelected),
                          color: isSelected ? Colors.red : Colors.grey[400],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          condition,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? const Color(0xFF1E293B)
                                : Colors.grey[600],
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // BEFORE / AFTER CHECKLIST CARD with completion indicator
  Widget _buildChecklistCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Map<String, bool?> checklist,
    required void Function(String item, bool? value) onChanged,
  }) {
    final checked = checklist.values.where((v) => v != null).length;
    final passed = checklist.values.where((v) => v == true).length;
    final total = checklist.length;
    final isComplete = checked == total;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isComplete
            ? Border.all(color: Colors.green.shade300, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with completion badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isComplete)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Complete',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress summary chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _summaryChip('$checked/$total Checked', Colors.blue),
                _summaryChip('$passed Pass', Colors.green),
                _summaryChip(
                  '${total - passed - (checked - passed)} Pending',
                  Colors.grey,
                ),
              ],
            ),

            // Progress bar
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? checked / total : 0,
                backgroundColor: Colors.grey[200],
                color: isComplete ? Colors.green : iconColor,
                minHeight: 6,
              ),
            ),

            const Divider(height: 20),

            // Reset all button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    for (final key in checklist.keys) {
                      checklist[key] = null;
                    }
                  });
                  _saveChanges();
                },
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Reset', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Checklist items
            ...checklist.entries.map((entry) {
              final item = entry.key;
              final state = entry.value; // null, true, false

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    // PASS button
                    _checklistButton(
                      icon: Icons.check,
                      color: Colors.green,
                      isActive: state == true,
                      onTap: () => onChanged(item, state == true ? null : true),
                    ),
                    const SizedBox(width: 6),
                    // FAIL button
                    _checklistButton(
                      icon: Icons.close,
                      color: Colors.red,
                      isActive: state == false,
                      onTap: () =>
                          onChanged(item, state == false ? null : false),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          color: state == null
                              ? Colors.grey[500]
                              : state == true
                              ? const Color(0xFF1E293B)
                              : Colors.red[700],
                          fontWeight: state != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                          decoration: state == false
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    // State indicator dot
                    if (state != null)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state == true ? Colors.green : Colors.red,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _checklistButton({
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.white : color.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _summaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // TOTAL AMOUNT CARD

  Widget _buildTotalAmountCard(NumberFormat currencyFormat) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'To Be Paid',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            Flexible(
              child: Text(
                currencyFormat.format(_repair.totalAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // GENERATE PDF BUTTON

  Widget _buildGeneratePdfButton(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _generatePdf(context),
        icon: const Icon(Icons.picture_as_pdf, size: 20),
        label: const Text(
          'Generate PDF Bill',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF97316),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
