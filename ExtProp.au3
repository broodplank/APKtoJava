Func _GetExtProperty($sPath, $iProp)
   Local $iExist, $sFile, $sDir, $oShellApp, $oDir, $oFile, $aProperty, $sProperty
   $iExist = FileExists($sPath)
   If $iExist = 0 Then
      SetError(1)
      Return 0
   Else
      $sFile = StringTrimLeft($sPath, StringInStr($sPath, "\", 0, -1))
      $sDir = StringTrimRight($sPath, (StringLen($sPath) - StringInStr($sPath, "\", 0, -1)))
      $oShellApp = ObjCreate ("shell.application")
      $oDir = $oShellApp.NameSpace ($sDir)
      $oFile = $oDir.Parsename ($sFile)
      If $iProp = -1 Then
         Local $aProperty[35]
         For $i = 0 To 34
            $aProperty[$i] = $oDir.GetDetailsOf ($oFile, $i)
         Next
         Return $aProperty
      Else
         $sProperty = $oDir.GetDetailsOf ($oFile, $iProp)
         If $sProperty = "" Then
            Return 0
         Else   
            Return $sProperty
         EndIf
      EndIf
   EndIf
EndFunc   ;==>_GetExtProperty