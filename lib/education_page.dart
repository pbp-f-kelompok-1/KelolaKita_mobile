import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _apiBase = String.fromEnvironment('API_BASE_URL');

Future<Map<String, dynamic>> _fetch(String path) async {
  final origin = Uri.tryParse(_apiBase);
  if (origin == null ||
      !origin.hasAuthority ||
      (origin.scheme != 'https' && origin.scheme != 'http')) {
    throw const FormatException('API_BASE_URL harus berupa URL HTTP(S).');
  }
  final response = await http
      .get(origin.resolve('/api/education/$path'))
      .timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw http.ClientException('HTTP ${response.statusCode}');
  }
  return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
}

Future<List<Map<String, dynamic>>> _list(String resource) async {
  final json = await _fetch('$resource/');
  return (json['results'] as List).cast<Map<String, dynamic>>();
}

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  late var _content = _load();

  Future<List<List<Map<String, dynamic>>>> _load() =>
      Future.wait([_list('articles'), _list('events'), _list('distributions')]);

  void _retry() => setState(() => _content = _load());

  void _openArticle(Map<String, dynamic> article) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ArticlePage(
          title: article['title'] as String,
          slug: article['slug'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _content,
    builder: (context, snapshot) {
      final sections = snapshot.data;
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          Text(
            'Edukasi & komunitas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text('Ide sederhana, kebiasaan lebih baik.'),
          const SizedBox(height: 24),
          Text(
            'Bukan dibuang.\nBisa berguna lagi.',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (snapshot.connectionState != ConnectionState.done)
            const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Memuat edukasi',
              ),
            )
          else if (sections == null)
            _LoadError(onRetry: _retry)
          else ...[
            if (sections[0].isNotEmpty) _featured(sections[0].first),
            _section(
              'Baca selanjutnya',
              sections[0]
                  .skip(1)
                  .map(
                    (article) => _item(
                      Icons.menu_book_outlined,
                      article['title'] as String,
                      _metadata(article),
                      onTap: () => _openArticle(article),
                    ),
                  ),
            ),
            _section(
              'Agenda komunitas',
              sections[1].map(
                (event) => _item(
                  Icons.calendar_today_outlined,
                  event['title'] as String,
                  "${_date(event['start_at'])} · ${event['location_name']}",
                ),
              ),
            ),
            _section(
              'Catatan penyaluran',
              sections[2].map(
                (entry) => _item(
                  Icons.volunteer_activism_outlined,
                  entry['item_name'] as String,
                  "${entry['quantity']} barang · ${entry['destination_name']} · ${_date(entry['distributed_at'])}",
                ),
              ),
            ),
          ],
        ],
      );
    },
  );

  String _metadata(Map<String, dynamic> article) =>
      "${article['category_label']} · ${article['read_minutes']} menit baca";

  String _date(dynamic value) {
    final date = DateTime.parse(value as String);
    return MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
  }

  Widget _featured(Map<String, dynamic> article) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _openArticle(article),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 144,
            child: Image.network(
              article['cover_url'] as String,
              fit: BoxFit.cover,
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.menu_book_outlined, size: 40),
            ),
          ),
          ListTile(
            title: Text(article['title'] as String),
            subtitle: Text(_metadata(article)),
          ),
        ],
      ),
    ),
  );

  Widget _section(String title, Iterable<Widget> items) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(
            title == 'Baca selanjutnya'
                ? 'Belum ada artikel tambahan.'
                : 'Belum ada data.',
          )
        else
          ...items.map(
            (item) =>
                Padding(padding: const EdgeInsets.only(bottom: 8), child: item),
          ),
      ],
    ),
  );

  Widget _item(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text('Konten belum bisa dimuat.'),
      const SizedBox(height: 8),
      FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
    ],
  );
}

class _ArticlePage extends StatefulWidget {
  const _ArticlePage({required this.title, required this.slug});

  final String title;
  final String slug;

  @override
  State<_ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<_ArticlePage> {
  late var _article = _load();

  Future<Map<String, dynamic>> _load() =>
      _fetch('articles/${Uri.encodeComponent(widget.slug)}/');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Artikel')),
    body: FutureBuilder(
      future: _article,
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (snapshot.connectionState != ConnectionState.done)
            const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Memuat artikel',
              ),
            )
          else if (snapshot.hasData)
            Text(snapshot.data!['body'] as String)
          else
            _LoadError(onRetry: () => setState(() => _article = _load())),
        ],
      ),
    ),
  );
}
