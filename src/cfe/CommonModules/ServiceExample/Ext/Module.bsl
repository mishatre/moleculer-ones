
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

	Schema.Started = "Started";
	Schema.Stopped = "Stopped";
	
	Schema.Metadata.Insert("$name"       , "example-service");
	Schema.Metadata.Insert("$description", "External node example service");
	Schema.Metadata.Insert("$official"   , False);

	Action = Builder.NewAction(Schema, "ExampleAction");
	Action.Name        = "example-action";
	Action.Description = "This is example action";
	//Action.Cache       = True;
	
	Event = Builder.NewEvent(Schema, "ExampleEvent");
	Event.Name        = "example-event";
	Event.Description = "This is example event";
	
EndProcedure

// Executes every time service get registered in sidecar
//
// Parameters:
//  Context - Service context
//
Procedure Started(Context) Export	
	
	WriteLogEvent(
		"Moleculer.Service.Started",
		EventLogLevel.Note,
		Undefined,
		New Structure(
			"Name",
			"example"
		)
	);
	
EndProcedure

// Executes every time service get unregistered in sidecar
//
// Parameters:
//  Context - Service context
//
Procedure Stopped(Context) Export	
	
	WriteLogEvent(
		"Moleculer.Service.Stopped",
		EventLogLevel.Note,
		Undefined,
		New Structure(
			"Name",
			"example"
		)
	);
	
EndProcedure

#EndRegion

#Region Protected

#Region Actions

// Example action
Function ExampleAction(Context) Export

	Return "Hello. I am example action";
	
EndFunction

#EndRegion

#Region Events


Function ExampleEvent(Context) Export
	
	WriteLogEvent(
		"Moleculer.Service.Event",
		EventLogLevel.Note,
		Undefined,
		New Structure(
			"Name, EventName",
			"example",
			"example-event"
		)
	);
	
EndFunction

#EndRegion

#EndRegion

#Region Private



#EndRegion
