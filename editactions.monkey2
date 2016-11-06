
Namespace ted2

Class EditActions

	Field undo:Action
	Field redo:Action
	Field cut:Action
	Field copy:Action
	Field paste:Action
	Field selectAll:Action
	Field wordWrap:Action
	Field gotoLine:Action
	
	Method New( docs:DocumentManager )
	
		_docs=docs
		
		undo=New Action( "Undo" )
		undo.Triggered=OnUndo
		undo.HotKey=Key.Z
		undo.HotKeyModifiers=Modifier.Menu|Modifier.Ignore

		redo=New Action( "Redo" )
		redo.Triggered=OnRedo
		redo.HotKey=Key.Y
		redo.HotKeyModifiers=Modifier.Menu|Modifier.Ignore

		cut=New Action( "Cut" )
		cut.Triggered=OnCut
		cut.HotKey=Key.X
		cut.HotKeyModifiers=Modifier.Menu|Modifier.Ignore

		copy=New Action( "Copy" )
		copy.Triggered=OnCopy
		copy.HotKey=Key.C
		copy.HotKeyModifiers=Modifier.Menu|Modifier.Ignore

		paste=New Action( "Paste" )
		paste.Triggered=OnPaste
		paste.HotKey=Key.V
		paste.HotKeyModifiers=Modifier.Menu|Modifier.Ignore

		selectAll=New Action( "Select all" )
		selectAll.Triggered=OnSelectAll
		selectAll.HotKey=Key.A
		selectAll.HotKeyModifiers=Modifier.Menu|Modifier.Ignore
		
		wordWrap=New Action( "Toggle word wrap" )
		wordWrap.Triggered=OnWordWrap
		wordWrap.HotKey=Key.W
		wordWrap.HotKeyModifiers=Modifier.Menu
		
		gotoLine=New Action( "Goto line" )
		gotoLine.Triggered=OnGotoLine
		gotoLine.HotKey=Key.G
		gotoLine.HotKeyModifiers=Modifier.Menu
	End
	
	Method Update()
	
		Local tv:=Cast<TextView>( App.KeyView )
		
		undo.Enabled=tv And tv.CanUndo
		redo.Enabled=tv And tv.CanRedo
		cut.Enabled=tv And tv.CanCut
		copy.Enabled=tv And tv.CanCopy
		paste.Enabled=tv And tv.CanPaste
		selectAll.Enabled=tv
	End
	
	Private
	
	Field _docs:DocumentManager
	
	Method OnUndo()

		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.Undo()
	End
	
	Method OnRedo()
	
		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.Redo()
	End
	
	Method OnCut()
	
		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.Cut()
	End

	Method OnCopy()

		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.Copy()
	End

	Method OnPaste()		
		
		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.Paste()
	End
	
	Method OnSelectAll()
		
		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.SelectAll()
	End
	
	Method OnWordWrap()
	
		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.WordWrap=Not tv.WordWrap
	End
	
	Method OnGotoLine()
	
		Local tv:=Cast<TextView>( App.KeyView )
		If Not tv Return
		
		Local line:=RequestInt( "Goto line:","Goto line",tv.CursorLine+1,0,1,tv.Document.NumLines )
		If Not line Return
		
		tv.GotoLine( line-1 )
		
		tv.MakeKeyView()
	End

End
