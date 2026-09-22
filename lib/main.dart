import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(const DreamWeaverApp());
}

class DreamWeaverApp extends StatelessWidget {
  const DreamWeaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.kuraleTextTheme(ThemeData.dark().textTheme),
      ),
      home: const DreamEntryScreen(),
    );
  }
}

// ---------------------------------------------------------
// ЭКРАН ЗАПИСИ СНА
// ---------------------------------------------------------
class DreamEntryScreen extends StatefulWidget {
  const DreamEntryScreen({super.key});

  @override
  State<DreamEntryScreen> createState() => _DreamEntryScreenState();
}

class _DreamEntryScreenState extends State<DreamEntryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _saveDream() async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сон не может быть абсолютно пустым...'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedDreams = prefs.getStringList('dreams') ?? [];

      final timestamp = DateTime.now().toString().split('.')[0];
      final title = _titleController.text.isNotEmpty
          ? _titleController.text
          : "Безымянный сон";
      final content = _contentController.text;
      final image = _imagePath ?? "";

      final dreamData = "$title分裂$timestamp分裂$content分裂$image";
      savedDreams.insert(0, dreamData);
      await prefs.setStringList('dreams', savedDreams);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сон успешно сохранен в архив!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _titleController.clear();
        _contentController.clear();
        _imagePath = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ЗАМЕНА: Иконка меню на текстовый символ ≡
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Text('≡',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('DREAM WEAVER',
            style: TextStyle(color: Colors.grey, letterSpacing: 3)),
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Название сна...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _contentController,
              maxLines: 8,
              style: const TextStyle(color: Colors.white, height: 1.5),
              decoration: InputDecoration(
                hintText:
                    'Что вам приснилось?\nОпишите детали, эмоции, цвета...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[800]!)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 20),
            if (_imagePath != null) ...[
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(_imagePath!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover)
                        : Image.file(File(_imagePath!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover),
                  ),
                  // ЗАМЕНА: Иконка закрытия на ✕
                  IconButton(
                    icon: const Text('✕',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    style:
                        IconButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: () => setState(() => _imagePath = null),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _pickImage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.grey),
                  foregroundColor: Colors.grey,
                ),
                // ЗАМЕНА: Иконка камеры на 📷
                icon: const Text('📷', style: TextStyle(fontSize: 18)),
                label: const Text('ПРИКРЕПИТЬ ОБРАЗ ИЗ СНА'),
              ),
              const SizedBox(height: 20),
            ],
            ElevatedButton.icon(
              onPressed: _saveDream,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
              ),
              // ЗАМЕНА: Иконка сохранения на 💾
              icon: const Text('💾', style: TextStyle(fontSize: 18)),
              label: const Text('СОХРАНИТЬ В АРХИВ',
                  style: TextStyle(letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// БОКОВОЕ МЕНЮ (DRAWER)
// ---------------------------------------------------------
class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  Future<void> _launchPrivacyPolicy() async {
    final Uri url =
        Uri.parse('https://sites.google.com/view/dreamweaver-privacy-policy');
    if (!await launchUrl(url)) throw Exception('Could not launch $url');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.black,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5))),
              child: Center(
                child: Text('DREAM WEAVER',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 2,
                        fontFamily: GoogleFonts.kurale().fontFamily)),
              ),
            ),
            ListTile(
              leading: const Text('✏️',
                  style: TextStyle(color: Colors.grey, fontSize: 24)),
              title:
                  const Text('Дневник', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DreamEntryScreen()));
              },
            ),
            ListTile(
              leading: const Text('🗄',
                  style: TextStyle(color: Colors.grey, fontSize: 24)),
              title: const Text('Архив снов',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SavedDreamsScreen()));
              },
            ),
            ListTile(
              leading: const Text('🌑',
                  style: TextStyle(color: Colors.grey, fontSize: 24)),
              title:
                  const Text('Сонариум', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SonariumScreen()));
              },
            ),
            ListTile(
              leading: const Text('🛡',
                  style: TextStyle(color: Colors.grey, fontSize: 24)),
              title: const Text('Конфиденциальность',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _launchPrivacyPolicy();
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Text('✕',
                  style: TextStyle(color: Colors.grey, fontSize: 24)),
              title: const Text('Выход', style: TextStyle(color: Colors.white)),
              onTap: () => SystemNavigator.pop(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// АРХИВ СНОВ
// ---------------------------------------------------------
class SavedDreamsScreen extends StatefulWidget {
  const SavedDreamsScreen({super.key});

  @override
  State<SavedDreamsScreen> createState() => _SavedDreamsScreenState();
}

class _SavedDreamsScreenState extends State<SavedDreamsScreen> {
  List<String> _savedDreams = [];

  @override
  void initState() {
    super.initState();
    _loadDreams();
  }

  Future<void> _loadDreams() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _savedDreams = prefs.getStringList('dreams') ?? []);
  }

  Future<void> _deleteDream(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _savedDreams.removeAt(index));
    await prefs.setStringList('dreams', _savedDreams);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Text('≡',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('АРХИВ СНОВ',
            style: TextStyle(color: Colors.grey, letterSpacing: 2)),
        backgroundColor: Colors.black,
      ),
      drawer: const MainDrawer(),
      body: _savedDreams.isEmpty
          ? const Center(
              child: Text('В архиве пока нет записей...',
                  style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: _savedDreams.length,
              itemBuilder: (context, index) {
                final parts = _savedDreams[index].split('分裂');
                final title = parts[0];
                final date = parts.length > 1 ? parts[1] : '';
                final content = parts.length > 2 ? parts[2] : '';
                final imagePath = parts.length > 3 ? parts[3] : '';

                return Card(
                  color: Colors.grey[900],
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.grey,
                    title: Text(title,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(date,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    children: [
                      if (imagePath.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: kIsWeb
                              ? Image.network(imagePath, fit: BoxFit.cover)
                              : Image.file(File(imagePath), fit: BoxFit.cover),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(content,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14, height: 1.5)),
                      ),
                      TextButton.icon(
                        onPressed: () => _deleteDream(index),
                        // ЗАМЕНА: Иконка удаления на 🗑
                        icon: const Text('🗑',
                            style: TextStyle(
                                color: Colors.redAccent, fontSize: 18)),
                        label: const Text('Удалить сон',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------
// СОНАРИУМ (ВСЕ ФАКТЫ ВОССТАНОВЛЕНЫ)
// ---------------------------------------------------------
class SonariumScreen extends StatelessWidget {
  const SonariumScreen({super.key});

  final String introText =
      "Сон — это естественное состояние организма, при котором снижается внешняя активность, но мозг продолжает работать, обрабатывая информацию и восстанавливая внутренние системы. Он необходим человеку для физического и психического восстановления: во время сна укрепляется иммунитет, регулируются гормоны, восстанавливаются ткани, а также улучшаются память, внимание и эмоциональное состояние. Без достаточного и качественного сна организм постепенно истощается, что негативно влияет на здоровье, работоспособность и общее самочувствие. Автор Dream Weaver: vk.com/nisarium";

  final List<String> sleepFacts = const [
    "Сон — это естественное физиологическое состояние, при котором снижается активность мозга и реакция на окружающий мир.",
    "В среднем человеку требуется от 7 до 9 часов сна в сутки для нормального функционирования.",
    "Сон делится на две основные фазы: быстрый (REM) и медленный (non-REM).",
    "Во время REM-фазы чаще всего происходят яркие сновидения.",
    "Мозг во сне остаётся активным и обрабатывает информацию, полученную за день.",
    "Недостаток сна ухудшает память, внимание и способность принимать решения.",
    "Хроническое недосыпание связано с повышенным риском сердечно-сосудистых заболеваний.",
    "Во время сна организм восстанавливает ткани и укрепляет иммунную систему.",
    "Температура тела немного снижается, когда человек засыпает.",
    "Сон помогает регулировать гормоны, включая гормон роста и кортизол.",
    "Люди могут видеть до нескольких снов за ночь, но не всегда их запоминают.",
    "Слепые люди тоже видят сны, но они чаще основаны на звуках и ощущениях.",
    "Некоторые животные могут спать только половиной мозга, например дельфины.",
    "Сонный паралич — это состояние, при котором человек просыпается, но не может двигаться.",
    "Качество сна важнее его количества — даже 8 часов могут не помочь, если сон прерывистый.",
    "Свет от экранов перед сном может нарушать выработку мелатонина.",
    "Мелатонин — гормон, который регулирует цикл сна и бодрствования.",
    "Алкоголь может ускорить засыпание, но ухудшает качество сна.",
    "Кофеин может оставаться в организме до 6–8 часов, влияя на засыпание.",
    "Сновидения могут отражать эмоции, стресс и переживания человека.",
    "Лунатизм чаще встречается у детей, чем у взрослых.",
    "Сон помогает «очищать» мозг от токсинов, накопленных за день.",
    "Люди, работающие в ночные смены, чаще страдают от нарушений сна.",
    "Недостаток сна может привести к набору веса из-за изменения гормонов аппетита.",
    "Во сне снижается частота сердечных сокращений и дыхания.",
    "Короткий дневной сон (20–30 минут) может улучшить продуктивность.",
    "Слишком долгий сон тоже может быть вреден для здоровья.",
    "Сны могут быть как логичными, так и абсолютно абсурдными из-за особенностей работы мозга.",
    "Стресс и тревога — одни из главных причин бессонницы.",
    "Регулярный режим сна (ложиться и вставать в одно время) улучшает общее самочувствие.",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Text('≡',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('СОНАРИУМ',
            style: TextStyle(color: Colors.grey, letterSpacing: 3)),
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      drawer: const MainDrawer(),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sleepFacts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(introText,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.justify),
            );
          }
          final factIndex = index - 1;
          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[800]!, width: 0.5)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ЗАМЕНА: Иконка луны на ☾
                  const Text('☾',
                      style: TextStyle(color: Colors.grey, fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(sleepFacts[factIndex],
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 15, height: 1.5)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
