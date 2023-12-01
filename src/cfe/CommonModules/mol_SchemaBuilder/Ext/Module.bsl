
#Region Public 

#Region ServiceBuilderOptions

Function OnStarted(Schema, Handler = "Started") Export
	
	Schema.Started = NewHandler(Schema, Handler);	
	
EndFunction

Function OnStopped(Schema, Handler = "Stopped") Export

	Schema.Stopped = NewHandler(Schema, Handler);	
	
EndFunction

Function Meta(Schema, Name, Value) Export

	Schema.Metadata.Insert(Name, Value);
	
EndFunction

// Create new action definition
//
// Parameters:
//  Schema  - Structure - New schema of service module
//  Handler - String    - Function name in service module that will be executed on action call
//
// Returns:
//  NewAction - Structure - See. NewActionSchema()
Function Action(Schema, Handler) Export

	NewElement = NewActionSchema();
	NewElement.Handler = NewHandler(Schema, Handler); 
	
	Schema.Actions.Add(NewElement);
	
	Return NewElement;
	
EndFunction

// Create new event definition
//
// Parameters:
//  Schema  - Structure - New schema of service module
//  Handler - String    - Function name in service module that will be executed on event call
//
// Returns:
//  NewEvent - Structure - See. NewEventSchema()
Function Event(Schema, Handler) Export

	NewElement = NewEventSchema();
	NewElement.Handler = NewHandler(Schema, Handler); 
	
	Schema.Events.Add(NewElement);
	
	Return NewElement;
	
EndFunction

#EndRegion

#EndRegion

#Region Protected

#EndRegion

#Region Private 

Function NewSchema(ModuleName = "") Export
	
	// Map is used to allow internal settings ($noVersionPrefix)

	Result = New Structure;
	Result.Insert("name"         , ""       );
	Result.Insert("version"      , Undefined);
	Result.Insert("settings"     , New Map  );
	Result.Insert("dependencies" , New Array);
	Result.Insert("metadata"     , New Map  );
	Result.Insert("actions"      , New Array);
	Result.Insert("methods"      , New Array);
	Result.Insert("hooks"        , New Array); 
	
	Result.Insert("events"       , New Array);     
	Result.Insert("created"      , Undefined);
	Result.Insert("started"      , Undefined);
	Result.Insert("stopped"      , Undefined);

	Result.Insert("channels"     , New Array); 
	
	Result.Insert("_ModuleName"  , ModuleName);
	
	Return Result;
	
EndFunction

Function NewActionSchema()
	
	Result = New Structure();
	Result.Insert("name"          , ""       ); // name?: string;
	Result.Insert("rest"          , Undefined); // rest?: RestSchema | RestSchema[] | string | string[]; 
	// Visibility property to control the visibility & callability of service actions.
	// - published, null - public action. It can be called locally, remotely and can be published via API Gateway
	// - public          - public action, can be called locally & remotely but not published via API GW
	// - protected       - can be called only locally (from local services)
	// - private         - can be called only internally (via this.actions.xy() inside service)
	Result.Insert("visibility"    , Undefined); // visibility?: "published" | "public" | "protected" | "private";
	Result.Insert("params"        , Undefined); // params?: ActionParams;
	Result.Insert("cache"         , Undefined); // cache?: boolean | ActionCacheOptions;
	Result.Insert("handler"       , ""       );      
	Result.Insert("tracing"       , Undefined); // boolean | TracingActionOptions;
	Result.Insert("bulkhead"      , Undefined); // bulkhead?: BulkheadOptions;
	Result.Insert("circuitBreaker", Undefined); // circuitBreaker?: BrokerCircuitBreakerOptions;
	Result.Insert("retryPolicy"   , Undefined); // retryPolicy?: RetryPolicyOptions;
	Result.Insert("fallback"      , Undefined); // fallback?: string | FallbackHandler;
	Result.Insert("hooks"         , Undefined); // hooks?: ActionHooks;
	Result.Insert("version"       , Undefined);
	
	Result.Insert("description"   , ""       );
	
	Return Result;
	
EndFunction
 
Function NewEventSchema()

	Result = New Structure();
	Result.Insert("name"       , ""       ); // name?: string;
	Result.Insert("group"      , Undefined); // group?: string;
	Result.Insert("params"     , Undefined); // params?: ActionParams;
	Result.Insert("tracing"    , Undefined); // tracing?: boolean | TracingEventOptions;
	Result.Insert("bulkhead"   , Undefined); // bulkhead?: BulkheadOptions;
	Result.Insert("handler"    , ""       );
	Result.Insert("context"    , True     ); // context?: boolean;
		
	Result.Insert("description", ""       );

	Return Result;
	
EndFunction

Function NewRestSchema()
	
	Result = New Structure();
	Result.Insert("path"    , Undefined); // path?: string;
	Result.Insert("method"  , Undefined); // method?: "GET" | "POST" | "DELETE" | "PUT" | "PATCH";
	Result.Insert("fullPath", Undefined); // fullPath?: string;
	Result.Insert("basePath", Undefined); // basePath?: string;
	
	Return Result;
	
EndFunction

Function NewHandler(Schema, Handler)
	Return StrTemplate("%1.%2", Schema._ModuleName, Handler);	
EndFunction

#EndRegion