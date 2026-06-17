import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../payment/payment_screen.dart';
import '../bloc/product_bloc.dart';
import '../../../../core/bloc/auth_bloc.dart';

class InsuranceDetailScreen extends StatefulWidget {
  const InsuranceDetailScreen({super.key});

  @override
  State<InsuranceDetailScreen> createState() => _InsuranceDetailScreenState();
}

class _InsuranceDetailScreenState extends State<InsuranceDetailScreen> {
  bool _confirmNoDamage = false;
  bool _confirmDeclaration = false;

  // Controllers for auto-fill
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Upload state
  PlatformFile? _invoiceFile;
  final List<XFile?> _sitePhotos = [null, null, null, null];
  PlatformFile? _siteVideoFile;

  // Date state
  DateTime? _installationDate;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _autoFillUser();
  }

  void _autoFillUser() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _nameController.text = authState.user.name;
      _phoneController.text = authState.user.phone;
      _emailController.text = authState.user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickInvoice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final sizeInMB = (file.size) / (1024 * 1024);
      if (sizeInMB > 10) {
        _showSizeError('Invoice must be under 10 MB.');
        return;
      }
      setState(() => _invoiceFile = file);
    }
  }

  void _removeInvoice() => setState(() => _invoiceFile = null);

  Future<void> _pickPhoto(int index) async {
    final source = await _showImageSourceSheet();
    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (picked != null) {
      setState(() => _sitePhotos[index] = picked);
    }
  }

  void _removePhoto(int index) => setState(() => _sitePhotos[index] = null);

  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'webm', 'mov'],
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final sizeInMB = (file.size) / (1024 * 1024);
      if (sizeInMB > 100) {
        _showSizeError('Video must be under 100 MB.');
        return;
      }
      setState(() => _siteVideoFile = file);
    }
  }

  void _removeVideo() => setState(() => _siteVideoFile = null);

  void _showSizeError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        backgroundColor: const Color(0xFF2C2C2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _truncateName(String name, {int max = 24}) =>
      name.length > max ? '${name.substring(0, max)}…' : name;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, productState) {
        if (productState is! ProductLoaded) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Fill Insurance Detail',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: const Color(0xFFE5E5EA), height: 1.0),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderSummary(productState),
                        const SizedBox(height: 16),
                        _buildSection(1, 'User Information',
                            _buildUserInformationContent()),
                        const SizedBox(height: 16),
                        _buildSection(2, 'Installation Address',
                            _buildInstallationAddressContent()),
                        const SizedBox(height: 16),
                        _buildSection(3, 'Solar Installation Details',
                            _buildSolarInstallationDetailsContent()),
                        const SizedBox(height: 16),
                        _buildSection(
                          4,
                          'Upload Documents',
                          _buildUploadDocumentsContent(),
                          subtitle:
                          'Please upload files as requested. Invoice is required; site photos and videos are optional.',
                        ),
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

  Widget _buildSection(int number, String title, Widget content,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF2C2C2E),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('$number',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    )),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                )),
          ],
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ProductLoaded state) {
    const processingFee = 50.0;
    final gstAmount = state.totalPrice * 0.18;
    final totalPayable = state.totalPrice + gstAmount + processingFee;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              )),
          const SizedBox(height: 16),
          _buildSummaryRow('Plan', 'Solar Insurance', isValueBold: true),
          const SizedBox(height: 8),
          _buildSummaryRow('Sum Insured', state.selectedVariant.name, isValueBold: true),
          const SizedBox(height: 8),
          _buildSummaryRow('Duration', state.selectedDuration, isValueBold: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Color(0xFFE5E5EA), height: 1),
          ),
          _buildSummaryRow('Base Premium', '₹${state.totalPrice.toStringAsFixed(2)}',
              color: const Color(0xFF8E8E93)),
          const SizedBox(height: 8),
          _buildSummaryRow('GST (18%)', '₹${gstAmount.toStringAsFixed(2)}',
              color: const Color(0xFF8E8E93)),
          const SizedBox(height: 8),
          _buildSummaryRow('Taxes & Charges', '₹${processingFee.toStringAsFixed(2)}',
              color: const Color(0xFF8E8E93)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Color(0xFFE5E5EA), height: 1),
          ),
          _buildSummaryRow('Total Payable', '₹ ${totalPayable.toStringAsFixed(2)}',
              isLabelBold: true, isValueBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isLabelBold = false, bool isValueBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: isLabelBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? const Color(0xFF8E8E93),
            )),
        Text(value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: isValueBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? Colors.black,
            )),
      ],
    );
  }

  Widget _buildUserInformationContent() {
    return Column(children: [
      _buildTextField('Full Name', 'Enter full name', controller: _nameController),
      const SizedBox(height: 16),
      _buildTextField('Mobile Number', 'Enter mobile number',
          keyboardType: TextInputType.phone, controller: _phoneController),
      const SizedBox(height: 16),
      _buildTextField('Email Address', 'Enter email address',
          keyboardType: TextInputType.emailAddress, controller: _emailController),
    ]);
  }

  Widget _buildInstallationAddressContent() {
    return Column(children: [
      _buildTextField('House / Shop No.', 'Enter house / shop no.'),
      const SizedBox(height: 16),
      _buildTextField('Area / Locality', 'Enter area / locality'),
      const SizedBox(height: 16),
      _buildTextField('City', 'Enter city'),
      const SizedBox(height: 16),
      _buildTextField('District', 'Enter district'),
      const SizedBox(height: 16),
      _buildTextField('State', 'Enter state'),
      const SizedBox(height: 16),
      _buildTextField('PIN Code', 'Enter PIN code',
          keyboardType: TextInputType.number),
    ]);
  }

  Widget _buildSolarInstallationDetailsContent() {
    return Column(children: [
      Row(children: [
        Expanded(
            child: _buildTextField('Capacity (kW) / Size', 'e.g. 5',
                keyboardType: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _buildDateField('Installation Date', 'e.g. 15-06-2026')),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
            child:
            _buildTextField('Brand / Manufacturer', 'e.g. Tata Solar')),
        const SizedBox(width: 12),
        Expanded(
            child: _buildTextField(
                'Installer / Contractor', 'e.g. Green Energy Solutions')),
      ]),
    ]);
  }

  Widget _buildUploadDocumentsContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildUploadLabel('INVOICE FILE'),
      const SizedBox(height: 8),
      _invoiceFile == null
          ? _buildDropZone(
        icon: Icons.upload_file_outlined,
        title: 'Upload Invoice',
        subtitle: 'PDF or Image (Max 10MB)',
        onTap: _pickInvoice,
      )
          : _buildFileChip(
        icon: Icons.insert_drive_file_outlined,
        name: _truncateName(_invoiceFile!.name),
        size: _formatBytes(_invoiceFile!.size),
        onRemove: _removeInvoice,
      ),

      const SizedBox(height: 20),

      _buildUploadLabel('SITE INSTALLATION PHOTOS (OPTIONAL)'),
      const SizedBox(height: 8),
      Row(
        children: List.generate(4, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
              child: _buildPhotoBox(i),
            ),
          );
        }),
      ),

      const SizedBox(height: 20),

      _buildUploadLabel('SITE VIDEO (OPTIONAL)'),
      const SizedBox(height: 8),
      _siteVideoFile == null
          ? _buildDropZone(
        icon: Icons.videocam_outlined,
        title: 'Upload Site Video',
        subtitle: 'MP4, WebM, MOV (Max 100MB)',
        onTap: _pickVideo,
      )
          : _buildFileChip(
        icon: Icons.video_file_outlined,
        name: _truncateName(_siteVideoFile!.name),
        size: _formatBytes(_siteVideoFile!.size),
        onRemove: _removeVideo,
      ),

      const SizedBox(height: 20),

      _buildInlineCheckbox(
        value: _confirmNoDamage,
        onChanged: (v) => setState(() => _confirmNoDamage = v ?? false),
        label: 'I confirm that the product has no damage and is not pre-repaired.',
      ),
    ]);
  }

  Widget _buildUploadLabel(String label) {
    return Text(label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
          letterSpacing: 0.5,
        ));
  }

  Widget _buildDropZone({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: DashedBorderBox(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 28, color: const Color(0xFF8E8E93)),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              )),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF8E8E93),
              )),
        ]),
      ),
    );
  }

  Widget _buildFileChip({
    required IconData icon,
    required String name,
    required String size,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF34C759), width: 1),
      ),
      child: Row(children: [
        Icon(icon, size: 22, color: const Color(0xFF34C759)),
        const SizedBox(width: 10),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  )),
              Text(size,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF8E8E93),
                  )),
            ])),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close, size: 18, color: Color(0xFF8E8E93)),
        ),
      ]),
    );
  }

  Widget _buildPhotoBox(int index) {
    final photo = _sitePhotos[index];
    return GestureDetector(
      onTap: () => photo == null ? _pickPhoto(index) : null,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: photo != null
                      ? const Color(0xFF34C759)
                      : const Color(0xFFD1D1D6),
                  width: 1,
                ),
              ),
              child: photo == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_rounded,
                      size: 22, color: Color(0xFF8E8E93)),
                  const SizedBox(height: 6),
                  Text('Photo ${index + 1}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF8E8E93),
                      )),
                ],
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.file(
                  File(photo.path),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (photo != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removePhoto(index),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C2C2E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2C2C2E),
            side: const BorderSide(color: Color(0xFFD1D1D6), width: 1.5),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black,
                  height: 1.5,
                ))),
      ]),
    );
  }

  Widget _buildDeclarationCheckbox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _confirmDeclaration,
            onChanged: (v) =>
                setState(() => _confirmDeclaration = v ?? false),
            activeColor: const Color(0xFF2C2C2E),
            side: const BorderSide(color: Color(0xFFD1D1D6), width: 1.5),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.black,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text:
                  'I hereby declare that the details provided above are true and accurate to the best of my knowledge. '
                      'I understand that any discrepancy found later may lead to policy cancellation or claim rejection. '
                      'I accept the ',
                ),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildProceedButton(ProductLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, -4))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: (_confirmNoDamage && _confirmDeclaration)
              ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentPreviewScreen(
                  product: 'Solar Insurance',
                  basePremium: state.totalPrice,
                  gstRate: 0.18,
                  processingFee: 50,
                  years: int.parse(state.selectedDuration.replaceAll('y', '')),
                  applicationId: '6a2ba7e8a3bc85617000bad2',
                  onPayNow: (finalAmount) {},
                ),
              ),
            );
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C2C2E),
            disabledBackgroundColor: const Color(0xFFD1D1D6),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Proceed to Payment',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              )),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint,
      {TextInputType keyboardType = TextInputType.text, TextEditingController? controller}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          )),
      const SizedBox(height: 8),
      SizedBox(
        height: 44,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 13, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontFamily: 'Poppins', fontSize: 12, color: Color(0xFFC7C7CC)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: Color(0xFFE5E5EA), width: 1)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: Color(0xFFE5E5EA), width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: Color(0xFF2C2C2E), width: 1.5)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildDateField(String label, String hint) {
    final displayText = _installationDate != null
        ? '${_installationDate!.day.toString().padLeft(2, '0')}-'
        '${_installationDate!.month.toString().padLeft(2, '0')}-'
        '${_installationDate!.year}'
        : '';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          )),
      const SizedBox(height: 8),
      SizedBox(
        height: 44,
        child: TextField(
          readOnly: true,
          controller: TextEditingController(text: displayText),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _installationDate ?? DateTime.now(),
              firstDate: DateTime(2010),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF2C2C2E),
                    onPrimary: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _installationDate = picked);
          },
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 13, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontFamily: 'Poppins', fontSize: 12, color: Color(0xFFC7C7CC)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            suffixIcon: const Icon(Icons.calendar_today_outlined,
                size: 18, color: Color(0xFF8E8E93)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: Color(0xFFE5E5EA), width: 1)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: Color(0xFFE5E5EA), width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: Color(0xFF2C2C2E), width: 1.5)),
          ),
        ),
      ),
    ]);
  }
}

class DashedBorderBox extends StatelessWidget {
  final Widget child;
  final double dashWidth;
  final double dashGap;
  final Color color;
  final double borderRadius;

  const DashedBorderBox({
    super.key,
    required this.child,
    this.dashWidth = 6,
    this.dashGap = 4,
    this.color = const Color(0xFFD1D1D6),
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        dashWidth: dashWidth,
        dashGap: dashGap,
        color: color,
        radius: borderRadius,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double dashWidth;
  final double dashGap;
  final Color color;
  final double radius;

  _DashedBorderPainter({
    required this.dashWidth,
    required this.dashGap,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
