class RepairRecord {
  final int? id;
  final String customerName;
  final String deviceType;
  final String deviceBrand;
  final String deviceModel;
  final List<String> issues;
  final String? customIssue;
  final DateTime repairDate;
  final DateTime? pickupDate;
  final String warrantyPeriod;
  final DateTime warrantyExpiryDate;
  final double totalAmount;
  final DateTime createdAt;

  final List<String> warrantyVoidConditions;
  final Map<String, String> checklistBefore;
  final Map<String, String> checklistAfter;

  // NEW: Customer-provided parts (no warranty applies to these)
  final List<String> customerProvidedParts;

  // NEW: Free-text notes for work done (e.g. "Replaced Power IC", "OLED Original screen")
  final String? repairNotes;

  RepairRecord({
    this.id,
    required this.customerName,
    required this.deviceType,
    required this.deviceBrand,
    required this.deviceModel,
    required this.issues,
    this.customIssue,
    required this.repairDate,
    this.pickupDate,
    required this.warrantyPeriod,
    required this.warrantyExpiryDate,
    required this.totalAmount,
    required this.createdAt,
    this.warrantyVoidConditions = const [],
    this.checklistBefore = const {},
    this.checklistAfter = const {},
    this.customerProvidedParts = const [],
    this.repairNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'deviceType': deviceType,
      'deviceBrand': deviceBrand,
      'deviceModel': deviceModel,
      'issues': issues.join('|'),
      'customIssue': customIssue,
      'repairDate': repairDate.toIso8601String(),
      'pickupDate': pickupDate?.toIso8601String(),
      'warrantyPeriod': warrantyPeriod,
      'warrantyExpiryDate': warrantyExpiryDate.toIso8601String(),
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'warrantyVoidConditions': warrantyVoidConditions.join('||'),
      'checklistBefore': checklistBefore.entries
          .map((e) => '${e.key}:::${e.value}')
          .join('||'),
      'checklistAfter': checklistAfter.entries
          .map((e) => '${e.key}:::${e.value}')
          .join('||'),
      'customerProvidedParts': customerProvidedParts.join('|'),
      'repairNotes': repairNotes,
    };
  }

  factory RepairRecord.fromMap(Map<String, dynamic> map) {
    Map<String, String> parseChecklist(String? raw) {
      if (raw == null || raw.isEmpty) return {};
      return Map.fromEntries(
        raw.split('||').where((e) => e.contains(':::')).map((e) {
          final parts = e.split(':::');
          return MapEntry(parts[0], parts[1]);
        }),
      );
    }

    return RepairRecord(
      id: map['id'] as int?,
      customerName: map['customerName'] as String,
      deviceType: map['deviceType'] as String,
      deviceBrand: map['deviceBrand'] as String,
      deviceModel: map['deviceModel'] as String,
      issues: (map['issues'] as String).split('|'),
      customIssue: map['customIssue'] as String?,
      repairDate: DateTime.parse(map['repairDate'] as String),
      pickupDate: map['pickupDate'] != null
          ? DateTime.parse(map['pickupDate'] as String)
          : null,
      warrantyPeriod: map['warrantyPeriod'] as String,
      warrantyExpiryDate: DateTime.parse(map['warrantyExpiryDate'] as String),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      warrantyVoidConditions:
          map['warrantyVoidConditions'] != null &&
              (map['warrantyVoidConditions'] as String).isNotEmpty
          ? (map['warrantyVoidConditions'] as String).split('||')
          : [],
      checklistBefore: parseChecklist(map['checklistBefore'] as String?),
      checklistAfter: parseChecklist(map['checklistAfter'] as String?),
      customerProvidedParts:
          map['customerProvidedParts'] != null &&
              (map['customerProvidedParts'] as String).isNotEmpty
          ? (map['customerProvidedParts'] as String).split('|')
          : [],
      repairNotes: map['repairNotes'] as String?,
    );
  }

