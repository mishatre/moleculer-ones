
#Region Public

// Provide nessesary details to build service in sidecar
// and connect it actions/events to current module functions
//
// Parameters:
//  Schema  - New service schema
//  Builder - Schema builder module
//
Procedure Service(Schema, Builder) Export
	
	Schema.Name    = "$node"; 
	
	Action = Builder.Action("list", "ListAction");
	Action.Cache   = False;
	Action.Tracing = False;
	Action.Params = New Structure();
	Action.Params.Insert("withServices", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	);
	Action.Params.Insert("onlyAvailable", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	);
	
	Action = Builder.Action("services", "ServicesAction");
	Action.Cache   = False;
	Action.Tracing = False;
	Action.Params = New Structure();
	Action.Params.Insert("onlyLocal", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	);
	Action.Params.Insert("withActions", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	); 
	Action.Params.Insert("withEvents", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	);
	Action.Params.Insert("onlyAvailable", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	);
	Action.Params.Insert("grouping", 
		New Structure("type, optional, convert, default", "boolean", True, True, True)
	);  
	
	Action = Builder.Action("actions", "ActionsAction");
	Action.Cache   = False;
	Action.Tracing = False;
	Action.Params = New Structure();
	Action.Params.Insert("onlyLocal", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	);
	Action.Params.Insert("skipInternal", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	); 
	Action.Params.Insert("withEndpoints", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	);
	Action.Params.Insert("onlyAvailable", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	);
	
	Action = Builder.Action("events", "EventsAction");
	Action.Cache   = False;
	Action.Tracing = False;
	Action.Params = New Structure();
	Action.Params.Insert("onlyLocal", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	);
	Action.Params.Insert("skipInternal", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	); 
	Action.Params.Insert("withEndpoints", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	);
	Action.Params.Insert("onlyAvailable", 
		New Structure("type, optional, convert, default", "boolean", True, True, False)
	); 
	
	Action = Builder.Action("health", "HealthAction");
	Action.Cache   = False;
	Action.Tracing = False;
	
	Action = Builder.Action("options", "OptionsAction");
	Action.Cache   = False;
	Action.Tracing = False;
	
	Action = Builder.Action("metrics", "MetricsAction");
	Action.Cache   = False;
	Action.Tracing = False; 
	
	Rules = New Array();
	Rules.Add(New Structure("type", "string"));
	Rules.Add(New Structure("type, items", "array", "string"));
	DefaultParam = New Structure("type, optional, rules", "multi", True, Rules);
	
	Action.Params = New Structure();
	Action.Params.Insert("types"   , DefaultParam);
	Action.Params.Insert("includes", DefaultParam); 
	Action.Params.Insert("excludes", DefaultParam);
	
	
	Action = Builder.Action("ping", "PingAction");
	Action.Cache   = False;
	Action.Tracing = False;
	
	
	Action = Builder.Action("registration", "RegistrationAction");
	Action.Cache   = False;
	Action.Tracing = False;
	
EndProcedure

#EndRegion

#Region Protected

#Region Actions

Function ListAction(Context) Export
	
	mol_Logger.Warn(
		"InternalService.ListAction", 
		"Called $node.list action",
		Undefined, 
		Metadata.CommonModules.mol_InternalService
	);
	Return "Hello. I am example action";
	
EndFunction 

Function ServicesAction(Context) Export
	
	mol_Logger.Warn(
		"InternalService.ServicesAction", 
		"Called $node.services action",
		Undefined, 
		Metadata.CommonModules.mol_InternalService
	);
	Return "Hello. I am example action";
	
EndFunction

Function ActionsAction(Context) Export
	
	mol_Logger.Warn(
		"InternalService.ActionsAction", 
		"Called $node.actions action",
		Undefined, 
		Metadata.CommonModules.mol_InternalService
	);
	Return "Hello. I am example action";
	
EndFunction

Function EventsAction(Context) Export
	
	mol_Logger.Warn(
		"InternalService.EventsAction", 
		"Called $node.events action",
		Undefined, 
		Metadata.CommonModules.mol_InternalService
	);
	Return "Hello. I am example action";
	
EndFunction

Function HealthAction(Context) Export
	
	mol_Logger.Warn(
		"InternalService.HealthAction", 
		"Called $node.health action",
		Undefined, 
		Metadata.CommonModules.mol_InternalService
	);
	Return "Hello. I am example action";
	
EndFunction

Function OptionsAction(Context) Export
	
	mol_Logger.Warn(
		"InternalService.OptionsAction", 
		"Called $node.options action",
		Undefined, 
		Metadata.CommonModules.mol_InternalService
	);
	Return "Hello. I am example action";
	
EndFunction

Function MetricsAction(Context) Export
	
	mol_Logger.Warn(
		"InternalService.MetricsAction", 
		"Called $node.metrics action",
		Undefined, 
		Metadata.CommonModules.mol_InternalService
	);
	Return "Hello. I am example action";
	
EndFunction    

Function PingAction(Context) Export
	Return "pong";	
EndFunction

Function RegistrationAction(Context) Export
	
	Result = New Structure();
	Result.Insert("success", True);
	
	AuthType = Constants.mol_NodeAuthorizationType.Get();     
	If AuthType = Enums.mol_AuthorizationType.UsingAccessToken Then
		UserUUID  = Constants.mol_NodeUser.Get();
		FoundUser = InfoBaseUsers.FindByUUID(UserUUID);
		Result.Insert("accessToken", mol_InternalHelpers.CreateJWTAccessKey(
			Constants.mol_NodeSecretKey.Get(),
			FoundUser.Name
		));                                                            
	EndIf;                      
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#EndRegion
