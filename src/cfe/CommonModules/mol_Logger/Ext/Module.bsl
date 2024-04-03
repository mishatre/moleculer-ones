
#Region Public

Procedure Debug(EventName, Message, Data = Undefined, Meta = Undefined) Export
	
	WriteLogEventSystem(
		EventName,
		"debug",
		Meta,
		Data,
		Message
	);
	
EndProcedure

Procedure Error(EventName, Message, Data = Undefined, Meta = Undefined) Export 
		
	WriteLogEventSystem(
		EventName,
		"error",
		Meta,
		Data,
		Message
	);
	
EndProcedure

Procedure Warn(EventName, Message, Data = Undefined, Meta = Undefined) Export 
		
	WriteLogEventSystem(
		EventName,
		"warn",
		Meta,
		Data,
		Message
	);
	
EndProcedure      

Procedure Info(EventName, Message, Data = Undefined, Meta = Undefined) Export 
	
	WriteLogEventSystem(
		EventName,
		"info",
		Meta,
		Data,
		Message
	);
	
EndProcedure  


#EndRegion   

#Region Private

Procedure WriteLogEventSystem(EventName, LogLevel, Meta = Undefined, Val Data, Message)

	#If MobileAppServer Then
		Return;
	#EndIf
	
	Level = GetLogLevel(LogLevel);
	
	//If Lower(Level) = "debug" And Not ОбщегоНазначения.РежимОтладки() Then
	//	Return;
	//EndIf;  
	
	If TypeOf(Data) = Type("Structure") Or TypeOf(Data) = Type("Map") Then
		Data = mol_InternalHelpers.ToJSONString(Data, True);
	EndIf;

	WriteLogEvent(
		EventName,
		Level,
		Meta,
		Data,
		Message
	);
	
EndProcedure      

Function GetLogLevel(Val Level) 
	
    Level = Lower(Level);
	
	If Level = "debug" Then
		Return EventLogLevel.Note;
	ElsIf Level = "error" Then
		Return EventLogLevel.Error;
	ElsIf Level = "warn" Then
		Return EventLogLevel.Warning;	
	EndIf;
	
	Return EventLogLevel.Information;
	
EndFunction 

#EndRegion