  RepairRecord copyWith({
    int? id,
    String? customerName,
    String? deviceType,
    String? deviceBrand,
    String? deviceModel,
    List<String>? issues,
    String? customIssue,
    DateTime? repairDate,
    DateTime? pickupDate,
    String? warrantyPeriod,
    DateTime? warrantyExpiryDate,
    double? totalAmount,
    DateTime? createdAt,
    List<String>? warrantyVoidConditions,
    Map<String, String>? checklistBefore,
    Map<String, String>? checklistAfter,
    List<String>? customerProvidedParts,
    String? repairNotes,
  }) {
    return RepairRecord(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      deviceType: deviceType ?? this.deviceType,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      deviceModel: deviceModel ?? this.deviceModel,
      issues: issues ?? this.issues,
      customIssue: customIssue ?? this.customIssue,
      repairDate: repairDate ?? this.repairDate,
      pickupDate: pickupDate ?? this.pickupDate,
      warrantyPeriod: warrantyPeriod ?? this.warrantyPeriod,
      warrantyExpiryDate: warrantyExpiryDate ?? this.warrantyExpiryDate,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      warrantyVoidConditions:
          warrantyVoidConditions ?? this.warrantyVoidConditions,
      checklistBefore: checklistBefore ?? this.checklistBefore,
      checklistAfter: checklistAfter ?? this.checklistAfter,
      customerProvidedParts:
          customerProvidedParts ?? this.customerProvidedParts,
      repairNotes: repairNotes ?? this.repairNotes,
    );
  }
}

// ─────────────────────────────────────────────
// DEVICE BRANDS
// ─────────────────────────────────────────────

class DeviceBrands {
  static const List<String> brands = [
    'Apple',
    'Samsung',
    'Oppo',
    'Vivo',
    'Xiaomi',
    'Realme',
    'Asus',
    'Huawei',
    'OnePlus',
    'Nokia',
    'Motorola',
    'Infinix',
    'Tecno',
    'Google',
    'Other',
  ];
}

// ─────────────────────────────────────────────
// DEVICE ISSUES
// ─────────────────────────────────────────────

class DeviceIssues {
  static const List<String> phoneIssues = [
    // Display
    'Screen Replacement (cracked, broken display, touch not responding)',
    'Ghost Touch / Phantom Touch (screen tapping on its own)',
    'Display Discoloration (yellow tint, burn-in, dead pixels)',
    'LCD Bleed / Backlight Issues (dark spots, uneven lighting)',

    // Battery & Power
    'Battery Replacement (drains fast, swollen, sudden shutdown)',
    'Charging Port Repair (not charging, loose port, bent pins)',
    'Overheating Issues (device gets hot, thermal throttling)',
    'Boot Loop / Stuck on Logo (device won\'t start properly)',

    // Physical & Hardware
    'Water Damage Repair (liquid exposure, corrosion)',
    'Motherboard Repair (dead device, component-level damage)',
    'Button Repairs (power button, volume button, home button)',
    'Back Glass / Housing Repair (cracked back panel, dented frame, broken chassis)',
    'SIM Card Tray Repair (stuck, broken, not reading SIM)',
    'Headphone Jack Repair (no audio, debris stuck, bent jack)',
    'Fingerprint Sensor Repair (not recognizing, unresponsive)',
    'Face ID / Facial Recognition Repair (not working after drop or repair)',
    'Vibration Motor Repair (no haptic feedback, rattling)',

    // Audio & Camera
    'Speaker / Microphone Repair (no sound, muffled audio, mic not working)',
    'Camera Repair (blurry, black screen, front or rear camera failure)',

    // Connectivity
    'Network Issues (no signal, Wi-Fi not working, call drops)',
    'Bluetooth Issues (not pairing, dropping connection)',
    'GPS / Location Issues (inaccurate, not locking on)',
    'NFC Repair (tap-to-pay not working)',
    'Mobile Hotspot Issues (cannot share internet, slow tethering)',

    // Software & Performance
    'Software Issues (slow performance, app crashes, malware, OS update failure)',
    'Factory Reset / Virus Removal',
    'Data Recovery (deleted files, failed restore, corrupted storage)',

    // Account & Security
    'iCloud / Google Account Issues (locked out, sync problems)',
    'Passcode / Pattern Unlock (locked out of device)',
    'iCloud Activation Lock Removal',
    'IMEI Repair / Restoration (invalid IMEI, blocked device)',
  ];

