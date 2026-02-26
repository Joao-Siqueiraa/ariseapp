import 'package:flutter/material.dart';

void main() => runApp(const AriseApp());

class Quest {
  final String name;
  final String description;
  final String statType;
  final double xpReward;
  final List<int> activeDays; // 1 = Seg, 7 = Dom. Vazio = Diária do Sistema.

  Quest({
    required this.name,
    required this.description,
    required this.statType,
    required this.xpReward,
    required this.activeDays,
  });
}

class AriseApp extends StatelessWidget {
  const AriseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF050A10)),
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
  
  // STATUS DO HUNTER
  int level = 1;
  double globalXp = 0.0;
  Map<String, int> stats = {"STR": 10, "INT": 10, "VIT": 10, "FOC": 10, "DIS": 10};
  Map<String, double> statsXp = {"STR": 0, "INT": 0, "VIT": 0, "FOC": 0, "DIS": 0};

  bool isInPenaltyMode = false;
  List<Quest> dailyQuests = []; // Geradas pelo sistema
  List<Quest> customQuests = []; // Criadas pelo usuário

  final List<String> weekDaysNames = ["SEG", "TER", "QUA", "QUI", "SEX", "SÁB", "DOM"];

  @override
  void initState() {
    super.initState();
    _generateSystemDailies();
  }

  void _generateSystemDailies() {
    dailyQuests = [
      Quest(name: "HIDRATAÇÃO DO SISTEMA", description: "Beba 500ml de água agora.", statType: "VIT", xpReward: 10, activeDays: []),
      Quest(name: "FOCO INICIAL", description: "5 minutos de meditação ou silêncio.", statType: "FOC", xpReward: 15, activeDays: []),
    ];
  }

  void _applyPenalty() {
    setState(() {
      isInPenaltyMode = true;
      stats.forEach((key, value) { if (value > 5) stats[key] = value - 1; });
      _currentIndex = 2;
    });
  }

  void completeQuest(Quest q, bool isDaily, int index) {
    setState(() {
      if (isInPenaltyMode && !isDaily) return;

      globalXp += q.xpReward * 0.4;
      statsXp[q.statType] = (statsXp[q.statType] ?? 0) + q.xpReward;

      if (statsXp[q.statType]! >= (5 * stats[q.statType]!)) {
        statsXp[q.statType] = 0;
        stats[q.statType] = stats[q.statType]! + 1;
      }

      if (globalXp >= 100) { globalXp = 0; level++; }

      if (isDaily) {
        dailyQuests.removeAt(index);
        if (dailyQuests.isEmpty) isInPenaltyMode = false;
      } else {
        customQuests.removeAt(index); // Aqui removemos da lista original após concluir
      }
    });
  }

  // Filtra as missões customizadas pelo dia atual
  List<Quest> _getVisibleCustomQuests() {
    int today = DateTime.now().weekday;
    return customQuests.where((q) => q.activeDays.contains(today)).toList();
  }

  @override
  Widget build(BuildContext context) {
    Color sysColor = isInPenaltyMode ? Colors.redAccent : const Color(0xFF00E5FF);
    return Scaffold(
      body: _buildBody(sysColor),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF050A10),
        selectedItemColor: sysColor,
        unselectedItemColor: Colors.white24,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "STATUS"),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "MISSÕES"),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber), label: "DIÁRIAS"),
        ],
      ),
      floatingActionButton: _currentIndex == 1 && !isInPenaltyMode
          ? FloatingActionButton(backgroundColor: sysColor, onPressed: _showAddQuestDialog, child: const Icon(Icons.add, color: Colors.black))
          : null,
    );
  }

  Widget _buildBody(Color sysColor) {
    if (_currentIndex == 0) return _buildStatusTab(sysColor);
    if (_currentIndex == 1) return _buildQuestList("MURAL DE MISSÕES", _getVisibleCustomQuests(), false, sysColor);
    return _buildQuestList(isInPenaltyMode ? "ZONA DE PUNIÇÃO" : "DIÁRIO DO SISTEMA", dailyQuests, true, sysColor);
  }

  Widget _buildStatusTab(Color sysColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50),
          Text("HUNTER STATUS", style: TextStyle(color: sysColor, letterSpacing: 5)),
          Text("LV. $level", style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold)),
          LinearProgressIndicator(value: globalXp / 100, color: sysColor, backgroundColor: Colors.white10),
          const SizedBox(height: 30),
          _statRow("FORÇA (STR)", stats["STR"]!, statsXp["STR"]! / (5 * stats["STR"]!), Colors.redAccent),
          _statRow("INTELIGÊNCIA (INT)", stats["INT"]!, statsXp["INT"]! / (5 * stats["INT"]!), Colors.purpleAccent),
          _statRow("VITALIDADE (VIT)", stats["VIT"]!, statsXp["VIT"]! / (5 * stats["VIT"]!), Colors.greenAccent),
          _statRow("FOCO (FOC)", stats["FOC"]!, statsXp["FOC"]! / (5 * stats["FOC"]!), Colors.orangeAccent),
          _statRow("DISCIPLINA (DIS)", stats["DIS"]!, statsXp["DIS"]! / (5 * stats["DIS"]!), Colors.blueAccent),
          Center(child: TextButton(onPressed: _applyPenalty, child: const Text("SIMULAR FALHA", style: TextStyle(color: Colors.white10, fontSize: 10)))),
        ],
      ),
    );
  }

  Widget _statRow(String label, int val, double prog, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 11)), Text("$val", style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: prog.clamp(0.0, 1.0), color: color, backgroundColor: Colors.white10, minHeight: 2),
      ]),
    );
  }

  Widget _buildQuestList(String title, List<Quest> quests, bool isDaily, Color sysColor) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: sysColor)),
          const Divider(color: Colors.white10),
          Expanded(
            child: quests.isEmpty 
              ? const Center(child: Text("SEM MISSÕES ATIVAS", style: TextStyle(color: Colors.white24))) 
              : ListView.builder(
                  itemCount: quests.length,
                  itemBuilder: (context, index) => Card(
                    color: Colors.white.withOpacity(0.05),
                    child: ListTile(
                      title: Text(quests[index].name),
                      trailing: Icon(Icons.info_outline, color: sysColor),
                      onTap: () => _showQuestDetail(quests[index], isDaily, index),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  void _showQuestDetail(Quest q, bool isDaily, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A121A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
            const SizedBox(height: 10),
            Text(q.description, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                onPressed: () { completeQuest(q, isDaily, index); Navigator.pop(context); },
                child: const Text("CONCLUIR MISSÃO"),
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
          backgroundColor: const Color(0xFF0A121A),
          title: const Text("AGENDAR MISSÃO"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(onChanged: (v) => name = v, decoration: const InputDecoration(labelText: "Nome")),
                DropdownButtonFormField<String>(
                  value: stat,
                  items: ["STR", "INT", "VIT", "FOC", "DIS"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => stat = v!,
                ),
                const SizedBox(height: 15),
                const Text("DIAS ATIVOS:", style: TextStyle(fontSize: 10)),
                Wrap(
                  spacing: 5,
                  children: List.generate(7, (i) {
                    int d = i + 1;
                    return FilterChip(
                      label: Text(weekDaysNames[i], style: const TextStyle(fontSize: 10)),
                      selected: selectedDays.contains(d),
                      onSelected: (sel) => setDialogState(() => sel ? selectedDays.add(d) : selectedDays.remove(d)),
                    );
                  }),
                )
              ],
            ),
          ),
          actions: [
            ElevatedButton(onPressed: () {
              if (name.isNotEmpty && selectedDays.isNotEmpty) {
                setState(() => customQuests.add(Quest(name: name.toUpperCase(), description: "Missão Agendada", statType: stat, xpReward: 20, activeDays: List.from(selectedDays))));
                Navigator.pop(context);
              }
            }, child: const Text("CRIAR"))
          ],
        ),
      ),
    );
  }
}