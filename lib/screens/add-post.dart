import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/client_jobs_cubit.dart';
import '../logic/cubits/listings_cubit.dart';
import '../data/repositories/jobs/jobs_repo.dart';
import '../data/models/job_model.dart';


class PostJobScreen extends StatefulWidget {
  const PostJobScreen({Key? key}) : super(key: key);

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  String? selectedServiceType;
  String? selectedProvince;
  final TextEditingController budgetController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedDurationUnit = 'Hours';
  final ImagePicker _picker = ImagePicker();
  List<XFile> selectedImages = [];

  final List<Map<String, dynamic>> serviceTypes = [
    {
      'title': 'Home',
      'image': 'https://images.unsplash.com/photo-1502005229762-cf1b2da7c52f?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Office',
      'image': 'https://images.unsplash.com/photo-1507206130118-b5907f817163?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Industrial',
      'image': 'https://images.unsplash.com/photo-1551703599-62b152d0f8f1?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Specialty',
      'image': 'https://images.unsplash.com/photo-1581578017426-1c42a7f1d449?w=600&auto=format&fit=crop',
    },
  ];

  final List<String> provinces = [
    'Adrar',
    'Chlef',
    'Laghouat',
    'Oum El Bouaghi',
    'Batna',
    'Béjaïa',
    'Biskra',
    'Béchar',
    'Blida',
    'Bouira',
    'Tamanrasset',
    'Tébessa',
    'Tlemcen',
    'Tiaret',
    'Tizi Ouzou',
    'Alger',
    'Djelfa',
    'Jijel',
    'Sétif',
    'Saïda',
    'Skikda',
    'Sidi Bel Abbès',
    'Annaba',
    'Guelma',
    'Constantine',
    'Médéa',
    'Mostaganem',
    'M\'Sila',
    'Mascara',
    'Ouargla',
    'Oran',
    'El Bayadh',
    'Illizi',
    'Bordj Bou Arréridj',
    'Boumerdès',
    'El Tarf',
    'Tindouf',
    'Tissemsilt',
    'El Oued',
    'Khenchela',
    'Souk Ahras',
    'Tipaza',
    'Mila',
    'Aïn Defla',
    'Naâma',
    'Aïn Témouchent',
    'Ghardaïa',
    'Relizane',
  ];

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          
          if (selectedImages.length + images.length <= 5) {
            selectedImages.addAll(images);
          } else {
            int remainingSlots = 5 - selectedImages.length;
            selectedImages.addAll(images.take(remainingSlots));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 5 photos allowed'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  Future<void> _submitJob() async {
    
    if (selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (budgetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a budget'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a job description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      
      final profilesCubit = context.read<ProfilesCubit>();
      await profilesCubit.loadCurrentUser();
      final state = profilesCubit.state;
      
      if (state is! ProfilesLoaded || state.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to post a job'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final user = state.currentUser!;
      final clientId = user['id'] as int?;
      
      if (clientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get user ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      
      final budgetText = budgetController.text.trim();
      double? budgetMin;
      double? budgetMax;
      
      if (budgetText.contains('-')) {
        final parts = budgetText.split('-');
        if (parts.length == 2) {
          budgetMin = double.tryParse(parts[0].trim());
          budgetMax = double.tryParse(parts[1].trim());
        }
      } else {
        budgetMin = double.tryParse(budgetText);
        budgetMax = budgetMin;
      }

      
      int? estimatedHours;
      if (durationController.text.isNotEmpty) {
        final duration = int.tryParse(durationController.text);
        if (duration != null) {
          estimatedHours = selectedDurationUnit == 'Hours' ? duration : duration * 24;
        }
      }

      
      String? coverImageDataUrl;
      if (selectedImages.isNotEmpty) {
        try {
          final imageFile = File(selectedImages[0].path);
          final imageBytes = await imageFile.readAsBytes();
          final base64Image = base64Encode(imageBytes);
          
          final extension = selectedImages[0].path.split('.').last.toLowerCase();
          String mimeType = 'image/jpeg'; 
          if (extension == 'png') {
            mimeType = 'image/png';
          } else if (extension == 'gif') {
            mimeType = 'image/gif';
          } else if (extension == 'webp') {
            mimeType = 'image/webp';
          }
          coverImageDataUrl = 'data:$mimeType;base64,$base64Image';
        } catch (e) {
          print('Error converting image to base64: $e');
          
        }
      }

      
      final job = Job(
        title: '$selectedServiceType Cleaning - ${selectedProvince}',
        city: selectedProvince!,
        country: 'Algeria',
        description: descriptionController.text,
        status: JobStatus.active,
        postedDate: DateTime.now(),
        jobDate: DateTime.now().add(const Duration(days: 7)), 
        coverImageUrl: coverImageDataUrl,
        clientId: clientId,
        agencyId: null, 
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        estimatedHours: estimatedHours,
        requiredServices: [selectedServiceType!],
      );

      
      final jobsRepo = AbstractJobsRepo.getInstance();
      final createdJob = await jobsRepo.createJob(job);

      
      if (!mounted) return;
      
      
      setState(() {
        selectedServiceType = null;
        selectedProvince = null;
        budgetController.clear();
        durationController.clear();
        descriptionController.clear();
        selectedImages.clear();
        selectedDurationUnit = 'Hours';
      });
      
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job posted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      
      if (mounted) {
        try {
          await context.read<ClientJobsCubit>().refresh(clientId);
          await context.read<ListingsCubit>().loadListings();
        } catch (e) {
          print('Error refreshing data: $e');
        }
      }
      
      
      if (mounted && Navigator.canPop(context)) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          print('Error navigating back: $e');
        }
      }
      
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting job: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        
        print('Error posting job: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Post a New Job',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              const Text(
                'Select Service Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: serviceTypes.length,
                itemBuilder: (context, index) {
                  final service = serviceTypes[index];
                  final isSelected = selectedServiceType == service['title'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedServiceType = service['title'];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00A8E8)
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  service['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 40,
                                      color: Colors.grey[500],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              service['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              
              const Text(
                'Location (Wilaya)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey),
                    hintText: 'Select your province',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  value: selectedProvince,
                  items: provinces.map((String province) {
                    return DropdownMenuItem<String>(
                      value: province,
                      child: Text(province),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedProvince = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              
              const Text(
                'Your Budget (DZD)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: Colors.grey),
                    hintText: 'Enter your budget',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              
              const Text(
                'Estimated Duration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.schedule, color: Colors.grey),
                          hintText: 'e.g., 3',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDurationUnit,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: ['Hours', 'Days', 'Weeks'].map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedDurationUnit = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              
              const Text(
                'Add Photos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              
              if (selectedImages.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(selectedImages[index].path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              
              GestureDetector(
                onTap: selectedImages.length < 5 ? _pickImages : null,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: selectedImages.length >= 5 
                        ? Colors.grey[200] 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 60,
                        color: selectedImages.length >= 5 
                            ? Colors.grey[300]
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          children: [
                            TextSpan(
                              text: selectedImages.length >= 5 
                                  ? 'Maximum 5 photos reached'
                                  : 'Click to upload',
                              style: TextStyle(
                                color: selectedImages.length >= 5 
                                    ? Colors.grey[400]
                                    : const Color(0xFF00A8E8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (selectedImages.length < 5)
                              const TextSpan(text: ' or drag and drop'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedImages.length >= 5 
                            ? 'Remove photos to add more'
                            : 'SVG, PNG, JPG or GIF (MAX. 800x400px)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (selectedImages.isNotEmpty && selectedImages.length < 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${selectedImages.length}/5 photos selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              
              const Text(
                'Job Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: descriptionController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Describe the work to be done, including any specific tasks, areas to focus on, or special instructions...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A8E8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Post Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  

  @override
  void dispose() {
    budgetController.dispose();
    durationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
