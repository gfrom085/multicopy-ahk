; MultiCopy / Archive - AutoHotkey v2
; Copier cumulatif → coller groupé avec archivage Markdown
; @LLM-GENERATED: 2025-01-24

#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; CONFIGURATION
; ==============================================================================

; Chemins
global SCRIPT_DIR := A_ScriptDir
global DATA_DIR := SCRIPT_DIR . "\data"
global ARCHIVES_DIR := DATA_DIR . "\archives"
global BUFFER_POINTER := DATA_DIR . "\buffer.pointer"
global CONFIG_FILE := DATA_DIR . "\config.ini"

; Configuration par défaut
global SEPARATOR := "`n"
global ENCODING := "UTF-8"
global PREVIEW_LINES := 5

; ==============================================================================
; INITIALISATION
; ==============================================================================

; Initialiser les dossiers au démarrage
InitDirectories()

; Charger la configuration
LoadConfig()

; ==============================================================================
; HOTKEYS GLOBAUX
; ==============================================================================

; Copier cumulatif (Ctrl+Alt+C)
^!c::CumulativeCopy()

; Couper cumulatif (Ctrl+Alt+X)
^!x::CumulativeCut()

; Coller groupé (Ctrl+Alt+V)
^!v::GroupPaste()

; Viewer (Ctrl+Alt+B)
^!b::OpenViewer()

; ==============================================================================
; FONCTIONS PRINCIPALES
; ==============================================================================

/**
 * Initialise les dossiers nécessaires
 */
InitDirectories() {
    ; Créer data/ si inexistant
    if !DirExist(DATA_DIR) {
        DirCreate(DATA_DIR)
    }

    ; Créer data/archives/ si inexistant
    if !DirExist(ARCHIVES_DIR) {
        DirCreate(ARCHIVES_DIR)
    }
}

/**
 * Charge la configuration depuis config.ini
 */
LoadConfig() {
    if FileExist(CONFIG_FILE) {
        global SEPARATOR := IniRead(CONFIG_FILE, "MultiCopy", "Separator", "`n")
        global ENCODING := IniRead(CONFIG_FILE, "MultiCopy", "Encoding", "UTF-8")
        global PREVIEW_LINES := IniRead(CONFIG_FILE, "Viewer", "PreviewLines", 5)
    }
}

/**
 * Copier cumulatif - Ajoute la sélection au buffer
 */
CumulativeCopy() {
    ; TODO: Implémenter
    ; 1. Capturer clipboard (Send ^c)
    ; 2. Attendre disponibilité (ClipWait)
    ; 3. Nettoyer format → texte brut
    ; 4. Si buffer.pointer absent → créer nouvelle archive
    ; 5. Append texte au fichier pointé

    MsgBox("CumulativeCopy - À implémenter")
}

/**
 * Couper cumulatif - Ajoute la sélection au buffer puis la supprime
 */
CumulativeCut() {
    ; TODO: Implémenter
    ; 1. Appeler CumulativeCopy()
    ; 2. Supprimer la sélection originale (Send Delete)

    MsgBox("CumulativeCut - À implémenter")
}

/**
 * Coller groupé - Colle le buffer et l'archive
 */
GroupPaste() {
    ; TODO: Implémenter
    ; 1. Vérifier si buffer.pointer existe
    ; 2. Si OUI:
    ;    - Lire contenu du fichier pointé
    ;    - Définir clipboard = contenu
    ;    - Envoyer Ctrl+V
    ;    - Supprimer buffer.pointer
    ; 3. Si NON:
    ;    - Créer archive vide
    ;    - Coller vide
    ;    - Ne pas créer pointeur

    MsgBox("GroupPaste - À implémenter")
}

/**
 * Ouvre le viewer d'archives
 */
OpenViewer() {
    ; TODO: Implémenter
    ; 1. Créer fenêtre GUI
    ; 2. Lister toutes les archives
    ; 3. Afficher preview (règle des 5 lignes)
    ; 4. Boutons: Ouvrir dossier, Éditer archive

    MsgBox("OpenViewer - À implémenter")
}

; ==============================================================================
; FONCTIONS UTILITAIRES - BUFFER
; ==============================================================================

/**
 * Vérifie si le buffer existe
 * @return {Boolean} True si buffer.pointer existe
 */
BufferExists() {
    return FileExist(BUFFER_POINTER) ? true : false
}

/**
 * Lit le chemin de l'archive active depuis buffer.pointer
 * @return {String} Chemin de l'archive ou "" si erreur
 */
GetBufferPath() {
    if !BufferExists() {
        return ""
    }

    try {
        content := FileRead(BUFFER_POINTER, ENCODING)
        return Trim(content)
    } catch {
        return ""
    }
}

/**
 * Crée une nouvelle archive et met à jour le pointeur
 * @return {String} Chemin de la nouvelle archive
 */
CreateNewArchive() {
    ; Générer nom de fichier timestamp
    timestamp := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
    archivePath := ARCHIVES_DIR . "\" . timestamp . ".md"

    ; Créer fichier vide
    try {
        FileAppend("", archivePath, ENCODING)
    } catch as err {
        MsgBox("Erreur: Impossible de créer l'archive`n" . err.Message)
        return ""
    }

    ; Mettre à jour le pointeur
    try {
        FileDelete(BUFFER_POINTER)
    }
    try {
        FileAppend(archivePath, BUFFER_POINTER, ENCODING)
    } catch as err {
        MsgBox("Erreur: Impossible de créer buffer.pointer`n" . err.Message)
        return ""
    }

    return archivePath
}

