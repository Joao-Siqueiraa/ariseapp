import 'dart:math';

class HunterSystem {
  int level = 1;
  double xp = 0;
  
  // Atributos Solo Leveling
  int str = 10; // Força
  int intl = 10; // Inteligência
  int vit = 10; // Vitalidade

  // O XP necessário segue uma curva: cada nível fica 20% mais difícil
  double get nextLevelXp => 100 * pow(1.2, level - 1);

  void gainXp(double amount, String statTarget) {
    xp += amount;
    
    // Evolui o atributo específico da missão
    if (statTarget == 'STR') str++;
    if (statTarget == 'INT') intl++;
    if (statTarget == 'VIT') vit++;

    // Lógica de Level Up
    while (xp >= nextLevelXp) {
      xp -= nextLevelXp;
      level++;
      print("!!! LEVEL UP: Hunter agora é Nível $level !!!");
    }
  }
}