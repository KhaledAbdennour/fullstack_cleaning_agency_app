import 'package:flutter/material.dart';
import '../data/models/job_model.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job? job; 
  final Map<String, dynamic>? jobMap; 
  
  const JobDetailsScreen({super.key, this.job, this.jobMap});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final _priceController = TextEditingController(text: 'DA 6000');
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildImageCard(
                      'https://via.placeholder.com/200x120/90EE90/FFFFFF?text=Living+Room',
                      'Living Room',
                      'View from the entrance',
                    ),
                    _buildImageCard(
                      'https://via.placeholder.com/200x120/D2B48C/FFFFFF?text=Kitchen',
                      'Kitchen',
                      'Stove and cabinets',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.job?.title ?? widget.jobMap?['title'] ?? 'Apartment Deep Clean - 3 Bedroom',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: const NetworkImage(
                      'https://via.placeholder.com/40x40/FFA07A/FFFFFF?text=S',
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Posted by Client',
                    style: TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  const Text(
                    '4.8',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                Icons.location_on_outlined, 
                widget.job?.fullLocation ?? widget.jobMap?['location'] ?? 'Algiers, Hydra'
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.calendar_today_outlined,
                widget.job != null
                    ? '${_formatDate(widget.job!.jobDate)} (Est. ${widget.job!.estimatedHours ?? 4} hours)'
                    : widget.jobMap?['date'] ?? '15 Nov 2023, 10:00 AM (Est. 4 hours)',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.account_balance_wallet_outlined,
                widget.job != null
                    ? 'Budget: ${widget.job!.budgetMin != null && widget.job!.budgetMax != null 
                        ? 'DA ${widget.job!.budgetMin!.toStringAsFixed(0)} - DA ${widget.job!.budgetMax!.toStringAsFixed(0)}'
                        : 'Negotiable'}'
                    : widget.jobMap?['price'] ?? 'Budget: DA 5,000 - DA 7,000',
              ),
              const SizedBox(height: 24),
              const Text(
                'Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.job?.description ?? widget.jobMap?['description'] ?? 'Looking for a thorough deep clean of my 3-bedroom apartment. Focus areas are the kitchen and bathrooms. All cleaning supplies and equipment will be provided. The apartment will be empty, so no need to move furniture. Please be meticulous and detail-oriented.',
                style: const TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'Required Services',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.job?.requiredServices != null
                    ? widget.job!.requiredServices!.map((service) => _buildChip(service)).toList()
                    : [
                        _buildChip('Deep Cleaning'),
                        _buildChip('Kitchen Cleaning'),
                        _buildChip('Bathroom Sanitization'),
                        _buildChip('Floor Mopping'),
                        _buildChip('Window Washing'),
                      ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Your Bid',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your Price (DA)',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Message (Optional)',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add a short message to the client...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit Bid',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageUrl, String title, String subtitle) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
