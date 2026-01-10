import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../logic/cubits/agency_dashboard_cubit.dart';
import '../data/repositories/cleaners/cleaners_repo.dart';
import '../data/models/cleaner_model.dart';
import '../data/repositories/profiles/profile_repo.dart';
import '../utils/validators.dart';

class AddCleanerPage extends StatefulWidget {
  final int agencyId;

  const AddCleanerPage({super.key, required this.agencyId});

  @override
  State<AddCleanerPage> createState() => _AddCleanerPageState();
}

class _AddCleanerPageState extends State<AddCleanerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchProfileController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  String _selectedExperienceLevel = 'Beginner';
  final Set<String> _selectedServices = {};

  final List<String> _availableServices = [
    'Residential Cleaning',
    'Office Cleaning',
    'Deep Cleaning',
    'Window Cleaning',
  ];

  final List<String> _experienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _searchProfileController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _profileImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _linkExistingProfile() async {
    final searchQuery = _searchProfileController.text.trim();
    if (searchQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name or email to search'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final profileRepo = AbstractProfileRepo.getInstance();
      final allProfiles = await profileRepo.getAllProfiles();
      if (!mounted) return;

      final matches = allProfiles.where((profile) {
        final name = (profile['full_name'] as String? ?? '').toLowerCase();
        final email = (profile['email'] as String? ?? '').toLowerCase();
        final searchLower = searchQuery.toLowerCase();
        return name.contains(searchLower) || email.contains(searchLower);
      }).toList();

      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No matching profile found'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (matches.length == 1) {
        await _addCleanerFromProfile(matches.first);
      } else {
        _showProfileSelectionDialog(matches);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching profiles: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showProfileSelectionDialog(List<Map<String, dynamic>> profiles) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Profile'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final name = profile['full_name'] as String? ?? 'Unknown';
              final email = profile['email'] as String? ?? '';
              return ListTile(
                title: Text(name),
                subtitle: Text(email),
                onTap: () {
                  Navigator.pop(context);
                  _addCleanerFromProfile(profile);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _addCleanerFromProfile(Map<String, dynamic> profile) async {
    try {
      final cleanerId = profile['id'] as int?;
      if (cleanerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid profile'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final cleanersRepo = AbstractCleanersRepo.getInstance();
      final existingCleaners = await cleanersRepo.getCleanersForAgency(
        widget.agencyId,
      );
      if (!mounted) return;
      if (existingCleaners.any((c) => c.id == cleanerId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This cleaner is already in your team'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final cleaner = Cleaner(
        name: profile['full_name'] as String? ?? 'Unknown',
        avatarUrl: profile['picture'] as String?,
        rating: (profile['rating'] as num?)?.toDouble() ?? 0.0,
        jobsCompleted: 0,
        agencyId: widget.agencyId,
        isActive: true,
      );

      await cleanersRepo.addCleaner(cleaner);

      if (mounted) {
        context.read<CleanerTeamCubit>().refresh(widget.agencyId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cleaner added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding cleaner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final profileRepo = AbstractProfileRepo.getInstance();

      final profileData = {
        'username': _emailController.text.trim().split('@').first,
        'password': 'temp123',
        'email': _emailController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'user_type': 'Individual Cleaner',
        'bio': 'Professional cleaner',
        'services': _selectedServices.join(', '),
        'experience_years': _getExperienceYears(),
        'picture': _profileImage?.path,
      };

      final cleanersRepo = AbstractCleanersRepo.getInstance();

      final cleaner = Cleaner(
        name: _fullNameController.text.trim(),
        avatarUrl: _profileImage?.path,
        rating: 0.0,
        jobsCompleted: 0,
        agencyId: widget.agencyId,
        isActive: true,
      );

      await cleanersRepo.addCleaner(cleaner);

      if (mounted) {
        context.read<CleanerTeamCubit>().refresh(widget.agencyId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cleaner added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding cleaner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getExperienceYears() {
    switch (_selectedExperienceLevel) {
      case 'Beginner':
        return 0;
      case 'Intermediate':
        return 2;
      case 'Advanced':
        return 5;
      case 'Expert':
        return 10;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Worker',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfilePictureSection(),
                const SizedBox(height: 24),

                _buildSectionTitle('Personal Information'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'Enter full name',
                  icon: Icons.person_outline,
                  validator: (value) => Validators.validateFullName(value),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  icon: Icons.phone_outlined,
                  isPhone: true,
                  validator: (value) => Validators.validatePhone(value),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'Enter email address',
                  icon: Icons.email_outlined,
                  isEmail: true,
                  validator: (value) => Validators.validateEmail(value),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Professional Details'),
                const SizedBox(height: 16),
                _buildServicesSection(),
                const SizedBox(height: 16),
                _buildExperienceDropdown(),
                const SizedBox(height: 24),

                _buildSectionTitle('Existing Profile'),
                const SizedBox(height: 16),
                _buildLinkExistingProfileSection(),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add Worker',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  Widget _buildProfilePictureSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: _profileImage != null
                ? ClipOval(
                    child: Image.file(
                      File(_profileImage!.path),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.person, size: 60, color: Colors.grey),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPhone = false,
    bool isEmail = false,
    String? Function(String?)? validator,
  }) {
    List<TextInputFormatter>? inputFormatters;
    TextInputType keyboardType = TextInputType.text;

    if (isPhone) {
      inputFormatters = [
        FilteringTextInputFormatter.allow(RegExp(r'^\+?[\d]*$')),
      ];
      keyboardType = TextInputType.phone;
    } else if (isEmail) {
      keyboardType = TextInputType.emailAddress;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services Offered',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableServices.map((service) {
            final isSelected = _selectedServices.contains(service);
            return FilterChip(
              label: Text(service),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedServices.add(service);
                  } else {
                    _selectedServices.remove(service);
                  }
                });
              },
              selectedColor: const Color(0xFF3B82F6).withOpacity(0.2),
              checkmarkColor: const Color(0xFF3B82F6),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExperienceDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Experience Level',
          prefixIcon: Icon(Icons.work_outline, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        initialValue: _selectedExperienceLevel,
        items: _experienceLevels.map((level) {
          return DropdownMenuItem<String>(value: level, child: Text(level));
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedExperienceLevel = value!;
          });
        },
      ),
    );
  }

  Widget _buildLinkExistingProfileSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Link Existing CleanSpace Profile (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchProfileController,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _linkExistingProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Link'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
