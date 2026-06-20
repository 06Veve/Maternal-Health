import 'package:bebezen/admin/admin_service.dart';
import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _AdminSection { dashboard, users, households, moderation, audit }

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _service = AdminService();
  _AdminSection _section = _AdminSection.dashboard;
  late Future<AdminMetrics> _metrics;

  @override
  void initState() {
    super.initState();
    _metrics = _service.loadMetrics();
  }

  void _refreshMetrics() {
    setState(() => _metrics = _service.loadMetrics());
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 920;
    final content = _sectionContent();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: wide
          ? null
          : AppBar(
              title: Text(_section.label),
              actions: [
                IconButton(
                  tooltip: 'Déconnexion',
                  onPressed: _service.signOut,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
      drawer: wide
          ? null
          : Drawer(
              child: _AdminNavigation(
                selected: _section,
                onSelected: (section) {
                  setState(() => _section = section);
                  Navigator.pop(context);
                },
                onSignOut: _service.signOut,
              ),
            ),
      body: wide
          ? Row(
              children: [
                SizedBox(
                  width: 268,
                  child: _AdminNavigation(
                    selected: _section,
                    onSelected: (section) => setState(() => _section = section),
                    onSignOut: _service.signOut,
                  ),
                ),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  Widget _sectionContent() {
    return switch (_section) {
      _AdminSection.dashboard => _OverviewPage(
        metrics: _metrics,
        auditStream: _service.auditStream(),
        onRefresh: _refreshMetrics,
      ),
      _AdminSection.users => _UsersPage(service: _service),
      _AdminSection.households => _HouseholdsPage(service: _service),
      _AdminSection.moderation => _ModerationPage(service: _service),
      _AdminSection.audit => _AuditPage(service: _service),
    };
  }
}

extension on _AdminSection {
  String get label => switch (this) {
    _AdminSection.dashboard => 'Tableau de bord',
    _AdminSection.users => 'Utilisateurs',
    _AdminSection.households => 'Foyers',
    _AdminSection.moderation => 'Modération',
    _AdminSection.audit => 'Journal d’audit',
  };

  IconData get icon => switch (this) {
    _AdminSection.dashboard => Icons.dashboard_rounded,
    _AdminSection.users => Icons.people_alt_rounded,
    _AdminSection.households => Icons.family_restroom_rounded,
    _AdminSection.moderation => Icons.shield_rounded,
    _AdminSection.audit => Icons.history_rounded,
  };
}

class _AdminNavigation extends StatelessWidget {
  const _AdminNavigation({
    required this.selected,
    required this.onSelected,
    required this.onSignOut,
  });

  final _AdminSection selected;
  final ValueChanged<_AdminSection> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF211B35),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: BebezenPalette.primary,
                    child: Icon(Icons.favorite_rounded, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bebezen',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Administration',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              for (final section in _AdminSection.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: ListTile(
                    selected: selected == section,
                    selectedTileColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Icon(
                      section.icon,
                      color: selected == section
                          ? Colors.white
                          : Colors.white60,
                    ),
                    title: Text(
                      section.label,
                      style: TextStyle(
                        color: selected == section
                            ? Colors.white
                            : Colors.white70,
                        fontWeight: selected == section
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    onTap: () => onSelected(section),
                  ),
                ),
              const Spacer(),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Déconnexion',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: onSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Color(0xFF737789)),
                      ),
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({
    required this.metrics,
    required this.auditStream,
    required this.onRefresh,
  });

  final Future<AdminMetrics> metrics;
  final Stream<QuerySnapshot<Map<String, dynamic>>> auditStream;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      title: 'Tableau de bord',
      subtitle: 'Vue d’ensemble des données Bebezen',
      action: IconButton.filledTonal(
        tooltip: 'Actualiser',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: ListView(
        children: [
          FutureBuilder<AdminMetrics>(
            future: metrics,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorPanel(message: '${snapshot.error}');
              }
              final data = snapshot.data;
              final cards = [
                ('Utilisateurs', data?.users, Icons.people_alt_rounded),
                ('Mères', data?.mothers, Icons.pregnant_woman_rounded),
                ('Partenaires', data?.partners, Icons.person_rounded),
                ('Foyers', data?.households, Icons.family_restroom_rounded),
                ('Publications', data?.posts, Icons.forum_rounded),
              ];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 1100 ? 5 : (width >= 650 ? 3 : 1);
                  const gap = 14.0;
                  final cardWidth = (width - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final card in cards)
                        SizedBox(
                          width: cardWidth,
                          child: _MetricCard(
                            label: card.$1,
                            value: card.$2,
                            icon: card.$3,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 26),
          Text(
            'Activité administrative récente',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _Surface(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: auditStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorPanel(message: '${snapshot.error}');
                }
                if (!snapshot.hasData) return const _LoadingPanel();
                final documents = snapshot.data!.docs.take(6).toList();
                if (documents.isEmpty) {
                  return const _EmptyPanel(
                    icon: Icons.history_rounded,
                    message: 'Aucune action administrative enregistrée.',
                  );
                }
                return Column(
                  children: [
                    for (var index = 0; index < documents.length; index++) ...[
                      _AuditTile(data: documents[index].data()),
                      if (index < documents.length - 1)
                        const Divider(height: 1),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int? value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: BebezenPalette.primaryLight,
            child: Icon(icon, color: BebezenPalette.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value?.toString() ?? '—',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(label, style: const TextStyle(color: Color(0xFF737789))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersPage extends StatefulWidget {
  const _UsersPage({required this.service});
  final AdminService service;

  @override
  State<_UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<_UsersPage> {
  final _search = TextEditingController();
  String _role = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      title: 'Utilisateurs',
      subtitle: 'Consultation des comptes, sans accès aux données médicales',
      child: Column(
        children: [
          _Filters(
            controller: _search,
            hint: 'Rechercher un nom ou un email',
            onChanged: (_) => setState(() {}),
            trailing: DropdownButton<String>(
              value: _role,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tous les rôles')),
                DropdownMenuItem(value: 'mother', child: Text('Mères')),
                DropdownMenuItem(value: 'partner', child: Text('Partenaires')),
                DropdownMenuItem(value: 'admin', child: Text('Admins')),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'all'),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: widget.service.usersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorPanel(message: '${snapshot.error}');
                }
                if (!snapshot.hasData) return const _LoadingPanel();
                final query = _search.text.trim().toLowerCase();
                final users =
                    snapshot.data!.docs.where((document) {
                      final data = document.data();
                      final role = data['role'] as String? ?? '';
                      final text =
                          '${data['name'] ?? ''} ${data['email'] ?? ''}'
                              .toLowerCase();
                      return (_role == 'all' || role == _role) &&
                          (query.isEmpty || text.contains(query));
                    }).toList()..sort((a, b) {
                      final aName = '${a.data()['name'] ?? ''}'.toLowerCase();
                      final bName = '${b.data()['name'] ?? ''}'.toLowerCase();
                      return aName.compareTo(bName);
                    });
                if (users.isEmpty) {
                  return const _EmptyPanel(
                    icon: Icons.person_search_rounded,
                    message: 'Aucun utilisateur ne correspond aux filtres.',
                  );
                }
                return _Surface(
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final document = users[index];
                      final data = document.data();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: BebezenPalette.primaryLight,
                          child: Text(_initial(data['name'])),
                        ),
                        title: Text(
                          data['name'] ?? 'Nom indisponible',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(data['email'] ?? 'Email indisponible'),
                        trailing: _RoleChip(role: data['role'] ?? 'unknown'),
                        onTap: () => _showUser(context, document.id, data),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showUser(BuildContext context, String uid, Map<String, dynamic> data) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du compte'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'Nom', value: '${data['name'] ?? '—'}'),
              _DetailRow(label: 'Email', value: '${data['email'] ?? '—'}'),
              _DetailRow(label: 'Rôle', value: '${data['role'] ?? '—'}'),
              _DetailRow(
                label: 'Foyer',
                value: '${data['householdId'] ?? 'Non lié'}',
              ),
              _DetailRow(label: 'UID', value: uid),
              _DetailRow(label: 'Création', value: _date(data['createdAt'])),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _HouseholdsPage extends StatelessWidget {
  const _HouseholdsPage({required this.service});
  final AdminService service;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      title: 'Foyers',
      subtitle: 'Vue technique des liaisons mère–partenaire',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.householdsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorPanel(message: '${snapshot.error}');
          }
          if (!snapshot.hasData) return const _LoadingPanel();
          final households = snapshot.data!.docs;
          if (households.isEmpty) {
            return const _EmptyPanel(
              icon: Icons.family_restroom_rounded,
              message: 'Aucun foyer disponible.',
            );
          }
          return _Surface(
            child: ListView.separated(
              itemCount: households.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final document = households[index];
                final data = document.data();
                final pregnancy = Map<String, dynamic>.from(
                  data['pregnancy'] as Map? ?? {},
                );
                final partnerId = data['partnerId'] as String?;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: partnerId == null
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                    child: Icon(
                      Icons.family_restroom_rounded,
                      color: partnerId == null ? Colors.orange : Colors.green,
                    ),
                  ),
                  title: Text(
                    'Foyer ${_shortId(document.id)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Semaine initiale ${pregnancy['gestationalAgeWeeks'] ?? '—'} · '
                    '${partnerId == null ? 'Partenaire non lié' : 'Partenaire lié'}',
                  ),
                  trailing: Text(
                    '${(data['memberIds'] as List?)?.length ?? 1} membre(s)',
                  ),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Foyer ${_shortId(document.id)}'),
                      content: SizedBox(
                        width: 460,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _DetailRow(
                              label: 'Identifiant',
                              value: document.id,
                            ),
                            _DetailRow(
                              label: 'UID mère',
                              value: '${data['motherId'] ?? '—'}',
                            ),
                            _DetailRow(
                              label: 'UID partenaire',
                              value: partnerId ?? 'Non lié',
                            ),
                            _DetailRow(
                              label: 'Création',
                              value: _date(data['createdAt']),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ModerationPage extends StatefulWidget {
  const _ModerationPage({required this.service});
  final AdminService service;

  @override
  State<_ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<_ModerationPage> {
  final _search = TextEditingController();
  String _category = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      title: 'Modération',
      subtitle: 'Publications et réponses de la communauté',
      child: Column(
        children: [
          _Filters(
            controller: _search,
            hint: 'Rechercher un contenu ou un auteur',
            onChanged: (_) => setState(() {}),
            trailing: DropdownButton<String>(
              value: _category,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('Toutes les catégories'),
                ),
                DropdownMenuItem(value: 'General', child: Text('General')),
                DropdownMenuItem(value: 'Pregnancy', child: Text('Pregnancy')),
                DropdownMenuItem(value: 'Nutrition', child: Text('Nutrition')),
                DropdownMenuItem(
                  value: 'Mental Health',
                  child: Text('Mental Health'),
                ),
                DropdownMenuItem(value: 'Baby Care', child: Text('Baby Care')),
              ],
              onChanged: (value) => setState(() => _category = value ?? 'all'),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: widget.service.postsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorPanel(message: '${snapshot.error}');
                }
                if (!snapshot.hasData) return const _LoadingPanel();
                final query = _search.text.trim().toLowerCase();
                final posts =
                    snapshot.data!.docs.where((document) {
                      final data = document.data();
                      final content =
                          '${data['username'] ?? ''} ${data['content'] ?? ''}'
                              .toLowerCase();
                      return (_category == 'all' ||
                              data['category'] == _category) &&
                          (query.isEmpty || content.contains(query));
                    }).toList()..sort(
                      (a, b) => _timestamp(
                        b.data()['timestamp'],
                      ).compareTo(_timestamp(a.data()['timestamp'])),
                    );
                if (posts.isEmpty) {
                  return const _EmptyPanel(
                    icon: Icons.forum_outlined,
                    message: 'Aucune publication ne correspond aux filtres.',
                  );
                }
                return ListView.separated(
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final data = post.data();
                    return _Surface(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                child: Text(_initial(data['username'])),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['username'] ?? 'Anonyme',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${data['category'] ?? 'General'} · ${_date(data['timestamp'])}',
                                      style: const TextStyle(
                                        color: Color(0xFF737789),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Supprimer la publication',
                                onPressed: () => _deletePost(post.id),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SelectableText(data['content'] ?? ''),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => _showReplies(post.id),
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            label: const Text('Consulter les réponses'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    final reason = await _moderationReason(
      context,
      title: 'Supprimer cette publication ?',
    );
    if (reason == null) return;
    try {
      await widget.service.deletePost(postId: postId, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publication supprimée et auditée.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Suppression impossible.')),
      );
    }
  }

  void _showReplies(String postId) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Réponses',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: widget.service.repliesStream(postId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _ErrorPanel(message: '${snapshot.error}');
                      }
                      if (!snapshot.hasData) return const _LoadingPanel();
                      if (snapshot.data!.docs.isEmpty) {
                        return const _EmptyPanel(
                          icon: Icons.chat_bubble_outline,
                          message: 'Aucune réponse.',
                        );
                      }
                      return ListView.separated(
                        itemCount: snapshot.data!.docs.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final reply = snapshot.data!.docs[index];
                          final data = reply.data();
                          return ListTile(
                            title: Text(
                              data['username'] ?? 'Anonyme',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(data['text'] ?? ''),
                            trailing: IconButton(
                              tooltip: 'Supprimer la réponse',
                              onPressed: () => _deleteReply(
                                dialogContext: context,
                                postId: postId,
                                replyId: reply.id,
                              ),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteReply({
    required BuildContext dialogContext,
    required String postId,
    required String replyId,
  }) async {
    final reason = await _moderationReason(
      dialogContext,
      title: 'Supprimer cette réponse ?',
    );
    if (reason == null) return;
    await widget.service.deleteReply(
      postId: postId,
      replyId: replyId,
      reason: reason,
    );
  }
}

class _AuditPage extends StatelessWidget {
  const _AuditPage({required this.service});
  final AdminService service;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      title: 'Journal d’audit',
      subtitle: 'Historique immuable des opérations de modération',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.auditStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorPanel(message: '${snapshot.error}');
          }
          if (!snapshot.hasData) return const _LoadingPanel();
          if (snapshot.data!.docs.isEmpty) {
            return const _EmptyPanel(
              icon: Icons.history_rounded,
              message: 'Aucune action enregistrée.',
            );
          }
          return _Surface(
            child: ListView.separated(
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _AuditTile(data: snapshot.data!.docs[index].data()),
            ),
          );
        },
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final action = switch (data['action']) {
      'delete_post' => 'Publication supprimée',
      'delete_reply' => 'Réponse supprimée',
      _ => '${data['action'] ?? 'Action'}',
    };
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: BebezenPalette.primaryLight,
        child: Icon(Icons.gavel_rounded, color: BebezenPalette.primary),
      ),
      title: Text(action, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        '${data['adminEmail'] ?? data['adminId'] ?? 'Admin'} · '
        '${data['reason'] ?? 'Sans motif'}',
      ),
      trailing: Text(
        _date(data['createdAt']),
        style: const TextStyle(color: Color(0xFF737789), fontSize: 12),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search_rounded),
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E8EE)),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF737789)),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(switch (role) {
        'mother' => 'Mère',
        'partner' => 'Partenaire',
        'admin' => 'Admin',
        _ => role,
      }),
      side: BorderSide.none,
      backgroundColor: BebezenPalette.primaryLight,
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Erreur : $message', textAlign: TextAlign.center),
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: const Color(0xFF9A9DAC)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

Future<String?> _moderationReason(
  BuildContext context, {
  required String title,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 300,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Motif obligatoire',
          hintText: 'Expliquez la décision de modération',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final reason = controller.text.trim();
            if (reason.length >= 3) Navigator.pop(context, reason);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

String _initial(dynamic value) {
  final text = '${value ?? '?'}'.trim();
  return text.isEmpty ? '?' : text.substring(0, 1).toUpperCase();
}

String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);

DateTime _timestamp(dynamic value) => value is Timestamp
    ? value.toDate()
    : DateTime.fromMillisecondsSinceEpoch(0);

String _date(dynamic value) {
  if (value is! Timestamp) return 'Date indisponible';
  return DateFormat('dd/MM/yyyy HH:mm').format(value.toDate());
}
