import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/study.dart';

Future<bool> confirmDelete(BuildContext context, String what) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus?'),
      content: Text('Yakin ingin menghapus $what?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
      ],
    ),
  );
  return result ?? false;
}

String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

class _FormScaffold extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSave;
  final List<Widget> children;

  const _FormScaffold({
    required this.title,
    required this.formKey,
    required this.onSave,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [TextButton(onPressed: onSave, child: const Text('Simpan'))],
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final child in children) ...[child, const SizedBox(height: 16)],
          ],
        ),
      ),
    );
  }
}

/// Menulis atau mengedit sejarah / asbabun nuzul sebuah ayat.
/// Mengedit sejarah bawaan akan membuat salinan milik pengguna.
class HistoryForm extends StatefulWidget {
  final int surah;
  final int ayat;
  final AyatHistory? existing;

  const HistoryForm({super.key, required this.surah, required this.ayat, this.existing});

  @override
  State<HistoryForm> createState() => _HistoryFormState();
}

class _HistoryFormState extends State<HistoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _period = TextEditingController(text: widget.existing?.period);
  late final _content = TextEditingController(text: widget.existing?.content);
  late final _sources = TextEditingController(text: widget.existing?.sources);
  late final _from = TextEditingController(text: '${widget.existing?.fromAyat ?? widget.ayat}');
  late final _to = TextEditingController(text: '${widget.existing?.toAyat ?? widget.ayat}');

  @override
  void dispose() {
    for (final c in [_title, _period, _content, _sources, _from, _to]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validateRange(String? _) {
    final from = int.tryParse(_from.text);
    final to = int.tryParse(_to.text);
    if (from == null || to == null) return 'Isi dengan angka';
    if (from > to) return 'Ayat awal harus ≤ ayat akhir';
    if (widget.ayat < from || widget.ayat > to) return 'Rentang harus mencakup ayat ${widget.ayat}';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existing;
    await AppScope.of(context).study.saveHistory(
          AyatHistory(
            surah: widget.surah,
            fromAyat: int.parse(_from.text),
            toAyat: int.parse(_to.text),
            title: _title.text.trim(),
            period: _period.text.trim(),
            content: _content.text.trim(),
            sources: _sources.text.trim(),
            isUser: true,
          ),
          replacing: existing != null && existing.isUser ? existing : null,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: widget.existing == null ? 'Tulis Sejarah' : 'Edit Sejarah',
      formKey: _formKey,
      onSave: _save,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _from,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Dari ayat', prefixText: 'QS ${widget.surah}:'),
                validator: _validateRange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _to,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sampai ayat'),
              ),
            ),
          ],
        ),
        TextFormField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Judul peristiwa', hintText: 'mis. Perpindahan kiblat'),
          validator: _required,
        ),
        TextFormField(
          controller: _period,
          decoration: const InputDecoration(
            labelText: 'Waktu / periode',
            hintText: 'mis. Madaniyah · Tahun ke-2 Hijriyah',
          ),
        ),
        TextFormField(
          controller: _content,
          minLines: 6,
          maxLines: null,
          decoration: const InputDecoration(
            labelText: 'Kisah / asbabun nuzul',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          validator: _required,
        ),
        TextFormField(
          controller: _sources,
          maxLines: null,
          decoration: const InputDecoration(labelText: 'Sumber rujukan', hintText: 'mis. Shahih Al-Bukhari no. 40'),
        ),
      ],
    );
  }
}

/// Menambah atau mengedit hadist yang menjelaskan sebuah ayat.
class HadithForm extends StatefulWidget {
  final int surah;
  final int ayat;
  final Hadith? existing;

  /// Isian awal untuk hadist baru, misalnya dari perpustakaan kitab hadist.
  final Hadith? draft;

  const HadithForm({super.key, required this.surah, required this.ayat, this.existing, this.draft});

  @override
  State<HadithForm> createState() => _HadithFormState();
}

class _HadithFormState extends State<HadithForm> {
  final _formKey = GlobalKey<FormState>();
  late final Hadith? _initial = widget.existing ?? widget.draft;
  late final _arabic = TextEditingController(text: _initial?.arabic);
  late final _translation = TextEditingController(text: _initial?.translation);
  late final _narrator = TextEditingController(text: _initial?.narrator);
  late final _source = TextEditingController(text: _initial?.source);
  late final _explanation = TextEditingController(text: _initial?.explanation);
  late HadithGrade _grade = _initial?.grade ?? HadithGrade.unknown;

