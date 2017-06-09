
#If __TARGET__="windows"

#Import "bin/wget.exe"

'to build resource.o when icon changes...
'
'windres resource.rc resource.o

#Import "logo/resource.o"

#Endif

'----------------------------

'#Import "<reflection>"

#Import "<std>"
#Import "<mojo>"
#Import "<mojox>"
#Import "<tinyxml2>"

#Import "action/FileActions"
#Import "action/EditActions"
#Import "action/BuildActions"
#Import "action/HelpActions"
#Import "action/FindActions"
#Import "action/ViewActions"

#Import "dialog/FindDialog"
#Import "dialog/PrefsDialog"
#Import "dialog/EditProductDialog"
#Import "dialog/DialogExt"
#Import "dialog/NoTitleDialog"
#Import "dialog/FindInFilesDialog"

#Import "document/DocumentManager"
#Import "document/Ted2Document"
#Import "document/CodeDocument"
#Import "document/PlainTextDocument"
#Import "document/ImageDocument"
#Import "document/AudioDocument"
#Import "document/JsonDocument"
#Import "document/XmlDocument"

#Import "eventfilter/TextViewKeyEventFilter"
#Import "eventfilter/Monkey2KeyEventFilter"

#Import "parser/CodeItem"
#Import "parser/Parser"
#Import "parser/Monkey2Parser"
#Import "parser/ParserPlugin"

#Import "product/BuildProduct"
#Import "product/Mx2ccEnv"
#Import "product/ModuleManager"

#Import "syntax/Keywords"
#Import "syntax/Monkey2Keywords"
#Import "syntax/Highlighter"
#Import "syntax/Monkey2Highlighter"
#Import "syntax/CppHighlighter"
#Import "syntax/CppKeywords"
#Import "syntax/GlslHighlighter"
#Import "syntax/GlslKeywords"
#Import "syntax/CodeFormatter"
#Import "syntax/Monkey2Formatter"

#Import "testing/ParserTests"

#Import "utils/JsonUtils"
#Import "utils/Utils"

#Import "view/CodeTextView"
#Import "view/ConsoleViewExt"
#Import "view/ListViewExt"
#Import "view/AutocompleteView"
#Import "view/CodeTreeView"
#Import "view/TreeViewExt"
#Import "view/CodeGutterView"
#Import "view/ToolBarViewExt"
#Import "view/HintView"
#Import "view/HtmlViewExt"
#Import "view/ProjectBrowserView"
#Import "view/TabViewExt"
#Import "view/StatusBarView"
#Import "view/DebugView"
#Import "view/ProjectView"
#Import "view/HelpTreeView"
#Import "view/Ted2TextView"
#Import "view/JsonTreeView"
#Import "view/XmlTreeView"
#Import "view/Monkey2TreeView"
#Import "view/GutterView"
#Import "view/MenuExt"

#Import "MainWindow"
#Import "Plugin"
#Import "ThemeImages"
#Import "Prefs"
#Import "ProcessReader"


Namespace ted2go

Using std..
Using mojo..
Using mojox..
Using tinyxml2..


Global AppTitle:="Ted2Go v2.3.2"


Function Main()

	Prefs.LoadLocalState()
	
	Local root:=Prefs.MonkeyRootPath
	If Not root Then root=AppDir()
	
	' return real folder or empty string
	Local path:=SetupMonkeyRootPath( root,True )
	If Not path
		libc.exit_( 1 )
		Return
	Endif
	
	If path<>root
		Prefs.MonkeyRootPath=path
		Prefs.SaveLocalState()
	Endif
	
	'load ted2 state
	'
	Local jobj:=JsonObject.Load( "bin/ted2.state.json" )
	If Not jobj jobj=New JsonObject

	Prefs.LoadState( jobj )
	
	'initial theme
	'	
	If Not jobj.Contains( "theme" ) jobj["theme"]=New JsonString( "theme-classic-dark" )
	If Not jobj.Contains( "themeScale" ) jobj["themeScale"]=New JsonNumber( 1 )
	
	Local config:=New StringMap<String>
	
	config["initialTheme"]=jobj.GetString( "theme" )
	config["initialThemeScale"]=jobj.GetNumber( "themeScale" )
	
	'start the app!
	'	
	New AppInstance( config )
	
	'initial window state
	'
	Local flags:=WindowFlags.Resizable|WindowFlags.HighDPI

	Local rect:Recti
	
	If jobj.Contains( "windowRect" ) 
		rect=ToRecti( jobj["windowRect"] )
	Else
		Local w:=Min( 1024,App.DesktopSize.x-40 )
		Local h:=Min( 768,App.DesktopSize.y-64 )
		rect=New Recti( 0,0,w,h )
		flags|=WindowFlags.Center
	Endif

	New MainWindowInstance( AppTitle,rect,flags,jobj )
	
	' open docs from args
	Local args:=AppArgs()
	For Local i:=1 Until args.Length
		Local arg:=args[i]
		arg=arg.Replace( "\","/" )
		If GetFileType( arg ) = FileType.File
			MainWindow.OpenDocument( arg )
		Endif
	Next
	
	App.Run()
		
End

Function SetupMonkeyRootPath:String( rootPath:String,searchMode:Bool )
	
#If __DESKTOP_TARGET__
	
	ChangeDir( rootPath )
	
	If searchMode
		While GetFileType( "bin" )<>FileType.Directory Or GetFileType( "modules" )<>FileType.Directory
	
			If IsRootDir( CurrentDir() )
				
				Local ok:=Confirm( "Initializing","Error initializing - can't find working dir!~nDo you want to specify Monkey2 root folder now?" )
				If Not ok
					Return ""
				End
				Local s:=requesters.RequestDir( "Choose Monkey2 folder",AppDir() )
				ChangeDir( s )
				Continue
			Endif
			
			ChangeDir( ExtractDir( CurrentDir() ) )
		Wend
		
		rootPath=CurrentDir()
	Else
		
		Local ok:= (GetFileType( "bin" )=FileType.Directory And GetFileType( "modules" )=FileType.Directory)
		If Not ok
			Notify( "Monkey2 root folder","Incorrect folder!" )
			Return ""
		Endif
		
	Endif
	
#Endif
	
	Return rootPath
End

Function GetActionTextWithShortcut:String( action:Action )

	Return action.Text+" ("+action.HotKeyText+")"
End

