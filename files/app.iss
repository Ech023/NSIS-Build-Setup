; ============================================================================
;  SourceGit 安装程序
;  基于 Inno Setup 6.4+ 通用模板
; ============================================================================

; ============================================================================
;  1. 用户配置区域 — 所有可定制项集中在此，方便修改
; ============================================================================

; 应用名称（显示在安装界面、开始菜单、控制面板等）
#define AppName          "SourceGit"
; 发布者名称（用于安装目录、注册表路径等）
#define AppPublisher     "SourceGit-scm"
; 官方网站 URL（用于快捷方式和注册表）
#define AppURL           "https://github.com/SourceGit-scm/SourceGit"
; 主程序可执行文件名（必须与 SourceDir 中的实际文件名一致）
#define AppExe           "SourceGit.exe"
; 应用唯一标识（建议使用反向域名风格或 GUID，确保全局唯一）
#define AppId            "com.github.SourceGit-scm.SourceGit"

; 待打包文件的源目录（请确保路径以反斜杠结尾，所有应用文件及子目录均在此）
#define SourceDir        "D:\Fsoft\SourceGit\"
; 安装目录名称（通常与应用名相同，将安装在 {autopf}\{#AppPublisher}\{#InstallDirName}）
#define InstallDirName   AppName
; 输出目录（生成的安装包存放位置，相对于脚本所在目录）
#define OutputDir        "release"
; 安装包图标（位于脚本同目录，格式 .ico）
#define SetupIcon        "icon.ico"
; 许可证文件（位于脚本同目录，安装时将显示此文件内容）
#define License          "LICENSE"
; 手动指定版本号（格式 X.Y.Z.W，将用于显示和注册表）
#define MyAppVersion      "2026.7.31.17"
; 短版本号（用于输出文件名，通常取前三位）
#define MyAppVersionShort "2026.7.17"

; ============================================================================
;  2. 编译时检查 — 确保关键文件存在，避免无效编译
; ============================================================================

; 检查主程序是否存在，若不存在则中止编译并报错
#if !FileExists(SourceDir + "\" + AppExe)
  #error "找不到主程序 EXE，请检查 SourceDir 或 AppExe"
#endif

; 根据应用名和短版本号生成安装包文件名（例如：SourceGit_Setup_2026.7.17.exe）
#define SetupFileName AppName + "_Setup_" + MyAppVersionShort

; ============================================================================
;  3. 安装程序核心设置 — [Setup] 段控制安装包的整体行为
; ============================================================================

[Setup]

; ---- 应用标识 ----
AppId={#AppId}                         
AppName={#AppName}                   
AppVersion={#MyAppVersion}            
AppVerName={#AppName} {#MyAppVersion}  
AppPublisher={#AppPublisher}          
AppPublisherURL={#AppURL}              
AppSupportURL={#AppURL}                
AppUpdatesURL={#AppURL}               

; ---- 安装路径 ----
; 默认安装目录（Program Files 下）
DefaultDirName={autopf}\{#AppPublisher}\{#InstallDirName} 
; 开始菜单文件夹名称
DefaultGroupName={#AppName}           

; ---- 输出 ----
; 安装包输出目录
OutputDir={#OutputDir}
; 安装包文件名（不含扩展名 .exe）                 
OutputBaseFilename={#SetupFileName}   
; 安装包图标
SetupIconFile={#SetupIcon}     
; 卸载程序显示的图标（使用主程序图标）      
UninstallDisplayIcon={app}\{#AppExe}   

; ---- 压缩 ----
; 使用 LZMA2 压缩算法（高压缩率）
Compression=lzma2 
; 将文件打包为单一固实压缩块，提高压缩率                   
SolidCompression=yes                 

; ---- 架构 ----
; 允许在 x64 和 ARM64 系统上安装
ArchitecturesAllowed=x64compatible arm64   
ArchitecturesInstallIn64BitMode=x64compatible arm64 

; ---- 权限 ---- 
; 需要管理员权限（以写入 Program Files）
PrivilegesRequired=admin          
; 允许通过命令行参数 /ALLUSERS 或 /CURRENTUSER 覆盖    
PrivilegesRequiredOverridesAllowed=commandline
; ---- 版本信息 ----
VersionInfoCompany={#AppPublisher}    
VersionInfoProductName={#AppName}     
VersionInfoProductVersion={#MyAppVersion}  
VersionInfoTextVersion={#MyAppVersion} 
VersionInfoCopyright="Copyright (C) {#AppPublisher}"  

; ---- 界面 ----
; 显示“选择安装目录”页面（用户可更改）
DisableDirPage=no       
; 允许用户不创建开始菜单快捷方式              
AllowNoIcons=yes        
; 显示许可证文件（页面在安装开始前）               
LicenseFile={#License}                

; ---- 互斥体 ----
; 系统级互斥体，防止同时运行多个安装程序实例
SetupMutex=Global\{#AppId}_Setup_Mutex  

; ============================================================================
;  4. 语言 — 仅支持简体中文，可扩展其他语言
; ============================================================================

[Languages]
Name: "zh_cn"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

; ============================================================================
;  5. 文件安装 — 将源目录所有内容复制到安装目录
; ============================================================================

[Files]
; 递归复制 SourceDir 下所有文件及子文件夹到 {app}（安装目标目录）
; ignoreversion: 不检查文件版本，直接覆盖（适用于发布新版本）
; recursesubdirs: 包含子目录
; createallsubdirs: 自动创建所有子目录
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; ============================================================================
;  6. 快捷方式 — 开始菜单和桌面
; ============================================================================

[Icons]
; 开始菜单中的应用快捷方式
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
; 开始菜单中的卸载快捷方式
Name: "{group}\卸载 {#AppName}"; Filename: "{uninstallexe}"
; 桌面快捷方式（由 Tasks: desktopicon 控制是否创建）
Name: "{commondesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon
; 开始菜单中的官网链接
Name: "{group}\访问 {#AppName} 网站"; Filename: "{#AppURL}"

[Tasks]
; 桌面快捷方式任务，默认勾选（未加 unchecked 标志）
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加选项："

; ============================================================================
;  7. 注册表 — 写入卸载信息和应用配置，卸载时自动清理
; ============================================================================

[Registry]

; ---- 控制面板卸载信息（HKLM） ----
; 此键使应用显示在“卸载或更改程序”列表中
; uninsdeletekey 确保卸载时删除此键
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1"; ValueType: string; ValueName: "DisplayName"; ValueData: "{#AppName}"
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1"; ValueType: string; ValueName: "DisplayVersion"; ValueData: "{#MyAppVersion}"
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1"; ValueType: string; ValueName: "Publisher"; ValueData: "{#AppPublisher}"
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1"; ValueType: string; ValueName: "URLInfoAbout"; ValueData: "{#AppURL}"
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1"; ValueType: string; ValueName: "DisplayIcon"; ValueData: "{app}\{#AppExe}"
; 静默卸载命令（用于企业批量部署）
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1"; ValueType: string; ValueName: "QuietUninstallString"; ValueData: """{uninstallexe}"" /SILENT"

; ---- 应用配置（HKCU） ----
; 存储安装路径和安装日期，供应用运行时读取
; uninsdeletekey 确保卸载时删除整个键
Root: HKCU; Subkey: "Software\{#AppPublisher}\{#AppName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\{#AppPublisher}\{#AppName}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"
Root: HKCU; Subkey: "Software\{#AppPublisher}\{#AppName}"; ValueType: dword; ValueName: "InstallDate"; ValueData: "{code:GetCurrentDate}"

; ============================================================================
;  8. 安装后运行 — 可选启动主程序
; ============================================================================

[Run]
; 安装完成后，勾选“启动 SourceGit”复选框则运行主程序
; nowait: 不等待程序结束，安装程序立即退出
; postinstall: 显示在安装完成页面
; skipifsilent: 静默安装时不运行
; shellexec: 使用 Shell 执行（可处理文件关联）
Filename: "{app}\{#AppExe}"; Description: "启动 {#AppName}"; Flags: nowait postinstall skipifsilent shellexec

; ============================================================================
;  9. 卸载清理 — 删除应用运行时产生的临时文件
; ============================================================================

[UninstallDelete]
; 删除安装目录下的缓存、临时文件、日志等（Inno 会自动删除安装时复制的文件，此处额外清理运行时生成的文件）
Type: filesandordirs; Name: "{app}\Cache"
Type: filesandordirs; Name: "{app}\Temp"
Type: filesandordirs; Name: "{app}\Logs"
Type: files; Name: "{app}\*.log"
Type: files; Name: "{app}\*.tmp"

; ============================================================================
;  10. 自定义消息 — 用于安装界面显示的中文文本
; ============================================================================

[CustomMessages]
 ; %1 会被替换为 AppName
zh_cn.LaunchProgram=启动 %1         
zh_cn.CreateDesktopIcon=创建桌面快捷方式
; 安装完成弹窗的标题
zh_cn.InstallComplete={#AppName} 安装完成！  

; ============================================================================
;  11. 代码段 — Pascal 脚本，实现高级功能
; ============================================================================

[Code]

// ----------------------------------------------------------------------------
// 获取当前日期（用于注册表 InstallDate）
// 格式：YYYYMMDD，例如 20260731
// ----------------------------------------------------------------------------
function GetCurrentDate(Param: string): string;
begin
  Result := GetDateTimeString('yyyyMMdd', '-', '-');
end;

// ----------------------------------------------------------------------------
// 检查应用是否正在运行（基于互斥体）
// 应用启动时应创建同名互斥体，用于检测实例
// ----------------------------------------------------------------------------
function IsAppRunning(): Boolean;
begin
  Result := CheckForMutexes('Global\' + '{#AppId}' + '_App_Mutex');
end;

// ----------------------------------------------------------------------------
// 安装初始化函数 — 在安装向导显示之前执行
// 返回 True 继续安装，False 中止安装
// 功能：
//   1. 检测旧版本，询问用户是否继续（可能覆盖安装）
//   2. 检测应用是否正在运行，若运行则提示用户关闭，并尝试自动终止进程
// ----------------------------------------------------------------------------
function InitializeSetup(): Boolean;
var
  OldVersion: string;
  Msg: string;
  ResultCode: Integer;
  i: Integer;
begin
  Result := True;   // 默认允许安装

  // 1. 检测旧版本（通过注册表卸载信息）
  if RegQueryStringValue(HKLM, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1', 'DisplayVersion', OldVersion) then
  begin
    Msg := '检测到已安装的旧版本 (v' + OldVersion + ')。' + #13#10 +
           '建议先卸载旧版本再继续安装。' + #13#10 + #13#10 +
           '是否继续安装？（可能导致文件冲突）';
    if MsgBox(Msg, mbConfirmation, MB_YESNO) = IDNO then
    begin
      Result := False;   // 用户选择不继续，退出安装
      Exit;
    end;
  end;

  // 2. 检测应用是否正在运行，若运行则提供自动关闭选项
  if IsAppRunning() then
  begin
    Msg := ExpandConstant('{#AppName} 正在运行。' + #13#10 +
           '点击 "确定" 将自动关闭 {#AppName} 并继续安装。' + #13#10 +
           '点击 "取消" 将退出安装。');
    if MsgBox(Msg, mbInformation, MB_OKCANCEL) = IDOK then
    begin
      // 用户同意自动关闭 → 执行 taskkill 强制终止进程
      Exec('taskkill', '/f /im {#AppExe}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      // 等待互斥体释放，最多 3 秒（6 次 × 500 ms）
      for i := 1 to 6 do
      begin
        Sleep(500);
        if not IsAppRunning() then Break;
      end;
      // 如果进程仍然存在，提示用户手动关闭并退出安装
      if IsAppRunning() then
      begin
        MsgBox('无法自动关闭 {#AppName}，请手动关闭后再试。', mbError, MB_OK);
        Result := False;
        Exit;
      end;
    end
    else
    begin
      // 用户取消 → 退出安装
      Result := False;
      Exit;
    end;
  end;
  // 所有检查通过，继续安装
end;

// ----------------------------------------------------------------------------
// 卸载初始化函数 — 在卸载向导显示之前执行
// 检测应用是否正在运行，若运行则提示用户关闭，否则阻止卸载
// ----------------------------------------------------------------------------
function InitializeUninstall(): Boolean;
var
  Msg: string;
begin
  Result := True;
  if IsAppRunning() then
  begin
    Msg := ExpandConstant('{#AppName} 正在运行。' + #13#10 +
           '请关闭程序后再卸载。' + #13#10 + #13#10 +
           '是否继续卸载？');
    if MsgBox(Msg, mbError, MB_YESNO) = IDNO then
    begin
      Result := False;   // 用户选择不继续，中止卸载
      Exit;
    end;
  end;
end;

// ----------------------------------------------------------------------------
// 卸载后清理 — 在卸载完成后执行
// 双重保险：删除用户数据目录和残留注册表项
// ----------------------------------------------------------------------------
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  UserDataPath: string;
  RegKey: string;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    // 删除用户数据目录（%APPDATA%\SourceGit-scm\SourceGit）
    UserDataPath := ExpandConstant('{userappdata}') + '\{#AppPublisher}\{#AppName}';
    if DirExists(UserDataPath) then
      DelTree(UserDataPath, True, True, True);

    // 额外清理 HKCU 注册表项（防止 uninsdeletekey 因权限问题未生效）
    RegKey := 'Software\{#AppPublisher}\{#AppName}';
    if RegKeyExists(HKCU, RegKey) then
      RegDeleteKeyIncludingSubkeys(HKCU, RegKey);

    // 额外清理 HKLM 卸载键（同样作为兜底）
    RegKey := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1';
    if RegKeyExists(HKLM, RegKey) then
      RegDeleteKeyIncludingSubkeys(HKLM, RegKey);
  end;
end;