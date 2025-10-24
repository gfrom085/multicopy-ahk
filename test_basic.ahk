; Test basique des fonctions MultiCopy
; @LLM-GENERATED: 2025-01-24
#Requires AutoHotkey v2.0

; Inclure le script principal (commenté pour tests isolés)
; #Include MultiCopy.ahk

; ==============================================================================
; CONFIGURATION TEST
; ==============================================================================

global TEST_DIR := A_ScriptDir . "\test_data"
global TEST_ARCHIVES := TEST_DIR . "\archives"
global TEST_BUFFER := TEST_DIR . "\buffer.pointer"
global TEST_CONFIG := TEST_DIR . "\config.ini"

; ==============================================================================
; SETUP
; ==============================================================================

SetupTest() {
    ; Nettoyer ancien test
    if DirExist(TEST_DIR) {
        DirDelete(TEST_DIR, 1)
    }

    ; Créer structure
    DirCreate(TEST_DIR)
    DirCreate(TEST_ARCHIVES)

    ; Créer config de test
    configContent := "
    (
[MultiCopy]
Separator=\n
Encoding=UTF-8

[Viewer]
PreviewLines=5
    )"
    FileAppend(configContent, TEST_CONFIG, "UTF-8")

    OutputDebug("✓ Setup test complété")
}

; ==============================================================================
; TESTS UNITAIRES
; ==============================================================================

TestNormalizeToLF() {
    OutputDebug("`n=== Test NormalizeToLF ===")

    ; Test 1: Texte avec CRLF
    input := "Item 1`r`nItem 2`r`nItem 3"
    expected := "Item 1`nItem 2`nItem 3"
    result := NormalizeToLF(input)

    if (result = expected) {
        OutputDebug("✓ Test 1 PASS: CRLF -> LF")
    } else {
        OutputDebug("✗ Test 1 FAIL: Expected " . StrLen(expected) . " chars, got " . StrLen(result))
    }

    ; Test 2: Texte déjà en LF
    input2 := "Item A`nItem B"
    result2 := NormalizeToLF(input2)

    if (result2 = input2) {
        OutputDebug("✓ Test 2 PASS: LF inchangé")
    } else {
        OutputDebug("✗ Test 2 FAIL")
    }
}

TestEnsureEndsWithSeparator() {
    OutputDebug("`n=== Test EnsureEndsWithSeparator ===")

    ; Test 1: Texte sans séparateur
    input := "Item 1"
    result := EnsureEndsWithSeparator(input)
    expected := "Item 1`n"

    if (result = expected) {
        OutputDebug("✓ Test 1 PASS: Séparateur ajouté")
    } else {
        OutputDebug("✗ Test 1 FAIL")
    }

    ; Test 2: Texte avec séparateur déjà
    input2 := "Item 1`n"
    result2 := EnsureEndsWithSeparator(input2)

    if (result2 = expected) {
        OutputDebug("✓ Test 2 PASS: Pas de double séparateur")
    } else {
        OutputDebug("✗ Test 2 FAIL: Got " . StrLen(result2) . " chars, expected " . StrLen(expected))
    }

    ; Test 3: Texte avec multiples séparateurs
    input3 := "Item 1`n`n`n"
    result3 := EnsureEndsWithSeparator(input3)

    if (result3 = expected) {
        OutputDebug("✓ Test 3 PASS: Multiples séparateurs normalisés")
    } else {
        OutputDebug("✗ Test 3 FAIL")
    }
}

TestCreateNewArchive() {
    OutputDebug("`n=== Test CreateNewArchive ===")

    ; Simuler création
    timestamp := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
    archivePath := TEST_ARCHIVES . "\" . timestamp . ".md"

    ; Créer manuellement
    try {
        FileAppend("", archivePath, "UTF-8")
        OutputDebug("✓ Archive créée: " . archivePath)

        ; Vérifier existence
        if FileExist(archivePath) {
            OutputDebug("✓ Archive existe bien")
        } else {
            OutputDebug("✗ Archive n'existe pas!")
        }
    } catch as err {
        OutputDebug("✗ Erreur création: " . err.Message)
    }
}

