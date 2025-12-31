/// Resource Service
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/resource_model.dart';

class ResourceService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Fetch approved resources
  Future<List<ResourceModel>> getApprovedResources() async {
    final response = await _supabase
        .from('resources')
        .select()
        .eq('is_approved', true)
        .order('created_at', ascending: false);

    return (response as List).map((e) => ResourceModel.fromJson(e)).toList();
  }

  // Fetch pending resources (Admin only)
  Future<List<ResourceModel>> getPendingResources() async {
    final response = await _supabase
        .from('resources')
        .select()
        .eq('is_approved', false)
        .order('created_at', ascending: false);

    return (response as List).map((e) => ResourceModel.fromJson(e)).toList();
  }

  // Fetch user's pending resources
  Future<List<ResourceModel>> getUserPendingResources(String userId) async {
    final response = await _supabase
        .from('resources')
        .select()
        .eq('uploaded_by', userId)
        .eq('is_approved', false)
        .order('created_at', ascending: false);

    return (response as List).map((e) => ResourceModel.fromJson(e)).toList();
  }

  // Upload Resource Metadata
  Future<ResourceModel> createResource(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('resources')
        .insert(data)
        .select()
        .single();

    return ResourceModel.fromJson(response);
  }

  // Approve Resource (Admin)
  Future<void> approveResource(int id, String adminId) async {
    await _supabase.from('resources').update({
      'is_approved': true,
      'approved_by': adminId,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // Delete Resource
  Future<void> deleteResource(int id) async {
    await _supabase.from('resources').delete().eq('id', id);
  }
}
