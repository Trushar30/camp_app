/// Profile Screen - Redesigned
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Edit State
  bool _isEditing = false;
  bool _isSaving = false;
  
  // Department State
  String? _department;
  bool _isLoadingDept = false;

  // Controllers
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyController = TextEditingController();
  String _dob = ''; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _fnameController.text = user.firstName;
      _lnameController.text = user.lastName;
      _phoneController.text = user.mobileNum ?? '';
      _addressController.text = user.address ?? '';
      _emergencyController.text = user.emergencyContact ?? '';
      _dob = user.dob?.toString().split(' ').first ?? '';
      
      _fetchDepartment();
    }
  }

  Future<void> _fetchDepartment() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || !user.isStudent) return;

    if (mounted) setState(() => _isLoadingDept = true);

    try {
      final studentData = await _supabase
          .from('student_records')
          .select('class_id, course_taken')
          .eq('user_id', user.userId)
          .maybeSingle();

      if (studentData != null && studentData['class_id'] != null) {
        final classData = await _supabase
            .from('class_details')
            .select('department, institute')
            .eq('class_id', studentData['class_id'])
            .maybeSingle();

        if (classData != null && mounted) {
          setState(() {
            _department = '${classData['institute']} ${classData['department']}';
            _isLoadingDept = false;
          });
          return;
        }
      }
      
      if (mounted) {
        setState(() {
          _department = user.courseTaken;
          _isLoadingDept = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDept = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) return;

    try {
      // Use correct table names matching web version
      final tableName = user.role == 'student' ? 'student_records' : 'faculty';

      final response = await _supabase
          .from(tableName)
          .update({
            'fname': _fnameController.text,
            'lname': _lnameController.text,
            'mobile_num': _phoneController.text,
            'address': _addressController.text,
            'emergency_contact': _emergencyController.text,
          })
          .eq('user_id', user.userId)
          .select()
          .single();

      final updatedUser = user.copyWith(
        firstName: response['fname'],
        lastName: response['lname'],
        mobileNum: response['mobile_num']?.toString(),
        address: response['address'],
        emergencyContact: response['emergency_contact']?.toString(),
      );

      authProvider.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppTheme.success),
        );
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppTheme.error),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fnameController.dispose();
    _lnameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 320,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryBlue,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              actions: [
                if (_isEditing)
                  IconButton(
                    icon: _isSaving 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Iconsax.tick_circle, color: Colors.white),
                    onPressed: _isSaving ? null : _saveProfile,
                    tooltip: 'Save',
                  )
                else
                  IconButton(
                    icon: const Icon(Iconsax.edit, color: Colors.white),
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: 'Edit Profile',
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient Background
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.heroGradient,
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Avatar
                          Hero(
                            tag: 'profile_avatar',
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: user.profilePhoto != null 
                                    ? NetworkImage(user.profilePhoto!) 
                                    : null,
                                child: user.profilePhoto == null
                                    ? Text(
                                        user.firstName[0],
                                        style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                            ),
                          ).animate().scale(delay: 200.ms, begin: const Offset(0.8, 0.8)),
                          
                          const SizedBox(height: 16),
                          
                          // Name
                          if (_isEditing)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(child: _buildHeaderInput(_fnameController, 'First Name')),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildHeaderInput(_lnameController, 'Last Name')),
                                ],
                              ),
                            )
                          else
                            Text(
                              user.fullName,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                          
                          const SizedBox(height: 8),
                          
                          // Role & Dept
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_department ?? user.courseTaken ?? "Department"} • ${user.role.toUpperCase()}',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                          
                          const SizedBox(height: 12),
                          // ID Badge
                          Text(
                            'ID: ${user.userId}',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Docs'), // Shortened for space
                  Tab(text: 'Face Rec'),
                  Tab(text: 'Settings'),
                ],
              ),
            ),
          ];
        },
        body: Container(
          color: AppTheme.backgroundLight,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(user),
              _buildDocumentsTab(),
              _buildFaceRecTab(),
              _buildSettingsTab(user),
            ],
          ),
        ),
      ),
      floatingActionButton: _isEditing 
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveProfile,
              backgroundColor: AppTheme.secondaryTeal,
              icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Iconsax.tick_circle, color: Colors.white),
              label: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildHeaderInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // --- TABS ---

  Widget _buildOverviewTab(UserModel user) {
    final fields = [user.mobileNum, user.dob, user.address, user.emergencyContact];
    final filled = fields.where((f) => f != null && f.toString().isNotEmpty).length;
    final progress = filled / 4;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Personal Info
        _buildSectionTitle('Personal Information', Iconsax.user),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8), // Vertical padding for card
          child: Column(
            children: [
              _buildInfoRow(Iconsax.profile_circle, 'Full Name', user.fullName, showDivider: true),
              _buildInfoRow(Iconsax.calendar, 'Date of Birth', user.dob?.toString().split(' ').first ?? 'Not provided', showDivider: true),
              _buildInfoRow(Iconsax.location, 'Address', user.address ?? 'Not provided', 
                controller: _addressController, isEditable: _isEditing, showDivider: true),
              _buildInfoRow(Iconsax.call, 'Emergency Contact', user.emergencyContact ?? 'Not provided',
                controller: _emergencyController, isEditable: _isEditing, showDivider: false),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Student Info
        _buildSectionTitle('Academic Details', Iconsax.teacher),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              _buildInfoRow(Iconsax.building, 'Department', _department ?? user.courseTaken ?? 'Not specified', showDivider: true),
              _buildInfoRow(Iconsax.verify, 'Role', user.role.toUpperCase(), showDivider: true),
              _buildInfoRow(Iconsax.sms, 'Email', user.email, showDivider: true),
              _buildInfoRow(Iconsax.mobile, 'Phone', user.mobileNum ?? 'Not provided', 
                controller: _phoneController, isEditable: _isEditing, showDivider: false),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Completion
        _buildSectionTitle('Profile Completion', Iconsax.task),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Completion Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                    child: Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  color: AppTheme.secondaryTeal,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip('Phone', user.mobileNum != null),
                  _buildStatusChip('DOB', user.dob != null),
                  _buildStatusChip('Address', user.address != null),
                  _buildStatusChip('Emergency', user.emergencyContact != null),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 60), // Bottom padding
      ],
    );
  }

  Widget _buildDocumentsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionTitle('Academic Records', Iconsax.archive_book),
        const SizedBox(height: 16),
        _buildDocCard('Official Transcript', 'Updated: Oct 1, 2023'),
        _buildDocCard('Enrollment Verification', 'Updated: Sep 5, 2023'),
        _buildDocCard('Degree Audit', 'Updated: Sep 30, 2023'),
        
        const SizedBox(height: 32),
        
        _buildSectionTitle('Financial Documents', Iconsax.empty_wallet),
        const SizedBox(height: 16),
        _buildDocCard('Tuition Statement - Fall 2023', 'Issued: Aug 15, 2023'),
        _buildDocCard('Financial Aid Letter', 'Issued: Jul 20, 2023'),
      ],
    );
  }

  Widget _buildFaceRecTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Icon(Iconsax.scan_barcode, size: 60, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 24),
          const Text(
            'Face ID Configuration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enroll your face for\ncontactless attendance',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Iconsax.camera),
            label: const Text('Start Enrollment'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(UserModel user) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionTitle('Account', Iconsax.setting_2),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              _buildSettingTile(Iconsax.lock, 'Change Password', onTap: () {}),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(height: 1)),
              _buildSettingTile(Iconsax.notification, 'Notifications', trailing: Switch(
                value: true, 
                onChanged: (v) {},
                activeColor: AppTheme.primaryBlue,
              )),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(height: 1)),
              _buildSettingTile(Iconsax.security_safe, 'Privacy Policy', onTap: () {}),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: _buildSettingTile(
            Iconsax.logout, 
            'Logout', 
            color: AppTheme.error,
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            }
          ),
        ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 12),
        Text(
          title, 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {
    TextEditingController? controller, 
    bool isEditable = false,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    if (isEditable && controller != null)
                      TextField(
                        controller: controller,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          isDense: true,
                        ),
                      )
                    else
                      Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 68, right: 20), // Indent to align with text (20 pad + 10x2 icon + 22 icon + 16 gap = ~68? No. 20 pad + 42 container + 16 gap = 78.)
            // Container width = 22 (icon) + 20 (padding) = 42.
            // Row starts at 20. Icon ends at 62. Gap is 16. Text starts at 78.
            child: Divider(height: 1, color: Colors.grey.shade100),
          ),
      ],
    );
  }

  Widget _buildStatusChip(String label, bool isComplete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isComplete ? AppTheme.success.withValues(alpha: 0.2) : Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete ? AppTheme.success : Colors.white24,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Iconsax.tick_circle : Iconsax.close_circle,
            size: 14,
            color: isComplete ? AppTheme.success : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isComplete ? AppTheme.success : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Iconsax.document_text, color: AppTheme.primaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: IconButton(
          icon: const Icon(Iconsax.document_download),
          onPressed: () {},
          tooltip: 'Download',
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, {Widget? trailing, Color? color, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: color ?? Colors.grey.shade700),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      trailing: trailing ?? const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
