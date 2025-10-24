# Bugs Identifiés - Analyse de Code

## BUG CRITIQUE #1: LoadConfig() - Logique unescape incorrecte

**Localisation**: `MultiCopy.ahk:77`

**Code actuel**:
```ahk
global SEPARATOR := (sep = "\n") ? "`n" : "`n"  ; v1: toujours LF
```

**Problème**: Les deux branches du ternaire retournent la même valeur (`n`).

**Impact**: SEPARATOR sera toujours `n` (LF), ce qui est correct par hasard, mais la logique est fausse.

**Test nécessaire**: Vérifier comment IniRead() lit la valeur littérale `\n` du fichier INI:
- Si IniRead retourne `"\n"` (2 caractères: backslash + n) → comparaison `sep = "\n"` serait vraie
- Si IniRead retourne `"\\n"` (échappé) → comparaison serait fausse

**Solution potentielle**:
```ahk
; Option 1: Si IniRead retourne littéralement les 2 caractères
sep := IniRead(CONFIG_FILE, "MultiCopy", "Separator", "`n")
if (StrLen(sep) = 2 && SubStr(sep, 1, 1) = "\" && SubStr(sep, 2, 1) = "n") {
    global SEPARATOR := "`n"
} else if (sep = "`n") {
    global SEPARATOR := "`n"
} else {
    global SEPARATOR := "`n"  ; Fallback
}

; Option 2: Plus simple - toujours utiliser LF
global SEPARATOR := "`n"  ; Ignorer config pour v1
```

**Recommandation**: Utiliser Option 2 (coder en dur) pour v1, documenter que config.ini ne supporte que `\n`.

---

## BUG POTENTIEL #2: DeleteBufferPointer() - Pas de gestion d'erreur

**Localisation**: `MultiCopy.ahk:274-280`

**Code actuel**:
```ahk
DeleteBufferPointer() {
    try {
        if FileExist(BUFFER_POINTER) {
            FileDelete(BUFFER_POINTER)
        }
    }
}
```

**Problème**: Le `try` n'a pas de `catch`, donc les erreurs sont ignorées silencieusement.

**Impact**: Moyen - Si FileDelete échoue (permissions), le pointeur reste et cause un état incohérent.

**Solution**:
```ahk
DeleteBufferPointer() {
    try {
        if FileExist(BUFFER_POINTER) {
            FileDelete(BUFFER_POINTER)
        }
    } catch as err {
        ; Optionnel: log erreur
        OutputDebug("Avertissement: Impossible de supprimer buffer.pointer - " . err.Message)
    }
}
```

---

## BUG POTENTIEL #3: GetLastLines() - Mauvais calcul startIndex

**Localisation**: `MultiCopy.ahk:379-382`

**Code actuel**:
```ahk
startIndex := total - count + 2
loop count - 1 {
    result.Push(lines[startIndex + A_Index - 1])
}
```

**Test manuel** (12 items, count=5):
- hidden = 12 - 5 + 1 = 8 ✓
- startIndex = 12 - 5 + 2 = 9 ✓
- Loop 4 fois (count - 1 = 5 - 1 = 4):
  - A_Index=1: lines[9 + 1 - 1] = lines[9] → "Item 9" ✓
  - A_Index=2: lines[9 + 2 - 1] = lines[10] → "Item 10" ✓
  - A_Index=3: lines[9 + 3 - 1] = lines[11] → "Item 11" ✓
  - A_Index=4: lines[9 + 4 - 1] = lines[12] → "Item 12" ✓

Résultat: `["+8", "Item 9", "Item 10", "Item 11", "Item 12"]` ✓

**Conclusion**: Logique correcte, pas de bug.

---

## BUG POTENTIEL #4: GroupPaste() cas buffer vide - Pas de gestion d'erreur

**Localisation**: `MultiCopy.ahk:147-149`

**Code actuel**:
```ahk
try {
    FileAppend("", archivePath, ENCODING)
}
```

**Problème**: Pas de `catch`, si erreur → clipboard reste vide mais script continue.

**Impact**: Moyen - Archive non créée mais T1 échoue silencieusement.

**Solution**:
```ahk
try {
    FileAppend("", archivePath, ENCODING)
} catch as err {
    ; Fallback: ne rien faire, clipboard reste vide
    OutputDebug("Avertissement: Impossible de créer archive vide - " . err.Message)
}
```

---

## AVERTISSEMENT #5: Variables globales non réinitialisées entre tests

**Localisation**: Toutes les variables `global`

**Problème**: Si MultiCopy.ahk est rechargé, les variables globales gardent leurs anciennes valeurs.

**Impact**: Faible - En production, le script tourne en continu. En dev, peut causer confusion.

**Solution**: Aucune pour v1, acceptable.

---

## TESTS RECOMMANDÉS

### Test 1: Vérifier unescape \n
```ahk
; Créer config.ini avec Separator=\n (littéral)
; Lancer MultiCopy.ahk
; MsgBox SEPARATOR pour vérifier valeur
```

### Test 2: Copie 3 items
```ahk
; Sélectionner "Item 1" dans Notepad
; Ctrl+Alt+C
; Sélectionner "Item 2"
; Ctrl+Alt+C
; Sélectionner "Item 3"
; Ctrl+Alt+C
; Vérifier data/buffer.pointer existe
; Vérifier archive .md contient 3 lignes LF pures
```

### Test 3: Collage buffer actif
```ahk
; Après Test 2
; Ouvrir nouveau Notepad
; Ctrl+Alt+V
; Vérifier collage "Item 1\r\nItem 2\r\nItem 3" (CRLF)
; Vérifier buffer.pointer supprimé
; Vérifier archive .md toujours présente
```

### Test 4: Collage buffer vide (T1)
```ahk
; Après Test 3 (buffer supprimé)
; Ouvrir Notepad
; Ctrl+Alt+V
; Vérifier archive vide créée
; Vérifier buffer.pointer n'existe PAS
```

### Test 5: Normalisation CRLF
```ahk
; Copier texte multi-ligne depuis Notepad (CRLF natif)
; Ctrl+Alt+C
; Vérifier archive contient seulement LF (\n), pas CRLF (\r\n)
; Utiliser hex editor ou: FileRead + StrLen check
```

### Test 6: Padding GetLastLines
```ahk
; Créer archive avec 2 items
; Appeler GetLastLines(path, 5)
; Vérifier result.Length = 5
; Vérifier result[3], result[4], result[5] = ""
```

### Test 7: Règle +N GetLastLines
```ahk
; Créer archive avec 12 items
; Appeler GetLastLines(path, 5)
; Vérifier result[1] = "+8"
; Vérifier result[2] = "Item 9"
; Vérifier result[5] = "Item 12"
```

---

## RÉSUMÉ

**Bugs critiques**: 1 (unescape logique, mais fonctionne par hasard)
**Bugs potentiels**: 3 (gestion d'erreurs manquantes)
**Avertissements**: 1 (variables globales)

**Action immédiate recommandée**:
1. Fixer LoadConfig() unescape (Option 2: coder LF en dur)
2. Ajouter catch aux try orphelins
3. Tester manuellement sur Windows avec AHK v2
