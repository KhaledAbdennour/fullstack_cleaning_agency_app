import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cleaner_profile_page.dart';
import '../logic/cubits/search_cubit.dart';

class FindCleanerPage extends StatefulWidget {
  const FindCleanerPage({super.key});

  @override
  State<FindCleanerPage> createState() => _FindCleanerPageState();
}

class _FindCleanerPageState extends State<FindCleanerPage> {
  final TextEditingController _searchController = TextEditingController();
  String? selectedLocation;
  String? selectedRating;
  String? selectedPrice;

  @override
  void initState() {
    super.initState();
    
    context.read<SearchCubit>().loadSearchResults();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _reloadSearch();
      }
    });
  }

  void _reloadSearch() {
    context.read<SearchCubit>().loadSearchResults(
      query: _searchController.text.isEmpty ? null : _searchController.text,
      location: selectedLocation == 'All' ? null : selectedLocation,
      rating: selectedRating == 'All' ? null : selectedRating,
      price: selectedPrice == 'All' ? null : selectedPrice,
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for cleaning services',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Flexible(
                  flex: 1,
                  child: _buildFilterButton(
                    label: 'Location',
                    icon: Icons.location_on_outlined,
                    value: selectedLocation ?? 'All',
                    onTap: () {
                      _showLocationFilter();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: _buildFilterButton(
                    label: 'Rating',
                    icon: Icons.star_outline,
                    value: selectedRating ?? 'All',
                    onTap: () {
                      _showRatingFilter();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: _buildFilterButton(
                    label: 'Price',
                    icon: Icons.attach_money,
                    value: selectedPrice ?? 'All',
                    onTap: () {
                      _showPriceFilter();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SearchError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<SearchCubit>().refresh(
                              query: _searchController.text.isEmpty ? null : _searchController.text,
                              location: selectedLocation == 'All' ? null : selectedLocation,
                              rating: selectedRating == 'All' ? null : selectedRating,
                              price: selectedPrice == 'All' ? null : selectedPrice,
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is SearchLoaded) {
                  if (state.results.isEmpty) {
                    return const Center(
                      child: Text(
                        'No cleaners found',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.results.length,
                    itemBuilder: (context, index) {
                      return _buildCleanerCard(state.results[index]);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      );
  }

  Widget _buildFilterButton({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanerCard(Map<String, dynamic> cleaner) {
    
    final name = cleaner['name'] as String? ?? 'Unknown';
    final description = cleaner['description'] as String? ?? '';
    final location = cleaner['location'] as String? ?? 'Unknown';
    final price = cleaner['price'] as String? ?? 'Contact for pricing';
    final rating = cleaner['rating'] as num? ?? 0.0;
    final reviews = cleaner['reviews'] as int? ?? 0;
    final imageUrl = cleaner['image'] as String?;
    
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
              
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE5E7EB),
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 30, color: Color(0xFF9CA3AF));
                          },
                        )
                      : const Icon(Icons.person, size: 30, color: Color(0xFF9CA3AF)),
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
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
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
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
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
                    builder: (context) => CleanerProfilePage(cleaner: cleaner),
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
              child: const Text(
                'View Profile',
                style: TextStyle(
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

  void _showLocationFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFilterOption('All', selectedLocation == 'All', () {
              setState(() => selectedLocation = 'All');
              _reloadSearch();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }),
            _buildFilterOption('Algiers', selectedLocation == 'Algiers', () {
              setState(() => selectedLocation = 'Algiers');
              _reloadSearch();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }),
            _buildFilterOption('Oran', selectedLocation == 'Oran', () {
              setState(() => selectedLocation = 'Oran');
              _reloadSearch();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }),
            _buildFilterOption('Constantine', selectedLocation == 'Constantine', () {
              setState(() => selectedLocation = 'Constantine');
              _reloadSearch();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }),
          ],
        ),
      ),
    );
  }

  void _showRatingFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Minimum Rating',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFilterOption('All', selectedRating == 'All', () {
              setState(() => selectedRating = 'All');
              _reloadSearch();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }),
            _buildFilterOption('4.5+', selectedRating == '4.5+', () {
              setState(() => selectedRating = '4.5+');
              _reloadSearch();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }),
            _buildFilterOption('4.0+', selectedRating == '4.0+', () {
              setState(() => selectedRating = '4.0+');
              _reloadSearch();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }),
            _buildFilterOption('3.5+', selectedRating == '3.5+', () {
              setState(() => selectedRating = '3.5+');
              _reloadSearch();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }),
          ],
        ),
      ),
    );
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Price Range',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFilterOption('All', selectedPrice == 'All', () {
              setState(() => selectedPrice = 'All');
              _reloadSearch();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }),
            _buildFilterOption('Under 1500 DZD', selectedPrice == 'Under 1500 DZD', () {
              setState(() => selectedPrice = 'Under 1500 DZD');
              _reloadSearch();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }),
            _buildFilterOption('1500-2000 DZD', selectedPrice == '1500-2000 DZD', () {
              setState(() => selectedPrice = '1500-2000 DZD');
              _reloadSearch();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }),
            _buildFilterOption('2000+ DZD', selectedPrice == '2000+ DZD', () {
              setState(() => selectedPrice = '2000+ DZD');
              _reloadSearch();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, bool isSelected, VoidCallback onTap) {
    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF3B82F6)) : null,
      onTap: onTap,
    );
  }
}


