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
        ; Pour v1: toujours utiliser LF, ignorer la config
        ; La valeur config.ini "Separator=\n" est documentaire uniquement
        global SEPARATOR := "`n"

        global ENCODING := IniRead(CONFIG_FILE, "MultiCopy", "Encoding", "UTF-8")
        global PREVIEW_LINES := IniRead(CONFIG_FILE, "Viewer", "PreviewLines", 5)
    }
}

/**
 * Copier cumulatif - Ajoute la sélection au buffer
 */
CumulativeCopy() {
    ; Envoyer Ctrl+C pour copier la sélection
    Send("^c")

    ; Attendre que le clipboard soit disponible (timeout 1s)
    if !ClipWait(1) {
        MsgBox("Clipboard inaccessible, réessayez")
        return
    }

    ; Récupérer le contenu du clipboard
    text := A_Clipboard

    ; AppendToBuffer gère:
    ; - Normalisation CRLF->LF
    ; - Ignorer si vide (silencieusement)
    ; - Assurer séparateur unique
    ; - Créer buffer/archive si absent
    AppendToBuffer(text)
}

/**
 * Couper cumulatif - Ajoute la sélection au buffer puis la supprime
 */
CumulativeCut() {
    ; Copier d'abord au buffer
    CumulativeCopy()

    ; Puis supprimer la sélection originale
    Send("{Delete}")
}

/**
 * Coller groupé - Colle le buffer et l'archive
 */
GroupPaste() {
    if BufferExists() {
        ; Cas 1: Buffer actif - lire et coller
        archivePath := GetBufferPath()

        ; Lire le contenu de l'archive
        content := ReadArchive(archivePath)

        ; Convertir LF -> CRLF pour compatibilité Windows
        content := StrReplace(content, "`r", "")    ; Strip \r d'abord (sécurité)
        content := StrReplace(content, "`n", "`r`n")  ; LF -> CRLF

        ; Coller via clipboard
        A_Clipboard := content
        Send("^v")

        ; Supprimer le pointeur (archive persiste)
        DeleteBufferPointer()
    } else {
        ; Cas 2: Buffer vide (Test T1) - créer archive vide et coller
        ; Générer nom de fichier timestamp
        timestamp := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
        archivePath := ARCHIVES_DIR . "\" . timestamp . ".md"

        ; Créer archive vide (0 bytes)
        try {
            FileAppend("", archivePath, ENCODING)
        } catch as err {
            ; Ignorer silencieusement - non critique pour T1
            OutputDebug("Avertissement: Impossible de créer archive vide - " . err.Message)
        }

        ; Coller clipboard vide
        A_Clipboard := ""
        Send("^v")

        ; NE PAS créer buffer.pointer (reste vide pour prochaine copie)
    }
}

/**
 * Ouvre le viewer d'archives
 */
