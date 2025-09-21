import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PitchIngestionScreen extends StatefulWidget {
  @override
  _PitchIngestionScreenState createState() => _PitchIngestionScreenState();
}

class _PitchIngestionScreenState extends State<PitchIngestionScreen> {
  final ImagePicker _picker = ImagePicker();

  // Mock data for existing pitches
  final List<Map<String, dynamic>> existingPitches = [
    {
      'type': 'PDF',
      'title': 'Company Pitch Deck',
      'date': '2024-01-15',
      'size': '2.4 MB',
      'status': 'Uploaded',
    },
    {
      'type': 'Video',
      'title': '1-Minute Video Intro',
      'date': '2024-01-10',
      'size': '15.2 MB',
      'status': 'Processed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Tell Your Story, Your Way',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Present your pitch in the format that best tells your story.',
              style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
            ),
            const SizedBox(height: 24),

            // Upload Options
            _buildUploadOptions(),

            const SizedBox(height: 24),

            // Existing Pitches
            if (existingPitches.isNotEmpty) ...[
              const Text(
                'Your Pitches',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 16),
              ...existingPitches.map((pitch) => _buildPitchCard(pitch)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOptions() {
    return Column(
      children: [
        _buildUploadOption(
          title: 'Upload Pitch Deck (PDF)',
          description: 'Upload your traditional pitch deck',
          icon: Icons.upload_file,
          color: const Color(0xFF4A90E2),
          onTap: () => _uploadPDF(),
        ),
        const SizedBox(height: 16),
        _buildUploadOption(
          title: 'Record Video Pitch',
          description: 'Record a passionate video pitch',
          icon: Icons.videocam,
          color: const Color(0xFF757575),
          onTap: () => _recordVideo(),
        ),
        const SizedBox(height: 16),
        _buildUploadOption(
          title: 'Submit Audio Summary',
          description: 'Record an audio summary of your pitch',
          icon: Icons.mic,
          color: const Color(0xFF757575),
          onTap: () => _recordAudio(),
        ),
      ],
    );
  }

  Widget _buildUploadOption({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPitchCard(Map<String, dynamic> pitch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPitchTypeColor(pitch['type']).withOpacity(0.1),
          child: Icon(
            _getPitchTypeIcon(pitch['type']),
            color: _getPitchTypeColor(pitch['type']),
          ),
        ),
        title: Text(
          pitch['title'],
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${pitch['date']} • ${pitch['size']}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(pitch['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pitch['status'],
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(pitch['status']),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deletePitch(pitch);
            } else if (value == 'share') {
              _sharePitch(pitch);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'share', child: Text('Share')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Color _getPitchTypeColor(String type) {
    switch (type) {
      case 'PDF':
        return const Color(0xFF4A90E2);
      case 'Video':
        return const Color(0xFFE91E63);
      case 'Audio':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF757575);
    }
  }

  IconData _getPitchTypeIcon(String type) {
    switch (type) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'Video':
        return Icons.videocam;
      case 'Audio':
        return Icons.audiotrack;
      default:
        return Icons.file_present;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Uploaded':
        return const Color(0xFF4CAF50);
      case 'Processing':
        return const Color(0xFFFF9800);
      case 'Processed':
        return const Color(0xFF4A90E2);
      case 'Error':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF757575);
    }
  }

  void _uploadPDF() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (file != null) {
        // In a real app, you would upload this to your backend
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF upload started...'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _recordVideo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Video Pitch'),
        content: const Text(
          'This feature will open your camera to record a video pitch.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video recording started...'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            child: const Text('Start Recording'),
          ),
        ],
      ),
    );
  }

  void _recordAudio() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Audio Summary'),
        content: const Text(
          'This feature will start recording an audio summary of your pitch.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Audio recording started...'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            child: const Text('Start Recording'),
          ),
        ],
      ),
    );
  }

  void _deletePitch(Map<String, dynamic> pitch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pitch'),
        content: Text('Are you sure you want to delete "${pitch['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                existingPitches.remove(pitch);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pitch deleted successfully'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _sharePitch(Map<String, dynamic> pitch) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${pitch['title']}"...'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
    );
  }
}
