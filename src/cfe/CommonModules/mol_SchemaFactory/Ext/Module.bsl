
#Region Public 

#Region ServiceBuilderOptions

Function OnStarted(Handler = "Started") Export
	
	CurrentContext = GetCurrentContext();	
	CurrentContext.Schema.Started = NewHandler(CurrentContext, Handler);	
	
EndFunction

Function OnStopped(Handler = "Stopped") Export
	
	CurrentContext = GetCurrentContext();	
	CurrentContext.Schema.Stopped = NewHandler(CurrentContext, Handler);	
	
EndFunction

Function Meta(Name, Value) Export
	
	CurrentContext = GetCurrentContext();	
	CurrentContext.Schema.Metadata.Insert(Name, Value);
	
EndFunction

// Create new action definition
//
// Parameters:
//  Schema  - Structure - New schema of service module
//  Handler - String    - Function name in service module that will be executed on action call
//
// Returns:
//  NewAction - Structure - See. NewActionSchema()
Function Action(Name, Handler) Export
	
	CurrentContext = GetCurrentContext();	
	
	NewElement = mol_Helpers.NewActionSchema();
	NewElement.Name    = Name;
	NewElement.Handler = NewHandler(CurrentContext, Handler); 
	
	CurrentContext.Schema.Actions.Insert(Name, NewElement);
	
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
Function Event(Name, Handler) Export
	
	CurrentContext = GetCurrentContext();	
	
	NewElement = mol_Helpers.NewEventSchema();
	NewElement.Name    = Name;
	NewElement.Handler = NewHandler(CurrentContext, Handler); 
	
	CurrentContext.Schema.Events.Insert(Name, NewElement);
	
	Return NewElement;
	
EndFunction

// Create new channel definition
//
// Parameters:
//  Schema  - Structure - New schema of service module
//  Handler - String    - Function name in service module that will be executed on event call
//
// Returns:
//  NewEvent - Structure - See. NewEventSchema()
Function Channel(Name, Handler) Export
	
	CurrentContext = GetCurrentContext();	
	
	NewElement = mol_Helpers.NewEventSchema();
	NewElement.Name    = Name;
	NewElement.Handler = NewHandler(CurrentContext, Handler); 
	
	CurrentContext.Schema.Channels.Insert(Name, NewElement);
	
	Return NewElement;
	
EndFunction


#EndRegion

#Region Parameters

Function TypeString(Optional = False) Export

	Result = New Structure();
	Result.Insert("type"    , "string");
	Result.Insert("optional", Optional);
	
	Return Result;
	
EndFunction

Function TypeBoolean(Default = False, Optional = True, Convert = True) Export

	Result = New Structure();
	Result.Insert("type"    , "boolean");
	Result.Insert("optional", Optional);
	Result.Insert("convert" , Convert);
	Result.Insert("default" , Default);
	
	Return Result;
	
EndFunction

Function TypeArray(Items, Optional = False) Export

	Result = New Structure();
	Result.Insert("type"    , "array"); 
	Result.Insert("items"   , Items);
	Result.Insert("optional", Optional);
	
	Return Result;
	
EndFunction

Function TypeMulti(Rules, Optional = True) Export

	Result = New Structure();
	Result.Insert("type"    , "multi");
	Result.Insert("rules"   , Rules);
	Result.Insert("optional", Optional);
	
	Return Result;
	
EndFunction


#EndRegion

#EndRegion

#Region Protected

Function GetVersionedFullName(Name, Version = Undefined) Export
	If Version = Undefined Then
		Return Name;
	EndIf;
	Return StrTemplate("%1.%2",
		?(mol_Helpers.IsNumber(Version), "v" + Format(Version, "NG="), Version),
		Name
	);
EndFunction

Function CompileServiceSchema(ModuleName, Namespace = "") Export 
	
	NewSchema = mol_Helpers.NewSchema();
	
	CurrentContext = mol_ReuseCalls.GetServiceSchemaContext();
	CurrentContext.Schema     = NewSchema; 
	CurrentContext.ModuleName = ModuleName;
	CurrentContext.Namespace  = Namespace;
	
	Parameters = New Array();
	Parameters.Add(CurrentContext.Schema);
	Parameters.Add(mol_SchemaFactory);
	
	Response = mol_Helpers.NewResponse();
	
	MainProcedureName = "Service"; 
	Try                            
		SetSafeMode(True);
		mol_Helpers.ExecuteModuleProcedure(ModuleName, MainProcedureName, Parameters);
		Schema = Parameters[0];
		
		If Not StrStartsWith(Schema.Name, "$") Then
			Schema.Name = StrTemplate("%1.%2", Namespace, Schema.Name);
		EndIf;          
		
		If Schema.Settings.Get("$noVersionPrefix") <> True Then
			Schema.FullName = GetVersionedFullName(
				Schema.Name,
				Schema.Version
			);         
		Else
			Schema.FullName = Schema.Name;
		EndIf;  
		
		Schema.Metadata.Insert("$sidecarNodeID", mol_Broker.NodeID());
		
		Response.Result = Schema
	Except                                                 
		ErrorInfo = ErrorInfo();
		ErrorMessage = StrTemplate("Couldn't compile service schema in module %1", ModuleName); 
		Response.Error = mol_Errors.ServiceSchemaError(ErrorMessage, Undefined, ErrorInfo);	
	EndTry; 
	
	CurrentContext.Schema     = Undefined;
	CurrentContext.ModuleName = Undefined;
	CurrentContext.Namespace  = Undefined;
	
	Return Response;
	
EndFunction

#EndRegion

#Region Private 

#Region Context

Function GetCurrentContext()  
	
	CurrentContext = mol_ReuseCalls.GetServiceSchemaContext();
	If CurrentContext.Schema = Undefined Then
		Raise "Call without current context";
	EndIf;	
	
	Return CurrentContext;
	
EndFunction

#EndRegion

Function NewHandler(CurrentContext, Handler)
	Return StrTemplate("%1.%2", CurrentContext.ModuleName, Handler);	
EndFunction

#EndRegion