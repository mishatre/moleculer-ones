
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	LoadInternalServices();	
	
EndProcedure

&AtServer
Procedure LoadInternalServices()
	
	InternalServices.Clear();
	
	Namespace = Constants.mol_NodeNamespace.Get();
	ModuleNames = mol_Internal.GetServiceModuleNames(, True);	
	
	For Each ModuleName In ModuleNames Do
		
		NewRow = InternalServices.Add();  
		NewRow.Module = ModuleName;
		
		Response = mol_Internal.CompileServiceSchema(ModuleName);
		If mol_Internal.IsError(Response) Then
			NewRow.Name = "Error";
			Continue;                     		
		EndIf;       
		Schema = Response.Result;
		
		NewRow.Name    = Namespace + "." + Schema.Name;
		NewRow.Version = Schema.Version;
		
		Description = Schema.Metadata.Get("$description");
		If Description <> Undefined Then
			NewRow.Description = Description;
		EndIf;
		
		NewRow.Actions = Schema.Actions.Count();
		NewRow.Events  = Schema.Events.Count();
		
		NewRow.Details = "Open details";  
		NewRow.Schema  = Schema;
		
	EndDo; 
	
	If mol_Internal.NodeRegistered().Result Then
		LoadServiceRegistration();	
	EndIf;
	
	
EndProcedure                      

Procedure LoadServiceRegistration()
	
	Response = mol_Internal.GetPublishedNodeServices();
	If mol_Internal.IsError(Response) Then
		// Could not load registered services
		Return;
	EndIf;                                   
	
	RegisteredServices = Response.Result;
	For Each Service In RegisteredServices Do
		
		Filter = New Structure();
		Filter.Insert("Name", Service.Name);
		FoundRows = InternalServices.FindRows(Filter);
		If FoundRows.Count() <> 0 Then
			FoundRows[0].Published = True;
		EndIf;
		
	EndDo;
	
	
EndProcedure  


&AtClient
Procedure InternalServicesSelection(Item, SelectedRow, Field, StandardProcessing)
	If Field.Name = "InternalServicesDetails" Then
		StandardProcessing = False;
		Params = New Structure();                           
		Params.Insert("ServiceModule", InternalServices[SelectedRow].Module);
		Params.Insert("ServiceSchema", InternalServices[SelectedRow].Schema);
			
		OpenForm(
			"DataProcessor.mol_AdminPanel.Form.ServiceInfo", 
			Params, 
			Item,
		);
	EndIf;
EndProcedure

