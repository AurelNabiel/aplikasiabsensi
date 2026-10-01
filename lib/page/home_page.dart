import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/activity.dart';
import '../../core/models/profile.dart';
import '../../core/models/stats.dart';
import '../../core/models/task.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/providers/auth_providers.dart';
import '../page/notification_page.dart';
import '../auth/providers/activity_providers.dart';
import '../auth/providers/statistics_provider.dart';
import '../auth/providers/task_provider.dart';

String _salam() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 18) return 'Selamat sore';
  return 'Selamat malam';
}


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _debounce;
  Timer? _notifDebounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _notifDebounce?.cancel();
    super.dispose();
  }

  void _syncNotifications() {
    _notifDebounce?.cancel();
    _notifDebounce = Timer(const Duration(milliseconds: 900), () async {
      final acts = ref.read(divisionUpcomingProvider).asData?.value;
      final myId = ref.read(currentProfileProvider).asData?.value?.id;
      final tasks =
          myId == null ? null : ref.read(myTasksProvider(myId)).asData?.value;
      if (acts != null && tasks != null) {
        await NotificationService.syncReminders(
            activities: acts, tasks: tasks);
      }
    });
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (ref.read(dashboardStatsProvider).hasValue) {
        ref.invalidate(dashboardStatsProvider);
      }
      if (ref.read(divisionUpcomingProvider).hasValue) {
        ref.invalidate(divisionUpcomingProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    final myId = profileAsync.asData?.value?.id;
    if (myId != null) {
      void onEvent(Object? prev, Object? next) {
        if (next is AsyncData) _scheduleRefresh();
      }
      ref.listen(userAttendanceRealtimeProvider(myId), onEvent);
      ref.listen(userSubmissionRealtimeProvider(myId), onEvent);
      ref.listen(activitiesRealtimeProvider, onEvent);
      ref.listen(myTaskAssignRealtimeProvider(myId), onEvent);
      ref.listen(divisionUpcomingProvider, (_, n) {
        if (n is AsyncData) _syncNotifications();
      });
      ref.listen(myTasksProvider(myId), (_, n) {
        if (n is AsyncData) _syncNotifications();
      });
    }

    final profile = profileAsync.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(currentProfileProvider);
          await Future.wait([
            ref.read(dashboardStatsProvider.future),
            ref.read(currentProfileProvider.future),
          ]);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeaderBlock(profile: profile),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BannerCarousel(),
                  const SizedBox(height: 18),
                  const _AbsenHero(),
                  const SizedBox(height: 18),
                  const _StatRow(),
                  const SizedBox(height: 22),
                  _sectionTitle('Menu'),
                  const SizedBox(height: 14),
                  const _MenuGrid(),
                ],
              ),
              
            ),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: const FloatingNavBar(current: NavTab.beranda),
      
    );
  }

  Widget _sectionTitle(String t) => Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(t,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      );
}

/// Header gradient: sapaan + jam digital live + tanggal (khas app absensi).
class _HeaderBlock extends ConsumerWidget {
  const _HeaderBlock({required this.profile});
  final Profile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = profile;
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 10, 22),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          UserAvatar(
            name: p?.fullName ?? '',
            url: p?.avatarUrl,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_salam()},',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9), fontSize: 12.5)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(p?.callName ?? 'Pengguna',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ),
                    if (p?.division != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(p!.division!.label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const _NotifBell(color: Colors.white),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Keluar',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
    );
  }
}

/// Kartu Absen menonjol: kegiatan terdekat + hitung mundur live + tombol besar.
class _AbsenHero extends ConsumerStatefulWidget {
  const _AbsenHero();

  @override
  ConsumerState<_AbsenHero> createState() => _AbsenHeroState();
}

class _AbsenHeroState extends ConsumerState<_AbsenHero> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ambil kegiatan terdekat yang AKAN DATANG dari daftar yang sudah
    // terfilter divisi (anggota: divisi+Umum, admin: semua).
    final acts =
        ref.watch(activitiesProvider).asData?.value ?? const <Activity>[];
    final now = DateTime.now();
    final upcoming = acts.where((a) => a.startTime.isAfter(now)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final next = upcoming.isEmpty ? null : upcoming.first;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: next != null ? AppColors.brandGradient : null,
        color: next == null ? AppColors.surface : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (next != null ? AppColors.primary : Colors.black)
                .withOpacity(next != null ? 0.30 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: next == null
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event_busy_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Belum ada kegiatan mendatang',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_available_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text('Kegiatan Berikutnya',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(next.division?.label ?? 'Umum',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(next.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(formatHitungMundur(next.startTime.difference(now)),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text('mulai ${formatTanggalJam(next.startTime)}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 12)),
              ],
            ),
    );
  }
}

