
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("ServiceSchema", ServiceSchema) 
		Or Not Parameters.Property("ServiceModule", ServiceModule) Then
		Cancel = True;
		Return;
	EndIf;
	
	LoadServiceData();
	
EndProcedure         

&AtServer
Procedure LoadServiceData()
	
	Namespace = Constants.mol_NodeNamespace.Get();
	
	ServiceName    = Namespace + "." + ServiceSchema.Name;
	ServiceVersion = ServiceSchema.Version;
	
	ServiceActions.Clear();
	For Each Action In ServiceSchema.Actions Do
		NewRow = ServiceActions.Add();
		NewRow.Name        = Action.Name;
		NewRow.Description = Action.Description;
		NewRow.Params      = Action.Params;
	EndDo;
	
	ServiceEvents.Clear();
	For Each Event In ServiceSchema.Events Do
		NewRow = ServiceEvents.Add();
		NewRow.Name        = Event.Name;
		NewRow.Description = Event.Description;
	EndDo;    
	
	ServiceRawSchema.SetText(mol_InternalHelpers.ToString(ServiceSchema, True));
	
	LoadServiceRegistration();
	
EndProcedure

&AtServer
Procedure LoadServiceRegistration()
	
	If Not mol_Internal.NodeRegistered().Result Then
		SetRegistrationButtonAvailability();		
	EndIf;
	
	Response = mol_Internal.GetPublishedNodeServices();
	If mol_Internal.IsError(Response) Then 
		ServiceRegistered = Undefined;
		RegistrationStatus = New FormattedString(
			"UNKNOWN",
			,
			StyleColors.SpecialTextColor
		);            
		SetRegistrationButtonAvailability();
		Return;
	EndIf;    
	
	ServiceRegistered = False;
	
	RegisteredServices = Response.Result;
	For Each Service In RegisteredServices Do
		If Service.Name = ServiceName Then
			ServiceRegistered = True;
			Break;
		EndIf;
	EndDo;     
	
	If ServiceRegistered Then 
		RegistrationStatus = New FormattedString(
				"Registered",
				,
				StyleColors.AccentColor
			);
	Else
		RegistrationStatus = New FormattedString(
			"Unregistered",
			,
			StyleColors.FieldTextColor
		);
	EndIf;
	
	SetRegistrationButtonAvailability();
	
EndProcedure  

&AtServer
Procedure SetRegistrationButtonAvailability()
	
	If ServiceRegistered = True Then
		Items.RegisterService.Visible   = False;
		Items.UnregisterService.Visible = True;
		Items.CheckRegistration.Visible = True;
	ElsIf ServiceRegistered = False Then
		Items.RegisterService.Visible   = True;
		Items.UnregisterService.Visible = False;
		Items.CheckRegistration.Visible = False;
	Else
		Items.RegisterService.Visible   = False;
		Items.UnregisterService.Visible = False;
		Items.CheckRegistration.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckRegistration(Command)
	
	LoadServiceRegistration();
	
EndProcedure

&AtServer
Procedure RegisterServiceAtServer()
	
	RegistrationResponse = Undefined;
	Response = mol_Internal.RegisterNodeService(ServiceModule); 
	RegistrationResponse = Response;
	If mol_Internal.IsError(Response) Then 
		ServiceRegistered = Undefined;
		RegistrationStatus = New FormattedString(
			New FormattedString("Error ",,StyleColors.SpecialTextColor),
			New FormattedString("(show error)",,,,"Error")
		);              
		SetRegistrationButtonAvailability();
		Return;
	EndIf;  
	
	Result = Response.Result;
	If Result.Success = True Then  
		ServiceRegistered = True;
		RegistrationStatus = New FormattedString("Registered ",,StyleColors.AccentColor);	
	Else                         
		ServiceRegistered = False;
		RegistrationStatus = New FormattedString(
			New FormattedString("Error ",,StyleColors.SpecialTextColor),
			New FormattedString("(show error)",,,,"Error")
		);	
	EndIf;                              
	
	SetRegistrationButtonAvailability();
	
EndProcedure

&AtClient
Procedure RegisterService(Command)
	RegisterServiceAtServer();
EndProcedure

&AtServer
Procedure UnregisterServiceAtServer()
	
	RegistrationResponse = Undefined;
	Response = mol_Internal.RevokeNodeServicePubliction(ServiceName, ServiceVersion); 
	RegistrationResponse = Response;
	If mol_Internal.IsError(Response) Then 
		ServiceRegistered = Undefined;
		RegistrationStatus = New FormattedString(
			New FormattedString("Error ",,StyleColors.SpecialTextColor),
			New FormattedString("(show error)",,,,"Error")
		);       
		SetRegistrationButtonAvailability();
		Return;
	EndIf;  
	
	If Response.Result = True Then 
		ServiceRegistered = False;
		RegistrationStatus = New FormattedString("Unregistered ",,StyleColors.FieldTextColor);	
	Else                          
		ServiceRegistered = Undefined;
		RegistrationStatus = New FormattedString(
			New FormattedString("Error ",,StyleColors.SpecialTextColor),
			New FormattedString("(show error)",,,,"Error")
		);	
	EndIf;	   
	
	SetRegistrationButtonAvailability();
	
EndProcedure

&AtClient
Procedure UnregisterService(Command)
	UnregisterServiceAtServer();
EndProcedure

&AtClient
Procedure RegistrationStatusURLProcessing(Item, FormattedStringURL, StandardProcessing)
	If RegistrationResponse.Error <> Undefined Then 
		StandardProcessing = False;
		Params = New Structure();
		Params.Insert("Error", RegistrationResponse.Error); 	
		OpenForm(
			"CommonForm.mol_ErrorViewer", 
			Params, 
			ThisForm
		);	
	Else
		
	EndIf;
EndProcedure
