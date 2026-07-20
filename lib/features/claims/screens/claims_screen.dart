import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../bloc/claims_bloc.dart';
import '../../../core/widgets/Cards.dart';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedPolicyId;
  DateTime? _incidentDate;
  String? _typeOfDamage;
  bool _consentChecked = false;
  String _searchQuery = '';
  String _filterStatus = 'All Status';
  final List<String> _filterOptions = ['All Status', 'Pending', 'Approved', 'Rejected'];

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final List<File?> _imageFiles = List.filled(5, null);
  File? _videoFile;

  final List<String> _damageTypes = [
    'Storm / Cyclone Damage',
    'Physical Impact',
    'Electrical Breakdown',
    'Fire / Lightning',
    'Theft / Burglary',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<ClaimsBloc>().add(FetchClaimsData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dateController.dispose();
    _descController.dispose();
    super.dispose();
  }

  (Color, Color) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return (AppColors.successBg, AppColors.successFg);
      case 'pending':
        return (AppColors.warnBg, AppColors.warnFg);
      case 'rejected':
      case 'declined':
        return (AppColors.dangerBg, AppColors.dangerFg);
      default:
        return (AppColors.neutralBg, AppColors.neutralFg);
    }
  }

  Future<void> _pickImage(ImageSource source, int index) async {
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
      setState(() => _imageFiles[index] = file);
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
      if (size > 100 * 1024 * 1024) {
        _showError('Video must be under 100 MB.');
        return;
      }
      setState(() => _videoFile = file);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.dangerFg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAttachmentOptions(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.ink),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.ink),
                title: const Text('Choose Photo from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, index);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<ClaimsBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          bottom: false,
          child: PremiumEntrance(
            child: Column(
              children: [
                ScreenHeader(
                  title: 'Claims Center',
                  subtitle: 'Raise a new claim or track existing ones.',
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.inkStrong,
                    labelColor: AppColors.inkStrong,
                    unselectedLabelColor: AppColors.bodyGrey,
                    labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Raise a Claim'),
                      Tab(text: 'Track Claims'),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRect(
                    child: BlocConsumer<ClaimsBloc, ClaimsState>(
                      listener: (context, state) {
                        if (state is ClaimSubmitSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Claim submitted successfully.'),
                              backgroundColor: AppColors.successFg,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          _dateController.clear();
                          _descController.clear();
                          setState(() {
                            _selectedPolicyId = null;
                            _incidentDate = null;
                            _typeOfDamage = null;
                            _consentChecked = false;
                            _imageFiles.fillRange(0, 5, null);
                            _videoFile = null;
                          });
                          _tabController.animateTo(1);
                        }
                      },
                      builder: (context, state) {
                        if (state is ClaimsLoading || state is ClaimsInitial) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.inkStrong, strokeWidth: 2.5),
                          );
                        } else if (state is ClaimsError) {
                          return PremiumEmptyState(
                            icon: Icons.error_outline_rounded,
                            iconBg: AppColors.dangerBg,
                            iconFg: AppColors.dangerFg,
                            message: state.message,
                          );
                        } else if (state is ClaimsLoaded) {
                          return _buildContent(context, state.data);
                        } else if (state is ClaimSubmitting) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const CircularProgressIndicator(
                                    color: AppColors.inkStrong,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Submitting your claim...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.bodyGrey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final canSubmit = _selectedPolicyId != null &&
        _incidentDate != null &&
        _typeOfDamage != null &&
        _descController.text.trim().isNotEmpty &&
        _consentChecked &&
        _imageFiles[0] != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isTiny = constraints.maxWidth < 360;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(isCompact ? 16 : 32, 24, isCompact ? 16 : 32, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Select Policy *'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedPolicyId ?? 'policy_dropdown'),
                      initialValue: _selectedPolicyId,
                      isDense: true,
                      isExpanded: true,
                      decoration: _inputDecoration('Choose an active policy'),
                      items: data.eligiblePolicies.map((policy) {
                        return DropdownMenuItem(
                          value: policy.id,
                          child: Text(
                            policy.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: data.eligiblePolicies.isEmpty
                          ? null
                          : (value) => setState(() => _selectedPolicyId = value),
                    ),
                    if (data.eligiblePolicies.isEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'You have no active policies eligible for a claim.',
                        style: TextStyle(fontSize: 12, color: AppColors.dangerFg),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const _FieldLabel('Date of Damage *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: _inputDecoration('Select damage date').copyWith(
                        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.bodyGrey),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _incidentDate = date;
                            _dateController.text = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('Type of Damage *'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_typeOfDamage ?? 'damage_dropdown'),
                      initialValue: _typeOfDamage,
                      isDense: true,
                      isExpanded: true,
                      decoration: _inputDecoration('Select damage type..'),
                      items: _damageTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _typeOfDamage = value),
                    ),
                    const SizedBox(height: 24),
                    const _FieldLabel('Upload Damage Photos (Photo 1 Compulsory, 2-5 Optional) *'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.start,
                      children: List.generate(5, (index) {
                        final file = _imageFiles[index];
                        final isCompulsory = index == 0;
                        final boxSize = isTiny ? (constraints.maxWidth - 60) / 2 : 72.0;

                        return GestureDetector(
                          onTap: () => _showAttachmentOptions(index),
                          child: SizedBox(
                            width: boxSize,
                            height: boxSize,
                            child: Container(
                              decoration: BoxDecoration(
                                color: file != null ? Colors.transparent : (isCompulsory && file == null ? AppColors.dangerBg.withValues(alpha: 0.2) : AppColors.surface),
                                border: Border.all(
                                  color: isCompulsory && file == null ? AppColors.dangerFg.withValues(alpha: 0.5) : AppColors.border,
                                  style: file != null ? BorderStyle.solid : BorderStyle.none,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: file != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(file, fit: BoxFit.cover),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _imageFiles[index] = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              )
                                  : CustomPaint(
                                painter: DashedBorderPainter(
                                  color: isCompulsory ? AppColors.dangerFg.withValues(alpha: 0.5) : AppColors.border,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '+${index + 1}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isCompulsory ? AppColors.dangerFg : AppColors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (isCompulsory)
                                      const Text(
                                        'Req',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors.dangerFg,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('Upload Damage Video (Optional)'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickVideo,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: CustomPaint(
                          painter: DashedBorderPainter(color: AppColors.border),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            child: _videoFile != null
                                ? Column(
                              children: [
                                const Icon(Icons.video_file_outlined, size: 28, color: AppColors.successFg),
                                const SizedBox(height: 8),
                                Text(
                                  _videoFile!.path.split('/').last,
                                  style: const TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => setState(() => _videoFile = null),
                                  child: const Text('Remove Video', style: TextStyle(fontSize: 12, color: AppColors.dangerFg, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            )
                                : const Column(
                              children: [
                                Icon(Icons.videocam_outlined, size: 24, color: AppColors.bodyGrey),
                                SizedBox(height: 8),
                                Text('Upload Damage Video', style: TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text('MP4, WebM, MOV (Max 100MB)', style: TextStyle(fontSize: 11, color: AppColors.bodyGrey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('Explain Reason / Details *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration('Provide details about the damage incident..'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _consentChecked,
                            onChanged: (val) => setState(() => _consentChecked = val ?? false),
                            activeColor: AppColors.dangerFg,
                            side: const BorderSide(color: AppColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'I confirm that all given details are correct and the uploaded photos accurately represent the damage. *',
                            style: TextStyle(fontSize: 12, color: AppColors.bodyGrey, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              isTiny
                  ? Column(
                children: [
                  _buildCancelButton(),
                  const SizedBox(height: 12),
                  _buildConfirmButton(canSubmit),
                ],
              )
                  : Row(
                children: [
                  Expanded(child: _buildCancelButton()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildConfirmButton(canSubmit)),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _dateController.clear();
          _descController.clear();
          setState(() {
            _selectedPolicyId = null;
            _incidentDate = null;
            _typeOfDamage = null;
            _consentChecked = false;
            _imageFiles.fillRange(0, 5, null);
            _videoFile = null;
          });
          _tabController.animateTo(1);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          elevation: 0,
        ),
        child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildConfirmButton(bool canSubmit) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit
            ? () {
          final List<String> paths = [];
          for (var file in _imageFiles) {
            if (file != null) paths.add(file.path);
          }
          if (_videoFile != null) paths.add(_videoFile!.path);

          BlocProvider.of<ClaimsBloc>(context).add(
            SubmitClaimEvent(
              policyId: _selectedPolicyId!,
              incidentDate: _incidentDate,
              typeOfDamage: _typeOfDamage,
              description: _descController.text.trim(),
              claimAmount: 1000,
              evidencePaths: paths,
            ),
          );
        }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8A8A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFFF8A8A).withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text('Confirm Claim', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildTrackClaimsTab(ClaimsData data) {
    final filteredClaims = data.claimHistory.where((claim) {
      final matchesSearch = claim.claimId.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filterStatus == 'All Status' || claim.status == _filterStatus;
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 480;

              final searchField = TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: _inputDecoration('Search Claim ID...').copyWith(
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.bodyGrey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              );

              final filterField = DropdownButtonFormField<String>(
                initialValue: _filterStatus,
                isDense: true,
                isExpanded: true,
                decoration: _inputDecoration('').copyWith(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                icon: const Icon(Icons.filter_list, size: 18),
                items: _filterOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _filterStatus = val ?? 'All Status'),
              );

              if (isCompact) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    filterField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 2, child: searchField),
                  const SizedBox(width: 12),
                  Expanded(flex: 1, child: filterField),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: filteredClaims.isEmpty
              ? const PremiumEmptyState(
            icon: Icons.search_off_rounded,
            iconBg: AppColors.neutralBg,
            iconFg: AppColors.neutralFg,
            message: "No claims found matching your criteria.",
          )
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
            itemCount: filteredClaims.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final claim = filteredClaims[index];
              final (bg, fg) = _statusColors(claim.status);

              return GestureDetector(
                onTap: () => _showClaimDetailsModal(claim),
                child: PremiumCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: MetaItem(label: 'CLAIM ID', value: claim.claimId)),
                          StatusChip(label: claim.status, background: bg, foreground: fg),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const FadedDivider(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: MetaItem(label: 'Policy', value: claim.policyName)),
                          Expanded(child: MetaItem(label: 'Date Filed', value: claim.date)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkStrong)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.inkStrong),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showClaimDetailsModal(ClaimHistoryItem claim) {
    final (bg, fg) = _statusColors(claim.status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text('Claim Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  ),
                  const SizedBox(width: 12),
                  StatusChip(label: claim.status, background: bg, foreground: fg),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MetaItem(label: 'CLAIM ID', value: claim.claimId),
                    const SizedBox(height: 16),
                    MetaItem(label: 'LINKED POLICY', value: claim.policyName),
                    const SizedBox(height: 16),
                    MetaItem(label: 'DATE FILED', value: claim.date),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: claim.status == 'Pending' ? AppColors.warnBg : AppColors.neutralBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: claim.status == 'Pending' ? AppColors.warnFg.withValues(alpha: 0.2) : AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      claim.status == 'Pending' ? Icons.access_time_rounded : Icons.info_outline_rounded,
                      color: claim.status == 'Pending' ? AppColors.warnFg : AppColors.bodyGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        claim.status == 'Pending'
                            ? 'Your claim is currently under review by our team. We will notify you once a decision is made.'
                            : 'This claim has been processed.',
                        style: TextStyle(
                            fontSize: 13,
                            color: claim.status == 'Pending' ? AppColors.warnFg : AppColors.bodyGrey,
                            height: 1.4,
                            fontWeight: FontWeight.w500
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.labelGrey),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.inkStrong, width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.valueDark, letterSpacing: 0.5),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;

  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(10)));

    for (ui.PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}