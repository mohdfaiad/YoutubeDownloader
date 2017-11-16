unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, XMLConf, FileUtil, Forms, Controls, Graphics,
  Dialogs, StdCtrls, Menus, ExtCtrls, clipbrd, Windows, lclintf;

var
  CurrentVersion : String = '0.0.14';

type

  { TForm1 }

  TForm1 = class(TForm)
    ButtonMenu: TButton;
    ButtonDownloadWAV: TButton;
    ComboBoxEncoding: TComboBox;
    Edit1: TEdit;
    Label1: TLabel;
    MenuItem1: TMenuItem;
    MenuItemCacheToggle: TMenuItem;
    MenuItemAbout: TMenuItem;
    MenuItemUpdate: TMenuItem;
    MenuItemCacheHelp: TMenuItem;
    MenuItemCacheClear: TMenuItem;
    MenuItemCacheOpen: TMenuItem;
    MenuItemHide: TMenuItem;
    MenuItemExit: TMenuItem;
    PopupMenuTray: TPopupMenu;
    Process1: TProcess;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    TimerAfterLoad: TTimer;
    TimerClipboard: TTimer;
    TrayIcon1: TTrayIcon;
    XMLConfig1: TXMLConfig;
    procedure ButtonMenuClick(Sender: TObject);
    procedure ButtonDownloadClick(Sender: TObject);
    procedure ButtonPasteClick(Sender: TObject);
    procedure ComboBoxEncodingChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItemAboutClick(Sender: TObject);
    procedure MenuItemCacheClearClick(Sender: TObject);
    procedure MenuItemCacheHelpClick(Sender: TObject);
    procedure MenuItemCacheOpenClick(Sender: TObject);
    procedure MenuItemCacheToggleClick(Sender: TObject);
    procedure MenuItemExitClick(Sender: TObject);
    procedure MenuItemHideClick(Sender: TObject);
    procedure MenuItemShowClick(Sender: TObject);
    procedure MenuItemUpdateClick(Sender: TObject);
    procedure TimerAfterLoadTimer(Sender: TObject);
    procedure TimerClipboardTimer(Sender: TObject);
    procedure DoDownload();
    function GetWinDir: string;
    procedure ExecuteProcess(cmd: String);
    procedure ExecuteProcess(cmd: String; pwait, pshow: Boolean);
    function getEncoding(): String;
    procedure ConfigSave;
    procedure ConfigLoad;
    procedure WriteFile(Filename, Content : String);
    function ReadFile(Filename: String):String;
    procedure DownloadFile(http, filename: String; pshow: Boolean);
    procedure CheckUpdate();
  private
    { private declarations }
  public
    { public declarations }
  end;


var
  Form1: TForm1;
  Config_YoutubeDownloader: String = 'youtube-dl.exe';
  oldClipboardValue: String = '';

implementation

{$R *.lfm}

{ TForm1 }


procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.Height:= 66;
  Edit1.Text:= '';
  ConfigLoad;
  Caption := 'Youtube Downloader V '+CurrentVersion;
end;

procedure TForm1.ConfigLoad;
begin
  if not FileExists('config.xml') then exit;
  XMLConfig1 := TXMLConfig.Create(nil);
  XMLConfig1.LoadFromFile('config.xml');
  ComboBoxEncoding.ItemIndex := XMLConfig1.GetValue('Encoding', 4);
  MenuItemCacheToggle.Checked := XMLConfig1.GetValue('UseCache', True);
  XMLConfig1.Free;
end;

procedure TForm1.ConfigSave;
begin
  XMLConfig1 := TXMLConfig.Create(nil);
  XMLConfig1.SetValue('Encoding', ComboBoxEncoding.ItemIndex);
  XMLConfig1.SetValue('UseCache', MenuItemCacheToggle.Checked);
  XMLConfig1.SaveToFile('config.xml');
  XMLConfig1.Free;
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
  GetWindowsDirectory(dir, MAX_PATH);
  Result := StrPas(dir);
end;

procedure TForm1.ExecuteProcess(cmd: String);
var p: TProcess;
begin
  p := TProcess.Create(nil);
  p.ApplicationName:= '';
  p.CommandLine:= cmd;
  p.Execute;
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
  ShowMessage('Source: https://github.com/ddeeproton/YoutubeDownloader');
