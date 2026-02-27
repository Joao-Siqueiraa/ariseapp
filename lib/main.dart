import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert'; // IMPORTANTE: Para salvar as missões customizadas
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const AriseApp());

class Quest {
  final String name;
  final String description;
  final String statType;
  final double xpReward;
  final List<int> activeDays;
  final String difficulty;

  Quest({
    required this.name,
    required this.description,
    required this.statType,
    required this.xpReward,
    this.activeDays = const [],
    this.difficulty = "EASY",
  });

  // Converte a missão para JSON (Texto) para salvar
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'statType': statType,
    'xpReward': xpReward,
    'activeDays': activeDays,
    'difficulty': difficulty,
  };

  // Recupera a missão do JSON (Texto)
  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
    name: json['name'],
    description: json['description'],
    statType: json['statType'],
    xpReward: json['xpReward'].toDouble(),
    activeDays: List<int>.from(json['activeDays']),
    difficulty: json['difficulty'],
  );
}

class AriseApp extends StatelessWidget {
  const AriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050A10),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF00E5FF),
          error: const Color(0xFFFF3D00),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int level = 1;
  double globalXp = 0.0;
  
  Map<String, int> stats = {"STR": 10, "INT": 10, "VIT": 10, "FOC": 10, "DIS": 10};
  Map<String, double> statsXp = {"STR": 0, "INT": 0, "VIT": 0, "FOC": 0, "DIS": 0};
  
  bool isInPenaltyMode = false;
  List<Quest> dailyQuests = [];
  List<Quest> customQuests = [];
  List<String> completedTodayNames = [];
  final List<String> weekDaysNames = ["SEG", "TER", "QUA", "QUI", "SEX", "SÁB", "DOM"];

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  // --- PERSISTÊNCIA CORRIGIDA ---
  Future<void> _saveGameData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level', level);
    await prefs.setDouble('globalXp', globalXp);
    await prefs.setStringList('completedToday', completedTodayNames);
    await prefs.setString('lastAccess', DateTime.now().toIso8601String());
    await prefs.setBool('penalty', isInPenaltyMode);
    
    // SALVAR MISSÕES CUSTOMIZADAS
    List<String> customQuestsJson = customQuests.map((q) => jsonEncode(q.toJson())).toList();
    await prefs.setStringList('customQuests', customQuestsJson);

    List<String> currentDailiesNames = dailyQuests.map((q) => q.name).toList();
    await prefs.setStringList('currentDailiesNames', currentDailiesNames);

    stats.forEach((key, val) => prefs.setInt('stat_$key', val));
    statsXp.forEach((key, val) => prefs.setDouble('xp_$key', val));
  }

  Future<void> _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      level = prefs.getInt('level') ?? 1;
      globalXp = prefs.getDouble('globalXp') ?? 0.0;
      completedTodayNames = prefs.getStringList('completedToday') ?? [];
      isInPenaltyMode = prefs.getBool('penalty') ?? false;
      
      // CARREGAR MISSÕES CUSTOMIZADAS
      List<String>? customQuestsJson = prefs.getStringList('customQuests');
      if (customQuestsJson != null) {
        customQuests = customQuestsJson.map((q) => Quest.fromJson(jsonDecode(q))).toList();
      }

      stats.keys.forEach((key) {
        stats[key] = prefs.getInt('stat_$key') ?? 10;
        statsXp[key] = prefs.getDouble('xp_$key') ?? 0.0;
      });
    });

    String? lastDateStr = prefs.getString('lastAccess');
    List<String>? savedDailies = prefs.getStringList('currentDailiesNames');
    _handleTimeReset(lastDateStr, savedDailies);
  }

  void _handleTimeReset(String? lastDateStr, List<String>? savedDailies) {
    DateTime now = DateTime.now();
    if (lastDateStr == null) {
      _generateSystemDailies();
      _saveGameData();
      return;
    }
    DateTime lastDate = DateTime.parse(lastDateStr);
    bool isSameDay = now.year == lastDate.year && now.month == lastDate.month && now.day == lastDate.day;
    if (isSameDay) {
      if (savedDailies != null) {
        _restoreSavedDailies(savedDailies);
        setState(() {
          dailyQuests.removeWhere((q) => completedTodayNames.contains(q.name));
        });
      }
    } else {
      if (completedTodayNames.length < 3) { _applyPenalty(); }
      setState(() { completedTodayNames = []; });
      _generateSystemDailies();
      _saveGameData();
    }
  }

  void _applyPenalty() {
    setState(() {
      isInPenaltyMode = true;
      stats.forEach((key, value) { if (value > 5) stats[key] = value - 1; });
    });
  }

  void _generateSystemDailies() {
    final random = Random();
    List<Quest> easyPool = [
      Quest(name: "RESPIRAR CONSCIENTE", description: "5 respirações lentas e controladas.", statType: "FOC", xpReward: 8, difficulty: "EASY"),
      Quest(name: "BEBER ÁGUA", description: "Beba um copo grande de água.", statType: "VIT", xpReward: 5, difficulty: "EASY"),
      Quest(name: "ARRUMAR ESPAÇO", description: "Arrume sua mesa ou cama.", statType: "DIS", xpReward: 10, difficulty: "EASY"),
    ];
    List<Quest> mediumPool = [
      Quest(name: "PLANEJAR O DIA", description: "Anote 3 metas para hoje.", statType: "DIS", xpReward: 20, difficulty: "MEDIUM"),
      Quest(name: "LEITURA LEVE", description: "Leia 5 páginas de um livro.", statType: "INT", xpReward: 15, difficulty: "MEDIUM"),
      Quest(name: "CAMINHADA", description: "Caminhe 10 minutos focado.", statType: "VIT", xpReward: 20, difficulty: "MEDIUM"),
    ];
    List<Quest> hardPool = [
      Quest(name: "DEEP FOCUS", description: "25 min focado sem distrações.", statType: "FOC", xpReward: 50, difficulty: "HARD"),
      Quest(name: "DESAFIO DO SILÊNCIO", description: "15 min sem estímulos externos.", statType: "INT", xpReward: 45, difficulty: "HARD"),
      Quest(name: "ORGANIZAÇÃO GERAL", description: "Organize um ambiente inteiro.", statType: "DIS", xpReward: 55, difficulty: "HARD"),
    ];
    setState(() {
      dailyQuests = [
        easyPool[random.nextInt(easyPool.length)],
        mediumPool[random.nextInt(mediumPool.length)],
        hardPool[random.nextInt(hardPool.length)],
      ];
    });
  }

  void _restoreSavedDailies(List<String> names) {
    List<Quest> allPossible = [
      Quest(name: "RESPIRAR CONSCIENTE", description: "5 respirações lentas e controladas.", statType: "FOC", xpReward: 8, difficulty: "EASY"),
      Quest(name: "BEBER ÁGUA", description: "Beba um copo grande de água.", statType: "VIT", xpReward: 5, difficulty: "EASY"),
      Quest(name: "ARRUMAR ESPAÇO", description: "Arrume sua mesa ou cama.", statType: "DIS", xpReward: 10, difficulty: "EASY"),
      Quest(name: "PLANEJAR O DIA", description: "Anote 3 metas para hoje.", statType: "DIS", xpReward: 20, difficulty: "MEDIUM"),
      Quest(name: "LEITURA LEVE", description: "Leia 5 páginas de um livro.", statType: "INT", xpReward: 15, difficulty: "MEDIUM"),
      Quest(name: "CAMINHADA", description: "Caminhe 10 minutos focado.", statType: "VIT", xpReward: 20, difficulty: "MEDIUM"),
      Quest(name: "DEEP FOCUS", description: "25 min focado sem distrações.", statType: "FOC", xpReward: 50, difficulty: "HARD"),
      Quest(name: "DESAFIO DO SILÊNCIO", description: "15 min sem estímulos externos.", statType: "INT", xpReward: 45, difficulty: "HARD"),
      Quest(name: "ORGANIZAÇÃO GERAL", description: "Organize um ambiente inteiro.", statType: "DIS", xpReward: 55, difficulty: "HARD"),
    ];
    setState(() {
      dailyQuests = allPossible.where((q) => names.contains(q.name)).toList();
    });
  }

  void completeQuest(Quest q, bool isDaily, int index) {
    setState(() {
      globalXp += q.xpReward;
      statsXp[q.statType] = (statsXp[q.statType] ?? 0) + q.xpReward;
      if (statsXp[q.statType]! >= (stats[q.statType]! * 10)) {
        statsXp[q.statType] = 0;
        stats[q.statType] = stats[q.statType]! + 1;
      }
      if (globalXp >= (level * 100)) { globalXp = 0; level++; }
      if (isDaily) {
        completedTodayNames.add(q.name);
        dailyQuests.removeAt(index);
        if (completedTodayNames.length >= 3) isInPenaltyMode = false;
      } else {
        customQuests.remove(q);
      }
      _saveGameData();
    });
  }

  @override
  Widget build(BuildContext context) {
    Color sysColor = isInPenaltyMode ? const Color(0xFFFF3D00) : const Color(0xFF00E5FF);
    return Scaffold(
      body: _currentIndex == 0 ? _buildStatusTab(sysColor) : _buildQuestList(
          _currentIndex == 1 ? "MURAL DE MISSÕES" : "MISSÕES DIÁRIAS", 
          _currentIndex == 1 ? customQuests.where((q) => q.activeDays.contains(DateTime.now().weekday)).toList() : dailyQuests, 
          _currentIndex == 2, sysColor),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF050A10),
        selectedItemColor: sysColor,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "STATUS"),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "MISSÕES"),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber), label: "DIÁRIAS"),
        ],
      ),
      floatingActionButton: _currentIndex == 1 ? FloatingActionButton(backgroundColor: sysColor, onPressed: _showAddQuestDialog, child: const Icon(Icons.add, color: Colors.black)) : null,
    );
  }

  Widget _buildStatusTab(Color sysColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Text("STATUS", style: TextStyle(color: sysColor, letterSpacing: 5, fontWeight: FontWeight.bold)),
          Text("LV. $level", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: (globalXp / (level * 100)).clamp(0, 1), color: sysColor, backgroundColor: Colors.white10, minHeight: 10),
          const SizedBox(height: 40),
          ...stats.keys.map((key) => _statRow(key, stats[key]!, statsXp[key]! / (stats[key]! * 10), _getColor(key))).toList(),
        ],
      ),
    );
  }

  Color _getColor(String k) {
    if (k == "STR") return Colors.redAccent;
    if (k == "FOC") return Colors.cyanAccent;
    if (k == "INT") return Colors.purpleAccent;
    if (k == "VIT") return Colors.greenAccent;
    return Colors.amberAccent;
  }

  Widget _statRow(String label, int val, double prog, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
          Text("$val", style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22))
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(value: prog.clamp(0, 1), color: color, backgroundColor: Colors.white.withOpacity(0.05), minHeight: 6),
        ),
      ]),
    );
  }

  Widget _buildQuestList(String title, List<Quest> quests, bool isDaily, Color sysColor) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: sysColor, letterSpacing: 2)),
          const Divider(color: Colors.white24, height: 40),
          Expanded(
            child: quests.isEmpty 
              ? const Center(child: Text("SISTEMA SINCRONIZADO.", style: TextStyle(color: Colors.white24))) 
              : ListView.builder(
                  itemCount: quests.length,
                  itemBuilder: (context, index) {
                    Color diffCol = quests[index].difficulty == "HARD" ? Colors.redAccent : (quests[index].difficulty == "MEDIUM" ? Colors.orangeAccent : Colors.greenAccent);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B), 
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: sysColor.withOpacity(0.5), width: 1.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        title: Text(quests[index].name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                        subtitle: Text("${quests[index].difficulty} | +${quests[index].statType}", style: TextStyle(color: diffCol, fontSize: 12, fontWeight: FontWeight.bold)),
                        trailing: Icon(Icons.arrow_forward_ios, color: sysColor, size: 18),
                        onTap: () => _showQuestDetail(quests[index], isDaily, index),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  void _showQuestDetail(Quest q, bool isDaily, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D141C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(35),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).primaryColor, width: 3))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor)),
            const SizedBox(height: 20),
            Text(q.description, style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.5)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.black),
                onPressed: () { completeQuest(q, isDaily, index); Navigator.pop(context); },
                child: const Text("Concluído", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddQuestDialog() {
    String name = ""; String stat = "STR"; List<int> selectedDays = [];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF121B26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5))),
          title: Text("NOVA MISSÃO", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (v) => name = v,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Título", labelStyle: TextStyle(color: Colors.white70)),
                ),
                DropdownButtonFormField<String>(
                  value: stat,
                  dropdownColor: const Color(0xFF121B26),
                  items: stats.keys.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (v) => stat = v!,
                  decoration: const InputDecoration(labelText: "Atributo", labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: List.generate(7, (i) {
                    int d = i + 1; bool isSelected = selectedDays.contains(d);
                    return GestureDetector(
                      onTap: () => setDialogState(() => isSelected ? selectedDays.remove(d) : selectedDays.add(d)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.white24),
                        ),
                        child: Text(weekDaysNames[i], style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    );
                  }),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR", style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty && selectedDays.isNotEmpty) {
                  setState(() {
                    customQuests.add(Quest(
                      name: name.toUpperCase(), 
                      description: "MISSÃO AGENDADA.", 
                      statType: stat, 
                      xpReward: 30, 
                      activeDays: List.from(selectedDays), 
                      difficulty: "MEDIUM"
                    ));
                  });
                  _saveGameData(); // Salva IMEDIATAMENTE após criar
                  Navigator.pop(context);
                }
              }, 
              child: const Text("CRIAR")
            )
          ],
        ),
      ),
    );
  }
}