  static const List<String> laptopIssues = [
    // Display
    'Screen Replacement (cracked, dead pixels, backlight failure)',
    'Display Hinge Repair (loose, broken, won\'t stay open)',
    'Webcam Repair (not detected, blurry, black screen)',
    'External Display / HDMI Port Issue (no output, flickering)',

    // Battery & Power
    'Battery Replacement (not charging, draining fast, swollen)',
    'Charging Port Repair (loose, broken, not charging)',
    'Power Button Repair (won\'t turn on, stuck button)',
    'Overheating / Thermal Issues (hot, throttling, sudden shutdown)',

    // Physical & Hardware
    'Water Damage Repair (liquid spill, corrosion, dead board)',
    'Motherboard Repair (no power, component-level damage)',
    'Keyboard Repair / Replacement (keys not working, broken, sticky)',
    'Trackpad / Touchpad Repair (not clicking, erratic movement)',
    'USB / Port Repair (broken USB, SD card slot, Thunderbolt)',
    'Cooling System / Fan Repair (loud fan, overheating, fan failure)',
    'Housing / Chassis Repair (cracked casing, broken lid, bent frame)',

    // Storage & Memory
    'Storage Upgrade / Replacement (HDD to SSD, failed drive)',
    'RAM Upgrade / Replacement (slow performance, not booting)',
    'Data Recovery (corrupted drive, accidental deletion, failed OS)',

    // Audio & Connectivity
    'Speaker / Audio Repair (no sound, distorted audio)',
    'Microphone Repair (not detected, poor quality)',
    'Wi-Fi / Bluetooth Card Repair (no connection, dropping signal)',
    'Network Port (Ethernet) Repair (not detecting, broken port)',

    // Software & Performance
    'Software Issues (slow performance, app crashes, malware, driver issues)',
    'OS Reinstall / Recovery (Windows, macOS, Linux)',
    'Virus / Malware Removal',
    'BIOS / Firmware Issues (won\'t boot, corrupted firmware)',

    // Account & Security
    'Password / Account Unlock (forgotten login, locked out)',
    'Activation Lock / BitLocker Recovery',
  ];

  static const List<String> pcIssues = [
    // Power & Boot
    'No Power / Won\'t Turn On (dead PSU, faulty switch, board issue)',
    'Power Supply Repair / Replacement (insufficient wattage, failure)',
    'Boot Loop / Won\'t Boot (corrupted OS, failed drive, bad RAM)',
    'BIOS / Firmware Issues (corrupted BIOS, wrong settings)',

    // Motherboard & Components
    'Motherboard Repair / Replacement (dead board, component damage)',
    'CPU Issues (overheating, bent pins, failure)',
    'GPU / Graphics Card Repair (no display, artifacts, fan failure)',
    'RAM Upgrade / Replacement (crashes, not detected, incompatible)',

    // Storage
    'Storage Upgrade / Replacement (HDD, SSD, NVMe)',
    'Data Recovery (failed drive, corrupted files, accidental deletion)',
    'RAID Setup / Repair',

    // Cooling & Performance
    'Cooling System / Fan Repair (overheating, loud fans, thermal paste)',
    'Cable Management / Airflow Optimization',
    'Performance Upgrade / Optimization (bottleneck diagnosis)',

    // Ports & Connectivity
    'USB / Port Repair (broken ports, not detecting devices)',
    'Network Card / Wi-Fi Adapter Issue (no internet, slow speed)',
    'Bluetooth Adapter Issue (not pairing, not detected)',
    'Sound Card / Audio Issue (no sound, distorted audio)',

    // Display & Peripherals
    'GPU / Display Output Issue (no signal, flickering, wrong resolution)',
    'Monitor Repair (dead pixels, backlight failure, no power)',
    'Peripheral Issues (keyboard, mouse, printer not working)',

    // Software & Security
    'Software Issues (OS reinstall, malware removal, driver issues)',
    'Virus / Malware Removal',
    'OS Installation / Recovery (Windows, Linux)',
    'Driver Issues (GPU, audio, network drivers not working)',
    'Password / Account Unlock (forgotten login, locked out)',

    // Custom PC
    'Custom PC Build',
    'PC Diagnosis / Health Check',
  ];

