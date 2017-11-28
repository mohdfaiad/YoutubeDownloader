unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, XMLConf, FileUtil, BCButtonFocus, BCLabel, BGRACustomDrawn,
  Forms, Controls, Graphics, Dialogs, StdCtrls, Menus,
  ExtCtrls, clipbrd, Windows, lclintf, Buttons, Registry, ShlObj;

var
  CurrentVersion : String = '0.0.34';

type

  { TForm1 }

  TForm1 = class(TForm)
    BCButtonFocus1: TBCButtonFocus;
    BCButtonFocus2: TBCButtonFocus;
    BCLabel1: TBCLabel;
    ButtonSetDownloadPath: TButton;
    ComboBoxEncoding: TComboBox;
    EditHTTP: TEdit;
    EditPath: TEdit;
    Image1: TImage;
    ImageList1: TImageList;
    ImageList2: TImageList;
    Label2: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItemHideOnDownload: TMenuItem;
    MenuItemPathDL: TMenuItem;
    MenuItemSkinBlack: TMenuItem;
    MenuItemCheckClipboard: TMenuItem;
    MenuItemSkinWhite: TMenuItem;
    MenuItemSkinBlue: TMenuItem;
    MenuItemSkin: TMenuItem;
    MenuItemUpdateOnBoot: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItemStartOnBoot: TMenuItem;
    MenuItemCacheToggle: TMenuItem;
    MenuItemAbout: TMenuItem;
    MenuItemCacheHelp: TMenuItem;
    MenuItemCacheClear: TMenuItem;
    MenuItemCacheOpen: TMenuItem;
    MenuItemExit: TMenuItem;
    PopupMenuTray: TPopupMenu;
    Process1: TProcess;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    TimerAfterLoad: TTimer;
    TimerClipboard: TTimer;
    TrayIcon1: TTrayIcon;
    XMLConfig1: TXMLConfig;
    procedure ButtonDownloadKeyPress(Sender: TObject; var Key: char);
    procedure ButtonSetDownloadPathClick(Sender: TObject);
    procedure ButtonMenuClick(Sender: TObject);
    procedure ButtonDownloadClick(Sender: TObject);
    procedure ButtonPasteClick(Sender: TObject);
    procedure ComboBoxEncodingChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItemHideOnDownloadClick(Sender: TObject);
    procedure MenuItemPathDLClick(Sender: TObject);
    procedure MenuItemAboutClick(Sender: TObject);
    procedure MenuItemCacheClearClick(Sender: TObject);
    procedure MenuItemCacheHelpClick(Sender: TObject);
    procedure MenuItemCacheOpenClick(Sender: TObject);
    procedure MenuItemCacheToggleClick(Sender: TObject);
    procedure MenuItemCheckClipboardClick(Sender: TObject);
    procedure MenuItemExitClick(Sender: TObject);
    procedure MenuItemHideClick(Sender: TObject);
    procedure MenuItemShowClick(Sender: TObject);
    procedure MenuItemSkinBlackClick(Sender: TObject);
    procedure MenuItemSkinBlueClick(Sender: TObject);
    procedure MenuItemSkinWhiteClick(Sender: TObject);
    procedure MenuItemStartOnBootClick(Sender: TObject);
    procedure MenuItemUpdateClick(Sender: TObject);
    procedure MenuItemUpdateOnBootClick(Sender: TObject);
    procedure TimerAfterLoadTimer(Sender: TObject);
    procedure TimerClipboardTimer(Sender: TObject);
    procedure DoDownload();
    function GetWinDir: string;
    procedure ExecuteProcess(cmd: String);
    procedure ExecuteProcess(cmd: String; pwait, pshow: Boolean);
    function CloseProcess(const windowName: PChar): Boolean;
    function getEncoding(): String;
    procedure ConfigSave;
    procedure ConfigLoad;
    procedure WriteFile(Filename, Content : String);
    function ReadFile(Filename: String):String;
    procedure DownloadFile(http, filename: String; wait, pshow: Boolean);
    procedure DownloadFileToDir(http, dir: String; wait, pshow: Boolean);
    procedure CheckUpdate();
    procedure DoDownloadWithMixcloud();
    procedure DoDownloadWithYoutubeDl();
    function FindWindowByTitle(WindowTitle: string): Hwnd;
    procedure StartWithWindows(doStart: Boolean);
    function isStartWithWindows(): Boolean;
    procedure SplitStr(const Source, Delimiter: String; var DelimitedList: TStringList);
    function getUserPath:string;
    procedure setFormHeight(h: Integer);
    procedure setFormAtBottomRight;
    procedure SetSkin(skinIdImage: Integer; skinColor, bgColor:TColor);
  private
    { private declarations }
  protected
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  public
    { public declarations }
  end;


