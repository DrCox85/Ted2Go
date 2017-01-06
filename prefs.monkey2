
Namespace ted2go


Class Prefs
	
	' AutoCompletion
	Global AcEnabled:=True
	Global AcKeywordsOnly:=False
	Global AcShowAfter:=2
	Global AcUseTab:=True
	Global AcUseEnter:=False
	Global AcNewLineByEnter:=True
	
	'
	Global MainToolBarVisible:=True
	Global EditorToolBarVisible:=True
	Global EditorGutterVisible:=True
	
	Function LoadState( json:JsonObject )
		
		If json.Contains( "completion" )
		
			Local j2:=json["completion"].ToObject()
			AcEnabled=j2["enabled"].ToBool()
			AcKeywordsOnly=j2["keywordsOnly"].ToBool()
			AcShowAfter=j2["showAfter"].ToNumber()
			AcUseTab=j2["useTab"].ToBool()
			AcUseEnter=j2["useEnter"].ToBool()
			AcNewLineByEnter=j2["newLineByEnter"].ToBool()
			
		Endif
		
		If json.Contains( "mainToolBarVisible" )
		
			MainToolBarVisible=json["mainToolBarVisible"].ToBool()
		
		Endif
		
		If json.Contains( "editor" )
		
			Local j2:=json["editor"].ToObject()
			EditorToolBarVisible=j2["toolBarVisible"].ToBool()
			EditorGutterVisible=j2["gutterVisible"].ToBool()
			
		Endif
	End
	
	Function SaveState( json:JsonObject )
		
		Local j:=New JsonObject
		j["enabled"]=New JsonBool( AcEnabled )
		j["keywordsOnly"]=New JsonBool( AcKeywordsOnly )
		j["showAfter"]=New JsonNumber( AcShowAfter )
		j["useTab"]=New JsonBool( AcUseTab )
		j["useEnter"]=New JsonBool( AcUseEnter )
		j["newLineByEnter"]=New JsonBool( AcNewLineByEnter )
		json["completion"]=j
		
		json["mainToolBarVisible"]=New JsonBool( MainToolBarVisible )
		
		j=New JsonObject
		j["toolBarVisible"]=New JsonBool( EditorToolBarVisible )
		j["gutterVisible"]=New JsonBool( EditorGutterVisible )
		json["editor"]=j
		
	End
	
End