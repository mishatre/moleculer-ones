
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If ValueIsFilled(ConstantsSet.mol_NodeUser) Then 
		InfoBaseUser = InfoBaseUsers.FindByUUID(ConstantsSet.mol_NodeUser);
		If InfoBaseUser <> Undefined Then
			Constantmol_NodeUser = InfoBaseUser.Name;		     
		EndIf;
	EndIf;
	
	SetItemsAvailability();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ValueIsFilled(ConstantsSet.mol_NodeId) Then
		AttachIdleHandler("CheckNodeRegistrationHandler", 2, True);
	EndIf;
EndProcedure

&AtServer
Procedure SidecarTestConnectionAtServer()  
	
	SidecarTestConnectionStatus   = ""; 
	SidecarTestConnectionResponse = Undefined;	
	
	Response = mol_Internal.GetSidecarServiceInfo();
	SidecarTestConnectionResponse = Response;
	
	If mol_Internal.IsError(Response) Then
		SidecarTestConnectionStatus = New FormattedString(
			New FormattedString("Node connection error ",,StyleColors.SpecialTextColor,,Undefined),
			New FormattedString("(show error)",,,,"Error")
		);		
	Else     
		If TypeOf(Response.Result) <> Type("Structure") Or Not Response.Result.Property("name") Then
			SidecarTestConnectionStatus = New FormattedString(
				"Connection was successful, but sidecar return incorrect response",
				,
				StyleColors.SpecialTextColor
			);
		Else
			SidecarTestConnectionStatus  = New FormattedString(
				New FormattedString("Connection successfull ",,StyleColors.AccentColor,,Undefined),
				New FormattedString("(show details)",,,,"Details")
			);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SidecarTestConnection(Command)
	SidecarTestConnectionAtServer();
EndProcedure

&AtClient
Procedure ConnectionTypeOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtServer
Function OnAttributeChangeAtServer(ElementName)

    DataPathAttribute = Items[ElementName].DataPath;
	ConstantName = SaveAttributeValue(DataPathAttribute);
	SetItemsAvailability(DataPathAttribute);
	RefreshReusableValues();
	
	Return ConstantName;
		
EndFunction 

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	If DataPathAttribute = "" Then
		Return "";
	EndIf;
	
	NameParts = StrSplit(DataPathAttribute, ".");
	
	If NameParts.Count() = 2 Then
		ConstantName  = NameParts[1];
		ConstantValue = ConstantsSet[ConstantName];
	ElsIf NameParts.Count() = 1 And Lower(Left(DataPathAttribute, 8)) = Lower("Constant") Then
		ConstantName  = Mid(DataPathAttribute, 9);
		ConstantValue = ConstantsSet[ConstantName];          
	Else
		Return "";
	EndIf;        
	
	If Constants[ConstantName].Get() <> ConstantValue Then
		Constants[ConstantName].Set(ConstantValue);
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtClient
Procedure OnAttributeChange(Item, UpdateInterface = True)
	
	ConstantName = OnAttributeChangeAtServer(Item.Name);
	RefreshReusableValues();
	
	If UpdateInterface Then
		AttachIdleHandler("UpdateAppInterface", 2, True);	
	EndIf;                                               
	
	SetVisibilityOnClient(ConstantName);
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure 

&AtClient
Procedure SetVisibilityOnClient(ConstantName)
	
EndProcedure  

&AtClient
Procedure UpdateAppInterface()
	
EndProcedure

&AtServer
Procedure SetItemsAvailability(DataPathAttribute = "")
	
	If DataPathAttribute = "ConstantsSet.mol_ConnectionType" Or DataPathAttribute = "" Then
		
		If ConstantsSet.mol_ConnectionType = Enums.mol_ConnectionType.Sidecar Then
			Items.PagesConnectionType.CurrentPage = Items.PageConnectionTypeSidecar;	
		ElsIf ConstantsSet.mol_ConnectionType = Enums.mol_ConnectionType.NativeAPI Then
			Items.PagesConnectionType.CurrentPage = Items.PageConnectionTypeNativeAPI;	
		EndIf;
		
	EndIf;    
	
	If DataPathAttribute = "ConstantsSet.mol_UseProxyForConnection" Or DataPathAttribute = "" Then
		Items.GroupSidecarUseProxyConnection.Enabled = ConstantsSet.mol_UseProxyForConnection;	
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.mol_PublishServices" Or DataPathAttribute = "" Then
		PublicationEnabled = ConstantsSet.mol_PublishServices;
		Items.OpenInternalServices.Enabled                = PublicationEnabled;
		Items.GroupSidecarPublicationConnection.Enabled   = PublicationEnabled;
		Items.ConstantsSetmol_NodePublicationName.Enabled = PublicationEnabled;
		Items.OpenInternalServices.Enabled = PublicationEnabled;
		Items.GroupDynamicServices.Enabled = PublicationEnabled;
	EndIf;    
	
	If DataPathAttribute = "ConstantsSet.mol_NodeAuthorizationType" Or DataPathAttribute = "" Then
		If ConstantsSet.mol_NodeAuthorizationType = Enums.mol_AuthorizationType.NoAuth Then
			Items.Constantmol_NodeUser.Enabled = False;
			Items.PagesSidecarPublicationAuthorizationType.Visible = False;   
		Else
			Items.Constantmol_NodeUser.Enabled = True;
			Items.PagesSidecarPublicationAuthorizationType.Visible = True;	
		EndIf;
		If ConstantsSet.mol_NodeAuthorizationType = Enums.mol_AuthorizationType.UsingPassword Then
			Items.PagesSidecarPublicationAuthorizationType.CurrentPage = Items.PageSidecarPublicationAuthorizationTypeBasic;	
		ElsIf ConstantsSet.mol_NodeAuthorizationType = Enums.mol_AuthorizationType.UsingAccessToken Then
			Items.PagesSidecarPublicationAuthorizationType.CurrentPage = Items.PageSidecarPublicationAuthorizationTypeAccessToken;	
		EndIf;
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.mol_UseDynamicServices" Or DataPathAttribute = "" Then
		Items.OpenDynamicServices.Enabled = ConstantsSet.mol_UseDynamicServices;
	EndIf;   
	
	
