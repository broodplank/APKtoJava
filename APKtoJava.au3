#region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=apktojavaicon_trans.ico
#AutoIt3Wrapper_Outfile=APKtoJava.exe
#AutoIt3Wrapper_Outfile_x64=APKtoJava_x64.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Res_Description=©2012 broodplank.net
#AutoIt3Wrapper_Res_Fileversion=0.0.0.9
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Obfuscator=y
#endregion ;**** Directives created by AutoIt3Wrapper_GUI ****

;No tray icon
#NoTrayIcon

;Match window titles by any substring matched
Opt("WinTitleMatchMode", 2)


;Includes
#include <Process.au3>
#include <File.au3>
#include <WindowsConstants.au3>
#include <GuiConstantsEx.au3>
#include <ExtProp.au3>
#include <WinAPI.au3>
#include <EditConstants.au3>

;Include splash image in exe
FileInstall("E:\apktojava\splash.jpg", @TempDir & "\splash.jpg", 1)

;Show splash
$splash = GUICreate("Loading...", 400, 100, -1, -1, $WS_POPUPWINDOW)
GUICtrlCreatePic(@TempDir & "\splash.jpg", 0, 0, 400, 100)
WinSetTrans($splash, "", 0)
GUISetState(@SW_SHOW, $splash)
For $i = 0 To 255 Step 6
	WinSetTrans($splash, "", $i)
	Sleep(1)
Next

;Make jd-gui.cfg (ini)
FixConfig()

