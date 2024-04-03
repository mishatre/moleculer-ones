
#Region Public 

#Region Main

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
	Return mol_Broker.Call(ActionName, Params, Opts);	
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
   	Return mol_Broker.MCall(Def, Opts);	
EndFunction

// Emit an event (grouped & balanced global event)
//
// Parameters:
//  EventName - String                             - event name
//  Data      - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
// 
Function Emit(EventName, Data = Undefined, Val Opts = Undefined) Export
    Return mol_Broker.Emit(EventName, Data, Opts);	
EndFunction 

// Broadcast an event for all local & remote services
//
// Parameters:
//  EventName - String                             - event name
//  Data      - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
//
Function Broadcast(EventName, Data = Undefined, Val Opts = Undefined) Export
	Return mol_Broker.Broadcast(EventName, Data, Opts);	
EndFunction

// Broadcast an event for all local services
//
// Parameters:
//  EventName - String                             - event name
//  Data      - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
// 
Function BroadcastLocal(EventName, Data = Undefined, Val Opts = Undefined) Export
   	Return mol_Broker.BroadcastLocal(EventName, Data, Opts);	
EndFunction

#EndRegion

Function Broker() Export
	Return Eval("mol_Broker");
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