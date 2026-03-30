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
import '../l10n/app_localizations.dart';

class PostJobScreen extends StatefulWidget {
  final bool showInScaffold;
  const PostJobScreen({super.key, this.showInScaffold = true});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  String? selectedServiceType;
  String? selectedProvince;
  final TextEditingController budgetMinController = TextEditingController();
  final TextEditingController budgetMaxController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedDurationUnit;
  final ImagePicker _picker = ImagePicker();
  List<XFile> selectedImages = [];

  List<Map<String, dynamic>> getServiceTypes(BuildContext context) => [
        {
          'title': AppLocalizations.of(context)!.homeCleaning,
          'key': 'Home',
          'image':
              'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=600&auto=format&fit=crop', // Modern house exterior (switched from specialty)
          'isAsset': false,
        },
        {
          'title': AppLocalizations.of(context)!.officeCleaning,
          'key': 'Office',
          'image':
              'https://images.unsplash.com/photo-1497366216548-37526070297c?w=600&auto=format&fit=crop', // Company/office building
          'isAsset': false,
        },
        {
          'title': AppLocalizations.of(context)!.industrialCleaning,
          'key': 'Industrial',
          'image':
              'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=600&auto=format&fit=crop', // Factory
          'isAsset': false,
        },
        {
          'title': AppLocalizations.of(context)!.specialtyCleaning,
          'key': 'Specialty',
          'image':
              'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=600&auto=format&fit=crop', // Mop/cleaning on wooden floor (switched from home)
          'isAsset': false,
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectLocation),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (budgetMinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter minimum budget'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (budgetMaxController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter maximum budget'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final budgetMin = double.tryParse(budgetMinController.text.trim());
    final budgetMax = double.tryParse(budgetMaxController.text.trim());

    if (budgetMin == null || budgetMax == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid budget amounts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (budgetMax < budgetMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum budget must be greater than or equal to minimum budget',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.pleaseEnterJobDescription,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final profilesCubit = context.read<ProfilesCubit>();

      var state = profilesCubit.state;
      if (state is! ProfilesLoaded || state.currentUser == null) {
        await profilesCubit.loadCurrentUser();
        if (!mounted) return;
        state = profilesCubit.state;
      }

      if (state is! ProfilesLoaded || state.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to post a job'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final user = state.currentUser!;
      final clientId = user['id'] as int?;

      if (clientId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get user ID'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final budgetMin = double.parse(budgetMinController.text.trim());
      final budgetMax = double.parse(budgetMaxController.text.trim());

      int? estimatedHours;
      if (durationController.text.isNotEmpty) {
        final duration = int.tryParse(durationController.text);
        if (duration != null) {
          final hoursText = AppLocalizations.of(context)!.hours;
          final currentUnit = selectedDurationUnit ?? hoursText;
          estimatedHours = currentUnit == hoursText ? duration : duration * 24;
        }
      }

      String? coverImageDataUrl;
      List<String> jobImagesList = [];

      if (selectedImages.isNotEmpty) {
        for (int i = 0; i < selectedImages.length; i++) {
          try {
            final imageFile = File(selectedImages[i].path);
            final imageBytes = await imageFile.readAsBytes();
            final base64Image = base64Encode(imageBytes);

            final extension =
                selectedImages[i].path.split('.').last.toLowerCase();
            String mimeType = 'image/jpeg';
            if (extension == 'png') {
              mimeType = 'image/png';
            } else if (extension == 'gif') {
              mimeType = 'image/gif';
            } else if (extension == 'webp') {
              mimeType = 'image/webp';
            }

            final imageDataUrl = 'data:$mimeType;base64,$base64Image';
            jobImagesList.add(imageDataUrl);

            if (i == 0) {
              coverImageDataUrl = imageDataUrl;
            }
          } catch (e) {
            print('Error converting image ${i + 1} to base64: $e');
          }
        }
      }

      final job = Job(
        title: '$selectedServiceType Cleaning - $selectedProvince',
        city: selectedProvince!,
        country: 'Algeria',
        description: descriptionController.text,
        status: JobStatus.active,
        postedDate: DateTime.now(),
        jobDate: DateTime.now().add(const Duration(days: 7)),
        coverImageUrl: coverImageDataUrl,
        jobImages: jobImagesList.isNotEmpty ? jobImagesList : null,
        clientId: clientId,
        agencyId: null,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        estimatedHours: estimatedHours,
        requiredServices: [selectedServiceType!],
      );

      final jobsRepo = AbstractJobsRepo.getInstance();
      await jobsRepo.createJob(job);

      if (!mounted) return;

      setState(() {
        selectedServiceType = null;
        selectedProvince = null;
        budgetMinController.clear();
        budgetMaxController.clear();
        durationController.clear();
        descriptionController.clear();
        selectedImages.clear();
        selectedDurationUnit = null;
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
    } catch (e, stackTrace) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting job: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        print('Error posting job: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  Widget _buildFormContent() {
    selectedDurationUnit ??= AppLocalizations.of(context)!.hours;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.selectServiceType,
              style: const TextStyle(
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
              itemCount: getServiceTypes(context).length,
              itemBuilder: (context, index) {
                final service = getServiceTypes(context)[index];
                final isSelected = selectedServiceType == service['key'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedServiceType = service['key'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(
                                13,
                              ),
                              topRight: Radius.circular(13),
                            ),
                            child: service['isAsset'] == true
                                ? Image.asset(
                                    service['image'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    cacheWidth: 600,
                                    cacheHeight: 600,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 40,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Image not found',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : Image.network(
                                    service['image'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    cacheWidth: 600,
                                    cacheHeight: 600,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 40,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Failed to load',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            service['title'],
                            textAlign: TextAlign.center,
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
            Text(
              AppLocalizations.of(context)!.locationWilaya,
              style: const TextStyle(
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
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey,
                  ),
                  hintText: AppLocalizations.of(context)!.selectYourProvince,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                initialValue: selectedProvince,
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
            Text(
              AppLocalizations.of(context)!.yourBudgetDzd,
              style: const TextStyle(
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
                controller: budgetMinController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.grey,
                  ),
                  hintText: 'Minimum Budget (DZD)',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
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
                controller: budgetMaxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.grey,
                  ),
                  hintText: 'Maximum Budget (DZD)',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.estimatedDuration,
              style: const TextStyle(
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
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.schedule,
                          color: Colors.grey,
                        ),
                        hintText: AppLocalizations.of(context)!.egPlaceholder,
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDurationUnit ??
                            AppLocalizations.of(context)!.hours,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: [
                          AppLocalizations.of(context)!.hours,
                          AppLocalizations.of(context)!.days,
                          AppLocalizations.of(context)!.weeks,
                        ].map((String unit) {
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
            Text(
              AppLocalizations.of(context)!.addPhotos,
              style: const TextStyle(
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
                width: double.infinity,
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        children: [
                          TextSpan(
                            text: selectedImages.length >= 5
                                ? AppLocalizations.of(
                                    context,
                                  )!
                                    .maximumPhotosReached
                                : AppLocalizations.of(context)!.clickToUpload,
                            style: TextStyle(
                              color: selectedImages.length >= 5
                                  ? Colors.grey[400]
                                  : const Color(0xFF3B82F6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (selectedImages.length < 5)
                            TextSpan(
                              text: AppLocalizations.of(context)!.dragAndDrop,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedImages.length >= 5
                          ? 'Remove photos to add more'
                          : 'SVG, PNG, JPG or GIF (MAX. 800x400px)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
            Text(
              AppLocalizations.of(context)!.jobDescription,
              style: const TextStyle(
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
                  hintText:
                      'Describe the work to be done, including any specific tasks, areas to focus on, or special instructions...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Post Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formContent = _buildFormContent();

    if (widget.showInScaffold) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            AppLocalizations.of(context)!.postANewJob,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: formContent,
      );
    } else {
      return formContent;
    }
  }

  @override
  void dispose() {
    budgetMinController.dispose();
    budgetMaxController.dispose();
    durationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
