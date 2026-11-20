import 'package:flutter/material.dart';

/// Halaman modul Penyetoran & Penjemputan.
///
/// Sementara memakai data statis; akan dihubungkan ke API Django
/// (`/api/schedule/`) pada tahap berikutnya.
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  static const Color _scheduledColor = Color(0xFF6DD47E);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          'Jadwal setor',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Atur penyetoran dan penjemputan barangmu.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // === Metode penyetoran ===
        const _SectionTitle('Pilih metode'),
        const _MethodCard(
          icon: Icons.local_shipping_outlined,
          title: 'Dijemput kurir',
          description: 'Kurir menjemput dari alamatmu sesuai sesi.',
        ),
        const SizedBox(height: 12),
        const _MethodCard(
          icon: Icons.place_outlined,
          title: 'Antar sendiri',
          description: 'Antarkan barang ke titik setoran mitra.',
        ),
        const SizedBox(height: 28),

        // === Sesi ===
        const _SectionTitle('Sesi penyetoran'),
        const Row(
          children: [
            Expanded(
              child: _SessionCard(
                icon: Icons.wb_twilight_outlined,
                name: 'Pagi',
                time: '08.00–11.30',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _SessionCard(
                icon: Icons.wb_sunny_outlined,
                name: 'Siang',
                time: '13.00–16.30',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // === Jadwal mendatang ===
        const _SectionTitle('Jadwal mendatang'),
        _ScheduleItemCard(
          title: 'Meja belajar kayu',
          meta: '23 Nov 2026 · Sesi Pagi',
          statusText: 'Terjadwal · Dijemput kurir',
          statusColor: _scheduledColor,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _ScheduleItemCard(
          title: 'Buku pelajaran SMA',
          meta: '25 Nov 2026 · Sesi Siang',
          statusText: 'Terjadwal · Antar sendiri',
          statusColor: _scheduledColor,
          onTap: () {},
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: colors.secondaryContainer,
              foregroundColor: colors.onSurface,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Jadwalkan penyetoran',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

class _IconBadge extends StatelessWidget {
  const _IconBadge(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: colors.onSurface, size: 26),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _IconBadge(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.icon,
    required this.name,
    required this.time,
  });

  final IconData icon;
  final String name;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.onSecondaryContainer),
            const SizedBox(height: 12),
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleItemCard extends StatelessWidget {
  const _ScheduleItemCard({
    required this.title,
    required this.meta,
    required this.statusText,
    required this.statusColor,
    this.onTap,
  });

  final String title;
  final String meta;
  final String statusText;
  final Color statusColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const _IconBadge(Icons.event_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