class _StatRow extends ConsumerWidget {
  const _StatRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats =
        ref.watch(dashboardStatsProvider).asData?.value ?? DashboardStats.empty;
    return Row(
      children: [
        _StatCard(
            label: 'Hadir',
            value: '${stats.hadirBulan}',
            color: AppColors.success,
            icon: Icons.check_circle_rounded),
        const SizedBox(width: 12),
        _StatCard(
            label: 'Tugas',
            value: '${stats.tugasAktif}',
            color: AppColors.info,
            icon: Icons.task_alt_rounded),
        const SizedBox(width: 12),
        _StatCard(
            label: 'Kegiatan',
            value: '${stats.kegiatanBerlangsung}',
            color: AppColors.warning,
            icon: Icons.event_rounded),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 10),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w800)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

/// Bottom navigation bar dengan tombol Absen di tengah.
class _MenuGrid extends StatelessWidget {
  const _MenuGrid();

  @override
  Widget build(BuildContext context) {
    const items = <(String, String, IconData, List<Color>)>[
      ('Absensi', '/attendance', Icons.how_to_reg_rounded,
          [Color(0xFF5B5FEF), Color(0xFF7C4DFF)]),
      ('Jadwal', '/activities', Icons.calendar_month_rounded,
          [Color(0xFF22D3EE), Color(0xFF3B82F6)]),
      ('Tugas', '/tasks', Icons.checklist_rounded,
          [Color(0xFF22C55E), Color(0xFF16A34A)]),
      ('Statistik', '/statistics', Icons.bar_chart_rounded,
          [Color(0xFFF59E0B), Color(0xFFF97316)]),
      ('Anggota', '/members', Icons.groups_rounded,
          [Color(0xFF3B82F6), Color(0xFF5B5FEF)]),
      ('Profil', '/profile', Icons.person_rounded,
          [Color(0xFFEC4899), Color(0xFFEF4444)]),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.92,
      children: [
        for (final it in items)
          _MenuTile(label: it.$1, path: it.$2, icon: it.$3, colors: it.$4),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.label,
    required this.path,
    required this.icon,
    required this.colors,
  });
  final String label;
  final String path;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(path),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifBell extends ConsumerWidget {
  const _NotifBell({this.color});
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming =
        ref.watch(divisionUpcomingProvider).asData?.value ?? const [];
    final profile = ref.watch(currentProfileProvider).asData?.value;
    final tasks = profile == null
        ? const <TaskItem>[]
        : (ref.watch(myTasksProvider(profile.id)).asData?.value ??
                const <TaskItem>[])
            .where((t) => t.mySubmission == null)
            .toList();
    final count = upcoming.length + tasks.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none_rounded, color: color),
          tooltip: 'Notifikasi',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

/// Data satu slide banner. Isi [image] dengan path aset (mis.
/// 'assets/banners/promo.png') atau URL (https://...). Biarkan null untuk
/// slide gradient berteks.
class _Banner {
  const _Banner({this.image, this.title = '', this.subtitle = '', required this.colors});
  final String? image;
  final String title;
  final String subtitle;
  final List<Color> colors;
}

/// Karosel banner beranda (auto-slide + indikator titik).
/// Ganti daftar [_banners] dengan gambar milikmu.
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();
  Timer? _auto;
  int _index = 0;

  // === Ganti / tambah banner di sini ===
  // Untuk gambar: _Banner(image: 'assets/banners/1.png', colors: [...])
  //   lalu daftarkan folder assets/banners/ di pubspec.yaml.
  // Untuk URL:    _Banner(image: 'https://.../1.jpg', colors: [...])
  static const List<_Banner> _banners = [
    _Banner(
      title: 'Selamat Datang di Umalink',
      subtitle: 'Absensi, jadwal & tugas dalam satu aplikasi',
      colors: [Color(0xFF5B5FEF), Color(0xFF7C4DFF)],
    ),
    _Banner(
      title: 'Jangan lupa absen kegiatanmu',
      subtitle: 'Cek jadwal terdekat di beranda',
      colors: [Color(0xFF22D3EE), Color(0xFF3B82F6)],
    ),
    _Banner(
      title: 'Kumpulkan poin keaktifan',
      subtitle: 'Hadir & selesaikan tugas tepat waktu',
      colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => _slide(_banners[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _index
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _slide(_Banner b) {
    final hasImage = b.image != null && b.image!.isNotEmpty;
    final radius = BorderRadius.circular(20);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: b.colors,
    );

    Widget content;
    if (hasImage) {
      final img = b.image!;
      final provider = img.startsWith('http')
          ? NetworkImage(img)
          : AssetImage(img) as ImageProvider;
      content = Image(
        image: provider,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) =>
            Container(decoration: BoxDecoration(gradient: gradient)),
      );
    } else {
      content = Container(
        decoration: BoxDecoration(gradient: gradient),
        padding: const EdgeInsets.all(18),
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (b.title.isNotEmpty)
              Text(b.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            if (b.subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(b.subtitle,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 12.5)),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: b.colors.first.withOpacity(0.30),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }
}
