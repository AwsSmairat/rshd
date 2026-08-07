import '../../features/contact/data/contact_channels.dart';

class PlatformSettings {
  const PlatformSettings({
    required this.platformName,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.studentRegistrationEnabled,
    required this.paymentInstructions,
    required this.assignmentMaxFileSizeMb,
    required this.assignmentAllowedFileTypes,
    required this.currencySymbol,
    required this.contact,
    this.allowQuizRetake = true,
    this.supportEmail,
    this.supportPhone,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final types = data['assignment_allowed_file_types'];
    final contactRaw = data['contact'];
    return PlatformSettings(
      platformName: data['platform_name']?.toString() ?? 'RSHD',
      maintenanceMode: data['maintenance_mode'] == true,
      maintenanceMessage: data['maintenance_message']?.toString() ??
          'الموقع حالياً تحت الصيانة، يرجى المحاولة لاحقاً.',
      studentRegistrationEnabled:
          data['student_registration_enabled'] != false,
      paymentInstructions: data['payment_instructions']?.toString() ?? '',
      assignmentMaxFileSizeMb:
          int.tryParse(data['assignment_max_file_size']?.toString() ?? '') ??
              10,
      assignmentAllowedFileTypes: types is List
          ? types.map((e) => e.toString()).toList()
          : const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'zip'],
      currencySymbol: data['currency_symbol']?.toString() ?? 'د.أ',
      allowQuizRetake: data['allow_quiz_retake'] != false,
      supportEmail: data['support_email']?.toString(),
      supportPhone: data['support_phone']?.toString(),
      contact: ContactChannels.fromJson(
        contactRaw is Map<String, dynamic> ? contactRaw : null,
      ),
    );
  }

  final String platformName;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final bool studentRegistrationEnabled;
  final String paymentInstructions;
  final int assignmentMaxFileSizeMb;
  final List<String> assignmentAllowedFileTypes;
  final String currencySymbol;
  final bool allowQuizRetake;
  final String? supportEmail;
  final String? supportPhone;
  final ContactChannels contact;

  static final fallback = PlatformSettings(
    platformName: 'RSHD',
    maintenanceMode: false,
    maintenanceMessage: 'الموقع حالياً تحت الصيانة، يرجى المحاولة لاحقاً.',
    studentRegistrationEnabled: true,
    paymentInstructions: '',
    assignmentMaxFileSizeMb: 10,
    assignmentAllowedFileTypes: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'zip'],
    currencySymbol: 'د.أ',
    allowQuizRetake: true,
    supportEmail: 'admin@rshdacademy.com',
    contact: ContactChannels.empty,
  );
}
