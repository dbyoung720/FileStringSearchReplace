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
  Writeln('功能 : 在文件中进行字符串的搜索替换');
  Writeln('作者 : dbyoung@sina.com');
  Writeln('时间 : 2020-08-16');
  Writeln('格式 : fsr [文件路径],[文件类型],[待替换字符串],[替换字符串],[是否包含子目录],[是否区分大小写],[文件保存编码格式],[VC 工程添加 MT 编译]');
  Writeln('示范 : fsr ''C:\Windows'',''*.txt'',''AAA'',''BBB'',1,0,''utf8'', 1');
  Writeln('注意 : 参数用符号,分割；中间不能有空格。前四个参数必须，后四个参数可省略');
end;

{ 给 VC 工程添加 MT 编译 }
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
    Writeln(Format('%s 添加 MT 编译', [strFileName]));
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
      lstFile.LoadFromFile(sFile, ft);
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
        Writeln(Format('%s 替换成功', [sFile]));
      end;

      { 给 VC 工程文件添加 MT 编译 }
      if bVCAddMT and (not bReplace) and SameText(ExtractFileExt(sFile), '.vcxproj') then
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

{ 文件的字符串搜索替换 }
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
  { 参数必须不少于 4 个 }
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

  { 其它 4 个参数 }
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
    Writeln('没有找到满足条件的文件');
    Exit;
  end;

  SearchAndReplaceInFile(arrFiles, bCase, strSearch, strReplace, strEncoding, bVCAddMT);
end;

begin
  FilesSearchAndReplace;

end.
