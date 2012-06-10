!include "MUI.nsh"
!include "FileFunc.nsh"
!include "TextFunc.nsh"
!include "WordFunc.nsh"
!include "LogicLib.nsh"
!include "nsDialogs.nsh"

; Include the project header file generated by the nsis-maven-plugin
!include "..\..\..\..\target\project.nsh"
!include "..\..\..\..\target\extra.nsh"

!define REG_KEY_UNINSTALL "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PROJECT_NAME}"
!define REG_KEY_SOFTWARE "SOFTWARE\${PROJECT_NAME}"

RequestExecutionLevel admin

Name "${PROJECT_NAME}"
InstallDir "$PROGRAMFILES\${PROJECT_NAME}"

;Get install folder from registry for updates
InstallDirRegKey HKCU "${REG_KEY_SOFTWARE}" ""

SetCompressor /SOLID lzma
SetCompressorDictSize 32

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\UMS.exe"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\win.bmp"

!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Create Desktop Shortcut"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION CreateDesktopShortcut

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
Page custom SetMem SetMemLeave ;Custom page
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

ShowUninstDetails show

; Offer to install AviSynth 2.6 MT
Section -Prerequisites
  SetOutPath $INSTDIR\win32\avisynth
  MessageBox MB_YESNO "AviSynth 2.6 MT is recommended. Install it now?" /SD IDYES IDNO endAviSynthInstall
    File "..\win32\avisynth\AviSynth2.6.0MT-2012.05.16.exe"
    ExecWait "$INSTDIR\win32\avisynth\AviSynth2.6.0MT-2012.05.16.exe"
  endAviSynthInstall:
SectionEnd

Var Dialog
Var Text
Var Label
Var Desc

Function SetMem
	!insertmacro MUI_HEADER_TEXT "Choose Memory Allocation" "Choose the maximum amount of memory to allow UMS to use." 
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}

	${NSD_CreateLabel} 0 0 100% 20u "This allows you to set the Java's Heap size limit. If you are not sure what this means, just leave it at 768. Click Install to continue."
	Pop $Desc
	
	${NSD_CreateLabel} 2% 50% 37% 12u "Maximum memory in megabytes"
	Pop $Label

	${NSD_CreateText} 3% 60% 10% 12u "768"
	Pop $Text

	nsDialogs::Show
FunctionEnd

Function SetMemLeave
	${NSD_GetText} $Text $0
	WriteRegStr HKCU "${REG_KEY_SOFTWARE}" "HeapMem" "$0"
FunctionEnd

Function CreateDesktopShortcut
  CreateShortCut "$DESKTOP\${PROJECT_NAME}.lnk" "$INSTDIR\UMS.exe"
FunctionEnd

Section "Program Files"
  SetOutPath "$INSTDIR"
  SetOverwrite on
  File /r /x "*.conf" /x "*.zip" /x "*.dll" /x "third-party" "${PROJECT_BASEDIR}\src\main\external-resources\plugins"
  File /r "${PROJECT_BASEDIR}\src\main\external-resources\documentation"
  File /r "${PROJECT_BASEDIR}\src\main\external-resources\renderers"
  File /r "${PROJECT_BASEDIR}\src\main\external-resources\win32"
  File "${PROJECT_BUILD_DIR}\UMS.exe"
  File "${PROJECT_BASEDIR}\src\main\external-resources\UMS.bat"
  File "${PROJECT_BUILD_DIR}\ums.jar"
  File "${PROJECT_BASEDIR}\MediaInfo.dll"
  File "${PROJECT_BASEDIR}\MediaInfo64.dll"
  File "${PROJECT_BASEDIR}\CHANGELOG.txt"
  File "${PROJECT_BASEDIR}\README.txt"
  File "${PROJECT_BASEDIR}\LICENSE.txt"
  File "${PROJECT_BASEDIR}\src\main\external-resources\logback.xml"
  File "${PROJECT_BASEDIR}\src\main\external-resources\icon.ico"

  ;the user may have set the installation dir
  ;as the profile dir, so we can't clobber this
  SetOverwrite off
  File "${PROJECT_BASEDIR}\src\main\external-resources\WEB.conf"

  ;Store install folder
  WriteRegStr HKCU "${REG_KEY_SOFTWARE}" "" $INSTDIR

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\uninst.exe"

  WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "DisplayName" "${PROJECT_NAME}"
  WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "DisplayIcon" "$INSTDIR\icon.ico"
  WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "DisplayVersion" "${PROJECT_VERSION}"
  WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "Publisher" "${PROJECT_ORGANIZATION_NAME}"
  WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "URLInfoAbout" "${PROJECT_ORGANIZATION_URL}"
  WriteRegStr HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}" "UninstallString" '"$INSTDIR\uninst.exe"'

  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM "${REG_KEY_UNINSTALL}" "EstimatedSize" "$0"

  WriteUnInstaller "uninst.exe"

  ReadENVStr $R0 ALLUSERSPROFILE
  SetOutPath "$R0\UMS"
  AccessControl::GrantOnFile "$R0\UMS" "(S-1-5-32-545)" "FullAccess"
