
#Region Protected

#Region General

// Call an action 
//
// Parameters:
//  ActionName - String            - name of action
//  Params     - Any, Undefined    - params of action
//  Opts       - Object, Undefined - options of call  
//
// Returns - service response
//
Function Call(ActionName, Val Params = Undefined, Opts = Undefined) Export
	
	If Params = Undefined Then
		Params = New Structure;
	EndIf;
	
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;  
	
	ParentSpan = New Structure(); 
	ParentSpan.Insert("id", mol_Broker.GenerateUid());
	ParentSpan.Insert("traceID", ParentSpan.Id);
	ParentSpan.Insert("sampled", True);
	Opts.Insert("parentSpan", ParentSpan);
	
	Context = Undefined;
	If Opts.Property("Context") And Opts.Context <> Undefined Then		
		Context = Opts.Context;
		Context.Action = New Structure();
		Context.Action.Insert("name", ActionName);
	Else              
		Context = mol_ContextFactory.Create(mol_Broker, Params, Opts);
		Context.Action = New Structure();
		Context.Action.Insert("name", ActionName);		
	EndIf; 
	
	mol_Logger.Debug("Broker.Call", 
		"Call action through remote sidecar node.",
		New Structure(
			"Action, RequestID",
			Context.Action.Name,
			Context.RequestID
		),
		Metadata.CommonModules.mol_Broker
	); 
	
	Response = mol_Transit.Request(Context);
	//Response.Insert("Context", Context);
	
	Return Response;
	
EndFunction 

// Multiple action calls.
//
// Parameters:
//  Def  - Array Of Structure   - Calling definitions. See Mol.NewActionDef();
//  Opts - Structure, Undefined - Calling options for each call. See. Mol.NewMCallOpts() 
//
// @throws MoleculerServerError - If the `def` is not an `Array`.
//
// Returns:
//  any
Function MCall(Def, Opts = Undefined) Export
	
	Settled = mol_Helpers.Get(Opts, "Settled", False);
	If mol_Helpers.IsObject(Opts) And Opts.Property("Settled") Then
		Opts.Delete("Settled");
	EndIf;
	
	If mol_Helpers.IsArray(def) Then 
		
		Result = New Array();
		For Each Item In Def Do                          
			CallOptions = mol_Helpers.Get(Item, "Options", Opts);
			Response = Call(Item.Action, Item.Params, CallOptions);
			If Settled = False And mol_Helpers.IsError(Response) Then
				Return Response;
			EndIf;
			Result.Add(Response);			
		EndDo;
		
		Return Result;
		
	ElsIf mol_Helpers.IsObject(Def) Then
		Results = New Map();
		
		For Each KeyValue in Def Do
			Name = KeyValue.Key;
			Item = KeyValue.Value;      
			
			CallOptions = mol_Helpers.Get(Item, "Options", Opts);
			Response = Call(Item.Action, Item.Params, CallOptions);
			If Settled = False And mol_Helpers.IsError(Response) Then
				Return Response;
			EndIf;
			Results.Insert(Name, Response);
			
		EndDo;
		
		Return Results;
		
	Else     
		Error = mol_Errors.ServiceError("INVALID_PARAMETERS", 500, "Invalid calling definition.", Def); 
		mol_Logger.Error("Broker.MCall",                                                                	
			Error.Message,
			Def,
			Metadata.CommonModules.mol_Broker
		);
		Return mol_Helpers.NewResponse(Error);
	EndIf;
    
EndFunction

