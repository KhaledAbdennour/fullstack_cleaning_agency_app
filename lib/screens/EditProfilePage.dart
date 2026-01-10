import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../logic/cubits/profiles_cubit.dart';
import '../utils/validators.dart';
import '../utils/algerian_addresses.dart';
import '../data/repositories/profiles/profile_repo.dart';
import '../utils/image_helper.dart';
import '../l10n/app_localizations.dart';
import 'login.dart';

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
  final _addressFocusNode = FocusNode();
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
  
  // Cleaner-specific fields
  String? _userType;
  Set<String> _selectedServices = {};
  String _experienceLevel = 'Entry';
  final TextEditingController _hourlyRateController = TextEditingController();
  final List<String> _availableServices = ['Home', 'Office', 'Industrial', 'Specialty'];
  
  // Agency-specific fields
  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _businessIdController = TextEditingController();

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
          
          // Load cleaner-specific fields
          _userType = user['user_type'] as String?;
          if (_userType == 'Individual Cleaner' || _userType == 'Agency') {
            // Load services
            final servicesStr = user['services'] as String? ?? '';
            if (servicesStr.isNotEmpty) {
              _selectedServices = servicesStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
            }
            
            // Load experience level
            _experienceLevel = user['experience_level'] as String? ?? 'Entry';
            
            // Load hourly rate
            final hourlyRate = user['hourly_rate'] as String? ?? '';
            _hourlyRateController.text = hourlyRate;
          }
          
          // Load agency-specific fields
          if (_userType == 'Agency') {
            final agencyName = user['agency_name'] as String? ?? '';
            _agencyNameController.text = agencyName;
            
            final businessId = user['business_id'] as String? ?? '';
            _businessIdController.text = businessId;
          }
          
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

  void _showDeleteAccountDialog() {
    final cubit = context.read<ProfilesCubit>();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline, size: 40, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.deleteAccount,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.areYouSureDeleteAccount,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (_userId != null) {
                      cubit.deleteAccount(_userId!).then((_) {
                        final state = cubit.state;
                        if (state is LogoutSuccess || state is ProfilesLoaded) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const Login()),
                            (route) => false,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.accountDeletedSuccessfully),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (state is ProfilesError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text((state as ProfilesError).message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.yesDeleteAccount,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9FAFB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    _addressController.dispose();
    _addressFocusNode.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _agencyNameController.dispose();
    _businessIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6), // Blue color
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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
          title: Text(
          AppLocalizations.of(context)!.editProfile,
          style: const TextStyle(
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
                    
                    // Cleaner-specific fields
                    if (_userType == 'Individual Cleaner' || _userType == 'Agency') ...[
                      const SizedBox(height: 24),
                      _buildServicesSection(),
                      const SizedBox(height: 24),
                      _buildExperienceAndRateSection(),
                    ],
                    
                    // Agency-specific fields
                    if (_userType == 'Agency') ...[
                      const SizedBox(height: 24),
                      _buildAgencyInfoSection(),
                    ],
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
                      AppLocalizations.of(context)!.accountDetails,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      AppLocalizations.of(context)!.birthdate,
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
                      AppLocalizations.of(context)!.gender,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildGenderButton('Male', AppLocalizations.of(context)!.male),
                        const SizedBox(width: 12),
                        _buildGenderButton('Female', AppLocalizations.of(context)!.female),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      AppLocalizations.of(context)!.wilayaProvince,
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
                        hintText: AppLocalizations.of(context)!.selectYourWilaya,
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
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.wilayaRequired;
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
                            AppLocalizations.of(context)!.baladiyaMunicipality,
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
                              hintText: AppLocalizations.of(context)!.selectYourBaladiya,
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
                            AppLocalizations.of(context)!.streetAddressOptional,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _addressController,
                            focusNode: _addressFocusNode,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.enterStreetName,
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
                            validator: (value) => Validators.validateAddress(_addressController.text),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    
                    Text(
                      AppLocalizations.of(context)!.bio,
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
                        hintText: AppLocalizations.of(context)!.tellUsAboutYourself,
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
                    const SizedBox(height: 24),
                    // Delete Account Button
                    SizedBox(
                      width: double.infinity,
                        child: ElevatedButton(
                        onPressed: _userId != null ? _showDeleteAccountDialog : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.deleteAccount,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: BlocConsumer<ProfilesCubit, ProfilesState>(
                  listener: (context, state) {
                    // Only handle states when we're in the updating process
                    if (!_isUpdating) return;

                    if (state is ProfilesLoaded) {
                      // Check if this is a successful update (user data exists)
                      if (state.currentUser != null) {
                        setState(() {
                          _isUpdating = false;
                        });
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.profileUpdated),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          
                          // Reload profile data to reflect changes
                          _loadProfile();
                          
                          // Navigate to profile page after a short delay to allow user to see success message
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted) {
                              // Pop back to profile page (ClientProfilePage)
                              // Return true to indicate successful save
                              Navigator.of(context).pop(true);
                            }
                          });
                        }
                      }
                    } else if (state is ProfilesError) {
                      setState(() {
                        _isUpdating = false;
                      });
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                    // Note: ProfilesLoading state is handled by the builder
                  },
                  builder: (context, state) {
                    final isLoading = state is ProfilesLoading;
                    return ElevatedButton(
                      onPressed: (_isLoading || isLoading || _userId == null)
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }

                              // Prevent multiple simultaneous updates
                              if (_isUpdating) {
                                return;
                              }

                              setState(() {
                                _isUpdating = true;
                              });

                              try {
                                // Validate cleaner-specific fields
                                if (_userType == 'Individual Cleaner' || _userType == 'Agency') {
                                  if (_selectedServices.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please select at least one service'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    setState(() {
                                      _isUpdating = false;
                                    });
                                    return;
                                  }
                                }

                                // Prepare profile data - only include non-empty fields
                                final profileData = <String, dynamic>{};
                                
                                final fullName = _fullNameController.text.trim();
                                if (fullName.isNotEmpty) {
                                  profileData['full_name'] = fullName;
                                }

                                final email = _emailController.text.trim();
                                if (email.isNotEmpty) {
                                  profileData['email'] = email;
                                }

                                final phone = _phoneController.text.trim();
                                if (phone.isNotEmpty) {
                                  profileData['phone'] = phone;
                                }

                                final birthdate = _birthdateController.text.trim();
                                if (birthdate.isNotEmpty) {
                                  profileData['birthdate'] = birthdate;
                                }

                                final address = _addressController.text.trim();
                                if (address.isNotEmpty) {
                                  profileData['address'] = address;
                                }

                                final bio = _bioController.text.trim();
                                if (bio.isNotEmpty) {
                                  profileData['bio'] = bio;
                                }

                                // Always include gender (required field)
                                profileData['gender'] = _selectedGender;

                                // Add cleaner-specific fields if user is a cleaner
                                if (_userType == 'Individual Cleaner' || _userType == 'Agency') {
                                  // Services (required for cleaners)
                                  profileData['services'] = _selectedServices.join(', ');
                                  
                                  // Experience level
                                  profileData['experience_level'] = _experienceLevel;
                                  
                                  // Hourly rate
                                  final hourlyRate = _hourlyRateController.text.trim();
                                  if (hourlyRate.isNotEmpty) {
                                    profileData['hourly_rate'] = hourlyRate;
                                  }
                                }
                                
                                // Add agency-specific fields if user is an agency
                                if (_userType == 'Agency') {
                                  final agencyName = _agencyNameController.text.trim();
                                  if (agencyName.isNotEmpty) {
                                    profileData['agency_name'] = agencyName;
                                  }
                                  
                                  final businessId = _businessIdController.text.trim();
                                  if (businessId.isNotEmpty) {
                                    profileData['business_id'] = businessId;
                                  }
                                }

                                // Call updateProfile - the cubit will handle validation and backend update
                                context.read<ProfilesCubit>().updateProfile(
                                      _userId!,
                                      profileData,
                                    );
                              } catch (e) {
                                // Handle any unexpected errors
                                if (mounted) {
                                  setState(() {
                                    _isUpdating = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
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
          AppLocalizations.of(context)!.profilePicture,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Current avatar display - matching profile page style
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 2,
                    ),
                  ),
                  child: _currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
                      ? ClipOval(
                          child: AppImage(
                            imageUrl: _currentAvatarUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorWidget: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                ),
                if (_isUploadingImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ),
              ],
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
                      label: Text(AppLocalizations.of(context)!.changePhoto),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                              )
                            : const Icon(Icons.delete_outline, size: 18),
                        label: Text(AppLocalizations.of(context)!.removePhoto),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
    if (_userId == null || _isUploadingImage) return;

    try {
      // Show options to pick from gallery or camera
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null || !mounted) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      setState(() {
        _isUploadingImage = true;
      });

      try {
        // Convert image to base64 data URL (same approach as post images)
        final imageFile = File(image.path);
        final imageBytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        
        final extension = image.path.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg'; 
        if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'gif') {
          mimeType = 'image/gif';
        } else if (extension == 'webp') {
          mimeType = 'image/webp';
        }
        
        final imageDataUrl = 'data:$mimeType;base64,$base64Image';

        if (!mounted) return;

        // Update profile with base64 data URL
        final profileRepo = AbstractProfileRepo.getInstance();
        print('Updating picture field for user $_userId with base64 data URL');
        print('Data URL length: ${imageDataUrl.length}');
        
        final success = await profileRepo.updateAvatarUrl(_userId!, imageDataUrl);
        print('Update picture field result: $success');
        
        if (!success) {
          setState(() {
            _isUploadingImage = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save picture to database. Please try again.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        if (!mounted) return;

        // Immediately update the UI with the uploaded image
        setState(() {
          _currentAvatarUrl = imageDataUrl;
          _isUploadingImage = false;
        });

        // Refresh profile state to sync with backend (in background)
        final cubit = context.read<ProfilesCubit>();
        await cubit.loadCurrentUser();

        // Update with backend value if different (to ensure consistency)
        if (mounted) {
          final updatedState = cubit.state;
          if (updatedState is ProfilesLoaded && updatedState.currentUser != null) {
            final updatedPicture = updatedState.currentUser!['picture'] as String?;
            if (updatedPicture != null && updatedPicture != _currentAvatarUrl) {
              setState(() {
                _currentAvatarUrl = updatedPicture;
              });
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profilePictureUpdatedSuccessfully),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (error) {
        print('Error processing image: $error');
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to process image: ${error.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (outerError) {
      // Handle any errors from showing bottom sheet or picking image
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

      // Update profile to remove avatar URL (base64 data URLs are stored in DB, no storage deletion needed)
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profilePictureRemovedSuccessfully),
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToRemoveProfilePicture),
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

  Widget _buildGenderButton(String gender, String label) {
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
            label,
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

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
                      AppLocalizations.of(context)!.servicesOfferedLabel,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableServices.map((service) {
            final isSelected = _selectedServices.contains(service);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedServices.remove(service);
                  } else {
                    _selectedServices.add(service);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3B82F6).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFE5E7EB),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      service,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExperienceAndRateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Experience Level - Full Width
        Text(
                AppLocalizations.of(context)!.experienceLevel,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _experienceLevel,
          isExpanded: true,
          decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.selectExperienceLevel,
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
                items: [
                  DropdownMenuItem(value: 'Entry', child: Text(AppLocalizations.of(context)!.entry)),
                  DropdownMenuItem(value: 'Mid', child: Text(AppLocalizations.of(context)!.mid)),
                  DropdownMenuItem(value: 'Senior', child: Text(AppLocalizations.of(context)!.senior)),
                ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _experienceLevel = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        // Hourly Rate - Full Width
        Text(
                AppLocalizations.of(context)!.hourlyRateDzd,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _hourlyRateController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*')),
          ],
          decoration: InputDecoration(
            hintText: 'e.g., 3000',
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
          validator: (value) {
            // Optional in edit profile - if provided, must be valid
            if (value != null && value.trim().isNotEmpty) {
              return Validators.validateHourlyRate(value);
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAgencyInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.agencyName,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _agencyNameController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterAgencyName,
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context)!.agencyNameRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.businessId,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _businessIdController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterBusinessRegistrationId,
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context)!.businessIdRequired;
            }
            return null;
          },
        ),
      ],
    );
  }
}

