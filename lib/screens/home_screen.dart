import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../models/repair_record.dart' show RepairRecord, DeviceIssues;
import '../services/database_helper.dart';
import '../services/pdf_service.dart';
import 'add_repair_screen.dart';
import 'repair_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<RepairRecord> _repairs = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _loadRepairs();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRepairs() async {
    final repairs = await DatabaseHelper.instance.getAllRepairs();
    setState(() {
      _repairs = repairs;
      _isLoading = false;
    });
  }

  Future<void> _deleteRepair(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Delete Record'),
          ],
        ),
        content: const Text('Are you sure you want to delete this repair record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteRepair(id);
      _loadRepairs();
    }
  }

  Future<void> _openPdf(RepairRecord repair) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = Directory(dir.path).listSync().whereType<File>().where(
        (f) => f.path.contains('PhoneFX_Bill_${repair.id}_'),
      ).toList();
      if (files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No PDF found. Please generate one first.')),
          );
        }
        return;
      }
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      OpenFilex.open(files.first.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: $e')),
        );
      }
    }
  }

  Future<void> _generatePdf(RepairRecord repair) async {
    final hasWarrantyConditions = repair.warrantyVoidConditions.isNotEmpty ||
        repair.warrantyVoidConditions.length < DeviceIssues.warrantyVoidConditions.length;
    final hasBeforeChecklist = repair.checklistBefore.isNotEmpty;
    final hasAfterChecklist = repair.checklistAfter.isNotEmpty;

    if (!hasWarrantyConditions || !hasBeforeChecklist || !hasAfterChecklist) {
      final missing = <String>[];
      if (!hasWarrantyConditions) missing.add('• Warranty Void Conditions');
      if (!hasBeforeChecklist) missing.add('• Before Repair Checklist');
      if (!hasAfterChecklist) missing.add('• After Repair Checklist');

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('Cannot Generate Bill'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please complete all sections in the repair detail before generating the bill:'),
                const SizedBox(height: 12),
                ...missing.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(item, style: const TextStyle(color: Colors.red, fontSize: 13)),
                )),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap on the repair card to open details and complete all checklists.',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      final file = await PdfService.generatePdf(repair);
      
      if (mounted) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) => Container(
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
                  child: Icon(Icons.check_circle, color: Colors.green[600], size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PDF Generated!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bill for ${repair.customerName}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
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
                              Navigator.pop(context);
                              Share.shareXFiles([XFile(file.path)], text: 'PhoneFX+ Bill for ${repair.customerName}');
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
                  ],
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
            flexibleSpace: FlexibleSpaceBar(
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.build_circle, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text('PhoneFX+', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2563EB),
                      const Color(0xFF1D4ED8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: 40,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: 20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_repairs.length} Repairs',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _repairs.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final repair = _repairs[index];
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildRepairCard(repair, index),
                            );
                          },
                          childCount: _repairs.length,
                        ),
                      ),
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRepairScreen()),
          );
          _loadRepairs();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Repair'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long, size: 64, color: Colors.blue[300]),
          ),
          const SizedBox(height: 24),
          Text(
            'No repairs yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first repair',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildRepairCard(RepairRecord repair, int index) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final isWarrantyValid = repair.warrantyExpiryDate.isAfter(DateTime.now());
    final daysLeft = repair.warrantyExpiryDate.difference(DateTime.now()).inDays;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isWarrantyValid) {
      if (daysLeft <= 7) {
        statusColor = Colors.orange;
        statusText = 'Expiring soon';
        statusIcon = Icons.warning_amber_rounded;
      } else {
        statusColor = Colors.green;
        statusText = 'Valid';
        statusIcon = Icons.verified_user;
      }
    } else {
      statusColor = Colors.red;
      statusText = 'Expired';
      statusIcon = Icons.cancel;
    }

    IconData deviceIcon;
    Color deviceColor;
    switch (repair.deviceType) {
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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RepairDetailScreen(repair: repair),
                ),
              );
              _loadRepairs();
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: deviceColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(deviceIcon, color: deviceColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repair.customerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: deviceColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    repair.deviceBrand,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: deviceColor,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    repair.deviceType,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              repair.deviceModel,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Repair Date',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(repair.repairDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Warranty Until',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(repair.warrantyExpiryDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(repair.totalAmount),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF97316),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteRepair(repair.id!),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openPdf(repair),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('Open PDF', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _generatePdf(repair),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('Generate PDF', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
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
    );
  }
}