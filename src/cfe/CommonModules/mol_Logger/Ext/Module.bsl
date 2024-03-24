
#Region Public

Function mol_Debug(Message, Data = Undefined) Export
	
	#If Not MobileAppServer Then
	WriteLogEvent(
		"Moleculer.Service",
		EventLogLevel.Information,
		Undefined,
		Data,
		Message
	);                          
	#EndIf
	
EndFunction 

Function mol_Warn(Message, Data = Undefined) Export
	
	#If Not MobileAppServer Then
	WriteLogEvent(
		"Moleculer.Service",
		EventLogLevel.Warning,
		Undefined,
		Data,
		Message
	);                          
	#EndIf
	
EndFunction

#EndRegion