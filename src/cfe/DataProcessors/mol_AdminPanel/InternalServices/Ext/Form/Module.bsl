
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	LoadInternalServices();	
	
EndProcedure

&AtServer
Procedure LoadInternalServices()
	
	InternalServices.Clear(); 
	Result = mol_Internal.GetServiceSchemas(True);
		
	For Each ServiceInfo In Result.Specification Do
		
		NewRow = InternalServices.Add();  
		NewRow.Module = ServiceInfo.Module;
				
		NewRow.Name    = ServiceInfo.Name;
		NewRow.Version = ServiceInfo.Version;
		
		Description = ServiceInfo.Metadata.Get("$description");
		If Description <> Undefined Then
			NewRow.Description = Description;
		EndIf;
		
		NewRow.Actions = ServiceInfo.Actions.Count();
		NewRow.Events  = ServiceInfo.Events.Count();
		
		NewRow.ServiceInfo  = ServiceInfo;
		
	EndDo; 
	
	LoadServiceRegistration();
	
	
EndProcedure                      

Procedure LoadServiceRegistration()
	
	Response = mol_Internal.GetServicesList();
	If mol_Internal.IsError(Response) Then
		// Could not load registered services
		Return;
	EndIf;                                   
	
	For Each Service In Response Do
		
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
	StandardProcessing = False;
	Params = New Structure();                           
	Params.Insert("ServiceInfo", InternalServices[SelectedRow].ServiceInfo);	
	OpenForm(
		"DataProcessor.mol_AdminPanel.Form.ServiceInfo", 
		Params, 
		Item,
	);
EndProcedure