/**
 * Ajoute du texte au buffer actif
 * @param {String} text Texte à ajouter
 * @return {Boolean} True si succès
 */
AppendToBuffer(text) {
    ; Si pas de buffer, en créer un
    archivePath := GetBufferPath()
    if (archivePath = "") {
        archivePath := CreateNewArchive()
        if (archivePath = "") {
            return false
        }
    }

    ; Vérifier que l'archive existe
    if !FileExist(archivePath) {
        ; Archive supprimée, recréer
        archivePath := CreateNewArchive()
        if (archivePath = "") {
            return false
        }
    }

    ; Append texte + séparateur
    try {
        FileAppend(text . SEPARATOR, archivePath, ENCODING)
        return true
    } catch as err {
        MsgBox("Erreur: Impossible d'écrire dans l'archive`n" . err.Message)
        return false
    }
}

/**
 * Supprime le buffer.pointer (archive reste)
 */
DeleteBufferPointer() {
    try {
        if FileExist(BUFFER_POINTER) {
            FileDelete(BUFFER_POINTER)
        }
    }
}

; ==============================================================================
; FONCTIONS UTILITAIRES - ARCHIVES
; ==============================================================================

/**
 * Liste toutes les archives
 * @return {Array} Tableau de chemins d'archives (triés par date décroissante)
 */
GetAllArchives() {
    archives := []

    Loop Files, ARCHIVES_DIR . "\*.md" {
        archives.Push(A_LoopFileFullPath)
    }

    ; Trier par nom (timestamp ISO) décroissant (plus récent en premier)
    ; Le format YYYY-MM-DD_HH-MM-SS.md permet un tri alphabétique
    if (archives.Length > 0) {
        archives := SortArchivesByName(archives)
    }

    return archives
}

/**
 * Trie un tableau d'archives par nom décroissant
 * @param {Array} archives Tableau de chemins
 * @return {Array} Tableau trié
 */
SortArchivesByName(archives) {
    ; Tri par insertion simple (suffisant pour petites listes)
    n := archives.Length
    loop n - 1 {
        i := A_Index
        loop n - i {
            j := n - A_Index + 1
            ; Extraire les noms de fichiers
            name1 := SubStr(archives[j-1], InStr(archives[j-1], "\",, -1) + 1)
            name2 := SubStr(archives[j], InStr(archives[j], "\",, -1) + 1)
            ; Comparer (ordre décroissant)
            if (name1 < name2) {
                temp := archives[j-1]
                archives[j-1] := archives[j]
                archives[j] := temp
            }
        }
    }
    return archives
}

/**
 * Lit le contenu d'une archive
 * @param {String} archivePath Chemin de l'archive
 * @return {String} Contenu de l'archive
 */
ReadArchive(archivePath) {
    try {
        return FileRead(archivePath, ENCODING)
    } catch {
        return ""
    }
}

/**
 * Récupère les N dernières lignes d'une archive
 * @param {String} archivePath Chemin de l'archive
 * @param {Integer} count Nombre de lignes à récupérer
 * @return {Array} Tableau de lignes
 */
GetLastLines(archivePath, count := 5) {
    content := ReadArchive(archivePath)
    if (content = "") {
        return []
    }

    ; Séparer en lignes
    lines := StrSplit(content, "`n", "`r")

    ; Retirer lignes vides à la fin
    while (lines.Length > 0 && Trim(lines[lines.Length]) = "") {
        lines.RemoveAt(lines.Length)
    }

    ; Retourner les N dernières
    result := []
    total := lines.Length

    if (total <= count) {
        ; Moins de N lignes, retourner toutes + padding pour atteindre N lignes
        for line in lines {
            result.Push(line)
        }
        ; Ajouter lignes vides jusqu'à atteindre count (uniformité)
        while (result.Length < count) {
            result.Push("")
        }
    } else {
        ; Plus de N lignes, retourner +X et les (N-1) dernières
        hidden := total - count + 1
        result.Push("+" . hidden)

        startIndex := total - count + 2
        loop count - 1 {
            result.Push(lines[startIndex + A_Index - 1])
        }
    }

    return result
}

; ==============================================================================
; GUI - VIEWER
; ==============================================================================

/**
 * Crée et affiche la fenêtre du viewer
 */
CreateViewerGUI() {
    ; TODO: Implémenter
    ; 1. Créer fenêtre principale
    ; 2. ListView avec archives
    ; 3. Preview 5 lignes par archive
    ; 4. Boutons: Ouvrir dossier, Éditer
}

/**
 * Crée et affiche l'éditeur d'archive
 * @param {String} archivePath Chemin de l'archive à éditer
 */
CreateEditorGUI(archivePath) {
    ; TODO: Implémenter
    ; 1. Zone texte multi-ligne
    ; 2. Boutons: Save, Copier, Ajouter au buffer, Nouveau buffer
}

; ==============================================================================
; AIDE ET INFORMATIONS
; ==============================================================================

; Afficher notification au démarrage
TrayTip("MultiCopy/Archive", "Script actif`n`nCtrl+Alt+C = Copier`nCtrl+Alt+V = Coller`nCtrl+Alt+B = Viewer", 5)