var
  Form1: TForm1;
  Config_YoutubeDownloader: String = 'youtube-dl.exe';
  oldClipboardValue: String = '';
  currentSkin: Integer = 0;
  Config_Dir: String = '';
implementation

{$R *.lfm}

{ TForm1 }



procedure TForm1.FormCreate(Sender: TObject);
begin
  setFormHeight(60);
  Image1.Align:= alClient;
  EditHTTP.Clear;
  EditPath.Clear;
  EditPath.TabStop := False;
  ButtonSetDownloadPath.TabStop := False;

  Config_Dir := getUserPath + '\YoutubeDownloader\';
  if not DirectoryExists(Config_Dir) then MkDir(Config_Dir);

  ConfigLoad;

  if currentSkin = 0 then MenuItemSkinBlueClick(nil);
  if currentSkin = 1 then MenuItemSkinWhiteClick(nil);
  if currentSkin = 2 then MenuItemSkinBlackClick(nil);
  TimerClipboard.Enabled := MenuItemCheckClipboard.Checked;
  MenuItemUpdateOnBoot.Checked := isStartWithWindows;
end;


procedure TForm1.MenuItemPathDLClick(Sender: TObject);
begin
  setFormHeight(110);
  EditPath.TabStop := True;
  ButtonSetDownloadPath.TabStop := True;
end;

procedure TForm1.setFormHeight(h: Integer);
begin
  Self.Height:= h;
  Self.Constraints.MaxHeight := h;
  Self.Constraints.MinHeight:= h;
  setFormAtBottomRight;
end;

procedure TForm1.TimerAfterLoadTimer(Sender: TObject);
var i: integer;
begin
  TimerAfterLoad.Enabled := False;
  if MenuItemUpdateOnBoot.Checked then CheckUpdate();

  for i:=0 to ParamCount() do
  begin
    if ParamStr(i) = '/background' then hide;
    if ParamStr(i) = '/close' then
    begin
      CloseProcess(PChar(Self.Caption));
      Application.Terminate;
    end;
  end;

end;

procedure TForm1.ConfigLoad;
begin
  XMLConfig1 := TXMLConfig.Create(nil);
  if FileExists(Config_Dir+'config.xml') then XMLConfig1.LoadFromFile(Config_Dir+'config.xml');
  ComboBoxEncoding.ItemIndex := XMLConfig1.GetValue('Encoding', 4);
  MenuItemCacheToggle.Checked := XMLConfig1.GetValue('UseCache', True);
  MenuItemUpdateOnBoot.Checked := XMLConfig1.GetValue('UpdateOnBoot', True);
  EditPath.Text := XMLConfig1.GetValue('Path', ExtractFileDir(Application.ExeName));
  currentSkin := XMLConfig1.GetValue('Skin', 0);
  MenuItemCheckClipboard.Checked := XMLConfig1.GetValue('CheckClipboard', True);
  MenuItemHideOnDownload.Checked := XMLConfig1.GetValue('HideOnDownload', False);
  XMLConfig1.Free;
end;

