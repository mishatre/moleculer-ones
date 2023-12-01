
#Region Public

// Provide nessesary details to build service in sidecar
// and connect it actions/events to current module functions
//
// Parameters:
//  Schema  - New service schema
//  Builder - Schema builder module
//
Procedure Service(Schema, Builder) Export        

	Schema.Name = "$wms.registry";
	Schema.Metadata.Insert("$name"       , "$registry");
	Schema.Metadata.Insert("$description", "External node internal registry service");
	Schema.Metadata.Insert("$official"   , False); 
			
	Action = Builder.NewAction(Schema, "GetNodeServices");
	Action.Name        = "services";
	Action.Description = "Get available node services";
	Action.Visibility  = "protected";
	
EndProcedure

#EndRegion

#Region Protected

Function GetNodeServices(ctx) Export
	
	ServiceNames = mol_SchemaBuilder.GetNodeServiceNames("Service");
	Services = New Array();	
	
	For Each ServiceName in ServiceNames Do 
		
		Response = mol_SchemaBuilder.GetServiceModuleSchema(ServiceName);
		If IsError(Response) Then
			// Write to journal
			Continue;
		EndIf;
		Schema = Response.Result;	
		Services.Add(Schema);
		
	EndDo;
	
	Result = New Structure();
	Result.Insert("services", Services);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private


#Region Utils

Function IsError(Response)
	Return mol_Internal.IsError(Response);
EndFunction

#EndRegion

#EndRegion
