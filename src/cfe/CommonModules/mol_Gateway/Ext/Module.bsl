
#Region Public

Function BuildGatewayPath(NodeID) Export
	
	HTTPServiceMetadata = Metadata.HTTPServices.mol_Moleculer;
	
	RootURL     = HTTPServiceMetadata.RootURL; 
	GatewayPath = HTTPServiceMetadata.URLTemplates.Gateway.Template;
	
	Return StrTemplate(
		"%1/hs/%2%3", 
		NodeID,
		RootURL,
		GatewayPath
	);
	
EndFunction

#EndRegion

#Region Protected

Function HandleGatewayRequest(HTTPServiceRequest) Export

	ContextResult = BuildServiceContext(HTTPServiceRequest);
	If IsError(ContextResult) Then
		Return NewResultResponse(ContextResult);	
	EndIf;
	Context = ContextResult.Result;
	
	ModuleInfo = GetModuleInfo(Context);
	If ModuleInfo = Undefined Then
		Return NewResultResponse(
			mol_Internal.NewResponse(
				mol_Errors.RequestRejected("Service module not found")
			)
		);	
	EndIf;
	
	CallDescription = GetModuleCallDescription(ModuleInfo, Context); 
	If CallDescription = Undefined Then
		Return NewResultResponse(
			mol_Internal.NewResponse(
				mol_Errors.RequestRejected("Service module action not found", Context)
			)
		);	
	EndIf;
	
	ServiceCallString = BuildServiceCallString(
		ModuleInfo.ModuleName, 
		CallDescription.Handler
	);     
	
	Argument    = Context;
	Unsafe      = mol_InternalHelpers.Get(CallDescription, "Unsafe"   , False);
	IsProcedure = mol_InternalHelpers.Get(CallDescription, "Procedure", False);
	Response = ExecuteServiceCall(ServiceCallString, Argument, IsProcedure, Unsafe); 
	If IsError(Response) Then
		Return NewResultResponse(Response);
	EndIf;
	
	Return NewResultResponse(Response);
	
EndFunction

#EndRegion

#Region Private

Function GetModuleInfo(Context)
	
	If Not ValueIsFilled(Context.ServiceName) Then
		Return Undefined;
	EndIf;
	
	ModuleMappings = mol_SchemaBuilderReuse.GetServiceNameMapping("Service");
	Return ModuleMappings.Get(Context.ServiceName);
	
EndFunction

Function GetModuleCallDescription(ModuleInfo, Context)
	
	CallType = Undefined;  
	CallName = Undefined;
	If Context.Action <> Undefined And TypeOf(Context.Action) = Type("Structure") And Context.Action.Count() > 0 Then 		
		CallType = "action";
		Context.Action.Property("Name", CallName);
	ElsIf Context.EventName <> Undefined Then 
		CallType = "event";
		CallName = Context.EventName;
	ElsIf Context.Lifecycle <> Undefined And TypeOf(Context.Lifecycle) = Type("Structure") And Context.Lifecycle.Count() > 0 Then 
		CallType = "lifecycle";
		Context.Lifecycle.Property("Name", CallName);
	EndIf; 
	
	If CallType = Undefined Or CallName = Undefined Then 
		Return Undefined;	
	EndIf;
	
	ElementKey = StrTemplate("%1_%2", CallType, CallName);
	Return ModuleInfo.Map.Get(ElementKey);
	
EndFunction



Function NewServiceResponse(Context, StatusCode = 200, Result = Undefined, Error = Undefined)

	Response = New Structure();
	If Error <> Undefined Then
		Response.Insert("error", Error);
	Else
		Response.Insert("result", Result);
	EndIf;
	
	If Context <> Undefined And Context.Property("Meta") Then
		Response.Insert("meta", Context.Meta);
	EndIf;
	
	Headers = New Map();
	Headers.Insert("content-type", "application/json");
	
	HTTPServiceResponse = New HTTPServiceResponse(StatusCode, , Headers); 
	ResponseString = mol_InternalHelpers.ToString(Response);
	mol_InternalHelpers.SetHTTPBody(HTTPServiceResponse, ResponseString);
		
	Return HTTPServiceResponse;
	
EndFunction

Function NewResultResponse(ResponseStructure)
	
	StatusCode = ?(ResponseStructure.Error <> Undefined, ResponseStructure.Error.Code, 200); 
	Return NewServiceResponse(Undefined, StatusCode, ResponseStructure.Result, ResponseStructure.Error); 
	
EndFunction

Function ParseRequestPayload(HTTPServiceRequest)
	
	PayloadString = HTTPServiceRequest.GetBodyAsString();
	Try
		ParsedObject  = mol_InternalHelpers.BasicFromString(PayloadString); 
		Return mol_Internal.NewResponse(Undefined, ParsedObject);
	Except                                                           
		Data = New Structure();
		Data.Insert("body", PayloadString);
		Error = mol_Errors.RequestRejected("Malformed sidecar request body", Data);
		Return mol_Internal.NewResponse(Error);	
	EndTry;
	
EndFunction

