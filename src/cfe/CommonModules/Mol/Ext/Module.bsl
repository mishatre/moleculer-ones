
#Region Public 

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
	
	ActionName = mol_InternalHelpers.UriResourceEscape(ActionName);
	
	Parameters = New Structure();
	Parameters.Insert("Method", "POST");
	Parameters.Insert("Path"  , StrTemplate("/call/%1", ActionName));
		
	mol_Logger.Debug(
		"Call action",
		New Structure("action", ActionName)
	);
	
	Return mol_Internal.ExecuteSidecarAction(Parameters, WrapActionPayload(Params, Opts));
	
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

	If Not mol_InternalHelpers.IsArray(Def) Then
		Return mol_Internal.NewResponse(
			mol_Errors.ServiceError("INVALID_PARAMETERS", 500, "Invalid calling definition.")
		);
	EndIf;
	
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;    
	
	Parameters = New Structure();
	Parameters.Insert("Method", "POST");
	Parameters.Insert("Path"  , "/mcall");	

	mol_Logger.Debug(
		"Call multiple actions"
	);
	
	Return mol_Internal.ExecuteSidecarAction(Parameters, WrapMCallPayload(Def, Opts));
	
EndFunction

// Emit an event (grouped & balanced global event)
//
// Parameters:
//  EventName - String                             - event name
//  Data      - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
// 
Function Emit(EventName, Data = Undefined, Val Opts = Undefined) Export

	If mol_InternalHelpers.IsArray(Opts) Or mol_InternalHelpers.IsString(Opts) Then
		Opts = New Structure("groups", Opts);
	ElsIf Opts = Undefined Then
		Opts = New Structure();	
	EndIf;
	
	If Opts.Property("groups") And Not mol_InternalHelpers.IsArray(Opts) Then
		Groups = New Array();
		Groups.Add(Opts);
		Opts.Groups = Groups;
	EndIf;
	
	EventName = mol_InternalHelpers.UriResourceEscape(EventName); 
	Parameters = New Structure();
	Parameters.Insert("Method", "POST");
	Parameters.Insert("Path"  , StrTemplate("/emit/%1", EventName));
	
	mol_Logger.Debug(
		StrTemplate(
			"Emit %1 event %2.",
			EventName,         
			?(Opts.Property("Groups"), "to " + StrConcat(Opts.Groups, ", ") + " group(s)", "")
		)
	);
	
	Return mol_Internal.ExecuteSidecarAction(Parameters, WrapEventPayload(Data, Opts));
	
EndFunction 

// Broadcast an event for all local & remote services
//
// Parameters:
//  EventName - String                             - event name
//  Data      - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
//
Function Broadcast(EventName, Data = Undefined, Val Opts = Undefined) Export
	
	If mol_InternalHelpers.IsArray(Opts) Or mol_InternalHelpers.IsString(Opts) Then
		Opts = New Structure("groups", Opts);
	ElsIf Opts = Undefined Then
		Opts = New Structure();	
	EndIf;
	
	If Opts.Property("groups") And Not mol_InternalHelpers.IsArray(Opts) Then
		Groups = New Array();
		Groups.Add(Opts);
		Opts.Groups = Groups;
	EndIf;  
	
	EventName = mol_InternalHelpers.UriResourceEscape(EventName); 
	Parameters = New Structure();
	Parameters.Insert("Method", "POST");
	Parameters.Insert("Path"  , StrTemplate("/broadcast/%1", EventName));
	
	mol_Logger.Debug(
		StrTemplate(
			"Broadcast %1 event %2.",
			EventName,         
			?(Opts.Property("Groups"), "to " + StrConcat(Opts.Groups, ", ") + " group(s)", "")
		)
	);
	
	Return mol_Internal.ExecuteSidecarAction(Parameters, WrapEventPayload(Data, Opts));
	
EndFunction

// Broadcast an event for all local services
//
// Parameters:
//  EventName - String                             - event name
//  Data      - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
// 
Function BroadcastLocal(EventName, Data = Undefined, Val Opts = Undefined) Export

	If mol_InternalHelpers.IsArray(Opts) Or mol_InternalHelpers.IsString(Opts) Then
		Opts = New Structure("groups", Opts);
	ElsIf Opts = Undefined Then
		Opts = New Structure();	
	EndIf;
	
	If Opts.Property("groups") And Not mol_InternalHelpers.IsArray(Opts) Then
		Groups = New Array();
		Groups.Add(Opts);
		Opts.Groups = Groups;
	EndIf;
	
	EventName = mol_InternalHelpers.UriResourceEscape(EventName); 
	Parameters = New Structure();
	Parameters.Insert("Method", "POST");
	Parameters.Insert("Path"  , StrTemplate("/broadcastlocal/%1", EventName));
	
	mol_Logger.Debug(
		StrTemplate(
			"Broadcast %1 local event %2.",
			EventName,         
			?(Opts.Property("Groups"), "to " + StrConcat(Opts.Groups, ", ") + " group(s)", "")
		)
	); 
	
	Return mol_Internal.ExecuteSidecarAction(Parameters, WrapEventPayload(Data, Opts));
	
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

