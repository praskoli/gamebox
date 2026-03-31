import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/player_profile.dart';
import '../../core/services/profile_service.dart';

class EditPlayerProfileScreen extends StatefulWidget {
  const EditPlayerProfileScreen({
    super.key,
    required this.initialProfile,
  });

  final PlayerProfile initialProfile;

  @override
  State<EditPlayerProfileScreen> createState() =>
      _EditPlayerProfileScreenState();
}

class _EditPlayerProfileScreenState extends State<EditPlayerProfileScreen> {
  static const Color _bgColor = Color(0xFFF8F2E8);
  static const Color _cardColor = Color(0xFFFFFCF8);
  static const Color _textPrimary = Color(0xFF2F2A25);
  static const Color _textSecondary = Color(0xFF7C7167);
  static const Color _accent = Color(0xFFFF9E2C);
  static const Color _softBorder = Color(0xFFEADFD2);
  static const Color _softAccent = Color(0xFFFFF1DE);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _approvalEmailController = TextEditingController();
  final _temporaryEmailController = TextEditingController();
  final _loginEmailController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    _nameController.text =
    widget.initialProfile.displayName.trim().toLowerCase() == 'player'
        ? ''
        : widget.initialProfile.displayName;
    _mobileController.text = _prettifyMobile(widget.initialProfile.mobileNumber);
    _approvalEmailController.text = widget.initialProfile.approvalEmail;
    _temporaryEmailController.text = widget.initialProfile.temporaryEmail;
    _loginEmailController.text = widget.initialProfile.loginEmail;
    _photoUrl = widget.initialProfile.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _approvalEmailController.dispose();
    _temporaryEmailController.dispose();
    _loginEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.initialProfile;
    final isGuest = profile.email.trim().isEmpty;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _textPrimary,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _softBorder),
                ),
                child: Column(
                  children: [
                    _AvatarEditor(
                      photoUrl: _photoUrl,
                      displayName: _nameController.text.trim().isEmpty
                          ? 'Player'
                          : _nameController.text.trim(),
                      isBusy: _isUploadingAvatar,
                      onEditTap: _pickAvatarSource,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile.uid,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _softBorder),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration('Name').copyWith(
                        hintText: 'Enter your name',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Mobile Number').copyWith(
                        hintText: '10-digit mobile or +E.164',
                      ),
                      validator: _validateMobile,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _approvalEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                      _inputDecoration('Parent Approval Email').copyWith(
                        hintText: 'Primary email for parent approval OTP',
                      ),
                      validator: _validateOptionalEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _temporaryEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        'Temporary Email (Optional)',
                      ).copyWith(
                        hintText:
                        'If set, OTP will be sent here first until changed again',
                      ),
                      validator: _validateOptionalEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: isGuest ? _loginEmailController : null,
                      initialValue: isGuest ? null : profile.email,
                      readOnly: !isGuest,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        isGuest ? 'Login Email' : 'Login Email (read-only)',
                      ).copyWith(
                        hintText: isGuest
                            ? 'Enter email to use later for login/recovery'
                            : null,
                      ),
                      validator: isGuest ? _validateOptionalEmail : null,
                    ),
                    if (isGuest) ...[
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Guest users should add a login email to recover progress and login later.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: _providerLabel(profile.provider),
                      readOnly: true,
                      decoration: _inputDecoration('Login Provider (read-only)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _accent.withOpacity(0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Save Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _softAccent.withOpacity(0.42),
      labelStyle: const TextStyle(color: _textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _softBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }

  String? _validateName(String? value) {
    final input = _normalizeName(value ?? '');
    if (input.isEmpty) return 'Please enter your name.';
    if (input.length < 3) return 'Name must be at least 3 characters.';
    if (input.length > 80) return 'Name must be at most 80 characters.';
    final regex = RegExp(r'^[A-Za-z ]+$');
    if (!regex.hasMatch(input)) {
      return 'Only letters and spaces are allowed.';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;

    final cleaned = raw.replaceAll(RegExp(r'[\s\-()]'), '');

    if (cleaned.startsWith('+')) {
      if (!RegExp(r'^\+\d{10,15}$').hasMatch(cleaned)) {
        return 'Enter valid international number';
      }
      return null;
    }

    if (RegExp(r'^\d{10}$').hasMatch(cleaned)) {
      return null;
    }

    if (RegExp(r'^91\d{10}$').hasMatch(cleaned)) {
      return null;
    }

    return 'Enter valid 10-digit mobile number';
  }

  String? _validateOptionalEmail(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null;
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(input)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String _normalizeName(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizeIndianPhoneToE164(String raw) {
    final input = raw.replaceAll(RegExp(r'[\s\-()]'), '');

    if (input.isEmpty) return '';

    if (input.startsWith('+')) {
      if (!RegExp(r'^\+\d{10,15}$').hasMatch(input)) {
        throw Exception('Enter a valid mobile number.');
      }
      return input;
    }

    if (RegExp(r'^\d{10}$').hasMatch(input)) {
      return '+91$input';
    }

    if (RegExp(r'^91\d{10}$').hasMatch(input)) {
      return '+$input';
    }

    throw Exception('Enter a valid 10-digit mobile number.');
  }

  String _prettifyMobile(String raw) {
    if (raw.startsWith('+91') && raw.length == 13) {
      return raw.substring(3);
    }
    return raw;
  }

  String _providerLabel(String provider) {
    switch (provider.trim()) {
      case 'google.com':
        return 'Logged in using Google';
      case 'facebook.com':
        return 'Logged in using Facebook';
      case 'phone':
        return 'Logged in using Mobile';
      case 'guest':
        return 'Logged in as Guest';
      case 'apple.com':
        return 'Logged in using Apple';
      default:
        return 'Logged in';
    }
  }

  Future<void> _pickAvatarSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4C7BA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Update Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: _softAccent,
                  leading: const Icon(Icons.photo_camera_outlined, color: _accent),
                  title: const Text('Take Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: _softAccent,
                  leading:
                  const Icon(Icons.photo_library_outlined, color: _accent),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    try {
      setState(() => _isUploadingAvatar = true);

      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
      );

      if (picked == null) {
        if (mounted) {
          setState(() => _isUploadingAvatar = false);
        }
        return;
      }

      final bytes = await picked.readAsBytes();
      final photoUrl = await ProfileService.instance.uploadAvatarBytes(bytes);

      if (!mounted) return;

      setState(() {
        _photoUrl = photoUrl;
        _isUploadingAvatar = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile photo: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      final normalizedName = _normalizeName(_nameController.text);
      final normalizedMobile = _mobileController.text.trim().isEmpty
          ? ''
          : _normalizeIndianPhoneToE164(_mobileController.text);
      final normalizedApprovalEmail =
      _approvalEmailController.text.trim().toLowerCase();
      final normalizedTemporaryEmail =
      _temporaryEmailController.text.trim().toLowerCase();
      final normalizedLoginEmail =
      _loginEmailController.text.trim().toLowerCase();

      final saved = await ProfileService.instance.saveProfile(
        displayName: normalizedName,
        mobileNumber: normalizedMobile,
        approvalEmail: normalizedApprovalEmail,
        temporaryEmail: normalizedTemporaryEmail,
        loginEmail: normalizedLoginEmail,
        photoUrl: _photoUrl,
      );

      if (!mounted) return;

      setState(() => _isSaving = false);
      Navigator.pop(context, saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    }
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.photoUrl,
    required this.displayName,
    required this.isBusy,
    required this.onEditTap,
  });

  final String photoUrl;
  final String displayName;
  final bool isBusy;
  final VoidCallback onEditTap;

  static const Color _avatarBg = Color(0xFFECE1FA);
  static const Color _avatarText = Color(0xFF7C1FB1);
  static const Color _accent = Color(0xFFFF9E2C);

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(displayName);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 54,
          backgroundColor: _avatarBg,
          backgroundImage:
          photoUrl.trim().isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.trim().isEmpty
              ? Text(
            initials,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: _avatarText,
            ),
          )
              : null,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isBusy ? null : onEditTap,
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
                child: isBusy
                    ? const Padding(
                  padding: EdgeInsets.all(9),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _buildInitials(String name) {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}