procedure TForm1.ConfigSave;
begin
  XMLConfig1 := TXMLConfig.Create(nil);
  XMLConfig1.SetValue('Encoding', ComboBoxEncoding.ItemIndex);
  XMLConfig1.SetValue('UseCache', MenuItemCacheToggle.Checked);
  XMLConfig1.SetValue('UpdateOnBoot', MenuItemUpdateOnBoot.Checked);
  XMLConfig1.SetValue('Path', EditPath.Text);
  XMLConfig1.SetValue('Skin', currentSkin);
  XMLConfig1.SetValue('CheckClipboard', MenuItemCheckClipboard.Checked);
  XMLConfig1.SetValue('HideOnDownload', MenuItemHideOnDownload.Checked);
  XMLConfig1.SaveToFile(Config_Dir+'config.xml');
  XMLConfig1.Free;
end;


procedure TForm1.WMNCHitTest(var Message: TWMNCHitTest);
begin
  Message.Result := HTCAPTION; // Move window on drag
end;

function TForm1.ReadFile(Filename: String):String;
var
  Fichier        : textfile;
  texte          : string;
begin
  result:= '';
  assignFile(Fichier, Filename);
  reset(Fichier);
  while not eof(Fichier) do begin
    read(Fichier, texte);
    result := result + texte;
  end;
  closefile(Fichier);
end;

procedure TForm1.WriteFile(Filename, Content : String);
var
  Fp : textfile;
begin
  assignFile(Fp, Filename);
  reWrite(Fp);
  Writeln(Fp, Content);
  closefile(Fp);
end;


function TForm1.GetWinDir: string;
var
  dir: array [0..MAX_PATH] of Char;
begin
  dir := '';
  GetWindowsDirectory(dir, MAX_PATH);
  Result := StrPas(dir);
end;


function TForm1.getUserPath:string;
var pathString:array[0..1023] of char;
begin
   ShGetSpecialFolderPath(0,PChar(@pathString),CSIDL_APPDATA,false);
   result:=pathString;
end;


function TForm1.FindWindowByTitle(WindowTitle: string): Hwnd;
var
  NextHandle: Hwnd;
  NextTitle: array[0..260] of char;
  ProcessId: Cardinal;
begin
  // Get the first window
  NextHandle := GetWindow(Self.Handle, GW_HWNDFIRST);
  while NextHandle > 0 do
  begin
    // retrieve its text
    GetWindowText(NextHandle, NextTitle, 255);
    GetWindowThreadProcessId(NextHandle ,@ProcessId);
    if (Pos(LowerCase(WindowTitle), LowerCase(StrPas(NextTitle))) <> 0) then
    begin
      Result := NextHandle;
      Exit;
    end
    else
      // Get the next window
      NextHandle := GetWindow(NextHandle, GW_HWNDNEXT);
  end;
  Result := 0;
end;



function TForm1.CloseProcess(const windowName: PChar): Boolean;
var AppHandle: THandle;
begin
  AppHandle:=FindWindow(Nil, windowName);
  Result:=PostMessage(AppHandle, WM_QUIT, 0, 0);
end;



procedure TForm1.ExecuteProcess(cmd: String);
begin
  ExecuteProcess(cmd, False, True);
end;


procedure TForm1.ExecuteProcess(cmd: String; pwait, pshow: Boolean);
var p: TProcess;
begin
  p := TProcess.Create(nil);
  p.ApplicationName:= '';
  p.CommandLine:= cmd;
  if not pshow then p.ShowWindow:= swoHIDE;
  p.Execute;
  if pwait then p.WaitOnExit;
end;


procedure TForm1.StartWithWindows(doStart: Boolean);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  try
  if Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', True) then
  begin
    if doStart then
      Reg.WriteString(ExtractFileName(Application.ExeName), '"'+Application.ExeName+'" /background')
    else
      Reg.DeleteValue(ExtractFileName(Application.ExeName));
    Reg.CloseKey;
  end;
  finally
    Reg.Free;
  end;
end;


function TForm1.isStartWithWindows(): Boolean;
var
  Reg: TRegistry;
begin
  result := False;
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  if Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', True) then
  begin
    result := Reg.ValueExists(ExtractFileName(Application.ExeName));
    Reg.CloseKey;
  end;
  Reg.Free;
end;