// Emit an event (grouped & balanced global event)
//
// Parameters:
//  EventName - String                             - event name
//  Payload   - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
// 
Function Emit(EventName, Payload = Undefined, Val Opts = Undefined) Export
	
	If mol_Helpers.IsArray(Opts) Or mol_Helpers.IsString(Opts) Then
		_Opts = Opts;
		Opts = New Structure();
		Opts.Insert("groups", opts);
	ElsIf Opts = Undefined Then
		Opts = New Structure();
		Opts.Insert("groups", New Array);
	EndIf;
	
	If Opts.Property("Groups") And Not mol_Helpers.IsArray(Opts.Groups) Then
		_Groups = New Array();
		_Groups.Add(Opts.Groups);
		Opts.Groups = _Groups;
	EndIf;
	
	Context = mol_ContextFactory.Create(mol_Broker, Payload, Opts);
	
	Context.EventName   = EventName;
	Context.EventType   = "emit";
	Context.EventGroups = Opts.Groups;

	mol_Logger.Debug("Broker.Emit",
		StrTemplate(
			"Emit '%1' event%2.",
			EventName, 
			?(Opts.Property("Groups"),
				StrTemplate(
					" to %1 groups(s)",
					StrConcat(Opts.Groups, ", ")
				),
				""
			)			
		),
		Undefined,
		Metadata.CommonModules.mol_Broker
	);
	
	Return mol_Transit.SendEvent(Context);
		
EndFunction 

// Broadcast an event for all local & remote services
//
// Parameters:
//  EventName - String                             - event name
//  Payload   - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
//
Function Broadcast(EventName, Payload = Undefined, Val Opts = Undefined) Export
	
	If mol_Helpers.IsArray(Opts) Or mol_Helpers.IsString(Opts) Then
		_Opts = Opts;
		Opts = New Structure();
		Opts.Insert("groups", opts);
	ElsIf Opts = Undefined Then
		Opts = New Structure();
	EndIf;
	
	If Opts.Property("Groups") And Not mol_Helpers.IsArray(Opts.Groups) Then
		_Groups = New Array();
		_Groups.Add(Opts.Groups);
		Opts.Groups = _Groups;
	EndIf;
	
	mol_Logger.Debug("Broker.Emit",
		StrTemplate(
			"Broadcast '%1' event%2.",
			EventName, 
			?(Opts.Property("Groups"),
				StrTemplate(
					" to %1 groups(s)",
					StrConcat(Opts.Groups, ", ")
				),
				""
			)			
		),
		Undefined,
		Metadata.CommonModules.mol_Broker
	);
	
	Context = mol_ContextFactory.Create(mol_Broker, Payload, Opts);
	
	Context.EventName   = EventName;
	Context.EventType   = "broadcast";
	Context.EventGroups = Opts.groups; 
	
	Return mol_Transit.SendEvent(Context);
	
EndFunction

// Broadcast an event for all local services
//
// Parameters:
//  EventName - String                             - event name
//  Payload   - Any, Undefined                     - event payload
//  Opts      - Structure, String, Array Of String - Event options or groups
// 
Function BroadcastLocal(EventName, Payload = Undefined, Val Opts = Undefined) Export

	If mol_Helpers.IsArray(Opts) Or mol_Helpers.IsString(Opts) Then
		_Opts = Opts;
		Opts = New Structure();
		Opts.Insert("groups", opts);
	ElsIf Opts = Undefined Then
		Opts = New Structure(); 
		Opts.Insert("groups", Undefined);
	EndIf;
	
	If Opts.Property("Groups") And Not mol_Helpers.IsArray(Opts.Groups) Then
		_Groups = New Array();
		_Groups.Add(Opts.Groups);
		Opts.Groups = _Groups;
	EndIf;                                            
	
	Context = mol_ContextFactory.Create(mol_Broker, Payload, Opts);
	
	Context.EventName   = EventName;
	Context.EventType   = "broadcastLocal";
	Context.EventGroups = Opts.Groups;

	mol_Logger.Debug("Broker.Emit",
		StrTemplate(
			"Broadcast '%1' local event%2.",
			EventName, 
			?(Opts.Property("Groups"),
				StrTemplate(
					" to %1 groups(s)",
					StrConcat(Opts.Groups, ", ")
				),
				""
			)			
		),
		Undefined,
		Metadata.CommonModules.mol_Broker
	);
	
	Return mol_Transit.SendEvent(Context);
	
