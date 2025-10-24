; Test comment IniRead lit \n
#Requires AutoHotkey v2.0

; Créer un fichier INI de test
iniPath := A_ScriptDir . "\test.ini"
iniContent := "
(
[Test]
Separator=\n
)"

FileDelete(iniPath)
FileAppend(iniContent, iniPath, "UTF-8")

; Lire la valeur
sep := IniRead(iniPath, "Test", "Separator", "default")

; Afficher
MsgBox("Valeur lue: " . sep . "`nLongueur: " . StrLen(sep) . " caractères`n`nComparaisons:`nsep = '\n' : " . (sep = "\n" ? "TRUE" : "FALSE") . "`nsep = '``n' : " . (sep = "``n" ? "TRUE" : "FALSE"))

; Cleanup
FileDelete(iniPath)
