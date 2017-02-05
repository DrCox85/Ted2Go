
Namespace ted2go


Class ToolButtonExt Extends ToolButton

	Field Toggled:Void( state:Bool )
	
	Method New( action:Action,hint:String=Null )
		
		Super.New( action )
		PushButtonMode=True
		_hint=hint
		
		UpdateColors()
		
		App.ThemeChanged+=Lambda()
			UpdateColors()
		End
		
		Clicked+=Lambda()
			If ToggleMode Then IsToggled=Not IsToggled
		End
		
	End
	
	Property Hint:String()
		Return _hint
	Setter( value:String )
		_hint=value
	End
	
	Property IsToggled:Bool()
		Return _toggled
	Setter( value:Bool )
		If value = _toggled Return
		_toggled=value
		Toggled( _toggled )
	End
	
	Property ToggleMode:Bool()
		Return _toggleMode
	Setter( value:Bool )
		If value = _toggleMode Return
		_toggleMode=value
		If Not _toggleMode Then IsToggled=False
	End
		
		
	Protected
	
	Method OnMouseEvent( event:MouseEvent ) Override
		
		If _hint <> Null
			If event.Type = EventType.MouseEnter
				ShowHint( _hint,event.Location,Self )
			Elseif event.Type = EventType.MouseLeave
				HideHint()
			Endif
		Endif
		
		Super.OnMouseEvent( event )
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		If _toggled
			canvas.Color=_selColor
			canvas.LineWidth=1
			Utils.DrawRect( canvas,Rect,True )
		Endif	
		Super.OnRender( canvas )
	End
	
	
	Private
	
	Field _hint:String
	Field _selColor:Color
	Field _toggled:Bool,_toggleMode:Bool
	
	Method UpdateColors()
		
		_selColor=App.Theme.GetColor( "active" )
		
	End
	
End


Class ToolBarExt Extends ToolBar

	Method New()
		
		Super.New()
		MinSize=New Vec2i( 0,42 )
		Style=GetStyle( "ToolBarExt" )
	End
	
	Method AddIconicButton:ToolButtonExt( icon:Image,trigger:Void(),hint:String=Null )
		
		Local act:=New Action( Null,icon )
		act.Triggered=trigger
		Local b:=New ToolButtonExt( act,hint )
		AddView( b )
		Return b
	End
	
End

