import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/resource_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/resource_service.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> with SingleTickerProviderStateMixin {
  final ResourceService _resourceService = ResourceService();
  late TabController _tabController;
  
  // Data State
  List<ResourceModel> _approvedResources = [];
  List<ResourceModel> _myPendingResources = [];
  List<ResourceModel> _adminPendingResources = [];
  bool _isLoading = true;

  // Filter State
  String _searchQuery = '';
  String _selectedSubject = 'All Subjects';
  
  final List<String> _subjects = [
    'All Subjects',
    'Data Structures',
    'Database Management',
    'Computer Networks',
    'Operating Systems',
    'Software Engineering',
    'Web Development',
    'Machine Learning',
    'Computer Graphics',
    'Mobile App Development',
    'Cyber Security',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      // 1. Fetch Approved
      final approved = await _resourceService.getApprovedResources();
      
      // 2. Fetch My Pending (if not admin)
      List<ResourceModel> myPending = [];
      if (user.role != 'admin') {
        myPending = await _resourceService.getUserPendingResources(user.userId);
      }

      // 3. Fetch Admin Pending (if admin)
      List<ResourceModel> adminPending = [];
      if (user.role == 'admin') {
        adminPending = await _resourceService.getPendingResources();
      }

      if (mounted) {
        setState(() {
          _approvedResources = approved;
          _myPendingResources = myPending;
          _adminPendingResources = adminPending;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading resources: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading resources: $e')),
        );
      }
    }
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context, 
      builder: (ctx) => _UploadResourceDialog(
        subjects: _subjects.where((s) => s != 'All Subjects').toList(),
        onSubmit: (data, file) => _handleUpload(data, file),
      )
    );
  }

  Future<void> _handleUpload(Map<String, dynamic> formData, PlatformFile? file) async {
    if (file == null) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final fileBytes = File(file.path!).readAsBytesSync();
      final fileExt = file.name.split('.').last;
      final fileName = '${user.userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'resources/$fileName';

      // 1. Upload to Supabase Storage
      await Supabase.instance.client.storage
          .from('resources')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: false),
          );

      // 2. Get Public URL
      final publicUrl = Supabase.instance.client.storage
          .from('resources')
          .getPublicUrl(filePath);

      // 3. Create Database Record
      final isAutoApproved = user.role == 'faculty' || user.role == 'admin';
      
      final resourceData = {
        'title': formData['title'],
        'description': formData['description'],
        'subject': formData['subject'],
        'file_url': publicUrl,
        'file_name': file.name,
        'file_type': fileExt, // or MIME type
        'file_size': file.size,
        'uploaded_by': user.userId,
        'uploader_name': user.fullName,
        'uploader_role': user.role,
        'department': user.department ?? (formData['department'] ?? 'General'),
        'semester': user.courseTaken != null ? int.tryParse(user.courseTaken!.replaceAll(RegExp(r'[^0-9]'), '')) : 1, // Simplified parsing or default
        'is_approved': isAutoApproved,
        'approved_by': isAutoApproved ? user.userId : null,
        'approved_at': isAutoApproved ? DateTime.now().toIso8601String() : null,
      };

      await _resourceService.createResource(resourceData);

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAutoApproved 
              ? 'Resource uploaded successfully!' 
              : 'Resource uploaded! Waiting for approval.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleApprove(int id) async {
      try {
        final user = context.read<AuthProvider>().user;
        if (user == null) return;
        
        await _resourceService.approveResource(id, user.userId);
        
        if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Resource Approved!'), backgroundColor: Colors.green),
             );
             _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
  }

  Future<void> _handleDelete(int id) async {
      try {
          await _resourceService.deleteResource(id);
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Resource Deleted!')),
              );
              _loadData();
          }
      } catch (e) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
             );
           }
      }
  }

  List<ResourceModel> get _filteredApproved {
    return _approvedResources.where((r) {
      final matchesSearch = r.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            r.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSubject = _selectedSubject == 'All Subjects' || r.subject == _selectedSubject;
      return matchesSearch && matchesSubject;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final bool isAdmin = user.role == 'admin';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Resources', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              pinned: true,
              floating: true,
              backgroundColor: AppTheme.primaryBlue,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  const Tab(text: 'Browse'),
                  Tab(text: isAdmin 
                    ? 'Pending Requests (${_adminPendingResources.length})'
                    : 'My Uploads (${_myPendingResources.length})'
                  ),
                ],
              ),
            ),
          ];
        },
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBrowseTab(),
                if (isAdmin) 
                  _buildListTab(_adminPendingResources, isPending: true, isAdminView: true)
                else 
                  _buildListTab(_myPendingResources, isPending: true, isMyUploads: true),
              ],
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(context),
        label: const Text('Upload'),
        icon: const Icon(Iconsax.document_upload),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildBrowseTab() {
     return Column(
       children: [
         // Filters
         Container(
           padding: const EdgeInsets.all(16),
           color: Colors.white,
           child: Column(
             children: [
               TextField(
                 onChanged: (v) => setState(() => _searchQuery = v),
                 decoration: InputDecoration(
                   hintText: 'Search resources...',
                   prefixIcon: const Icon(Iconsax.search_normal),
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                   filled: true,
                   fillColor: Colors.grey.shade100,
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                 ),
               ),
               const SizedBox(height: 12),
               SingleChildScrollView(
                 scrollDirection: Axis.horizontal,
                 child: Row(
                   children: _subjects.map((sub) {
                     final isSelected = _selectedSubject == sub;
                     return Padding(
                       padding: const EdgeInsets.only(right: 8),
                       child: ChoiceChip(
                         label: Text(sub),
                         selected: isSelected,
                         onSelected: (b) => setState(() => _selectedSubject = b ? sub : 'All Subjects'),
                         selectedColor: AppTheme.primaryBlue.withOpacity(0.1),
                         labelStyle: TextStyle(
                           color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                         ),
                         side: BorderSide(color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300),
                       ),
                     );
                   }).toList(),
                 ),
               ),
             ],
           ),
         ),
         Expanded(child: _buildListTab(_filteredApproved)),
       ],
     );
  }

  Widget _buildListTab(List<ResourceModel> resources, {bool isPending = false, bool isAdminView = false, bool isMyUploads = false}) {
    if (resources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.folder_open, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending items' : 'No resources found',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final res = resources[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.document_text, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            res.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            res.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildTag(res.subject, Colors.blue),
                              if (res.department != null) ...[
                                const SizedBox(width: 8),
                                _buildTag(res.department!, Colors.teal),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'By ${res.uploaderName} • ${_formatSize(res.fileSize)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    Row(
                      children: [
                         if (!isPending)
                            TextButton.icon(
                                onPressed: () => _launchURL(res.fileUrl),
                                icon: const Icon(Iconsax.document_download, size: 18),
                                label: const Text('Download'),
                            ),
                         if (isAdminView)
                            TextButton.icon(
                                onPressed: () => _handleApprove(res.id),
                                icon: const Icon(Iconsax.tick_circle, size: 18, color: AppTheme.success),
                                label: const Text('Approve', style: TextStyle(color: AppTheme.success)),
                            ),
                          if (isAdminView || (isMyUploads && isPending))
                             IconButton(
                                 icon: const Icon(Iconsax.trash, color: AppTheme.error, size: 20),
                                 onPressed: () => _handleDelete(res.id),
                             ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildTag(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.shade100),
      ),
      child: Text(
        text,
        style: TextStyle(color: color.shade700, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _launchURL(String url) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Could not launch $url')),
           );
        }
      }
  }
}

class _UploadResourceDialog extends StatefulWidget {
  final List<String> subjects;
  final Function(Map<String, dynamic>, PlatformFile?) onSubmit;

  const _UploadResourceDialog({required this.subjects, required this.onSubmit});

  @override
  State<_UploadResourceDialog> createState() => _UploadResourceDialogState();
}

class _UploadResourceDialogState extends State<_UploadResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String? _subject;
  String? _department;
  PlatformFile? _selectedFile;

  final List<String> _departments = ['IT', 'CE', 'CS', 'DIT', 'DCE', 'DCS'];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'zip'],
      );
      if (result != null) {
        setState(() => _selectedFile = result.files.first);
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Resource'),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
              validator: (v) => v?.isNotEmpty == true ? null : 'Required',
              onSaved: (v) => _title = v!,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 2,
              onSaved: (v) => _description = v ?? '',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Subject *', border: OutlineInputBorder()),
              items: widget.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _subject = v),
              validator: (v) => v != null ? null : 'Required',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
              items: _departments.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _department = v),
              onSaved: (v) => _department = v,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.document_upload),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFile?.name ?? 'Select File *',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _selectedFile != null ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedFile != null) {
              _formKey.currentState!.save();
              widget.onSubmit({
                'title': _title,
                'description': _description,
                'subject': _subject,
                'department': _department,
              }, _selectedFile);
            } else if (_selectedFile == null) {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a file')),
              );
            }
          },
          child: const Text('Upload'),
        ),
      ],
    );
  }
}