// Create new context structure
// 
// @internal
//
// Returns:
//  Structure:
//  	* id          - String          - Context ID
//  	* broker      - ServiceBroker   - Instance of the broker.
//  	* nodeID      - String          - The caller or target Node ID.
//  	* action      - Object          - Instance of action definition.
//  	* event       - Object          - Instance of event definition.
//  	* eventName   - Object          - The emitted event name.
//  	* eventType   - String          - Type of event (“emit” or “broadcast”).
//  	* eventGroups - Array Of String - Groups of event.
//  	* caller      - String          - Service full name of the caller. E.g.: v3.myService
//  	* requestID   - String          - Request ID. If you make nested-calls, it will be the same ID.
//  	* parentID    - String          - Parent context ID (in nested-calls).
//  	* params      - Any             - Request params. Second argument from broker.call.
//  	* meta        - Any             - Request metadata. It will be also transferred to nested-calls.
//  	* locals      - Any             - Local data.
//  	* level       - Number          - Request level (in nested-calls). The first level is 1.
//  	* span        - Span            - Current active span.
Function NewContext()

    Result = New Structure();
    // String - Context ID
    Result.Insert("id"         , ""); 
    // ServiceBroker - Instance of the broker.
    Result.Insert("broker"     , Undefined); 
    // String - The caller or target Node ID.
    Result.Insert("nodeID"     , ""); 
    // Object - Instance of action definition.
    Result.Insert("action"     , Undefined); 
    // Object - Instance of event definition.
    Result.Insert("event"      , Undefined); 
    // Object - The emitted event name.
    Result.Insert("eventName"  , Undefined); 
    // String - Type of event (“emit” or “broadcast”).
    Result.Insert("eventType"  , ""); 
    // Array<String> - Groups of event.
    Result.Insert("eventGroups", New Array()); 
    // String - Service full name of the caller. E.g.: v3.myService
    Result.Insert("caller"     , ""); 
    // String - Request ID. If you make nested-calls, it will be the same ID.
    Result.Insert("requestID"  , ""); 
    // String - Parent context ID (in nested-calls).
    Result.Insert("parentID"   , ""); 
    // Any - Request params. Second argument from broker.call.
    Result.Insert("params"     , Undefined); 
    // Any - Request metadata. It will be also transferred to nested-calls.
    Result.Insert("meta"       , Undefined); 
    // Any - Local data.
    Result.Insert("locals"     , Undefined); 
    // Number - Request level (in nested-calls). The first level is 1.
    Result.Insert("level"      , 1); 
    // Span - Current active span.
    Result.Insert("span"       , Undefined); 
	
	// @internal
	// String - Name of service that take action in call.
    Result.Insert("serviceName"  , Undefined);
	// Object - Instance of lifecycle action definition.
    Result.Insert("lifecycle"  , Undefined);
	
	Return Result;

EndFunction

Function BuildServiceContext(HTTPServiceRequest)  
	
	Payload = ParseRequestPayload(HTTPServiceRequest);
	If IsError(Payload) Then Return Payload; Else Payload = Payload.Result; EndIf;
		
	Context = NewContext();
	
	Try
		PopulateContextFromPayload(Context, Payload)
	Except                                                                    
		Data = New Structure();
		Data.Insert("payload", Payload);
		Return mol_Internal.NewResponse(
			mol_Errors.RequestRejected("Malformed sidecar request payload", Data)
		);	
	EndTry;
		
	Return mol_Internal.NewResponse(Undefined, Context);
	
EndFunction

Procedure PopulateContextFromPayload(Context, Payload)
	
	Context.ServiceName     = Payload.ServiceName;
	If Payload.Property("Lifecycle") Then 
		Context.Lifecycle = Payload.Lifecycle;
		Return;
	EndIf;
	
	Context.Id              = Payload.Id;
	Context.NodeID          = Payload.NodeID;
	
	Context.EventGroups     = ?(Payload.Property("EventGroups"), Payload.EventGroups, Undefined);
	Context.EventName       = Payload.EventName;
	Context.EventType       = Payload.EventType;	
	
	Context.Caller          = Payload.Caller;
	Context.Level           = Payload.Level;
		
	Context.RequestID       = Payload.Id;
	If Payload.Property("parentId") Then
		Context.ParentID    = Payload.ParentId;	
	EndIf;
	
	Context.Params          = Payload.Params;
	
	If Payload.Property("meta") And mol_InternalHelpers.IsMap(Payload.Meta) Then
		Context.Meta = New Map();		
		For Each KeyValue In Payload.Meta Do
			Context.Meta.Insert(KeyValue.Key, KeyValue.Value);
		EndDo; 
	EndIf; 
	
	If Payload.Property("action") And mol_InternalHelpers.IsObject(Payload.Action) Then
		Context.Action = New Structure();
		For Each KeyValue In Payload.Action Do
			Context.Action.Insert(KeyValue.Key, KeyValue.Value);
		EndDo; 
	EndIf;
	
EndProcedure 

Function ExecuteServiceCall(_CallString, _Arg1, _IsProcedure = False, _Unsafe = False)

	_Result = Undefined;
	
	Try
		If Not _Unsafe Then
			SetSafeMode(True);
		EndIf;    
		If _IsProcedure Then
			Execute(_CallString);
		Else
			_Result = Eval(_CallString);
		EndIf;
		If Not _Unsafe Then
			SetSafeMode(False);     
		EndIf;                      
	Except	
		ErrorInfo = ErrorInfo();
		Return mol_Internal.NewResponse(
			mol_Errors.RequestRejected(
				"Error executing service call", 
				ErrorProcessing.DetailErrorDescription(ErrorInfo)
			)
		);		
	EndTry;
	
	Return mol_Internal.NewResponse(Undefined, _Result);
	
EndFunction

#Region Utils

Function BuildServiceCallString(ServiceName, MethodName)
	Return StrTemplate("%1.%2(%3)", ServiceName, MethodName, "_arg1");	
EndFunction

Function IsError(Response)
	
	If Response.Error <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#EndRegion