
#Region Protected

// Call an action 
//
// Parameters:
//  ActionName - String            - name of action
//  Params     - Any, Undefined    - params of action
//  Opts       - Object, Undefined - options of call  
//
// Returns - service response
//
Function Call(ActionName, Val Params = Undefined, Opts = Undefined) Export
	
	If Params = Undefined Then
		Params = New Structure;
	EndIf;
	
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;  
	
	ParentSpan = New Structure(); 
	ParentSpan.Insert("id", mol_Broker.GenerateUid());
	ParentSpan.Insert("traceID", ParentSpan.Id);
	ParentSpan.Insert("sampled", True);
	Opts.Insert("parentSpan", ParentSpan);
	
	Context = Undefined;
	If Opts.Property("Context") And Opts.Context <> Undefined Then
		Endpoint = FindNextActionEndpoint(ActionName, Opts, Opts.Context);
		If mol_Internal.IsError(Endpoint) Then
			//Return this.Promise.reject(endpoint).catch(err =>
			//	this.errorHandler(err, { actionName, params, opts })
			//);
		EndIf;	
		mol_Internal.Unwrap(Endpoint);
		
		Context = Opts.Context;
		Context.Endpoint = Endpoint;
		Context.NodeID   = Endpoint.Id;
		Context.Action   = Endpoint.Action;
		Context.Service  = Endpoint.Action.Service;
	Else              
		Broker = Eval("mol_Broker");
		Context = mol_ContextFactory.Create(Broker, Undefined, Params, Opts);
		
		Endpoint = FindNextActionEndpoint(ActionName, Opts, Context);
		If mol_Internal.IsError(Endpoint) Then
			//Return this.Promise.reject(endpoint).catch(err =>
			//	this.errorHandler(err, { actionName, params, opts })
			//);
		EndIf;  
		mol_Internal.Unwrap(Endpoint);
		
		mol_ContextFactory.SetEndpoint(Context, Endpoint);
		
	EndIf; 
	
	If Context.Endpoint.Local Then
		mol_Logger.Debug("Broker.Call",
			"Call action locally.", 
			New Structure(
				"Action, RequestID",
				Context.Action.Name,
				Context.RequestID
			),
			Metadata.CommonModules.mol_Broker
		);
	Else
		mol_Logger.Debug("Broker.Call", 
			"Call action through remote sidecar node.",
			New Structure(
				"Action, RequestID",
				Context.Action.Name,
				Context.RequestID
			),
			Metadata.CommonModules.mol_Broker
		);	
	EndIf; 
	
	Response = mol_Transit.Request(Context);
	//Response.Insert("Context", Context);
	
	Return Response;
	
EndFunction 

// Multiple action calls.
//
// Parameters:
//  Def  - Array Of Structure   - Calling definitions. See Mol.NewActionDef();
//  Opts - Structure, Undefined - Calling options for each call. See. Mol.NewMCallOpts() 
//
// @throws MoleculerServerError - If the `def` is not an `Array`.
//
// Returns:
//  any
Function MCall(Def, Opts = Undefined) Export

	//If Not mol_InternalHelpers.IsArray(Def) Then
	//	Return mol_Internal.NewResponse(
	//		mol_Errors.ServiceError("INVALID_PARAMETERS", 500, "Invalid calling definition.")
	//	);
	//EndIf;
	//
	//If Opts = Undefined Then
	//	Opts = New Structure();
	//EndIf;    
	//
	//Parameters = New Structure();
	//Parameters.Insert("Method", "POST");
	//Parameters.Insert("Path"  , "/mcall");	

	//mol_Logger.mol_Debug(
	//	"Call multiple actions"
	//);
	//
	//Return mol_Internal.ExecuteSidecarAction(Parameters, WrapMCallPayload(Def, Opts));
	//
EndFunction

