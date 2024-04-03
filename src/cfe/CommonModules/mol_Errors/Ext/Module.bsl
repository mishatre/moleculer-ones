
Function TypeError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return ClientError("TYPE_ERROR", , Message, Data, ErrorInfo); 
EndFunction   

Function AccessKeyRequiredError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export  
	Return ClientError("ACCESS_KEY_REQUIRED", , Message, Data, ErrorInfo);
EndFunction

Function SecretKeyRequiredError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export 
	Return ClientError("SECRET_KEY_REQUIRED", , Message, Data, ErrorInfo);
EndFunction

Function ExpiresParamError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return ClientError("EXPIRES_PARAM_ERROR", , Message, Data, ErrorInfo);
EndFunction

#Region Public

Function ServiceNotFound(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return RetryableError("SERVICE_NOT_AVAILABLE", 404, Message, Data, ErrorInfo);
EndFunction

Function ServiceNotAvailable(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return RetryableError("SERVICE_NOT_AVAILABLE", 404, Message, Data, ErrorInfo);
EndFunction

Function RequestTimeout(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return ServiceError("REQUEST_TIMEOUT", 504, Message, Data, ErrorInfo);
EndFunction

Function RequestSkipped(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return NewError("REQUEST_SKIPPED", 514, "MoleculerError", Message, Data, ErrorInfo);
EndFunction

Function RequestRejected(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return ServiceError("REQUEST_REJECTED", 503, Message, Data, ErrorInfo);
EndFunction

Function QueueIsFull(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return NewError("QUEUE_FULL", 429, "MoleculerError", Message,  Data, ErrorInfo);
EndFunction

Function ValidationError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return ClientError("VALIDATION_ERROR", 422, Message, Data, ErrorInfo);
EndFunction

Function MaxCallLevel(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return NewError("MAX_CALL_LEVEL", 500, "MoleculerError", Message, Data, ErrorInfo);
EndFunction

Function ServiceSchemaError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return NewError("SERVICE_SCHEMA_ERROR", 500, "MoleculerError", Message, Data, ErrorInfo);
EndFunction

Function BrokerOptionsError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return NewError("BROKER_OPTIONS_ERROR", 500, "MoleculerError", Message, Data, ErrorInfo);
EndFunction

Function GracefulStopTimeoutError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return NewError("GRACEFUL_STOP_TIMEOUT", 500, "MoleculerError", Message, Data, ErrorInfo);
EndFunction

Function ProtocolVersionMismatchError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return NewError("PROTOCOL_VERSION_MISMATCH", 500, "MoleculerError", Message, Data, ErrorInfo);
EndFunction

Function InvalidPacketData(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return NewError("INVALID_PACKET_DATA", 500, "MoleculerError", Message, Data, ErrorInfo);
EndFunction

#EndRegion

#Region Protected

Function FromErrorInfo(ErrorInfo) Export

	If Not ValueIsFilled(ErrorInfo.ModuleName) Then
		Raise "FromErrorInfo function called outside except block. ErrorInfo is empty";
	EndIf; 
	
	Category = ErrorProcessing.ErrorCategoryForUser(ErrorInfo);
	If Category = ErrorCategory.NetworkError Then     
		
		Type = GetErrorType(ErrorInfo);		
		If Type = "REQUEST_TIMEOUT" Then
			Return RequestTimeout(
				ErrorProcessing.BriefErrorDescription(ErrorInfo),
				, // Add data  
				ErrorInfo
			);
		ElsIf Type = "CONNECTION_ERROR" Then
			Return ServiceNotAvailable(
				ErrorProcessing.BriefErrorDescription(ErrorInfo),
				, // Add data  
				ErrorInfo
			);
		EndIf;
		
	Else
		
	EndIf;
	
	Return ClientError(
		"UNKNOWN_ERROR", 
		,
		ErrorProcessing.BriefErrorDescription(ErrorInfo),
		,
		ErrorInfo
	);
	
EndFunction

Function ClientError(Type, Code = 400, Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return NewError(Type, Code, "MoleculerClientError", Message, Data, ErrorInfo);
EndFunction

Function ServiceError(Type, Code = 500, Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return NewError(Type, Code, "MoleculerServerError", Message, Data, ErrorInfo);
EndFunction

Function RetryableError(Type, Code = 500, Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return NewError(Type, Code, "MoleculerRetryableError", Message, Data, ErrorInfo);
EndFunction

#EndRegion

#Region Private
 
Function NewError(Type, Code = 500, Name = "MoleculerError", Message = "", Data = Undefined, ErrorInfo = Undefined)

	Result = New Structure();
	Result.Insert("name"   , Name     );
	Result.Insert("message", Message  );
	Result.Insert("code"   , Code     );
	Result.Insert("type"   , Type     );
	Result.Insert("data"   , Data     );
	Result.Insert("stack"  , GetErrorStack(ErrorInfo, Message));
	
	Return Result;

EndFunction

Function GetErrorType(ErrorInfo)
	
	BriefDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);	
	TextParts = StrSplit(BriefDescription, ":"); 
	ErrorMessage = TrimAll(TextParts[1]);
	
	If ErrorMessage = "Превышено время ожидания" Then
		Return "REQUEST_TIMEOUT";
	ElsIf ErrorMessage = "Не могу установить соединение" Then
		Return "CONNECTION_ERROR";
	EndIf;
	
	Return "UNKNOWN";
	
EndFunction 

Function GetErrorStack(ErrorInfo = Undefined, CustomMessage = "")
	
	SkipStackItems = 0;
	If ErrorInfo = Undefined Then
		ErrorInfo = CreateErrorInfo();
		If ErrorInfo = Undefined Then
			Return Undefined;
		EndIf;
		SkipStackItems = 5; // Remove first 5 rows as they are meaningless
	EndIf;
	                           
	DetailDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	TextParts = StrSplit(DetailDescription, Chars.LF);
	StackParts = New Array();
	
	For Each Row In TextParts Do   
		If Row = "" Then
			Break;
		EndIf;
		StackParts.Add(Row);	
	EndDo;
	
	If SkipStackItems > 0 Then
		For Index = 0 To SkipStackItems - 1 Do 
			StackParts.Delete(0);	
		EndDo; 
	EndIf;
	
	If CustomMessage <> "" Then
		StackParts.Insert(0, CustomMessage);
	EndIf;
	
	Return TrimAll(StrConcat(StackParts, Chars.LF));
	
EndFunction 

Function CreateErrorInfo()
	
	Try
		A = 1/0;
	Except
		Return ErrorInfo();
	EndTry;
	
	Return Undefined;
	
EndFunction

#EndRegion
