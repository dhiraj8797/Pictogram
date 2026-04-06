import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/user_search_service.dart';
import '../../../core/models/user.dart';

// ── Trendily color tokens ─────────────────────────────────────────────────────
const Color _bgDark  = Color.fromRGBO(16,  7, 18, 1.0);
const Color _bgMid   = Color.fromRGBO(23,  8, 19, 1.0);
const Color _bgTop   = Color.fromRGBO(37,  4, 20, 1.0);
const Color _pink    = Color.fromRGBO(255, 61, 135, 1.0);
const Color _coral   = Color.fromRGBO(255, 106, 92, 1.0);
const Color _card    = Color.fromRGBO(255, 255, 255, 0.06);
const Color _border  = Color.fromRGBO(255, 255, 255, 0.10);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final UserSearchService _userSearchService = UserSearchService();

  String _query = '';
  List<AppUser> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults.clear(); _isSearching = false; });
      return;
    }
    setState(() { _isLoading = true; _isSearching = true; });
    try {
      final users = await _userSearchService.searchUsersPartial(query);
      if (mounted) setState(() { _searchResults = users; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clear() {
    _searchController.clear();
    setState(() { _query = ''; _searchResults.clear(); _isSearching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgTop, _bgMid, _bgDark],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.8),
                radius: 1.1,
                colors: [Color.fromRGBO(255, 61, 135, 0.15), Colors.transparent],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _card,
                            shape: BoxShape.circle,
                            border: Border.all(color: _border),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text('Search',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),

                // ── Search field ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? _pink.withValues(alpha: 0.5)
                                : _border,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          onChanged: (v) {
                            setState(() => _query = v.trim());
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted && _query == v.trim()) {
                                _searchUsers(_query);
                              }
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search users…',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 15),
                            prefixIcon: _isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(13),
                                    child: SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          color: _pink, strokeWidth: 2),
                                    ),
                                  )
                                : const Icon(Icons.search_rounded,
                                    color: Colors.white38, size: 22),
                            suffixIcon: _query.isNotEmpty
                                ? GestureDetector(
                                    onTap: _clear,
                                    child: const Icon(Icons.close_rounded,
                                        color: Colors.white38, size: 20),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Results ───────────────────────────────────────────────
                Expanded(
                  child: _isSearching
                      ? (_isLoading && _searchResults.isEmpty)
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: _pink, strokeWidth: 2))
                          : _searchResults.isEmpty
                              ? _emptyState(
                                  icon: Icons.person_search_rounded,
                                  title: 'No users found',
                                  subtitle: 'Try a different name',
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                                  itemCount: _searchResults.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, i) =>
                                      _UserTile(user: _searchResults[i]),
                                )
                      : _emptyState(
                          icon: Icons.search_rounded,
                          title: 'Find people',
                          subtitle: 'Search by display name',
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_pink.withValues(alpha: 0.18), _coral.withValues(alpha: 0.08)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: _pink.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: _pink, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── User result tile ──────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final AppUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile/${user.uid}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border, width: 0.8),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_pink, _coral],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: user.profileImage != null &&
                            user.profileImage!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.profileImage!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.person, color: Colors.white54),
                          )
                        : Container(
                            color: const Color(0xFF2A0830),
                            child: const Icon(Icons.person,
                                color: Colors.white54, size: 24),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.verificationBadge) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded,
                                color: _pink, size: 15),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white24, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
