
Namespace ted2go


Class ImageDocumentView Extends View

	Method New( doc:ImageDocument )
		_doc=doc
		
		Layout="fill"
		
		_checkButton=New CheckButton( "Filtering" )
		_checkButton.Clicked=Lambda()
			_drag=False
			ChangeFiltering( _checkButton.Checked )
		End
		
		_label=New Label( " " )
		_label.Style=App.Theme.GetStyle( "PushButton" )
		_label.Layout="float"
		_label.Gravity=New Vec2f( .5,1 )
		_label.AddView( _checkButton )
		_label.Clicked=Lambda()
			_drag=False
		End
		
		_doc.ImageChanged=Lambda()
			If Not _doc.Image 
				_label.Text=""
				Return
			Endif
			
			Local format:="?????"
			Select _doc.Image.Texture.Format
			Case PixelFormat.I8 format="PixelFormat.I8"
			Case PixelFormat.A8 format="PixelFormat.A8"
			Case PixelFormat.IA16 format="PixelFormat.IA16"
			Case PixelFormat.RGB24 format="PixelFormat.RGB24"
			Case PixelFormat.RGBA32 format="PixelFormat.RGBA32"
			End
			
			_label.Text="Width="+_doc.Image.Width+", Height="+_doc.Image.Height+", BytesPerPixel="+PixelFormatDepth( _doc.Image.Texture.Format )+", format="+format+
			"~nPath: "+_doc.ImagePath+
			"~nLeft Mouse Down move image, Zoom with Mousewheel, Mouse Right Reset"
		End
		
		AddChildView( _label )
	End
	
	Protected
	
	Method OnLayout() Override
	
		_label.Frame=Rect
	End
	
	Method OnRender( canvas:Canvas ) Override
		
		App.RequestRender()
		For Local x:=0 Until Width Step 64
			For Local y:=0 Until Height Step 64
				canvas.Color=(x~y) & 64 ? New Color( .1,.1,.1 ) Else New Color( .05,.05,.05 )
				canvas.DrawRect( x,y,64,64 )
			Next
		Next
		
		If Not _doc.Image Return
		
		canvas.TextureFilteringEnabled=_filterEnable
		
		canvas.Color=Color.White
		
		canvas.Translate( Width/2,Height/2 )
		
		canvas.Scale( _zoom,_zoom )
		
		canvas.DrawImage( _doc.Image,_pos.x/_zoom,_pos.y/_zoom )	
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
			Case EventType.MouseWheel
				If event.Wheel.Y>0
					_zoom*=1.1
					_pos.x*=1.1
					_pos.y*=1.1
				Else If event.Wheel.Y<0
					_zoom/=1.1
					_pos.x/=1.1
					_pos.y/=1.1
				Endif
			Case EventType.MouseDown
				If( _drag=False And event.Button=MouseButton.Left )
					_drag=True
					_uimouse.x=Mouse.Location.x-_pos.x
					_uimouse.y=Mouse.Location.y-_pos.y
				End
				If( event.Button=MouseButton.Right )Then 
					_zoom=1
					_pos.x=0
					_pos.y=0
				End
			Case EventType.MouseUp
				_drag=False
			Case EventType.MouseMove
				If( _drag )
					_pos.x=Mouse.Location.x-_uimouse.x
					_pos.y=Mouse.Location.y-_uimouse.y
				End	
		End
	End
	
	Method ChangeFiltering( _filter:Bool )
		
		_filterEnable=_filter
		_doc.Image=Image.Load( _doc.ImagePath )
		_doc.Image.Handle=New Vec2f( .5,.5 )	
	End
	
	Private
	
	Field _zoom:Float=1
		
	Field _doc:ImageDocument
	
	Field _label:Label
	
	Field _checkButton:CheckButton
	
	Field _pos:Vec2f
		
	Field _drag:Bool
	
	Field _uimouse:Vec2i
	
	Field _filterEnable:Bool
	
	Field _filterSwitch:Bool
End

Class ImageDocument Extends Ted2Document

	Field ImageChanged:Void()

	Method New( path:String )
		
		Super.New( path )
		
		_view=New ImageDocumentView( Self )
	End
	
	Property Image:Image()
	
		Return _image
	Setter (value:Image)
		
		_image=value
	End
	
	Property ImagePath:String()
		
		Return _path
	End
	
	Protected
	
	Method OnLoad:Bool() Override
	
		_image=Image.Load( Path )
		If Not _image Return False
		_path=Path
		
		_image.Handle=New Vec2f( .5,.5 )
		
		ImageChanged()
		
		Return True
	End
	
	Method OnSave:Bool() Override

		Return False
	End
	
	Method OnClose() Override
	
		If _image _image.Discard()

		_image=Null
	End
	
	Method OnCreateView:ImageDocumentView() Override
	
		Return _view
	End
	
	Private
	
	Field _image:Image
	
	Field _view:ImageDocumentView
	
	Field _path:String
		
End

Class ImageDocumentType Extends Ted2DocumentType

	Property Name:String() Override
		Return "ImageDocumentType"
	End
	
	Protected
	
	Method New()
		AddPlugin( Self )
		
		Extensions=New String[]( ".png",".jpg",".jpeg",".bmp" )
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
	
		Return New ImageDocument( path )
	End
	
	Private
	
	Global _instance:=New ImageDocumentType
	
End
