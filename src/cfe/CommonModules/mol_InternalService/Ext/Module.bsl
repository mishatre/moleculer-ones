
#Region Public

// Provide nessesary details to build service in sidecar
// and connect it actions/events to current module functions
//
// Parameters:
//  Schema  - New service schema
//  Builder - Schema builder module
//
Function Service(Schema, Builder) Export

	Schema.Name = "wms.internal";
	Schema.Metadata.Insert("$name"       , "internal");
	Schema.Metadata.Insert("$description", "External node internal serivce");
	Schema.Metadata.Insert("$official"   , False);
	
	Action = Builder.NewAction(Schema, "Node_List");
	Action.Name        = "list";
	Action.Description = "Lists all known nodes";
	Action.Visibility  = "public";
	
	Action = Builder.NewAction(Schema, "Services");
	Action.Name        = "services";
	Action.Description = "Lists all registered services";
	Action.Visibility  = "public";
	
	Action = Builder.NewAction(Schema, "Node_Actions");
	Action.Name        = "actions";
	Action.Description = "Lists all registered actions";
	Action.Visibility  = "public";
	
	Action = Builder.NewAction(Schema, "Node_Events");
	Action.Name        = "events";
	Action.Description = "Lists all event subscriptions";
	Action.Visibility  = "public";
	
	Action = Builder.NewAction(Schema, "Node_Metrics");
	Action.Name        = "metrics";
	Action.Description = "Lists all metrics";	     
	Action.Visibility  = "public";
	
	Action = Builder.NewAction(Schema, "Node_Health");
	Action.Name        = "health";
	Action.Description = "Node health info";   
	Action.Visibility  = "public";
	
EndFunction

#EndRegion

#Region Protected

// Lists all known nodes
//
// @internal
//
// Parameters:
//  ctx - Structure - Service context
//
// Returns:
//  Structure - Service response
//
Function Node_List(ctx) Export
	
EndFunction

Function Services(Context) Export

	//Context	
	
EndFunction 

// Lists all registered actions
//
// @internal
//
// Parameters:
//  ctx - Structure - Service context
//
// Returns:
//  Structure - Service response
//
Function Node_Actions(ctx) Export

	
	
EndFunction   

Function Node_Events() Export
	
EndFunction   

Function Node_Metrics() Export
	
EndFunction 

Function Node_Health() Export
	
EndFunction

#EndRegion

#Region Private



#EndRegion