EndFunction

Function SendToChannel(ChannelName, Payload = Undefined, Val Opts = Undefined) Export

	mol_Logger.Debug("Broker.SendToChannel",
		StrTemplate(
			"Send '%1' channel event.",
			ChannelName,		
		),
		Undefined,
		Metadata.CommonModules.mol_Broker
	);
	
	Return mol_Transit.SendChannelEvent(ChannelName, Payload, Opts);

	
EndFunction

#EndRegion

#Region SidecarCalls

#Region ReverseCalls

Function PingLocalGateway() Export
	
	GatewayInfo = mol_Helpers.NewGatewayInfo();
	
	GatewayInfo.Endpoint    = Constants.mol_NodeEndpoint.Get();
	GatewayInfo.Port        = Constants.mol_NodePort.Get();
	GatewayInfo.UseSSL      = Constants.mol_NodeUseSSL.Get();    
	GatewayInfo.Path        = Constants.mol_NodePublicationPath.Get();
	
	GatewayAuthType = Constants.mol_NodeAuthorizationType.Get();
	GatewayAuthInfo = mol_Helpers.NewGatewayAuthInfo(GatewayAuthType);

	If GatewayAuthType = Enums.mol_AuthorizationType.UsingAccessToken Then
		UserUUID  = Constants.mol_NodeUser.Get();
		FoundUser = InfoBaseUsers.FindByUUID(UserUUID);
		GatewayAuthInfo.AccessToken = mol_Helpers.CreateOneTimeJWT(
			Constants.mol_NodeSecretKey.Get(),
			FoundUser.Name
		);
	ElsIf GatewayAuthType = Enums.mol_AuthorizationType.UsingPassword Then 
		UserUUID  = Constants.mol_NodeUser.Get();
		FoundUser = InfoBaseUsers.FindByUUID(UserUUID);
		GatewayAuthInfo.Username = FoundUser.Name;
		GatewayAuthInfo.Password = Constants.mol_NodeUserPassword.Get();
	EndIf; 
	
	GatewayInfo.Auth = GatewayAuthInfo; 
	
	Action = New Structure();
	Action.Insert("name"   , "$node.ping");
	Action.Insert("handler", "mol_InternalService.PingAction");
	
	Params = New Structure();          
	Params.Insert("action" , Action);                          
	Params.Insert("nodeID" , mol_Broker.NodeID());
	Params.Insert("gateway", GatewayInfo);
		
	Response = Moleculer.Call("$sidecar.gateway.request", Params);
	
	Return Response;
	
EndFunction

#EndRegion

#EndRegion

// Send ping to a node (or all nodes if nodeID is null)
// 
// Parameters:
//  NodeID  - String, Array Of String, Undefined - NodeID
//  Timeout - Number, Undefined                  - Ping timeout
//
// Returns:
//  - Structure          - PongResponse
//  - Array Of Structure - PongResponse
Function Ping(NodeID = Undefined, Timeout = Undefined) Export
	
EndFunction

Function GenerateUid() Export
	Return String(New UUID());
EndFunction

Function NodeID(Force = False) Export
	If Not Force Then
		Return mol_Reuse.NodeID();
	EndIf;
	Return Constants.mol_NodeId.Get();
EndFunction

Function GetNodeInfo() Export

	NodeInfo = mol_Helpers.NewNodeInfo();
	NodeInfo.InstanceID = mol_Broker.GetInstanceID();
	NodeInfo.Metadata   = mol_Broker.Metadata();   
	NodeInfo.Gateway    = GetGatewayConnectionSettings();
	
	NodeInfo.Client.Type        = mol_Broker.CLIENT_TYPE();
	NodeInfo.Client.Version     = mol_Broker.MOLECULER_VERSION();
	NodeInfo.Client.ModuleType  = mol_Broker.MODULE_TYPE();
	NodeInfo.Client.LangVersion = mol_Broker.LANG_VERSION();
	NodeInfo.Client.LangCompatibilityVersion = mol_Broker.LANG_COMPATIBILITY_VERSION();
	
	Return NodeInfo;
	
