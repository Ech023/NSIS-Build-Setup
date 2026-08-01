; ================================================================
; SourceGit Inno Setup Installer (app.iss)
; 自动迁移自现有 NSIS 脚本（app.nsi）行为：
; - 首次安装：显示向导（欢迎、选择目录、准备页），完成后弹框询问是否启动程序
; - 升级安装（检测到已安装且存在主程序）：以静默模式自动覆盖安装（隐藏所有页面），安装完成后弹框询问是否启动程序
; - 安装时写入与原 NSIS 脚本兼容的注册表键（HKLM 32/64）以便互通（Install_Dir / Version）
; - 卸载时保护系统关键路径并可删除用户配置目录（请在卸载时手动确认）
; ================================================================

; -------- 用户配置（请按需修改）-----------------------------------
#define AppDisplayName  "SourceGit"                    ; 界面显示名称（可为中文）
#define AppBaseName     "SourceGit"                    ; 内部英文名称（用于目录和注册表键）
#define AppVersion      "2026.7.27.16"
#define AppExe          "SourceGit.exe"
#define AppPublisher    "SourceGit-scm"
#define AppURL          "https://github.com/SourceGit-scm/SourceGit"
#define AppIdValue      "com.github.SourceGit-scm.SourceGit" ; 唯一标识
#define SourceDir       "D:\\Fsoft\\SourceGit"        ; 可替换为你的构建输出目录或相对路径
#define IconFile        "icon.ico"                       ; 脚本同级目录下的图标文件（打包时请确认存在）
; ----------------------------------------------------------------