  static const List<String> tabletIssues = [
    // Display
    'Screen Replacement (cracked, broken display, touch not responding)',
    'Ghost Touch / Phantom Touch (screen tapping on its own)',
    'Display Discoloration (dead pixels, burn-in, yellow tint)',
    'LCD Bleed / Backlight Issues (dark spots, uneven lighting)',

    // Battery & Power
    'Battery Replacement (drains fast, swollen, sudden shutdown)',
    'Charging Port Repair (not charging, loose port, bent pins)',
    'Overheating Issues (device gets hot, throttling)',
    'Boot Loop / Stuck on Logo (won\'t start properly)',

    // Physical & Hardware
    'Water Damage Repair (liquid exposure, corrosion)',
    'Motherboard Repair (dead device, component-level damage)',
    'Button Repairs (power button, volume button, home button)',
    'Back Housing / Frame Repair (cracked casing, bent frame)',
    'SIM Card Tray Repair (for cellular tablets)',
    'Headphone Jack Repair (no audio, debris stuck)',
    'Fingerprint / Face ID Sensor Repair',
    'Stylus / Pen Compatibility Issues (Apple Pencil, S Pen)',

    // Audio & Camera
    'Speaker / Microphone Repair (no sound, muffled audio)',
    'Camera Repair (blurry, not working, front or rear)',

    // Connectivity
    'Wi-Fi Issues (not connecting, slow, dropping signal)',
    'Bluetooth Issues (not pairing, dropping connection)',
    'Cellular / SIM Issues (no signal, not reading SIM)',
    'GPS / Location Issues (inaccurate, not locking on)',

    // Software & Performance
    'Software Issues (slow performance, app crashes, OS update failure)',
    'Factory Reset / Virus Removal',
    'Data Recovery (deleted files, corrupted storage)',

    // Account & Security
    'iCloud / Google Account Issues (locked out, sync problems)',
    'Passcode / Pattern Unlock (locked out of device)',
    'Activation Lock Removal (iCloud, Google FRP)',
  ];

  static const List<String> smartwatchIssues = [
    // Display
    'Screen Replacement (cracked, broken display, touch not responding)',
    'Display Discoloration (burn-in, dead pixels)',

    // Battery & Charging
    'Battery Replacement (drains fast, swollen)',
    'Charging Dock / Pin Repair (not charging, loose connection)',

    // Physical & Hardware
    'Water Damage Repair (liquid exposure, corrosion)',
    'Crown / Button Repair (stuck, not working)',
    'Band / Strap Connector Repair (broken lug, won\'t attach)',
    'Housing / Case Repair (cracked casing, scratched)',
    'Vibration Motor Repair (no haptic feedback)',
    'Sensor Repair (heart rate, SpO2, GPS not accurate)',

    // Connectivity & Software
    'Bluetooth / Wi-Fi Pairing Issues (won\'t connect to phone)',
    'Software Issues (frozen, crashing, won\'t update)',
    'Factory Reset / Account Unlock',
  ];

  static const List<String> consoleIssues = [
    // Power & Boot
    'No Power / Won\'t Turn On',
    'Boot Issues (stuck on logo, error codes)',
    'Overheating / Fan Repair (loud fan, thermal paste, shutdown)',

    // Physical & Hardware
    'Disc Drive Repair (not reading discs, loud grinding)',
    'HDMI Port Repair (no display, broken port)',
    'USB Port Repair (not detecting controllers or drives)',
    'Housing / Shell Repair (cracked casing, broken panels)',
    'Motherboard Repair (component-level damage)',

    // Controller
    'Controller Repair (stick drift, button not working, charging issue)',
    'Controller Charging Port Repair',
    'Trigger / Button Repair',

    // Storage & Software
    'Storage Upgrade / Replacement (HDD to SSD)',
    'Data Recovery (corrupted save data, failed drive)',
    'Software Issues (system update failure, corrupted firmware)',
    'Account / Network Issues (PSN, Xbox Live, Nintendo account)',
  ];

  static List<String> getIssuesForDeviceType(String deviceType) {
    switch (deviceType) {
      case 'Phone':
        return phoneIssues;
      case 'Laptop':
        return laptopIssues;
      case 'PC':
        return pcIssues;
      case 'Tablet':
        return tabletIssues;
      case 'Smartwatch':
        return smartwatchIssues;
      case 'Console':
        return consoleIssues;
      default:
        return [];
    }
  }

  // ── Warranty Void Conditions ──────────────────
  static const List<String> warrantyVoidConditions = [
    'Physical damage after repair (cracked screen, dents, scratches)',
    'Water / liquid damage after repair',
    'Unauthorized modifications or opening of device',
    'Damage from improper use or accidents',
    'Software issues caused by user-installed apps or malware',
    'Normal wear and tear (battery degradation, cosmetic damage)',
    'Damage from using non-original chargers or accessories',
    'Jailbreak / root modifications',
    'Service by unauthorized technicians after our repair',
    'Overcharging or use of incompatible power adapters',
    'Physical force or pressure applied to screen or body',
    'Damage from extreme temperatures or humidity',
  ];
}