procedure TForm1.MenuItemCacheClearClick(Sender: TObject);
begin
  if MessageDlg('Voulez-vous effacer le cache?',  mtConfirmation, [mbYes, mbNo], 0) <> IDYES then Exit;
  DeleteFile('archive.txt');
  if FileExists('archive.txt') then
    ShowMessage('Il y a eu un problème avec l''effacement du cache. '
      +'Peut-être le fichier est utilisé. '
      +'Veuillez fermer tous les programmes et recommencer, '
      +'ou effacer à la main le fichier "archive.txt"')
  else
    ShowMessage('Cache effacé :)');
end;

procedure TForm1.MenuItemCacheHelpClick(Sender: TObject);
begin
  ShowMessage('Ce cache mémorise les vidéos téléchargées pour ne pas les télécharger une seconde fois.');
end;

procedure TForm1.MenuItemAboutClick(Sender: TObject);
begin
  ShowMessage('Youtube Downlader version: '+CurrentVersion+#13#10#13#10+
  'Source: https://github.com/ddeeproton/YoutubeDownloader');
end;


procedure TForm1.DownloadFile(http, filename: String; wait, pshow: Boolean);
begin
  if not FileExists('wget.exe') then
  begin
    ShowMessage('wget.exe est introuvable. Il doit se trouver à côté de cette application pour fonctionner.');
    exit;
  end;
  if FileExists(filename) then DeleteFile(PChar(filename));
  ExecuteProcess('wget.exe -O "'+filename+'" "'+http+'" --no-check-certificate', wait, pshow);
end;


procedure TForm1.DownloadFileToDir(http, dir: String; wait, pshow: Boolean);
begin
  if not FileExists('wget.exe') then
  begin
    ShowMessage('wget.exe est introuvable. Il doit se trouver à côté de cette application pour fonctionner.');
    exit;
  end;
  if not DirectoryExists(dir) then
  begin
    if not SelectDirectoryDialog1.Execute then exit;
    EditPath.Text := SelectDirectoryDialog1.FileName;
    ConfigSave;
    dir := EditPath.Text;
  end;
  SetCurrentDirectory(PChar(dir));
  ExecuteProcess(ExtractFileDir(Application.Exename)+'\wget.exe "'+http+'" --no-check-certificate', wait, pshow);
  SetCurrentDirectory(PChar(ExtractFileDir(Application.Exename)));
end;


procedure TForm1.MenuItemCacheOpenClick(Sender: TObject);
begin
  ExecuteProcess('"'+GetWinDir+'\notepad.exe" "'+ExtractFileDir(Application.ExeName) + '\archive.txt"');
end;

procedure TForm1.MenuItemCacheToggleClick(Sender: TObject);
begin
  TMenuItem(Sender).Checked := not TMenuItem(Sender).Checked;
  ConfigSave;
end;

procedure TForm1.MenuItemCheckClipboardClick(Sender: TObject);
begin
  TMenuItem(Sender).Checked := not TMenuItem(Sender).Checked;
  TimerClipboard.Enabled := TMenuItem(Sender).Checked;
  ConfigSave;
end;


procedure TForm1.MenuItemHideOnDownloadClick(Sender: TObject);
begin
  TMenuItem(Sender).Checked := not TMenuItem(Sender).Checked;
  ConfigSave;
end;

procedure TForm1.MenuItemExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.MenuItemShowClick(Sender: TObject);
begin
  Show;
  Form1.WindowState:= wsNormal;
  BringToFront;
end;


procedure TForm1.SetSkin(skinIdImage: Integer; skinColor, bgColor:TColor);
var a: TControlBorderSpacing;
  b: TSpacingSize;