EndFunction

#Region Settings

Function GetSidecarConnectionSettings(ForceUpdate = False) Export
	
	If ForceUpdate = False Then
		Return mol_Reuse.GetSidecarConnectionSettings();    
	EndIf;
	
	Result = mol_Helpers.NewConnectionInfo();
	
	Result.Endpoint  = Constants.mol_SidecarEndpoint .Get();
	Result.Port      = Constants.mol_SidecarPort     .Get();
	Result.UseSSL    = Constants.mol_SidecarUseSSL   .Get();
	Result.SecretKey = Constants.mol_SidecarSecretKey.Get();
	Result.AccessKey = Constants.mol_SidecarAccessKey.Get(); 
		
	If GetFunctionalOption("mol_UseProxyForConnection") Then	
		ProxyInfo = mol_Helpers.NewProxyConnectionInfo();
		
		ProxyInfo.Protocol = Constants.mol_ProxyProtocol.Get();
		ProxyInfo.Server   = Constants.mol_ProxyServer.Get();
		ProxyInfo.Port     = Constants.mol_ProxyPort.Get();
		ProxyInfo.User     = Constants.mol_ProxyUser.Get();
		ProxyInfo.Password = Constants.mol_ProxyPassword.Get();
		
		Result.Proxy = ProxyInfo;
		
	EndIf; 
	
	Result.Timeout = 60000;
	
	Return Result;
	
EndFunction

Function GetGatewayConnectionSettings(ForceUpdate = False) Export
	
	// Add reuse call
	
	If GetFunctionalOption("mol_PublishInternalServices") Then
	
		Gateway = mol_Helpers.NewGatewayInfo();
		Gateway.Endpoint = Constants.mol_NodeEndpoint.Get();
		Gateway.Port     = Constants.mol_NodePort.Get();
		Gateway.UseSSL   = Constants.mol_NodeUseSSL.Get(); 
		Gateway.Path     = Constants.mol_NodePublicationPath.Get();         
		
		// Auth
		GatewayAuthType = Constants.mol_NodeAuthorizationType.Get();
		GatewayAuthInfo = mol_Helpers.NewGatewayAuthInfo(GatewayAuthType);
				
		If GatewayAuthType = Enums.mol_AuthorizationType.UsingAccessToken Then
			UserUUID  = Constants.mol_NodeUser.Get();
			FoundUser = InfoBaseUsers.FindByUUID(UserUUID);
			GatewayAuthInfo.AccessToken = mol_Helpers.CreateJWTAccessKey(
				Constants.mol_NodeSecretKey.Get(),
				FoundUser.Name            
			);
		ElsIf GatewayAuthType = Enums.mol_AuthorizationType.UsingPassword Then
			UserUUID  = Constants.mol_NodeUser.Get();
			FoundUser = InfoBaseUsers.FindByUUID(UserUUID);
			GatewayAuthInfo.Username = FoundUser.Name;
			GatewayAuthInfo.Password = Constants.mol_NodeUserPassword.Get();
		EndIf; 
		
		Gateway.Auth = GatewayAuthInfo;
		
		Return Gateway;         
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Schema

