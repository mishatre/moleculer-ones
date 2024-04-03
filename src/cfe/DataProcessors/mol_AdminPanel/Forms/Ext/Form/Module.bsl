	  
#Region FormEventHandlers

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
		NodeStatus = "Loading...";
		AttachIdleHandler("CheckNodeRegistrationHandler", 2, True);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region Status

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

&AtClient
Procedure SidecarTestConnectionStatusURLProcessing(Item, FormattedStringURL, StandardProcessing)
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

#EndRegion

&AtClient
Procedure mol_NodeIdOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

&AtClient
Procedure ConnectionTypeOnChange(Item)
	OnAttributeChange(Item);
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
Procedure PublishInternalServicesOnChange(Item)
	OnAttributeChange(Item);
EndProcedure 

&AtClient
Procedure ConstantsSetmol_NodePublicationNameOnChange(Item)
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
Procedure mol_NodePublicationPathOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

#Region mol_NodeUser

&AtClient
Procedure Constantmol_NodeUserOnChange(Item)
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

#EndRegion

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

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RegisterNode(Command)
	RegisterNodeAtServer();
EndProcedure

&AtClient
Procedure UnregisterNode(Command)
	UnregisterNodeAtServer();
EndProcedure

&AtClient
Procedure UpdateNodeStatus(Item)
	UpdateNodeStatusAtServer()	
EndProcedure

&AtClient
Procedure SidecarTestConnection(Command)
	SidecarTestConnectionAtServer();
EndProcedure

&AtClient
Procedure TestPublicationAccessibility(Command)
	TestPublicationAccessibilityAtServer();
EndProcedure

&AtClient
Procedure OpenInternalServices(Command)
	OpenForm(
		"DataProcessor.mol_AdminPanel.Form.InternalServices", 
		Undefined, 
		ThisForm
	);
EndProcedure  

#EndRegion

#Region Private  

Function GetDefaultString(Text)
	Return New FormattedString(Text,,StyleColors.FieldTextColor,,Undefined);	
EndFunction

Function GetSuccessString(Text, Hyperlink = False)
	Return New FormattedString(
		New FormattedString(Text,,StyleColors.AccentColor,,Undefined),
		?(Hyperlink, New FormattedString("(show details)",,,,"Details"), "")
	);	
EndFunction

Function GetErrorString(Text = "Error ", Hyperlink = True)
	Return New FormattedString(
		New FormattedString(Text,,StyleColors.SpecialTextColor,,Undefined),
		?(Hyperlink, New FormattedString("(show error)",,,,"Error"), "")
	)	
EndFunction

#Region IdleHandlers

&AtClient
Procedure CheckNodeRegistrationHandler()
	UpdateNodeStatusAtServer()	
EndProcedure

#EndRegion

#Region FormUpdate

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

&AtClient
Procedure SetVisibilityOnClient(ConstantName)
	
EndProcedure  

&AtClient
Procedure UpdateAppInterface()
	
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

#EndRegion

#Region Attributes

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

#EndRegion

#Region SidecarActions

#Region Node

&AtServer
Procedure RegisterNodeAtServer()

	NodeStatus = "Loading...";
	RegistrationResponse = mol_Internal.RegisterNode();
	If mol_Internal.IsError(RegistrationResponse) Then
		NodeRegistered = Undefined;
		NodeStatus     = GetErrorString();		
	ElsIf RegistrationResponse = True Then
		NodeRegistered = True;
		NodeStatus     = GetSuccessString("Registered");
	Else
		NodeRegistered = Undefined;
		NodeStatus = GetErrorString("Incorrect response");
	EndIf;    
	
	SetRegistrationButtonAvailability();
	
EndProcedure

&AtServer
Procedure UnregisterNodeAtServer()
	
	NodeStatus = "Loading...";	
	RegistrationResponse = mol_Internal.RemoveNode();	
	If mol_Internal.IsError(RegistrationResponse) Then
		NodeRegistered = Undefined;
		NodeStatus     = GetErrorString();		
	Else    
		mol_Internal.Unwrap(RegistrationResponse);
		If RegistrationResponse = True Then
			NodeRegistered = False;
			NodeStatus     = GetDefaultString("Unregistered");
		Else
			NodeRegistered = Undefined;
			NodeStatus = GetErrorString("Incorrect response");
		EndIf;
	EndIf;    
	
	SetRegistrationButtonAvailability();
	
EndProcedure

&AtServer
Procedure UpdateNodeStatusAtServer()   
	
	NodeID = mol_Broker.NodeID();
	
	NodeStatus = "Loading...";	
	RegistrationResponse = Undefined;
	Response = mol_Internal.GetNodesList();	
	If mol_Internal.IsError(Response) Then
		RegistrationResponse = Response;
		NodeRegistered = Undefined;
		NodeStatus     = GetErrorString();		
	Else    
		If TypeOf(Response) = Type("Array") Then
			Registered = False;
			For Each NodeInfo In Response Do
				If NodeInfo.Id = NodeID Then
					Registered = True;
					Break;
				EndIf;
			EndDo;    
			If Registered Then
				NodeRegistered = True;
				NodeStatus     = GetSuccessString("Registered");		
			Else
				NodeRegistered = False;
				NodeStatus     = GetDefaultString("Unregistered");	
			EndIf;
		Else
			NodeRegistered = Undefined;
			NodeStatus = GetErrorString("Incorrect response");
		EndIf;
	EndIf;    
	
	SetRegistrationButtonAvailability();
		
EndProcedure

#EndRegion

#Region Connection

&AtServer
Procedure SidecarTestConnectionAtServer()
	
	SidecarTestConnectionStatus   = "Loading..."; 
	SidecarTestConnectionResponse = mol_Transit.DiscoverSidecarNode();
	If mol_Internal.IsError(SidecarTestConnectionResponse) Then
		SidecarTestConnectionStatus = GetErrorString();		
	Else    
		mol_Internal.Unwrap(SidecarTestConnectionResponse);
		If TypeOf(SidecarTestConnectionResponse) <> Type("Structure") 
			Or Not SidecarTestConnectionResponse.Property("name") Then
			SidecarTestConnectionStatus = GetErrorString(
				"Connection was successful, but sidecar return incorrect response",
				False
			);                              
		Else
			SidecarTestConnectionStatus = GetSuccessString("Connection successfull ", True);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Publication

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
	ElsIf Response.Result = "pong" Then     
		TestPublicationAccessibilityStatus  = New FormattedString(
			New FormattedString("Connection to gateway successfull ",,StyleColors.AccentColor,,Undefined)
		); 
	Else
		TestPublicationAccessibilityStatus = New FormattedString(
			"Connection to gateway was successful, but gateway return incorrect response",
			,
			StyleColors.SpecialTextColor
		);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion







