import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/repair_record.dart';
import '../services/database_helper.dart';

class AddRepairScreen extends StatefulWidget {
  final RepairRecord? repair;

  const AddRepairScreen({super.key, this.repair});

  @override
  State<AddRepairScreen> createState() => _AddRepairScreenState();
}

class _AddRepairScreenState extends State<AddRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _deviceModelController = TextEditingController();
  final _amountController = TextEditingController();
  final _customIssueController = TextEditingController();
  final _repairNotesController = TextEditingController();

  String _deviceType = 'Phone';
  String _deviceBrand = 'Apple';
  bool _isCustomBrand = false;
  final _customBrandController = TextEditingController();
  List<String> _selectedIssues = [];
  List<String> _selectedCustomerParts = [];
  DateTime _repairDate = DateTime.now();
  DateTime? _pickupDate;
  String _warrantyPeriod = '1 month';
  bool _isSaving = false;

  final List<String> _deviceTypes = ['Phone', 'Laptop', 'PC', 'Tablet', 'Smartwatch', 'Console'];

  @override
  void initState() {
    super.initState();
    if (widget.repair != null) {
      _customerNameController.text = widget.repair!.customerName;
      _deviceModelController.text = widget.repair!.deviceModel;
      _amountController.text = widget.repair!.totalAmount.toString();
      _deviceType = widget.repair!.deviceType;
      _deviceBrand = widget.repair!.deviceBrand;
      _selectedIssues = List.from(widget.repair!.issues);
      _repairDate = widget.repair!.repairDate;
      _pickupDate = widget.repair!.pickupDate;
      _warrantyPeriod = widget.repair!.warrantyPeriod;
      if (widget.repair!.customIssue != null) {
        _customIssueController.text = widget.repair!.customIssue!;
      }
      _selectedCustomerParts = List.from(widget.repair!.customerProvidedParts);
      if (widget.repair!.repairNotes != null) {
        _repairNotesController.text = widget.repair!.repairNotes!;
      }
      if (!DeviceBrands.brands.contains(_deviceBrand)) {
        _isCustomBrand = true;
        _customBrandController.text = _deviceBrand;
      }
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _deviceModelController.dispose();
    _amountController.dispose();
    _customIssueController.dispose();
    _customBrandController.dispose();
    _repairNotesController.dispose();
    super.dispose();
  }

  List<String> _getIssuesForDeviceType() {
    return DeviceIssues.getIssuesForDeviceType(_deviceType);
  }

  Future<void> _selectRepairDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _repairDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _repairDate = date;
      });
    }
  }

  Future<void> _selectPickupDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _pickupDate ?? DateTime.now(),
      firstDate: _repairDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _pickupDate = date;
      });
    }
  }

  Future<void> _saveRepair() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedIssues.isEmpty && _customIssueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 8),
              Text('Please select at least one issue'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final warrantyExpiryDate = WarrantyOptions.calculateExpiryDate(
      _repairDate,
      _warrantyPeriod,
    );

    final finalBrand = _isCustomBrand ? _customBrandController.text.trim() : _deviceBrand;

    final allIssues = List<String>.from(_selectedIssues);
    if (_customIssueController.text.trim().isNotEmpty) {
      final custom = _customIssueController.text.trim();
      if (!allIssues.contains(custom)) {
        allIssues.add(custom);
      }
    }

    final repair = RepairRecord(
      id: widget.repair?.id,
      customerName: _customerNameController.text.trim(),
      deviceType: _deviceType,
      deviceBrand: finalBrand,
      deviceModel: _deviceModelController.text.trim(),
      issues: allIssues,
      customIssue: _customIssueController.text.trim().isNotEmpty
          ? _customIssueController.text.trim()
          : null,
      repairDate: _repairDate,
      pickupDate: _pickupDate,
      warrantyPeriod: _warrantyPeriod,
      warrantyExpiryDate: warrantyExpiryDate,
      totalAmount: double.parse(_amountController.text),
      createdAt: widget.repair?.createdAt ?? DateTime.now(),
      customerProvidedParts: _selectedCustomerParts,
      repairNotes: _repairNotesController.text.trim().isNotEmpty
          ? _repairNotesController.text.trim()
          : null,
    );

    try {
      if (widget.repair != null) {
        await DatabaseHelper.instance.updateRepair(repair);
      } else {
        final newId = await DatabaseHelper.instance.insertRepair(repair);
        if (newId > 0) {
          final count = await DatabaseHelper.instance.getRepairCount();
          final billNumber = 'PFX-${count.toString().padLeft(4, '0')}';
          await DatabaseHelper.instance.updateBillNumber(newId, billNumber);
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.repair != null ? 'Repair updated!' : 'Repair saved!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
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
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.repair != null ? 'Edit Repair' : 'New Repair',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCustomerSection(),
                    const SizedBox(height: 16),
                    _buildDeviceSection(),
                    const SizedBox(height: 16),
                    _buildIssuesSection(),
                    const SizedBox(height: 16),
                    _buildCustomerPartsSection(),
                    const SizedBox(height: 16),
                    _buildRepairNotesSection(),
                    const SizedBox(height: 16),
                    _buildDateSection(),
                    const SizedBox(height: 16),
                    _buildWarrantySection(),
                    const SizedBox(height: 16),
                    _buildAmountSection(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color iconColor, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                    color: iconColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      filled: true,
      fillColor: const Color(0xFF334155),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return _buildSectionCard(
      'Customer Information',
      Icons.person,
      const Color(0xFF2563EB),
      TextFormField(
        controller: _customerNameController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: _inputDecoration('Customer Name', Icons.person_outline, hint: 'Enter customer name'),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter customer name';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDeviceSection() {
    return _buildSectionCard(
      'Device Information',
      Icons.devices,
      const Color(0xFF10B981),
      Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _deviceType,
            dropdownColor: const Color(0xFF334155),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Device Type', Icons.phone_android),
            items: _deviceTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(color: Colors.white)));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _deviceType = value!;
                _selectedIssues = [];
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _isCustomBrand ? 'Other' : _deviceBrand,
            dropdownColor: const Color(0xFF334155),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Device Brand', Icons.business),
            items: DeviceBrands.brands.map((brand) {
              return DropdownMenuItem(value: brand, child: Text(brand, style: const TextStyle(color: Colors.white)));
            }).toList(),
            onChanged: (value) {
              setState(() {
                if (value == 'Other') {
                  _isCustomBrand = true;
                } else {
                  _isCustomBrand = false;
                  _deviceBrand = value!;
                }
              });
            },
          ),
          if (_isCustomBrand) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _customBrandController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: _inputDecoration('Enter Brand Name', Icons.edit, hint: 'e.g., Honor, Poco'),
              validator: (value) {
                if (_isCustomBrand && (value == null || value.trim().isEmpty)) {
                  return 'Please enter brand name';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _deviceModelController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: _inputDecoration('Device Model', Icons.devices, hint: 'e.g., iPhone 13 Pro Max, Galaxy S23'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter device model';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesSection() {
    final issues = _getIssuesForDeviceType();

    return _buildSectionCard(
      'Damage / Issues',
      Icons.build,
      const Color(0xFFF97316),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select issues (tap to select):',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: issues.map((issue) {
              final isSelected = _selectedIssues.contains(issue);
              return FilterChip(
                label: Text(
                  issue.split(' ').take(3).join(' '),
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? const Color(0xFF2563EB) : Colors.grey[300],
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFFDBEAFE),
                checkmarkColor: const Color(0xFF2563EB),
                backgroundColor: const Color(0xFF334155),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedIssues.add(issue);
                    } else {
                      _selectedIssues.remove(issue);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customIssueController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: _inputDecoration('Custom Issue (if not listed)', Icons.edit_note, hint: 'Describe any other issue...'),
          ),
          if (_selectedIssues.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text(
                        'Selected Issues (${_selectedIssues.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._selectedIssues.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(
                            issue,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerPartsSection() {
    return _buildSectionCard(
      'Customer Provided Parts',
      Icons.build,
      const Color(0xFFEC4899),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[900]!.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[700]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber[400], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Parts brought by customer — NO WARRANTY applies to these.',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[300], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select parts the customer brought (tap to select):',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CustomerProvidedParts.parts.map((part) {
              final isSelected = _selectedCustomerParts.contains(part);
              return FilterChip(
                label: Text(
                  part,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? const Color(0xFFEC4899) : Colors.grey[300],
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFFFCE4EC),
                checkmarkColor: const Color(0xFFEC4899),
                backgroundColor: const Color(0xFF334155),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCustomerParts.add(part);
                    } else {
                      _selectedCustomerParts.remove(part);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedCustomerParts.isNotEmpty
                      ? '${_selectedCustomerParts.length} part(s) — customer-provided, no warranty'
                      : 'Customer has not provided any parts',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepairNotesSection() {
    return _buildSectionCard(
      'Repair Notes',
      Icons.notes,
      const Color(0xFF8B5CF6),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo[900]!.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo[700]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.indigo[400], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Describe what you repaired/replaced (e.g. "Replaced Power IC", "Installed OLED Original screen").',
                    style: TextStyle(color: Colors.indigo[300], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _repairNotesController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              'Work done / Parts replaced',
              Icons.edit_note,
              hint: 'e.g. Replaced Power IC on motherboard\nInstalled OLED Original screen\nReplaced battery connector...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    final dateFormat = DateFormat('dd MMM yyyy');
    final expiryDate = WarrantyOptions.calculateExpiryDate(_repairDate, _warrantyPeriod);

    return _buildSectionCard(
      'Repair Dates',
      Icons.calendar_today,
      const Color(0xFF8B5CF6),
      Column(
        children: [
          InkWell(
            onTap: _selectRepairDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: _inputDecoration('Repair Date (Received)', Icons.arrow_downward),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(_repairDate),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month, size: 18, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectPickupDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: _inputDecoration('Pickup Date (Optional)', Icons.arrow_upward),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _pickupDate != null ? dateFormat.format(_pickupDate!) : 'Not set yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: _pickupDate != null ? Colors.white : Colors.grey[500],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month, size: 18, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _warrantyPeriod,
            dropdownColor: const Color(0xFF334155),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Warranty Period', Icons.verified_user),
            items: WarrantyOptions.periods.map((period) {
              return DropdownMenuItem(value: period, child: Text(period, style: const TextStyle(color: Colors.white)));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _warrantyPeriod = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: WarrantyOptions.isNoWarranty(_warrantyPeriod)
                    ? [Colors.grey[600]!, Colors.grey[800]!]
                    : [Colors.green[400]!, Colors.green[600]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    WarrantyOptions.isNoWarranty(_warrantyPeriod)
                        ? Icons.block
                        : Icons.access_time,
                    color: Colors.white, size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        WarrantyOptions.isNoWarranty(_warrantyPeriod)
                            ? 'No Warranty'
                            : 'Warranty Valid Until:',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        WarrantyOptions.isNoWarranty(_warrantyPeriod)
                            ? 'No warranty provided'
                            : dateFormat.format(expiryDate),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantySection() {
    return _buildSectionCard(
      'Warranty Void Conditions',
      Icons.warning_amber,
      Colors.red[600]!,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[900]!.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[700]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red[400], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Warranty will be void if:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[300], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...DeviceIssues.warrantyVoidConditions.take(5).map((condition) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.close, size: 14, color: Colors.red[400]),
                const SizedBox(width: 8),
                Expanded(child: Text(condition, style: const TextStyle(fontSize: 12, color: Colors.grey))),
              ],
            ),
          )),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: const Color(0xFF1E293B),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.5,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (context, scrollController) => Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.red[600], size: 24),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('All Warranty Void Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: DeviceIssues.warrantyVoidConditions
                              .map((c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.close, size: 16, color: Colors.red[400]),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(c, style: const TextStyle(color: Colors.grey))),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.expand_more, size: 18, color: Colors.grey), SizedBox(width: 4), Text('View All Conditions', style: TextStyle(color: Colors.grey))],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return _buildSectionCard(
      'Total Amount',
      Icons.payments,
      const Color(0xFFEC4899),
      TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: _inputDecoration('Total Amount (RM)', Icons.attach_money, hint: '0.00'),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter total amount';
          }
          final amount = double.tryParse(value);
          if (amount == null || amount < 0) {
            return 'Please enter a valid amount';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveRepair,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF97316),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.repair != null ? Icons.save : Icons.add_circle_outline),
                  const SizedBox(width: 8),
                  Text(widget.repair != null ? 'Update Repair' : 'Save Repair', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}