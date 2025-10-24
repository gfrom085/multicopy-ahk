# Spécifications Techniques - MultiCopy/Archive

## Vue d'Ensemble

Système de copie cumulative avec archivage automatique basé sur un modèle de **pointeur unique** vers une archive active.

## Architecture du Buffer

### Principe Fondamental

```
Buffer ≠ Fichier temporaire
Buffer = Pointeur vers Archive
```

### Composants

1. **buffer.pointer** (`data/buffer.pointer`)
   - Contient : chemin absolu du fichier d'archive actif
   - Encodage : UTF-8
   - Présence : optionnelle (supprimé après collage)

2. **Archives** (`data/archives/*.md`)
   - Format : `YYYY-MM-DD_HH-MM-SS.md`
   - Contenu : liste d'entrées séparées par `\n`
   - Persistance : permanente (jamais supprimées automatiquement)

## États du Système

### État 1 : Buffer Vide
```
buffer.pointer → N'EXISTE PAS
Action copie → Créer nouvelle archive + pointer
Action colle → Créer archive vide + coller + ne pas pointer
```

### État 2 : Buffer Actif
```
buffer.pointer → EXISTE, pointe vers archive-X.md
Action copie → Append à archive-X.md
Action colle → Lire archive-X.md + coller + supprimer pointeur
```

## Comportements par Opération

### Copier Cumulatif (`Ctrl+Alt+C`)

**Préconditions** :
- Texte sélectionné dans l'application active

**Processus** :
1. Capturer la sélection via clipboard système
2. Attendre disponibilité (ClipWait)
3. Nettoyer format → texte brut
4. Si `buffer.pointer` absent :
   - Créer nouvelle archive `YYYY-MM-DD_HH-MM-SS.md`
   - Écrire chemin dans `buffer.pointer`
5. Append texte brut + `\n` au fichier pointé

**Postconditions** :
- `buffer.pointer` existe
- Archive contient la nouvelle entrée
- Clipboard système intact

### Couper Cumulatif (`Ctrl+Alt+X`)

**Identique à Copier + suppression de la sélection originale**

**Processus supplémentaire** :
- Après capture : envoyer `Delete` ou `Backspace` à l'application

### Coller Groupé (`Ctrl+Alt+V`)

#### Cas 1 : Buffer Actif

**Préconditions** :
- `buffer.pointer` existe

**Processus** :
1. Lire chemin depuis `buffer.pointer`
2. Lire contenu complet du fichier pointé
3. Définir clipboard système = contenu
4. Envoyer `Ctrl+V` à l'application active
5. Supprimer `buffer.pointer` (archive reste)

**Postconditions** :
- Contenu collé dans l'application
- `buffer.pointer` n'existe plus
- Archive préservée dans `data/archives/`

#### Cas 2 : Buffer Vide

**Préconditions** :
- `buffer.pointer` n'existe pas

**Processus** :
1. Créer nouvelle archive vide `YYYY-MM-DD_HH-MM-SS.md`
2. Définir clipboard système = "" (vide)
3. Envoyer `Ctrl+V` à l'application active
4. NE PAS créer `buffer.pointer`