EndProcedure  

&AtServer
Procedure SetRegistrationButtonAvailability()
	
	If NodeRegistered = True Then
		Items.RegisterNode.Visible      = False;
		Items.UnregisterNode.Visible    = True;
		Items.CheckRegistration.Visible = True;
	ElsIf NodeRegistered = False Then
		Items.RegisterNode.Visible      = True;
		Items.UnregisterNode.Visible    = False;
		Items.CheckRegistration.Visible = False;
	Else
		Items.RegisterNode.Visible      = False;
		Items.UnregisterNode.Visible    = False;
		Items.CheckRegistration.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SidecarTestConnectionStatusClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	Params = New Structure();
	
	If SidecarTestConnectionResponse.Error <> Undefined Then
		Params.Insert("Error", SidecarTestConnectionResponse.Error); 	
		OpenForm(
			"CommonForm.mol_ErrorViewer", 
			Params, 
			ThisForm
		);  
	ElsIf SidecarTestConnectionResponse.Result <> Undefined Then		
		Params.Insert("SidecarInfo", SidecarTestConnectionResponse.Result); 	
		OpenForm(
			"CommonForm.mol_SidecarInfo", 
			Params, 
			ThisForm,
		); 	
	EndIf;
	
EndProcedure

&AtClient
Procedure ConstantsSetmol_SidecarEndpointOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure ConstantsSetmol_SidecarPortOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure ConstantsSetmol_SidecarUseSSLOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure ConstantsSetmol_SidecarSecretKeyOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure ConstantsSetmol_SidecarAccessKeyOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure PublishInternalServicesOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure ConstantsSetmol_NodeEndpointOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure ConstantsSetmol_NodePortOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure ConstantsSetmol_NodeUseSSLOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure mol_NodeUserOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure mol_NodeAuthorizationTypeOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure mol_NodeUserPasswordOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure mol_NodeSecretKeyOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure mol_UseDynamicServicesOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure Constantmol_NodeUserStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	Params = New Structure();
	If ValueIsFilled(ConstantsSet.mol_NodeUser) Then
		Params.Insert("SelectedUser", ConstantsSet.mol_NodeUser);
	EndIf;
		
	OpenForm(
		"CommonForm.mol_UserSelection", 
		Params, 
		Item,
	); 
	
EndProcedure

&AtClient
Procedure Constantmol_NodeUserChoiceProcessing(Item, SelectedValue, AdditionalData, StandardProcessing)
	ConstantsSet.mol_NodeUser = SelectedValue.Value;
	SelectedValue = SelectedValue.Presentation;
EndProcedure

&AtClient
Procedure TestPublicationAccessibility(Command)
	TestPublicationAccessibilityAtServer();
EndProcedure  

&AtServer
Procedure TestPublicationAccessibilityAtServer()  
	
	TestPublicationAccessibilityStatus   = ""; 
	TestPublicationAccessibilityResponse = Undefined;
	
	Response = mol_Internal.PingLocalGateway();
	TestPublicationAccessibilityResponse = Response;
	
	If mol_Internal.IsError(Response) Then
		TestPublicationAccessibilityStatus = New FormattedString(
			New FormattedString("Sidecar connection error ",,StyleColors.SpecialTextColor,,Undefined),
			New FormattedString("(show error)",,,,"Error")
		);		
	Else     
		If TypeOf(Response.Result) <> Type("Structure") 
				Or Not Response.Result.Property("Success")
				Or Not Response.Result.Success Then
			TestPublicationAccessibilityStatus = New FormattedString(
				"Connection to gateway was successful, but gateway return incorrect response",
				,
				StyleColors.SpecialTextColor
			);
		Else
			TestPublicationAccessibilityStatus  = New FormattedString(
				New FormattedString("Connection to gateway successfull ",,StyleColors.AccentColor,,Undefined)
			);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure mol_NodePublicationPathOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure RegisterNode(Command)
	RegisterNodeAtServer();
