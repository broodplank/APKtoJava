;No tray icon
#NoTrayIcon

#region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=apktojavaicon_trans.ico
#AutoIt3Wrapper_Outfile=APKtoJava.exe
#AutoIt3Wrapper_Outfile_x64=APKtoJava_x64.exe
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Res_Description=©2012 broodplank.net
#AutoIt3Wrapper_Res_Fileversion=0.0.2.0
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Obfuscator=y
#endregion ;**** Directives created by AutoIt3Wrapper_GUI ****

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
#include <ComboConstants.au3>
#include <Constants.au3>



EnvSet("path", EnvGet("path") & ";" & @ScriptDir)
;Include splash image in exe
FileInstall("splash.jpg", @TempDir & "\splash.jpg", 1)

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
If Not FileExists("tools") Then
	MsgBox(16, "APK to Java", "Missing tools folder, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists("tools\7za.exe") Then
	MsgBox(16, "APK to Java", "Missing 7za.exe, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists("tools\aapt.exe") Then
	MsgBox(16, "APK to Java", "Missing aapt.exe, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists("tools\apktool.jar") Then
	MsgBox(16, "APK to Java", "Missing apktool.jar, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists("tools\baksmali-1.4.0.jar") Then
	MsgBox(16, "APK to Java", "Missing baksmali-1.4.0.jar, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists("tools\jd-gui.exe") Then
	MsgBox(16, "APK to Java", "Missing jd-gui.exe, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists("tools\lib") Then
	MsgBox(16, "APK to Java", "Missing tools\lib folder, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists("tools\dex2jar.bat") Then
	MsgBox(16, "APK to Java", "Missing dex2jar.bat, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists("tools\setclasspath.bat") Then
	MsgBox(16, "APK to Java", "Missing setclasspath.bat, please reinstall the application and try again!")
	Exit
EndIf
If Not FileExists("tools\jad.exe") Then
	MsgBox(16, "APK to Java", "Missing jad.exe, please reinstall the application and try again!")
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


;Declare Globals
Global $getpath_apkjar, $getpath_classes, $getpath_outputdir, $log, $decompile_eclipse, $decompile_resource, $decompile_source_java, $decompile_source_smali, $failparam, $javaeror, $resourcerror


;StringSearchInFile func
Func _StringSearchInFile($file, $qry)
	_RunDos("find /n /i " & Chr(34) & $qry & Chr(34) & " " & Chr(34) & $file & Chr(34) & " >> " & @TempDir & "\results.txt")
	If Not @error Then
		FileSetAttrib(@TempDir & "\results.txt", "-N+H+T", 0)
		$CHARS = FileGetSize(@TempDir & "\results.txt")
		Return FileRead(@TempDir & "\results.txt", $CHARS) & @CRLF
	EndIf
EndFunc   ;==>_StringSearchInFile


;ExtractAPK
Func _ExtractAPK($apkfile)
	GUICtrlSetData($log, "APK to Java RC2 Initialized...." & @CRLF & "------------------------------------------" & @CRLF)
	FileDelete(@ScriptDir & "\tools\classes.dex")

	_AddLog("- Extracting APK...")
	FileCopy($getpath_apkjar, @ScriptDir & "\tools\" & _GetExtProperty($getpath_apkjar, 0))
	FileCopy(@ScriptDir & "\tools\" & _GetExtProperty($getpath_apkjar, 0), @ScriptDir & "\tools\" & _GetExtProperty($getpath_apkjar, 0) & ".zip", 1)
	RunWait(@ComSpec & " /c " & "7za.exe x -y " & _GetExtProperty($getpath_apkjar, 0) & ".zip *.dex", @ScriptDir & "\tools", @SW_HIDE)
	_AddLog("- Extracting APK Done!")

	If GUICtrlRead($decompile_resource) = 1 Then _DecompileResource()

	If FileExists(@ScriptDir & "\tools\classes.dex") Then
		If GUICtrlRead($decompile_source_smali) = 1 Then _DecompileSmali()
		If GUICtrlRead($decompile_source_java) = 1 Then _DecompileJava()
	Else
		$failparam = "noclasses"
		_AddLog(@CRLF & "ERROR: No classes.dex file found! Aborting..." & @CRLF)
	EndIf

	If GUICtrlRead($decompile_eclipse) = 1 Then _MakeEclipse()
EndFunc   ;==>_ExtractAPK


;Decompile Smali
Func _DecompileSmali()
	If FileExists(@ScriptDir & "\tools\smalicode") Then DirRemove(@ScriptDir & "\tools\smalicode", 1)

	_AddLog("- Decompiling to Smali code...")
	RunWait(@ComSpec & " /c " & "java -jar baksmali-1.4.0.jar -o smalicode/ classes.dex", @ScriptDir & "\tools", @SW_HIDE)
	_AddLog("- Decompiling to Smali Done!")

	_AddLog("- Copying to output dir...")
	DirCopy(@ScriptDir & "\tools\smalicode", $getpath_outputdir & "\smalicode", 1)
	_AddLog("- Copying to output dir Done!")
EndFunc   ;==>_DecompileSmali


;Decompile Java
Func _DecompileJava()

	$options_app_jad_read = IniRead(@ScriptDir & "\config.ini", "options", "usejad", "0")
	$options_app_jdgui_read = IniRead(@ScriptDir & "\config.ini", "options", "usejdgui", "1")

	_AddLog("- Converting classes.dex to classes-dex2jar.jar...")

	If FileExists(@ScriptDir & "\tools\classes-dex2jar.src.zip") Then FileDelete(@ScriptDir & "\tools\classes-dex2jar.src.zip")

	RunWait(@ScriptDir & "\tools\dex2jar.bat" & " classes.dex", @ScriptDir & "\tools", @SW_HIDE)

	If $options_app_jdgui_read = "1" Then

		Run(@ScriptDir & "\tools\jd-gui.exe " & Chr(34) & @ScriptDir & "\tools\classes-dex2jar.jar" & Chr(34), @ScriptDir & "\tools", @SW_SHOW)

		WinWaitActive("Java Decompiler - classes-dex2jar.jar", "")
		WinSetTrans("Java Decompiler - classes-dex2jar.jar", "", 0)

		ControlSend("Java Decompiler - classes-dex2jar.jar", "", "", "^!s")
		WinWaitActive("Save")
		WinSetTrans("Save", "", 0)

		$CLIPSAVE = ClipGet()
		ClipPut(@ScriptDir & "\tools\classes-dex2jar.src.zip")
		ControlSend("Save", "", "", "^v")

		ClipPut($CLIPSAVE)
		ControlSend("Save", "", "", "{enter}")
		Sleep(25)

		WinSetTrans("Save All Sources", "", 0)
		WinWaitClose("Save All Sources", "")

		ProcessClose("jd-gui.exe")

		_AddLog("- Generating Java Code Done!")

		_AddLog("- Extracting Java Code....")
		RunWait(@ComSpec & " /c " & "7za.exe x -y classes-dex2jar.src.zip -ojavacode", @ScriptDir & "\tools", @SW_HIDE)

		_AddLog("- Extracting Java Code Done!")


		_AddLog("- Copying Java Code to output dir....")
		DirCopy(@ScriptDir & "\tools\javacode", $getpath_outputdir & "\javacode", 1)

		_AddLog("- Copying Java Code Done!")

	EndIf


	If $options_app_jad_read = "1" Then

		If FileExists(@ScriptDir & "\tools\classcode") Then DirRemove(@ScriptDir & "\tools\classcode", 1)

		FileMove(@ScriptDir & "\tools\classes-dex2jar.jar", @ScriptDir & "\tools\classes-dex2jar.jar.zip", 1)
		_AddLog("- Extracting class files...")
		RunWait(@ComSpec & " /c " & "7za.exe x -y classes-dex2jar.jar.zip -oclasscode", @ScriptDir & "\tools", @SW_HIDE)
		_AddLog("- Extracting class files Done!")

		_AddLog("- Converting class to java files..." & @CRLF & "(This may take several minutes...)")
		$runjad = Run(@ComSpec & " /c " & "jad -o -r -sjava -dclasscodeout classcode/**/**/**/**/**/*.class", @ScriptDir & "\tools", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)

		Local $line
		While 1
			$line = StderrRead($runjad)
			If @error Then ExitLoop
			ConsoleWrite($line)
		WEnd

		_AddLog("- Converting class to java done!")
		_AddLog("- Copying Java Code to output dir....")
		DirCopy(@ScriptDir & "\tools\classcodeout", $getpath_outputdir & "\javacode", 1)
		_AddLog("- Copying Java Code Done!")


	EndIf


EndFunc   ;==>_DecompileJava


;Decompile Resources
Func _DecompileResource()


	If FileExists(@ScriptDir & "\tools\resource") Then DirRemove(@ScriptDir & "\tools\resource")
	_AddLog("- Decompiling Resources...")

	RunWait(@ComSpec & " /c " & "java -jar " & Chr(34) & @ScriptDir & "\tools\apktool.jar" & Chr(34) & " d -s -f " & _GetExtProperty($getpath_apkjar, 0) & " " & Chr(34) & @ScriptDir & "\tools\resource" & Chr(34), @ScriptDir & "\tools", @SW_HIDE)
	_AddLog("- Decompiling Resources Done!")

	_AddLog("- Copying to output dir...")
	DirCopy(@ScriptDir & "\tools\resource", $getpath_outputdir & "\resource", 1)
	_AddLog("- Copying to output dir Done!")

EndFunc   ;==>_DecompileResource


;Make Eclipse Project
Func _MakeEclipse()
	_AddLog(@CRLF & "- Making Eclipse Project...")
	If FileExists($getpath_outputdir & "\eclipseproject") Then DirRemove($getpath_outputdir & "\eclipseproject", 1)

	_AddLog("- Extracting Example Project..")
	RunWait(@ComSpec & " /c " & "7za.exe x -y -o" & $getpath_outputdir & "\eclipseproject eclipseproject.zip * ", @ScriptDir & "\tools", @SW_HIDE)

	_AddLog("- Importing AndroidManifest.xml...")
	FileCopy($getpath_outputdir & "\resource\AndroidManifest.xml", $getpath_outputdir & "\eclipseproject\AndroidManifest.xml", 1)

	_AddLog("- Importing Resources...")
	DirCopy($getpath_outputdir & "\resource\res", $getpath_outputdir & "\eclipseproject\res", 1)

	_AddLog("- Setting Project Name..")
	Local $namearray
	$namearray = StringRegExp(_StringSearchInFile($getpath_outputdir & "\eclipseproject\AndroidManifest.xml", "package"), "package=" & Chr(34) & "(.*?)" & Chr(34), 1, 1)
	_FileWriteToLine($getpath_outputdir & "\eclipseproject\.project", 3, "        <name>" & $namearray & "</name>")

	_AddLog("- Setting Target SDK...")
	Local $tarsdkarray
	$tarsdkarray = StringRegExp(_StringSearchInFile($getpath_outputdir & "\eclipseproject\AndroidManifest.xml", "android:targetSdkVersion"), "android:targetSdkVersion=" & Chr(34) & "(.*?)" & Chr(34), 1, 1)
	$write = _FileWriteToLine($getpath_outputdir & "\eclipseproject\project.properties", 14, "target=android-" & $tarsdkarray, 1)

	_AddLog("- Importing Java Sources...")
	DirCopy($getpath_outputdir & "\javacode\com", $getpath_outputdir & "\eclipseproject\src\com", 1)
	_AddLog("- Making Eclipse Project Done!")

EndFunc   ;==>_MakeEclipse




;AddLog function
Func _AddLog($string)
	$CurrentLog = GUICtrlRead($log)
	$NewLog = $CurrentLog & @CRLF & $string
	GUICtrlSetData($log, $NewLog)
EndFunc   ;==>_AddLog


Func Restart()
	Run(@ScriptDir & "\APKtoJava.exe")
EndFunc   ;==>Restart



$gui = GUICreate("APK to Java Release Candidate 2  -  by broodplank", 550, 470)

$filemenu = GUICtrlCreateMenu("&File")
$filemenu_restart = GUICtrlCreateMenuItem("&Restart", $filemenu, 1)
$filemenu_exit = GUICtrlCreateMenuItem("E&xit", $filemenu, 2)

$optionsmenu = GUICtrlCreateMenu("&Options")
$optionsmenu_preferences = GUICtrlCreateMenuItem("&Preferences", $optionsmenu, 1)

$helpmenu = GUICtrlCreateMenu("&Help")
$helpmenu_help = GUICtrlCreateMenuItem("&Open Help File", $helpmenu, 1)
$helpmenu_about = GUICtrlCreateMenuItem("&About", $helpmenu, 2)
$helpmenu_donate = GUICtrlCreateMenuItem("&Donate", $helpmenu, 2)


GUISetFont(8, 8, 0, "Verdana")

GUICtrlCreateLabel("Log:", 305, 5)
$log = GUICtrlCreateEdit("APK to Java RC2 Initialized...." & @CRLF & "------------------------------------------" & @CRLF, 305, 22, 240, 420, BitOR($WS_VSCROLL, $ES_AUTOVSCROLL, $ES_MULTILINE, $ES_READONLY))

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
$decompile_eclipse = GUICtrlCreateCheckbox("Convert output to an Eclipse project", 15, 370)

$start_process = GUICtrlCreateButton("Start Decompilation Process!", 5, 400, 290, 25)

$copyright = GUICtrlCreateLabel("©2012 broodplank.net - All Rights Reserved", 5, 433)
GUICtrlSetStyle($copyright, $WS_DISABLED)

GUISetState()

While 1

	$msg = GUIGetMsg()

	Select

		Case $msg = $gui_event_close Or $msg = $filemenu_exit
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
				GUICtrlSetData($destination, "")
			Else
				GUICtrlSetData($destination, $getpath_outputdir)
				If StringInStr($getpath_outputdir, Chr(32), 1) Then
					Dim $msgbox
					$msgbox = MsgBox(49, "APK To Java Warning", "A space has been found in your destination directory." & @CRLF & "This can lead to an invalid output." & @CRLF & "Do you want to continue?")
					If $msgbox = 1 Then
						GUICtrlSetData($destination, $getpath_outputdir)
					ElseIf $msgbox = 2 Then
						GUICtrlSetData($destination, "")
					EndIf
				EndIf
			EndIf

		Case $msg = $decompile_eclipse And BitAND(GUICtrlRead($decompile_eclipse), $GUI_CHECKED) = $GUI_CHECKED
			GUICtrlSetState($decompile_resource, $GUI_CHECKED)
			GUICtrlSetState($decompile_resource, $GUI_DISABLE)
			GUICtrlSetState($decompile_source_java, $GUI_CHECKED)
			GUICtrlSetState($decompile_source_java, $GUI_DISABLE)

		Case $msg = $decompile_eclipse And BitAND(GUICtrlRead($decompile_eclipse), $GUI_UnChecked) = $GUI_UnChecked
			GUICtrlSetState($decompile_resource, $GUI_UnChecked)
			GUICtrlSetState($decompile_resource, $GUI_ENABLE)
			GUICtrlSetState($decompile_source_java, $GUI_UnChecked)
			GUICtrlSetState($decompile_source_java, $GUI_ENABLE)

		Case $msg = $start_process

			If GUICtrlRead($file) = "" Then
				If GUICtrlRead($filedex) = "" Then
					MsgBox(0, "APK to Java", "You haven't selected an apk/jar or classes.dex file!")
				EndIf

			ElseIf GUICtrlRead($destination) = "" Then
				MsgBox(0, "APK to Java", "You haven't selected an output directory!")

			Else

				_ExtractAPK(_GetExtProperty($getpath_apkjar, 0))

				If $failparam = "" Then
					_AddLog(@CRLF & "The decompilation process is completed!")
					_RunDos("explorer " & $getpath_outputdir)
				ElseIf $failparam = "noclasses" Then
					_AddLog(@CRLF & "Decompilation has been aborted due to missing classes.dex file!")
				ElseIf $javaeror = 1 Then
					_AddLog(@CRLF & "Making Eclipse project failed because no java decompilation has been selected!")
				ElseIf $resourcerror = 1 Then
					_AddLog(@CRLF & "Making Eclipse project failed because no resources decompilation has been selected!")
				EndIf

				_AddLog(@CRLF & "- Cleaning Up...")
				DirRemove(@ScriptDir & "\tools\smalicode", 1)
				DirRemove(@ScriptDir & "\tools\javacode", 1)
				DirRemove(@ScriptDir & "\tools\resource", 1)
				DirRemove(@ScriptDir & "\tools\classcode", 1)
				DirRemove(@ScriptDir & "\tools\classcodeout", 1)
				FileDelete(@ScriptDir & "\tools\" & _GetExtProperty($getpath_apkjar, 0) & ".zip")
				FileDelete(@ScriptDir & "\tools\classes-dex2jar.jar")
				FileDelete(@ScriptDir & "\tools\classes-dex2jar.src.zip")
				FileDelete(@ScriptDir & "\tools\classes-dex2jar.jar.zip")
				FileDelete(@ScriptDir & "\tools\classes.dex")
				FileDelete(@ScriptDir & "\tools\" & _GetExtProperty($getpath_apkjar, 0))
				_AddLog("- Cleaning Done!" & @CRLF)

			EndIf


		Case $msg = $helpmenu_help
			_RunDos("start " & @ScriptDir & "\help.chm")

		Case $msg = $helpmenu_about
			MsgBox(0, "APK to Java -- About", "About APK to Java" & @CRLF & @CRLF & "APK to Java" & @CRLF & "Version: RC2" & @CRLF & "Author: broodplank(1337)" & @CRLF & "Site: www.broodplank.net")

		Case $msg = $helpmenu_donate
			_RunDos("start http://forum.xda-developers.com/donatetome.php?u=4354408")

		Case $msg = $optionsmenu_preferences
			_PreferencesMenu()

		Case $msg = $filemenu_restart
			If ProcessExists("APKtoJava.exe") Then
				OnAutoItExitRegister("Restart")
				Exit
			EndIf



	EndSelect

WEnd


Func _PreferencesMenu()

	$optionsGUI = GUICreate("APK to Java Preferences", 260, 165, -1, -1, -1, BitOR($WS_EX_TOOLWINDOW, $WS_EX_MDICHILD), $gui)
	GUISetBkColor(0xefefef, $optionsGUI)

	GUICtrlCreateGroup("Java Generation Preferences:", 5, 5, 250, 65)

	$options_app_jdgui = GUICtrlCreateRadio("Use JD-GUI to make Java Sources", 15, 25)
	$options_app_jdgui_read = IniRead(@ScriptDir & "\config.ini", "options", "usejdgui", "")
	If $options_app_jdgui_read = 1 Then
		GUICtrlSetState($options_app_jdgui, $GUI_CHECKED)
	Else
		GUICtrlSetState($options_app_jdgui, $GUI_UnChecked)
	EndIf


	$options_app_jad = GUICtrlCreateRadio("Use JAD to make Java Sources", 15, 45)
	$options_app_jad_read = IniRead(@ScriptDir & "\config.ini", "options", "usejad", "")
	If $options_app_jad_read = 1 Then
		GUICtrlSetState($options_app_jad, $GUI_CHECKED)
	Else
		GUICtrlSetState($options_app_jad, $GUI_UnChecked)
	EndIf

	GUICtrlCreateGroup("Heapsize for decompiling:", 5, 75, 250, 50)
	GUICtrlCreateLabel("Heapsize:", 15, 98)
	$options_app_heapsize_read = IniRead(@ScriptDir & "\config.ini", "options", "heapsize", "512")
	$options_app_heapsize = GUICtrlCreateCombo("", 80, 95, 100, 20, $CBS_DROPDOWNLIST)
	GUICtrlSetData($options_app_heapsize, "32|64|128|256|512|1024|2048|4096", $options_app_heapsize_read)
	GUICtrlCreateLabel("MB", 190, 98)

	$options_ok_button = GUICtrlCreateButton("Ok", 5, 140, 80, 20)
	$options_cancel_button = GUICtrlCreateButton("Cancel", 90, 140, 80, 20)
	$options_apply_button = GUICtrlCreateButton("Apply", 175, 140, 80, 20)


	GUISetState(@SW_SHOW, $optionsGUI)
	GUISwitch($optionsGUI)

	While 1
		$msg2 = GUIGetMsg()

		Select

			Case $msg2 = $gui_event_close Or $msg2 = $options_cancel_button
				GUIDelete($optionsGUI)
				ExitLoop


			Case $msg2 = $options_ok_button
				If GUICtrlRead($options_app_jdgui) = 1 Then
					IniWrite(@ScriptDir & "\config.ini", "options", "usejdgui", "1")
					IniWrite(@ScriptDir & "\config.ini", "options", "usejad", "0")
				ElseIf GUICtrlRead($options_app_jdgui) = 4 Then
					IniWrite(@ScriptDir & "\config.ini", "options", "usejdgui", "0")
					IniWrite(@ScriptDir & "\config.ini", "options", "usejad", "1")
				EndIf

				If GUICtrlRead($options_app_jad) = 1 Then
					IniWrite(@ScriptDir & "\config.ini", "options", "usejad", "1")
					IniWrite(@ScriptDir & "\config.ini", "options", "usejdgui", "0")
				ElseIf GUICtrlRead($options_app_jad) = 4 Then
					IniWrite(@ScriptDir & "\config.ini", "options", "usejad", "0")
					IniWrite(@ScriptDir & "\config.ini", "options", "usejdgui", "1")
				EndIf

				$heapsize = GUICtrlRead($options_app_heapsize)
				IniWrite(@ScriptDir & "\config.ini", "options", "heapsize", $heapsize)
				_FileWriteToLine(@ScriptDir & "\tools\dex2jar.bat", "23", "java -Xms" & $heapsize & "m -cp " & Chr(34) & "%CLASSPATH%" & Chr(34) & " " & Chr(34) & "com.googlecode.dex2jar.tools.Dex2jarCmd" & Chr(34) & " %*", 1)
				GUIDelete($optionsGUI)
				ExitLoop


			Case $msg2 = $options_apply_button

				If GUICtrlRead($options_app_jdgui) = 1 Then
					IniWrite(@ScriptDir & "\config.ini", "options", "usejdgui", "1")
					IniWrite(@ScriptDir & "\config.ini", "options", "usejad", "0")
				ElseIf GUICtrlRead($options_app_jdgui) = 4 Then
					IniWrite(@ScriptDir & "\config.ini", "options", "usejdgui", "0")
					IniWrite(@ScriptDir & "\config.ini", "options", "usejad", "1")
				EndIf

				If GUICtrlRead($options_app_jad) = 1 Then
					IniWrite(@ScriptDir & "\config.ini", "options", "usejad", "1")
					IniWrite(@ScriptDir & "\config.ini", "options", "usejdgui", "0")
				ElseIf GUICtrlRead($options_app_jad) = 4 Then
					IniWrite(@ScriptDir & "\config.ini", "options", "usejad", "0")
					IniWrite(@ScriptDir & "\config.ini", "options", "usejdgui", "1")
				EndIf

				$heapsize = GUICtrlRead($options_app_heapsize)
				IniWrite(@ScriptDir & "\config.ini", "options", "heapsize", $heapsize)
				_FileWriteToLine(@ScriptDir & "\tools\dex2jar.bat", "23", "java -Xms" & $heapsize & "m -cp " & Chr(34) & "%CLASSPATH%" & Chr(34) & " " & Chr(34) & "com.googlecode.dex2jar.tools.Dex2jarCmd" & Chr(34) & " %*", 1)

				GUICtrlSetStyle($options_apply_button, $WS_DISABLED)

		EndSelect


	WEnd


EndFunc   ;==>_PreferencesMenu