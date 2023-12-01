
#Region Public 

Function GetServiceModuleSchema(ServiceName) Export

	Response = GetServiceModule(ServiceName);  
	If mol_Internal.IsError(Response) Then
		Return Response;
	EndIf;
	
	Response = mol_SchemaBuilder.BuildServiceSchema(ServiceName, Response.Result); 
	Return Response;
	
EndFunction  

Function GetNodeServiceNames(ServiceModulePrefix) Export
	Return mol_SchemaBuilder.GetNodeServiceNames(ServiceModulePrefix);	
EndFunction

Function GetServiceNameMapping(ServiceModulePrefix = "Service") Export

	ServiceNames = GetNodeServiceNames(ServiceModulePrefix);
	Mapping = New Map();	
	
	Errors = New Array();
	
	For Each ServiceName in ServiceNames Do 
		
		Response = GetServiceModuleSchema(ServiceName);
		If mol_Internal.IsError(Response) Then
			Data = New Structure();
			Data.Insert("Name" , ServiceName);
			Data.Insert("Error", Response.Error);
			Errors.Add(Data );
			Continue;
		EndIf;
		Schema = Response.Result;
		
		Data = New Structure();
		Data.Insert("ModuleName", ServiceName);
		Data.Insert("Map"       , CreateInternalMap(Schema));
		Mapping.Insert(Schema.name, Data);
				
	EndDo;  
	
	Mapping.Insert("Errors", Errors);
	
	Return Mapping;
	
EndFunction

#EndRegion

#Region Protected


#EndRegion

#Region Private

Function GetServiceModule(Name)

	ModuleMetadata = Metadata.CommonModules.Find(Name);
	If ModuleMetadata = Undefined Then                                  
		Data = New Structure();
		Data.Insert("moduleName", Name);
		Return mol_Internal.NewResponse(
			mol_Errors.ServiceSchemaError("Service module not found", Data)
		);
	EndIf;
	If ModuleMetadata.Server = False Then  
		Data = New Structure();
		Data.Insert("moduleName", Name);
		Data.Insert("reason"    , """Server"" flag is disabled in module");
		Return mol_Internal.NewResponse(
			mol_Errors.ServiceSchemaError("Service module is unavailable", Data)
		);	
	EndIf; 
	
	SetSafeMode(True);
	Module = Eval(ModuleMetadata.Name);
	SetSafeMode(False);
	
	Return mol_Internal.NewResponse(Undefined, Module);
	
EndFunction

Function CreateInternalMap(Schema)
	
	InternalMap = New Map();
	
	If ValueIsFilled(Schema.Created) Then
		InsertMapElement(InternalMap, "lifecycle", Schema.Created, LifecycleDescription(Schema, Schema.Created));
	EndIf;
	
	If ValueIsFilled(Schema.Started) Then
		InsertMapElement(InternalMap, "lifecycle", Schema.Started, LifecycleDescription(Schema, Schema.Started));
	EndIf;
	
	If ValueIsFilled(Schema.Stopped) Then
		InsertMapElement(InternalMap, "lifecycle", Schema.Stopped, LifecycleDescription(Schema, Schema.Stopped));
	EndIf;
	
	For Each Element In Schema.Actions Do		
		InsertMapElement(InternalMap, "action", Element.Name, Element);
	EndDo; 
	
	For Each Element In Schema.Events Do		
		InsertMapElement(InternalMap, "event", Element.Name, Element);
	EndDo;
	
	Return InternalMap;
	
EndFunction

Function LifecycleDescription(Schema, ActionName)

	Result = New Structure();
	Result.Insert("handler"  , ActionName);
	Result.Insert("procedure", True);
	
	Return Result;
	
EndFunction

Procedure InsertMapElement(Map, Prefix, Name, Element)
	ElementKey = StrTemplate("%1_%2", Prefix, Name);
	Map.Insert(ElementKey, Element);	
EndProcedure

#EndRegion