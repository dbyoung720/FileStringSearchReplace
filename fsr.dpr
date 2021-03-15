program fsr;
{$IF CompilerVersion >= 21.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}
{$APPTYPE CONSOLE}
{$R *.res}

uses
  NativeXml,
  Winapi.Windows,
  System.StrUtils,
  System.Types,
  System.IOUtils,
  System.Classes,
  System.SysUtils;

procedure ShowHelp;
begin
  Writeln('���� : ���ļ��н����ַ����������滻');
  Writeln('���� : dbyoung@sina.com');
  Writeln('ʱ�� : 2020-08-16');
  Writeln('��ʽ : fsr [�ļ�·��],[�ļ�����],[���滻�ַ���],[�滻�ַ���],[�Ƿ������Ŀ¼],[�Ƿ����ִ�Сд],[�ļ���������ʽ],[VC ������� MT ����]');
  Writeln('ʾ�� : fsr ''C:\Windows'',''*.txt'',''AAA'',''BBB'',1,0,''utf8'', 1');
  Writeln('ע�� : �����÷���,�ָ�м䲻���пո�ǰ�ĸ��������룬���ĸ�������ʡ��');
end;

{ �� VC ������� MT ���� }
procedure VCAddMT(const strFileName: string);
var
  xmlDocument: TNativeXml;
  pNode      : TXmlNode;
  gNode      : TXmlNode;
  cNode      : TXmlNode;
begin
  xmlDocument := TNativeXml.Create(nil);
  xmlDocument.LoadFromFile(strFileName);
  xmlDocument.XmlFormat := xfReadable;
  try
    pNode := xmlDocument.RootNodes[1];
    if pNode = nil then
      Exit;

    gNode       := pNode.NodeFindOrCreate('ItemDefinitionGroup').NodeFindOrCreate('ClCompile');
    cNode       := gNode.NodeNew('RuntimeLibrary');
    cNode.Value := 'MultiThreaded';

    xmlDocument.SaveToFile(strFileName);
    Writeln(Format('��� MT ����  %s', [strFileName]));
  finally
    xmlDocument.free;
  end;
end;

procedure SearchAndReplaceInFile(const arrFile: TStringDynArray; const bCase: Boolean; const strSearch, strReplace, strEncoding: string; const bVCAddMT: Boolean);
var
  sFile   : String;
  lstFile : TStringList;
  I       : Integer;
  ft      : TEncoding;
  strTemp : String;
  bReplace: Boolean;
begin
  ft := TEncoding.ASCII;
  if SameText('ASCII', strEncoding) then
    ft := TEncoding.ASCII
  else if SameText('ANSI', strEncoding) then
    ft := TEncoding.ANSI
  else if SameText('Unicode', strEncoding) then
    ft := TEncoding.Unicode
  else if SameText('UTF7', strEncoding) then
    ft := TEncoding.UTF7
  else if SameText('UTF8', strEncoding) then
    ft := TEncoding.UTF8;

  lstFile := TStringList.Create;
  try
    for sFile in arrFile do
    begin
      bReplace := False;
      try
        lstFile.LoadFromFile(sFile, ft);
      except
        lstFile.Clear;
        Continue;
      end;

      for I := 0 to lstFile.Count - 1 do
      begin
        strTemp := lstFile.Strings[I];
        if bCase then
          lstFile.Strings[I] := lstFile.Strings[I].Replace(strSearch, strReplace, [rfReplaceAll])
        else
          lstFile.Strings[I] := lstFile.Strings[I].Replace(strSearch, strReplace, [rfReplaceAll, rfIgnoreCase]);
        bReplace             := bReplace or (not SameText(strTemp, lstFile.Strings[I]));
      end;

      if bReplace then
      begin
        lstFile.SaveToFile(sFile, ft);
        Writeln(Format('%s �滻�ɹ�', [sFile]));
      end;

      { �� VC �����ļ���� MT ���� }
      if bVCAddMT and (not bReplace) and SameText(ExtractFileExt(sFile), '.vcxproj') and FileExists(sFile) then
      begin
        VCAddMT(sFile);
      end;

      lstFile.Clear;
    end;
  finally
    lstFile.free;
  end;
end;

function MiddleStr(const strValue: string): String;
begin
  Result := MidStr(strValue, 2, Length(strValue) - 2);
end;

{ �ļ����ַ��������滻 }
procedure FilesSearchAndReplace;
var
  strFilePath: String;
  strFileType: String;
  strSearch  : String;
  strReplace : String;
  bSubDir    : Boolean;
  bCase      : Boolean;
  strEncoding: string;
  arrFiles   : TStringDynArray;
  strParam   : string;
  arrParam   : TStringDynArray;
  I          : Integer;
  bVCAddMT   : Boolean;
begin
  { �������벻���� 4 �� }
  strParam := string(GetCommandLine);
  I        := Pos(' ''', strParam);
  strParam := RightStr(strParam, Length(strParam) - I);
  arrParam := strParam.Split([',']);
  if Length(arrParam) < 4 then
  begin
    ShowHelp;
    Exit;
  end;

  strFilePath := MiddleStr(arrParam[0]);
  strFileType := MiddleStr(arrParam[1]);
  strSearch   := MiddleStr(arrParam[2]);
  strReplace  := MiddleStr(arrParam[3]);

  { ���� 4 ������ }
  bSubDir     := True;
  bCase       := False;
  bVCAddMT    := False;
  strEncoding := 'ASCII';

  if Length(arrParam) = 8 then
  begin
    bSubDir     := StrToBool(arrParam[4]);
    bCase       := StrToBool(arrParam[5]);
    strEncoding := MiddleStr(arrParam[6]);
    bVCAddMT    := StrToBool(arrParam[7]);
  end
  else if Length(arrParam) = 7 then
  begin
    bSubDir     := StrToBool(arrParam[4]);
    bCase       := StrToBool(arrParam[5]);
    strEncoding := MiddleStr(arrParam[6]);
  end
  else if Length(arrParam) = 6 then
  begin
    bSubDir := StrToBool(arrParam[4]);
    bCase   := StrToBool(arrParam[5]);
  end
  else if Length(arrParam) = 5 then
  begin
    bSubDir := StrToBool(arrParam[4]);
  end;

  if bVCAddMT then
  begin
    strEncoding := 'UTF8';
  end;

  if bSubDir then
    arrFiles := TDirectory.GetFiles(strFilePath, strFileType, TSearchOption.soAllDirectories)
  else
    arrFiles := TDirectory.GetFiles(strFilePath, strFileType, TSearchOption.soTopDirectoryOnly);

  if Length(arrFiles) = 0 then
  begin
    Writeln('û���ҵ������������ļ�');
    Exit;
  end;

  Writeln(Format('�����ҵ� %d ���ļ�', [Length(arrFiles)]));
  SearchAndReplaceInFile(arrFiles, bCase, strSearch, strReplace, strEncoding, bVCAddMT);
end;

begin
  FilesSearchAndReplace;

end.
