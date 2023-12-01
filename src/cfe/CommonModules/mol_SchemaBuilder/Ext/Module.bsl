
#Region Public 

// Create new action definition
//
// Parameters:
//  Schema  - Structure - New schema of service module
//  Handler - String    - Function name in service module that will be executed on action call
//
// Returns:
//  NewAction - Structure - See. NewActionSchema()
Function NewAction(Schema, Handler) Export

	NewAction = NewActionSchema();
	NewAction.Handler = Handler; 
	
	Schema.Actions.Add(NewAction);
	
	Return NewAction;
	
EndFunction

// Create new event definition
//
// Parameters:
//  Schema  - Structure - New schema of service module
//  Handler - String    - Function name in service module that will be executed on event call
//
// Returns:
//  NewEvent - Structure - See. NewEventSchema()
Function NewEvent(Schema, Handler) Export

	NewEvent = NewEventSchema();
	NewEvent.Handler = Handler; 
	
	Schema.Events.Add(NewEvent);
	
	Return NewEvent;
	
EndFunction

Function GetServiceModuleSchema(ServiceName) Export
	Return mol_SchemaBuilderReuse.GetServiceModuleSchema(ServiceName);		
EndFunction

Function GetServiceModuleNames(ServiceModulePrefix = "Service") Export
	Return mol_SchemaBuilderReuse.GetNodeServiceNames(ServiceModulePrefix);	
EndFunction

#EndRegion

#Region Protected

// Build service module schema by calling "Service" function inside service module
//
// Parameters:
//  ModuleName - String - Module name
//  Module     - CommonModule.mol_SchemaBuilder - Reference to current module to assist with schema creation
// 
// Returns:
//  Structure: See. mol_Internal.NewResponse()
//  	* Result - Structure, Undefined - New service schema
//  	* Error  - Structure, Undefined - Schema create error
//
Function BuildServiceSchema(ModuleName, Module) Export

	Schema = NewSchema();	
	BuilderModule = Eval("mol_SchemaBuilder");
	
	Try
		SetSafeMode(True);
		Module.Service(Schema, BuilderModule);	
		SetSafeMode(False);
	Except
		ErrorInfo = ErrorInfo();
		Return mol_Internal.NewResponse(
			mol_Errors.ServiceSchemaError(
				"Error evaluating service schema", 
				ErrorProcessing.DetailErrorDescription(ErrorInfo)
			)
		);			
	EndTry;
	
	Return mol_Internal.NewResponse(Undefined, Schema);
 	
EndFunction

Function GetNodeServiceNames(ServiceModulePrefix) Export 
		
	ServiceNames = New Array();
	
	CommonModules = Metadata.CommonModules;
	For Each ModuleMetadata In CommonModules Do
		If StrStartsWith(ModuleMetadata.Name, ServiceModulePrefix) Then
			ServiceNames.Add(ModuleMetadata.Name);		
		EndIf;
	EndDo;  
	
	// Internal service
	ServiceNames.Add("mol_InternalService");
	ServiceNames.add("mol_RegistryService");
	
	Return ServiceNames;
	
EndFunction

#EndRegion

#Region Private 

Function NewSchema()
	
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

#EndRegion