SectionEnd

Section "Start Menu Shortcuts"
  SetShellVarContext all
  CreateDirectory "$SMPROGRAMS\${PROJECT_NAME}"
  CreateShortCut "$SMPROGRAMS\${PROJECT_NAME}\${PROJECT_NAME}.lnk" "$INSTDIR\UMS.exe" "" "$INSTDIR\UMS.exe" 0
  CreateShortCut "$SMPROGRAMS\${PROJECT_NAME}\${PROJECT_NAME} (Select Profile).lnk" "$INSTDIR\UMS.exe" "profiles" "$INSTDIR\UMS.exe" 0
  CreateShortCut "$SMPROGRAMS\${PROJECT_NAME}\Uninstall.lnk" "$INSTDIR\uninst.exe" "" "$INSTDIR\uninst.exe" 0
SectionEnd

Section "Uninstall"
  SetShellVarContext all

  Delete /REBOOTOK "$INSTDIR\uninst.exe"
  RMDir /R /REBOOTOK "$INSTDIR\plugins"
  RMDir /R /REBOOTOK "$INSTDIR\renderers"
  RMDir /R /REBOOTOK "$INSTDIR\documentation"
  RMDir /R /REBOOTOK "$INSTDIR\win32"
  Delete /REBOOTOK "$INSTDIR\UMS.exe"
  Delete /REBOOTOK "$INSTDIR\UMS.bat"
  Delete /REBOOTOK "$INSTDIR\ums.jar"
  Delete /REBOOTOK "$INSTDIR\MediaInfo.dll"
  Delete /REBOOTOK "$INSTDIR\MediaInfo64.dll"
  Delete /REBOOTOK "$INSTDIR\CHANGELOG.txt"
  Delete /REBOOTOK "$INSTDIR\WEB.conf"
  Delete /REBOOTOK "$INSTDIR\README.txt"
  Delete /REBOOTOK "$INSTDIR\LICENSE.txt"
  Delete /REBOOTOK "$INSTDIR\debug.log"
  Delete /REBOOTOK "$INSTDIR\logback.xml"
  Delete /REBOOTOK "$INSTDIR\icon.ico"
  RMDir /REBOOTOK "$INSTDIR"

  Delete /REBOOTOK "$DESKTOP\${PROJECT_NAME}.lnk"
  RMDir /REBOOTOK "$SMPROGRAMS\${PROJECT_NAME}"
  Delete /REBOOTOK "$SMPROGRAMS\${PROJECT_NAME}\${PROJECT_NAME}.lnk"
  Delete /REBOOTOK "$SMPROGRAMS\${PROJECT_NAME}\${PROJECT_NAME} (Select Profile).lnk"
  Delete /REBOOTOK "$SMPROGRAMS\${PROJECT_NAME}\Uninstall.lnk"

  DeleteRegKey HKEY_LOCAL_MACHINE "${REG_KEY_UNINSTALL}"
  DeleteRegKey HKCU "${REG_KEY_SOFTWARE}"

  nsSCM::Stop "${PROJECT_NAME}"
  nsSCM::Remove "${PROJECT_NAME}"
SectionEnd
