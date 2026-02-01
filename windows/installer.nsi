; NSIS Installer Script for Lumio
; This script creates a Windows installer that installs the application
; to Program Files and creates shortcuts.

;--------------------------------
; Includes

!define APP_EXE "lumio.exe"

!include "MUI2.nsh"
!include "FileFunc.nsh"

;--------------------------------
; General

; Name and file
Name "Lumio"
OutFile "lumio-windows-setup.exe"
Unicode True

; Default installation folder
InstallDir "$PROGRAMFILES64\Lumio"

; Get installation folder from registry if available
InstallDirRegKey HKCU "Software\Lumio" ""

; Request application privileges for Windows Vista/7/8/10/11
RequestExecutionLevel admin

; Version information
VIProductVersion "1.3.0.0"
VIAddVersionKey "ProductName" "Lumio"
VIAddVersionKey "Comments" "A modern IPTV player application"
VIAddVersionKey "CompanyName" "Lumio"
VIAddVersionKey "LegalCopyright" "Copyright © 2025"
VIAddVersionKey "FileDescription" "Lumio Installer"
VIAddVersionKey "FileVersion" "1.3.0.0"
VIAddVersionKey "ProductVersion" "1.3.0.0"

;--------------------------------
; Interface Settings

!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

;--------------------------------
; Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
; Languages

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Sections

Section "Lumio" SecMain

  SectionIn RO

  ; Set output path to the installation directory

  SetOutPath "$INSTDIR"

  ; Copy all files from the build directory
  ; Note: In GitHub Actions, we're in windows/ directory, so we go up one level
  File /r /x "*.pdb" /x "lumio-windows-*" "..\build\windows\x64\runner\Release\*"

  ; Store installation folder
  WriteRegStr HKCU "Software\Lumio" "" $INSTDIR

  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Add to Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lumio" \
                   "DisplayName" "Lumio"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lumio" \
  "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lumio" \
                   "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lumio" \
                 "DisplayIcon" "$INSTDIR\${APP_EXE}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lumio" \
                   "Publisher" "Lumio"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lumio" \
                   "DisplayVersion" "1.3.0"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lumio" \
                     "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lumio" \
                     "NoRepair" 1

SectionEnd

Section "Start Menu Shortcuts" SecStartMenu

  ; Create shortcuts
  CreateDirectory "$SMPROGRAMS\Lumio"
  CreateShortcut "$SMPROGRAMS\Lumio\Lumio.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
  CreateShortcut "$SMPROGRAMS\Lumio\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

SectionEnd

Section "Desktop Shortcut" SecDesktop

  CreateShortcut "$DESKTOP\Lumio.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0


SectionEnd

;--------------------------------
; Descriptions

; Language strings
LangString DESC_SecMain ${LANG_ENGLISH} "Install Lumio application files."
LangString DESC_SecStartMenu ${LANG_ENGLISH} "Create Start Menu shortcuts."
LangString DESC_SecDesktop ${LANG_ENGLISH} "Create a desktop shortcut."

; Assign language strings to sections
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} $(DESC_SecMain)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenu} $(DESC_SecStartMenu)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} $(DESC_SecDesktop)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Uninstaller Section

Section "Uninstall"

  ; Remove files and uninstaller
  Delete "$INSTDIR\Uninstall.exe"
  RMDir /r "$INSTDIR"

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\Lumio\Lumio.lnk"
  Delete "$SMPROGRAMS\Lumio\Uninstall.lnk"
  RMDir "$SMPROGRAMS\Lumio"
  Delete "$DESKTOP\Lumio.lnk"

  ; Remove registry keys
  DeleteRegKey /ifempty HKCU "Software\Lumio"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Lumio"

SectionEnd