EndProcedure

&AtServer
Procedure RegisterNodeAtServer()  
	
	RegistrationResponse = Undefined;
	Response = mol_Internal.RegisterSidecarNode();
	RegistrationResponse = Response;
	If mol_Internal.IsError(Response) Then
		NodeRegistered = Undefined;
		NodeStatus = New FormattedString(
			New FormattedString("Error ",,StyleColors.SpecialTextColor,,Undefined),
			New FormattedString("(show error)",,,,"Error")
		);		
	Else     
		If TypeOf(Response.Result) <> Type("Structure") 
				Or Not Response.Result.Property("Success")
				Or Not Response.Result.Success Then 
			NodeRegistered = Undefined;
			NodeStatus = New FormattedString(
				"Error",
				,
				StyleColors.SpecialTextColor
			);
		Else       
			NodeRegistered = True;
			NodeStatus  = New FormattedString(
				"Registered",
				,
				StyleColors.AccentColor
			);
		EndIf;
	EndIf;    
	
	SetRegistrationButtonAvailability();
	
EndProcedure

&AtClient
Procedure mol_NodeIdOnChange(Item)
	OnAttributeChange(Item);
EndProcedure     

&AtClient
Procedure CheckNodeRegistrationHandler()
	CheckNodeRegistrationAtServer()	
EndProcedure

&AtClient
Procedure CheckNodeRegistration(Item)
	CheckNodeRegistrationAtServer()	
EndProcedure   

&AtServer
Procedure CheckNodeRegistrationAtServer() 
	
    RegistrationResponse = Undefined;      	
	Response = mol_Internal.NodeRegistered();
	RegistrationResponse = Response;   
	
	If mol_Internal.IsError(Response) Then
		NodeRegistered = Undefined;
		NodeStatus = New FormattedString(
			New FormattedString("Error ",,StyleColors.SpecialTextColor,,Undefined),
			New FormattedString("(show error)",,,,"Error")
		);		
	ElsIf TypeOf(Response.Result) = Type("Boolean") Then
		NodeRegistered = Response.Result;
		NodeStatus = ?(Response.Result, 
			New FormattedString("Registered",, StyleColors.AccentColor),
			New FormattedString("Unegistered",, StyleColors.FieldTextColor)
		);
	Else  
		NodeStatus = New FormattedString("UNKNOWN",, StyleColors.SpecialTextColor);
	EndIf; 
	
	SetRegistrationButtonAvailability();
	
EndProcedure

&AtClient
Procedure NodeStatusURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	Params = New Structure();
	
	If RegistrationResponse.Error <> Undefined Then
		Params.Insert("Error", RegistrationResponse.Error); 	
		OpenForm(
			"CommonForm.mol_ErrorViewer", 
			Params, 
			ThisForm
		);  
	EndIf;
EndProcedure

&AtServer
Procedure UnregisterNodeAtServer() 
	
	RegistrationResponse = Undefined;
	Response = mol_Internal.UnregisterSidecarNode();
	RegistrationResponse = Response;
	
	If mol_Internal.IsError(Response) Then
		NodeRegistered = Undefined;
		NodeStatus = New FormattedString(
			New FormattedString("Error ",,StyleColors.SpecialTextColor,,Undefined),
			New FormattedString("(show error)",,,,"Error")
		);		
	Else     
		If Response.Result = True Then
			NodeRegistered = False;
			NodeStatus  = New FormattedString(
				"Unregistered",
				,
				StyleColors.FieldTextColor
			);
		Else  
			NodeRegistered = Undefined;
			NodeStatus = New FormattedString(
				"Error",
				,
				StyleColors.SpecialTextColor
			);	
		EndIf;
	EndIf;    
	
	SetRegistrationButtonAvailability();
	
EndProcedure

&AtClient
Procedure UnregisterNode(Command)
	UnregisterNodeAtServer();
EndProcedure

&AtClient
Procedure ConstantsSetmol_NodePublicationNameOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure OpenInternalServices(Command)
	OpenForm(
		"DataProcessor.mol_AdminPanel.Form.InternalServices", 
		Undefined, 
		ThisForm
	);
EndProcedure

&AtClient
Procedure mol_UseProxyForConnectionOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure mol_ProxyProtocolOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure mol_ProxyServerOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure mol_ProxyPortOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure mol_ProxyUserOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure mol_ProxyPasswordOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure TestPublicationAccessibilityStatusURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;	
	If TestPublicationAccessibilityResponse.Error <> Undefined Then
		Params = New Structure();
		Params.Insert("Error", TestPublicationAccessibilityResponse.Error); 	
		OpenForm(
			"CommonForm.mol_ErrorViewer", 
			Params, 
			ThisForm
		);  
	ElsIf TestPublicationAccessibilityResponse.Result <> Undefined Then		
	
	EndIf;
EndProcedure