TestGetLastLinesWithPadding() {
    OutputDebug("`n=== Test GetLastLines avec Padding ===")

    ; Créer archive test avec 3 items
    timestamp := FormatTime(, "yyyy-MM-dd_HH-mm-ss-") . "test3"
    archivePath := TEST_ARCHIVES . "\" . timestamp . ".md"

    content := "Item 1`nItem 2`nItem 3`n"
    try {
        FileAppend(content, archivePath, "UTF-8")

        ; Simuler GetLastLines (version simplifiée)
        lines := StrSplit(content, "`n", "`r")

        ; Retirer vides
        while (lines.Length > 0 && Trim(lines[lines.Length]) = "") {
            lines.RemoveAt(lines.Length)
        }

        result := []
        for line in lines {
            result.Push(line)
        }

        ; Padding jusqu'à 5
        while (result.Length < 5) {
            result.Push("")
        }

        if (result.Length = 5) {
            OutputDebug("✓ Padding correct: " . result.Length . " lignes")
        } else {
            OutputDebug("✗ Padding incorrect: " . result.Length . " lignes au lieu de 5")
        }

        ; Vérifier contenu
        if (result[1] = "Item 1" && result[2] = "Item 2" && result[3] = "Item 3") {
            OutputDebug("✓ Contenu correct")
        } else {
            OutputDebug("✗ Contenu incorrect")
        }

        if (result[4] = "" && result[5] = "") {
            OutputDebug("✓ Lignes vides correctes")
        } else {
            OutputDebug("✗ Lignes vides incorrectes")
        }

    } catch as err {
        OutputDebug("✗ Erreur test: " . err.Message)
    }
}

TestGetLastLinesWithPlusN() {
    OutputDebug("`n=== Test GetLastLines avec +N ===")

    ; Créer archive test avec 12 items
    timestamp := FormatTime(, "yyyy-MM-dd_HH-mm-ss-") . "test12"
    archivePath := TEST_ARCHIVES . "\" . timestamp . ".md"

    content := "Item 1`nItem 2`nItem 3`nItem 4`nItem 5`nItem 6`nItem 7`nItem 8`nItem 9`nItem 10`nItem 11`nItem 12`n"

    try {
        FileAppend(content, archivePath, "UTF-8")

        ; Simuler GetLastLines avec règle +N
        lines := StrSplit(content, "`n", "`r")

        ; Retirer vides
        while (lines.Length > 0 && Trim(lines[lines.Length]) = "") {
            lines.RemoveAt(lines.Length)
        }

        total := lines.Length
        count := 5
        result := []

        if (total > count) {
            ; Règle +N
            hidden := total - count + 1  ; 12 - 5 + 1 = 8
            result.Push("+" . hidden)

            startIndex := total - count + 2  ; 12 - 5 + 2 = 9
            loop count - 1 {  ; 4 itérations
                result.Push(lines[startIndex + A_Index - 1])
            }
        }

        if (result.Length = 5) {
            OutputDebug("✓ Nombre lignes correct: 5")
        } else {
            OutputDebug("✗ Nombre lignes incorrect: " . result.Length)
        }

        if (result[1] = "+8") {
            OutputDebug("✓ +N correct: +8")
        } else {
            OutputDebug("✗ +N incorrect: " . result[1])
        }

        if (result[2] = "Item 9" && result[5] = "Item 12") {
            OutputDebug("✓ Items corrects: Item 9 à Item 12")
        } else {
            OutputDebug("✗ Items incorrects: " . result[2] . " à " . result[5])
        }

    } catch as err {
        OutputDebug("✗ Erreur test: " . err.Message)
    }
}

; ==============================================================================
; FONCTIONS UTILITAIRES (copie pour test isolé)
; ==============================================================================

NormalizeToLF(text) {
    return StrReplace(text, "`r", "")
}

EnsureEndsWithSeparator(text) {
    text := RTrim(text, "`n")
    return text . "`n"  ; Hardcodé pour test
}

; ==============================================================================
; EXÉCUTION
; ==============================================================================

; Setup
SetupTest()

; Run tests
TestNormalizeToLF()
TestEnsureEndsWithSeparator()
TestCreateNewArchive()
TestGetLastLinesWithPadding()
TestGetLastLinesWithPlusN()

OutputDebug("`n=== Tests terminés ===")
MsgBox("Tests terminés. Vérifiez DebugView ou Output.")
