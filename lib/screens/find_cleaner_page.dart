import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cleaner_profile_page.dart';
import '../logic/cubits/search_cubit.dart';
import '../utils/algerian_addresses.dart';
import '../l10n/app_localizations.dart';

class FindCleanerPage extends StatefulWidget {
  const FindCleanerPage({super.key});

  @override
  State<FindCleanerPage> createState() => _FindCleanerPageState();
}

class _FindCleanerPageState extends State<FindCleanerPage> {
  final TextEditingController _searchController = TextEditingController();
  Set<String> selectedWilayas = {}; // Multiple selection support
  double? minRating;
  double? maxRating;
  double? minPrice;
  double? maxPrice;

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
      wilayas: selectedWilayas.isEmpty ? null : selectedWilayas.toList(),
      minRating: minRating,
      maxRating: maxRating,
      minPrice: minPrice,
      maxPrice: maxPrice,
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
                hintText: AppLocalizations.of(context)!.searchForCleaningServices,
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
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
                    label: AppLocalizations.of(context)!.location,
                    icon: Icons.location_on_outlined,
                    value: selectedWilayas.isEmpty 
                        ? AppLocalizations.of(context)!.all 
                        : selectedWilayas.length == 1 
                            ? selectedWilayas.first 
                            : '${selectedWilayas.length} selected',
                    onTap: () {
                      _showLocationFilter();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: _buildFilterButton(
                    label: AppLocalizations.of(context)!.rating,
                    icon: Icons.star_outline,
                    value: minRating == null && maxRating == null
                        ? AppLocalizations.of(context)!.all
                        : '${minRating ?? 0.0}-${maxRating ?? 5.0}',
                    onTap: () {
                      _showRatingFilter();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: _buildFilterButton(
                    label: AppLocalizations.of(context)!.price,
                    icon: Icons.attach_money,
                    value: minPrice == null && maxPrice == null
                        ? AppLocalizations.of(context)!.all
                        : '${minPrice ?? 0}-${maxPrice ?? "∞"} DZD',
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
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
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
                              wilayas: selectedWilayas.isEmpty ? null : selectedWilayas.toList(),
                              minRating: minRating,
                              maxRating: maxRating,
                              minPrice: minPrice,
                              maxPrice: maxPrice,
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is SearchLoaded) {
                  if (state.results.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.noCleanersFound,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
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
            Icon(icon, size: 14, color: const Color(0xFF3B82F6)),
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
            const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF3B82F6)),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanerCard(Map<String, dynamic> cleaner) {
    
    final name = cleaner['name'] as String? ?? 'Unknown';
    final description = cleaner['description'] as String? ?? '';
    final location = cleaner['location'] as String? ?? 'Unknown';
    final price = cleaner['price'] as String? ?? AppLocalizations.of(context)!.contactForPricing;
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
              child: Text(
                AppLocalizations.of(context)!.viewProfile,
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
    final allWilayas = AlgerianAddresses.getAllWilayas();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Wilayas (Multiple)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (selectedWilayas.length == allWilayas.length) {
                            selectedWilayas.clear();
                          } else {
                            selectedWilayas = allWilayas.toSet();
                          }
                        });
                        setModalState(() {}); // Update modal UI
                        _reloadSearch();
                      },
                  child: Text(
                    selectedWilayas.length == allWilayas.length
                        ? AppLocalizations.of(context)!.deselectAll
                        : AppLocalizations.of(context)!.selectAll,
                        style: const TextStyle(color: Color(0xFF3B82F6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: allWilayas.length,
                    itemBuilder: (context, index) {
                      final wilaya = allWilayas[index];
                      final isSelected = selectedWilayas.contains(wilaya);
                      return CheckboxListTile(
                        title: Text(wilaya),
                        value: isSelected,
                        activeColor: const Color(0xFF3B82F6),
                        checkColor: Colors.white,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedWilayas.add(wilaya);
                            } else {
                              selectedWilayas.remove(wilaya);
                            }
                          });
                          setModalState(() {}); // Update modal UI immediately
                          _reloadSearch();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                  ),
                  child: Text(AppLocalizations.of(context)!.done, style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRatingFilter() {
    final minController = TextEditingController(text: minRating?.toString() ?? '');
    final maxController = TextEditingController(text: maxRating?.toString() ?? '');
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.ratingRange,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.minRating,
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 2),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.maxRating,
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 2),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        minRating = null;
                        maxRating = null;
                        minController.clear();
                        maxController.clear();
                      });
                      _reloadSearch();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                    child: Text(AppLocalizations.of(context)!.clear, style: const TextStyle(color: Color(0xFF3B82F6))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        minRating = double.tryParse(minController.text);
                        maxRating = double.tryParse(maxController.text);
                        // Validate range
                        if (minRating != null && (minRating! < 0 || minRating! > 5)) {
                          minRating = null;
                        }
                        if (maxRating != null && (maxRating! < 0 || maxRating! > 5)) {
                          maxRating = null;
                        }
                        if (minRating != null && maxRating != null && minRating! > maxRating!) {
                          // Swap if min > max
                          final temp = minRating;
                          minRating = maxRating;
                          maxRating = temp;
                        }
                      });
                      _reloadSearch();
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                    ),
                    child: Text(AppLocalizations.of(context)!.apply, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceFilter() {
    final minController = TextEditingController(text: minPrice?.toString() ?? '');
    final maxController = TextEditingController(text: maxPrice?.toString() ?? '');
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.priceRangeDzd,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.minPrice,
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 2),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      prefixText: 'DZD ',
                      prefixStyle: const TextStyle(color: Colors.grey),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.maxPrice,
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 2),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      prefixText: 'DZD ',
                      prefixStyle: const TextStyle(color: Colors.grey),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        minPrice = null;
                        maxPrice = null;
                        minController.clear();
                        maxController.clear();
                      });
                      _reloadSearch();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                    child: Text(AppLocalizations.of(context)!.clear, style: const TextStyle(color: Color(0xFF3B82F6))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        minPrice = double.tryParse(minController.text);
                        maxPrice = double.tryParse(maxController.text);
                        // Validate range
                        if (minPrice != null && minPrice! < 0) {
                          minPrice = null;
                        }
                        if (maxPrice != null && maxPrice! < 0) {
                          maxPrice = null;
                        }
                        if (minPrice != null && maxPrice != null && minPrice! > maxPrice!) {
                          // Swap if min > max
                          final temp = minPrice;
                          minPrice = maxPrice;
                          maxPrice = temp;
                        }
                      });
                      _reloadSearch();
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                    ),
                    child: Text(AppLocalizations.of(context)!.apply, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
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