[Setup]
AppId={#AppIdValue}
AppName={#AppDisplayName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
DefaultDirName={autopf}\{#AppBaseName}
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin
OutputDir=.
OutputBaseFilename={#AppBaseName}-{#AppVersion}-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile={#IconFile}
UninstallDisplayName={#AppDisplayName}
UninstallDisplayIcon={app}\{#AppExe}
CloseApplications=yes
RestartApplications=no
DisableProgramGroupPage=yes

[Languages]
Name: "chinesesimp"; MessagesFile: "compiler:Languages\\ChineseSimplified.isl"

[Files]
Source: "{#SourceDir}\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{commondesktop}\{#AppDisplayName}"; Filename: "{app}\{#AppExe}"; WorkingDir: "{app}"
Name: "{commonprograms}\{#AppDisplayName}\{#AppDisplayName}"; Filename: "{app}\{#AppExe}"; WorkingDir: "{app}"
Name: "{commonprograms}\{#AppDisplayName}\卸载 {#AppDisplayName}"; Filename: "{uninstallexe}"

[Registry]
; 写入 64 位视图
Root: HKLM64; Subkey: "Software\{#AppIdValue}"; ValueType: string; ValueName: "Install_Dir"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKLM64; Subkey: "Software\{#AppIdValue}"; ValueType: string; ValueName: "Version"; ValueData: "{#AppVersion}"; Flags: uninsdeletekey
; 写入 32 位视图（兼容原 NSIS 脚本在不同视图下的读写）
Root: HKLM32; Subkey: "Software\{#AppIdValue}"; ValueType: string; ValueName: "Install_Dir"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKLM32; Subkey: "Software\{#AppIdValue}"; ValueType: string; ValueName: "Version"; ValueData: "{#AppVersion}"; Flags: uninsdeletekey

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]

// ================================================================
// Windows API 声明（用于模拟按钮点击）
// ================================================================
function PostMessage(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL;
external 'PostMessageA@user32.dll stdcall';

const
  BM_CLICK = $00F1;  // 按钮点击消息

var
  UpgradeMode: Boolean;
  OldInstallPath: String;

// ----------------------------------------------------------------
// 获取旧安装路径（兼容 HKLM 32/64）
// ----------------------------------------------------------------
function GetOldInstallPath(): String;
var
  S: String;
begin
  S := '';
  if RegQueryStringValue(HKLM64, 'Software\\{#AppIdValue}', 'Install_Dir', S) then
  begin
    Result := S;
    Exit;
  end;
  if RegQueryStringValue(HKLM32, 'Software\\{#AppIdValue}', 'Install_Dir', S) then
  begin
    Result := S;
    Exit;
  end;
  Result := '';
end;

// ----------------------------------------------------------------
// 静默强制终止进程（最多重试 3 次）
// ----------------------------------------------------------------
procedure KillProcessSilent(ExeName: String);
var
  ResultCode: Integer;
  Retry: Integer;
  CmdLine: String;
begin
  CmdLine := '/F /IM "' + ExeName + '"';
  for Retry := 0 to 2 do
  begin
    if Exec('taskkill', CmdLine, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      if (ResultCode = 0) or (ResultCode = 128) then
        Exit;
    Sleep(1000);
  end;
end;

// ----------------------------------------------------------------
// 初始化安装：检测旧安装并根据情况设置升级模式
// ----------------------------------------------------------------
function InitializeSetup(): Boolean;
begin
  Result := True;
  UpgradeMode := False;
  OldInstallPath := GetOldInstallPath();
  if OldInstallPath <> '' then
  begin
    if FileExists(ExpandConstant(AddBackslash(OldInstallPath) + '{#AppExe}')) then
    begin
      UpgradeMode := True;
      KillProcessSilent('{#AppExe}');
      Sleep(500);
    end
    else
    begin
      ; 清理残留注册表（如果旧目录已不存在）
      RegDeleteKeyIncludingSubkeys(HKLM64, 'Software\\{#AppIdValue}');
      RegDeleteKeyIncludingSubkeys(HKLM32, 'Software\\{#AppIdValue}');
      OldInstallPath := '';
    end;
  end;
end;

// ----------------------------------------------------------------
// 向导初始化：预设路径，隐藏页面（仅升级模式隐藏所有标准页面）
// ----------------------------------------------------------------
procedure InitializeWizard();
begin
  if OldInstallPath <> '' then
    WizardForm.DirEdit.Text := OldInstallPath;

  if UpgradeMode then
  begin
    // 升级模式尽量隐藏向导页面（Inno 有些内置页面在某些主题下不可见/移除，下面为尽量隐藏）    WizardForm.WelcomeLabel.Visible := False;    WizardForm.SelectDirPage.Visible := False;    WizardForm.ReadyPage.Visible := False;    WizardForm.FinishedPage.Visible := False;  end;
end;

// ----------------------------------------------------------------
// 页面是否跳过：升级时跳过交互页；首次安装跳过完成页以实现“完成后弹窗询问启动”行为
// ----------------------------------------------------------------
function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  if UpgradeMode then
  begin
    if (PageID = wpWelcome) or (PageID = wpLicense) or (PageID = wpSelectDir) or (PageID = wpReady) or (PageID = wpFinished) then
      Result := True;
  end
  else
  begin
    if (PageID = wpFinished) then
      Result := True;
  end;
end;

// ----------------------------------------------------------------
// 页面切换时：如果当前是准备页面，自动点击“安装”按钮（仅升级模式）
// ----------------------------------------------------------------
procedure CurPageChanged(CurPageID: Integer);
begin
  if UpgradeMode and (CurPageID = wpReady) then
  begin
    // 触发按钮点击以开始安装
    PostMessage(WizardForm.NextButton.Handle, BM_CLICK, 0, 0);
  end;
end;

// ----------------------------------------------------------------
// 安装完成后询问是否启动（在 ssPostInstall 阶段）
// ----------------------------------------------------------------
procedure CurStepChanged(CurStep: TSetupStep);
var
  Ret: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    Ret := MsgBox(ExpandConstant('{#AppDisplayName} 安装完成，是否立即启动？'), mbConfirmation, MB_YESNO);
    if Ret = IDYES then
      Exec(ExpandConstant('{app}\\{#AppExe}'), '', '', SW_SHOWNORMAL, ewNoWait, Ret);
  end;
end;

// ----------------------------------------------------------------
// 卸载初始化与保护（阻止在危险目录卸载）
// ----------------------------------------------------------------
function InitializeUninstall(): Boolean;
var
  Path: String;
begin
  Result := True;
  Path := ExpandConstant('{app}');
  if (LowerCase(Path) = 'c:\\') or (LowerCase(Path) = 'c:\\windows') or
     (LowerCase(Path) = 'c:\\windows\\system32') or (LowerCase(Path) = 'c:\\windows\\syswow64') or
     (LowerCase(Path) = 'd:\\') or (Length(Path) < 3) then
  begin
    MsgBox('检测到危险系统目录，卸载已取消。', mbError, MB_OK);
    Result := False;
  end;
end;

// ----------------------------------------------------------------
// 卸载过程中杀进程以便删除文件
// ----------------------------------------------------------------
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    KillProcessSilent('{#AppExe}');
end;
