import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../logic/cubits/profiles_cubit.dart';
import '../utils/validators.dart';
import '../utils/algerian_addresses.dart';
import '../data/repositories/storage/storage_repo.dart';
import '../data/repositories/profiles/profile_repo.dart';
import '../widgets/profile_avatar_widget.dart';
import '../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedWilaya;
  String? _selectedBaladiya;
  final _bioController = TextEditingController();
  String _selectedGender = 'Male';
  int? _userId;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _currentAvatarUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  bool _isRemovingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final cubit = context.read<ProfilesCubit>();
    cubit.loadCurrentUser().then((_) {
      if (!mounted) return;
      final state = cubit.state;
      if (state is ProfilesLoaded && state.currentUser != null) {
        final user = state.currentUser!;
        setState(() {
          _userId = user['id'] as int?;
          _fullNameController.text = user['full_name'] as String? ?? '';
          _emailController.text = user['email'] as String? ?? '';
          _phoneController.text = user['phone'] as String? ?? '';
          _birthdateController.text = user['birthdate'] as String? ?? '';
          final address = user['address'] as String? ?? '';
          _addressController.text = address;
          
          _selectedWilaya = AlgerianAddresses.extractWilaya(address);
          if (_selectedWilaya != null) {
            _selectedBaladiya = AlgerianAddresses.extractBaladiya(address, _selectedWilaya!);
          }
          _bioController.text = user['bio'] as String? ?? '';
          _selectedGender = user['gender'] as String? ?? 'Male';
          _currentAvatarUrl = user['picture'] as String?;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _birthdateController.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.of(context)!.editProfile,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.personalInformation,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      AppLocalizations.of(context)!.fullName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-']")),
                      ],
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.enterYourFullName,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) => Validators.validateFullName(value),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      AppLocalizations.of(context)!.emailAddress,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.enterYourEmail,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      AppLocalizations.of(context)!.phoneNumber,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\+?[\d]*$')),
                      ],
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.enterYourPhoneNumber,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) => Validators.validatePhone(value),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildProfilePictureSection(),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              
              
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identity Verification',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For the safety of our community, we require ID verification.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    InkWell(
                      onTap: () {
                        
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.badge_outlined, color: Colors.grey.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Upload ID',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Front and back of your ID',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Birthdate',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _birthdateController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: InputDecoration(
                        hintText: 'mm/dd/yyyy',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        suffixIcon: Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildGenderButton('Male'),
                        const SizedBox(width: 12),
                        _buildGenderButton('Female'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Wilaya (Province)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedWilaya,
                      decoration: InputDecoration(
                        hintText: 'Select your wilaya',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: AlgerianAddresses.getAllWilayas().map((wilaya) {
                        return DropdownMenuItem<String>(
                          value: wilaya,
                          child: Text(wilaya),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWilaya = value;
                          _selectedBaladiya = null;
                          if (value != null) {
                            _addressController.text = value;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wilaya is required';
                        }
                        return null;
                      },
                    ),
                    if (_selectedWilaya != null) const SizedBox(height: 16),
                    
                    if (_selectedWilaya != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Baladiya (Municipality)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBaladiya,
                            decoration: InputDecoration(
                              hintText: 'Select your baladiya (optional)',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: () {
                              final baladiyat = AlgerianAddresses.getBaladiyatForWilaya(_selectedWilaya!);
                              if (baladiyat == null) return <DropdownMenuItem<String>>[];
                              
                              final uniqueBaladiyat = baladiyat.toSet().toList();
                              if (_selectedBaladiya != null && !uniqueBaladiyat.contains(_selectedBaladiya)) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      _selectedBaladiya = null;
                                    });
                                  }
                                });
                              }
                              return uniqueBaladiyat.map((baladiya) {
                                return DropdownMenuItem<String>(
                                  value: baladiya,
                                  child: Text(baladiya),
                                );
                              }).toList();
                            }(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBaladiya = value;
                                if (value != null && _selectedWilaya != null) {
                                  _addressController.text = '$value, ${_selectedWilaya!}';
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    if (_selectedWilaya != null) const SizedBox(height: 16),
                    
                    if (_selectedWilaya != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Street Address (Optional)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              hintText: 'Enter street name, building number, etc.',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onChanged: (value) {
                              
                              if (_selectedWilaya != null) {
                                final street = value.trim();
                                if (_selectedBaladiya != null) {
                                  _addressController.text = street.isNotEmpty 
                                      ? '$street, $_selectedBaladiya, $_selectedWilaya'
                                      : '$_selectedBaladiya, $_selectedWilaya';
                                } else {
                                  _addressController.text = street.isNotEmpty 
                                      ? '$street, $_selectedWilaya'
                                      : _selectedWilaya!;
                                }
                              }
                            },
                            validator: (value) => Validators.validateAddress(_addressController.text),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Bio',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tell us about yourself...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) => Validators.validateBio(value, required: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: BlocConsumer<ProfilesCubit, ProfilesState>(
                  listener: (context, state) {
                    if (_isUpdating) {
                      if (state is ProfilesLoaded && state.currentUser != null) {
                        setState(() {
                          _isUpdating = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        Future.microtask(() {
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        });
                      } else if (state is ProfilesError) {
                        setState(() {
                          _isUpdating = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  builder: (context, state) {
                    final isLoading = state is ProfilesLoading;
                    return ElevatedButton(
                      onPressed: (_isLoading || isLoading || _userId == null)
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isUpdating = true;
                                });
                                final profileData = <String, dynamic>{
                                  'full_name': _fullNameController.text.trim(),
                                  'email': _emailController.text.trim().isEmpty
                                      ? null
                                      : _emailController.text.trim(),
                                  'phone': _phoneController.text.trim().isEmpty
                                      ? null
                                      : _phoneController.text.trim(),
                                  'birthdate': _birthdateController.text.trim().isEmpty
                                      ? null
                                      : _birthdateController.text.trim(),
                                  'address': _addressController.text.trim().isEmpty
                                      ? null
                                      : _addressController.text.trim(),
                                  'bio': _bioController.text.trim().isEmpty
                                      ? null
                                      : _bioController.text.trim(),
                                  'gender': _selectedGender,
                                };
                                context.read<ProfilesCubit>().updateProfile(
                                      _userId!,
                                      profileData,
                                    );
                              }
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Picture',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Current avatar display
            ProfileAvatarWidget(
              avatarUrl: _currentAvatarUrl,
              fullName: _fullNameController.text,
              radius: 40,
            ),
            const SizedBox(width: 16),
            // Buttons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_isUploadingImage || _isRemovingImage || _userId == null)
                          ? null
                          : _changePhoto,
                      icon: _isUploadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                            )
                          : const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Change Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: (_isUploadingImage || _isRemovingImage || _userId == null)
                            ? null
                            : _removePhoto,
                        icon: _isRemovingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                              )
                            : const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _changePhoto() async {
    if (_userId == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      setState(() {
        _isUploadingImage = true;
      });

      String? newImageUrl;
      
      try {
        // Upload new image
        final storageRepo = AbstractStorageRepo.getInstance();
        newImageUrl = await storageRepo.uploadProfileImage(
        _userId!,
        image.path,
      );

      if (!mounted) return;

      // Delete old image if it exists (fail silently if file doesn't exist)
      // Note: deleteProfileImage should not throw, but wrap in try-catch just in case
      if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty && _currentAvatarUrl!.startsWith('http')) {
        try {
          await storageRepo.deleteProfileImage(_currentAvatarUrl!);
        } catch (e) {
          // Ignore all errors from delete - it's not critical if old file can't be deleted
          // This is expected if the file doesn't exist (e.g., first upload or file was already deleted)
        }
      }

      // Update profile with new avatar URL
      final profileRepo = AbstractProfileRepo.getInstance();
      final success = await profileRepo.updateAvatarUrl(_userId!, newImageUrl!);

        if (!mounted) return;

        if (success) {
          // Update local state first
          setState(() {
            _currentAvatarUrl = newImageUrl;
            _isUploadingImage = false;
          });

          // Refresh profile state to ensure UI updates with new picture
          final cubit = context.read<ProfilesCubit>();
          await cubit.loadCurrentUser();

          // Wait a bit to ensure state is updated
          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted) {
            // Force rebuild to show new image
            setState(() {});
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          setState(() {
            _isUploadingImage = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update profile picture'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        
        // Check if it's an object-not-found error (file doesn't exist)
        // This is expected and should be handled silently
        final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('object-not-found') || 
          errorStr.contains('no object exists') ||
          errorStr.contains('[firebase_storage/object-not-found]')) {
        // Silently handle - this is expected when old file doesn't exist
        setState(() {
          _isUploadingImage = false;
        });
        
        // Still try to update the profile if we have the new image URL from upload
        // The upload should have succeeded, only the delete failed
        if (newImageUrl != null && newImageUrl.isNotEmpty) {
          // Try to update profile with the new image URL (upload succeeded)
          try {
            final profileRepo = AbstractProfileRepo.getInstance();
            final success = await profileRepo.updateAvatarUrl(_userId!, newImageUrl);
            
            if (success) {
              // Update local state
              setState(() {
                _currentAvatarUrl = newImageUrl;
                _isUploadingImage = false;
              });
              
              // Refresh profile state to show new image
              final cubit = context.read<ProfilesCubit>();
              await cubit.loadCurrentUser();
              
              if (mounted) {
                // Force rebuild to show new image
                setState(() {});
              }
            } else {
              setState(() {
                _isUploadingImage = false;
              });
            }
          } catch (updateError) {
            // If profile update also fails, just reset the uploading state
            setState(() {
              _isUploadingImage = false;
            });
          }
        } else {
          setState(() {
            _isUploadingImage = false;
          });
        }
        return; // Don't show error message for expected errors
      }
      
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (outerError) {
      // Handle any unexpected errors from picking image
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _removePhoto() async {
    if (_userId == null || _currentAvatarUrl == null || _currentAvatarUrl!.isEmpty) {
      return;
    }

    try {
      setState(() {
        _isRemovingImage = true;
      });

      // Delete from storage
      final storageRepo = AbstractStorageRepo.getInstance();
      try {
        await storageRepo.deleteProfileImage(_currentAvatarUrl!);
      } catch (e) {
        // Log but continue - the URL might already be invalid
        print('Warning: Failed to delete avatar from storage: $e');
      }

      // Update profile to remove avatar URL
      final profileRepo = AbstractProfileRepo.getInstance();
      final success = await profileRepo.removeAvatar(_userId!);

      if (!mounted) return;

      if (success) {
        setState(() {
          _currentAvatarUrl = null;
          _isRemovingImage = false;
        });

        // Refresh profile state
        final cubit = context.read<ProfilesCubit>();
        await cubit.loadCurrentUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture removed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isRemovingImage = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove profile picture'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRemovingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing profile picture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildGenderButton(String gender) {
    final isSelected = _selectedGender == gender;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGender = gender;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Text(
            gender,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