begin
  currentSkin := skinIdImage;
  ImageList1.GetIcon(currentSkin, Image1.Picture.Icon);
  ImageList2.GetIcon(currentSkin, Self.Icon);
  ImageList2.GetIcon(currentSkin, TrayIcon1.Icon);

  Label2.Font.Color := skinColor;

  BCButtonFocus1.StateNormal.Background.Gradient1.EndColor:= bgColor; //$009C9623;
  BCButtonFocus2.StateNormal.Background.Gradient1.EndColor:= bgColor;

  BCLabel1.Font.Color := skinColor;
  BCLabel1.FontEx.Color := skinColor;
  BCLabel1.FontEx.ShadowColor := bgColor;

  EditHTTP.Font.Color := skinColor; //RGB(117,190,197);
  EditHTTP.Color := bgColor;

  ComboBoxEncoding.Font.Color := skinColor;
  ComboBoxEncoding.Color := bgColor;

end;

procedure TForm1.MenuItemSkinBlueClick(Sender: TObject);
begin
  SetSkin(0, clWhite, $009C9623);
  if Sender <> nil then ConfigSave;
end;

procedure TForm1.MenuItemSkinWhiteClick(Sender: TObject);
begin
  SetSkin(1, clBlack, $00B7B7B7);
  if Sender <> nil then ConfigSave;
end;

procedure TForm1.MenuItemSkinBlackClick(Sender: TObject);
begin
  SetSkin(2, RGB(200, 200, 200), RGB(20, 20, 20));
  if Sender <> nil then ConfigSave;
end;

procedure TForm1.MenuItemStartOnBootClick(Sender: TObject);
begin
  TMenuItem(Sender).Checked := not TMenuItem(Sender).Checked;
  StartWithWindows(TMenuItem(Sender).Checked);
end;

procedure TForm1.CheckUpdate();
var lastVersion: String;
begin
  if not FileExists('wget.exe') then exit;
  DownloadFile('https://github.com/ddeeproton/YoutubeDownloader/raw/master/lastversion.txt','lastversion.txt', True, False);
  if not FileExists('lastversion.txt') then exit;
  lastVersion := ReadFile('lastversion.txt');
  DeleteFile(PChar('lastversion.txt'));
  if CurrentVersion = lastVersion then exit;
  if MessageDlg('Une mise à jour est disponible. Télécharger?',  mtConfirmation, [mbYes, mbNo], 0) <> IDYES then Exit;
  MenuItemUpdateClick(nil);
end;

procedure TForm1.MenuItemUpdateClick(Sender: TObject);
var lastVersion: String;
begin
  if not FileExists('wget.exe') then
  begin
    ShowMessage('Il manque l''application wget.exe à côté de cette application pour la mise à jour. Essayez d''installer l''application manuellement à la place.');
    exit;
  end;
  DownloadFile('https://github.com/ddeeproton/YoutubeDownloader/raw/master/lastversion.txt','lastversion.txt', True, False);

  if not FileExists('lastversion.txt') then
  begin
    ShowMessage('Vous ne semblez pas connecté à Internet');
    exit;
  end;

  lastVersion := ReadFile('lastversion.txt');
  DeleteFile(PChar('lastversion.txt'));

  if CurrentVersion = lastVersion then
  begin
    ShowMessage('Vous êtes à jour :)');
    exit;
  end;

  DownloadFile('https://github.com/ddeeproton/YoutubeDownloader/raw/master/Setup%20installation/YoutubeDownloaderSetup_'+lastVersion+'.exe','YoutubeDownloaderSetup_'+lastVersion+'.exe', True, True);

  if not FileExists('YoutubeDownloaderSetup_'+lastVersion+'.exe') then
  begin
    ShowMessage('Erreur lors du téléchargement de la mise à jour');
    exit;
  end;

  ExecuteProcess('"YoutubeDownloaderSetup_'+lastVersion+'.exe" /S');
  Application.Terminate;

end;

procedure TForm1.MenuItemUpdateOnBootClick(Sender: TObject);
begin
  TMenuItem(Sender).Checked := not TMenuItem(Sender).Checked;
  ConfigSave;
end;


procedure TForm1.MenuItemHideClick(Sender: TObject);
begin
  Hide;
  setFormHeight(60);
end;

procedure TForm1.setFormAtBottomRight;
var x,y: Integer;
begin
  Left := Screen.WorkAreaWidth  - Form1.Width  + Screen.WorkAreaLeft;
  Top  := Screen.WorkAreaHeight - Form1.Height + Screen.WorkAreaTop;
