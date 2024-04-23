
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	LoadLocalServices();	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	AttachIdleHandler("UpdateServicePublicationInfoHandler", 0.1, True);
EndProcedure

#EndRegion

&AtClient
Procedure InternalServicesSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	Params = New Structure();                           
	Params.Insert("ServiceInfo", LocalServices[SelectedRow].ServiceInfo);
	Params.Insert("Published"  , LocalServices[SelectedRow].Published);
	OpenForm(
		"DataProcessor.mol_AdminPanel.Form.ServiceInfo", 
		Params, 
		Item,
	);
EndProcedure

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateServicePublicationInfo(Command)
	UpdateServicePublicationInfoAtServer();
EndProcedure

#EndRegion

#Region Private 

#Region IdleHandlers

&AtClient
Procedure UpdateServicePublicationInfoHandler()
	UpdateServicePublicationInfoAtServer();	
EndProcedure

#EndRegion

&AtServer
Procedure LoadLocalServices()
	
	LocalServices.Clear(); 
	Result = mol_Broker.GetServiceSchemas(True);
		
	For Each ServiceInfo In Result.Specification Do
		
		NewRow = LocalServices.Add();  
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
			
EndProcedure                      

&AtServer
Procedure UpdateServicePublicationInfoAtServer()
	
	Response = mol_Transit.DiscoverNodes();
	If mol_Helpers.IsError(Response) Then
		Return;
	EndIf;
	
	For Each Row In LocalServices Do
		Row.Published = False;
	EndDo;
	
	For Each Service In Response.Services Do
		If Service.Metadata.Get("$sidecarNodeID") <> mol_Broker.NodeID() Then
			Continue;
		EndIf;
		
		Filter = New Structure();
		Filter.Insert("Name"   , Service.Name);
		Filter.Insert("Version", Service.Version);
		FoundRows = LocalServices.FindRows(Filter);
		If FoundRows.Count() = 1 Then
			FoundRows[0].Published = True;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion


