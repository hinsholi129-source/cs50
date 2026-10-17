import 'package:flutter/material.dart';
import 'package:diskusifihk/discussion_repository.dart';
import 'package:diskusifihk/models/discussion.dart';
import 'package:diskusifihk/screens/detail_screen.dart';
import 'package:diskusifihk/screens/add_discussion_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DiscussionRepository _repository = DiscussionRepository();
  String? _currentUserId;
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'Semua Kategori';
  final List<String> _categories = [
    'Semua Kategori',
    'Fiqih Ibadah',
    'Fiqih Muamalah',
    'Fiqih Jinayah',
    'Fiqih Keluarga',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _repository.init();
      final userId = await _repository.getCurrentUserId();
      if (mounted) {
        setState(() {
          _currentUserId = userId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data: $e';
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
    // _loadData already handles setting state, so we don't need to do anything here
    // unless we want to show a specific refresh completion message
  }

  List<Discussion> _getFilteredDiscussions() {
    return _repository.discussions.where((discussion) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          discussion.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          discussion.content.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Filter by category
      final matchesCategory = _selectedCategory == 'Semua Kategori' ||
          discussion.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _toggleLikeDiscussion(String discussionId) {
    final discussion = _repository.discussions.firstWhere(
      (d) => d.id == discussionId,
      orElse: () => throw Exception('Discussion not found'),
    );
    setState(() {
      discussion.likeCount = discussion.likeCount > 0 ? discussion.likeCount - 1 : discussion.likeCount + 1;
    });
    _repository.saveToPrefs();
  }

  void _showEditDiscussionDialog(Discussion discussion) {
    final titleController = TextEditingController(text: discussion.title);
    final contentController = TextEditingController(text: discussion.content);
    String selectedCategory = discussion.category;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Topik'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Judul Topik'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Kategori'),
                value: selectedCategory,
                items: const [
                  'Fiqih Ibadah',
                  'Fiqih Muamalah',
                  'Fiqih Jinayah',
                  'Fiqih Keluarga',
                ].map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  selectedCategory = newValue!;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Isi Topik'),
                minLines: 4,
                maxLines: 8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                setState(() {
                  discussion = discussion.copyWith(
                    title: titleController.text,
                    content: contentController.text,
                    category: selectedCategory,
                    imageUrl: discussion.imageUrl, // Keep existing image URL
                  );
                });
                _repository.saveToPrefs();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDiscussion(String discussionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Topik'),
        content: const Text('Apakah Anda yakin ingin menghapus topik ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _repository.discussions.removeWhere((d) => d.id == discussionId);
              });
              _repository.saveToPrefs();
              Navigator.of(context).pop();
            },
            child: const Text('Hapus'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDiscussions = _getFilteredDiscussions();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diskusi Fiqih Kontemporer'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari diskusi...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _categories.map((category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : _selectedCategory;
                        });
                      },
                      labelStyle: TextStyle(
                        color: _selectedCategory == category 
                            ? Colors.white 
                            : Colors.grey[800],
                      ),
                      selectedColor: Colors.deepPurple,
                      backgroundColor: Colors.grey[200],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: filteredDiscussions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: filteredDiscussions.length,
                          itemBuilder: (context, index) {
                            final discussion = filteredDiscussions[index];
                            final bool isOwner = discussion.userId == _currentUserId;

                            return DiscussionCard(
                              discussion: discussion,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DetailScreen(discussionId: discussion.id),
                                  ),
                                );
                              },
                              onLikeToggle: _toggleLikeDiscussion,
                              isOwner: isOwner,
                              onEdit: isOwner ? () => _showEditDiscussionDialog(discussion) : null,
                              onDelete: isOwner ? () => _confirmDeleteDiscussion(discussion.id) : null,
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddDiscussionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada diskusi yang sesuai',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kata kunci atau filter kategori',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'Semua Kategori';
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Reset Filter'),
          ),
        ],
      ),
    );
  }
}

class DiscussionCard extends StatelessWidget {
  final Discussion discussion;
  final VoidCallback onTap;
  final ValueChanged<String> onLikeToggle;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DiscussionCard({
    super.key,
    required this.discussion,
    required this.onTap,
    required this.onLikeToggle,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        discussion.imageUrl != null && discussion.imageUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  discussion.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ListTile(
            onTap: onTap,
            title: Text(
              discussion.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  discussion.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(label: Text(discussion.category)),
                    const Spacer(),
                    Text(
                      '${discussion.commentCount} Komentar',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOwner) ...[
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit' && onEdit != null) onEdit!();
                      if (value == 'delete' && onDelete != null) onDelete!();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Hapus',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                    offset: const Offset(0, 30),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: Icon(
                    discussion.likeCount > 0
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: discussion.likeCount > 0 ? Colors.red : null,
                  ),
                  onPressed: () => onLikeToggle(discussion.id),
                ),
                Text(
                  '${discussion.likeCount}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
