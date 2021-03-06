
Namespace ted2go


Class UndockWindow Extends Window
	
	Field _storeView:View
	Field _storeDocument:CodeDocument
	Field _storeTabbutton:TabButtonExt
	Field _storeIndex:Int
	Field _visible:Int
	Field _type:String
	
	Global _undockWindows:=New Stack<UndockWindow>
	
	Method New()
		
		Super.New( "Undock Window", MainWindow.Width/2, MainWindow.Height/2, WindowFlags.Resizable | WindowFlags.HighDPI | WindowFlags.Center )
		Self.UpdateWindow( True )
		_undockWindows.Push( Self )
	End
	
	Function NewUndockDocument:UndockWindow(_doc:CodeDocument)
		
		Local _window:UndockWindow
	
		For Local dw:=Eachin _undockWindows
			If dw.Title=_doc.Path Then _window=dw ; Exit
		Next
		
		If Not _window Then _window=New UndockWindow
		
		_window._storeDocument=_doc
		_doc.Close()
		_window.ContentView=_window._storeDocument.View
		_window.Title=_doc.Path
		_window._visible=True
		_window.Activated()
		_window._type="document"
		Return _window
	End
	
	Function NewUndock:UndockWindow( _tabbutton:TabButtonExt )
		
		Local _window:UndockWindow
	
		For Local dw:=Eachin _undockWindows
			If dw.Title=_tabbutton.Text Then _window=dw ; Exit
		Next
		
		If Not _window Then _window=New UndockWindow
		
		_tabbutton.CurrentHolder.MakeCurrent( _tabbutton.Text )
		_window.Title=_tabbutton.Text
		_tabbutton.Visible=False
	
		_window._storeTabbutton=_tabbutton
		_window._storeView=_tabbutton.CurrentHolder.CurrentView
		_window._storeIndex=_tabbutton.CurrentHolder.CurrentIndex
	
		_tabbutton.CurrentHolder.SetTabView( _window._storeIndex, Null )
		If Not _tabbutton.CurrentHolder.VisibleTabs Then _tabbutton.CurrentHolder.Visible=False
	
		For Local mk:=Eachin _tabbutton.CurrentHolder.Tabs
			If mk.Visible Then _tabbutton.CurrentHolder.MakeCurrent( mk.Text )
		Next
		
		_window.ContentView=_window._storeView
		_window._visible=True
		_window.Activated()
		_window._type="dock"
		Return _window
	End
	
	Method SetUndockFrame( _frame:Recti )

		
		SDL_SetWindowPosition( Self.Window.SDLWindow, _frame.X, _frame.Y )
		SDL_SetWindowSize( Self.Window.SDLWindow, _frame.Width, _frame.Height )
		Self.Restore()
		Local event:=New WindowEvent( EventType.WindowMoved, Self )
		SendWindowEvent( event )
	End
	
	Method OnWindowEvent( event:WindowEvent ) Override
		
		Select event.Type
			Case EventType.WindowClose
				CloseWindow()
			Default
				Super.OnWindowEvent( event )
		End
	End
	
	Method CloseWindow()
		Select _type
			Case "dock"
				Local view:=ContentView
				ContentView=Null
				_storeTabbutton.CurrentHolder.SetTabView( _storeIndex, view )
				_storeTabbutton.Visible=True
				If Not _storeTabbutton.CurrentHolder.Visible Then _storeTabbutton.CurrentHolder.Visible=True
				SDL_HideWindow( Self.Window.SDLWindow )
				Self._visible=False
			Case "document"
				Local _undockFile:=FileStream.Open(_storeDocument.Path,"w")
				_undockFile.WriteString(_storeDocument.TextView.Text)
				_undockFile.Close()
				ContentView=Null
				MainWindow.OpenDocument(_storeDocument.Path)
				SDL_HideWindow( Self.Window.SDLWindow )
				Self._visible=False
		End
	End
	
	Function RestoreUndock()
	
		For Local i:=Eachin _undockWindows
			i.CloseWindow()
		Next
	End
	
End

