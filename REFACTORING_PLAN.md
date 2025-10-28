# 📋 Plan de Refactorisation - MultiCopy.ahk

## 🎯 Objectifs
Nettoyer et améliorer la qualité du code tout en conservant les fonctionnalités critiques.

## 📊 Analyse du Code Actuel
- **Taille**: 786 lignes, 25 fonctions
- **Modifications prévues**: ~40 lignes impactées
- **Complexité**: Faible (refactoring sûr)

---

## 🔄 Phase 1: Nettoyage TrayTip DEBUG (9 suppressions)

**Retirer les TrayTip de debug:**
- L167: "Paste depuis buffer: ..."
- L183: "GroupPaste: Création nouveau buffer..."
- L234: "GetBufferPath: buffer.pointer n'existe pas"
- L242: "GetBufferPath: ..."
- L246: "GetBufferPath: Erreur lecture"
- L282: "Buffer pointer écrit: ..."
- L321: "Nouveau buffer créé: ..."
- L355: "AppendToBuffer: Pas de buffer, création..."
- L366: "AppendToBuffer: Archive n'existe pas, recréation..."

**✅ GARDER (comme demandé):**
- L143: TrayTip "Copie ajoutée au buffer" → **notification critique**
- L785: TrayTip démarrage script → **info utilisateur**
- Tous les `LogWrite()` → **fichier logs/session_*.log conservé**

---

## 🔔 Phase 2: Convertir MsgBox GUI → TrayTip (3 conversions)

**Rendre les confirmations GUI moins intrusives:**
- L697: `MsgBox("Archive sauvegardée", "Succès", "T1")` → `TrayTip("Succès", "Archive sauvegardée", 1)`
- L708: `MsgBox("Contenu copié...", "Succès", "T1")` → `TrayTip("Succès", "Contenu copié", 1)`
- L724: `MsgBox("Contenu ajouté...", "Succès", "T1")` → `TrayTip("Succès", "Contenu ajouté au buffer", 1)`

**❌ GARDER MsgBox pour:**
- Erreurs critiques (création archive, écriture fichier, etc.)
- Validations utilisateur (sélection vide, aucune archive, etc.)

---

## 📝 Phase 3: Convertir OutputDebug → LogWrite (3 conversions)

**Utiliser LogWrite pour traçabilité:**
```ahk
; L196 - Avant:
OutputDebug("Avertissement: Impossible de créer archive vide - " . err.Message)
; Après:
LogWrite("Impossible de créer archive vide - " . err.Message, "WARN")

; L266 - Avant:
OutputDebug("Avertissement: Impossible de supprimer buffer.pointer après 3 essais")
; Après:
LogWrite("Impossible de supprimer buffer.pointer après 3 essais", "WARN")

; L395 - Avant:
OutputDebug("Avertissement: Impossible de supprimer buffer.pointer - " . err.Message)
; Après:
LogWrite("Impossible de supprimer buffer.pointer - " . err.Message, "WARN")
```

---

## 🔧 Phase 4: Extraire Constantes Magiques

**Créer section après ligne 24:**
```ahk
; ==============================================================================
; CONSTANTES GUI
; ==============================================================================

; Dimensions ListView
global GUI_COLUMN_WIDTH_ARCHIVE := 180
global GUI_COLUMN_WIDTH_LINE := 132
global GUI_LISTVIEW_HEIGHT := 400
global GUI_WINDOW_WIDTH := 860
global GUI_WINDOW_HEIGHT := 480

; Dimensions Éditeur
global GUI_EDITOR_WIDTH := 600
global GUI_EDITOR_HEIGHT := 470

; Timeouts et Retry
global CLIPBOARD_TIMEOUT := 1        ; secondes
global FILE_DELETE_RETRY := 3
global FILE_DELETE_WAIT := 50        ; millisecondes
```

**Remplacements dans le code:**
- L120: `ClipWait(1)` → `ClipWait(CLIPBOARD_TIMEOUT)`
- L257: `loop 3` → `loop FILE_DELETE_RETRY`
- L268: `Sleep(50)` → `Sleep(FILE_DELETE_WAIT)`
- L526-534: Largeurs colonnes → constantes
- L576: Dimensions fenêtre → constantes
- L682: Dimensions éditeur → constantes

---

## 🏷️ Phase 5: Améliorer Nommage Variables (4 renommages)

**Variables GUI plus explicites:**

| Avant | Après | Occurrences |
|-------|-------|-------------|
| `lv` | `archiveListView` | 8 fois (CreateViewerGUI, EditSelectedArchive, RefreshViewer) |
| `editControl` | `contentEdit` | 6 fois (CreateEditorGUI + callbacks) |
| `viewerGui` | `viewerWindow` | 6 fois |
| `editorGui` | `editorWindow` | 5 fois |

---

## ♻️ Phase 6: Déduplication RefreshViewer (nouvelle fonction)

**Problème:** RefreshViewer() duplique 15 lignes de CreateViewerGUI()

**Solution:** Extraire fonction `PopulateArchiveListView(listView)`

```ahk
/**
 * Remplit un ListView avec toutes les archives
 * @param {ListView} listView ListView à remplir
 */
PopulateArchiveListView(listView) {
    archives := GetAllArchives()
    for archivePath in archives {
        SplitPath(archivePath, &fileName)
        lines := GetLastLines(archivePath, 5)

        l1 := lines.Length >= 1 ? lines[1] : ""
        l2 := lines.Length >= 2 ? lines[2] : ""
        l3 := lines.Length >= 3 ? lines[3] : ""
        l4 := lines.Length >= 4 ? lines[4] : ""
        l5 := lines.Length >= 5 ? lines[5] : ""

        listView.Add("", fileName, l1, l2, l3, l4, l5)
    }
}
```

**Utilisation:**
- L536-554 dans `CreateViewerGUI()` → `PopulateArchiveListView(archiveListView)`
- L614-631 dans `RefreshViewer()` → `archiveListView.Delete()` puis `PopulateArchiveListView(archiveListView)`

---

## ✅ Phase 7: Tests de Validation

**Scénarios à tester:**
1. ✅ Copier cumulatif → TrayTip "Copie ajoutée" s'affiche
2. ✅ Coller groupé → fonctionne correctement
3. ✅ Viewer → affichage correct des archives
4. ✅ Éditeur Save → TrayTip "Archive sauvegardée" (au lieu de MsgBox)
5. ✅ Éditeur Copier → TrayTip "Contenu copié" (au lieu de MsgBox)
6. ✅ Éditeur Ajouter → TrayTip "Contenu ajouté" (au lieu de MsgBox)
7. ✅ Fichier log → contient tous les LogWrite (y compris nouveaux WARN)

---

## 📈 Résumé des Modifications

| Type | Nombre | Impact |
|------|--------|--------|
| TrayTip supprimés | 9 | Code plus propre |
| MsgBox → TrayTip | 3 | GUI moins intrusive |
| OutputDebug → LogWrite | 3 | Meilleure traçabilité |
| Constantes extraites | 10 | Maintenabilité |
| Variables renommées | 4 | Lisibilité |
| Fonctions créées | 1 | Déduplication |
| **Total lignes modifiées** | **~40** | **Sur 786 lignes** |

---

## ⚠️ Risques & Mitigations

| Risque | Probabilité | Mitigation |
|--------|-------------|------------|
| Casse de notification copie | Faible | Tests manuels Phase 7 |
| Régression GUI | Très faible | Changements cosmétiques uniquement |
| Perte de logs | Très faible | OutputDebug → LogWrite conserve info |

---

*Plan créé le 2025-10-28*
*Branche: refactor/code-cleanup*
