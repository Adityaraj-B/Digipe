import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../bloc/claims_bloc.dart';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedPolicyId;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _evidenceFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dateController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final size = await file.length();
      if (size > 10 * 1024 * 1024) {
        _showError('Image must be under 10 MB.');
        return;
      }
      setState(() => _evidenceFiles.add(file));
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final size = await file.length();
      if (size > 50 * 1024 * 1024) {
        _showError('Video must be under 50 MB.');
        return;
      }
      setState(() => _evidenceFiles.add(file));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF1A1A1A)),
              title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF1A1A1A)),
              title: const Text('Choose Photo from Gallery', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined, color: Color(0xFF1A1A1A)),
              title: const Text('Upload Video', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<ClaimsBloc>()..add(FetchClaimsData()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: BlocConsumer<ClaimsBloc, ClaimsState>(
                    listener: (context, state) {
                      if (state is ClaimSubmitSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Claim submitted successfully.'),
                            backgroundColor: Color(0xFF2E7D32),
                          ),
                        );
                        _dateController.clear();
                        _descController.clear();
                        setState(() {
                          _selectedPolicyId = null;
                          _evidenceFiles.clear();
                        });
                        _tabController.animateTo(1);
                      }
                    },
                    builder: (context, state) {
                      if (state is ClaimsLoading || state is ClaimsInitial) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF2C2C2E)),
                        );
                      } else if (state is ClaimsError) {
                        return Center(child: Text(state.message));
                      } else if (state is ClaimsLoaded) {
                        return _buildContent(context, state.data);
                      } else if (state is ClaimSubmitting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF2C2C2E)),
                              SizedBox(height: 16),
                              Text('Submitting your claim...',
                                  style: TextStyle(color: Color(0xFF8E8E93))),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'DIGIPE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 24, color: const Color(0xFFE5E5EA)),
          const SizedBox(width: 16),
          const Text(
            'Hello, +917206787699',
            style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE5E5EA),
            child: Icon(Icons.person, size: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Claims Center',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Raise a new claim or track existing ones.',
            style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 24),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF1A1A1A),
            labelColor: const Color(0xFF1A1A1A),
            unselectedLabelColor: const Color(0xFF8E8E93),
            labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Raise a Claim'),
              Tab(text: 'Track Claims'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ClaimsData data) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRaiseClaimTab(context, data),
            _buildTrackClaimsTab(data),
          ],
        ),
      ),
    );
  }

  Widget _buildRaiseClaimTab(BuildContext context, ClaimsData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Incident Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                const Text('Select Policy',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPolicyId,
                  decoration: _inputDecoration('Choose an active policy'),
                  items: data.eligiblePolicies.map((policy) {
                    return DropdownMenuItem(
                      value: policy.id,
                      child: Text(policy.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedPolicyId = value),
                ),
                const SizedBox(height: 20),
                const Text('Date of Incident',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: _inputDecoration('DD/MM/YYYY').copyWith(
                    suffixIcon: const Icon(Icons.calendar_today_outlined,
                        size: 18, color: Color(0xFF8E8E93)),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      _dateController.text = '${date.day}/${date.month}/${date.year}';
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text('Describe the Incident',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: _inputDecoration('Provide details about the damage or loss...'),
                ),
                const SizedBox(height: 24),
                const Text('Upload Evidence (Optional)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showAttachmentOptions,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 32, color: Color(0xFF8E8E93)),
                        SizedBox(height: 12),
                        Text('Click to upload photos or videos',
                            style: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500)),
                        SizedBox(height: 4),
                        Text('Max file size: 10MB (Image) / 50MB (Video)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                      ],
                    ),
                  ),
                ),
                if (_evidenceFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(_evidenceFiles.length, (index) {
                      final file = _evidenceFiles[index];
                      final isVideo = file.path.toLowerCase().endsWith('.mp4') ||
                          file.path.toLowerCase().endsWith('.mov');
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                              size: 16,
                              color: const Color(0xFF1A1A1A),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 100),
                              child: Text(
                                file.path.split('/').last,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _evidenceFiles.removeAt(index)),
                              child: const Icon(Icons.close, size: 16, color: Color(0xFF8E8E93)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_selectedPolicyId != null && _dateController.text.isNotEmpty && _descController.text.isNotEmpty)
                  ? () {
                BlocProvider.of<ClaimsBloc>(context).add(
                  SubmitClaimEvent(
                    policyId: _selectedPolicyId!,
                    incidentDate: _dateController.text,
                    description: _descController.text,
                    evidencePaths: _evidenceFiles.map((e) => e.path).toList(),
                  ),
                );
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E5EA),
                disabledForegroundColor: const Color(0xFF8E8E93),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Submit Claim', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackClaimsTab(ClaimsData data) {
    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: data.claimHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final claim = data.claimHistory[index];
        return _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Claim ID', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                      const SizedBox(height: 4),
                      Text(claim.claimId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  _buildStatusBadge(claim.status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Policy', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                      const SizedBox(height: 4),
                      Text(claim.policyName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Date Filed', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                      const SizedBox(height: 4),
                      Text(claim.date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFC7C7CC)),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'pending':
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF57F17);
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF555555);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}