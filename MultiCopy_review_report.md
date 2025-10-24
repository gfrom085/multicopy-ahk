# MultiCopy.ahk — Revue rapide et actions

## Résumé
- Fichier analysé: `/mnt/data/MultiCopy.ahk`
- Points **OK** détectés: hotkeys ^!c/^!x/^!v/^!b, fonctions cœur présentes, règle `+N` et padding à 5 **détectés**, boutons de l’éditeur **présents**.
- Points à **corriger**:
  - **Global APP_DIR manquant** — Définis un répertoire racine pour data/, p.ex. `global APP_DIR := A_ScriptDir "\data"` au top.
  - **Fonction SetBufferPath manquante** — Ajoute une fonction qui écrit le chemin dans `buffer.pointer` (UTF-8) après suppression préalable.
  - **Normalisation CR→LF à l'entrée absente** — À l'ajout (copy/cut) supprime `\r` pour stocker uniquement en LF en archive.
  - **Conversion LF→CRLF au collage absente** — Avant `Send ^v`, convertis `\n` en `\r\n` pour compatibilité Windows.
  - **Append sans contrôle du séparateur** — Ajoute `EnsureEndsWithSeparator(text)` pour garantir exactement un séparateur final lors de l'append.
  - **Viewer: tableau 6 colonnes manquant** — Utilise un ListView compact avec colonnes Archive + L1..L5 (règle `+N` + padding 5).

## Snippets suggérés (à intégrer là où pertinent)

### Globals APP_DIR
```ahk
; Globals
global APP_DIR        := A_ScriptDir "\data"
global ARCHIVES_DIR   := APP_DIR "\archives"
global BUFFER_POINTER := APP_DIR "\buffer.pointer"
global SEPARATOR      := "`n"
global PREVIEW_LINES  := 5
```

### SetBufferPath
```ahk
SetBufferPath(path) {
    FileDelete(BUFFER_POINTER)
    FileAppend(path, BUFFER_POINTER, "UTF-8")
}
```

### Unescape \n
```ahk
; Dans LoadConfig():
sep := IniRead(ini, "MultiCopy", "Separator", "\n")
global SEPARATOR := (sep = "\n") ? "`n" : "`n"  ; v1: ne supporter que \n
```

### Normalize LF on input
```ahk
NormalizeToLF(text) {
    return StrReplace(text, "`r", "")
}
```

### EnsureEndsWithSeparator
```ahk
EnsureEndsWithSeparator(text) {
    t := RTrim(text, "`n")
    return t . SEPARATOR
}
```

### AppendToBuffer usage
```ahk
AppendToBuffer(text) {
    text := NormalizeToLF(text)
    if (Trim(text) = "")
        return
    path := GetBufferPath()
    if (path = "") {
        path := CreateNewArchive()
    }
    text := EnsureEndsWithSeparator(text)
    FileAppend(text, path, "UTF-8")
}
```

### LF→CRLF before paste
```ahk
; Dans GroupPaste() avant Send ^v:
content := StrReplace(content, "`r", "")
content := StrReplace(content, "`n", "`r`n")
A_Clipboard := content
Send("^v")
```

### Viewer columns
```ahk
; Viewer ListView (6 colonnes)
lv := g.Add("ListView", "x10 y45 w840 r20 Grid", ["Archive","L1","L2","L3","L4","L5"])
```
