import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cleaner_profile_page.dart';
import '../logic/cubits/listings_cubit.dart';
import '../l10n/app_localizations.dart';
import '../utils/image_helper.dart';

class AgenciesListPage extends StatefulWidget {
  const AgenciesListPage({super.key});

  @override
  State<AgenciesListPage> createState() => _AgenciesListPageState();
}

class _AgenciesListPageState extends State<AgenciesListPage> {
  @override
  void initState() {
    super.initState();
    // Load listings to get agencies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ListingsCubit>().loadListings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Agencies',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ListingsCubit, ListingsState>(
        builder: (context, state) {
          if (state is ListingsLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
          } else if (state is ListingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ListingsCubit>().refresh();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is ListingsLoaded) {
            // Get all agencies and sort by rating descending
            final allAgencies = List<Map<String, dynamic>>.from(state.topAgencies);
            allAgencies.sort((a, b) {
              final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
              final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
              return ratingB.compareTo(ratingA); // Higher rating first
            });

            if (allAgencies.isEmpty) {
              return Center(
                child: Text(
                  'No agencies available',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allAgencies.length,
              itemBuilder: (context, index) {
                final agency = allAgencies[index];
                return _buildAgencyCard(context, agency);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAgencyCard(BuildContext context, Map<String, dynamic> agency) {
    final name = agency['name'] as String? ?? 'Unknown Agency';
    final description = agency['bio'] as String? ?? 'Professional cleaning service provider.';
    final location = agency['location'] as String? ?? 'Unknown';
    final priceValue = agency['hourly_rate'];
    final price = priceValue != null && priceValue.toString().isNotEmpty
        ? 'From $priceValue DZD/hr'
        : AppLocalizations.of(context)!.contactForPricing;
    final rating = (agency['rating'] as num?)?.toDouble() ?? 0.0;
    final reviews = agency['jobsCompleted'] as int? ?? 0;
    final imageUrl = agency['image'] as String?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Agency logo/image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE5E7EB),
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? AppImage(
                          imageUrl: imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(Icons.business, size: 30, color: Color(0xFF9CA3AF)),
                        )
                      : const Icon(Icons.business, size: 30, color: Color(0xFF9CA3AF)),
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            price,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} ($reviews Reviews)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CleanerProfilePage(cleaner: {
                      'name': name,
                      'rating': rating,
                      'reviews': reviews,
                      'isVerified': agency['is_verified'] as bool? ?? false,
                      'description': description,
                      'image': imageUrl,
                      'type': 'Agency',
                      'location': location,
                      'price': price,
                      'profileData': agency,
                    }),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                AppLocalizations.of(context)!.viewProfile,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
