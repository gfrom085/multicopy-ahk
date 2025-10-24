# MultiCopy / Archive

Utilitaire AutoHotkey v2 minimal de "copier cumulatif → coller groupé" avec archivage Markdown.

## Caractéristiques

- **Copier cumulatif** : Accumulez plusieurs sélections avant de coller
- **Archivage automatique** : Toutes les copies sont sauvegardées en Markdown
- **Léger et local** : Aucune dépendance externe, 100% local
- **Windows 10/11** : Compatible avec les versions récentes de Windows
- **UTF-8** : Support complet des caractères Unicode

## Installation

1. Installer [AutoHotkey v2](https://www.autohotkey.com/v2/)
2. Cloner ou télécharger ce dépôt
3. Double-cliquer sur `MultiCopy.ahk` pour lancer le script
4. (Optionnel) Ajouter au démarrage de Windows

## Raccourcis Globaux

| Raccourci | Action | Description |
|-----------|--------|-------------|
| `Ctrl+Alt+C` | Copier cumulatif | Ajoute la sélection au buffer actif |
| `Ctrl+Alt+X` | Couper cumulatif | Ajoute la sélection au buffer puis la supprime |
| `Ctrl+Alt+V` | Coller groupé | Colle tout le buffer et l'archive |
| `Ctrl+Alt+B` | Viewer | Ouvre le gestionnaire d'archives |

## Fonctionnement du Buffer

### Concept "Buffer = Pointeur"

Le buffer actif n'est qu'un **pointeur** (`data/buffer.pointer`) vers le dernier fichier `.md` créé dans `data/archives/`.

### Copier/Couper (`Ctrl+Alt+C` / `Ctrl+Alt+X`)

1. Si `buffer.pointer` n'existe pas → créer un nouveau fichier d'archive `YYYY-MM-DD_HH-MM-SS.md`
2. Écrire son chemin dans `buffer.pointer`
3. Ajouter la sélection (texte brut) à la fin du fichier pointé (séparateur `\n`)

### Coller (`Ctrl+Alt+V`)

**Si buffer existe (pointeur présent)** :
- Lire tout le contenu du fichier pointé
- Le coller à la position du curseur
- Supprimer `buffer.pointer` (le fichier archive reste)

**Si buffer vide (pas de pointeur)** :
- Créer un nouveau fichier d'archive et le coller immédiatement (même si vide)
- Ne pas recréer de pointeur (reste vide)
- La prochaine copie créera un nouveau fichier et deviendra le nouveau buffer

## Viewer d'Archives (`Ctrl+Alt+B`)

### Fenêtre Principale

- Liste défilante de toutes les archives (tableau compact)
- Par archive : nom en gras + 5 lignes représentant la fin de la liste
  - Si ≤ 5 items : afficher ces items + lignes vides (uniformité)
  - Si > 5 items : première ligne = `+N` (N = items non affichés) + 4 derniers items
- Sélection d'une archive → ouvre l'éditeur
- Bouton : **Ouvrir le dossier d'archives** (explorateur)

### Éditeur Léger

Zone de texte multi-ligne avec boutons :

| Bouton | Action |
|--------|--------|
| **Save** | Écrit le contenu dans le fichier ouvert |
| **Copier dans le presse-papiers** | Copie immédiate de tout le contenu |
| **Ajouter au buffer en cours** | Append au fichier pointé par `buffer.pointer` |
| **Nouveau buffer** | Crée un nouveau fichier d'archive vide et le pointe |

## Format d'Archive

- Fichiers `.md` dans `data/archives/`
- Nommés `YYYY-MM-DD_HH-MM-SS.md`
- Encodage UTF-8
- Une entrée par ligne (texte brut)
- Pas de YAML/JSON (version minimaliste)

## Structure du Projet

```
multicopy-ahk/
├── MultiCopy.ahk          # Script principal
├── data/
│   ├── archives/          # Fichiers d'archives .md
│   ├── buffer.pointer     # Pointeur vers l'archive active (généré)
│   └── config.ini         # Configuration
└── README.md
```

## Configuration

Éditer `data/config.ini` pour personnaliser :

- Séparateur entre éléments
- Encodage des fichiers
- Nombre de lignes de prévisualisation dans le viewer

## Tests d'Acceptation

1. `Ctrl+Alt+V` sans buffer → crée une archive et colle (même si vide), pas de pointeur
2. `Ctrl+Alt+C` sur 3 sélections → crée un fichier et ajoute 3 lignes
3. `Ctrl+Alt+V` → colle les 3 lignes et supprime `buffer.pointer` (archive persistante)
4. `Ctrl+Alt+B` → liste toutes les archives avec règle +N et padding à 5 lignes
5. Sélection d'archive → ouvre l'éditeur (Save / Copier / Ajouter / Nouveau)

## Contraintes Techniques

- AutoHotkey v2 uniquement
- Code compact et lisible
- Pas de dépendance réseau
- Gestion d'erreurs minimale
- Messages simples

## Roadmap (Future)

- Hook IA (GPT) post-archivage pour nommage intelligent
- Support JSON structuré pour métadonnées
- Rotation automatique des archives anciennes

## Licence

À définir

## Auteur

Généré avec spécifications détaillées
