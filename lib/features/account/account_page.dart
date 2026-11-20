import 'package:flutter/material.dart';

import 'account_controller.dart';
import 'account_profile.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.controller});
  final AccountController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (!controller.initialized ||
          (controller.busy && controller.profile == null)) {
        return const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat akun'),
        );
      }
      final profile = controller.profile;
      if (profile == null) {
        return _AccountLayout(
          title: 'Akun kamu',
          subtitle: 'Langkah kecilmu, dampak besar untuk bumi.',
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.eco_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Mulai kebiasaan baik bersama KelolaKita.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text('Masuk untuk melihat dan mengelola profilmu.'),
            if (controller.error != null) ...[
              _ErrorMessage(controller.error!),
              TextButton(
                onPressed: controller.initialize,
                child: const Text('Coba pulihkan sesi'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _open(
                context,
                _AccountForm(controller: controller, mode: _FormMode.login),
              ),
              child: const Text('Masuk'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _open(
                context,
                _AccountForm(controller: controller, mode: _FormMode.register),
              ),
              child: const Text('Daftar akun'),
            ),
          ],
        );
      }
      final colors = Theme.of(context).colorScheme;
      return _AccountLayout(
        title: 'Profil saya',
        subtitle: 'Kenali dampakmu. Kelola informasi akunmu.',
        children: [
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: profile.avatarUrl.isEmpty
                          ? _avatar(colors)
                          : Image.network(
                              profile.avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _avatar(colors),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.fullName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('@${profile.username}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Chip(label: Text(profile.role)),
                  const SizedBox(height: 8),
                  Text(
                    '${profile.points} poin dampak',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                _detail(Icons.mail_outline, 'Email', profile.email),
                _detail(
                  Icons.phone_outlined,
                  'Nomor telepon',
                  profile.phoneNumber,
                ),
                _detail(
                  Icons.location_on_outlined,
                  'Alamat utama',
                  profile.address,
                ),
                if (profile.updatedAt.isNotEmpty)
                  _detail(
                    Icons.update,
                    'Terakhir diperbarui',
                    profile.updatedAt,
                  ),
              ],
            ),
          ),
          if (controller.error != null) _ErrorMessage(controller.error!),
          const SizedBox(height: 24),
          if (controller.busy)
            const LinearProgressIndicator(semanticsLabel: 'Memproses akun'),
          FilledButton.icon(
            onPressed: controller.busy
                ? null
                : () => _open(
                    context,
                    _AccountForm(
                      controller: controller,
                      mode: _FormMode.edit,
                      profile: profile,
                    ),
                  ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit profil'),
          ),
          TextButton.icon(
            onPressed: controller.busy ? null : controller.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat ulang profil'),
          ),
          OutlinedButton.icon(
            onPressed: controller.busy
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Keluar dari akun?'),
                        content: const Text(
                          'Kamu dapat masuk kembali kapan saja.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Keluar'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) await controller.logout();
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar dari akun'),
          ),
        ],
      );
    },
  );

  Widget _avatar(ColorScheme colors) => ColoredBox(
    color: colors.secondaryContainer,
    child: Icon(Icons.person_outline, size: 48, color: colors.primary),
  );

  Widget _detail(IconData icon, String title, String value) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(value.isEmpty ? 'Belum diisi' : value),
  );

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

enum _FormMode { login, register, edit }

class _AccountForm extends StatefulWidget {
  const _AccountForm({
    required this.controller,
    required this.mode,
    this.profile,
  });
  final AccountController controller;
  final _FormMode mode;
  final AccountProfile? profile;

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  bool _hidePassword = true;
  String? _error;

  bool get _login => widget.mode == _FormMode.login;
  bool get _edit => widget.mode == _FormMode.edit;
  String get _title => _edit
      ? 'Edit profil'
      : _login
      ? 'Selamat datang'
      : 'Buat akun';

