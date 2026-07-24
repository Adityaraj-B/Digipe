import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../bloc/claims_bloc.dart';
import '../../../core/services/api_service.dart';

const _kDamageTypes = <String>[
  'Panel Damage / Breakage',
  'Inverter Failure',
  'Fire Damage',
  'Storm / Natural Calamity',
  'Theft',
  'Installation Defect',
  'Other',
];

class RaiseClaimDialog extends StatefulWidget {
  final String policyId;
  final String policyNumber;
  final num coverageAmount;

  const RaiseClaimDialog({
    super.key,
    required this.policyId,
    required this.policyNumber,
    required this.coverageAmount,
  });

  @override
  State<RaiseClaimDialog> createState() => _RaiseClaimDialogState();
}

class _RaiseClaimDialogState extends State<RaiseClaimDialog> {
  DateTime? _dateOfDamage;
  String? _damageType;

  final List<String?> _imageIds = List.filled(5, null);
  final List<String?> _imageUrls = List.filled(5, null);
  final List<bool> _imageUploading = List.filled(5, false);

  String? _videoId;
  String? _videoName;
  bool _videoUploading = false;

  final _reasonController = TextEditingController();
  bool _consent = false;
  bool _submitAttempted = false;

  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(int index) async {
    final img = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1920);
    if (img == null) return;
    setState(() => _imageUploading[index] = true);
    try {
      if (!mounted) return;
      final doc = await context.read<ApiService>().uploadDocumentFull(img.path);
      setState(() {
        _imageUrls[index] = doc['url'];
        _imageIds[index] = doc['_id'] ?? doc['id'];
      });
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      setState(() => _imageUploading[index] = false);
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.video, allowMultiple: false);
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _videoUploading = true);
    try {
      if (!mounted) return;
      final doc = await context.read<ApiService>().uploadDocumentFull(path);
      setState(() {
        _videoId = doc['_id'] ?? doc['id'];
        _videoName = result!.files.single.name;
      });
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      setState(() => _videoUploading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _isValid =>
      _dateOfDamage != null &&
      _damageType != null &&
      _imageIds[0] != null &&
      _reasonController.text.trim().isNotEmpty &&
      _consent &&
      !_imageUploading.contains(true) &&
      !_videoUploading;

  void _submit() {
    setState(() => _submitAttempted = true);
    if (!_isValid) return;

    final imageIds = _imageIds.whereType<String>().toList();
    final videoIds = _videoId != null ? [_videoId!] : <String>[];

    context.read<ClaimsBloc>().add(SubmitClaimEvent(
          policyId: widget.policyId,
          typeOfDamage: _damageType,
          description: _reasonController.text.trim(),
          claimAmount: widget.coverageAmount,
          incidentDate: _dateOfDamage,
          imageIds: imageIds,
          videoIds: videoIds,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClaimsBloc, ClaimsState>(
      listener: (context, state) {
        if (state is ClaimSubmitSuccess) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Claim submitted successfully.')),
          );
        } else if (state is ClaimsError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Dialog(
        backgroundColor: Theme.of(context).cardColor,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFE0554B), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raise Insurance Claim (${widget.policyNumber})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('DATE OF DAMAGE'),
                      const SizedBox(height: 6),
                      _dateField(),
                      const SizedBox(height: 18),
                      _label('TYPE OF DAMAGE'),
                      const SizedBox(height: 6),
                      _damageDropdown(),
                      const SizedBox(height: 18),
                      _label(
                          'UPLOAD DAMAGE PHOTOS (PHOTO 1 COMPULSORY, 2-5 OPTIONAL)'),
                      const SizedBox(height: 8),
                      _photoGrid(),
                      const SizedBox(height: 18),
                      _label('UPLOAD DAMAGE VIDEO (OPTIONAL)'),
                      const SizedBox(height: 8),
                      _videoUploadBox(),
                      const SizedBox(height: 18),
                      _label('EXPLAIN REASON / DETAILS'),
                      const SizedBox(height: 6),
                      _reasonField(),
                      const SizedBox(height: 16),
                      _consentCheckbox(),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    BlocBuilder<ClaimsBloc, ClaimsState>(
                      builder: (context, state) {
                        final loading = state is ClaimSubmitting;
                        return ElevatedButton(
                          onPressed: loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE98B8B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 12),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Confirm Claim',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            letterSpacing: 0.3),
      );

  InputDecoration _decoration({Widget? suffix, String? hint, String? error}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: isDark
            ? const BorderSide(color: Color(0xFF3A3A3C))
            : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: isDark
            ? const BorderSide(color: Color(0xFF3A3A3C))
            : BorderSide.none,
      ),
      suffixIcon: suffix,
      errorText: error,
    );
  }

  Widget _dateField() {
    final invalid = _submitAttempted && _dateOfDamage == null;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _dateOfDamage = picked);
      },
      child: InputDecorator(
        decoration: _decoration(
          hint: 'Select damage date',
          suffix: const Icon(Icons.calendar_today_outlined, size: 18),
          error: invalid ? 'Required' : null,
        ),
        child: Text(_dateOfDamage == null
            ? ''
            : '${_dateOfDamage!.day}/${_dateOfDamage!.month}/${_dateOfDamage!.year}'),
      ),
    );
  }

  Widget _damageDropdown() {
    final invalid = _submitAttempted && _damageType == null;
    return DropdownButtonFormField<String>(
      initialValue: _damageType,
      isDense: true,
      isExpanded: true,
      dropdownColor: Theme.of(context).cardColor,
      decoration: _decoration(
          hint: 'Select damage type...', error: invalid ? 'Required' : null),
      items: _kDamageTypes
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text(
                t,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _damageType = v),
    );
  }

  Widget _photoGrid() {
    final invalid = _submitAttempted && _imageIds[0] == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            final url = _imageUrls[i];
            final isUploading = _imageUploading[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 4 ? 0 : 8),
                child: GestureDetector(
                  onTap: () => _pickPhoto(i),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: i == 0
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF3D2323)
                                : const Color(0xFFFCEAEA))
                            : (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2C2C2E)
                                : Colors.grey.shade50),
                        border: Border.all(
                            color: i == 0
                                ? const Color(0xFFE0A9A6)
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF3A3A3C)
                                    : Colors.grey.shade300)),
                      ),
                      child: isUploading
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : url != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(url, fit: BoxFit.cover),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _imageUrls[i] = null;
                                            _imageIds[i] = null;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle),
                                            child: const Icon(Icons.close,
                                                size: 12, color: Colors.white),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('+${i + 1}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: i == 0
                                                  ? const Color(0xFFE0554B)
                                                  : Colors.grey.shade500)),
                                      if (i == 0)
                                        const Text('Req',
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: Color(0xFFE0554B))),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (invalid)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Photo 1 is required',
                style: TextStyle(color: Colors.red, fontSize: 11)),
          ),
      ],
    );
  }

  Widget _videoUploadBox() {
    return GestureDetector(
      onTap: _pickVideo,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2E)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF3A3A3C)
                : Colors.grey.shade300,
          ),
        ),
        child: _videoUploading
            ? const Column(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 8),
                  Text('Uploading...',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              )
            : Column(
                children: [
                  Icon(Icons.videocam_outlined,
                      color: Colors.grey.shade500, size: 26),
                  const SizedBox(height: 8),
                  Text(
                    _videoId == null
                        ? 'Upload Damage Video'
                        : _videoName ?? 'Video Uploaded',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text('MP4, WebM, MOV (Max 50MB)',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  if (_videoId != null)
                    TextButton(
                      onPressed: () => setState(() {
                        _videoId = null;
                        _videoName = null;
                      }),
                      child:
                          const Text('Remove', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _reasonField() {
    final invalid = _submitAttempted && _reasonController.text.trim().isEmpty;
    return TextField(
      controller: _reasonController,
      maxLines: 4,
      decoration: _decoration(
          hint: 'Provide details about the damage incident...',
          error: invalid ? 'Required' : null),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _consentCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'I confirm that all given details are correct and the uploaded photos accurately represent the damage.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ),
      ],
    );
  }
}
