# Guide de Test - GUI MultiCopy

## Prérequis
- Windows 10/11
- AutoHotkey v2 installé
- Lancer MultiCopy.ahk

## Test T4: Viewer d'Archives (Ctrl+Alt+B)

### Étapes de test

1. **Préparer des archives de test**:
   - Copier 3 textes avec Ctrl+Alt+C pour créer une archive
   - Coller avec Ctrl+Alt+V pour archiver
   - Répéter 2-3 fois pour avoir plusieurs archives

2. **Ouvrir le viewer**:
   - Appuyer sur `Ctrl+Alt+B`
   - Vérifier l'apparition de la fenêtre "MultiCopy - Viewer d'Archives"

3. **Vérifier le ListView 6 colonnes**:
   - Colonne 1: Nom du fichier (YYYY-MM-DD_HH-MM-SS.md)
   - Colonnes 2-6 (L1-L5): Preview des 5 dernières lignes

4. **Vérifier les cas de preview**:
   - Archive avec ≤5 items: Affiche tous + lignes vides (padding)
   - Archive avec >5 items: Affiche "+N" en L1 + 4 dernières lignes

5. **Tester les boutons**:
   - **Ouvrir dossier**: Ouvre explorer dans data/archives/
   - **Éditer sélection**: Sélectionner une archive → clic → ouvre éditeur
   - **Éditer buffer actif**: Ouvre l'éditeur du buffer actuel
   - **Rafraîchir**: Recharge la liste après nouvelles copies
   - **Fermer**: Ferme le viewer

6. **Tester le double-clic**:
   - Double-cliquer sur une archive
   - Vérifier ouverture de l'éditeur

### Résultats attendus

✅ ListView affiche toutes les archives triées (plus récent en premier)
✅ Colonnes L1-L5 contiennent exactement 5 éléments par archive
✅ Règle +N fonctionne (ex: 12 items → "+8" en L1)
✅ Padding avec lignes vides pour archives <5 items
✅ Double-clic ouvre l'éditeur
✅ Tous les boutons fonctionnent

## Test T5: Éditeur d'Archive

### Étapes de test

1. **Ouvrir l'éditeur depuis le viewer**:
   - Dans le viewer, sélectionner une archive
   - Cliquer "Éditer sélection" ou double-cliquer
   - Vérifier titre fenêtre: "Éditeur - YYYY-MM-DD_HH-MM-SS.md"

2. **Vérifier le contenu**:
   - Zone de texte affiche le contenu complet de l'archive
   - Texte éditable (essayer de modifier)

3. **Tester bouton "Save"**:
   - Modifier le texte
   - Cliquer "Save"
   - Vérifier message "Archive sauvegardée"
   - Rouvrir → vérifier modifications sauvées

4. **Tester bouton "Copier presse-papiers"**:
   - Cliquer le bouton
   - Vérifier message "Contenu copié"
   - Coller dans Notepad → vérifier contenu

5. **Tester bouton "Ajouter au buffer"**:
   - Cliquer le bouton
   - Vérifier message "Contenu ajouté au buffer actif"
   - Faire Ctrl+Alt+V ailleurs → vérifier collage du buffer enrichi

6. **Tester bouton "Nouveau buffer"**:
   - Modifier le texte dans l'éditeur
   - Cliquer "Nouveau buffer"
   - Vérifier message avec nom du nouveau fichier
   - Vérifier dans data/archives/ qu'un nouveau fichier existe
   - Vérifier que buffer.pointer pointe vers ce nouveau fichier

### Cas spéciaux

1. **Éditer buffer actif**:
   - Depuis viewer, cliquer "Éditer buffer actif"
   - Si buffer existe → ouvre éditeur avec contenu actuel
   - Si pas de buffer → message "Aucun buffer actif"

2. **Archive vide**:
   - Créer archive vide (Ctrl+Alt+V sans buffer)
   - Éditer cette archive
   - Zone texte doit être vide
   - Save doit fonctionner même avec contenu vide

3. **Contenu multi-ligne**:
   - Copier texte avec plusieurs lignes depuis Notepad
   - Ctrl+Alt+C
   - Ouvrir viewer → éditer
   - Vérifier que les sauts de ligne sont préservés

## Checklist Globale GUI

### Viewer (CreateViewerGUI)
- [ ] Fenêtre s'ouvre avec Ctrl+Alt+B
- [ ] ListView 6 colonnes visible
- [ ] Archives triées par date décroissante
- [ ] Preview 5 lignes par archive
- [ ] Règle +N fonctionne (>5 items)
- [ ] Padding lignes vides (≤5 items)
- [ ] Double-clic → ouvre éditeur
- [ ] Bouton "Ouvrir dossier" → explorer
- [ ] Bouton "Éditer sélection" → éditeur
- [ ] Bouton "Éditer buffer actif" → éditeur
- [ ] Bouton "Rafraîchir" → recharge liste
- [ ] Bouton "Fermer" → ferme fenêtre

### Éditeur (CreateEditorGUI)
- [ ] Fenêtre s'ouvre depuis viewer
- [ ] Titre affiche nom du fichier
- [ ] Zone texte affiche contenu
- [ ] Zone texte éditable
- [ ] Bouton "Save" → sauvegarde
- [ ] Bouton "Copier presse-papiers" → copie
- [ ] Bouton "Ajouter au buffer" → append
- [ ] Bouton "Nouveau buffer" → crée + pointe
- [ ] Bouton "Fermer" → ferme fenêtre

## Problèmes Connus / Limitations

1. **Pas de formatage gras**: ListView AHK v2 ne supporte pas le formatage par cellule
2. **Largeurs fixes**: Les colonnes ont des largeurs prédéfinies (pas auto-resize)
3. **Messages temporaires**: MsgBox avec timeout T1/T1.5 (disparaissent vite)
4. **Pas de confirmation**: Save écrase sans demander
5. **Encodage**: Toujours UTF-8, pas configurable dans GUI

## Tests de Performance

- Ouvrir viewer avec 50+ archives → doit rester fluide
- Éditer archive de 100+ lignes → doit charger rapidement
- Rafraîchir après 10 nouvelles archives → <1s

## Rapport de Bug

Si un problème est trouvé:
1. Noter l'action exacte qui cause le problème
2. Copier le message d'erreur exact
3. Vérifier OutputDebug ou Event Viewer Windows
4. Documenter dans BUGS_FOUND.md