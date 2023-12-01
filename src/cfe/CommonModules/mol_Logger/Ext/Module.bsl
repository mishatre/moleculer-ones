
#Region Public

Function Debug(Message, Data = Undefined) Export
	
	WriteLogEvent(
		"Moleculer.Service",
		EventLogLevel.Information,
		Undefined,
		Data,
		Message
	);
	
EndFunction  

#EndRegion