// ─────────────────────────────────────────────
// DEVICE CHECKLIST  (before & after repair)
// ─────────────────────────────────────────────

class DeviceChecklist {
  /// Common checklist items for ALL device types
  static const List<String> commonItems = [
    'Power On / Boot',
    'Touchscreen Response',
    'Display Quality (brightness, colors, dead pixels)',
    'Front Camera',
    'Rear Camera',
    'Speaker (earpiece & loudspeaker)',
    'Microphone',
    'Wi-Fi Connectivity',
    'Bluetooth Pairing',
    'Charging (cable & wireless if supported)',
    'Battery Level & Health',
    'Volume Buttons',
    'Power Button',
    'Vibration / Haptics',
    'Fingerprint Sensor',
    'Face ID / Facial Recognition',
    'Headphone Jack (if present)',
    'SIM Card Detection',
    'Mobile Network / Signal',
    'GPS / Location Accuracy',
    'NFC (if supported)',
    'Settings App Access',
    'IMEI / Serial Number Visible',
    'USB / Charging Port Condition',
    'Overall Physical Condition',
  ];

  /// Extra items specific to Laptops
  static const List<String> laptopItems = [
    'Keyboard (all keys functional)',
    'Trackpad / Touchpad',
    'Webcam',
    'HDMI / Display Output',
    'USB Ports',
    'SD Card Slot',
    'Ethernet Port',
    'Cooling Fan (noise, airflow)',
    'Display Hinge Stability',
    'Battery Charge Cycle Count',
    'Storage Health (S.M.A.R.T.)',
    'RAM Detection',
    'OS Boot Speed',
    'Sleep / Wake Function',
  ];

  /// Extra items specific to PCs
  static const List<String> pcItems = [
    'POST / BIOS Screen',
    'GPU Output (HDMI / DisplayPort)',
    'All USB Ports',
    'Audio Jack (front & rear)',
    'Ethernet / Network Card',
    'Wi-Fi / Bluetooth Adapter (if present)',
    'Cooling Fans (CPU, GPU, case)',
    'RAM Slots Detection',
    'Storage Drives Detected (HDD / SSD)',
    'OS Boot & Login',
    'GPU Driver Status',
    'Temperature Under Load',
    'Power Supply Stability',
  ];

  /// Returns the appropriate checklist for a device type
  static List<String> getChecklistForDeviceType(String deviceType) {
    switch (deviceType) {
      case 'Laptop':
        return [...commonItems, ...laptopItems];
      case 'PC':
        return pcItems; // PC uses its own set (no touchscreen etc.)
      default:
        return commonItems; // Phone, Tablet, Smartwatch, Console
    }
  }
}

// ─────────────────────────────────────────────
// WARRANTY OPTIONS
// ─────────────────────────────────────────────

class WarrantyOptions {
  static const List<String> periods = [
    'No Warranty',
    '1 week',
    '1 month',
    '3 months',
    '6 months',
    '1 year',
  ];

  static DateTime calculateExpiryDate(DateTime startDate, String period) {
    switch (period) {
      case 'No Warranty':
        return startDate; // expires immediately
      case '1 week':
        return startDate.add(const Duration(days: 7));
      case '1 month':
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case '3 months':
        return DateTime(startDate.year, startDate.month + 3, startDate.day);
      case '6 months':
        return DateTime(startDate.year, startDate.month + 6, startDate.day);
      case '1 year':
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
      default:
        return startDate.add(const Duration(days: 30));
    }
  }

  static bool isNoWarranty(String period) => period == 'No Warranty';
}

// ─────────────────────────────────────────────
// CUSTOMER-PROVIDED PARTS
// ─────────────────────────────────────────────

class CustomerProvidedParts {
  static const List<String> parts = [
    'Screen / Display',
    'Battery',
    'Charging Port',
    'Speaker',
    'Microphone',
    'Front Camera',
    'Rear Camera',
    'Back Glass / Housing',
    'SIM Card Tray',
    'Headphone Jack',
    'Fingerprint Sensor',
    'Face ID Sensor',
    'Power Button',
    'Volume Button',
    'Vibration Motor',
    'Cooling Fan',
    'Keyboard',
    'Trackpad',
    'Hard Drive / SSD',
    'RAM',
    'Motherboard',
  ];
}