Function GetServiceSchemas(ForceUpdate = False) Export

	If ForceUpdate = False Then
		Return mol_Reuse.GetServiceSchemas();
	EndIf;
	
	Result = New Structure();
	Result.Insert("Services"     , New Array());
	Result.Insert("Specification", New Array());
	
	NodeID        = Constants.mol_NodeId.Get();
	NodeNamespace = Constants.mol_NodeNamespace.Get();
	
	ServiceModuleNames = GetServiceModuleNames();
	For Each ServiceModuleName In ServiceModuleNames Do
		Response = mol_SchemaFactory.CompileServiceSchema(ServiceModuleName, NodeNamespace);
		If mol_Helpers.IsError(Response) Then
			mol_Logger.Warn("Internal.GetServiceSchemas", 
				Response.Error.Message,
				Response.Error, 
				Metadata.CommonModules.mol_Broker
			);
		    Continue;
		EndIf;   
		Schema = Response.Result;
		
		ServiceSpecification = New Structure();
		ServiceSpecification.Insert("nodeID"  , NodeID); 
		ServiceSpecification.Insert("module"  , ServiceModuleName);
		ServiceSpecification.Insert("name"    , Schema.Name);
		ServiceSpecification.Insert("version" , Schema.Version); 
		ServiceSpecification.Insert("fullName", Schema.FullName);
		ServiceSpecification.Insert("settings", GetPublicSettings(Schema.Settings));
		ServiceSpecification.Insert("metadata", Schema.Metadata);
		ServiceSpecification.Insert("actions" , New Map());
		ServiceSpecification.Insert("events"  , New Map());
		ServiceSpecification.Insert("rawSchema", Schema);
		
		NoServiceNamePrefix = Schema.Settings.Get("$noServiceNamePrefix") = True;
		
		For Each KeyValue In Schema.Actions Do
			Name   = KeyValue.Key;
			Action = KeyValue.Value;
			If Not NoServiceNamePrefix Then
				Name = ServiceSpecification.FullName + "." + Action.Name;
			EndIf;
			
			ServiceSpecification.Actions.Insert(Name, Action);
			
		EndDo;	   
		
		For Each KeyValue In Schema.Events Do
			Name  = KeyValue.Key;
			Event = New Structure(New FixedStructure(KeyValue.Value));     
			                                                          		
			EventGroup = ?(Event.Group <> Undefined, Event.Group, Schema.Name);
			Event.Group = EventGroup;
			
			ServiceSpecification.Events.Insert(Name, Event);
			
		EndDo;
		
		Result.Services.Add(Schema);
		Result.Specification.Add(ServiceSpecification);
	EndDo;                          
	
	Return Result;
	
EndFunction

#EndRegion

#Region Serialization

Function Serialize(Value) Export
	Return mol_Helpers.ToJSONString(Value);
EndFunction

Function Deserialize(Value) Export
	Return mol_Helpers.FromJSONString(Value);	
EndFunction

#EndRegion 

#Region ServiceDiscovery

Function GetLocalActionEndpoint(ActionName) Export
	
	Result = GetServiceSchemas();	
	
	For Each ServiceSpecification In Result.Specification Do
		For Each KeyValue In ServiceSpecification.Actions Do
			If ActionName = KeyValue.Key Then
				Action = KeyValue.Value;
				Endpoint = New Structure();                    
				Endpoint.Insert("id", NodeID());
				Action.Insert("service", ServiceSpecification);
				Endpoint.Insert("action", Action);				
				Return Endpoint;				
			EndIf;
		EndDo;
	EndDo;        
	
	Return Undefined;
	
EndFunction

Function EmitLocalServices(Context) Export 
	
	BroadcastTypes = New Array();
	BroadcastTypes.Add("broadcast");
	BroadcastTypes.Add("broadcastLocal");
	
	IsBroadcast = BroadcastTypes.Find(Context.EventType) <> Undefined;
	Sender = Context.NodeID;
	
	Result = GetServiceSchemas(); 
	
	For Each Service In Result.Specification Do
		For Each KeyValue In Service.Events Do 
			Event = KeyValue.Value;
			If Not mol_Helpers.Match(Context.EventName, Event.Name) Then
				Continue;
			EndIf;
			IsArray = mol_Helpers.IsArray(Context.EventGroups);
			If Context.EventGroups = Undefined Or 
				(IsArray And Context.EventGroups.Count() = 0) Or
				(IsArray And Context.EventGroups.Find(Event.Group) <> Undefined) Then
				
				If IsBroadcast Then
					// Unimplemented
				Else 
					Try
						HandlerParts = StrSplit(Event.Handler, ".");      
						Parameters = New Array();
						Parameters.Add(Context);
						mol_Helpers.ExecuteModuleProcedure(HandlerParts[0], HandlerParts[1], Parameters);
					Except           
						mol_Logger.Error("Broker.EmitLocalServices", "Error while handling event", ErrorInfo(), Metadata.CommonModules.mol_Broker);
					EndTry;	
				EndIf;
			EndIf;
		EndDo;
	EndDo;

	