OpenViewer() {
    CreateViewerGUI()
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
 * Définit le chemin du buffer actif dans buffer.pointer
 * @param {String} path Chemin absolu de l'archive à pointer
 */
SetBufferPath(path) {
    try {
        if FileExist(BUFFER_POINTER) {
            FileDelete(BUFFER_POINTER)
        }
    } catch as err {
        ; Ignorer - si delete échoue, FileAppend écrasera quand même
        OutputDebug("Avertissement: Impossible de supprimer ancien buffer.pointer - " . err.Message)
    }

    try {
        FileAppend(path, BUFFER_POINTER, ENCODING)
    } catch as err {
        MsgBox("Erreur: Impossible de créer buffer.pointer`n" . err.Message)
    }
}

/**
 * Normalise un texte en LF pur (retire tous les \r)
 * @param {String} text Texte à normaliser
 * @return {String} Texte avec seulement LF
 */
NormalizeToLF(text) {
    return StrReplace(text, "`r", "")
}

/**
 * Assure qu'un texte se termine par exactement un séparateur
 * @param {String} text Texte à traiter
 * @return {String} Texte avec un séparateur final unique
 */
EnsureEndsWithSeparator(text) {
    text := RTrim(text, "`n")  ; Retirer tous les \n à la fin
    return text . SEPARATOR     ; Ajouter exactement UN séparateur
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
    SetBufferPath(archivePath)

    return archivePath
}

/**
 * Ajoute du texte au buffer actif
 * @param {String} text Texte à ajouter
 * @return {Boolean} True si succès
 */
AppendToBuffer(text) {
    ; Normaliser le texte (CRLF -> LF)
    text := NormalizeToLF(text)

    ; Ignorer silencieusement si texte vide
    if (Trim(text) = "") {
        return true
    }

    ; Assurer exactement un séparateur final
    text := EnsureEndsWithSeparator(text)

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

    ; Append texte (déjà avec séparateur)
    try {
        FileAppend(text, archivePath, ENCODING)
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
    } catch as err {
        ; Ignorer silencieusement - non critique
        OutputDebug("Avertissement: Impossible de supprimer buffer.pointer - " . err.Message)
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
    ; Créer fenêtre GUI
    viewerGui := Gui()
    viewerGui.Title := "MultiCopy - Viewer d'Archives"
    viewerGui.Opt("+Resize")

    ; Label d'information
    viewerGui.Add("Text", "x10 y10 w840", "Archives (triées par date, plus récent en premier) :")

    ; ListView avec 6 colonnes (Archive + L1..L5)
    lv := viewerGui.Add("ListView", "x10 y35 w840 h400 Grid", ["Archive", "L1", "L2", "L3", "L4", "L5"])

    ; Largeurs de colonnes
    lv.ModifyCol(1, 180)  ; Archive (nom fichier)
    lv.ModifyCol(2, 132)  ; L1
    lv.ModifyCol(3, 132)  ; L2
    lv.ModifyCol(4, 132)  ; L3
    lv.ModifyCol(5, 132)  ; L4
    lv.ModifyCol(6, 132)  ; L5

    ; Remplir le ListView avec les archives
    archives := GetAllArchives()
    for archivePath in archives {
        ; Extraire le nom de fichier
        SplitPath(archivePath, &fileName)

        ; Obtenir les 5 dernières lignes avec padding/+N
        lines := GetLastLines(archivePath, 5)

        ; Ajouter ligne au ListView
        ; Si moins de 5 éléments dans lines, compléter avec vide
        l1 := lines.Length >= 1 ? lines[1] : ""
        l2 := lines.Length >= 2 ? lines[2] : ""
        l3 := lines.Length >= 3 ? lines[3] : ""
        l4 := lines.Length >= 4 ? lines[4] : ""
        l5 := lines.Length >= 5 ? lines[5] : ""

        lv.Add("", fileName, l1, l2, l3, l4, l5)
    }

    ; Boutons
    btnOpenFolder := viewerGui.Add("Button", "x10 y445 w150", "Ouvrir dossier")
    btnOpenFolder.OnEvent("Click", (*) => Run("explorer.exe " . ARCHIVES_DIR))

    btnEdit := viewerGui.Add("Button", "x170 y445 w150", "Éditer sélection")
    btnEdit.OnEvent("Click", (*) => EditSelectedArchive(lv))

    btnEditBuffer := viewerGui.Add("Button", "x330 y445 w150", "Éditer buffer actif")
    btnEditBuffer.OnEvent("Click", (*) => EditCurrentBuffer())

    btnRefresh := viewerGui.Add("Button", "x490 y445 w150", "Rafraîchir")
    btnRefresh.OnEvent("Click", (*) => RefreshViewer(lv))

    btnClose := viewerGui.Add("Button", "x700 y445 w150", "Fermer")
    btnClose.OnEvent("Click", (*) => viewerGui.Destroy())

    ; Double-clic sur une archive -> éditer
    lv.OnEvent("DoubleClick", (*) => EditSelectedArchive(lv))

    ; Afficher la fenêtre
    viewerGui.Show("w860 h480")
}

/**
 * Édite l'archive sélectionnée dans le ListView
 */
EditSelectedArchive(lv) {
    ; Obtenir la ligne sélectionnée
    row := lv.GetNext()
    if (row = 0) {
        MsgBox("Aucune archive sélectionnée")
        return
    }

    ; Obtenir le nom de fichier
    fileName := lv.GetText(row, 1)
    archivePath := ARCHIVES_DIR . "\" . fileName

    ; Ouvrir l'éditeur
    CreateEditorGUI(archivePath)
}

/**
 * Édite le buffer actif (fichier pointé par buffer.pointer)
 */
EditCurrentBuffer() {
    archivePath := GetBufferPath()
    if (archivePath = "") {
        MsgBox("Aucun buffer actif")
        return
    }

    CreateEditorGUI(archivePath)
}

/**
 * Rafraîchit la liste des archives
 */
RefreshViewer(lv) {
    ; Vider le ListView
    lv.Delete()

    ; Recharger les archives
    archives := GetAllArchives()
    for archivePath in archives {
        SplitPath(archivePath, &fileName)
        lines := GetLastLines(archivePath, 5)

        l1 := lines.Length >= 1 ? lines[1] : ""
        l2 := lines.Length >= 2 ? lines[2] : ""
        l3 := lines.Length >= 3 ? lines[3] : ""
        l4 := lines.Length >= 4 ? lines[4] : ""
        l5 := lines.Length >= 5 ? lines[5] : ""

        lv.Add("", fileName, l1, l2, l3, l4, l5)
    }
}

/**
 * Crée et affiche l'éditeur d'archive
 * @param {String} archivePath Chemin de l'archive à éditer
 */
CreateEditorGUI(archivePath) {
    ; Extraire le nom du fichier
    SplitPath(archivePath, &fileName)

    ; Créer fenêtre GUI
    editorGui := Gui()
    editorGui.Title := "Éditeur - " . fileName
    editorGui.Opt("+Resize")

    ; Label d'information
    editorGui.Add("Text", "x10 y10 w580", "Contenu de l'archive :")

    ; Zone de texte multi-ligne
    editControl := editorGui.Add("Edit", "x10 y35 w580 h350 Multi VScroll", "")

    ; Charger le contenu du fichier
    content := ""
    if FileExist(archivePath) {
        try {
            content := FileRead(archivePath, ENCODING)
        } catch as err {
            MsgBox("Erreur lecture: " . err.Message)
        }
    }
    editControl.Value := content

    ; Boutons (4 comme demandé)
    btnSave := editorGui.Add("Button", "x10 y395 w135", "Save")
    btnSave.OnEvent("Click", (*) => SaveArchive(archivePath, editControl))

    btnCopy := editorGui.Add("Button", "x155 y395 w135", "Copier presse-papiers")
    btnCopy.OnEvent("Click", (*) => CopyToClipboard(editControl))

    btnAddToBuffer := editorGui.Add("Button", "x300 y395 w135", "Ajouter au buffer")
    btnAddToBuffer.OnEvent("Click", (*) => AddToCurrentBuffer(editControl))

    btnNewBuffer := editorGui.Add("Button", "x445 y395 w145", "Nouveau buffer")
    btnNewBuffer.OnEvent("Click", (*) => CreateNewBufferFromEditor(editControl))

    ; Bouton fermer
    btnClose := editorGui.Add("Button", "x250 y430 w100", "Fermer")
    btnClose.OnEvent("Click", (*) => editorGui.Destroy())

    ; Afficher la fenêtre
    editorGui.Show("w600 h470")
}

/**
 * Sauvegarde le contenu dans l'archive
 */
SaveArchive(archivePath, editControl) {
    content := editControl.Value

    try {
        ; Supprimer et recréer le fichier
        if FileExist(archivePath) {
            FileDelete(archivePath)
        }
        FileAppend(content, archivePath, ENCODING)
        MsgBox("Archive sauvegardée", "Succès", "T1")
    } catch as err {
        MsgBox("Erreur sauvegarde: " . err.Message, "Erreur")
    }
}

/**
 * Copie tout le contenu dans le presse-papiers
 */
CopyToClipboard(editControl) {
    A_Clipboard := editControl.Value
    MsgBox("Contenu copié dans le presse-papiers", "Succès", "T1")
}

/**
 * Ajoute le contenu au buffer actif
 */
AddToCurrentBuffer(editControl) {
    content := editControl.Value

    if (Trim(content) = "") {
        MsgBox("Aucun contenu à ajouter")
        return
    }

    ; Normaliser et ajouter au buffer
    AppendToBuffer(content)
    MsgBox("Contenu ajouté au buffer actif", "Succès", "T1")
}

/**
 * Crée un nouveau buffer et y place le contenu
 */
CreateNewBufferFromEditor(editControl) {
    content := editControl.Value

    ; Créer nouvelle archive
    archivePath := CreateNewArchive()
    if (archivePath = "") {
        MsgBox("Erreur création nouveau buffer")
        return
    }

    ; Si du contenu, l'ajouter
    if (Trim(content) != "") {
        try {
            ; Normaliser et ajouter
            content := NormalizeToLF(content)
            content := EnsureEndsWithSeparator(content)
            FileAppend(content, archivePath, ENCODING)
        } catch as err {
            MsgBox("Erreur écriture: " . err.Message)
            return
        }
    }

    MsgBox("Nouveau buffer créé: " . SubStr(archivePath, InStr(archivePath, "\", , -1) + 1), "Succès", "T1.5")
}

; ==============================================================================
; AIDE ET INFORMATIONS
; ==============================================================================

; Afficher notification au démarrage
TrayTip("MultiCopy/Archive", "Script actif`n`nCtrl+Alt+C = Copier`nCtrl+Alt+V = Coller`nCtrl+Alt+B = Viewer", 5)
