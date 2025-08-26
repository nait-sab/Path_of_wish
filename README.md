# Path of Wish

**Fan game inspiré de *Path of Exile***
- Moteur de jeu : **Godot**
- Projet **amateur et non officiel**
- Aucune affiliation avec Grinding Gear Games ou de la marque *Path of Exile*

---

## À propos

**Type de jeu** : Hack'n'slash en développement (prototype)
Exploration, Collecte d'item, Combat, Inventaire, Mods, Statistiques dynamique et Skills

---

## Version actuelle

- Godot Engine : **v4.4.1**
- Plateformes d’export prises en charge : **Windows** uniquement (export `.exe` + `.pck`)
- Version du jeu : **prototype**, Fonctionnalités à venir ensuite (Loot, Préparation de la map, caméra, skills, Arbre à talent)

---

## Fonctionnalités clés implémentées

- **Système de Stats** via `StatEngine` (joueur) et `StatBlock` (ennemis)
- **Inventaire & Équipements** dynamiques avec Tooltip, Stack, et déplacable au clic
- **Mods** (items & ennemis)
- **Break Bar (PoE 2)** pour les ennemis (état "brisé" temporaire)
- **Armure, Evasion et Bouclier d'énergie** dans le pipeline de dégâts
- **DevTools** intégré pour le debug, spawn enemi, dump stats joueur

---

## Structure du dépôt

- `scenes/` — Scènes de jeu (Player, Enemy, World, UI…)
- `scripts/` — Code GDScript standalone, autoloads, moteur de stats, outils, mods
- `data/` — Fichiers JSON pour items, mods ennemis, etc
- `assets/` — Textures, sons et autres ressources graphiques
- `project.godot` — paramètres du projet

---