// Create opts object
//
// Returns:
//  Opts - Structure:
//  	* timeout          - Number, null  - Timeout of request in milliseconds.
//  	* retries          - Number, null  - Count of retry of request. 
//  	* fallbackResponse - Any, null     - Returns it, if the request has failed. 
//  	* nodeID           - String, null  - Target nodeID.   
//  	* meta             - Object {}     - Metadata of request.  
//  	* parentCtx        - Context, null - Parent Context instance.  
//  	* requestID        - String, null  - Request ID or Correlation ID.
Function NewOpts() Export

	Result = New Structure();            
	// timeout - Number, null - Timeout of request in milliseconds. 
	// If the request is timed out and you don’t define fallbackResponse, 
	// broker will throw a RequestTimeout error. To disable set 0. 
	// If it’s not defined, the requestTimeout value from broker options will be used.
	Result.Insert("timeout"         , null); 
	// retries - Number, null - Count of retry of request. If the request is timed out, 
	// broker will try to call again. To disable set 0. If it’s not defined, 
	// the retryPolicy.retries value from broker options will be used. 	
	Result.Insert("retries"         , null); 
	// fallbackResponse - Any, null - Returns it, if the request has failed.
	Result.Insert("fallbackResponse", null);     
	// nodeID - String, null - Target nodeID. If set, it will make a direct call to the specified node.
	Result.Insert("nodeID"          , null);                    
	// meta - Object {} - Metadata of request. Access it via ctx.meta in actions handlers. It will be transferred & merged at nested calls, as well.
	Result.Insert("meta"            , New Map);   
	// parentCtx - Context, null - Parent Context instance. Use it to chain the calls.
	Result.Insert("parentCtx"       , null);
	// requestID - String, null - Request ID or Correlation ID. Use it for tracing.
	Result.Insert("requestID"       , null );
	
	Return Result;

EndFunction 

Function NewMCallOpts() Export
	
	Result = NewOpts();
	Result.Insert("settled", false);
	
	Return Result;
	
EndFunction

Function NewActionDef(ActionName, Val Params = Undefined, Opts = Undefined) Export

	Result = New Structure();  
	Result.Insert("action" , ActionName);
	Result.Insert("params" , Params    );
	Result.Insert("options", Opts      );
	
	Return Result;
	
EndFunction

#EndRegion  

#Region Private

Function WrapActionPayload(Params = Undefined, Opts = Undefined)
	
	Result = New Structure();
	Result.Insert("params" , ?(Params = Undefined, New Structure, Params));
	Result.Insert("meta"   , New Structure);
	Result.Insert("options", New Structure);
		
	WrapOpts(Result, Opts);
	
	Return Result;
	
EndFunction

Function WrapMCallPayload(Def, Opts = Undefined)
		
	Result = New Structure();
	Result.Insert("def"    , Def);
	Result.Insert("meta"   , New Structure);
	Result.Insert("options", New Structure);
		
	WrapOpts(Result, Opts);	
	
	Return Result;
	
EndFunction

Function WrapEventPayload(Data = Undefined, Opts = Undefined)
		
	Result = New Structure();
	Result.Insert("def"    , Data);
	Result.Insert("meta"   , New Structure);
	Result.Insert("options", New Structure);
		
	WrapOpts(Result, Opts);	
	
	Return Result;
	
EndFunction

Function WrapOpts(Result, Opts = Undefined)

	If Opts <> Undefined Then    
		
		OptsMap = New Structure();            
		// timeout - Number, null - Timeout of request in milliseconds. 
		// If the request is timed out and you don’t define fallbackResponse, 
		// broker will throw a RequestTimeout error. To disable set 0. 
		// If it’s not defined, the requestTimeout value from broker options will be used.
		OptsMap.Insert("timeout"         , "timeout"         ); 
		// retries - Number, null - Count of retry of request. If the request is timed out, 
		// broker will try to call again. To disable set 0. If it’s not defined, 
		// the retryPolicy.retries value from broker options will be used. 	
		OptsMap.Insert("retries"         , "retries"         ); 
		// fallbackResponse - Any, null - Returns it, if the request has failed.
		OptsMap.Insert("fallbackResponse", "fallbackResponse");     
		// nodeID - String, null - Target nodeID. If set, it will make a direct call to the specified node.
		OptsMap.Insert("nodeID"          , "nodeID"          );                    
		// meta - Object {} - Metadata of request. Access it via ctx.meta in actions handlers. It will be transferred & merged at nested calls, as well.
		OptsMap.Insert("meta"            , "meta"            );   
		// parentCtx - Context, null - Parent Context instance. Use it to chain the calls.
		OptsMap.Insert("parentCtx"       , "parentCtx"       );
		// requestID - String, null - Request ID or Correlation ID. Use it for tracing.
		OptsMap.Insert("requestID"       , "requestID"       );
		
		For Each KeyValue In Opts Do 
			OptsKey = Undefined;
			OptsMap.Property(KeyValue.Key, OptsKey);
			If OptsKey = "meta" Then
				Result.Meta = KeyValue.Value;
			ElsIf OptsKey <> Undefined Then
				Result.Options.Insert(OptsKey, KeyValue.Value);
			Else
				Result.Options.Insert(KeyValue.Key, KeyValue.Value);
			EndIf;
		EndDo;
	EndIf;
	
EndFunction

#EndRegion