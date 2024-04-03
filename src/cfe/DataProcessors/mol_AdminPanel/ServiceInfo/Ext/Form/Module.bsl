
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("ServiceInfo", ServiceInfo) Then
		Cancel = True;
		Return;
	EndIf;
	
	LoadServiceData();
	
EndProcedure         

&AtServer
Procedure LoadServiceData()
	
		
	ServiceName     = ServiceInfo.Name;
	ServiceVersion  = ServiceInfo.Version;  	
	ServiceFullName = ServiceInfo.FullName;
	
	ServiceActions.Clear();
	For Each KeyValue In ServiceInfo.Actions Do
		Action = KeyValue.Value;
		NewRow = ServiceActions.Add();
		NewRow.Name        = Action.Name;
		NewRow.Description = Action.Description;
		NewRow.Params      = Action.Params;
	EndDo;
	
	ServiceEvents.Clear();
	For Each Event In ServiceInfo.Events Do
		Event = KeyValue.Value;
		NewRow = ServiceEvents.Add();
		NewRow.Name        = Event.Name;
		NewRow.Description = Event.Description;
	EndDo;    
	
	ServiceRawSchema.SetText(mol_InternalHelpers.ToJSONString(ServiceInfo.RawSchema, True));
	
	LoadServiceRegistration();
	
EndProcedure

&AtServer
Procedure LoadServiceRegistration()
	
	//SetRegistrationButtonAvailability();
	//
	//Response = mol_Internal.GetPublishedNodeServices();
	//If mol_Internal.IsError(Response) Then 
	//	ServiceRegistered = Undefined;
	//	RegistrationStatus = New FormattedString(
	//		"UNKNOWN",
	//		,
	//		StyleColors.SpecialTextColor
	//	);            
	//	SetRegistrationButtonAvailability();
	//	Return;
	//EndIf;    
	//
	//ServiceRegistered = False;
	//
	//RegisteredServices = Response.Result;
	//For Each Service In RegisteredServices Do
	//	If Service.Name = ServiceName Then
	//		ServiceRegistered = True;
	//		Break;
	//	EndIf;
	//EndDo;     
	//
	//If ServiceRegistered Then 
	//	RegistrationStatus = New FormattedString(
	//			"Registered",
	//			,
	//			StyleColors.AccentColor
	//		);
	//Else
	//	RegistrationStatus = New FormattedString(
	//		"Unregistered",
	//		,
	//		StyleColors.FieldTextColor
	//	);
	//EndIf;
	//
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
	
	Items.RegisterService.Visible   = True;
	Items.UnregisterService.Visible = true;
	Items.CheckRegistration.Visible = True;
	
EndProcedure

&AtClient
Procedure CheckRegistration(Command)
	
	LoadServiceRegistration();
	
EndProcedure

&AtServer
Procedure RegisterServiceAtServer()
	
	RegistrationResponse = Undefined;
	Response = mol_Internal.PublishService(ServiceFullName); 
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
	
	If Response = True Then  
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
	Response = mol_Internal.RemoveService(ServiceFullName); 
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
