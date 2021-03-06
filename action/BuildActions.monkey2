
Namespace ted2go


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


Interface IModuleBuilder
	
	' cleanState:
	' -1: don't clean
	' 0: use previous
	' 1: clean
	Method BuildModules:Bool( modules:String="",configs:String="",cleanState:Int=0 )
	
End


Class BuildActions Implements IModuleBuilder

	Field buildAndRun:Action
	Field debugApp:Action
	Field build:Action
	Field semant:Action
	Field buildSettings:Action
	Field nextError:Action
	Field lockBuildFile:Action
	Field updateModules:Action
	Field moduleManager:Action
	Field rebuildHelp:Action
	Field forceStop:Action
	
	Field targetMenu:MenuExt
	
	
	Field PreBuild:Void()
	Field PreSemant:Void()
	Field PreBuildModules:Void()
	Field ErrorsOccured:Void(errors:BuildError[])
	
	Method New( docs:DocumentManager,console:ConsoleExt,debugView:DebugView )
	
		_docs=docs
		_console=console
		_debugView=debugView
		
		buildAndRun=ActionById( ActionId.Run )
		buildAndRun.Triggered=OnBuildAndRun
		
		debugApp=ActionById( ActionId.Debug )
		debugApp.Triggered=OnDebugApp

		build=ActionById( ActionId.Build )
		build.Triggered=OnBuild
		
		semant=ActionById( ActionId.Semant )
		semant.Triggered=OnSemant
		
		forceStop=ActionById( ActionId.ForceStop )
		forceStop.Triggered=OnForceStop
		
		buildSettings=ActionById( ActionId.ProductSettings )
		buildSettings.Triggered=OnBuildFileSettings
		
		nextError=ActionById( ActionId.NextError )
		nextError.Triggered=OnNextError
		
		lockBuildFile=ActionById( ActionId.LockBuildFile )
		lockBuildFile.Triggered=_docs.LockBuildFile
		
		updateModules=ActionById( ActionId.UpdateModules )
		updateModules.Triggered=OnUpdateModules
		
		moduleManager=ActionById( ActionId.ModuleManager )
		moduleManager.Triggered=OnModuleManager
		
		rebuildHelp=ActionById( ActionId.RebuildDocs )
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
		_buildConfig="release"

		group=New CheckGroup

		_desktopTarget=New CheckButton( "Desktop",,group )
		_desktopTarget.Layout="fill-x"
		
		_emscriptenTarget=New CheckButton( "Emscripten",,group )
		_emscriptenTarget.Layout="fill-x"
		
		_androidTarget=New CheckButton( "Android",,group )
		_androidTarget.Layout="fill-x"
		
		_iosTarget=New CheckButton( "iOS",,group )
		_iosTarget.Layout="fill-x"
		
		_verboseMode=New CheckButton( "Verbose")
		_verboseMode.Layout="fill-x"
		
		targetMenu=New MenuExt( "Build target" )
		targetMenu.AddView( _debugConfig )
		targetMenu.AddView( _releaseConfig )
		targetMenu.AddSeparator()
		targetMenu.AddView( _desktopTarget )
		targetMenu.AddView( _emscriptenTarget )
		targetMenu.AddView( _androidTarget )
		targetMenu.AddView( _iosTarget )
		targetMenu.AddSeparator()
		targetMenu.AddAction( buildSettings )
		targetMenu.AddSeparator()
		targetMenu.AddView( _verboseMode )
		
		'check valid targets...WIP...
		
		_validTargets=EnumValidTargets( _console )
		
		If _validTargets _buildTarget=_validTargets[0].ToLower()
		
		If _validTargets.Contains( "desktop" )
			_desktopTarget.Clicked+=Lambda()
				_buildTarget="desktop"
			End
		Else
			_desktopTarget.Enabled=False
		Endif
		
		If _validTargets.Contains( "emscripten" )
			_emscriptenTarget.Clicked+=Lambda()
				_buildTarget="emscripten"
			End
		Else
			_emscriptenTarget.Enabled=False
		Endif

		If _validTargets.Contains( "android" )
			_androidTarget.Clicked+=Lambda()
				_buildTarget="android"
			End
		Else
			_androidTarget.Enabled=False
		Endif

		If _validTargets.Contains( "ios" )
			_iosTarget.Clicked+=Lambda()
				_buildTarget="ios"
			End
		Else
			_iosTarget.Enabled=False
		Endif
	End
	
	Property Verbosed:Bool()
	
		Return _verboseMode.Checked
	End
	
	Method SaveState( jobj:JsonObject )
		
		jobj["buildConfig"]=New JsonString( _buildConfig )
		
		jobj["buildTarget"]=New JsonString( _buildTarget )
		
		jobj["buildVerbose"]=New JsonBool( _verboseMode.Checked )
	End
	
	Method LoadState( jobj:JsonObject )
	
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
			
			local target:=jobj["buildTarget"].ToString()
			
			If _validTargets.Contains( target )
				
				_buildTarget=target
				
				Select _buildTarget
				Case "desktop"
					_desktopTarget.Checked=True
				Case "emscripten"
					_emscriptenTarget.Checked=True
				Case "android"
					_androidTarget.Checked=True
				Case "ios"
					_iosTarget.Checked=True
				End
			
			Endif
			
		Endif
		
		If jobj.Contains( "buildVerbose" )
			_verboseMode.Checked=jobj.GetBool( "buildVerbose" )
		Endif
		
	End
	
	Method Update()
	
		While Not _errors.Empty And _errors.First.removed
			_errors.RemoveFirst()
		Wend
		
		Local idle:=Not _console.Running
		Local canbuild:=idle And FilePathToBuild And _buildTarget
		
		build.Enabled=canbuild
		buildAndRun.Enabled=canbuild
		semant.Enabled=canbuild
		debugApp.Enabled=canbuild
		nextError.Enabled=Not _errors.Empty
		updateModules.Enabled=idle
		rebuildHelp.Enabled=idle
		moduleManager.Enabled=idle
	End
	
	Method BuildModules:Bool( modules:String="",configs:String="",cleanState:Int=0 )
		
		If Not modules Then modules=_storedModules
		
		If Not configs
			configs=_storedConfigs
			If Not configs Then configs="debug release"
		Endif
		
		Local clean:Bool
		If cleanState=0
			clean=_storedClean
		Else
			clean=(cleanState=1)
		Endif
		
		Local selTargets:=(_storedTargets ?Else "desktop")
		
		Local dialog:=New UpdateModulesDialog( _validTargets,selTargets,modules,configs,clean )
		dialog.Title="Update / Rebuild modules"
		
		Local ok:=dialog.ShowModal()
		If Not ok Return False
		
		Local result:Bool
		
		Local targets:=dialog.SelectedTargets
		modules=dialog.SelectedModules
		configs=dialog.SelectedConfigs
		clean=dialog.NeedClean
		
		' store
		_storedTargets=targets.Join( " " )
		_storedModules=modules
		_storedConfigs=configs
		_storedClean=clean
		
		Local time:=Millisecs()
		
		For Local target:=Eachin targets
			result=BuildModules( target,modules,configs,clean )
			If result=False Exit
		Next
		
		time=Millisecs()-time
		Local prefix:=clean ? "Rebuild" Else "Update"
		
		If result
			_console.Write( "~n"+prefix+" modules completed successfully!~n" )
		Else
			_console.Write( "~n"+prefix+" modules failed.~n" )
		Endif
		_console.Write( "Total time elapsed: "+FormatTime( time )+".~n" )
		
		Return result
	End
	
	Method GotoError( err:BuildError )
		
		Local targetPath:=GetCaseSensitivePath( err.path )
		Local doc:=_docs.OpenDocument( targetPath,True,True )
		If doc
			_docs.CurrentCodeDocument.JumpToPosition( targetPath,New Vec2i( err.line,0 ) )
		Endif
	End
	
	
	Private
	
	Field _docs:DocumentManager
	Field _console:ConsoleExt
	Field _debugView:DebugView
	
	Field _errors:=New List<BuildError>
	
	Field _buildConfig:String
	Field _buildTarget:String
	
	Field _debugConfig:CheckButton
	Field _releaseConfig:CheckButton
	Field _desktopTarget:CheckButton
	Field _emscriptenTarget:CheckButton
	Field _androidTarget:CheckButton
	Field _iosTarget:CheckButton
	Field _verboseMode:CheckButton
	
	Field _validTargets:StringStack
	Field _timing:Long
	
	Field _storedModules:String
	Field _storedConfigs:String
	Field _storedTargets:String
	Field _storedClean:Bool
	
	Property FilePathToBuild:String()
	
		Return PathsProvider.GetActiveMainFilePath()
	End
	
	Property FilePathToBuildWithPrompt:String()
		
		Return PathsProvider.GetActiveMainFilePath( True,True )
	End
	
	Method SaveAll:Bool( buildFile:String )
		
		Local proj:="" 'ProjectView.FindProjectByFile( buildFile )
		
		For Local doc:=Eachin _docs.OpenDocuments
			' save docs only for built project
			If proj And Not doc.Path.StartsWith( proj ) Continue
			If Not doc.Save() Return False
		Next
		
		Return True
	End
	
	Method ClearErrors()
	
		_errors.Clear()
	
		For Local doc:=Eachin _docs.OpenDocuments
			Local mx2Doc:=Cast<CodeDocument>( doc )
			If mx2Doc mx2Doc.Errors.Clear()
		Next

	End

	Method BuildMx2:Bool( cmd:String,progressText:String,action:String="build",buildFile:String="",showElapsedTime:Bool=False )
	
		MainWindow.StoreConsoleVisibility()
		
		MainWindow.ShowBuildConsole()
		
		If Not SaveAll( buildFile ) Return False
		
		_timing=Millisecs()
		
		If Not _console.Start( cmd )
			Alert( "Failed to start process: '"+cmd+"'" )
			Return False
		Endif
		
		Local title := (action="semant") ? "Checking" Else "Building"
		
		Local s:=progressText
		If Not s.EndsWith( "..." ) Then s+="..."
		
		MainWindow.ShowStatusBarText( s )
		MainWindow.ShowStatusBarProgress( _console.Terminate )
		
		Local hasErrors:=False
		
		Repeat
		
			Local result:=_console.ReadStdoutWithErrors()
			Local stdout:=result.stdout
			If Not stdout Exit
			
			If stdout.StartsWith( "Application built:" )

