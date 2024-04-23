
#Region Public

// Provide nessesary details to build service in sidecar
// and connect it actions/events to current module functions
//
// Parameters:
//  Schema  - New service schema
//  Builder - Schema builder module
//
Procedure Service(Schema, Builder) Export
	
	Schema.Name    = "example";
	Schema.Version = 1;
	
	Builder.OnStarted();
	Builder.OnStopped();
	
	Builder.Meta("$name"       , "example-service");
	Builder.Meta("$description", "External node example service");
	Builder.Meta("$official"   , False);

	Action = Builder.Action("example-action", "ExampleAction");
	Action.Description = "This is example action";
	
	Event = Builder.Event("example-event", "ExampleEvent");
	Event.Description = "This is example event";   
	
	Builder.Channel("example-channel", "ExampleChannel");	
	
EndProcedure

// Executes every time service get registered in sidecar
//
// Parameters:
//  Context - Service context
//
Procedure Started(Context) Export
	
	//WriteLogEvent(
	//	"Moleculer.Service.Started",
	//	EventLogLevel.Note,
	//	Undefined,
	//	New Structure(
	//		"Name",
	//		"example"
	//	)
	//);
	
EndProcedure

// Executes every time service get unregistered in sidecar
//
// Parameters:
//  Context - Service context
//
Procedure Stopped(Context) Export
	
	//WriteLogEvent(
	//	"Moleculer.Service.Stopped",
	//	EventLogLevel.Note,
	//	Undefined,
	//	New Structure(
	//		"Name",
	//		"example"
	//	)
	//);
	
EndProcedure

#EndRegion

#Region Protected

#Region Actions

// Example action
Function ExampleAction(Context) Export
	
	mol_Logger.Warn("ExampleAction", "Called example.action action");
	Return "Hello. I am example action";
	
EndFunction

#EndRegion

#Region Events

Procedure ExampleEvent(Context) Export
	
	mol_Logger.Warn("ExampleAction", ">> Received example-event event", Undefined, Metadata.CommonModules.ServiceExample);
	
	
EndProcedure

#EndRegion 

#Region Channels

Procedure ExampleChannel(Context, Raw) Export

	mol_Logger.Warn("ExampleChannel", ">> Received example-channel channel event", Undefined, Metadata.CommonModules.ServiceExample);		         
	
EndProcedure	
	
#EndRegion

#EndRegion

#Region Private

#EndRegion
