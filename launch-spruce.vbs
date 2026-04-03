' ============================================
'  ECI Spruce Desktop Launcher (Silent)
'  Runs the batch file without a console window
' ============================================
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run Chr(34) & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\launch-spruce.bat" & Chr(34), 0, False
