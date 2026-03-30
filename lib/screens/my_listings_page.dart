import 'package:flutter/material.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final TextEditingController _searchController = TextEditingController();

  String selectedStatus = 'All';
  String selectedSort = 'Newest';

  final List<Map<String, dynamic>> listings = [
    {
      'title': 'Apartment Cleaning Service',
      'description': 'Deep cleaning for 2–bedroom apartments.',
      'status': 'Active',
      'date': '12/03/2024',
      'image':
          'https://images.unsplash.com/photo-1581579184808-b72b4f5f8a03?w=800',
    },
    {
      'title': 'Office Cleaning',
      'description': 'Daily cleaning for small-medium offices.',
      'status': 'Paused',
      'date': '10/03/2024',
      'image':
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
    },
    {
      'title': 'Window Washing Service',
      'description': 'Professional window cleaning for homes and businesses.',
      'status': 'Booked',
      'date': '08/03/2024',
      'image':
          'https://images.unsplash.com/photo-1581578017423-3b243dbb3a34?w=800',
    },
  ];

  List<Map<String, dynamic>> get filteredListings {
    return listings.where((listing) {
      final matchesSearch = listing['title'].toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
      final matchesStatus =
          selectedStatus == 'All' ? true : listing['status'] == selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _handleDelete(Map<String, dynamic> listing) {
    setState(() {
      listings.remove(listing);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${listing['title']} deleted')));
  }

  void _handlePause(Map<String, dynamic> listing) {
    setState(() {
      listing['status'] = 'Paused';
    });
  }

  void _handleActivate(Map<String, dynamic> listing) {
    setState(() {
      listing['status'] = 'Active';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Listings',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildFilterRow(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredListings.length,
                itemBuilder: (context, index) {
                  final listing = filteredListings[index];
                  return _buildListingCard(listing);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search my listings...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            label: 'Filter by Status',
            value: selectedStatus,
            items: const ['All', 'Active', 'Paused', 'Booked'],
            onChanged: (val) => setState(() => selectedStatus = val!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDropdown(
            label: 'Sort by Date',
            value: selectedSort,
            items: const ['Newest', 'Oldest'],
            onChanged: (val) => setState(() => selectedSort = val!),
          ),
        ),
      ],
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    Color statusColor;
    switch (listing['status']) {
      case 'Active':
        statusColor = const Color(0xFF22C55E);
        break;
      case 'Paused':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'Booked':
        statusColor = const Color(0xFF3B82F6);
        break;
      default:
        statusColor = const Color(0xFF9CA3AF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              listing['image'],
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        listing['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      'Posted on: ${listing['date']}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  listing['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  listing['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSmallButton(
                      text: 'Edit',
                      color: const Color(0xFFE5E7EB),
                      textColor: const Color(0xFF111827),
                      onPressed: () {},
                    ),
                    if (listing['status'] == 'Active')
                      _buildSmallButton(
                        text: 'Pause',
                        color: const Color(0xFFF3F4F6),
                        textColor: const Color(0xFF6B7280),
                        onPressed: () => _handlePause(listing),
                      ),
                    if (listing['status'] == 'Paused')
                      _buildSmallButton(
                        text: 'Activate',
                        color: const Color(0xFFD1FAE5),
                        textColor: const Color(0xFF047857),
                        onPressed: () => _handleActivate(listing),
                      ),
                    _buildSmallButton(
                      text: 'Delete',
                      color: const Color(0xFFFEE2E2),
                      textColor: const Color(0xFFDC2626),
                      onPressed: () => _handleDelete(listing),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 38,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
