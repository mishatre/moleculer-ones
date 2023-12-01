
#Region Public

Function Debug(Message, Data = Undefined) Export
	
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

Function Warn(Message, Data = Undefined) Export
	
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