;Check for files
If Not FileExists(@ScriptDir & "\tools") Then
	MsgBox(16, "APK to Java", "Missing tools folder, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists(@ScriptDir & "\tools\7za.exe") Then
	MsgBox(16, "APK to Java", "Missing 7za.exe, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists(@ScriptDir & "\tools\apktool.jar") Then
	MsgBox(16, "APK to Java", "Missing apktool.jar, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists(@ScriptDir & "\tools\baksmali-1.4.0.jar") Then
	MsgBox(16, "APK to Java", "Missing baksmali-1.4.0.jar, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists(@ScriptDir & "\tools\jd-gui.exe") Then
	MsgBox(16, "APK to Java", "Missing jd-gui.exe, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists(@ScriptDir & "\tools\lib") Then
	MsgBox(16, "APK to Java", "Missing tools\lib folder, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists(@ScriptDir & "\tools\deosmali.bat") Then
	MsgBox(16, "APK to Java", "Missing deosmali.bat, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists(@ScriptDir & "\tools\dex2jar.bat") Then
	MsgBox(16, "APK to Java", "Missing dex2jar.bat, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists(@ScriptDir & "\tools\extractapk.bat") Then
	MsgBox(16, "APK to Java", "Missing extractapk.bat, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists(@ScriptDir & "\tools\extractjava.bat") Then
	MsgBox(16, "APK to Java", "Missing extractjava.bat, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists(@ScriptDir & "\tools\extractres.bat") Then
	MsgBox(16, "APK to Java", "Missing extractres.bat, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists(@ScriptDir & "\tools\setclasspath.bat") Then
	MsgBox(16, "APK to Java", "Missing setclasspath.bat, please reinstall the application and try again!")
	Exit
EndIf

Sleep(500)
GUIDelete($splash)

;Write INI
Func FixConfig()
	Sleep(500)
	$localdir = String(@ScriptDir & "\tools\")
	If FileExists(@ScriptDir & "\tools\jd-gui.cfg") Then FileDelete(@ScriptDir & "\tools\jd-gui.cfg")
	IniWrite(@ScriptDir & "\tools\jd-gui.cfg", "RecentDirectories", "LoadPath", StringReplace($localdir, "\", "\\", 0))
	IniWrite(@ScriptDir & "\tools\jd-gui.cfg", "RecentDirectories", "SavePath", StringReplace($localdir, "\", "\\", 0))
	IniWrite(@ScriptDir & "\tools\jd-gui.cfg", "Manifest", "Version", "2")
	IniWrite(@ScriptDir & "\tools\jd-gui.cfg", "Update", "CurrentVersion", "0.3.3")
	IniWrite(@ScriptDir & "\tools\jd-gui.cfg", "RecentFiles", "Path0", StringReplace($localdir, "\", "\\", 0) & "classes_dex2jar.jar")
EndFunc   ;==>FixConfig

Global $getpath_apkjar, $getpath_classes, $getpath_outputdir, $log, $decompile_eclipse, $decompile_resource, $decompile_source_java, $decompile_source_smali, $failparam


GUICreate("APK to Java v0.9 BETA (by broodplank)", 550, 450)

GUISetFont(8, 8, 0, "Verdana")

GUICtrlCreateLabel("Log:", 305, 5)
$log = GUICtrlCreateEdit("APK to Java v0.9 BETA Initialized...." & @CRLF & "------------------------------------------" & @CRLF, 305, 22, 240, 420, BitOR($WS_VSCROLL, $ES_AUTOVSCROLL, $ES_MULTILINE, $ES_WANTRETURN, $ES_READONLY));, $ES_READONLY))

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
$decompile_eclipse = GUICtrlCreateCheckbox("Convert the output to an Eclipse project (BETA)", 15, 370)

$start_process = GUICtrlCreateButton("Start Process!", 5, 400, 105, 25)
$about_button = GUICtrlCreateButton("Help / About", 115, 400, 105, 25)
$exit_button = GUICtrlCreateButton("Exit", 225, 400, 70, 25)

$copyright = GUICtrlCreateLabel("©2012 broodplank.net", 5, 435)
GUICtrlSetStyle($copyright, $WS_DISABLED)


Func _StringSearchInFile($file, $qry)
	_RunDos("find /n /i """ & $qry & """ " & $file & " >> " & @TempDir & "\results.txt")
	If Not @error Then
		FileSetAttrib(@TempDir & "\results.txt", "-N+H+T", 0)
		$CHARS = FileGetSize(@TempDir & "\results.txt")
		Return FileRead(@TempDir & "\results.txt", $CHARS) & @CRLF
	EndIf
EndFunc   ;==>_StringSearchInFile


Func _ExtractAPK($apkfile)
	GUICtrlSetData($log, "APK to Java v0.9 BETA Initialized...." & @CRLF & "------------------------------------------" & @CRLF)
	FileDelete(@ScriptDir & "\tools\classes.dex")
	_AddLog("- Extracting APK...")
	FileCopy($getpath_apkjar, @ScriptDir & "\tools\" & _GetExtProperty($getpath_apkjar, 0))
	RunWait(@ScriptDir & "\tools\extractapk.bat " & _GetExtProperty($getpath_apkjar, 0), "", @SW_HIDE)
	If GUICtrlRead($decompile_resource) = 1 Then _DecompileResource()
	If FileExists(@ScriptDir & "\tools\classes.dex") Then
		_AddLog("- Extracting APK Done!")
		If GUICtrlRead($decompile_source_smali) = 1 Then _DecompileSmali()
		If GUICtrlRead($decompile_source_java) = 1 Then _DecompileJava()
		If GUICtrlRead($decompile_eclipse) = 1 Then _MakeEclipse()


	Else
		$failparam = "noclasses"
		_AddLog(@CRLF & "ERROR: No classes.dex file found! Aborting..." & @CRLF)
	EndIf
EndFunc   ;==>_ExtractAPK

Func _DecompileSmali()
	If FileExists(@ScriptDir & "\tools\smalicode") Then DirRemove(@ScriptDir & "\tools\smalicode", 1)
	_AddLog("- Decompiling to Smali code...")
	RunWait(@ScriptDir & "\tools\deosmali.bat", "", @SW_HIDE)
	_AddLog("- Decompiling to Smali Done!")
	_AddLog("- Copying to output dir...")
	DirCopy(@ScriptDir & "\tools\smalicode", $getpath_outputdir & "\smalicode", 1)
	_AddLog("- Copying to output dir Done!")
EndFunc   ;==>_DecompileSmali

Func _DecompileJava()
	_AddLog("- Converting classes.dex to classes-dex2jar.jar...")
	If FileExists(@ScriptDir & "\tools\classes-dex2jar.src.zip") Then FileDelete(@ScriptDir & "\tools\classes-dex2jar.src.zip")
	RunWait(@ScriptDir & "\tools\dex2jar.bat classes.dex", "", @SW_HIDE)
	Sleep(250)
	MsgBox(0, "APK To Java", "Because controlling JD-GUI trough this application didn't work" & @CRLF & "You have to perform the manual action listed below to continue" & @CRLF & @CRLF & "In JD-GUI, press Control + Alt + S to open the save dialog" & @CRLF & "The script will take it from there.")
	Run(@ScriptDir & "\tools\jd-gui.exe " & Chr(34) & @ScriptDir & "\tools\classes-dex2jar.jar" & Chr(34), @ScriptDir, @SW_SHOW)
	WinWaitActive("Save")
	Sleep(100)
	ControlSend("Save", "", "", "classes-dex2jar.src.zip")
	Sleep(200)
	ControlSend("Save", "", "", "{enter}")
	Sleep(200)

	WinWaitClose("Save All Sources", "")

	ProcessClose("jd-gui.exe")

	Sleep(100)
	_AddLog("- Generating Java Code Done!")
	_AddLog("- Extracting Java Code....")
	RunWait(@ScriptDir & "\tools\extractjava.bat", "", @SW_HIDE)
	_AddLog("- Extracting Java Code Done!")
	Sleep(200)
	_AddLog("- Copying Java Code to output dir....")
	DirCopy(@ScriptDir & "\tools\javacode", $getpath_outputdir & "\javacode", 1)
	_AddLog("- Copying Java Code Done!")
EndFunc   ;==>_DecompileJava


Func _DecompileResource()
	If FileExists(@ScriptDir & "\tools\resource") Then DirRemove(@ScriptDir & "\tools\resource")
	_AddLog("- Decompiling Resources...")
	ConsoleWrite(@ScriptDir & "\tools\extractres.bat " & Chr(34) & @ScriptDir & "\tools\" & _GetExtProperty($getpath_apkjar, 0) & Chr(34))
	RunWait(@ScriptDir & "\tools\extractres.bat " & Chr(34) & @ScriptDir & "\tools\" & _GetExtProperty($getpath_apkjar, 0) & Chr(34), "", @SW_HIDE)
	_AddLog("- Decompiling Resources Done!")
	_AddLog("- Copying to output dir...")
	DirCopy(@ScriptDir & "\tools\resource", $getpath_outputdir & "\resource", 1)
	_AddLog("- Copying to output dir Done!")
EndFunc   ;==>_DecompileResource

Func _MakeEclipse()
	_AddLog(@CRLF & "- Making Eclipse Project...")
	If FileExists($getpath_outputdir & "\eclipseproject") Then DirRemove($getpath_outputdir & "\eclipseproject", 1)
	_AddLog("- Extracting Example Project..")
	RunWait(@ScriptDir & "\tools\extracteclipse.bat " & $getpath_outputdir, "", @SW_HIDE)
	_AddLog("- Importing AndroidManifest.xml...")
	FileCopy($getpath_outputdir & "\resource\AndroidManifest.xml", $getpath_outputdir & "\eclipseproject\AndroidManifest.xml", 1)
	_AddLog("- Importing Resources...")
	DirCopy($getpath_outputdir & "\resource\res", $getpath_outputdir & "\eclipseproject\res", 1)
	_AddLog("- Setting Project Name..")

	;Read package name from Manifest
	$namearray = StringRegExp(_StringSearchInFile($getpath_outputdir & "\eclipseproject\AndroidManifest.xml", "package"), "package=" & Chr(34) & "(.*?)" & Chr(34), 1, 1)
	_FileWriteToLine($getpath_outputdir & "\eclipseproject\.project", 3, "        <name>" & $namearray[0] & "</name>")

	_AddLog("- Setting Target SDK...")
	;Read targetsdk value from Manifest
	$tarsdkarray = StringRegExp(_StringSearchInFile($getpath_outputdir & "\eclipseproject\AndroidManifest.xml", "android:targetSdkVersion"), "android:targetSdkVersion=" & Chr(34) & "(.*?)" & Chr(34), 1, 1)
	$write = _FileWriteToLine($getpath_outputdir & "\eclipseproject\project.properties", 14, "target=android-" & $tarsdkarray[0], 1)

	_AddLog("- Importing Java Sources...")
	DirCopy($getpath_outputdir & "\javacode\com", $getpath_outputdir & "\eclipseproject\src\com", 1)
	_AddLog("- Making Eclipse Project Done!")
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
			$getpath_apkjar = FileOpenDialog("APK to Java, please select an apk/jar file", "", "APK Files (*.apk)|JAR Files (*.jar)", 1, "")
			If $getpath_apkjar = "" Then
				;
			Else
				GUICtrlSetData($file, _GetExtProperty($getpath_apkjar, 0))
				If GUICtrlRead($filedex) <> "" Then GUICtrlSetData($filedex, "")
			EndIf

		Case $msg = $filebrowsedex
			$getpath_classes = FileOpenDialog("APK to Java, please select a classes.dex file", "", "DEX Files (*.dex)", 1, "classes.dex")
			If $getpath_classes = "" Then
				;
			Else
				GUICtrlSetData($filedex, _GetExtProperty($getpath_classes, 0))
				If GUICtrlRead($file) <> "" Then GUICtrlSetData($file, "")
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
				If $failparam = "" Then
					_AddLog("The decompilation process is completed!")
				ElseIf $failparam = "noclasses" Then
					_AddLog("Decompilation has been aborted due to missing classes.dex file!")
				EndIf

			EndIf


		Case $msg = $about_button
			_RunDos("start " & @ScriptDir & "\help.chm")


	EndSelect

WEnd