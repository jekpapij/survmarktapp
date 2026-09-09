import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/survmarkt_app_bar.dart';
import '../../../../core/widgets/survmarkt_bottom_nav.dart';
import '../../../../router.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/survey_listing_entity.dart';
import '../providers/respondent_providers.dart';
import '../widgets/survey_detail_modal.dart';
import '../widgets/survey_listing_card.dart';

/// Discover — frame Figma `respondent-discover` (get_design_context, node
/// 77:2719). Data (list survei) diambil dari `respondentDiscoverProvider`
/// (mock) — `AsyncValue.when` di bawah nanganin ketiga state Loading/Error/
/// Success (CPMK 3).
///
/// Search bar & filter chip kategori di Figma keliatannya statis, tapi
/// sengaja dikasih interaksi CLIENT-SIDE beneran (`_searchQuery`/
/// `_selectedCategory` sebagai local state) — pola yang sama kayak chip
/// "Custom" di `create-survey` yang juga dikasih interaksi nyata walau di
/// Figma cuma teks. Search & filter TIDAK lewat provider/refetch — cukup
/// filter list yang udah di-fetch, biar nggak perlu invalidate provider
/// tiap ketikan.
class RespondentDiscoverScreen extends ConsumerStatefulWidget {
  const RespondentDiscoverScreen({super.key});

  @override
  ConsumerState<RespondentDiscoverScreen> createState() => _RespondentDiscoverScreenState();
}

class _RespondentDiscoverScreenState extends ConsumerState<RespondentDiscoverScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  SurveyCategory? _selectedCategory; // null = "Semua"

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SurveyListingEntity> _applyFilters(List<SurveyListingEntity> surveys) {
    return surveys.where((survey) {
      final matchesCategory = _selectedCategory == null || survey.category == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty || survey.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final discoverAsync = ref.watch(respondentDiscoverProvider);

    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SurvMarktAppBar(
              eyebrow: 'DISCOVER',
              unreadCount: ref.watch(unreadNotificationCountProvider),
              onBellTap: () => context.push(AppRoutes.notifications),
            ),
            Expanded(
              child: discoverAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.indigoAccent),
                ),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.slate400),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Gagal memuat daftar survei.\n$error',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: () => ref.invalidate(respondentDiscoverProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (surveys) => _DiscoverBody(
                  allSurveys: surveys,
                  filteredSurveys: _applyFilters(surveys),
                  searchController: _searchController,
                  selectedCategory: _selectedCategory,
                  onSearchChanged: (value) => setState(() => _searchQuery = value),
                  onCategorySelected: (category) => setState(() => _selectedCategory = category),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SurvMarktBottomNav(
        currentIndex: 0,
        items: const [
          SurvMarktNavItem(icon: Icons.explore_outlined, label: 'Discover'),
          SurvMarktNavItem(icon: Icons.history_rounded, label: 'Aktivitas'),
          SurvMarktNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
          SurvMarktNavItem(icon: Icons.person_outline, label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 0) return;
          // Update 2026-09-09: 3 frame respondent lain (`respondent-
          // activity`, `respondent-wallet`, `respondent-edit-profile`, +
          // `respondent-profil`) belum ditranslate — stub sementara, pola
          // sama kayak researcher pas dashboard-nya baru sendirian dulu.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layar ini nyusul — belum ditranslate dari Figma.')),
          );
        },
      ),
    );
  }
}

class _DiscoverBody extends StatelessWidget {
  const _DiscoverBody({
    required this.allSurveys,
    required this.filteredSurveys,
    required this.searchController,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategorySelected,
  });

  final List<SurveyListingEntity> allSurveys;
  final List<SurveyListingEntity> filteredSurveys;
  final TextEditingController searchController;
  final SurveyCategory? selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SurveyCategory?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final featured = filteredSurveys.where((s) => s.featured).toList();
    final normal = filteredSurveys.where((s) => !s.featured).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchInput(controller: searchController, onChanged: onSearchChanged),
          const SizedBox(height: 16),
          _FilterChipsRow(selected: selectedCategory, onSelected: onCategorySelected),
          if (featured.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'DIREKOMENDASIKAN',
              style: AppTypography.eyebrowMuted.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.slate600,
              ),
            ),
            const SizedBox(height: 10),
            for (final survey in featured)
              SurveyListingCard(survey: survey, onTap: () => showSurveyDetailModal(context, survey)),
          ],
          const SizedBox(height: 20),
          Text(
            'SEMUA SURVEI',
            style: AppTypography.eyebrowMuted.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 12),
          if (normal.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  allSurveys.isEmpty
                      ? 'Belum ada survei tersedia saat ini.'
                      : 'Nggak ada survei yang cocok — coba kata kunci atau kategori lain.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
              ),
            )
          else
            for (final survey in normal) ...[
              SurveyListingCard(survey: survey, onTap: () => showSurveyDetailModal(context, survey)),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary100),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: AppColors.slate400),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTypography.bodyMedium.copyWith(fontSize: 14, color: AppColors.slate900),
              decoration: InputDecoration.collapsed(
                hintText: 'Cari survei...',
                hintStyle: AppTypography.bodyMedium.copyWith(fontSize: 14, color: AppColors.slate400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.selected, required this.onSelected});

  final SurveyCategory? selected;
  final ValueChanged<SurveyCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(label: 'Semua', isActive: selected == null, onTap: () => onSelected(null)),
          const SizedBox(width: 8),
          for (final category in [SurveyCategory.pendidikan, SurveyCategory.kesehatan, SurveyCategory.bisnis]) ...[
            _Chip(
              label: category.label,
              isActive: selected == category,
              onTap: () => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.indigoAccent : Colors.white,
          border: isActive ? null : Border.all(color: AppColors.primary100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}
