
Namespace ted2

Class BuildError

	Field path:String
	Field line:Int
	Field msg:String
	Field removed:Bool
	
	Method New( path:String,line:Int,msg:String )
		Self.path=path
		Self.line=line
		Self.msg=msg
	End

	Operator<=>:Int( err:BuildError )
		If line<err.line Return -1
		If line>err.line Return 1
		Return 0
	End
	
End

Class BuildActions

	Field buildAndRun:Action
	Field build:Action
	Field nextError:Action
	Field lockBuildFile:Action
	Field updateModules:Action
	Field rebuildModules:Action
	Field moduleManager:Action
	Field rebuildHelp:Action
	
	Field configMenu:Menu
	Field targetMenu:Menu
	
	Method New( docs:DocumentManager,console:Console,debugView:DebugView )
	
		_docs=docs
		_console=console
		_debugView=debugView
		
		_docs.DocumentRemoved+=Lambda( doc:Ted2Document )

			If doc=_locked _locked=Null
		End
	
#If __HOSTOS__="macos"
		_mx2cc="bin/mx2cc_macos"
#Else If __HOSTOS__="windows"
		_mx2cc="bin/mx2cc_windows.exe"
#Else
		_mx2cc="bin/mx2cc_linux"
#Endif
		_mx2cc=RealPath( _mx2cc )
		
#if __HOSTOS__="macos"
		Local menuCmd:=Modifier.Gui
#else		
		Local menuCmd:=Modifier.Control