  @override
  void dispose() {
    for (final c in [_arabic, _translation, _narrator, _source, _explanation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await AppScope.of(context).study.saveHadith(Hadith(
          id: widget.existing?.id ?? 'user-${DateTime.now().microsecondsSinceEpoch}',
          surah: widget.surah,
          ayat: widget.ayat,
          arabic: _arabic.text.trim(),
          translation: _translation.text.trim(),
          narrator: _narrator.text.trim(),
          source: _source.text.trim(),
          grade: _grade,
          explanation: _explanation.text.trim(),
          isUser: true,
        ));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: '${widget.existing == null ? 'Tambah' : 'Edit'} Hadist · QS ${widget.surah}:${widget.ayat}',
      formKey: _formKey,
      onSave: _save,
      children: [
        TextFormField(
          controller: _source,
          decoration: const InputDecoration(labelText: 'Sumber', hintText: 'mis. HR. Al-Bukhari no. 8'),
          validator: _required,
        ),
        TextFormField(
          controller: _narrator,
          decoration: const InputDecoration(labelText: 'Perawi (sahabat)', hintText: 'mis. Abu Hurairah'),
        ),
        DropdownButtonFormField<HadithGrade>(
          initialValue: _grade,
          decoration: const InputDecoration(labelText: 'Derajat hadist'),
          items: [
            for (final g in HadithGrade.values) DropdownMenuItem(value: g, child: Text(g.label)),
          ],
          onChanged: (g) => setState(() => _grade = g ?? HadithGrade.unknown),
        ),
        TextFormField(
          controller: _arabic,
          maxLines: null,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(labelText: 'Teks Arab (opsional)'),
        ),
        TextFormField(
          controller: _translation,
          minLines: 4,
          maxLines: null,
          decoration: const InputDecoration(
            labelText: 'Terjemahan / isi hadist',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          validator: _required,
        ),
        TextFormField(
          controller: _explanation,
          minLines: 2,
          maxLines: null,
          decoration: const InputDecoration(
            labelText: 'Penjelasan kaitan dengan ayat (opsional)',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

/// Lembar bawah untuk menambah dan menghapus tag pembahasan sebuah ayat.
/// Setiap perubahan langsung disimpan.
Future<void> showTagEditor(BuildContext context, int surah, int ayat) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TagEditor(surah: surah, ayat: ayat),
    );

class _TagEditor extends StatefulWidget {
  final int surah;
  final int ayat;

  const _TagEditor({required this.surah, required this.ayat});

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _add(String raw) async {
    final study = AppScope.of(context).study;
    final tag = study.normalizeTag(raw);
    final current = study.tagsFor(widget.surah, widget.ayat);
    _input.clear();
    if (tag.isEmpty || current.contains(tag)) return;
    await study.setTags(widget.surah, widget.ayat, [...current, tag]);
  }

  Future<void> _remove(String tag) async {
    final study = AppScope.of(context).study;
    await study.setTags(
      widget.surah,
      widget.ayat,
      study.tagsFor(widget.surah, widget.ayat).where((t) => t != tag).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final study = AppScope.of(context).study;
    final current = study.tagsFor(widget.surah, widget.ayat);
    final query = _input.text.trim().toLowerCase();
    final suggestions = study.allTags
        .map((t) => t.$1)
        .where((t) => !current.contains(t) && t.toLowerCase().contains(query))
        .take(20)
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tema QS ${widget.surah}:${widget.ayat}', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Tema menandai pokok bahasan ayat, misalnya Tauhid, Shalat, atau Akhlak. Ayat dengan tema yang sama bisa dipelajari bersama.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (current.isEmpty)
            Text('Belum ada tema.', style: theme.textTheme.bodyMedium)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in current)
                  InputChip(label: Text(tag), onDeleted: () => _remove(tag)),
              ],
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _input,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Tema baru',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: () => _add(_input.text)),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: _add,
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Tema yang sudah ada', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in suggestions)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: Text(tag),
                    onPressed: () => _add(tag),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
