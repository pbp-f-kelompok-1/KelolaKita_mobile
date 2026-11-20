import 'package:flutter/material.dart';

class SubmissionPage extends StatelessWidget {
  const SubmissionPage({super.key});

  static const String endpoint = '/api/v1/pengajuan/';

  // Warna semantik status sesuai desain SVG
  static const Color _statusPendingColor = Color(0xFFE8C55B);
  static const Color _statusAcceptedColor = Color(0xFF6DD47E);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        // === Header ===
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengajuan saya',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pantau barang sampai diterima.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                color: colors.onSurface,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // === Kartu Ringkasan Statistik ===
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(
                child: _StatCard(
                  count: '02',
                  label: 'Total pengajuan',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  count: '01',
                  label: 'Menunggu\npemeriksaan',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // === Section: Pengajuan terbaru ===
        Text(
          'Pengajuan terbaru',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        _SubmissionItemCard(
          icon: Icons.inventory_2_outlined,
          title: 'Meja belajar kayu',
          meta: 'Perabot · 18 Nov 2026',
          statusText: 'Sedang diperiksa',
          statusColor: _statusPendingColor,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _SubmissionItemCard(
          icon: Icons.menu_book_outlined,
          title: 'Buku pelajaran SMA',
          meta: 'Buku · 17 Nov 2026',
          statusText: 'Diterima · siap dijadwalkan',
          statusColor: _statusAcceptedColor,
          onTap: () {},
        ),

        const SizedBox(height: 20),

        // === Tombol CTA ===
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
              'Ajukan barang lain',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.count,
    required this.label,
  });

  final String count;
  final String label;

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
            Text(
              count,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionItemCard extends StatelessWidget {
  const _SubmissionItemCard({
    required this.icon,
    required this.title,
    required this.meta,
    required this.statusText,
    required this.statusColor,
    this.onTap,
  });

  final IconData icon;
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: colors.onSurface,
                  size: 26,
                ),
              ),
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
              Icon(
                Icons.chevron_right,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}