end;

procedure TForm1.ButtonPasteClick(Sender: TObject);
begin
  EditHTTP.Clear;
  EditHTTP.PasteFromClipboard;
end;

procedure TForm1.ComboBoxEncodingChange(Sender: TObject);
begin
  ConfigSave;
end;


procedure TForm1.ButtonDownloadClick(Sender: TObject);
begin
  DoDownload();

end;

procedure TForm1.ButtonMenuClick(Sender: TObject);
begin
  PopupMenuTray.PopUp;
end;

procedure TForm1.ButtonSetDownloadPathClick(Sender: TObject);
begin
  if not SelectDirectoryDialog1.Execute then exit;
  EditPath.Text := SelectDirectoryDialog1.FileName;
  ConfigSave;
end;


procedure TForm1.ButtonDownloadKeyPress(Sender: TObject; var Key: char);
begin
  if ord(Key) = 27 then MenuItemHideClick(nil);
  if ord(Key) = 13 then ButtonDownloadClick(nil);
end;



procedure TForm1.SplitStr(const Source, Delimiter: String; var DelimitedList: TStringList);
var
  s: PChar;
  DelimiterIndex: Integer;
  Item: String;
begin
  s:=PChar(Source);
  repeat
    DelimiterIndex:=Pos(Delimiter, s);
    if DelimiterIndex=0 then Break;
    Item:=Copy(s, 1, DelimiterIndex-1);
    DelimitedList.Add(Item);
    inc(s, DelimiterIndex + Length(Delimiter)-1);
  until DelimiterIndex = 0;
  DelimitedList.Add(s);
end;

function TForm1.getEncoding(): String;
var
  i:integer;
  media_type, media_format, media_quality: String;
  data: TStringList;
begin
  data := TStringList.Create;
  SplitStr(ComboBoxEncoding.Text,' ',data);

  if data.Count = 1 then
  begin
    media_format := ComboBoxEncoding.Text;
    media_quality := '';
    media_type := '';
  end;
  if data.Count = 2 then
  begin
    media_type := data.Strings[0];
    media_format := data.Strings[1];
    media_quality := '';
  end;
  if data.Count = 3 then
  begin
    media_type := data.Strings[0];
    media_format := data.Strings[1];
    media_quality := data.Strings[2];
  end;
  if media_type = 'audio' then
  begin
    media_type := '--extract-audio ';
    if media_format = 'ogg' then media_format := 'vorbis';
    if media_format <> '' then media_format := ' --audio-format '+media_format;
    if media_quality <> '' then media_quality := ' --audio-quality '+media_quality;
    result := media_type + media_format + media_quality;
  end else
  begin
    result := '-f '+media_format;
  end;

end;

procedure TForm1.DoDownload();
var url: String;
begin
  url := EditHTTP.Text;
  if url = '' then
  begin
    ShowMessage('Veuillez entrer d''abord un lien avant de cliquer sur Télécharger.');
    exit;
  end;

  if ComboBoxEncoding.Text = 'fichier brut' then
  begin
    DownloadFileToDir(url, EditPath.Text, False, True);
  end else
  begin
    if url.Contains('https://www.mixcloud.com/') then
      DoDownloadWithMixcloud
    else
      DoDownloadWithYoutubeDl;
  end;

  if MenuItemHideOnDownload.Checked then
    MenuItemHideClick(nil);

end;



procedure TForm1.DoDownloadWithYoutubeDl();
var
  UseCache: String;
  WindRect: TRect;
  CmdHandle: Handle;
  VolumeWidth, VolumeHeight, VolumeTop, VolumeLeft: Integer;