EndFunction

#EndRegion 

Function GetInstanceID() Export
	Return GenerateUid();
EndFunction

Function Metadata() Export
	Return New Structure();	
EndFunction

Function CLIENT_TYPE() Export
	Return "BSL";	
EndFunction      

Function MOLECULER_VERSION() Export
	Return "0.14.32"         
EndFunction

Function MODULE_TYPE() Export
	Return "extension"         
EndFunction 

Function LANG_VERSION() Export
	Return "8.3.23.1688"         
EndFunction  

Function LANG_COMPATIBILITY_VERSION() Export
	Return "8.3.21"         
EndFunction

#EndRegion

#Region Private

Function FindNextActionEndpoint(ActionName, Opts, Context)
	
	If Not mol_Helpers.IsString(ActionName) Then
		Return mol_Helpers.NewResponse(Undefined, ActionName);
	Else 
		Result = New Structure();
		Result.Insert("id", Undefined);
		Result.Insert("action", New Structure());   
		Result.Action.Insert("name"   , ActionName);
		Result.Action.Insert("service", Undefined);
		Result.Insert("local", False);    
		
		Return mol_Helpers.NewResponse(Undefined, Result);
		
		// Try to find local endpoint
		// Otherwise bail for remote call
	EndIf;    
		
	Return mol_Helpers.NewResponse(Undefined);
	
EndFunction

#Region Schema

Function GetServiceModuleNames(ServiceModulePrefix = "Service")
	
	Result = New Array();
	
	CommonModules = Metadata.CommonModules;
	For Each ModuleMetadata In CommonModules Do
		If Not StrStartsWith(ModuleMetadata.Name, ServiceModulePrefix) Then
			Continue;
		EndIf;
		If Not ModuleMetadata.Server Then  
			Message = StrTemplate(
				"Service module name ""%1"" does not have ""server"" flag and was skipped",
				ModuleMetadata.Name	
			);
			mol_Logger.Warn("Internal.GetServiceModuleNames", Message, Undefined, Metadata.CommonModules.mol_Broker);
			Continue;
		EndIf;
		Result.Add(ModuleMetadata.Name);		
	EndDo;  
	
	Result.Add("mol_InternalService");
	
	Return Result;
	
EndFunction
	
Function GetPublicSettings(Val Settings) 
    SecureSettings = Settings.Get("$secureSettings"); 
	If mol_Helpers.IsArray(SecureSettings) Then
		For Each SecureSetting In SecureSettings Do
			Parts = StrSplit(SecureSettings, ".");
			If Parts.Count = 1 Then
				Settings.Delete(Parts[0]);				
			Else      
				CurrentLeaf = Settings;
				Index = -1;
				For Each Part In Parts Do
					Index = Index + 1;
					LeafType = TypeOf(CurrentLeaf);
					IsLast = Index = Parts.UBound();
					If LeafType = Type("Structure") Or LeafType = Type("Map") Then
						If LeafType = Type("Structure") And CurrentLeaf.Property(Part) Then
							If IsLast Then
								CurrentLeaf.Delete(Part);
							Else
								CurrentLeaf = CurrentLeaf[Part];
							EndIf;
						ElsIf LeafType = Type("Map") And CurrentLeaf.Get(Part) <> Undefined Then
							If IsLast Then
								CurrentLeaf.Delete(Part);
							Else
								CurrentLeaf = CurrentLeaf[Part];
							EndIf;	
						EndIf;
					Else
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;                                
	
	Return Settings;
	
EndFunction

#EndRegion

#EndRegion