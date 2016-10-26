
Namespace ted2go


Class Ted2CodeTextView Extends CodeTextView

	Property FileType:String() 'where else we can store this type?
		return _type
	Setter( value:String )
		_type=value
		Keywords = KeywordsManager.Get(_type)
		Highlighter = HighlightersManager.Get(_type)
		Formatter = FormattersManager.Get(_type)
		Document.TextHighlighter = Highlighter.Painter
	End
	
	Property FilePath:String()
		return _path
	Setter(value:String)
		_path = value
	End
	
	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		TextViewKeyEventFilter.FilterKeyEvent( event,Self,FileType )
		
		If Not event.Eaten
			Super.OnKeyEvent( event )
		Endif
		
	End

	Private
	
	Field _type:String
	Field _path:String
	
End


Class Ted2TextView Extends TextView

	Method New()

		CursorType=CursorType.Line
		CursorColor=App.Theme.GetColor( "text-default" )
		SelectionColor=App.Theme.GetColor( "text-selected" )

#If __TARGET__<>"raspbian"
		CursorBlinkRate=2.5	'crashing on Pi?
#Endif

	End

	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		TextViewKeyEventFilter.FilterKeyEvent( event,Self )
		
		If Not event.Eaten Super.OnKeyEvent( event )
	End

End