**Postconditions** :
- Rien collé (ou chaîne vide collée)
- `buffer.pointer` reste absent
- Archive vide créée (trace de l'action)

### Viewer (`Ctrl+Alt+B`)

#### Liste d'Archives

**Affichage par archive** :
```
Format : [NomArchive] (gras)
         Ligne 1
         Ligne 2
         Ligne 3
         Ligne 4
         Ligne 5
```

**Règles d'affichage (5 lignes fixes)** :

Si archive contient **≤ 5 items** :
```
Item 1
Item 2
...
[lignes vides pour atteindre 5]
```

Si archive contient **> 5 items** (ex: 12 items) :
```
+7          ← (12 - 5 + 1 = 8 items masqués, affichage "+7")
Item 9
Item 10
Item 11
Item 12
```

**Actions** :
- Clic sur archive → ouvrir éditeur
- Bouton "Ouvrir dossier" → `explorer.exe data\archives\`

#### Éditeur d'Archive

**Composants** :
- Zone texte multi-ligne (tout le contenu)
- Barre de boutons

**Boutons** :

| Bouton | Comportement |
|--------|-------------|
| **Save** | Écrire contenu → fichier ouvert (remplace tout) |
| **Copier** | Clipboard ← contenu complet |
| **Ajouter au buffer** | Append contenu → fichier pointé par `buffer.pointer`<br>Si pointeur absent → créer nouvelle archive + pointer |
| **Nouveau buffer** | Créer archive vide `YYYY-MM-DD_HH-MM-SS.md`<br>`buffer.pointer` ← nouveau chemin |

## Gestion d'Erreurs

### Erreurs Gérées

1. **Clipboard indisponible** :
   - Message : "Clipboard inaccessible, réessayez"
   - Action : Abandonner l'opération

2. **Fichier pointé introuvable** :
   - Si `buffer.pointer` pointe vers fichier supprimé
   - Action : Supprimer `buffer.pointer`, traiter comme buffer vide

3. **Erreur d'écriture** :
   - Permissions insuffisantes
   - Message : "Impossible d'écrire dans data/archives/"
   - Action : Abandonner

4. **Archive corrompue** :
   - Encodage invalide
   - Message : "Archive corrompue : [nom]"
   - Action : Ignorer dans le viewer

## Format de Données

### buffer.pointer
```
C:\chemin\absolu\vers\data\archives\2025-01-07_14-30-45.md
```

### Archive .md
```
Première entrée de texte
Deuxième entrée de texte
Troisième entrée
...
```

**Contraintes** :
- Encodage : UTF-8 BOM optionnel
- Séparateur : `\n` (LF ou CRLF)
- Pas de métadonnées (v1)

## Contraintes de Performance

- Temps de copie/colle : < 100ms
- Temps d'ouverture viewer : < 500ms
- Taille maximale de buffer : illimitée (pratiquement ~10MB)
- Nombre d'archives : illimité

## Tests de Non-Régression

### Test 1 : Cycle Complet Standard
```
1. Buffer vide
2. Copier "A" → buffer créé, archive-1.md = "A\n"
3. Copier "B" → archive-1.md = "A\nB\n"
4. Coller → affiche "A\nB", buffer vide, archive-1.md reste
```

### Test 2 : Collage Sans Buffer
```
1. Buffer vide
2. Coller → archive-2.md créée vide, rien collé, buffer reste vide
```

### Test 3 : Nouveau Buffer Depuis Éditeur
```
1. Buffer vide
2. Ouvrir viewer → archive-3.md (ancienne)
3. Bouton "Nouveau buffer" → archive-4.md créée, pointeur mis à jour
4. Copier "X" → archive-4.md = "X\n"
```

### Test 4 : Ajouter Archive au Buffer
```
1. Buffer actif pointe archive-5.md ("A\n")
2. Ouvrir archive-6.md ("B\nC\n") dans éditeur
3. Bouton "Ajouter au buffer" → archive-5.md = "A\nB\nC\n"
4. Pointeur reste sur archive-5.md
```

## Sécurité

- Pas de validation de contenu (accepte tout texte)
- Pas de limite de taille individuelle d'entrée
- Pas de chiffrement (stockage en clair)
- Pas d'authentification (utilitaire local)

## Évolutions Futures (Hors Scope v1)

- Hook GPT pour nommage intelligent des archives
- Métadonnées JSON (timestamp, source app, tags)
- Rotation automatique (archive archives > 30 jours)
- Recherche full-text dans archives
- Export multi-format (JSON, CSV, HTML)

## Glossaire

| Terme | Définition |
|-------|------------|
| **Buffer** | Pointeur logique vers l'archive active |
| **Archive** | Fichier .md persistant dans `data/archives/` |
| **Pointeur** | Fichier `buffer.pointer` contenant un chemin |
| **Entrée** | Ligne de texte dans une archive |
| **Viewer** | Interface graphique de gestion des archives |