// Emit an event (grouped & balanced global event)
//
// Parameters:
//  EventName - String                             - event name
//  Data      - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
// 
Function Emit(EventName, Data = Undefined, Val Opts = Undefined) Export

	//If mol_InternalHelpers.IsArray(Opts) Or mol_InternalHelpers.IsString(Opts) Then
	//	Opts = New Structure("groups", Opts);
	//ElsIf Opts = Undefined Then
	//	Opts = New Structure();	
	//EndIf;
	//
	//If Opts.Property("groups") And Not mol_InternalHelpers.IsArray(Opts) Then
	//	Groups = New Array();
	//	Groups.Add(Opts);
	//	Opts.Groups = Groups;
	//EndIf;
	//
	//EventName = mol_InternalHelpers.UriResourceEscape(EventName); 
	//Parameters = New Structure();
	//Parameters.Insert("Method", "POST");
	//Parameters.Insert("Path"  , StrTemplate("/emit/%1", EventName));
	//
	//mol_Logger.mol_Debug(
	//	StrTemplate(
	//		"Emit %1 event %2.",
	//		EventName,         
	//		?(Opts.Property("Groups"), "to " + StrConcat(Opts.Groups, ", ") + " group(s)", "")
	//	)
	//);
	//
	//Return mol_Internal.ExecuteSidecarAction(Parameters, WrapEventPayload(Data, Opts));
	
EndFunction 

// Broadcast an event for all local & remote services
//
// Parameters:
//  EventName - String                             - event name
//  Data      - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
//
Function Broadcast(EventName, Data = Undefined, Val Opts = Undefined) Export
	
	//If mol_InternalHelpers.IsArray(Opts) Or mol_InternalHelpers.IsString(Opts) Then
	//	Opts = New Structure("groups", Opts);
	//ElsIf Opts = Undefined Then
	//	Opts = New Structure();	
	//EndIf;
	//
	//If Opts.Property("groups") And Not mol_InternalHelpers.IsArray(Opts) Then
	//	Groups = New Array();
	//	Groups.Add(Opts);
	//	Opts.Groups = Groups;
	//EndIf;  
	//
	//EventName = mol_InternalHelpers.UriResourceEscape(EventName); 
	//Parameters = New Structure();
	//Parameters.Insert("Method", "POST");
	//Parameters.Insert("Path"  , StrTemplate("/broadcast/%1", EventName));
	//
	//mol_Logger.mol_Debug(
	//	StrTemplate(
	//		"Broadcast %1 event %2.",
	//		EventName,         
	//		?(Opts.Property("Groups"), "to " + StrConcat(Opts.Groups, ", ") + " group(s)", "")
	//	)
	//);
	//
	//Return mol_Internal.ExecuteSidecarAction(Parameters, WrapEventPayload(Data, Opts));
	
EndFunction

// Broadcast an event for all local services
//
// Parameters:
//  EventName - String                             - event name
//  Data      - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
// 
Function BroadcastLocal(EventName, Data = Undefined, Val Opts = Undefined) Export

	//If mol_InternalHelpers.IsArray(Opts) Or mol_InternalHelpers.IsString(Opts) Then
	//	Opts = New Structure("groups", Opts);
	//ElsIf Opts = Undefined Then
	//	Opts = New Structure();	
	//EndIf;
	//
	//If Opts.Property("groups") And Not mol_InternalHelpers.IsArray(Opts) Then
	//	Groups = New Array();
	//	Groups.Add(Opts);
	//	Opts.Groups = Groups;
	//EndIf;
	//
	//EventName = mol_InternalHelpers.UriResourceEscape(EventName); 
	//Parameters = New Structure();
	//Parameters.Insert("Method", "POST");
	//Parameters.Insert("Path"  , StrTemplate("/broadcastlocal/%1", EventName));
	//
	//mol_Logger.mol_Debug(
	//	StrTemplate(
	//		"Broadcast %1 local event %2.",
	//		EventName,         
	//		?(Opts.Property("Groups"), "to " + StrConcat(Opts.Groups, ", ") + " group(s)", "")
	//	)
	//); 
	//
	//Return mol_Internal.ExecuteSidecarAction(Parameters, WrapEventPayload(Data, Opts));
	
EndFunction

// Send ping to a node (or all nodes if nodeID is null)
// 
// Parameters:
//  NodeID  - String, Array Of String, Undefined - NodeID
//  Timeout - Number, Undefined                  - Ping timeout
//
// Returns:
//  - Structure          - PongResponse
//  - Array Of Structure - PongResponse
Function Ping(NodeID = Undefined, Timeout = Undefined) Export
	
