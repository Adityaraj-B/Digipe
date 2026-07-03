import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:screen_protector/screen_protector.dart';
import '../../payment/payment_screen.dart';
import '../bloc/product_bloc.dart';
import '../../../../core/bloc/auth_bloc.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/models/api_models.dart';
import '../../../../core/utils/input_validator.dart';

class InsuranceDetailScreen extends StatefulWidget {
  const InsuranceDetailScreen({super.key});

  @override
  State<InsuranceDetailScreen> createState() => _InsuranceDetailScreenState();
}

class _InsuranceDetailScreenState extends State<InsuranceDetailScreen> {
  bool _confirmNoDamage = false;
  bool _confirmDeclaration = false;

  double _gstPercentage = 18.0;
  double _discountPercentage = 0.0;
  bool _priceSettingsLoaded = false;

  List<ProductField> _fieldDefinitions = [];

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _installerController = TextEditingController();

  // Upload state
  String? _invoiceId;
  final List<String?> _photoIds = [null, null, null, null];
  String? _videoId;

  String? _invoiceName;
  String? _videoName;

  DateTime? _installationDate;
  final TextEditingController _dateController = TextEditingController();

  final _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // SECTION 7: Prevent screen capture
    ScreenProtector.preventScreenshotOn();
    _autoFillUser();
    _loadFieldDefinitions();
    _loadPriceSettings();
  }

  Future<void> _loadFieldDefinitions() async {
    final productBloc = context.read<ProductBloc>();
    if (productBloc.state is ProductLoaded) {
      final productId = (productBloc.state as ProductLoaded).selectedProduct.id;
      try {
        final defs = await context.read<ApiService>().getProductFields(
            productId);
        if (mounted) setState(() => _fieldDefinitions = defs);
      } catch (e) {
        dev.log('Warning: Could not fetch field definitions: $e');
      }
    }
  }
    Future<void> _loadPriceSettings() async {
      try {
        final settings = await context.read<ApiService>().getPriceSettings();
        if (!mounted) return;
        setState(() {
          _gstPercentage = (settings['tax']?['gstPercentage'] ?? 18.0).toDouble();
          final discount = settings['promotionalDiscount'];
          _discountPercentage = (discount?['isActive'] == true)
              ? (discount?['percentage'] ?? 0.0).toDouble()
              : 0.0;
          _priceSettingsLoaded = true;
        });
      } catch (e) {
        // Non-critical — keep defaults
        if (mounted) setState(() => _priceSettingsLoaded = true);
      }
    }

  void _autoFillUser() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _nameController.text = authState.user.name;
      _phoneController.text = authState.user.phone;
      _emailController.text = authState.user.email;
    }
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _houseController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    _capacityController.dispose();
    _brandController.dispose();
    _installerController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickInvoice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final doc = await context.read<ApiService>().uploadDocumentFull(result.files.single.path!);
        if (!mounted) return;
        setState(() {
          _invoiceId = doc['_id'] ?? doc['id'];
          _invoiceName = result.files.single.name;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickPhoto(int index) async {
    final source = await _showImageSourceSheet();
    if (source == null) return;

    final picked = await _imagePicker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final doc = await context.read<ApiService>().uploadDocumentFull(picked.path);
        if (!mounted) return;
        setState(() => _photoIds[index] = doc['_id'] ?? doc['id']);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final doc = await context.read<ApiService>().uploadDocumentFull(result.files.single.path!);
        if (!mounted) return;
        setState(() {
          _videoId = doc['_id'] ?? doc['id'];
          _videoName = result.files.single.name;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, productState) {
        if (productState is! ProductLoaded || _isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final plan = productState.selectedPlan!;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context)),
            title: Text(productState.selectedProduct.name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderSummary(plan, productState.selectedProduct.name),
                        const SizedBox(height: 16),
                        _buildSection(1, 'User Information', _buildUserInformationContent()),
                        const SizedBox(height: 16),
                        _buildSection(2, 'Installation Address', _buildInstallationAddressContent()),
                        const SizedBox(height: 16),
                        _buildSection(3, 'Solar Installation Details', _buildSolarInstallationDetailsContent()),
                        const SizedBox(height: 16),
                        _buildSection(4, 'Upload Documents', _buildUploadDocumentsContent()),
                        const SizedBox(height: 16),
                        _buildDeclarationCheckbox(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildProceedButton(productState),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(int number, String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E5EA), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(radius: 14, backgroundColor: const Color(0xFF2C2C2E), child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 12))),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Plan plan, String productName) {
    final base = plan.premium.toDouble();
    final discountAmount = (base * _discountPercentage / 100);
    final afterDiscount = base - discountAmount;
    final gstAmount = (afterDiscount * _gstPercentage / 100);
    final total = afterDiscount + gstAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Summary',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              if (!_priceSettingsLoaded)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Plan', productName, isValueBold: true),
          _buildSummaryRow(
              'Sum Insured', '₹${plan.coverageAmount}',
              isValueBold: true),
          _buildSummaryRow(
              'Duration', '${plan.durationMonths ~/ 12} Year',
              isValueBold: true),
          const Divider(height: 32),
          _buildSummaryRow(
              'Base Premium', '₹${base.toStringAsFixed(2)}'),
          if (_discountPercentage > 0)
            _buildSummaryRow(
              'Discount (${_discountPercentage.toStringAsFixed(0)}%)',
              '- ₹${discountAmount.toStringAsFixed(2)}',
              color: Colors.green,
            ),
          _buildSummaryRow(
              'GST (${_gstPercentage.toStringAsFixed(0)}%)',
              '₹${gstAmount.toStringAsFixed(2)}'),
          const Divider(height: 32),
          _buildSummaryRow(
            'Total Payable (Est.)',
            '₹${total.toStringAsFixed(2)}',
            isLabelBold: true,
            isValueBold: true,
          ),
          const SizedBox(height: 8),
          const Text(
            '* Final amount is confirmed after admin approval and calculated by the server.',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isLabelBold = false, bool isValueBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: isLabelBold ? FontWeight.w700 : FontWeight.w500, color: color ?? const Color(0xFF8E8E93))),
          Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: isValueBold ? FontWeight.w700 : FontWeight.w500, color: color ?? Colors.black)),
        ],
      ),
    );
  }

  Widget _buildUserInformationContent() => Column(children: [
    _buildTextField('Full Name', 'Enter full name', controller: _nameController),
    const SizedBox(height: 12),
    _buildTextField('Mobile Number', 'Enter mobile number', controller: _phoneController, keyboardType: TextInputType.phone),
    const SizedBox(height: 12),
    _buildTextField('Email Address', 'Enter email address', controller: _emailController, keyboardType: TextInputType.emailAddress),
  ]);

  Widget _buildInstallationAddressContent() => Column(children: [
    _buildTextField('House / Shop No.', 'Enter house / shop no.', controller: _houseController),
    const SizedBox(height: 12),
    _buildTextField('Area / Locality', 'Enter area / locality', controller: _areaController),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _buildTextField('City', 'Enter city', controller: _cityController)),
      const SizedBox(width: 12),
      Expanded(child: _buildTextField('District', 'Enter district', controller: _districtController)),
    ]),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _buildTextField('State', 'Enter state', controller: _stateController)),
      const SizedBox(width: 12),
      Expanded(child: _buildTextField('PIN Code', 'Enter PIN code', controller: _pinController, keyboardType: TextInputType.number)),
    ]),
  ]);

  Widget _buildSolarInstallationDetailsContent() => Column(children: [
    Row(children: [
      Expanded(child: _buildTextField('Capacity (kW) / Size', 'e.g. 5', controller: _capacityController, keyboardType: TextInputType.number)),
      const SizedBox(width: 12),
      Expanded(child: _buildDateField('Installation Date', 'e.g. 15-06-2026')),
    ]),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _buildTextField('Brand / Manufacturer', 'e.g. Tata Solar', controller: _brandController)),
      const SizedBox(width: 12),
      Expanded(child: _buildTextField('Installer / Contractor', 'e.g. Green Energy', controller: _installerController)),
    ]),
  ]);

  Widget _buildUploadDocumentsContent() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _buildUploadLabel('INVOICE FILE'),
    const SizedBox(height: 8),
    _invoiceName == null
        ? _buildDropZone(icon: Icons.upload_file_outlined, title: 'Upload Invoice', subtitle: 'PDF or Image (Max 10MB)', onTap: _pickInvoice)
        : _buildFileChip(icon: Icons.insert_drive_file_outlined, name: _invoiceName!, onRemove: () => setState(() => _invoiceName = null)),
    const SizedBox(height: 20),
    _buildUploadLabel('SITE INSTALLATION PHOTOS (OPTIONAL)'),
    const SizedBox(height: 8),
    Row(children: List.generate(4, (i) => Expanded(child: Padding(padding: EdgeInsets.only(right: i < 3 ? 8 : 0), child: _buildPhotoBox(i))))),
    const SizedBox(height: 20),
    _buildUploadLabel('SITE VIDEO (OPTIONAL)'),
    const SizedBox(height: 8),
    _videoName == null
        ? _buildDropZone(icon: Icons.videocam_outlined, title: 'Upload Site Video', subtitle: 'MP4, WebM, MOV (Max 100MB)', onTap: _pickVideo)
        : _buildFileChip(icon: Icons.video_file_outlined, name: _videoName!, onRemove: () => setState(() => _videoName = null)),
    const SizedBox(height: 20),
    _buildInlineCheckbox(value: _confirmNoDamage, onChanged: (v) => setState(() => _confirmNoDamage = v ?? false), label: 'I confirm that the product has no damage and is not pre-repaired.'),
  ]);

  Widget _buildUploadLabel(String label) => Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93), letterSpacing: 0.5));

  Widget _buildDropZone({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: DashedBorderBox(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 28, color: const Color(0xFF8E8E93)),
      const SizedBox(height: 8),
      Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF8E8E93))),
    ])),
  );

  Widget _buildFileChip({required IconData icon, required String name, required VoidCallback onRemove}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: const Color(0xFFF0FFF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF34C759), width: 1)),
    child: Row(children: [
      Icon(icon, size: 22, color: const Color(0xFF34C759)),
      const SizedBox(width: 10),
      Expanded(child: Text(name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black), overflow: TextOverflow.ellipsis)),
      GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 18, color: Color(0xFF8E8E93))),
    ]),
  );

  Widget _buildPhotoBox(int index) => GestureDetector(
    onTap: () => _pickPhoto(index),
    child: AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(10), border: Border.all(color: _photoIds[index] != null ? const Color(0xFF34C759) : const Color(0xFFD1D1D6), width: 1)),
        child: Icon(_photoIds[index] != null ? Icons.check_circle : Icons.upload_rounded, size: 22, color: _photoIds[index] != null ? Colors.green : const Color(0xFF8E8E93)),
      ),
    ),
  );

  Widget _buildInlineCheckbox({required bool value, required ValueChanged<bool?> onChanged, required String label}) => Row(children: [
    Checkbox(value: value, onChanged: onChanged, activeColor: const Color(0xFF2C2C2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
    Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black))),
  ]);

  Widget _buildDeclarationCheckbox() => Row(children: [
    Checkbox(value: _confirmDeclaration, onChanged: (v) => setState(() => _confirmDeclaration = v ?? false), activeColor: const Color(0xFF2C2C2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
    const Expanded(child: Text('I hereby declare that the details provided above are true.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black))),
  ]);

  Widget _buildProceedButton(ProductLoaded state) => Container(
    padding: const EdgeInsets.all(16),
    color: Colors.white,
    child: SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2C2E), disabledBackgroundColor: const Color(0xFFD1D1D6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: (_confirmNoDamage && _confirmDeclaration) ? () async {
          NotificationService.mediumImpact();
          // SECTION 10: Input Validation
          final nameErr = InputValidator.required(_nameController.text, 'Full Name');
          final phoneErr = InputValidator.phone(_phoneController.text);
          final emailErr = InputValidator.email(_emailController.text);
          
          if (nameErr != null || phoneErr != null || emailErr != null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(nameErr ?? phoneErr ?? emailErr!)));
            return;
          }

          final rawValues = [
            {'name': 'fullName', 'val': _nameController.text.trim()},
            {'name': 'mobile', 'val': _phoneController.text.trim()},
            {'name': 'email', 'val': _emailController.text.trim()},
            {'name': 'address', 'val': '${_houseController.text.trim()}, ${_areaController.text.trim()}'},
            {'name': 'city', 'val': _cityController.text.trim()},
            {'name': 'district', 'val': _districtController.text.trim()},
            {'name': 'state', 'val': _stateController.text.trim()},
            {'name': 'pinCode', 'val': _pinController.text.trim()},
            {'name': 'capacity', 'val': _capacityController.text.trim()},
            {'name': 'brand', 'val': _brandController.text.trim()},
            {'name': 'installationDate', 'val': _installationDate?.toIso8601String() ?? ''},
            {'name': 'invoice', 'val': _invoiceId ?? ''},
            {'name': 'siteVideo', 'val': _videoId ?? ''},
          ];

          final List<Map<String, dynamic>> fieldValues = [];
          for (var input in rawValues) {
            final def = _fieldDefinitions.where((d) => d.fieldName == input['name']).firstOrNull;
            if (def != null) {
              fieldValues.add({'productField': def.id, 'fieldName': input['name'], 'fieldValue': input['val']});
            }
          }

          try {
            if (!mounted) return;
            setState(() => _isLoading = true);
            final apiService = context.read<ApiService>();
            
            Map<String, dynamic>? application;
            try {
              application = await apiService.submitApplication({'planId': state.selectedPlan!.id, 'fieldValues': fieldValues});
            } on DioException catch (e) {
              // SECTION 2: 409 Conflict Handling
              if (e.response?.statusCode == 409) {
                final existing = await apiService.getMyApplications();
                application = existing.where((a) => a['planId'] == state.selectedPlan!.id || a['plan']?['_id'] == state.selectedPlan!.id).firstOrNull;
                if (application == null) throw Exception('Conflict detected but existing application not found.');
              } else {
                rethrow;
              }
            }

            final status = (application['status'] as String? ?? '').toUpperCase();
            if (!mounted) return;

            // TESTING BYPASS: Allow SUBMITTED/UNDER_REVIEW to proceed to consent & payment
            if (status == 'APPROVED') {
              _showConsentAndNavigate(application);
            } else if (status == 'SUBMITTED' || status == 'UNDER_REVIEW') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(
                    'Your application is under review. '
                        'You can proceed to payment once an admin approves it.'
                )),
              );
            } else if (status == 'REJECTED') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(
                    'Your application was rejected. Please contact support.'
                )),
              );
            } else if (status == 'REJECTED') {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your application was rejected. Please contact support.')));
            }
          } on DioException catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.response?.data['message'] ?? 'Submission failed')));
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        } : null,
        child: const Text('Proceed to Payment', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      ),
    ),
  );

  void _showConsentAndNavigate(Map<String, dynamic> app) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Consent',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: const Text(
                    'Required Consent',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  content: const Text(
                    'By proceeding, you agree to the terms and conditions of this insurance policy and confirm that all provided information is accurate.',
                    style: TextStyle(
                      height: 1.5,
                    ),
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        NotificationService.heavyImpact();
                        try {
                          final api = context.read<ApiService>();

                          await api.recordConsent(
                            app['_id'] ?? app['id'],
                          );

                          NotificationService.successHaptic();
                          NotificationService.showNotification(
                            id: 1,
                            title: 'Consent Recorded',
                            body: 'Your insurance application is now being processed.',
                          );

                          if (!context.mounted) return;

                          Navigator.pop(context);

                          _navigateToPreview(app);
                        } on DioException catch (e) {
                          if (e.response?.statusCode == 404) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Consent record not found. Please ensure your application has been approved by an admin first.',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to record consent: ${e.response?.data?["message"] ?? e.message}',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                            ),
                          );
                        }
                      },
                      child: const Text('I Agree'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.92,
              end: 1.0,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _navigateToPreview(Map<String, dynamic> app) async {
    final productLoaded = context.read<ProductBloc>().state as ProductLoaded;
    final apiService = context.read<ApiService>();
    final plan = productLoaded.selectedPlan!;

    try {
      final order = await apiService.createOrder(
        applicationId: app['_id'] ?? app['id'],
        planId: plan.id,
      );

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPreviewScreen(
        product: productLoaded.selectedProduct.name,
        basePremium: (order['subtotal'] ?? 0).toDouble(),
        years: plan.durationMonths ~/ 12,
        planId: plan.id,                    // ← ADD
        applicationId: app['_id'] ?? app['id'],
        orderData: order,
      )));
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data?['message']?.toString() ?? '';
      if (e.response?.statusCode == 400 && message.toLowerCase().contains('approved')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
              'Your application is pending admin approval. '
                  'You will be notified once approved.'
          )),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.isNotEmpty ? message : 'Order creation failed.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildTextField(
      String label,
      String hint, {
        TextEditingController? controller,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3A3A3C),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111111),
          ),
          cursorColor: Color(0xFF111111),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF9A9AA0),
            ),

            filled: true,
            fillColor: const Color(0xFFF7F7F8),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE8E8ED),
                width: 1,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF1A1A1A),
                width: 1.4,
              ),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFD64545),
                width: 1,
              ),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFD64545),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String hint) {
    _dateController.text = _installationDate == null
        ? ''
        : DateFormat('dd MMM yyyy').format(_installationDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3A3A3C),
            letterSpacing: .2,
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: _dateController,
          readOnly: true,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111111),
          ),
          onTap: () async {
            FocusScope.of(context).unfocus();

            final picked = await showDatePicker(
              context: context,
              initialDate: _installationDate ?? DateTime.now(),
              firstDate: DateTime(2010),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF111111),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Color(0xFF111111),
                    ),
                    dialogTheme: DialogThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    scale: 0.9,
                    child: child!,
                  ),
                );
              },
            );

            if (picked != null) {
              setState(() {
                _installationDate = picked;
                _dateController.text =
                    DateFormat('dd MMM yyyy').format(picked);
              });
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              color: Color(0xFF9A9AA0),
            ),

            filled: true,
            fillColor: const Color(0xFFF7F7F8),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),

            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: Color(0xFF6E6E73),
              ),
            ),

            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE8E8ED),
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF111111),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DashedBorderBox extends StatelessWidget {
  final Widget child;
  const DashedBorderBox({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 28), child: child);
}
