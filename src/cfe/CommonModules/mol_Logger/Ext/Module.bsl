
#Region Public

Procedure Debug(EventName, Message, Data = Undefined, Meta = Undefined) Export
	
	WriteLogEventSystem(
		EventName,
		EventLogLevel.Note,
		Meta,
		Data,
		Message
	);
	
EndProcedure

Procedure Error(EventName, Message, Data = Undefined, Meta = Undefined) Export 
		
	WriteLogEventSystem(
		EventName,
		EventLogLevel.Error,
		Meta,
		Data,
		Message
	);
	
EndProcedure

Procedure Warn(EventName, Message, Data = Undefined, Meta = Undefined) Export 
		
	WriteLogEventSystem(
		EventName,
		EventLogLevel.Warning,
		Meta,
		Data,
		Message
	);
	
EndProcedure      

Procedure Info(EventName, Message, Data = Undefined, Meta = Undefined) Export 
	
	WriteLogEventSystem(
		EventName,
		EventLogLevel.Information,
		Meta,
		Data,
		Message
	);
	
EndProcedure  

#EndRegion

#Region Protected

Function GetLogLevel(Force = False) Export 
	
	If Not Force Then
		Return mol_Reuse.GetLogLevel();
	EndIf;
	
	Return Constants.mol_LogLevel.Get();
	
EndFunction

#EndRegion

#Region Private

Procedure WriteLogEventSystem(EventName, LogLevel, Meta = Undefined, Val Data, Message)

	#If MobileAppServer Then
		Return;
	#EndIf
	
	LoggingLevel = GetLogLevel();
	If LoggingLevel = Enums.mol_LogLevel.Error Then
		// Allow only error logs
		If LogLevel <> EventLogLevel.Error Then
			Return;
		EndIf;
	ElsIf LoggingLevel = Enums.mol_LogLevel.Warn Then
		// Allow only warn and error logs
		If LogLevel = EventLogLevel.Note Or LogLevel = EventLogLevel.Information Then
			Return;
		EndIf;	
	ElsIf LoggingLevel = Enums.mol_LogLevel.Info Then
		// Allow all except debug
		If LogLevel = EventLogLevel.Note Then
			Return;
		EndIf;
	ElsIf LoggingLevel = Enums.mol_LogLevel.Debug Then
		// Allow all logs	
	EndIf;
	
	//If LogLevel = EventLogLevel.Note And Not ОбщегоНазначения.РежимОтладки() Then
	//	Return;
	//EndIf;  
	
	If mol_Helpers.IsObject(Data) Or mol_Helpers.IsMap(Data) Then
		Data = mol_Helpers.ToJSONString(Data, True);
	EndIf;

	WriteLogEvent(
		EventName,
		LogLevel,
		Meta,
		Data,
		Message
	);
	
EndProcedure      

#EndRegion