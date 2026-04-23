Unicode True
ManifestDPIAware True
RequestExecutionLevel user
XPStyle on
SetCompressor /SOLID lzma

!include "MUI2.nsh"

!ifndef APP_NAME
  !error "APP_NAME is required"
!endif

!ifndef APP_VERSION
  !error "APP_VERSION is required"
!endif

!ifndef SOURCE_DIR
  !error "SOURCE_DIR is required"
!endif

!ifndef OUTPUT_FILE
  !error "OUTPUT_FILE is required"
!endif

!ifndef MAIN_EXE
  !error "MAIN_EXE is required"
!endif

!ifndef INSTALLER_ICON
  !error "INSTALLER_ICON is required"
!endif

!ifndef INSTALLER_WELCOME_BITMAP
  !error "INSTALLER_WELCOME_BITMAP is required"
!endif

!ifndef INSTALLER_HEADER_BITMAP
  !error "INSTALLER_HEADER_BITMAP is required"
!endif

!ifndef INSTALL_DIR_NAME
  !define INSTALL_DIR_NAME "${APP_NAME}"
!endif

!ifndef FINISH_RUN_ENABLED
  !define FINISH_RUN_ENABLED 1
!endif

!define APP_ID "MistRelay"

Name "${APP_NAME}"
OutFile "${OUTPUT_FILE}"
InstallDir "$LOCALAPPDATA\Programs\${INSTALL_DIR_NAME}"
InstallDirRegKey HKCU "Software\${APP_ID}" "InstallDir"
BrandingText "MistRelay Installer"
ShowInstDetails hide
ShowUnInstDetails hide
Icon "${INSTALLER_ICON}"
UninstallIcon "${INSTALLER_ICON}"

!define MUI_ABORTWARNING
!define MUI_ICON "${INSTALLER_ICON}"
!define MUI_UNICON "${INSTALLER_ICON}"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "${INSTALLER_HEADER_BITMAP}"
!define MUI_HEADERIMAGE_UNBITMAP "${INSTALLER_HEADER_BITMAP}"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${INSTALLER_WELCOME_BITMAP}"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${INSTALLER_WELCOME_BITMAP}"

!define MUI_WELCOMEPAGE_TITLE "欢迎安装 ${APP_NAME}"
!define MUI_WELCOMEPAGE_TEXT "${APP_NAME} 桌面客户端将安装到你的用户目录。安装过程轻量快速，不会清理已有的本地配置与下载数据。$\r$\n$\r$\n点击“下一步”继续。"
!define MUI_DIRECTORYPAGE_TEXT_TOP "请选择 ${APP_NAME} 的安装位置。建议保留默认路径，便于后续更新和卸载。"
!define MUI_FINISHPAGE_TITLE "${APP_NAME} 已安装完成"
!define MUI_FINISHPAGE_TEXT "${APP_NAME} 已成功安装。你可以立即启动，也可以稍后通过桌面快捷方式或开始菜单进入。"

!if ${FINISH_RUN_ENABLED}
  !define MUI_FINISHPAGE_RUN "$INSTDIR\${MAIN_EXE}"
  !define MUI_FINISHPAGE_RUN_TEXT "立即启动 ${APP_NAME}"
!endif

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "SimpChinese"

!macro CloseRunningApp
  ClearErrors
  ExecWait '"$SYSDIR\taskkill.exe" /IM "${MAIN_EXE}" /T /F' $0
  Sleep 1000
!macroend

Section "Install"
  !insertmacro CloseRunningApp
  SetOutPath "$INSTDIR"
  RMDir /r "$INSTDIR"
  File /r "${SOURCE_DIR}\*.*"

  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${MAIN_EXE}"
  CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${MAIN_EXE}"

  WriteRegStr HKCU "Software\${APP_ID}" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "Publisher" "MistRelay"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayIcon" "$INSTDIR\${MAIN_EXE}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "NoRepair" 1
  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  !insertmacro CloseRunningApp
  Delete "$DESKTOP\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk"
  RMDir "$SMPROGRAMS\${APP_NAME}"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\${APP_ID}"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}"
SectionEnd
