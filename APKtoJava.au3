#region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=APKtoJava.exe
#AutoIt3Wrapper_Compression=0
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Res_Description=©2012 broodplank.net
#AutoIt3Wrapper_Res_Fileversion=0.0.0.5
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Obfuscator=y
#endregion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Process.au3>
#include <File.au3>
#include <WindowsConstants.au3>
#include <GuiConstantsEx.au3>
#include <ExtProp.au3>
#include <WinAPI.au3>
#include <EditConstants.au3>

#OnAutoItStartRegister "FixConfig"

Sleep(1000)

Func FixConfig()
	If FileExists(@ScriptDir & "\tools\jd-gui.cfg") Then FileDelete(@ScriptDir & "\tools\jd-gui.cfg")
;~ 	IniWriteSection("
	IniWrite(@ScriptDir & "\tools\jd-gui.cfg", "Manifest", "Version", "2")
	IniWrite(@ScriptDir & "\tools\jd-gui.cfg", "Update", "CurrentVersion", "0.3.3")
	IniWrite(@ScriptDir & "\tools\jd-gui.cfg", "RecentDirectories", "LoadPath", @ScriptDir & "\tools\")
	IniWrite(@ScriptDir & "\tools\jd-gui.cfg", "RecentDirectories", "SavePath", @ScriptDir & "\tools\")
EndFunc   ;==>FixConfig


Opt("WinTitleMatchMode", 2)

Global $getpath_apkjar, $getpath_classes, $getpath_outputdir, $log, $decompile_eclipse, $decompile_resource, $decompile_source_java, $decompile_source_smali


GUICreate("APK to Java v0.5 BETA (by broodplank)", 550, 450)

GUISetFont(8, 8, 0, "Verdana")

GUICtrlCreateLabel("Log:", 305, 5)
$log = GUICtrlCreateEdit("APK to Java v0.5 BETA Initialized...." & @CRLF & "------------------------------------------" & @CRLF, 305, 22, 240, 420, BitOR($WS_VSCROLL, $ES_AUTOVSCROLL, $ES_MULTILINE, $ES_READONLY))

GUICtrlCreateGroup("Step 1: Selecting the file", 5, 5, 290, 140)
GUICtrlCreateLabel("Please choose the apk/jar file that you want to " & @CRLF & "decompile to java sources: ", 15, 25)
$file = GUICtrlCreateInput("", 15, 55, 195, 20)
GUICtrlSetState($file, $GUI_DISABLE)
$filebrowse = GUICtrlCreateButton("Browse..", 215, 55, 70, 20)

GUICtrlCreateLabel("Or select a classes.dex file to decompile:", 15, 85)

$filedex = GUICtrlCreateInput("", 15, 110, 195, 20)
GUICtrlSetState($filedex, $GUI_DISABLE)
$filebrowsedex = GUICtrlCreateButton("Browse..", 215, 110, 70, 20)

GUICtrlCreateGroup("Step 2: Selecting the output dir", 5, 150, 290, 85)
GUICtrlCreateLabel("Please choose the destination directory for the" & @CRLF & "decompiled java sources: ", 15, 170)
$destination = GUICtrlCreateInput("", 15, 205, 195, 20)
GUICtrlSetState($destination, $GUI_DISABLE)
$destdirbrowse = GUICtrlCreateButton("Browse..", 215, 205, 70, 20)

GUICtrlCreateGroup("Step 3: Choosing decompilation preferences", 5, 240, 290, 155)
GUICtrlCreateLabel("Please choose the parts to decompile:", 15, 260)
$decompile_source_java = GUICtrlCreateCheckbox("Sources (generate java code)", 15, 280)
$decompile_source_smali = GUICtrlCreateCheckbox("Sources (generate smali code)", 15, 300)
$decompile_resource = GUICtrlCreateCheckbox("Resources (the images/layouts/etc)", 15, 320)

GUICtrlCreateLabel("Additional options:", 15, 350)
$decompile_eclipse = GUICtrlCreateCheckbox("Convert the output to an Eclipse project", 15, 370)
GUICtrlSetState($decompile_eclipse, $GUI_DISABLE)

$start_process = GUICtrlCreateButton("Start Process!", 5, 400, 105, 25)
$about_button = GUICtrlCreateButton("Help / About", 115, 400, 105, 25)
$exit_button = GUICtrlCreateButton("Exit", 225, 400, 70, 25)

$copyright = GUICtrlCreateLabel("©2012 broodplank.net", 5, 435)
GUICtrlSetStyle($copyright, $WS_DISABLED)



Func _ExtractAPK($apkfile)
	GUICtrlSetData($log, "APK to Java v0.5 BETA Initialized...." & @CRLF & "------------------------------------------" & @CRLF)
	FileDelete(@ScriptDir & "\tools\classes.dex")
	_AddLog("- Extracting APK...")
	FileCopy($getpath_apkjar, @ScriptDir & "\tools\" & _GetExtProperty($getpath_apkjar, 0))
	RunWait(@ScriptDir & "\tools\extractapk.bat " & _GetExtProperty($getpath_apkjar, 0), "", @SW_HIDE)
	If GUICtrlRead($decompile_resource) = 1 Then _DecompileResource()
	If FileExists(@ScriptDir & "\tools\classes.dex") Then
		_AddLog("- Extracting APK Done!")
		Sleep(250)
		If GUICtrlRead($decompile_source_smali) = 1 Then _DecompileSmali()
		If GUICtrlRead($decompile_source_java) = 1 Then _DecompileJava()
		If GUICtrlRead($decompile_eclipse) = 1 Then _MakeEclipse()
	Else
		_AddLog("No classes.dex file found! Aborting!")
	EndIf
EndFunc   ;==>_ExtractAPK

Func _DecompileSmali()
	If FileExists(@ScriptDir & "\tools\smalicode") Then DirRemove(@ScriptDir & "\tools\smalicode", 1)
	_AddLog("- Decompiling to Smali code...")
	RunWait(@ScriptDir & "\tools\deosmali.bat", "", @SW_HIDE)
	_AddLog("- Decompiling to Smali Done!")
	;	if FileExists($getpath_outputdir&"\smalicode") Then DirRemove($getpath_outputdir&"\smalicode", 1)
	_AddLog("- Copying to output dir...")
	DirCopy(@ScriptDir & "\tools\smalicode", $getpath_outputdir & "\smalicode", 1)
	Sleep(250)
	_AddLog("- Copying to output dir Done!")
EndFunc   ;==>_DecompileSmali

Func _DecompileJava()
	_AddLog("- Converting to Java Code...")
	Sleep(500)
	;if FileExists(@ScriptDir&"\tools\classes-dex2jar.jar") then FileDelete(@ScriptDir&"\tools\classes-dex2jar.jar")
	_AddLog("- Converting classes.dex to classes-dex2jar.jar...")
	If FileExists(@ScriptDir & "\tools\classes-dex2jar.src.zip") Then FileDelete(@ScriptDir & "\tools\classes-dex2jar.src.zip")
	RunWait(@ScriptDir & "\tools\dex2jar.bat classes.dex", "", @SW_HIDE)
	Sleep(250)
	MsgBox(0, "APK To Java", "Because controlling JD-GUI trough this application didn't work" & @CRLF & "You have to perform the manual action listed below to continue" & @CRLF & @CRLF & "In JD-GUI, press Control + Alt + S to open the save dialog" & @CRLF & "The script will take it from there.")
;~ 	if FileExists(@ScriptDir&"\tools\classes-dex2jar.jar") Then
	Run(@ScriptDir & "\tools\jd-gui.exe " & Chr(34) & @ScriptDir & "\tools\classes-dex2jar.jar" & Chr(34))
;~ 		sleep(250)
;~ 		Local $guititle = WinGetTitle("Java Decompiler", "")
;~ 		MsgBox(0, "Full title read was:", $guititle)



;~ 		WinWait($guititle)

;~ ControlFocus($guititle, "", "wxWindowClassNR")


;~ 		sleep(250)
;~ 		;WinSetOnTop($guititle, "", 1)
;~ 		ControlSend($guititle, "", "", "^!a")


	;WinSetOnTop("Save", "", 1)
	WinWaitActive("Save")
	Sleep(100)
	ControlSend("Save", "", "", "classes-dex2jar.src.zip")
	Sleep(200)
	ControlSend("Save", "", "", "{enter}")
	Sleep(200)

	WinWaitClose("Save All Sources", "")

	ProcessClose("jd-gui.exe")

	Sleep(250)
	_AddLog("- Generating Java Code Done!")
	Sleep(250)
	_AddLog("- Extracting Java Code....")
	RunWait(@ScriptDir & "\tools\extractjava.bat", "", @SW_HIDE)
	_AddLog("- Extracting Java Code Done!")
	Sleep(250)
	_AddLog("- Copying Java Code to output dir....")
	DirCopy(@ScriptDir & "\tools\javacode", $getpath_outputdir & "\javacode", 1)
	_AddLog("- Copying Java Code Done!")
;~ 	Else
;~ 		MsgBox(16, "APK to Java", "An error has occured, the classes.dex file could not be converted to a jar file...")
;~ 	EndIf


EndFunc   ;==>_DecompileJava


;~ Func _CleanUp()
;~ 	_AddLog("- Cleaning Up...")
;~ 	DirRemove(@ScriptDir&"\tools\smalicode")
;~ 	DirRemove(@ScriptDir&"\tools\javacode")
;~ 	DirRemove(@ScriptDir&"\tools\resources")
;~ 	FileDelete(@ScriptDir&"\tools\"&_GetExtProperty($getpath_apkjar, 0)&".zip")
;~ 	FileDelete(@ScriptDir&"\tools\classes-dex2jar.jar")
;~ 	FileDelete(@ScriptDir&"\tools\classes-dex2jar.src.zip")
;~ 	FileDelete(@ScriptDir&"\tools\classes.dex")
;~ 	_AddLog("- Cleaning Done!"&@CRLF)
;~ 	_AddLog("The decompilation process is completed!")

;~ EndFunc

Func _DecompileResource()
	If FileExists(@ScriptDir & "\tools\resource") Then DirRemove(@ScriptDir & "\tools\resource")
	_AddLog("- Decompiling Resources...")
	ConsoleWrite(@ScriptDir & "\tools\extractres.bat " & Chr(34) & @ScriptDir & "\tools\" & _GetExtProperty($getpath_apkjar, 0) & Chr(34))
	RunWait(@ScriptDir & "\tools\extractres.bat " & Chr(34) & @ScriptDir & "\tools\" & _GetExtProperty($getpath_apkjar, 0) & Chr(34), "", @SW_HIDE)
	_AddLog("- Decompiling Resources Done!")
	;	if FileExists($getpath_outputdir&"\resource") Then DirRemove($getpath_outputdir&"\resource")
	_AddLog("- Copying to output dir...")
	DirCopy(@ScriptDir & "\tools\resource", $getpath_outputdir & "\resource", 1)
	Sleep(250)
	_AddLog("- Copying to output dir Done!")
EndFunc   ;==>_DecompileResource

Func _MakeEclipse()

	TrayTip("APK to Java", "Making Eclipse Project Done!", 2)
	Sleep(1000)
EndFunc   ;==>_MakeEclipse

Func _AddLog($string)
	$CurrentLog = GUICtrlRead($log)
	$NewLog = $CurrentLog & @CRLF & $string
	GUICtrlSetData($log, $NewLog)
EndFunc   ;==>_AddLog




GUISetState()

While 1

	$msg = GUIGetMsg()

	Select

		Case $msg = $gui_event_close Or $msg = $exit_button
			Exit

		Case $msg = $filebrowse
			;			if GUICtrlGetState($filebrowsedex) = 144 Then GUICtrlSetState($filebrowsedex, $GUI_ENABLE)

			$getpath_apkjar = FileOpenDialog("APK to Java, please select an apk/jar file", "", "APK Files (*.apk)|JAR Files (*.jar)", 1, "")
			If $getpath_apkjar = "" Then
				;
			Else
				GUICtrlSetData($file, _GetExtProperty($getpath_apkjar, 0))
				If GUICtrlRead($filedex) <> "" Then GUICtrlSetData($filedex, "")
				;GUICtrlSetState($filebrowsedex, $GUI_DISABLE)
			EndIf

		Case $msg = $filebrowsedex
			;	if GUICtrlGetState($filebrowse) = 144 Then GUICtrlSetState($filebrowse, $GUI_ENABLE)
			$getpath_classes = FileOpenDialog("APK to Java, please select a classes.dex file", "", "DEX Files (*.dex)", 1, "classes.dex")
			If $getpath_classes = "" Then
				;
			Else
				GUICtrlSetData($filedex, _GetExtProperty($getpath_classes, 0))
				If GUICtrlRead($file) <> "" Then GUICtrlSetData($file, "")
				;	GUICtrlSetState($filebrowse, $GUI_DISABLE)
			EndIf

		Case $msg = $destdirbrowse
			$getpath_outputdir = FileSelectFolder("APK to Java, please select the output directory", "", 7, "")
			If $getpath_outputdir = "" Then
				;
			Else
				GUICtrlSetData($destination, $getpath_outputdir)
			EndIf

		Case $msg = $start_process
			If $file = "" Or $filedex = "" Then
				MsgBox(0, "APK to Java", "You haven't selected an apk/jar or dex file!")
			ElseIf $destination = "" Then
				MsgBox(0, "APK to Java", "You haven't selected an output directory!")
			Else
				_ExtractAPK(_GetExtProperty($getpath_apkjar, 0))
				_RunDos("explorer " & $getpath_outputdir)


				;CLEANING

				_AddLog("- Cleaning Up...")
				DirRemove(@ScriptDir & "\tools\smalicode", 1)
				DirRemove(@ScriptDir & "\tools\javacode", 1)
				DirRemove(@ScriptDir & "\tools\resource", 1)
				FileDelete(@ScriptDir & "\tools\" & _GetExtProperty($getpath_apkjar, 0) & ".zip")
				FileDelete(@ScriptDir & "\tools\classes-dex2jar.jar")
				FileDelete(@ScriptDir & "\tools\classes-dex2jar.src.zip")
				FileDelete(@ScriptDir & "\tools\classes.dex")
				_AddLog("- Cleaning Done!" & @CRLF)
				_AddLog("The decompilation process is completed!")

			EndIf



	EndSelect

WEnd



;~ $openfile = FileOpenDialog("Charged Notifcation Remover - Please choose a Samsung based SystemUI.apk", @WorkingDir, "APK Files (*.apk)", 1, "SystemUI.apk")
;~ If @error Then
;~ 	MsgBox(16, "Charged Notifcation Remover", "Aborted..")
;~ 	Exit
;~ Else
;~ 	If FileExists(@ScriptDir & "\classes.dex") Then FileDelete(@ScriptDir & "\classes.dex")
;~ 	If FileExists(@ScriptDir & "\out.dex") Then FileDelete(@ScriptDir & "\out.dex")
;~ 	If FileExists(@ScriptDir & "\SystemUI.apk") Then FileDelete(@ScriptDir & "\SystemUI.apk")
;~ 	If FileExists(@ScriptDir & "\SystemUI.zip") Then FileDelete(@ScriptDir & "\SystemUI.zip")
;~ 	If FileExists(@ScriptDir & "\finished_apks\SystemUI.apk") Then FileDelete(@ScriptDir & "\finished_apks\SystemUI.apk")
;~ 	If FileExists(@ScriptDir & "\finished_apks\SystemUI.zip") Then FileDelete(@ScriptDir & "\finished_apks\SystemUI.zip")
;~ 	FileCopy($openfile, @ScriptDir & "\SystemUI.apk")
;~ EndIf

;~ DirRemove(@ScriptDir & "\dexout", 1)
;~ If FileExists(@ScriptDir & "\finished_apks\SystemUI.apk.backup") Then FileDelete(@ScriptDir & "\finished_apks\SystemUI.apk.backup")
;~ FileCopy(@ScriptDir & "\SystemUI.apk", @ScriptDir & "\finished_apks\SystemUI.apk.backup")
;~ SplashTextOn("Charged Notifcation Remover", "Status: Making backup...", 250, 40, -1, -1, 4, "Verdana", 10, 400)
;~ Sleep(100)

;~ FileDelete(@TempDir & "\results.txt")

;~ Func _StringSearchInFile($file, $qry)
;~ 	_RunDos("find /n /i """ & $qry & """ " & $file & " >> " & @TempDir & "\results.txt")
;~ 	If Not @error Then
;~ 		FileSetAttrib(@TempDir & "\results.txt", "-N+H+T", 0)
;~ 		$CHARS = FileGetSize(@TempDir & "\results.txt")
;~ 		Return FileRead(@TempDir & "\results.txt", $CHARS) & @CRLF
;~ 	EndIf
;~ EndFunc   ;==>_StringSearchInFile

;~ SplashTextOn("Charged Notifcation Remover", "Status: Extracting...", 250, 40, -1, -1, 4, "Verdana", 10, 400)
;~ Sleep(100)
;~ RunWait(@ScriptDir & "\extract.bat", "", @SW_HIDE)
;~ SplashTextOn("Charged Notifcation Remover", "Status: Deodexing...", 250, 40, -1, -1, 4, "Verdana", 10, 400)
;~ RunWait(@ScriptDir & "\deodex.bat", "", @SW_HIDE)

;~ FileDelete(@TempDir & "\results.txt")

;~ SplashTextOn("Charged Notifcation Remover", "Status: Determine lines...", 250, 40, -1, -1, 4, "Verdana", 10, 400)

;~ $search1 = _StringSearchInFile(@ScriptDir & "\dexout\com\android\systemui\statusbar\policy\StatusBarPolicy.smali", "Landroid/app/NotificationManager;->notify(ILandroid/app/Notification;)V")
;~ $readfirst = FileReadLine(@TempDir & "\results.txt", 3)
;~ $readchars1 = StringLeft($readfirst, 5)
;~ $startline = StringRight($readchars1, 4)

;~ ConsoleWrite($startline & @CRLF)
;~ FileDelete(@TempDir & "\results.txt")

;~ $search2 = _StringSearchInFile(@ScriptDir & "\dexout\com\android\systemui\statusbar\policy\StatusBarPolicy.smali", "Lcom/android/systemui/statusbar/policy/StatusBarPolicy;->turnOnScreenWithForce()V")
;~ $readsecond = FileReadLine(@TempDir & "\results.txt", 3)
;~ $readchars2 = StringLeft($readsecond, 5)
;~ $endline = StringRight($readchars2, 4)

;~ $linecount = $endline - $startline


;~ FileDelete(@TempDir&"\results.txt")

;~ $linecount = $endline - $startline
;~ ConsoleWrite($linecount)

;~ If $linecount > 12 Or $linecount < 8 Then
;~ 	MsgBox(16, "Error", "Charged Notification lines are not found" & @CRLF & @CRLF & "Possible Reasons:" & @CRLF & "- No Samsung SystemUI.apk" & @CRLF & "- Already removed the charged notification")
;~ 	Exit
;~ Else
;~ 	SplashTextOn("Charged Notifcation Remover", "Status: Deleting Line: " & $startline & "...", 250, 40, -1, -1, 4, "Verdana", 10, 400)
;~ 	_FileWriteToLine(@ScriptDir & "\dexout\com\android\systemui\statusbar\policy\StatusBarPolicy.smali", $startline, " ", 1)
;~ 	Sleep(500)
;~ 	SplashTextOn("Charged Notifcation Remover", "Status: Deleting Line: " & $endline - 3 & "...", 250, 40, -1, -1, 4, "Verdana", 10, 400)
;~ 	_FileWriteToLine(@ScriptDir & "\dexout\com\android\systemui\statusbar\policy\StatusBarPolicy.smali", $endline - 3, " ", 1)
;~ 	Sleep(500)
;~ 	SplashTextOn("Charged Notifcation Remover", "Status: Deleting Line: " & $endline & "...", 250, 40, -1, -1, 4, "Verdana", 10, 400)
;~ 	_FileWriteToLine(@ScriptDir & "\dexout\com\android\systemui\statusbar\policy\StatusBarPolicy.smali", $endline, " ", 1)
;~ 	Sleep(500)
;~ EndIf

;~ SplashTextOn("Charged Notifcation Remover", "Status: Compiling classes.dex...", 250, 40, -1, -1, 4, "Verdana", 10, 400)
;~ RunWait(@ScriptDir & "\compile.bat", "", @SW_HIDE)
;~ Sleep(100)
;~ DirRemove(@ScriptDir & "\dexout", 1)

;~ SplashTextOn("Charged Notifcation Remover", "Status: Updating SystemUI.apk...", 250, 40, -1, -1, 4, "Verdana", 10, 400)
;~ RunWait(@ScriptDir & "\addfiles.bat", "", @SW_HIDE)
;~ Sleep(100)

;~ SplashTextOn("Charged Notifcation Remover", "Status: Moving..", 250, 40, -1, -1, 4, "Verdana", 10, 400)
;~ Sleep(100)

;~ SplashTextOn("Charged Notifcation Remover", "Status: Done!", 250, 40, -1, -1, 4, "Verdana", 10, 400)
;~ Sleep(500)
;~ SplashOff()
;~ ShellExecute(@ScriptDir & "\finished_apks", "", "", "open", @SW_SHOW)
;~ MsgBox(0, "Removed Charged Notification", "Thanks for using this tool, coded by: broodplank1337 @ XDA")

;~ Exit

