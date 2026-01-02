import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/job_model.dart';
import '../data/models/booking_model.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/available_jobs_cubit.dart';
import '../data/repositories/bookings/bookings_repo.dart';
import '../data/repositories/profiles/profile_repo.dart';
import '../utils/image_helper.dart';


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

  @override
  void dispose() {
    _bidPriceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
            const SnackBar(
              content: Text('Please login to submit a bid'),
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
            const SnackBar(
              content: Text('Unable to get user ID'),
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
            const SnackBar(
              content: Text('Please enter a valid bid price'),
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
        context.read<AvailableJobsCubit>().refresh(providerId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bid submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting bid: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text(
          'Job Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            if (widget.job.coverImageUrl != null)
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: 1, 
                  itemBuilder: (context, index) {
                    return AppImage(
                      imageUrl: widget.job.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 64, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),

            
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
                      if (state is ProfilesLoaded && widget.job.clientId != null) {
                        
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: AbstractProfileRepo.getInstance().getProfileById(widget.job.clientId!),
                          builder: (context, snapshot) {
                            final clientName = snapshot.data?['full_name'] as String? ?? 'Client';
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[300],
                                  child: const Icon(Icons.person, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Posted by',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        clientName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '4.8',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 16),

                  
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.job.fullLocation,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatDate(widget.job.jobDate)}, ${_formatTime(widget.job.jobDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (widget.job.estimatedHours != null)
                        Text(
                          ' (Est. ${widget.job.estimatedHours} ${widget.job.estimatedHours == 1 ? 'hour' : 'hours'})',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  
                  if (widget.job.budgetMin != null || widget.job.budgetMax != null)
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Budget: DA ${widget.job.budgetMin?.toStringAsFixed(0) ?? ''}${widget.job.budgetMax != null && widget.job.budgetMax != widget.job.budgetMin ? ' - DA ${widget.job.budgetMax!.toStringAsFixed(0)}' : ''}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
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
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.job.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),

            
            if (widget.job.requiredServices != null && widget.job.requiredServices!.isNotEmpty)
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
                    const Text(
                      'Required Services',
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
                        return Chip(
                          label: Text(service),
                          backgroundColor: Colors.blue[50],
                          labelStyle: const TextStyle(color: Colors.blue),
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
                    const Text(
                      'Your Bid',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    
                    const Text(
                      'Your Price (DA)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bidPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter your bid price',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixText: 'DA ',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a bid price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    
                    const Text(
                      'Message (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add a short message to the client...',
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Bid',
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
    );
  }
}


