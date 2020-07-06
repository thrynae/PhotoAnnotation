function PhotoAnnotation
% This function opens a GUI showing a photo and user-added comments.
% These comments extracted from the comment field, which is possible for
% jpeg, tif or png. Other file types might work as well, but are unlikely
% to work.
%
% A setup file to make this function 1-click should be available at:
% http://tiny.cc/PhotoAnnotation
% Because of overzealous anti-virus detection, it may be necessary to
% download some files and generate a setup yourself. This should still be
% a 1-click solution.
%
% There is a dictionary, so multiple languages can be selected from.
% Currently, only English and Dutch are included (English being the
% default). You can e-mail me translations if you would like me to add them
% (see the end of this help text for an e-mail address).
%
% The description that is entered in the text field, automatically is
% converted to a square matrix, which is padded with spaces. Line breaks
% are encoded with tilde signs (~) when written out, as that is a character
% that is unlikely to be used, but is still encoded in a stable way.
% Non-ASCII characters are encoded as a double tilde followed by the 4
% position hexadecimal representation of the unicode code point.
%
% The exif data is kept intact using exiftool.exe, which can't be packaged
% in this submission, because of the Mathworks rules. You can manually
% download a new copy from
% https://sno.phy.queensu.ca/~phil/exiftool/exiftool-10.61.zip or from the
% capture in The Wayback Machine (web.archive.org).
% If the file is missing, it will be downloaded.
%
% While it is possible to call this from Matlab/Octave, this function is
% designed to be called by a batch file included in the comment block
% below. The batch file downloads and extracts Octave 4.2.1 portable.
%
% In the options screen, it is possible to select the GUI language, the
% checkbox can be set (which results in the description being saved to file
% on exit or loading another image), the startup behavior can be set (open
% last file, open file picker in dir of last file or open file picker in
% pwd) and a button to check for an update is available. This updater tries
% to load the newest version from the Mathworks website, so when they
% change the URL syntax, this update will break.
%
% Compatibility:
% Matlab: should work on most releases (tested on R2017b and R2012b)
%         (for releases pre-2013a, you need a replacement for strsplit)
% Octave: tested on 4.2.1
% OS:     written on Windows 10 (x64), there is a Mac version for exiftool.
%         For other platforms, a Perl version is available as well.
%         The code should work cross-platform.
%
% Version: 1.4
% Date:    2017-11-10
% Author:  H.J. Wisselink
% Email=  'h_j_wisselink*alumnus_utwente_nl';
% Real_email = regexprep(Email,{'*','_'},{'@','.'})
%
% Changes from v1.0 to v1.1:
% - Changed save command to be compatible for switching use between Octave
%   and Matlab.
% - Implemented rotation if EXIF encodes it.
% - Updated batch files (different bat2exe, this one doesn't need pro).
% - Slightly tweaked position of buttons.
% - Set the color of the background to black and checkboxtext to white.
% - Changed default for CheckboxState to false.
% - Implemented command line input (open with exe/bat).
% - Switched the default behavior to the version with cmd screen in the
%   bat. The reason being that this makes pinning easier.
%
% Changes from v1.1 to v1.2
% - Changed the batch files to enable 'open with'.
% - Fixed a bug with the auto-save
% - Added support for non-ASCII, encoding unicode with a double tilde
%   followed by the unicode codepoint in hexadecimal. For compatibility
%   with previous versions, the line ending encoding was kept as a tilde.
% - Added dictionary (if you e-mail me your translation, I'll add it to the
%   next update).
% - Added an update functionality which checks the FEX website.
% - Added an option screen, where you can set the language, set the
%   auto-saving of the description and check for updates.
% - Added a method so the default language can be set with the setup.
%
% Changes from v1.2 to v1.3
% - Fixed a bug where the last loaded image wasn't re-opened at restart,
%   but only the last image selected with the file picker.
% - Added control of startup behavior in the options window.
% - Added an indication of when a a button is active (green background).
% - Changed the implementation of the saving of descriptions, which should
%   be faster now for unchanged descriptions.
% - Confirmed compatibility with Matlab R2017b
%
% Changes from v1.3 to v1.4
% - Addressed a bug that is caused by char>256 not extracted correctly from
%   the text field.

%Script used to convert batch file below to an executable file.
%{
del PhotoAnnotation.exe
del PhotoAnnotation_silent.exe
::Create a normal version (which shows the cmd screen) and a silent (-invisible) version.
::This converter only accepts #,#,#,# as fileversion

::portable x86 exe in the portable folder from this zip:
::https://web.archive.org/web/20170707220947/http://www.f2ko.de/downloads/Bat_To_Exe_Converter.zip

Bat_To_Exe_Converter.exe -bat backend.bat -save PhotoAnnotation_silent.exe -icon icon.ico -invisible -nodelete -fileversion 1,1,0,0 -productname PhotoAnnotation -description "Photo viewer with integrated description editor"
Bat_To_Exe_Converter.exe -bat backend.bat -save PhotoAnnotation.exe -icon icon.ico -nodelete -fileversion 1,1,0,0 -productname PhotoAnnotation -description "Photo viewer with integrated description editor"
%}


% Contents of the backend.bat file, which was converted to exe with
% 'Bat To Exe Converter'. This program can be downloaded at the URL below.
%{
::This batch file can be converted to an exe, which runs with a visual screen.
::A silent version will be compiled as well, so warnings can be hidden.
::
::This file will test if the octave portable is downloaded and unpacked,
::after which it starts the gui with octave.

::converted to exe with Bat To Exe Converter
::https://web.archive.org/web/20170707220947/http://www.f2ko.de/downloads/Bat_To_Exe_Converter.zip
@echo off

::make sure the current folder is set to the program folder
cd /d "%~d0%~p0"

::if Octave is not yet downloaded start a non-hidden cmd window to download it.
IF NOT EXIST "octave.bat" goto DowloadOctave

Rem   Find Octave's install directory through cmd.exe variables.
Rem   This batch file should reside in Octaves installation subdir!
Rem
Rem   This trick finds the location where the batch file resides.
Rem   Note: the result ends with a backslash
set OCT_HOME=%~dp0
Rem Coonvert to 8.3 format so dont have to worry about spaces
for %%I in ("%OCT_HOME%") do set OCT_HOME=%%~sI

Rem   Set up PATH. Make sure the octave bin dir
Rem   comes first.

set PATH=%OCT_HOME%qt5\bin;%OCT_HOME%bin;%PATH%

Rem   Set up any environment vars we may need

set TERM=cygwin
set GNUTERM=windows
set GS=gs.exe

Rem set home if not already set
if "%HOME%"=="" set HOME=%USERPROFILE%
if "%HOME%"=="" set HOME=%HOMEDRIVE%%HOMEPATH%
Rem set HOME to 8.3 format
for %%I in ("%HOME%") do set HOME=%%~sI

Rem   Start Octave
Rem   This supports inclusion of an input argument,
Rem   which the code currently ignores.
octave-gui.exe PhotoAnnotation.m %1

goto :eof

:DowloadOctave
start PhotoAnnotation_internal.bat
%}



% Contents of the PhotoAnnotation_internal.bat file:
%{
::this file will test if the octave portable is downloaded and unpacked
::after this, it will restart the exe file (or backend.bat)
@ECHO OFF

:: n is the name, x yields the extension
SET name_of_this_script=%~n0%~x0
SET open_on_close=PhotoAnnotation.exe
IF NOT EXIST %open_on_close% SET open_on_close=backend.bat

::if the file exists, skip to the actual running.
IF EXIST "octave.bat" goto OctaveIsExtracted
IF EXIST "octave-4.2.1-w32.zip" goto OctaveIsDownloaded
ECHO The runtime (Octave portable 4.2.1) will now be downloaded.
ECHO This may take a long time, as it is about 280MB.
ECHO .
ECHO If this download restarts multiple times, you can manually download the octave-4.2.1-w32.zip from the GNU website. Make sure to unpack the contents.
::if this errors, you can uncomment the line with archive.org (which doesn't report total size during download)
curl http://ftp.gnu.org/gnu/octave/windows/octave-4.2.1-w32.zip > octave-4.2.1-w32.zip
::curl http://web.archive.org/web/20170827205614/https://ftp.gnu.org/gnu/octave/windows/octave-4.2.1-w32.zip > octave-4.2.1-w32.zip
:OctaveIsDownloaded
::check to see if the file size is the correct size to assume a successful download
::if the file size is incorrect, delete the file, restart this script to attempt a new download
::file size should be 293570269 bytes
call :filesize octave-4.2.1-w32.zip
IF /I "%size%" GEQ "293560000" goto OctaveIsDownloadedSuccessfully
del octave-4.2.1-w32.zip
::start new instance and exit and release this one
start %name_of_this_script%
exit
:OctaveIsDownloadedSuccessfully
IF EXIST "octave.bat" goto OctaveIsExtracted
::unzip and move those contents to the current folder
ECHO Unzipping octave portable, this may take a moment.
cscript //B j_unzip.vbs octave-4.2.1-w32.zip
SET src_folder=octave-4.2.1
SET tar_folder=%cd%
for /f %%a IN ('dir "%src_folder%" /b') do move %src_folder%\%%a %tar_folder%
:OctaveIsExtracted
::restart the wrapper exe and detach this visible screen
start %open_on_close%
exit
goto :eof

:filesize
set size=%~z1
exit /b 0
%}


%This vbs script can be used to unzip files, without the need for an extra
%executable that could set off an overzealous anti-virus.
%{
' j_unzip.vbs
' UnZip a file script
' By Justin Godden 2010
' It's a mess, I know!!!

' Dim ArgObj, var1, var2
Set ArgObj = WScript.Arguments
If (Wscript.Arguments.Count > 0) Then
var1 = ArgObj(0)
Else
var1 = ""
End if
If var1 = "" then
strFileZIP = "example.zip"
Else
strFileZIP = var1
End if
'The location of the zip file.
REM Set WshShell = CreateObject("Wscript.Shell")
REM CurDir = WshShell.ExpandEnvironmentStrings("%%cd%%")
Dim sCurPath
sCurPath = CreateObject("Scripting.FileSystemObject").GetAbsolutePathName(".")
strZipFile = sCurPath & "\" & strFileZIP
'The folder the contents should be extracted to.
outFolder = sCurPath
'original line: outFolder = sCurPath & "\"
WScript.Echo ( "Extracting file " & strFileZIP)
Set objShell = CreateObject( "Shell.Application" )
Set objSource = objShell.NameSpace(strZipFile).Items()
Set objTarget = objShell.NameSpace(outFolder)
intOptions = 256
objTarget.CopyHere objSource, intOptions
WScript.Echo ( "Extracted." )
%}

try
    isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
    exiftool = which('exiftool.exe');
    %If exiftool is missing, download it.
    if isempty(exiftool),exiftool=download_exiftool;end
    checkboxmat=[fileparts(exiftool) filesep 'CheckboxState.mat'];
    if ~exist(checkboxmat,'file')
        CheckboxState=false;
        LastLoaded='';%Last successfully loaded image.
        language=LoadDefaultLanguage([fileparts(exiftool) filesep]);
        StartupBehavior='LastLoaded';%Open LastLoaded image if possible
        save_settings(checkboxmat,...
            CheckboxState,LastLoaded,language,StartupBehavior)
    else
        S=load(checkboxmat);
        CheckboxState=S.CheckboxState;
        LastLoaded=S.LastLoaded;%Last successfully loaded image.
        if isfield(S,'language')
            language=S.language;
        else
            language='en_english';%default to English
        end
        if isfield(S,'StartupBehavior')
            StartupBehavior=S.StartupBehavior;
        else
            StartupBehavior='LastLoaded';%Open LastLoaded image if possible
        end
        clear S
        %Save settings after loading in case of new settings.
        save_settings(checkboxmat,...
            CheckboxState,LastLoaded,language,StartupBehavior)
    end
    %If a command line argument has been supplied, overwrite LastLoaded.
    if isOctave,commandlineargs=argv;else,commandlineargs='';end
    if ~isempty(commandlineargs)
        LastLoaded=commandlineargs{1};
    end
    
    h.isOctave=isOctave;
    h.exiftool=exiftool;
    h.checkboxmat=checkboxmat;
    h.ButtonCallbackBuzy=false;
    h.LastLoaded=LastLoaded;
    h.language=language;
    h.StartupBehavior=StartupBehavior;
    
    %Start up the GUI.
    h=start_GUI(h,CheckboxState);
    
    %Load image in accordance with StartupBehavior, unless a file was
    %provided in the command line (or 'open with').
    LoadImage([],[],h,~isempty(commandlineargs))
    h=guidata(h.fig);%Reload struct in case something was changed.
    if sum(double(h.filename))==0
        %Image selection was canceled.
        return
    end
    
    %Pause execution, but don't block execution of callbacks.
    uiwait
catch ME
    %Provide the user with a pop-up in case of an error.
    functionname=dbstack;functionname=functionname(1).name;
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function version_names=get_version_names
%List of version numbers that were uploaded to the File Exchange.
version_names={'1.0','1.1','1.2','1.3','1.4'};
end

function h=start_GUI(h,CheckboxState)
%Start up the GUI.
%The CheckboxState controls the initial value of the checkbox, which in
%turn controls if a save attempt is made when switching to another image.

%Load correct language dictionary struct.
dict=get_dictionary(h.language);
%Save dictionary to the output struct.
h.dict=dict;

%The position must be set, or it will usually open in a strange position,
%at least that is the case on my personal hardware setup in combination
%with Octave 4.2.1 portable.
screensize = get( 0, 'Screensize' );
h.pos.fig=[0.3 0.3 0.389 0.496].*screensize([3 4 3 4]);
h.fig=figure('NumberTitle','off',...
    'MenuBar','none',...
    'Color',[0 0 0],...
    'Units','pixel',...
    'Position',h.pos.fig);

%To prevent these to be executed before the figure actually exists, define
%them separately.
set(h.fig,'ResizeFcn',@(hObject,eventdata)...
    GUI_update(hObject,eventdata,guidata(hObject)))
set(h.fig,'KeyPressFcn',...
    @(hObject,eventdata)KeyPress(hObject,eventdata,guidata(hObject)))
set(h.fig,'CloseRequestFcn',@(hObject,eventdata)...
    SaveIfCheckboxChecked_close(hObject,eventdata,guidata(hObject)))

h.pos.savebutton=[0.825 0.825 0.15 0.075];
h.savebutton = uicontrol(...
    'Parent',h.fig,...
    'Units','normalized',...
    'String',dict.savebutton,...
    'Position',h.pos.savebutton,...
    'KeyPressFcn',...
    @(hObject,eventdata)KeyPress(hObject,eventdata,guidata(hObject)),...
    'Callback',@(hObject,eventdata)...
    SaveDescription(hObject,eventdata,guidata(hObject)));

h.pos.loadbutton=[0.825 0.9 0.15 0.075];
h.loadbutton = uicontrol(...
    'Parent',h.fig,...
    'Units','normalized',...
    'String',dict.loadbutton,...
    'Position',h.pos.loadbutton,...
    'KeyPressFcn',...
    @(hObject,eventdata)KeyPress(hObject,eventdata,guidata(hObject)),...
    'Callback',@(hObject,eventdata)...
    LoadImage(hObject,eventdata,guidata(hObject)));

h.pos.axis=[0.025 0.05 0.775 0];h.pos.axis(4)=1-h.pos.axis(2);
h.axis = axes(...
    'Parent',h.fig,...
    'XTick',[],...
    'YTick',[],...
    'Units','normalized',...
    'Position',h.pos.axis);

h.pos.textfield=[0.825 0 0.15 0.75];
h.textfield = uicontrol(...
    'Parent',h.fig,...
    'Units','normalized',...
    'String',{ dict.textfield },...
    'Style','edit',...
    'Position',h.pos.textfield,...
    'Children',[],...
    'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','left',...
    'Max',10);%max number of text lines

h.pos.optionbutton=[0.825 0.75 0.15 0.075];
h.optionbutton = uicontrol(...
    'Parent',h.fig,...
    'FontUnits',get(0,'defaultuicontrolFontUnits'),...
    'Units','normalized',...
    'String',dict.optionbutton,...
    'Position',h.pos.optionbutton,...
    'KeyPressFcn',...
    @(hObject,eventdata)KeyPress(hObject,eventdata,guidata(hObject)),...
    'Callback',@(hObject,eventdata)...
    OptionCallback(hObject,eventdata,guidata(hObject)));

h.pos.prevbutton=[0.025 0 0.3875 0.05];
h.prevbutton = uicontrol(...
    'Parent',h.fig,...
    'Units','normalized',...
    'String',dict.prevbutton,...
    'Position',h.pos.prevbutton,...
    'KeyPressFcn',...
    @(hObject,eventdata)KeyPress(hObject,eventdata,guidata(hObject)),...
    'Children',[],...
    'Callback',@(hObject,eventdata)...
    MoveImage(hObject,eventdata,guidata(hObject),-1));

appdata = [];
appdata.lastValidTag = 'nextbutton';
h.pos.nextbutton=[0.4125 0 0.3875 0.05];
h.nextbutton = uicontrol(...
    'Parent',h.fig,...
    'Units','normalized',...
    'String',dict.nextbutton,...
    'Position',h.pos.nextbutton,...
    'Children',[],...
    'KeyPressFcn',...
    @(hObject,eventdata)KeyPress(hObject,eventdata,guidata(hObject)),...
    'Callback',@(hObject,eventdata)...
    MoveImage(hObject,eventdata,guidata(hObject),+1));

%The following objects are for the option window.
version_names=get_version_names;

%Open the option figure.
h.fig_option=figure('NumberTitle','off',...
    'MenuBar','none',...
    'Visible','off',...
    'Color',[1 1 1],...
    'Name',['PhotoAnnotation ' dict.Version ' ' version_names{end}]);
%Make invisible instead of closing. This ensures the value of the checkbox
%is still readable.
set(h.fig_option,'CloseRequestFcn',@(hObject,eventdata)...
    OptionCloseReqFun(hObject,eventdata,guidata(hObject)))
cur_item=0;tot_items=4;

cur_item=cur_item+1;
h.pos.check_updatebutton=[0.1 (cur_item-1)/tot_items+0.1/tot_items 0.8 0.8/tot_items];
h.check_updatebutton= uicontrol(...
    'Parent',h.fig_option,...
    'Units','normalized',...
    'String',dict.check_updatebutton,...
    'Position',h.pos.check_updatebutton,...
    'Callback',@(hObject,eventdata)...
    get_update(hObject,eventdata,guidata(hObject)));

cur_item=cur_item+1;
h.pos.LanguageDropdown_bg=[0.1 (cur_item-1)/tot_items+0.1/tot_items 0.8 0.8/tot_items];
h.LanguageDropdown_bg=uibuttongroup(...
    'Parent',h.fig_option,...
    'BackgroundColor',get(h.fig_option,'Color'),...
    'BorderWidth',0,...
    'Units','normalized',...
    'Position',h.pos.LanguageDropdown_bg);
if h.isOctave,popup_popupmenu='popupmenu';else,popup_popupmenu='popup';end
h.LanguageDropdown=uicontrol('Style', popup_popupmenu,...
    'Parent',h.LanguageDropdown_bg,...
    'Children',[],...
    'String',get_dictionary,...
    'Units','normalized',...
    'Position',[0.05 0.05 0.9 0.4],...
    'Callback',@(hObject,eventdata)...
    ChangeLanguage(hObject,eventdata,guidata(hObject)));
h.LanguageDropdownDescription= uicontrol('Style','text',...
    'Parent',h.LanguageDropdown_bg,...
    'BackgroundColor',get(h.fig_option,'Color'),...
    'Units','normalized',...
    'Position',[0.05 0.55 0.9 0.4],...
    'HorizontalAlignment','left',...
    'String',dict.LanguageDropdownDescription);

cur_item=cur_item+1;
h.pos.StartupBehavior_bg=[0.1 (cur_item-1)/tot_items+0.1/tot_items 0.8 0.8/tot_items];
h.StartupBehavior_bg=uibuttongroup(...
    'Parent',h.fig_option,...
    'BackgroundColor',get(h.fig_option,'Color'),...
    'BorderWidth',0,...
    'Units','normalized',...
    'Position',h.pos.StartupBehavior_bg);
if h.isOctave,popup_popupmenu='popupmenu';else,popup_popupmenu='popup';end
h.StartupBehaviorDropdown=uicontrol('Style', popup_popupmenu,...
    'Parent',h.StartupBehavior_bg,...
    'Children',[],...
    'String',parse_StartupBehavior(dict),...
    'Units','normalized',...
    'Position',[0.05 0.05 0.9 0.4],...
    'Callback',@(hObject,eventdata)...
    parse_StartupBehavior(hObject,eventdata,guidata(hObject)));
h.StartupBehaviorDescription= uicontrol('Style','text',...
    'Parent',h.StartupBehavior_bg,...
    'BackgroundColor',get(h.fig_option,'Color'),...
    'Units','normalized',...
    'Position',[0.05 0.55 0.9 0.4],...
    'HorizontalAlignment','left',...
    'String',dict.StartupBehaviorDescription);

cur_item=cur_item+1;
h.pos.savecheckbox=[0.1 (cur_item-1)/tot_items+0.1/tot_items 0.8 0.8/tot_items];
h.savecheckbox = uicontrol(...
    'Parent',h.fig_option,...
    'BackgroundColor',get(h.fig_option,'Color'),...
    'Units','normalized',...
    'String',dict.savecheckbox,...
    'Position',h.pos.savecheckbox,...
    'Style','checkbox',...
    'Callback',@(hObject,eventdata)...
    CheckboxCallback(hObject,eventdata,guidata(hObject)));

set(h.savecheckbox,'Value',CheckboxState);
set(h.LanguageDropdown,'Value',...
    find(ismember(get(h.LanguageDropdown,'String'),h.language)));
parse_StartupBehavior(dict,h);%sets dropdown value
guidata(h.fig_option,h)
end

function ChangeLanguage(source,~,h)
try
    val = get(source,'Value');
    selected_lang = get(source,'String');
    selected_lang=selected_lang{val};
    
    %Make sure struct is up to date, especially since at the end of this
    %script it is used to update the guidata struct.
    h=guidata(h.fig);
    %Check if the selected language is new
    if strcmp(h.language,selected_lang)
        return
    end
    %New language selected. Reload dictionary and tell user to restart app.
    %This could be could be changed to reload every single string that is
    %loaded, but that is a lot of work in writing and in double-checking
    %that no field was missed. Just reloading the dict will affect every
    %new string, so all msgbox messages will already be changed.
    h.language=selected_lang;
    dict=get_dictionary(selected_lang);
    msgbox(dict.RestartApp);
    h.dict=dict;
    guidata(h.fig,h);
    save_settings(h.checkboxmat,get(h.savecheckbox,'Value'),h.LastLoaded,selected_lang)
catch ME
    namestack=dbstack;functionname=namestack(1).name;
    disp('Function stack:')
    disp({namestack(:).name})
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function CheckboxCallback(~,~,appdata)
%Save the checkbox state to  the .mat file and update the tooltipstring
%(the mouse-over text) accordingly.
try
    appdata=guidata(appdata.fig);
    CheckboxState=get(appdata.savecheckbox,'Value');
    LastLoaded=appdata.LastLoaded;
    if ~exist(LastLoaded,'file'),LastLoaded(1:end)='';end
    save_settings(appdata.checkboxmat,CheckboxState,LastLoaded,...
        appdata.language,appdata.StartupBehavior)
    if CheckboxState
        TooltipString=appdata.dict.TooltipString_checkbox_enabled;
    else
        TooltipString=appdata.dict.TooltipString_checkbox_disabled;
    end
    %Prevent an m-lint warning about unused variables
    [~]=deal(LastLoaded);
    set(appdata.savecheckbox,'TooltipString',TooltipString)
catch ME
    namestack=dbstack;functionname=namestack(1).name;
    disp('Function stack:')
    disp({namestack(:).name})
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function exiftool=download_exiftool
% Download the zip-file containing exiftool, unzip it, and rename it to the
% correct file name.
try
    h_waitbar=waitbar(0,'Exiftool: preparing download');
    %Get the folder containing this file.
    a=dbstack;[folderpath,~,~]=fileparts(which(a(1).file));
    folderpath=[folderpath filesep];
    exiftool=[folderpath 'exiftool.exe'];
    
    waitbar(1/3,h_waitbar,'Exiftool: downloading');
    %Download the zip file from The Wayback Machine
    URL=['http://web.archive.org/web/20170820125224if_/',...
        'https://www.sno.phy.queensu.ca/~phil/exiftool/exiftool-10.61.zip'];
    urlwrite(URL,[folderpath 'exiftool.zip']);
    
    waitbar(2/3,h_waitbar,'Exiftool: unzipping');
    %Unzip to the current folder.
    unzip('exiftool.zip',folderpath);
    movefile([folderpath 'exiftool(-k).exe'],exiftool)
    delete(h_waitbar);
catch ME
    namestack=dbstack;functionname=namestack(1).name;
    disp('Function stack:')
    disp({namestack(:).name})
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function get_update(~,~,h)
%Try downloading the current version to test if the URL still works the
%same way. If it still works, loop through URLs until one fails. The
%current version of PhotoAnnotation.m is renamed with the version in the
%file name.

h=guidata(h.fig);

%Set update button color to green.
set(h.check_updatebutton,'BackgroundColor',[0 1 0])
pause(0.001)%give time to update

version_names=get_version_names;
exiftool=h.exiftool;
index=length(version_names);
current_url=['http://www.mathworks.com/matlabcentral/mlc-downloads/'...
    'downloads/submissions/64294/versions/' num2str(index) '/previews/'...
    'PhotoAnnotation.m/index.html?access_key='];
current_path=[fileparts(exiftool) filesep 'PhotoAnnotation_vernum_'];
filename=[current_path num2str(index) '.m'];
%Test if this method of updating still works by downloading the current
%version of the program.
try
    if exist('websave','builtin')||exist('websave','file')
        outfilename=websave(filename,current_url,weboptions('Timeout',10));
    else
        %Octave and old Matlab releases.
        outfilename=urlwrite(current_url,filename);
    end
    a=dir(outfilename);
    if a.bytes<100
        error('throw error: empty file')
    end
catch
    %Either the download failed, or the file downloaded is empty.
    msgbox(h.dict.auto_update_failed);
    
    %Reset update button color before returning.
    set(h.check_updatebutton,'BackgroundColor',[0.94118 0.94118 0.94118])
    return
end

while a.bytes>100
    %Rinse and repeat until a download fails.
    index=index+1;
    current_url=['http://www.mathworks.com/matlabcentral/mlc-downloads/'...
        'downloads/submissions/64294/versions/' num2str(index)...
        '/previews/PhotoAnnotation.m/index.html?access_key='];
    filename=[current_path num2str(index) '.m'];
    try
        if exist('websave','builtin')||exist('websave','file')
            outfilename=websave(filename,current_url,...
                weboptions('Timeout',10));
        else
            outfilename=urlwrite(current_url,filename);
        end
        a=dir(outfilename);
    catch ME
        disp(ME.message)
        a.bytes=0;%force loop exit
    end
end
index=index-1;
if index==length(version_names)
    %Current version is newest version. (Errors are delt with earlier in
    %the update script)
    temp=h.dict.CurrentVersionIsNewest;
    temp{2}=sprintf(temp{2},version_names{end});
    msgbox(temp);
    
    %Reset update button color before returning.
    set(h.check_updatebutton,'BackgroundColor',[0.94118 0.94118 0.94118])
    return
end

%New version detected: process the downloaded file to a normal m-file.
try
    filename1=[current_path num2str(index) '.m'];
    filename2=[fileparts(exiftool) filesep 'PhotoAnnotation_v' ...
        version_names{end} '_backup.m'];
    filename3=[fileparts(exiftool) filesep 'PhotoAnnotation.m'];
    fid=fopen(filename1,'rt','n');
    data=char(fread(fid)');
    fclose(fid);
    
    %Remove tags from first and last line.
    idx1=strfind(data,'>');
    idx2=strfind(data,'<');
    idx3=strfind(data,char(5+5));
    idx3=idx3([1 end]);
    idx1=idx1(idx1<idx3(1));idx1=idx1(end)+1;
    idx2=idx2(idx2>idx3(end));idx2=idx2(1)-1;
    data=data(idx1:idx2);
    
    data=strrep(data,'&quot;','"');
    data=strrep(data,'&#39;','''');
    
    copyfile(filename3,filename2);
    fid=fopen(filename3,'wb');
    fwrite(fid,unicode2nativeUTF8(data), 'uint8');
    fclose(fid);
    msgbox(h.dict.SuccessfulUpdate);
catch
    msgbox(h.dict.ErrorDuringUpdate);
end
%Reset update button color before returning.
set(h.check_updatebutton,'BackgroundColor',[0.94118 0.94118 0.94118])
end

function GUI_update(~,~,h)
%Because of the way this function is called, it needs to have three inputs.
%This function is needed, because sometimes when resizing the window
%(especially when maximizing), objects will move around unpredictably. This
%function resets their positions and also updates the figure title so it
%contains the file name and containing folder.
try
    %Set the figure title field
    [a,b,c]=fileparts(h.filename);
    NameField=['"' b c '"' h.dict.figure_title_field '"' a '"'];
    set(h.fig,'Name',NameField)
    
    %NB: 'Position' is a vector denoting [left bottom width height]
    figpos=get(h.fig,'Position');
    %savebutton:
    relpos=h.pos.savebutton;
    newpos=relpos.*[figpos(3:4) figpos(3:4)];
    set(h.savebutton,'Units','pixels')
    set(h.savebutton,'Position',newpos)
    set(h.savebutton,'Units','normalized')
    %loadbutton:
    relpos=h.pos.loadbutton;
    newpos=relpos.*[figpos(3:4) figpos(3:4)];
    set(h.loadbutton,'Units','pixels')
    set(h.loadbutton,'Position',newpos)
    set(h.loadbutton,'Units','normalized')
    %optionbutton:
    relpos=h.pos.optionbutton;
    newpos=relpos.*[figpos(3:4) figpos(3:4)];
    set(h.optionbutton,'Units','pixels')
    set(h.optionbutton,'Position',newpos)
    set(h.optionbutton,'Units','normalized')
    %textfield:
    relpos=h.pos.textfield;
    newpos=relpos.*[figpos(3:4) figpos(3:4)];
    set(h.textfield,'Units','pixels')
    set(h.textfield,'Position',newpos)
    set(h.textfield,'Units','normalized')
    %axis:
    relpos=h.pos.axis;
    newpos=relpos.*[figpos(3:4) figpos(3:4)];
    set(h.axis,'Units','pixels')
    set(h.axis,'Position',newpos)
    set(h.axis,'Units','normalized')
    %prevbutton:
    relpos=h.pos.prevbutton;
    newpos=relpos.*[figpos(3:4) figpos(3:4)];
    set(h.prevbutton,'Units','pixels')
    set(h.prevbutton,'Position',newpos)
    set(h.prevbutton,'Units','normalized')
    %nextbutton:
    relpos=h.pos.nextbutton;
    newpos=relpos.*[figpos(3:4) figpos(3:4)];
    set(h.nextbutton,'Units','pixels')
    set(h.nextbutton,'Position',newpos)
    set(h.nextbutton,'Units','normalized')
catch ME
    namestack=dbstack;functionname=namestack(1).name;
    disp('Function stack:')
    disp({namestack(:).name})
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function KeyPress(~,key,appdata)
%Find out if a key press is left/right/pageup/pagedown if so, switch image.
%This function needs to be as fast as possible in order react fast on a key
%press and be ready for the next key event.
try
    key=key.Key;
    direction=0;
    ButtonCallbackBuzy=appdata.ButtonCallbackBuzy;
    if ButtonCallbackBuzy
        return%ignore key presses if a callback is already in progress
    else
        appdata.ButtonCallbackBuzy=true;
        guidata(appdata.fig,appdata);
    end
    %For some reason Octave and Matlab disagree on whether it should be
    %'right' or 'rightarrow', so both are included.
    if strcmp(key,'right') || ...
            strcmp(key,'pagedown') || ...
            strcmp(key,'rightarrow')
        direction=+1;
    end
    if strcmp(key,'left') || ...
            strcmp(key,'pageup') || ...
            strcmp(key,'leftarrow')
        direction=-1;
    end
    if strcmp(key,'return')
        GUI_update([],[],appdata);
    end
    if direction~=0
        %Load next or previous image file
        MoveImage([],[],appdata,direction)
    end
catch ME
    namestack=dbstack;functionname=namestack(1).name;
    disp('Function stack:')
    disp({namestack(:).name})
    msgbox({['error in ' functionname ':'],ME.message});
end
appdata=guidata(appdata.fig);
appdata.ButtonCallbackBuzy=false;
guidata(appdata.fig,appdata);
end

function language=LoadDefaultLanguage(current_path)
%Try to find the default file created by the setup. If none or multiple
%files are present, default to English.
language_default='en_english';
filelist=dir([current_path 'default_lang_at_setup=*.txt']);
if numel(filelist)~=1%multiple or no files
    language=language_default;
    return
end
[~,filename,~]=fileparts(filelist.name);
lang=textscan(filename,'default_lang_at_setup=%s');
lang=lang{1}{1};
if any(ismember({'en_english','nl_dutch'},lang))
    language=lang;
else
    %Invalid language ID, so use the default
    language=language_default;
end
end

function description=LoadDescription(~,~,appdata)
%Load the description into a format that can be put in the text field.
try
    isOctave=appdata.isOctave;
    %Set the background to black (reset to white after loading text).
    set(appdata.textfield,'BackgroundColor',[0 0 0])
    
    %Get file locations.
    exiftool=appdata.exiftool;
    filename=appdata.filename;
    
    command=['"' exiftool '" -Description "' filename '"'];
    [~, description] = system(command);
    
    %The command line response might contain a warning instead of the
    %description itself.
    if ~isempty(description)
        %Extract the first line.
        first_part=description(1:find(double(description)==10,1));
        if strcmp(first_part(1:7),'Warning')
            %Remove the warning, so the description can be re-tested if it
            %is empty.
            description(1:find(double(description)==10,1))=[];
        end
    end
    if ~isempty(description)
        description=strsplit(description,' : ');
        description=description{2};%get the description field content
        if strcmp(description(end),char(5+5))
            description(end)=[];%remove line end
        end
        if strcmp(description(end),char(13))
            description(end)=[];%remove line end
        end
        
        idx=strfind(description,'~');
        if ~isempty(idx)%undo escaping
            %Find single tildes and double tildes. Replace singles with
            %char(0) and replace doubles with the correct unicode char.
            %(e.g. replace '~~20AC' with € and '~~00E9' with 'é')
            idx__=find([diff(idx) inf]==1);
            if isempty(idx__)
                description(idx)=char(0);
            else
                idx_=idx;
                idx_([idx__ idx__+1])=[];%~
                idx__=idx(idx__);        %~~
                
                description(idx_)=char(0);
                
                idx__=repmat(idx__',1,6)+meshgrid(0:5,1:length(idx__));
                codepoints=description(idx__);
                codepoints=unique(codepoints,'rows');
                if isOctave
                    %Octave can't display them (yet), so leave them
                    %escaped. They can only be saved with Matlab, only
                    %leave them in as a matter of compatibility.
                    codepoints(hex2dec(codepoints(:,3:6))>256,:)=[];
                    codepoints(codepoints>126 & codepoints<160)=[];
                end
                for n=1:size(codepoints,1)
                    description=strrep(description,codepoints(n,:),...
                        char(hex2dec(codepoints(n,3:end))));
                end
            end
            %Reshape description into the text block.
            idx=strfind(description,char(0));
            %If the description is too long, the end might be cropped. This
            %will result in idx being empty, which would result in an
            %error.
            if isempty(idx)
                description(end+1)=char(0);
                idx=strfind(description,char(0));
            end
            description=reshape(description,...
                idx(1),length(description)/idx(1));
            description(end,:)=[];
            description=description';
        end
    end
    set(appdata.textfield,'String',description)
    
    %If loading actions are successful, mark the current file as LastLoaded
    %and update the data structure.
    CheckboxState=get(appdata.savecheckbox,'Value');
    LastLoaded=appdata.filename;appdata.filename=LastLoaded;
    language=appdata.language;appdata.language=language;
    
    save_settings(appdata.checkboxmat,CheckboxState,LastLoaded,language,...
        appdata.StartupBehavior)
    guidata(appdata.fig,appdata)
    
    set(appdata.textfield,'BackgroundColor',[1 1 1])
    %Give the GUI time to update.
    pause(0.001)
catch ME
    functionname=dbstack;functionname=functionname(1).name;
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function LoadImage(~,~,appdata,CommandlineInput)
%Open a file picker to load an image and its description. The starting
%folder is the folder containing the currently loaded image, or (if no
%image is loaded yet) it is the root folder of this script.

try
    %Save the current description if the checkbox is ticked.
    SaveIfCheckboxChecked([],[],appdata)
    
    StartingUp=true;
    if ~exist('CommandlineInput','var')
        CommandlineInput=false;
        StartingUp=false;
    end
    
    dict=appdata.dict;
    %Let the user select an image
    if appdata.isOctave
        filetypes={'*.jpeg;*.jpg;*.png;*.tif;*.tiff',...
            dict.all_image_types};
    else
        filetypes={'*.jpeg;*.jpg;*.png;*.tif;*.tiff',...
            dict.all_image_types;...
            '*.*',dict.all_file_types};
    end
    %If no image has been loaded yet, start in the current folder (which is
    %the root folder of the program). If the file that was last loaded
    %successfully still exists, load it. If not, use its containing folder
    %as the start folder. If that folder doesn't exist, it will solve that
    %problem on its own.
    if CommandlineInput
        %Ignore all settings, just load the file (includes 'open with').
        filename=appdata.LastLoaded;
    else
        %Convert options to numeric values.
        score=3*strcmp(appdata.StartupBehavior,'LastLoaded')+...
            2*strcmp(appdata.StartupBehavior,'picker_LastLoaded')+...
            1*strcmp(appdata.StartupBehavior,'picker_pwd');
        if ~StartingUp && score==3
            %This is the button callback situation, so don't load the
            %LastLoaded image, as that should be the current image.
            score=2;
        end
        if score==3%Try loading the LastLoaded file
            if exist(appdata.LastLoaded,'file')
                filename=appdata.LastLoaded;
            else
                %Failed, so try the next option
                score=2;
            end
        end
        if score==2%Try opening the file picker in the LastLoaded folder
            pathname=fileparts(appdata.LastLoaded);
            if exist(pathname,'dir')
                [filename,pathname]=uigetfile(filetypes,...
                    dict.selectfile_menutext,pathname);
                filename=[pathname,filename];
            else
                %Failed, so try the next option
                score=1;
            end
        end
        if score==1%Open file picker in the program root
            pathname=pwd;
            [filename,pathname]=uigetfile(filetypes,...
                dict.selectfile_menutext,pathname);
            filename=[pathname,filename];
        end
    end
    
    if sum(double(filename))==0
        return%file picker operation was canceled, so abort loading
    end
    
    appdata.filename=filename;
    guidata(appdata.fig, appdata);
    
    %Open the file, which will load the description.
    openfile([],[],appdata)
catch ME
    namestack=dbstack;functionname=namestack(1).name;
    disp('Function stack:')
    disp({namestack(:).name})
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function MoveImage(~,~,appdata,direction)
%Get a sorted list of all images in the folder containing the current image
%and get the next/previous file.
try
    %Set the relevant button background to green as an indication of the
    %program processing the request.
    if direction==-1
        temp_handle=appdata.prevbutton;
    else
        temp_handle=appdata.nextbutton;
    end
    set(temp_handle,'BackgroundColor',[0 1 0])
    pause(0.001)%give time to update
    
    %Save the current description if the checkbox is ticked and the file
    %still exists.
    CheckboxState=get(appdata.savecheckbox,'Value');
    if CheckboxState && exist(appdata.LastLoaded,'file')
        SaveDescription([],[],appdata)
    end
    
    %The dir in Octave is case-sensitive.
    [currentfolder,fname,ext]=fileparts(appdata.filename);
    if appdata.isOctave
        f = [dir(fullfile(currentfolder,'*.jpg'));...
            dir(fullfile(currentfolder,'*.jpeg'));...
            dir(fullfile(currentfolder,'*.png'));...
            dir(fullfile(currentfolder,'*.tif'));...
            dir(fullfile(currentfolder,'*.tiff'));...
            dir(fullfile(currentfolder,'*.JPG'));...
            dir(fullfile(currentfolder,'*.JPEG'));...
            dir(fullfile(currentfolder,'*.PNG'));...
            dir(fullfile(currentfolder,'*.TIF'));...
            dir(fullfile(currentfolder,'*.TIFF'))];
    else
        f = [dir(fullfile(currentfolder,'*.jpg'));...
            dir(fullfile(currentfolder,'*.jpeg'));...
            dir(fullfile(currentfolder,'*.png'));...
            dir(fullfile(currentfolder,'*.tif'));...
            dir(fullfile(currentfolder,'*.tiff'))];
    end
    [~,order]=sort(cellfun(@lower,{f(:).name},'UniformOutput',0));
    if isempty(order)
        %The folder apparently doesn't exist (anymore).
        LoadImage([],[],appdata);
    else
        %The output from dir is not sorted in a conventional way, and
        %besides that, the list is build out of several parts. Therefore
        %the file list is sorted here to a normal order.
        f=f(order);
        %Find the current file on the list.
        pos=find(ismember({f(:).name},[fname,ext]));
        if isempty(pos)
            %If the file is deleted, select the first file.
            pos=1-direction;
        end
        if pos+direction>length(f)
            pos=1-direction;%wrap back to first image
        end
        if pos+direction==0
            pos=length(f)-direction;%wrap back to last image
        end
        newfile=f(pos+direction).name;
    end
    appdata.filename=[currentfolder,filesep,newfile];
    guidata(appdata.fig,appdata);
    
    %Open the selected file (this will also load the description).
    openfile([],[],appdata)
    %Set the button color back to normal.
    set(temp_handle,'BackgroundColor',[0.94118 0.94118 0.94118])
catch ME
    namestack=dbstack;functionname=namestack(1).name;
    disp('Function stack:')
    disp({namestack(:).name})
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function openfile(~,~,appdata)
%Open a file and rotate if needed.
rot90CW=@(IM) permute(IM(end:-1:1,:,:),[2 1 3]);
rot270CW=@(IM) permute(IM(:,end:-1:1,:),[2 1 3]);
%Get file locations.
exiftool=appdata.exiftool;
filename=appdata.filename;

command=['"' exiftool '" -Orientation -n "' filename '"'];
[~, orientation] = system(command);
%The command line response might contain a warning instead of the
%orientation itself.
if ~isempty(orientation)
    %Extract the first line.
    first_part=orientation(1:find(double(orientation)==10,1));
    if strcmp(first_part(1:7),'Warning')
        %Remove the warning, so the description can be re-tested if it
        %is empty.
        orientation(1:find(double(orientation)==10,1))=[];
    end
end
if ~isempty(orientation)
    orientation=strsplit(orientation,' : ');
    orientation=orientation{2};%get the orientation field content
    if strcmp(orientation(end),char(5+5))
        orientation(end)=[];%remove line end
    end
    if strcmp(orientation(end),char(13))
        orientation(end)=[];%remove line end
    end
else
    orientation='1';%assume normal orientation if field is missing
end

IM=imread(appdata.filename);

switch orientation
    case '6'
        IM=rot90CW(IM);
    case '8'
        IM=rot270CW(IM);
    case '3'%upside down
        IM=rot90CW(rot90CW(IM));
end

%Ensure the focus is on the main window.
figure(appdata.fig)
imshow(IM)
%Load current description and save it in the struct as well.
%This saving can then later be used to skip unnecessary write-outs.
appdata.OriginalDescription=LoadDescription([],[],appdata);
%Save LastLoaded to enable reloading at application restart.
appdata.LastLoaded=filename;
guidata(appdata.fig,appdata);
GUI_update([],[],appdata)
end

function OptionCallback(~,~,appdata)
%Ostensibly open the option figure window, but actually just change the
%position and make the figure visible.
%The option window will be above and in the middle of the main window.
try
    if strcmp(get(appdata.fig_option,'Visible'),'on')
        figure(appdata.fig_option);
        return
    end
    %Get the current position of the main window
    main_pos=get(appdata.fig,'Position');
    main_units=get(appdata.fig,'Units');
    
    %(pos=[left bottom width height])
    f=1/3;
    pos=[main_pos(1:2)+(0.5*main_pos(3:4))*(1-f) main_pos(3:4)*f];
    
    set(appdata.fig_option,'Units',main_units)
    set(appdata.fig_option,'Position',pos)
    set(appdata.fig_option,'Visible','on')
    figure(appdata.fig_option);
catch ME
    namestack=dbstack;functionname=namestack(1).name;
    disp('Function stack:')
    disp({namestack(:).name})
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function OptionCloseReqFun(~,~,appdata)
set(appdata.fig_option,'Visible','off')
end

function output=parse_StartupBehavior(dict,h,appdata)
%1 input:  output the list in cellstr.
%2 inputs: set the dropdown to the current setting.
%Callback: set the StartupBehavior field in appdata to the correct string.

narginchk(1,3);%should never occur, unless the code has a bug
try
    % 1: file picker in pwd
    % 2: file picker in LastLoaded
    % 3: LastLoaded
    options={'picker_pwd','picker_LastLoaded','LastLoaded'};
    
    if nargin==1
        output={['1: ' dict.StartupBehavior{1}],...
            ['2: ' dict.StartupBehavior{2}],...
            ['3: ' dict.StartupBehavior{3}]};
        return
    end
    
    if nargin==2
        set(h.StartupBehaviorDropdown,'Value',...
            find(ismember(options,h.StartupBehavior)));
        return
    end
    
    %Callback
    appdata.StartupBehavior=...
        options{get(appdata.StartupBehaviorDropdown,'Value')};
    guidata(appdata.fig,appdata)
    %Alert user that if missing, the program will revert to one level up.
    if get(appdata.StartupBehaviorDropdown,'Value')~=1
        msgbox(appdata.dict.StartupBehaviorCascade);
    end
catch ME
    namestack=dbstack;functionname=namestack(1).name;
    disp('Function stack:')
    disp({namestack(:).name})
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function SaveDescription(~,~,appdata)
%Save the description to the currently opened file.
if ~isfield(appdata,'filename') || ~exist(appdata.filename,'file')
    %File deleted/missing or startup is in progress.
    return
end
isOctave=appdata.isOctave;
try
    %Set the button color to green
    set(appdata.savebutton,'BackgroundColor',[0 1 0]);
    pause(0.001)%give time to update
    
    %Get the description from the text field. The conversion from cell
    %exists only for compatibility (different releases of Matlab and Octave
    %handle the text field differently).
    description=get(appdata.textfield,'String');
    if isa(description,'cell')
        maxlength=0;%for padding with spaces
        for k=1:length(description)
            maxlength=max([maxlength length(description{k})]);
        end
        for k=1:length(description)
            t=description{k};
            if length(t)==maxlength,continue,end
            t(maxlength)=0;t(t==0)=32;
            description{k}=t;
        end
        description=cell2mat(description);
    end
    %Skip processing and write-out if description is unchanged.
    if isequal(appdata.OriginalDescription,description) || ...
            numel(description)==0 && numel(appdata.OriginalDescription)==0
        %Description is equal to the original, so skip write-out.
        %The extra check is needed, because strcmp says [0x1] is not equal
        %to [0x0], at least in Octave.
        
        %Reset the button color back to normal.
        set(appdata.savebutton,'BackgroundColor',[0.94118 0.94118 0.94118])
        return
    end
    
    %Get file locations and generate a filename for a temporary file. The
    %current file will be copied to this location, which will then be
    %updated and moved back to the original location. This catches any file
    %access issues.
    exiftool=appdata.exiftool;
    filename=appdata.filename;[~,~,ext]=fileparts(filename);
    tempfile=[pwd filesep 'temp' ext];clear ext
    
    while size(description,2)>0 && ~any(double(description(:,end))~=32)
        %The entire last column is made up of padding spaces, so they can
        %all be removed.
        description(:,end)=[];
    end
    description(:,end+1)=char(0);%encode a line end, will be replaced by ~
    
    %Reshape to a vector so the description can be written via the command
    %line utility.
    description=reshape(description',1,numel(description));
    
    %Apply escaping of non-ASCII (char>128), single tildes and double
    %quotes. Double tildes should not be escaped, as they may be from a
    %Matlab-compatible character that is not compatible with Octave and is
    %therefore not escaped.
    codepoints=unique(double(description));
    codepoint=double('~');
    temp=find(codepoints==codepoint, 1);
    if ~isempty(temp)
        if ~isOctave
            description=strrep(description,...
                char(codepoint),['~~' dec2hex(codepoint,4)]);
        else
            %Ignore double tildes and escape single ones.
            escape_positions=strfind(description,'~');
            double_tilde=diff(escape_positions);
            double_tilde=sort([find(double_tilde==1) find(double_tilde==1)+1]);
            escape_positions(double_tilde)=[];
            if escape_positions(end)==length(description)
                description=[description(1:(end-1)) '~~007E'];
                escape_positions(end)=[];
            end
            if escape_positions(1)==1
                description=['~~007E' description(2:end)];
                escape_positions(1)=[];
                escape_positions=escape_positions+5;%keep empty array empty
            end
            for n=length(escape_positions):-1:1
                description=[description(1:(escape_positions(n)-1)) ...
                    '~~007E' ...
                    description((escape_positions(n)+1):end)];
            end
        end
    end
    codepoint=double('"');
    temp=find(codepoints==codepoint, 1);
    if ~isempty(temp)
        description=strrep(description,...
            char(codepoint),['~~' dec2hex(codepoint,4)]);
    end
    codepoints(codepoints<=128)=[];%don't escape ASCII
    if ~isempty(codepoints)
        if any(codepoints>65535)%hex2dec('FFFF')
            msgbox(appdata.dict.non_supported_input);
            codepoints(codepoints>65535)=[];%ignore non-supported chars
        end
        for codepoint=codepoints%loop through all non-ASCII characters
            if ~isOctave || codepoint<=256
                description=strrep(description,...
                    char(codepoint),['~~' dec2hex(codepoint,4)]);
            else
                %There will be a range error character conversion if
                %char(codepoint) is attempted for >256.
                esc_str=['~~' dec2hex(codepoint,4)];
                escape_positions=find(codepoint==description);
                if escape_positions(end)==length(description)
                    description=[description(1:(end-1)) esc_str];
                    escape_positions(end)=[];
                end
                if escape_positions(1)==1
                    description=[esc_str description(2:end)];
                    escape_positions(1)=[];
                    escape_positions=escape_positions+5;%keep empty array empty
                end
                for n=length(escape_positions):-1:1
                    description=[description(1:(escape_positions(n)-1)) ...
                        esc_str ...
                        description((escape_positions(n)+1):end)];
                end
            end
        end
    end
    %Replace the line end encoding with a tilde.
    description=strrep(description,char(0),'~');
    
    if strcmp(description,'~')
        %Empty description
        description='';
    end
    
    
    %Put a placeholder image in the working folder.
    copyfile(filename,tempfile);
    
    %Add the description from the textbox to the temporary file. All file
    %locations should be enclosed with double quotes to prevent spaces
    %causing problems.
    command=['"' exiftool '" -m -Description="' description '" "' tempfile '"'];
    [status,msg] = system(command);
    
    if status
        msgbox({['error in cmd (status=' num2str(status) '):'],msg});
    end
    
    %Delete the extra file exiftool created.
    if exist([tempfile,'_original"'],'file')
        %It should exist, but if it is missing, this check prevents an
        %error to the user.
        command = ['del "',tempfile,'_original"'];
        [status,msg] = system(command);
        if status
            msgbox({['error in cmd (status=' num2str(status) '):'],msg});
        end
    end
    
    %Overwrite the original file (containing the old description) with the
    %temporary file (which contains the new description).
    movefile(tempfile,filename,'f');
    
    %Re-load the description and display it, but not if the calling
    %function will change the image or close the program.
    function_calls=dbstack;
    if ~any(ismember({function_calls(:).name},...
            {'MoveImage','SaveIfCheckboxChecked_close'}))
        LoadDescription([],[],appdata);
    end
    %Reset the button color back to normal.
    set(appdata.savebutton,'BackgroundColor',[0.94118 0.94118 0.94118])
catch ME
    functionname=dbstack;functionname=functionname(1).name;
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function SaveIfCheckboxChecked(~,~,appdata)
%Save the current description if the checkbox is ticked.
try
    CheckboxState=get(appdata.savecheckbox,'Value');
    NoImageLoadedYet=false;
    if ~exist(appdata.LastLoaded,'file'),NoImageLoadedYet=true;end
    if CheckboxState && ~NoImageLoadedYet
        SaveDescription([],[],appdata)
    end
catch ME
    namestack=dbstack;functionname=namestack(1).name;
    disp('Function stack:')
    disp({namestack(:).name})
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function SaveIfCheckboxChecked_close(~,~,appdata)
%This is the CloseReq function. It will try to save the description if the
%checkbox is set to do so, after which it will close the figure. Should an
%error occur, the figure will still be closed.
try
    SaveIfCheckboxChecked([],[],appdata)
    delete(appdata.fig);
    delete(appdata.fig_option);
catch ME
    loop_var=20;
    while loop_var
        try
            %Close all the figures (msgbox also counts as a figure for gcf)
            delete(gcf)
            loop_var=loop_var-1;
        catch
            loop_var=false;
        end
    end
    namestack=dbstack;functionname=namestack(1).name;
    disp('Function stack:')
    disp({namestack(:).name})
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function save_settings(checkboxmat,CheckboxState,LastLoaded,language,...
    StartupBehavior)
try
    isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
    if isOctave
        save('-mat',checkboxmat,...
            'CheckboxState','LastLoaded','language','StartupBehavior');
    else
        save(checkboxmat,...
            'CheckboxState','LastLoaded','language','StartupBehavior');
    end
    %supress m-lint warning
    [~,~,~,~]=deal(CheckboxState,LastLoaded,language,StartupBehavior);
catch ME
    namestack=dbstack;functionname=namestack(1).name;
    disp('Function stack:')
    disp({namestack(:).name})
    msgbox({['error in ' functionname ':'],ME.message});
end
end

function output=unicode2nativeUTF8(input_char)
%Convert a string to UTF8, if possible with the built in function. This
%function is expected to be part of Octave 4.3, but as it is missing in
%Octave 4.2.1, it is implemented here.

if exist('unicode2native','builtin')
    output=unicode2native(input_char,'UTF-8');
    return
end
%No builtin function, so build a list of all non-ASCII items.

char_list=unique(input_char);

output=uint32(zeros(7,length(char_list)));
for n=length(char_list):-1:1
    if char_list(n)<2^8
        %This char is equal between ASCII and UTF8. Remove from the list
        %that is going to strrep.
        output(:,n)=[];
    else
        output(1,n)=char_list(n);
        encoded=unicode2nativeUTF8_internal(char_list(n));
        %This is a speed-memory trade off: this method will assume an
        %encoding length of 6 bytes, which removes the need for
        %computationally heavy checks and extensions, but it dramatically
        %increase the memory use, usually by about a factor 3.
        encoded=uint32(encoded);
        %Over-extend to 7 bytes and then remove the 7th byte, meaning the
        %length is guaranteed to be 6.
        encoded(7)=0;encoded(7)=[];
        output(2:7,n)=encoded;
    end
end

if ~isempty(output)
    %No need to waste memory with a double array, especially we plan to
    %extend it to multiple mostly empty columns.
    convertedlist=uint32(input_char');
    %There may be a null char in the list, so if we remove all zeros later
    %on, we'd remove that. Replace with inf and restore to null later.
    %Note: this get really close to the precision: uint32(inf)-2^32 should
    %equal 0, but sometimes will return -1, so stick to int data types.
    convertedlist(convertedlist==0)=uint32(inf);
    convertedlist(1,6)=0;%extend to fit all byte lengths
    for n=1:size(output,2)
        %Create a logical index array
        pos= input_char==output(1,n) ;
        %Replace the original codepoint with the encoded bytes.
        convertedlist(pos,:)=repmat(output(2:7,n)',sum(pos),1);
    end
    %Reshape the array into a vector again.
    convertedlist=reshape(convertedlist',1,numel(convertedlist));
    %Remove padding zeros.
    convertedlist(convertedlist==0)=[];
    %Restore the null chars.
    convertedlist(convertedlist==uint32(inf))=0;
    %Convert to uint8 to comply with the real encoding.
    output=uint8(convertedlist);
else
    output=uint8(input_char);
end
end

function bytes=unicode2nativeUTF8_internal(input_char)
%Convert the single character to UTF8 bytes.
%
%See https://en.wikipedia.org/wiki/UTF-8#Description
%
%The value of the input is converted to binary and padded with 0 bits at
%the front of the string to fill all 'x' positions in the scheme.
%
%scheme for  1- 7 bit chars (1 byte):
% 0xxxxxxx
%scheme for  8-11 bit chars (2 bytes):
% 110xxxxx 10xxxxxx
%scheme for 12-16 bit chars (3 bytes):
% 1110xxxx 10xxxxxx 10xxxxxx
%scheme for 17-21 bit chars (4 bytes):
% 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
%scheme for 22-26 bit chars (5 bytes):
% 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
%scheme for 27-31 bit chars (6 bytes):
% 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx

bytes=cell(1,2);
binarized=dec2bin(double(input_char));
if length(binarized)<8
    bytes={binarized};
elseif length(binarized)<12
    pading=repmat('0',1,(5+6)-length(binarized));
    binarized=[pading binarized];
    bytes{1}=['110' pading binarized(1:5)];
    bytes{2}=['10' binarized(6:11)];
elseif length(binarized)<17
    pading=repmat('0',1,(4+6+6)-length(binarized));
    binarized=[pading binarized];
    bytes{1}=['1110' binarized(1:4)];
    bytes{2}=['10' binarized(5:10)];
    bytes{3}=['10' binarized(11:16)];
elseif length(binarized)<21
    pading=repmat('0',1,(3+6+6+6)-length(binarized));
    binarized=[pading binarized];
    bytes{1}=['11110' binarized(1:3)];
    bytes{2}=['10' binarized(4:9)];
    bytes{3}=['10' binarized(10:15)];
    bytes{4}=['10' binarized(16:21)];
elseif length(binarized)<26
    pading=repmat('0',1,(2+6+6+6+6)-length(binarized));
    binarized=[pading binarized];
    bytes{1}=['111110' binarized(1:2)];
    bytes{2}=['10' binarized(3:8)];
    bytes{3}=['10' binarized(9:14)];
    bytes{4}=['10' binarized(15:20)];
    bytes{5}=['10' binarized(21:26)];
elseif length(binarized)<31
    pading=repmat('0',1,(2+6+6+6+6+6)-length(binarized));
    binarized=[pading binarized];
    bytes{1}=['111110' binarized(1)];
    bytes{2}=['10' binarized(2:7)];
    bytes{3}=['10' binarized(8:13)];
    bytes{4}=['10' binarized(14:19)];
    bytes{5}=['10' binarized(20:25)];
    bytes{6}=['10' binarized(26:31)];
end

for n=1:length(bytes)
    bytes{n}=bin2dec(bytes{n});
end
bytes=cell2mat(bytes);
end

function dict=get_dictionary(language)
% Return the dictionary for a language, or return the list of languages.
%
% Currently supported languages:
% - English (en_english)
% - Dutch (nl_dutch)
%
% You can e-mail me translations if you would like me to add them.

if ~exist('language','var')
    %If no input is given, return a list of valid language codes.
    dict={'en_english','nl_dutch'};
    return
end

switch language
    case 'en_english'
        language=1;
    case 'nl_dutch'
        language=2;
    otherwise
        language=1;
end
%Force direction (for easy viewing during debugging)
temp=cell(length(get_dictionary),1);

temp{1}='all file types (may not work)';
temp{2}='alle bestandstypen (werkt mogelijk niet)';
dict.all_file_types=temp{language};
temp{1}='all image file types';
temp{2}='alle afbeeldingstypen';
dict.all_image_types=temp{language};
temp{1}={'Automatic update failed.',...
    'This may be due to a (temporarily) failed internet connected,',...
    'or it is due to a structural change to the Mathworks website.',...
    'The later would mean only a manual update is possible.'};
temp{2}={'Automatische update is mislukt.',...
    'Dit kan komen doordat de internetverbinding (tijdelijk) mislukte,',...
    'of doordat Mathworks de structuur van hun website heeft aangepast.',...
    'Als het tweede het geval is, is een update alleen handmatig mogelijk.'};
dict.auto_update_failed=temp{language};
temp{1}='Check for update';
temp{2}='Controleer op update';
dict.check_updatebutton=temp{language};
temp{1}={'The program is up to date:',...
    'the current version (%s) is the newest version.'};
temp{2}={'Het programma is up to date:',...
    'de huidige versie (%s) is de nieuwste versie.'};
dict.CurrentVersionIsNewest=temp{language};
temp{1}='There is a new version, but there was an error during the update.';
temp{2}='Er is een nieuwere versie, maar het laden ervan is mislukt.';
dict.ErrorDuringUpdate=temp{language};
temp{1}=' in ';
temp{2}=' in ';
dict.figure_title_field=temp{language};
temp{1}='Select a language:';
temp{2}='Selecteer een taal:';
dict.LanguageDropdownDescription=temp{language};
temp{1}='Open file';
temp{2}='Open bestand';
dict.loadbutton=temp{language};
temp{1}='next photo ==>';
temp{2}='volgende foto ==>';
dict.nextbutton=temp{language};
temp{1}={...
    'You entered a character with a codepoint with more than 8 bits.',...
    'Non-supported characters are ignored on writing.',...
    'The saved text is reloaded to the text field.'};
temp{2}={...
    'Er is een teken ingevoerd met een unicode groter dan 8 bits.',...
    'Niet ondersteunde characters worden genegeerd bij het wegschrijven.',...
    'De opgeslagen tekst is geladen in het tekstveld.'};
dict.non_supported_input=temp{language};
temp{1}='Options';
temp{2}='Opties';
dict.optionbutton=temp{language};
temp{1}='<== previous photo';
temp{2}='<== vorige foto';
dict.prevbutton=temp{language};
temp{1}={'The English translation is loaded.',...
    'To change all texts, you need to restart the application.'};
temp{2}={'De Nederlandse vertaling is geladen.',...
    'Om alle teksten te veranderen moet de applicatie opnieuw gestart worden.'};
dict.RestartApp=temp{language};
temp{1}='Save text';
temp{2}='Tekst opslaan';
dict.savebutton=temp{language};
temp{1}='Auto-save text';
temp{2}='Automatisch opslaan';
dict.savecheckbox=temp{language};
temp{1}='Select image';
temp{2}='Selecteer afbeelding';
dict.selectfile_menutext=temp{language};
temp{1}={'The program was updated successfully.',...
    'The prior version is backed up in the setup folder.',...
    'Restart the application to load the updated version.'};
temp{2}={'De nieuwste versie is succesvol gedownload.',...
    'Een backup van de vorige versie is te vinden in de setup map.',...
    'Herstart de applicatie om de nieuwe versie te laden.'};
dict.SuccessfulUpdate=temp{language};
%options={'picker_pwd','picker_LastLoaded','LastLoaded'};
temp{1}={'File picker, starts in program root',...
    'File picker, starts in folder of last loaded image',...
    'Open last loaded image'};
temp{2}={'Bestand selecteren (start in installatiemap)',...
    'Bestand selecteren (start in map van laatste bestand)',...
    'Open laatste bestand'};
dict.StartupBehavior=temp{language};
temp{1}={'If the selected level fails, the program will automatically',...
    'revert to the level above.'};
temp{2}={'Als het geselecteerde niveau mislukt,',...
    'zal het niveau erboven geprobeerd worden.'};
dict.StartupBehaviorCascade=temp{language};
temp{1}='Select default behavior at startup:';
temp{2}='Selecteer de standaard bij het opstarten:';
dict.StartupBehaviorDescription=temp{language};
temp{1}='Placeholder text, enter description here.';
temp{2}='Begintekst, typ de omschrijving hier.';
dict.textfield=temp{language};
temp{1}='Check this box to automatically saving the text.';
temp{2}='Selecteer om de beschrijving automatisch op te slaan.';
dict.TooltipString_checkbox_disabled=temp{language};
temp{1}='Un-check this box to disable automatically saving the text.';
temp{2}='Deselecteer om de beschrijving niet automatisch op te slaan.';
dict.TooltipString_checkbox_enabled=temp{language};
temp{1}='version';
temp{2}='versie';
dict.Version=temp{language};
end