#endif
		buildAndRun=New Action( "Build And Run" )
		buildAndRun.Triggered=OnBuildAndRun
		buildAndRun.HotKey=Key.F5

		build=New Action( "Build Only" )
		build.Triggered=OnBuild
		build.HotKey=Key.F6
		
		nextError=New Action( "Next Error" )
		nextError.Triggered=OnNextError
		nextError.HotKey=Key.F4
		
		lockBuildFile=New Action( "Lock Build File" )
		lockBuildFile.Triggered=OnLockBuildFile
		lockBuildFile.HotKey=Key.L
		lockBuildFile.HotKeyModifiers=menuCmd
		
		updateModules=New Action( "Update Modules" )
		updateModules.Triggered=OnUpdateModules
		updateModules.HotKey=Key.U
		updateModules.HotKeyModifiers=menuCmd
		
		rebuildModules=New Action( "Rebuild Modules" )
		rebuildModules.Triggered=OnRebuildModules
		rebuildModules.HotKey=Key.U
		rebuildModules.HotKeyModifiers=menuCmd|Modifier.Shift
		
		moduleManager=New Action( "Module Manager" )
		moduleManager.Triggered=OnModuleManager
		
		rebuildHelp=New Action( "Rebuild Documentation" )
		rebuildHelp.Triggered=OnRebuildHelp
		
		local group:=New CheckGroup
		_debugConfig=New CheckButton( "Debug",,group )
		_debugConfig.Layout="fill-x"
		_releaseConfig=New CheckButton( "Release",,group )
		_releaseConfig.Layout="fill-x"
		_debugConfig.Clicked+=Lambda()
			_buildConfig="debug"
		End
		_releaseConfig.Clicked+=Lambda()
			_buildConfig="release"
		End
		_buildConfig="debug"
		configMenu=New Menu( "Config..." )
		configMenu.AddView( _debugConfig )
		configMenu.AddView( _releaseConfig )
		
		group=New CheckGroup
		_desktopTarget=New CheckButton( "Desktop",,group )
		_desktopTarget.Layout="fill-x"
		_consoleTarget=New CheckButton( "Console",,group )
		_consoleTarget.Layout="fill-x"
		_emscriptenTarget=New CheckButton( "Emscripten",,group )
		_desktopTarget.Layout="fill-x"
		_desktopTarget.Clicked+=Lambda()
			_buildTarget="desktop"
		End
		_consoleTarget.Clicked+=Lambda()
			_buildTarget="console"
		End
		_emscriptenTarget.Clicked+=Lambda()
			_buildTarget="emscripten"
		End
		_buildTarget="desktop"
		targetMenu=New Menu( "Target..." )
		targetMenu.AddView( _desktopTarget )
		targetMenu.AddView( _consoleTarget )
		targetMenu.AddView( _emscriptenTarget )

	End
	
	Method SaveState( jobj:JsonObject )
		
		If _locked jobj["lockedDocument"]=New JsonString( _locked.Path )
		
		jobj["buildConfig"]=New JsonString( _buildConfig )
		
		jobj["buildTarget"]=New JsonString( _buildTarget )
	End
		
	Method LoadState( jobj:JsonObject )
	
		If jobj.Contains( "lockedDocument" )
			Local path:=jobj["lockedDocument"].ToString()
			_locked=Cast<Monkey2Document>( _docs.FindDocument( path ) )
			If _locked _locked.State="+"
		Endif
		
		If jobj.Contains( "buildConfig" )
			_buildConfig=jobj["buildConfig"].ToString()
			Select _buildConfig
			Case "release"
				_releaseConfig.Checked=True
			Default
				_debugConfig.Checked=True
				_buildConfig="debug"
			End
		Endif
		
		If jobj.Contains( "buildTarget" )
			_buildTarget=jobj["buildTarget"].ToString()
			Select _buildTarget
			Case "console"
				_consoleTarget.Checked=True
			Case "emscripten"
				_emscriptenTarget.Checked=True
			Default
				_desktopTarget.Checked=True
				_buildTarget="desktop"
			End
		Endif
			
	End
	
	Method Update()
	
		While Not _errors.Empty And _errors.First.removed
			_errors.RemoveFirst()
		Wend
	
		Local idle:=Not _console.Running
		Local canbuild:=idle And BuildDoc()<>Null
		
		build.Enabled=canbuild
		buildAndRun.Enabled=canbuild
		nextError.Enabled=Not _errors.Empty
		updateModules.Enabled=idle
		rebuildModules.Enabled=idle
		rebuildHelp.Enabled=idle
	End
	
	Private
	
	Field _docs:DocumentManager
	Field _console:Console
	Field _debugView:DebugView

	Field _mx2cc:String
	
	Field _locked:Monkey2Document
	
	Field _errors:=New List<BuildError>
	
	Field _buildConfig:String
	Field _buildTarget:String

	Field _debugConfig:CheckButton
	Field _releaseConfig:CheckButton
	Field _consoleTarget:CheckButton
	Field _desktopTarget:CheckButton
	Field _emscriptenTarget:CheckButton
	
	Field _appFile:String
	
	Method BuildDoc:Monkey2Document()
		
		If Not _locked Return Cast<Monkey2Document>( _docs.CurrentDocument )
		
		Return _locked
	End
	
	Method SaveAll:Bool()
	
		For Local doc:=Eachin _docs.OpenDocuments
			If Not doc.Save() Return False
		Next
		
		Return True
	End
	
	Method ClearErrors()
	
		_errors.Clear()
	
		For Local doc:=Eachin _docs.OpenDocuments
			Local mx2Doc:=Cast<Monkey2Document>( doc )
			If mx2Doc mx2Doc.Errors.Clear()
		Next

	End

	Method GotoError( err:BuildError )
	
		Local doc:=Cast<Monkey2Document>( _docs.OpenDocument( err.path,True ) )
		If Not doc Return
		
		Local tv:=Cast<TextView>( doc.View )
		If Not tv Return
		
		MainWindow.UpdateWindow( False )
		
		tv.GotoLine( err.line )
	End
	
	Method BuildMx2:Bool( cmd:String,progressText:String )
	
		ClearErrors()
		
		_appFile=""

		_console.Clear()
		
		MainWindow.ShowBuildConsole( False )
		
		If _console.Running Return False
		
		If Not SaveAll() Return False

		If Not _console.Start( cmd )
			Alert( "Failed to start process: '"+cmd+"'" )
			Return False
		Endif
		
		Local progress:=New ProgressDialog( "Building",progressText )
		
		progress.MinSize=New Vec2i( 320,0 )
		
		progress.AddAction( "Cancel" ).Triggered=Lambda()
			_console.Terminate()
		End
		
		progress.Open()
		
		Repeat
		
			Local stdout:=_console.ReadStdout()
			If Not stdout Exit
			
			If stdout.StartsWith( "Application built:" )

				_appFile=stdout.Slice( stdout.Find( ":" )+1 ).Trim()
			Else
			
				Local i:=stdout.Find( "] : Error : " )
				If i<>-1
					Local j:=stdout.Find( " [" )
					If j<>-1
						Local path:=stdout.Slice( 0,j )
						Local line:=Int( stdout.Slice( j+2,i ) )-1
						Local msg:=stdout.Slice( i+12 )
						
						Local err:=New BuildError( path,line,msg )
						Local doc:=Cast<Monkey2Document>( _docs.OpenDocument( path,False ) )
						
						If doc
							doc.Errors.Add( err )
							If _errors.Empty 
								MainWindow.ShowBuildConsole( True )
								GotoError( err )
							Endif
							_errors.Add( err )
						Endif
						
					Endif
				Endif
			Endif
			
			_console.Write( stdout )
		
		Forever
		
		progress.Close()
		
		Return _console.ExitCode=0
	End
	
	Method BuildModules:Bool( clean:Bool )
	
		Local n:=clean ? "Rebuilding" Else "Updating"
		
		For Local config:=0 Until 2
		
			Local t:=(config ? "debug" Else "release")
			
			Local cmd:=_mx2cc+" makemods"
			If clean cmd+=" -clean"
			cmd+=" -config="+t
			
			If Not BuildMx2( cmd,n+" "+t+" modules..." ) Return False

		Next
		
		Return True
	End
	
	Method MakeDocs:Bool()
	
		Return BuildMx2( _mx2cc+" makedocs","Rebuilding documentation..." )
	End
	
	Method BuildApp:Bool( config:String,target:String,run:bool )
	
		Local buildDoc:=BuildDoc()
		If Not buildDoc Return False
		
		Local appType:="gui"
		If target="console"
			appType="console"
			target="desktop"
		End

		Local cmd:=_mx2cc+" makeapp -build"
		cmd+=" -apptype="+appType+" "
		cmd+=" -config="+config
		cmd+=" -target="+target
		cmd+=" ~q"+buildDoc.Path+"~q"
		
		If Not BuildMx2( cmd,"Building "+buildDoc.Path+"..." ) Return False
		
		If Not run Or Not _appFile Return True
		
		_debugView.DebugApp( _appFile,config )
		
		Return True
	End
	
	Method OnBuild()
	
		BuildApp( _buildConfig,_buildTarget,False )
	End
	
	Method OnBuildAndRun()

		BuildApp( _buildConfig,_buildTarget,True )
	End
	
	Method OnNextError()
	
		While Not _errors.Empty And _errors.First.removed
			_errors.RemoveFirst()
		Wend
		
		If _errors.Empty Return
		
		_errors.AddLast( _errors.RemoveFirst() )
			
		GotoError( _errors.First )
	End
	
	Method OnLockBuildFile()
	
		Local doc:=Cast<Monkey2Document>( _docs.CurrentDocument )
		If Not doc Return
		
		If _locked _locked.State=""
		
		If doc=_locked
			_locked=Null
			Return
		Endif
		
		_locked=doc
		_locked.State="+"
		
	End
	
	Method OnUpdateModules()
	
		BuildModules( False )
	End
	
	Method OnRebuildModules()
	
		BuildModules( True )
	End
	
	Method OnModuleManager()
	
		Local modman:=New ModuleManager( _mx2cc,_console )
		
		modman.Open()
	End
	
	Method OnRebuildHelp()
	
		MakeDocs()
		
		MainWindow.UpdateHelpTree()
	End
	
End
