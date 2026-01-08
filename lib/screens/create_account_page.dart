import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'homescreen.dart';
import 'client_profile_page.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../utils/validators.dart';
import '../utils/algerian_addresses.dart';
import '../utils/role_based_home.dart';
import '../data/repositories/storage/storage_repo.dart';
import '../data/repositories/profiles/profile_repo.dart';
import 'login.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  String selectedRole = 'Client';
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _businessIdController = TextEditingController();
  final TextEditingController _servicesController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  String experienceLevel = 'Entry';
  String _selectedGender = 'Male';
  String? _selectedWilaya;
  String? _selectedBaladiya;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedProfileImage;
  bool _isUploadingImage = false;
  
  final Set<String> _checkedUsernames = {};
  final Set<String> _checkedEmails = {};
  final Set<String> _checkedPhones = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE5E7EB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            }
          },
        ),
        title: const Text(
          'Create Account Page',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Create Your CleanSpace Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'Enter your username',
                    icon: Icons.person_outline,
                    isUsername: true,
                    validator: (value) => Validators.validateUsername(value),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    validator: (value) => Validators.validatePassword(
                      value,
                      username: _usernameController.text.trim(),
                      email: _emailController.text.trim(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                    isEmail: true,
                    validator: (value) => Validators.validateEmail(value),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    icon: Icons.person_outline,
                    isName: true,
                    validator: (value) => Validators.validateFullName(value),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    icon: Icons.phone_outlined,
                    isPhone: true,
                    validator: (value) => Validators.validatePhone(value),
                  ),
                  const SizedBox(height: 20),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedWilaya,
                    decoration: InputDecoration(
                      labelText: 'Wilaya (Province)',
                      hintText: 'Select your wilaya',
                      prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF6B7280)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
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
                        _addressController.text = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wilaya is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  if (_selectedWilaya != null)
                    DropdownButtonFormField<String>(
                      value: _selectedBaladiya,
                      isExpanded: true, 
                      decoration: InputDecoration(
                        labelText: 'Baladiya (Municipality)',
                        hintText: 'Select your baladiya (optional)',
                        hintMaxLines: 1,
                        prefixIcon: const Icon(Icons.location_city_outlined, color: Color(0xFF6B7280)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
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
                            child: Text(
                              baladiya,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList();
                      }(),
                      selectedItemBuilder: (BuildContext context) {
                        final baladiyat = AlgerianAddresses.getBaladiyatForWilaya(_selectedWilaya!);
                        if (baladiyat == null) return <Widget>[];
                        final uniqueBaladiyat = baladiyat.toSet().toList();
                        return uniqueBaladiyat.map((baladiya) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _selectedBaladiya ?? 'Select your baladiya (optional)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(color: Color(0xFF111827)),
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedBaladiya = value;
                          if (value != null && _selectedWilaya != null) {
                            _addressController.text = '$value, ${_selectedWilaya!}';
                          }
                        });
                      },
                    ),
                  if (_selectedWilaya != null) const SizedBox(height: 20),
                  
                  if (_selectedWilaya != null)
                    _buildTextField(
                      controller: _addressController,
                      label: 'Street Address (Optional)',
                      hint: 'Enter street name, building number, etc.',
                      icon: Icons.home_outlined,
                      isAddress: true,
                      validator: (value) {
                        
                        if (_selectedWilaya != null) {
                          final street = value?.trim() ?? '';
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
                        return null;
                      },
                    ),
                  if (_selectedWilaya != null) const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  
                  _buildGenderSelector(),
                  const SizedBox(height: 20),

                  _buildUploadTile(
                    title: 'Upload Profile Picture',
                    subtitle: 'Upload a clear photo',
                    icon: Icons.photo_camera_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Profile picture upload coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Identity Verification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For the safety of our community, we require ID verification.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildUploadTile(
                    title: 'Upload ID',
                    subtitle: 'Front and back of your ID',
                    icon: Icons.badge_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('ID verification upload coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  _buildDatePicker(),
                  const SizedBox(height: 20),

                  const Text(
                    'I am a...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRoleSelector(),
                  const SizedBox(height: 24),

                  
                  _buildTextField(
                    controller: _bioController,
                    label: 'Bio',
                    hint: 'Tell us about yourself...',
                    icon: Icons.description_outlined,
                    validator: (value) => Validators.validateBio(
                      value,
                      required: selectedRole != 'Client',
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (selectedRole == 'Agency') _buildAgencySection(),
                  if (selectedRole == 'Individual Cleaner')
                    _buildIndividualSection(),

                  const SizedBox(height: 24),
                  _buildCreateButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
        _emailController.dispose();
        _phoneController.dispose();
        _birthdateController.dispose();
        _addressController.dispose();
        _bioController.dispose();
        _agencyNameController.dispose();
        _businessIdController.dispose();
        _servicesController.dispose();
        _hourlyRateController.dispose();
        super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int? minLength,
    bool isInteger = false,
    bool isName = false,
    bool isPhone = false,
    bool isEmail = false,
    bool isAddress = false,
    bool isUsername = false,
    String? Function(String?)? validator,
  }) {
    List<TextInputFormatter>? inputFormatters;
    
    if (isInteger) {
      inputFormatters = [FilteringTextInputFormatter.digitsOnly];
    } else if (isPhone) {
      inputFormatters = [
        FilteringTextInputFormatter.allow(RegExp(r'^\+?[\d]*$')),
      ];
    } else if (isName) {
      inputFormatters = [
        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-']")),
      ];
    } else if (isAddress) {
      inputFormatters = [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-,.#]')),
      ];
    } else if (isUsername) {
      inputFormatters = [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
      ];
    }
    
    TextInputType keyboardType;
    if (isInteger || isPhone) {
      keyboardType = TextInputType.number;
    } else if (isEmail) {
      keyboardType = TextInputType.emailAddress;
    } else if (isPhone) {
      keyboardType = TextInputType.phone;
    } else {
      keyboardType = TextInputType.text;
    }
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator ??
          (minLength != null
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$label is required';
                  }
                  if (value.length < minLength) {
                    return '$label must be at least $minLength characters';
                  }
                  if (isInteger) {
                    if (int.tryParse(value) == null) {
                      return '$label must be a valid number';
                    }
                  }
                  return null;
                }
              : null),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF6B7280))
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF047857), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      controller: _birthdateController,
      readOnly: true,
      validator: (value) => Validators.validateBirthdate(value),
      decoration: InputDecoration(
        labelText: 'Birthdate *',
        hintText: 'mm/dd/yyyy',
        suffixIcon: const Icon(Icons.calendar_today_outlined,
            color: Color(0xFF6B7280)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF047857), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            _birthdateController.text =
                '${pickedDate.month}/${pickedDate.day}/${pickedDate.year}';
          });
        }
      },
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Male';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'Male'
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGender == 'Male'
                          ? const Color(0xFF047857)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedGender == 'Male'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _selectedGender == 'Male'
                            ? const Color(0xFF047857)
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Male',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Female';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'Female'
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGender == 'Female'
                          ? const Color(0xFF047857)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedGender == 'Female'
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _selectedGender == 'Female'
                            ? const Color(0xFF047857)
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Female',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfilePictureUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Picture (Optional)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Preview image or placeholder
            GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: _selectedProfileImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedProfileImage!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.photo_camera_outlined,
                        color: Color(0xFF6B7280),
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: _isUploadingImage ? null : _pickProfileImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose Photo'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                    ),
                  ),
                  if (_selectedProfileImage != null)
                    TextButton.icon(
                      onPressed: _isUploadingImage
                          ? null
                          : () {
                              setState(() {
                                _selectedProfileImage = null;
                              });
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedProfileImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildUploadTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF3B82F6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final roles = ['Client', 'Agency', 'Individual Cleaner'];

    return Column(
      children: roles.map((role) {
        final bool isSelected = selectedRole == role;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => selectedRole = role),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFF3F4F6),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF047857)
                      : const Color(0xFFE5E7EB),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF047857)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    role,
                    style: TextStyle(
                      color: const Color(0xFF111827),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAgencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agency Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _agencyNameController,
          label: 'Agency Name',
          hint: "Enter your agency's registered name",
          validator: (value) => Validators.validateAgencyName(value),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _businessIdController,
          label: 'Business Registration ID',
          hint: 'Enter registration ID',
          validator: (value) => Validators.validateBusinessId(value),
        ),
      ],
    );
  }

  Widget _buildIndividualSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Professional Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _servicesController,
          label: 'Services Offered',
          hint: 'E.g., Deep Cleaning, Office Cleaning...',
          validator: (value) => Validators.validateServices(value),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Flexible(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: experienceLevel,
                decoration: InputDecoration(
                  labelText: 'Experience Level',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                items: const [
                  DropdownMenuItem(value: 'Entry', child: Text('Entry')),
                  DropdownMenuItem(value: 'Mid', child: Text('Mid')),
                  DropdownMenuItem(value: 'Senior', child: Text('Senior')),
                ],
                onChanged: (value) =>
                    setState(() => experienceLevel = value!),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 1,
              child: _buildTextField(
                controller: _hourlyRateController,
                label: 'Hourly Rate (DZD)',
                hint: 'e.g., 3000',
                isInteger: true,
                isPhone: true,
                validator: (value) => Validators.validateHourlyRate(value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return BlocListener<ProfilesCubit, ProfilesState>(
      listener: (context, state) async {
        if (state is SignupSuccess) {
          // Upload profile picture if selected (async, non-blocking)
          if (_selectedProfileImage != null && state.user['id'] != null) {
            final userId = state.user['id'] as int;
            try {
              setState(() {
                _isUploadingImage = true;
              });
              
              final storageRepo = AbstractStorageRepo.getInstance();
              final imageUrl = await storageRepo.uploadProfileImage(
                userId,
                _selectedProfileImage!.path,
              );
              
              // Update profile with avatar URL
              final profileRepo = AbstractProfileRepo.getInstance();
              await profileRepo.updateAvatarUrl(userId, imageUrl);
              
              if (mounted) {
                setState(() {
                  _isUploadingImage = false;
                });
              }
            } catch (e) {
              // Image upload failed, but account is created - show warning
              if (mounted) {
                setState(() {
                  _isUploadingImage = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Account created, but profile picture upload failed: $e'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Account created as $selectedRole!'),
                backgroundColor: Colors.green,
              ),
            );
            
            RoleBasedHome.navigateToHome(context, state.user);
          }
        } else if (state is ProfilesError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: BlocBuilder<ProfilesCubit, ProfilesState>(
        builder: (context, state) {
          final isLoading = state is ProfilesLoading;
          return SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (isLoading || _isUploadingImage)
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        
                        final fullName = _fullNameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
                        
                        final profileData = <String, dynamic>{
                          'username': _usernameController.text.trim(),
                          'password': _passwordController.text,
                          'email': _emailController.text.trim().toLowerCase(),
                          'full_name': fullName,
                          'phone': _phoneController.text.trim(),
                          'birthdate': _birthdateController.text,
                          'address': _addressController.text.trim().replaceAll(RegExp(r'\s+'), ' '),
                          'gender': _selectedGender,
                          'bio': _bioController.text.trim(),
                          'user_type': selectedRole,
                        };

                        if (selectedRole == 'Agency') {
                          profileData['agency_name'] =
                              _agencyNameController.text.trim();
                          profileData['business_id'] =
                              _businessIdController.text.trim();
                          
                          if (profileData['bio'] == null || (profileData['bio'] as String).isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bio is required for Agency accounts'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        } else if (selectedRole == 'Individual Cleaner') {
                          profileData['services'] =
                              _servicesController.text.trim();
                          profileData['experience_level'] = experienceLevel;
                          profileData['hourly_rate'] =
                              _hourlyRateController.text.trim();
                          
                          if (profileData['bio'] == null || (profileData['bio'] as String).isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bio is required for Individual Cleaner accounts'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        }

                        context.read<ProfilesCubit>().signup(profileData);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: (isLoading || _isUploadingImage)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}