EndFunction

Function GenerateUid() Export
	Return String(New UUID());
EndFunction

Function NodeID() Export
	Return Constants.mol_NodeId.Get();
EndFunction

#Region Serialization

Function Serialize(Value) Export
	Return mol_InternalHelpers.ToJSONString(Value);
EndFunction

Function Deserialize(Value) Export
	Return mol_InternalHelpers.FromJSONString(Value);	
EndFunction

#EndRegion 

#Region ServiceDiscovery

Function GetLocalActionEndpoint(ActionName) Export
	
	Result = mol_Internal.GetServiceSchemas();	
	
	For Each ServiceSpecification In Result.Specification Do
		For Each KeyValue In ServiceSpecification.Actions Do
			If ActionName = KeyValue.Key Then
				Action = KeyValue.Value;
				Endpoint = New Structure();                    
				Endpoint.Insert("id", NodeID());
				Action.Insert("service", ServiceSpecification);
				Endpoint.Insert("action", Action);				
				Return Endpoint;				
			EndIf;
		EndDo;
	EndDo;        
	
	Return Undefined;
	
EndFunction

Function EmitLocalServices(Context) Export 
	
	BroadcastTypes = New Array();
	BroadcastTypes.Add("broadcast");
	BroadcastTypes.Add("broadcastLocal");
	
	IsBroadcast = BroadcastTypes.Find(Context.EventType) <> Undefined;
	Sender = Context.NodeID;
	
	Result = mol_Internal.GetServiceSchemas(); 
	
	For Each Service In Result.Services Do
		For Each KeyValue In Service.Events Do 
			Event = KeyValue.Value;
			If Not mol_InternalHelpers.Match(Context.EventName, Event.Name) Then
				Continue;
			EndIf;
			If Context.EventGroups = Undefined Or 
				(TypeOf(Context.EventGroups) = Type("Array") And Context.EventGroups.Length = 0) Or
				(TypeOf(Context.EventGroups) = Type("Array") And Context.EventGroups.Find(Event.Group) <> Undefined) Then
				
				If IsBroadcast Then
					// Unimplemented
				Else 
					Try
						HandlerParts = StrSplit(Event.Handler, ".");      
						Parameters = New Array();
						Parameters.Add(Context);
						mol_Internal.ExecuteModuleProcedure(HandlerParts[0], HandlerParts[1], Parameters);
					Except           
						mol_Logger.Error("Broker.EmitLocalServices", "Error while handling event", ErrorInfo(), Metadata.CommonModules.mol_Broker);
					EndTry;	
				EndIf;
			EndIf;
		EndDo;
	EndDo;

	
EndFunction

#EndRegion 

Function GetInstanceID() Export
	Return GenerateUid();
EndFunction

Function Metadata() Export
	Return New Structure();	
EndFunction

Function CLIENT_TYPE() Export
	Return "BSL";	
EndFunction      

Function MOLECULER_VERSION() Export
	Return "0.14.32"         
EndFunction

Function MODULE_TYPE() Export
	Return "extension"         
EndFunction 

Function LANG_VERSION() Export
	Return "8.3.23.1688"         
EndFunction  

Function LANG_COMPATIBILITY_VERSION() Export
	Return "8.3.21"         
EndFunction

#EndRegion

#Region Private

Function FindNextActionEndpoint(ActionName, Opts, Context)
	
	If TypeOf(ActionName) <> Type("String") Then
		Return mol_Internal.NewResponse(Undefined, ActionName);
	Else 
		Result = New Structure();
		Result.Insert("id", Undefined);
		Result.Insert("action", New Structure());   
		Result.Action.Insert("name"   , ActionName);
		Result.Action.Insert("service", Undefined);
		Result.Insert("local", False);    
		
		Return mol_Internal.NewResponse(Undefined, Result);
		
		// Try to find local endpoint
		// Otherwise bail for remote call
	EndIf;    
		
	Return mol_Internal.NewResponse(Undefined);
	
EndFunction



#EndRegion