end;


procedure TForm1.DownloadFile(http, filename: String; pshow: Boolean);
begin
  if FileExists(filename) then DeleteFile(PChar(filename));
  ExecuteProcess('wget.exe -O "'+filename+'" "'+http+'" --no-check-certificate', true, pshow);
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



procedure TForm1.CheckUpdate();
var lastVersion: String;
begin
  if not FileExists('wget.exe') then exit;
  DownloadFile('https://github.com/ddeeproton/YoutubeDownloader/raw/master/lastversion.txt','lastversion.txt', False);
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
  DownloadFile('https://github.com/ddeeproton/YoutubeDownloader/raw/master/lastversion.txt','lastversion.txt', False);

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

  DownloadFile('https://github.com/ddeeproton/YoutubeDownloader/raw/master/Setup%20installation/YoutubeDownloaderSetup_'+lastVersion+'.exe','YoutubeDownloaderSetup_'+lastVersion+'.exe', True);

  if not FileExists('YoutubeDownloaderSetup_'+lastVersion+'.exe') then
  begin
    ShowMessage('Erreur lors du téléchargement de la mise à jour');
    exit;
  end;

  ExecuteProcess('"YoutubeDownloaderSetup_'+lastVersion+'.exe" /S');
  Application.Terminate;

end;

procedure TForm1.TimerAfterLoadTimer(Sender: TObject);
begin
  TimerAfterLoad.Enabled := False;
  CheckUpdate();
end;

procedure TForm1.MenuItemHideClick(Sender: TObject);
begin
  Hide;
end;

procedure TForm1.ButtonPasteClick(Sender: TObject);
begin
  Edit1.Clear;
  Edit1.PasteFromClipboard;
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

function TForm1.getEncoding(): String;
var
  i:integer;
  audio_format, audio_quality: String;
begin
  i := Pos(' ', ComboBoxEncoding.Text);
  if i = 0 then
  begin
    audio_format := ComboBoxEncoding.Text;
    audio_quality := '';
  end else
  begin
    audio_format := Copy(ComboBoxEncoding.Text, 0, i);
    audio_quality := Copy(ComboBoxEncoding.Text, i+1);
  end;
  if audio_format = 'ogg' then audio_format := 'vorbis';

  if audio_format <> '' then audio_format := ' --audio-format '+audio_format;
  if audio_quality <> '' then audio_quality := ' --audio-quality '+audio_quality;

  result := audio_format + audio_quality;
end;

procedure TForm1.DoDownload();
var UseCache: String;
begin
  if Edit1.Text = '' then
  begin
    ShowMessage('Veuillez entrer d''abord un lien Youtube avant de cliquer sur Télécharger.');
    exit;
  end;

  if not FileExists(Config_YoutubeDownloader) then
  begin
    ShowMessage('youtube-dl.exe est introuvable. Il doit se trouver à côté de cette application pour fonctionner.');
    exit;
  end;

  if not SelectDirectoryDialog1.Execute then exit;

  UseCache := '';
  if MenuItemCacheToggle.Checked then
    UseCache := '--download-archive "archive.txt"';

  Process1.ApplicationName := Config_YoutubeDownloader;
  Process1.CommandLine := ' -q '+UseCache+' --ignore-errors --extract-audio '+getEncoding()
                       +' --restrict-filenames -o "'+SelectDirectoryDialog1.FileName+'\%(title)s.%(ext)s" '
                       +'"'+Edit1.Text+'"';
  Process1.Execute;
end;

procedure TForm1.TimerClipboardTimer(Sender: TObject);
var url: string;
begin
  url := clipbrd.Clipboard.AsText;
  if url = oldClipboardValue then exit;
  oldClipboardValue := url;
  if not url.StartsWith('http', true) then exit;
  MenuItemShowClick(nil);
  if Length(url) > 100 then url := url.Substring(0, 100)+'...';
  if MessageDlg('Voulez-vous télécharger en format "'+ComboBoxEncoding.Text+'"?'+#13#10#13#10+url,  mtConfirmation, [mbYes, mbNo], 0) <> IDYES then Exit;
  ButtonPasteClick(nil);
  ButtonDownloadClick(nil);
end;


end.

