import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/job_model.dart';
import '../data/models/booking_model.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/available_jobs_cubit.dart';
import '../logic/cubits/agency_dashboard_cubit.dart';
import '../data/repositories/bookings/bookings_repo.dart';
import '../data/repositories/profiles/profile_repo.dart';
import '../utils/image_helper.dart';
import '../l10n/app_localizations.dart';

class JobDetailsBidPage extends StatefulWidget {
  final Job job;

  const JobDetailsBidPage({super.key, required this.job});

  @override
  State<JobDetailsBidPage> createState() => _JobDetailsBidPageState();
}

class _JobDetailsBidPageState extends State<JobDetailsBidPage> {
  final TextEditingController _bidPriceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    if (widget.job.budgetMin != null) {
      final suggestedPrice = widget.job.budgetMax != null
          ? ((widget.job.budgetMin! + widget.job.budgetMax!) / 2).round()
          : widget.job.budgetMin!.round();
      _bidPriceController.text = suggestedPrice.toString();
    }
  }

  Widget _buildImageCarousel() {
    // Get all images from job_images field, or fallback to cover_image_url
    List<String> images = [];
    if (widget.job.jobImages != null && widget.job.jobImages!.isNotEmpty) {
      images = widget.job.jobImages!;
    } else if (widget.job.coverImageUrl != null &&
        widget.job.coverImageUrl!.isNotEmpty) {
      images = [widget.job.coverImageUrl!];
    }

    if (images.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 64, color: Colors.grey),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return AppImage(
                    imageUrl: images[index],
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _bidPriceController.dispose();
    _messageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBid() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final profilesCubit = context.read<ProfilesCubit>();
      await profilesCubit.loadCurrentUser();
      final state = profilesCubit.state;

      if (state is! ProfilesLoaded || state.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.pleaseLoginToSubmitBid,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final user = state.currentUser!;
      final providerId = user['id'] as int?;

      if (providerId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.unableToGetUserId),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final bidPrice = double.tryParse(_bidPriceController.text.trim());
      if (bidPrice == null || bidPrice <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.pleaseEnterValidBidPrice,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final booking = Booking(
        jobId: widget.job.id!,
        clientId: widget.job.clientId!,
        providerId: providerId,
        status: BookingStatus.pending,
        bidPrice: bidPrice,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bookingsRepo = AbstractBookingsRepo.getInstance();
      await bookingsRepo.createBooking(booking);

      if (mounted) {
        // Refresh available jobs (to remove the job from available list)
        context.read<AvailableJobsCubit>().refresh(providerId);

        // Refresh active listings (to show the job as pending)
        context.read<ActiveListingsCubit>().refresh(providerId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.bidSubmittedSuccessfully,
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        // Safely format error message (avoid encoding FieldValue in error string)
        String errorMsg = 'Error submitting bid';
        try {
          final errorStr = e.toString();
          // Remove FieldValue references from error message
          if (errorStr.contains('FieldValue')) {
            errorMsg = AppLocalizations.of(
              context,
            )!.errorSubmittingBidInvalidData;
          } else {
            errorMsg =
                'Error submitting bid: ${errorStr.length > 100 ? errorStr.substring(0, 100) : errorStr}';
          }
        } catch (_) {
          errorMsg = AppLocalizations.of(context)!.errorSubmittingBidUnexpected;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.jobDetails,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(),

            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  BlocBuilder<ProfilesCubit, ProfilesState>(
                    builder: (context, state) {
                      if (state is ProfilesLoaded &&
                          widget.job.clientId != null) {
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: AbstractProfileRepo.getInstance()
                              .getProfileById(widget.job.clientId!),
                          builder: (context, snapshot) {
                            final clientName =
                                snapshot.data?['full_name'] as String? ??
                                'Client';
                            final clientPhoto =
                                snapshot.data?['picture'] as String?;
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor: const Color(0xFF3B82F6),
                                  child:
                                      clientPhoto != null &&
                                          clientPhoto.isNotEmpty
                                      ? ClipOval(
                                          child: AppImage(
                                            imageUrl: clientPhoto,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorWidget: Container(
                                              width: 70,
                                              height: 70,
                                              color: const Color(0xFF3B82F6),
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            '${AppLocalizations.of(context)!.postedBy} ',
                                      ),
                                      TextSpan(
                                        text: clientName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    widget.job.fullLocation,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    '${_formatDate(widget.job.postedDate)} ${_formatTime(widget.job.postedDate)} (${AppLocalizations.of(context)!.estimatedHoursFormat((widget.job.estimatedHours ?? 4))})',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.account_balance_wallet_outlined,
                    widget.job.budgetMin != null && widget.job.budgetMax != null
                        ? '${AppLocalizations.of(context)!.budget}: DA ${widget.job.budgetMin!.toStringAsFixed(0)} - DA ${widget.job.budgetMax!.toStringAsFixed(0)}'
                        : widget.job.budgetMin != null
                        ? '${AppLocalizations.of(context)!.budget}: DA ${widget.job.budgetMin!.toStringAsFixed(0)}'
                        : widget.job.budgetMax != null
                        ? '${AppLocalizations.of(context)!.budget}: DA ${widget.job.budgetMax!.toStringAsFixed(0)}'
                        : '${AppLocalizations.of(context)!.budget}: ${AppLocalizations.of(context)!.budgetNegotiable}',
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.description,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.job.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),

            if (widget.job.requiredServices != null &&
                widget.job.requiredServices!.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.requiredServices,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.job.requiredServices!.map((service) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            service,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.yourBid,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      AppLocalizations.of(context)!.yourPriceDa,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bidPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        )!.enterYourBidPrice,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixText: 'DA ',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(
                            context,
                          )!.pleaseEnterBidPrice;
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return AppLocalizations.of(
                            context,
                          )!.pleaseEnterValidPrice;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Text(
                      AppLocalizations.of(context)!.messageOptional,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        )!.addShortMessageToClient,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B82F6),
                          ),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.submitBid,
                        style: const TextStyle(
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
    );
  }
}