'				_appFile=stdout.Slice( stdout.Find( ":" )+1 ).Trim()
			Else
				
				Local err:=result.error
				If err
					hasErrors=True
					
					Local buildErr:=New BuildError( err.path,err.line,err.message )
					Local doc:=Cast<CodeDocument>( _docs.OpenDocument( GetCaseSensitivePath( buildErr.path ),False ) )
					
					If doc
						doc.AddError( buildErr )
						'If _errors.Empty
						'	MainWindow.ShowBuildConsole( True )
						'	GotoError( err )
						'Endif
						_errors.Add( buildErr )
					Endif
					
				Endif
				
				If Not hasErrors
					Local i:=stdout.Find( "Build error: " )
					hasErrors=(i<>-1)
				Endif
				
			Endif
			
			_console.Write( stdout )
		
		Forever
		
		If Not _errors.Empty
			ErrorsOccured( _errors.ToArray() )
		Endif
		
		MainWindow.HideStatusBarProgress()
		
		Local status:=""
		If hasErrors
			status="{0} failed. See the build console for details."
		Else
			If _console.ExitCode=0
				status="{0} finished."
			Else
				status="{0} cancelled."
				' notify about cancellation
				_console.Write( "~n"+status.Replace( "{0}",title )+"~n" )
			Endif
		Endif
		status=status.Replace( "{0}",title )
		
		If showElapsedTime
			Local elapsed:=(Millisecs()-_timing)
			status+="   Time elapsed: "+FormatTime( elapsed )+"."
		Endif
		
		MainWindow.ShowStatusBarText( status )
		
		Return _console.ExitCode=0
	End

	Method BuildModules:Bool( target:String,modules:String,configs:String,clean:Bool )
		
		PreBuildModules()
		
		Local msg:=(clean ? "Rebuilding ~ " Else "Updating ~ ")+target
		
		Local arr:=configs.Split( " " )
		For Local cfg:=Eachin arr
		
			'Local cfg:=(config ? "debug" Else "release")
			
			Local cmd:=MainWindow.Mx2ccPath+" makemods -target="+target
			If clean cmd+=" -clean"
			If Verbosed cmd+=" -verbose"
			cmd+=" -config="+cfg
			If modules Then cmd+=" "+modules
			
			Local s:=msg+" ~ "+cfg+" ~ ["
			s+=modules ? modules Else "all modules"
			s+="]..."
			If Not BuildMx2( cmd,s ) Return False
		Next
		
		Return True
	End
	
	Method MakeDocs:Bool()
	
		Return BuildMx2( MainWindow.Mx2ccPath+" makedocs","Rebuilding documentation...","build","",True )
	End
	
	Method AddResourceFile:String(file:String,product:BuildProduct)
		
		Local iconFile:=product.GetIconFile()
			
		If GetFileType(iconFile)=FileType.File And ExtractExt(iconFile)=".ico" Then
			
			Local saveDir:=CurrentDir()
			Local mingwpath:=Prefs.MingWPath+"\bin\"
			If Not FileExists(mingwpath+"\windres.exe") Alert("Icon compile error.~n~nWrong MingW64 Path~n~nSet Path in Preferences");Return file
			Local mainpath:=ExtractDir(file)
			Local tempfile:=StripExt(file)+"_icon.monkey2"
			Local rcfile:=StripExt(file)+".rc"
			
			'Create Resource File
			Local _rcFile:=FileStream.Open(rcfile,"w")
			Local _icon:String				=StripDir(iconFile)
			Local _companyName:String		=product.GetCompanyName()
			Local _fileDescription:String	=product.GetFileDescription()
			Local _fileVersion:String		=product.GetFileVersion()
			Local _internalName:String		=product.GetInternalName()
			Local _legalCopyright:String	=product.GetLegalCopyright()
			Local _originalFilename:String	=product.GetOriginalFilename()
			Local _productName:String		=product.GetProductName()
			Local _productVersion:String	=product.GetProductVersion()
			
			_rcFile.WriteLine("AppIcon ICON ~q"+_icon+"~q~r
			1 VERSIONINFO~r
			FILEVERSION     1,0,0,0~r
			PRODUCTVERSION  1,0,0,0~r
			BEGIN~r
			  BLOCK ~qStringFileInfo~q~r
			  BEGIN~r
			    BLOCK ~q080904E4~q~r
			    BEGIN~r")
			    
			   	  If _companyName _rcFile.WriteLine("VALUE ~qCompanyName~q, ~q"+_companyName+"~q~r")
			      If _fileDescription _rcFile.WriteLine("VALUE ~qFileDescription~q, ~q"+_fileDescription+"~q~r")
			      If _fileVersion _rcFile.WriteLine("VALUE ~qFileVersion~q, ~q"+_fileVersion+"~q~r")
			      If _internalName _rcFile.WriteLine("VALUE ~qInternalName~q, ~q"+_internalName+"~q~r")
			      If _legalCopyright _rcFile.WriteLine("VALUE ~qLegalCopyright~q, ~q"+_legalCopyright+"~q~r")
			      If _originalFilename _rcFile.WriteLine("VALUE ~qOriginalFilename~q, ~q"+_originalFilename+"~q~r")
			      If _productName _rcFile.WriteLine("VALUE ~qProductName~q, ~q"+_productName+"~q~r")
			      If _productVersion _rcFile.WriteLine("VALUE ~qProductVersion~q, ~q"+_productVersion+"~q~r")
			      
			_rcFile.WriteLine("END~r
			  END~r
			  BLOCK ~qVarFileInfo~q~r
			  BEGIN~r
			    VALUE ~qTranslation~q, 0x407, 1252~r
			  END~r
			END~r
			")
			_rcFile.Close()
			
			CopyFile(iconFile,mingwpath+StripDir(iconFile))
			CopyFile(rcfile,mingwpath+"resource.rc")
			ChangeDir(mingwpath)
			_console.Start("windres -v --target=pe-i386 resource.rc resource.o")
			Repeat
				Local result:=_console.ReadStdoutWithErrors()
				Local stdout:=result.stdout
				If Not stdout Exit
				_console.Write( stdout )
			Forever
		
			_console.Start("windres -v --target=pe-x86-64 resource.rc resource_x64.o")
			Repeat
				Local result:=_console.ReadStdoutWithErrors()
				Local stdout:=result.stdout
				If Not stdout Exit
				_console.Write( stdout )
			Forever
		
			ChangeDir(saveDir)
			_console.Write("~nCreate Icon Files...")
			_console.Write("~nDone.")
			_console.Write("~n")
			CopyFile(mingwpath+"resource.o", mainpath+"resource.o")
			CopyFile(mingwpath+"resource_x64.o", mainpath+"resource_x64.o")
			DeleteFile(rcfile)
			DeleteFile(mingwpath+"resource.o")
			DeleteFile(mingwpath+"resource_x64.o")
			DeleteFile(mingwpath+"resource.rc")
			DeleteFile(mingwpath+StripDir(iconFile))
			If Not FileExists(mainpath+"resource.o")Then _console.Write("No resource found");Return file
			If Not FileExists(mainpath+"resource_x64.o")Then _console.Write("No resource_x64 found"); Return file
			'Create new file with Icon Imports
			Local _readFile:=FileStream.Open(file,"r")
			Local _writeFile:=FileStream.Open(tempfile,"w")
			_writeFile.WriteLine("#If __ARCH__=~qx86~q")
			_writeFile.WriteLine("#Import ~qresource.o~q")
			_writeFile.WriteLine("#Elseif __ARCH__=~qx64~q")
			_writeFile.WriteLine("#Import ~qresource_x64.o~q")
			_writeFile.WriteLine("#Endif")
			_writeFile.WriteLine("'END ICON CODE")
			While Not _readFile.Eof
				Local _line:=_readFile.ReadLine()
				_writeFile.WriteLine(_line)
			Wend
			_readFile.Close()
			_writeFile.Close()
			
			Return tempfile
		Else
			Return file
		End
	End
	
	Method BuildApp:Bool( config:String,target:String,sourceAction:String )
		
		ClearErrors()
			
		_console.Clear()
		
		Local buildDocPath:=FilePathToBuildWithPrompt
		If Not buildDocPath Return False
		
		Local mainFilePath:=PathsProvider.GetMainFileOfDocument(buildDocPath)
		If mainFilePath Then buildDocPath=mainFilePath
		
		Local product:=BuildProduct.GetBuildProduct( buildDocPath,target,False )
		If Not product Return False
		
		#if __TARGET__="windows"
		buildDocPath=AddResourceFile(buildDocPath,product)
		#Endif
		
		Local opts:=product.GetMx2ccOpts()
		
		Local run:=(sourceAction="run")
		
		Local action:=sourceAction
		If run Then action="build"
		
		Local cmd:=MainWindow.Mx2ccPath+" makeapp -"+action+" "+opts
		If Verbosed cmd+=" -verbose"
		cmd+=" -config="+config
		cmd+=" -target="+target
		cmd+=" ~q"+buildDocPath+"~q"
		
		Local title := sourceAction="build" ? "Building" Else (sourceAction="run" ? "Running" Else "Checking")
		Local msg:=title+" ~ "+target+" ~ "+config+" ~ "+StripDir( buildDocPath )
		
		If Not BuildMx2( cmd,msg,sourceAction,buildDocPath,True ) Return False
	
		_console.Write("~nDone.")
		
		If buildDocPath.Contains("_icon.monkey2")Then
			Local path:=ExtractDir(buildDocPath)
			DeleteFile(buildDocPath)
			DeleteFile(path+"resource.o")
			DeleteFile(path+"resource_x64.o")
		End
		
		If Not run
			MainWindow.RestoreConsoleVisibility()
			Return True
		Endif
		
		Local exeFile:=product.GetExecutable()
		Local cmdLine:=product.GetCommandLine()
		If Not exeFile Return True
		
		Select target
		Case "desktop"
			
			MainWindow.ShowStatusBarText( "   App is running now...",True )
			MainWindow.SetStatusBarActive( True )
			MainWindow.ShowStatusBarProgress( MainWindow.OnForceStop,True )
			
			_debugView.DebugApp( exeFile,config,cmdLine )

		Case "emscripten"
		
			Local mserver:=GetEnv( "MX2_MSERVER" )
			If mserver _console.Run( mserver+" ~q"+exeFile+"~q" )
		
		End
		
		Return True
	End
	
	Method OnBuildAndRun()
		
		PreBuild()
		
		If _console.Running Return
		
		BuildApp( _buildConfig,_buildTarget,"run" )
	End
	
	Method OnDebugApp()
	
		PreBuild()
	
		If _console.Running Return
	
		BuildApp( "debug",_buildTarget,"run" )
	End
	
	Method OnBuild()
		
		PreBuild()
		
		If _console.Running Return
	
		BuildApp( _buildConfig,_buildTarget,"build" )
	End
	
	Method OnSemant()
	
		PreSemant()
		
		If _console.Running Return
	
		BuildApp( _buildConfig,_buildTarget,"semant" )
	End
	
	Method OnForceStop()
	
		MainWindow.OnForceStop()
	End
	
	Method OnNextError()
	
		While Not _errors.Empty And _errors.First.removed
			_errors.RemoveFirst()
		Wend
		
		If _errors.Empty Return
		
		_errors.AddLast( _errors.RemoveFirst() )
		
		GotoError( _errors.First )
	End
	
	Method OnBuildFileSettings()

		Local path:=FilePathToBuild
		If Not path Return
		
		Local product:=BuildProduct.GetBuildProduct( path,_buildTarget,True )
	End
	
	Method OnUpdateModules()
		
		If _console.Running Return
	
		BuildModules()
	End
	
	Method OnModuleManager()
	
		If _console.Running Return
	
		Local modman:=New ModuleManager( _console )
		
		modman.Open()
	End
	
	Method OnRebuildHelp()
	
		If _console.Running Return
	
		MakeDocs()
		
		MainWindow.UpdateHelpTree()
	End
	
End