  @override
  void initState() {
    super.initState();
    final initial = widget.profile?.editableFields ?? <String, String>{};
    for (final key in [
      'username',
      'first_name',
      'last_name',
      'email',
      'password1',
      'password2',
      'phone_number',
      'address',
      'avatar_url',
    ]) {
      _fields[key] = TextEditingController(text: initial[key] ?? '');
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final fields = _fields.map(
      (key, value) => MapEntry(
        key,
        key.startsWith('password') ? value.text : value.text.trim(),
      ),
    );
    final controller = widget.controller;
    final result = _edit
        ? await controller.update(fields)
        : _login
        ? await controller.login(fields['username']!, fields['password1']!)
        : await controller.register(fields);
    if (!mounted) return;
    if (result) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _edit
                ? 'Profil berhasil diperbarui.'
                : _login
                ? 'Berhasil masuk. Selamat datang!'
                : 'Akun berhasil dibuat.',
          ),
        ),
      );
    } else {
      setState(() => _error = controller.error);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final busy = widget.controller.busy;
      return PopScope(
        canPop: !busy,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              _edit
                  ? 'Edit profil'
                  : _login
                  ? 'Masuk'
                  : 'Daftar',
            ),
            automaticallyImplyLeading: !busy,
          ),
          body: SafeArea(
            child: _AccountLayout(
              title: _title,
              subtitle: _edit
                  ? 'Lengkapi informasi agar mudah dihubungi.'
                  : _login
                  ? 'Lanjutkan langkah baikmu bersama KelolaKita.'
                  : 'Bergabung untuk berbagi dan menjaga bumi.',
              children: [
                const SizedBox(height: 24),
                AutofillGroup(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_edit)
                          _field(
                            'username',
                            'Nama pengguna',
                            enabled: !busy,
                            autofill: AutofillHints.username,
                            maxLength: 150,
                          ),
                        if (!_login) ...[
                          _field(
                            'first_name',
                            'Nama depan',
                            enabled: !busy,
                            autofill: AutofillHints.givenName,
                            maxLength: 150,
                          ),
                          _field(
                            'last_name',
                            'Nama belakang',
                            enabled: !busy,
                            autofill: AutofillHints.familyName,
                            maxLength: 150,
                          ),
                          _field(
                            'email',
                            'Alamat email',
                            enabled: !busy,
                            keyboard: TextInputType.emailAddress,
                            autofill: AutofillHints.email,
                            maxLength: 254,
                          ),
                        ],
                        if (!_edit) ...[
                          _field(
                            'password1',
                            'Kata sandi',
                            enabled: !busy,
                            password: true,
                            autofill: _login
                                ? AutofillHints.password
                                : AutofillHints.newPassword,
                          ),
                          if (!_login) ...[
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Minimal 8 karakter. Hindari kata sandi umum, angka saja, atau data pribadi.',
                              ),
                            ),
                            _field(
                              'password2',
                              'Konfirmasi kata sandi',
                              enabled: !busy,
                              password: true,
                              autofill: AutofillHints.newPassword,
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Sesi tersimpan di perangkat ini hingga kamu keluar atau sesi berakhir.',
                            ),
                          ),
                        ],
                        if (_edit) ...[
                          Text('Nama pengguna: @${widget.profile!.username}'),
                          const SizedBox(height: 16),
                          _field(
                            'phone_number',
                            'Nomor telepon',
                            enabled: !busy,
                            required: false,
                            keyboard: TextInputType.phone,
                            autofill: AutofillHints.telephoneNumber,
                            maxLength: 20,
                          ),
                          _field(
                            'address',
                            'Alamat utama',
                            enabled: !busy,
                            required: false,
                            lines: 3,
                            autofill: AutofillHints.fullStreetAddress,
                          ),
                          _field(
                            'avatar_url',
                            'URL foto profil',
                            enabled: !busy,
                            required: false,
                            keyboard: TextInputType.url,
                            maxLength: 200,
                          ),
                        ],
                        if (_error != null) _ErrorMessage(_error!),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: busy ? null : _submit,
                          child: busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    semanticsLabel: 'Memproses akun',
                                  ),
                                )
                              : Text(
                                  _edit
                                      ? 'Simpan perubahan'
                                      : _login
                                      ? 'Masuk ke KelolaKita'
                                      : 'Buat akun KelolaKita',
                                ),
                        ),
                        if (!_edit)
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => Navigator.pushReplacement<void, void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _AccountForm(
                                        controller: widget.controller,
                                        mode: _login
                                            ? _FormMode.register
                                            : _FormMode.login,
                                      ),
                                    ),
                                  ),
                            child: Text(
                              _login
                                  ? 'Belum punya akun? Daftar'
                                  : 'Sudah punya akun? Masuk',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _field(
    String key,
    String label, {
    required bool enabled,
    bool required = true,
    bool password = false,
    TextInputType? keyboard,
    String? autofill,
    int? maxLength,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(key),
      controller: _fields[key],
      enabled: enabled,
      obscureText: password && _hidePassword,
      autocorrect: !password,
      enableSuggestions: !password,
      keyboardType: keyboard,
      autofillHints: autofill == null ? null : [autofill],
      textInputAction: lines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      maxLines: lines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: lines > 1,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(context).cardTheme.color,
        suffixIcon: password
            ? IconButton(
                onPressed: enabled
                    ? () => setState(() => _hidePassword = !_hidePassword)
                    : null,
                tooltip: _hidePassword
                    ? 'Tampilkan kata sandi'
                    : 'Sembunyikan kata sandi',
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
      validator: (raw) {
        final value = password ? raw ?? '' : (raw ?? '').trim();
        if (required && value.isEmpty) return '$label wajib diisi.';
        if (key == 'username' &&
            !RegExp(r'^[\p{L}\p{N}@.+_-]+$', unicode: true).hasMatch(value)) {
          return 'Gunakan huruf, angka, atau @ . + - _.';
        }
        if (key == 'email' &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
          return 'Masukkan email yang valid.';
        }
        if (!_login && key == 'password1' && value.length < 8) {
          return 'Kata sandi minimal 8 karakter.';
        }
        if (key == 'password2' && value != _fields['password1']!.text) {
          return 'Konfirmasi kata sandi tidak cocok.';
        }
        if (key == 'avatar_url' && value.isNotEmpty) {
          final uri = Uri.tryParse(value);
          if (uri == null ||
              !uri.hasAuthority ||
              !['http', 'https'].contains(uri.scheme)) {
            return 'Gunakan URL foto HTTP atau HTTPS yang valid.';
          }
        }
        return null;
      },
    ),
  );
}

class _AccountLayout extends StatelessWidget {
  const _AccountLayout({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );
}