begin

  if not FileExists(Config_YoutubeDownloader) then
  begin
    ShowMessage('youtube-dl.exe est introuvable. Il doit se trouver à côté de cette application pour fonctionner.');
    exit;
  end;

  if EditHTTP.Text = '' then
  begin
    ShowMessage('Veuillez entrer d''abord un lien avant de cliquer sur Télécharger.');
    exit;
  end;

  if not DirectoryExists(EditPath.Text) then
  begin
    if not SelectDirectoryDialog1.Execute then exit;
    EditPath.Text := SelectDirectoryDialog1.FileName;
    ConfigSave;
  end;

  UseCache := '';
  if MenuItemCacheToggle.Checked then
    UseCache := '--download-archive "archive.txt"';

  Process1.ApplicationName := Config_YoutubeDownloader;
  Process1.CommandLine := ' '+UseCache
                       +' --ignore-errors '
                       +getEncoding()
                       +' --restrict-filenames -o "'+EditPath.Text+'\%(title)s.%(ext)s" '
                       +'"'+EditHTTP.Text+'"';

  Process1.Execute;
  Application.ProcessMessages;
  Sleep(1000);


  CmdHandle := FindWindowByTitle(Config_YoutubeDownloader);
  // Récupère les informations de la fenêtre (largeur, hauteur)
  GetWindowRect(CmdHandle, WindRect);
  // Mémorise les dimensions de la fenêtre du volume
  VolumeWidth := WindRect.Right - WindRect.Left;
  VolumeHeight := WindRect.Bottom - WindRect.Top;
  VolumeTop := Screen.WorkAreaHeight - VolumeHeight;
  VolumeLeft := Screen.WorkAreaWidth - VolumeWidth;
  // Déplace la fenêtre en bas de l'écran
  MoveWindow(CmdHandle, VolumeLeft, VolumeTop, VolumeWidth, VolumeHeight, true);
end;


procedure TForm1.DoDownloadWithMixcloud();
var
  url, filename: String;
  i: Integer;
begin
  url := EditHTTP.Text;
  if url = '' then
  begin
    ShowMessage('Veuillez entrer d''abord un lien avant de cliquer sur Télécharger.');
    exit;
  end;
  if not SelectDirectoryDialog1.Execute then exit;
  // Get the filename in last position of url
  i := url.LastIndexOf('/');
  if i = Length(url)-1 then
    url := Copy(url, 0, Length(url)-1);
  i := url.LastIndexOf('/');
  filename := Copy(url, i+2);
  url := url.Replace('https://www.mixcloud.com/', 'http://download.mixcloud-downloader.com/d/mixcloud/');
  DownloadFile(url, SelectDirectoryDialog1.FileName+'\'+filename+'.m4a', False, True);
end;

procedure TForm1.TimerClipboardTimer(Sender: TObject);
var url, message: string;
begin
  url := clipbrd.Clipboard.AsText;
  if url = oldClipboardValue then exit;
  oldClipboardValue := url;
  if not url.StartsWith('http', true) then exit;
  MenuItemShowClick(nil);
  ButtonPasteClick(nil);
  {
  // TODO
  //Application.ProcessMessages;
  //Application.Restore;
  //Application.RestoreStayOnTop(True);
  //LCLIntf.SetForegroundWindow(Form1.Handle);
  //LCLIntf.SetFocus(EditHTTP.Handle);
  //Application.ProcessMessages;
  //LCLIntf.SetFocus(Application.MainFormHandle);
  ShowWindow(Form1.Handle,SW_SHOW);
  Form1.SetFocus;
  BringWindowToTop(Form1.Handle);
  SetActiveWindow(Form1.Handle);
  SetForegroundWindow(Form1.Handle);
  ComboBoxEncoding.SetFocus;
  SetForegroundWindow(FindWindowA(nil, Pchar(Caption)));
  }
  //Windows.SetFocus(Application.MainFormHandle);
  {
  if Length(url) > 100 then url := url.Substring(0, 100)+'...';
  if url.Contains('https://www.mixcloud.com/') then
    message := 'Voulez-vous télécharger en format "m4a"? (pas d''autre choix de compression possible)'
  else
    message := 'Voulez-vous télécharger en format "'+ComboBoxEncoding.Text+'"?';
  if MessageDlg(message+#13#10#13#10+url,  mtConfirmation, [mbYes, mbNo], 0) <> IDYES then Exit;
  ButtonDownloadClick(nil);
  }
end;


end.

