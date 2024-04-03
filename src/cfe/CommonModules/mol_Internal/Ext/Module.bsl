
#Region Public

#Region SidecarCalls

Function RegisterNode() Export

	NodeInfo = NewNodeInfo();
	NodeInfo.InstanceID = mol_Broker.GetInstanceID();
	NodeInfo.Metadata   = mol_Broker.Metadata();   
	NodeInfo.Gateway    = GetGatewayConnectionSettings();
	
	NodeInfo.Client.Type        = mol_Broker.CLIENT_TYPE();
	NodeInfo.Client.Version     = mol_Broker.MOLECULER_VERSION();
	NodeInfo.Client.ModuleType  = mol_Broker.MODULE_TYPE();
	NodeInfo.Client.LangVersion = mol_Broker.LANG_VERSION();
	NodeInfo.Client.LangCompatibilityVersion = mol_Broker.LANG_COMPATIBILITY_VERSION();
		
	Params = New Structure();
	Params.Insert("node", NodeInfo);
	Response = mol_Broker.Call("$sidecar.nodes.register", Params);
	If IsError(Response) Then
		mol_Logger.Error("Internal.RegisterNode", "Couldn't register sidecar node", Response.Error, Metadata.CommonModules.mol_Internal);
		Return Response;
	EndIf;
	Unwrap(Response);
	
	If Response.Success Then
		mol_Logger.Warn(
			"Internal.RegisterNode", 
			StrTemplate("Node '%1' was successfully registered", mol_Broker.NodeID()),
			Undefined,
			Metadata.CommonModules.mol_Internal
		);
		Return True;
	EndIf;
	
	Return Response;
	            
EndFunction

Function RemoveNode() Export
	
	Response = Moleculer.Call("$sidecar.nodes.remove");
	If IsError(Response) Then
		mol_Logger.Error("Internal.RemoveNode", "Couldn't remove sidecar node (or detect if it was registered at all)", Response.Error, Metadata.CommonModules.mol_Internal);
		Return Response;
	EndIf;
	Unwrap(Response);
	
	If Response.Success Then
		mol_Logger.Warn("Internal.RemoveNode", StrTemplate("Node '%1' was removed from sidecar", mol_Broker.NodeID()), Undefined, Metadata.CommonModules.mol_Internal);
		Return True;
	EndIf;  
	
	mol_Logger.Warn("Internal.RemoveNode", StrTemplate("Couldn't remove sidecar node '%1'", mol_Broker.NodeID()), Response.Error, Metadata.CommonModules.mol_Internal);
	
	Return Response;
	
EndFunction

Function GetNodesList() Export

	Response = Moleculer.Call("$sidecar.nodes.list");
	If IsError(Response) Then
		mol_Logger.Error("Internal.GetNodesList", "Couldn't get sidecar nodes list", Response.Error, Metadata.CommonModules.mol_Internal);
		Return Response;
	EndIf; 
	Unwrap(Response);
	
	Return Response;
	
EndFunction

Function PublishService(ServiceName) Export
	
	Schema = Undefined;
	
	Result = GetServiceSchemas(True);
	For Each ServiceSchema In Result.Services Do
		If ServiceSchema.FullName = ServiceName	Then
			Schema = ServiceSchema;
			Break;
		EndIf;
	EndDo;    
	
	If Schema = Undefined Then
		mol_Logger.Error("Internal.PublishService", StrTemplate("Couldn't find service with name '%1'", ServiceName), Undefined, Metadata.CommonModules.mol_Internal);
		Return False;
	EndIf;
	
	Params = New Structure();
	Params.Insert("schema", Schema); 
	Response = Moleculer.Call("$sidecar.services.publish", Params);	
	If IsError(Response) Then
		mol_Logger.Error("Internal.PublishService", "Couldn't publish service to sidecar node", Response.Error, Metadata.CommonModules.mol_Internal);
		Return Response;
	EndIf;
	Unwrap(Response);
	
	If Response.Success Then
		mol_Logger.Warn("Internal.PublishService", StrTemplate("Service '%1', was published", Schema.Name), Undefined, Metadata.CommonModules.mol_Internal);
		Return True;
	EndIf;
	
	Return Response;
	
EndFunction

Function RemoveService(ServiceName) Export
	
	Params = New Structure();
	Params.Insert("service", ServiceName);
	Response = Moleculer.Call("$sidecar.services.remove"); 
	If IsError(Response) Then
		mol_Logger.Error("Internal.RemoveService", "Couldn't remove service publication", Response.Error, Metadata.CommonModules.mol_Internal);
		Return Response;
	EndIf;
	Unwrap(Response);
	
	If Response.Success Then
		mol_Logger.Warn("Internal.RemoveService", StrTemplate("Service '%1', was successfully removed", ServiceName), Undefined, Metadata.CommonModules.mol_Internal);
		Return True;
	EndIf;  
	
	mol_Logger.Warn("Internal.RemoveService", StrTemplate("Couldn't remove service '%1' publication", ServiceName), Response.Error, Metadata.CommonModules.mol_Internal);
	
	Return Response;
	
EndFunction

Function UpdateService(ServiceName) Export
	
	Schema = Undefined;
	
	Result = GetServiceSchemas(True);
	For Each ServiceSchema In Result.Services Do
		If ServiceSchema.FullName = ServiceName	Then
			Schema = ServiceSchema;
			Break;
		EndIf;
	EndDo;    
	
	If Schema = Undefined Then
		mol_Logger.Error("Internal.UpdateService", StrTemplate("Couldn't find service with name '%1'", ServiceName), Undefined, Metadata.CommonModules.mol_Internal);
		Return False;
	EndIf;
	
	Params = New Structure();
	Params.Insert("schema", Schema);
	Response = Moleculer.Call("$sidecar.services.update"); 
	If IsError(Response) Then
		mol_Logger.Error("Internal.UpdateService", "Couldn't update service publication", Response.Error, Metadata.CommonModules.mol_Internal);
		Return Response;
	EndIf;
	Unwrap(Response);
	
	If Response.Success Then
		mol_Logger.Warn("Internal.UpdateService", StrTemplate("Service '%1', was successfully updated", ServiceName), Undefined, Metadata.CommonModules.mol_Internal);
		Return True;
	EndIf;            
	
	mol_Logger.Warn("Internal.UpdateService", StrTemplate("Couldn't update service '%1' publication", ServiceName), Response.Error, Metadata.CommonModules.mol_Internal);
	
	Return Response;
	
EndFunction

Function GetServicesList() Export
	
	Response = Moleculer.Call("$sidecar.services.list");
	If IsError(Response) Then
		mol_Logger.Error("Internal.GetServicesList", "Couldn't get sidecar services list", Response.Error, Metadata.CommonModules.mol_Internal);
		Return Response;
	EndIf; 
	Unwrap(Response);
	
	Return Response;
	
EndFunction

#Region ReverseCalls

Function PingLocalGateway() Export
	
	GatewayInfo = NewGatewayInfo();
	
	GatewayInfo.Endpoint    = Constants.mol_NodeEndpoint.Get();
	GatewayInfo.Port        = Constants.mol_NodePort.Get();
	GatewayInfo.UseSSL      = Constants.mol_NodeUseSSL.Get();    
	GatewayInfo.Path        = Constants.mol_NodePublicationPath.Get();
	
	GatewayAuthType = Constants.mol_NodeAuthorizationType.Get();
	GatewayAuthInfo = NewGatewayAuthInfo(GatewayAuthType);

	If GatewayAuthType = Enums.mol_AuthorizationType.UsingAccessToken Then
		UserUUID  = Constants.mol_NodeUser.Get();
		FoundUser = InfoBaseUsers.FindByUUID(UserUUID);
		GatewayAuthInfo.AccessToken = mol_InternalHelpers.CreateOneTimeJWT(
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
	
	Params = New Structure();              
	Params.Insert("action" , "$node.ping");
	Params.Insert("nodeID" , mol_Broker.NodeID());
	Params.Insert("gateway", GatewayInfo);
		
	Response = Moleculer.Call("$sidecar.gateway.request", Params);
	
	Return Response;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region Protected

Function NewResponse(Error = Undefined, Result = Undefined, Meta = Undefined) Export
	Response = New Structure();
	Response.Insert("Error" , Error );
	Response.Insert("Result", Result);
	Response.Insert("Meta"  , Meta  );
	Return Response;
EndFunction 

Function IsError(Response) Export

	If TypeOf(Response) = Type("Structure") And 
		Response.Property("Error") And
		Response.Error <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function Unwrap(Response) Export
	Response = Response.Result;	
EndFunction

Function HasResult(Response) Export

	If TypeOf(Response) = Type("Structure") And 
		Response.Property("Result") And
		Response.Result <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#Region Connection

Function GetSidecarConnectionSettings(ForceUpdate = False) Export
	
	If ForceUpdate = False Then
		Return mol_InternalReuse.GetSidecarConnectionSettings();    
	EndIf;
	
	Result = NewConnectionInfo();
	
	Result.Endpoint  = Constants.mol_SidecarEndpoint .Get();
	Result.Port      = Constants.mol_SidecarPort     .Get();
	Result.UseSSL    = Constants.mol_SidecarUseSSL   .Get();
	Result.SecretKey = Constants.mol_SidecarSecretKey.Get();
	Result.AccessKey = Constants.mol_SidecarAccessKey.Get();
	
	Return Result;
	
EndFunction

Function GetGatewayConnectionSettings(ForceUpdate = False) Export
	
	// Add reuse call
	
	If GetFunctionalOption("mol_PublishInternalServices") Then
	
		Gateway = NewGatewayInfo();
		Gateway.Endpoint = Constants.mol_NodeEndpoint.Get();
		Gateway.Port     = Constants.mol_NodePort.Get();
		Gateway.UseSSL   = Constants.mol_NodeUseSSL.Get(); 
		Gateway.Path     = Constants.mol_NodePublicationPath.Get();         
		
		// Auth
		GatewayAuthType = Constants.mol_NodeAuthorizationType.Get();
		GatewayAuthInfo = NewGatewayAuthInfo(GatewayAuthType);
				
		If GatewayAuthType = Enums.mol_AuthorizationType.UsingAccessToken Then
			UserUUID  = Constants.mol_NodeUser.Get();
			FoundUser = InfoBaseUsers.FindByUUID(UserUUID);
			GatewayAuthInfo.AccessToken = mol_InternalHelpers.CreateOneTimeJWT(
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

#EndRegion

#Region Private                    

#Region Connection

Function NewConnectionInfo() Export 

	Result = New Structure();
	Result.Insert("endpoint" , "");
	Result.Insert("port"     , "");
	Result.Insert("useSSL"   , "");
	Result.Insert("secretKey", "");
	Result.Insert("accessKey", "");
	
	Return Result;
	
EndFunction

Function NewGatewayInfo()
	
	Result = New Structure();
	Result.Insert("endpoint");
	Result.Insert("port");
	Result.Insert("path");
	Result.Insert("useSSL");
	
	// See: NewGatewayAuthInfo()
	Result.Insert("auth");
	
	Return Result;
		
EndFunction  

Function NewGatewayAuthInfo(AuthType)
	
	Result = New Structure(); 
	
	If AuthType = Enums.mol_AuthorizationType.UsingPassword Then
		Result.Insert("username");
		Result.Insert("password");
	ElsIf AuthType = Enums.mol_AuthorizationType.UsingAccessToken Then
		Result.Insert("accessToken"); 
	ElsIf AuthType = Enums.mol_AuthorizationType.NoAuth Then    
		Return Result;
	Else
		Raise "UNKNOWN_AUTH_TYPE";
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Schema

Function GetServiceModuleNames(ServiceModulePrefix = "Service", ForceUpdate = False) Export
	
	If ForceUpdate = False Then
		Return mol_InternalReuse.GetServiceModuleNames(ServiceModulePrefix);
	EndIf;
	
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
			mol_Logger.Warn("Internal.GetServiceModuleNames", Message, Undefined, Metadata.CommonModules.mol_Internal);
			Continue;
		EndIf;
		Result.Add(ModuleMetadata.Name);		
	EndDo;  
	
	Result.Add("mol_InternalService");
	
	Return Result;
	
EndFunction
	
Function GetServiceSchemas(ForceUpdate = False) Export

	If ForceUpdate = False Then
		Return mol_InternalReuse.GetServiceSchemas();
	EndIf;
	
	Result = New Structure();
	Result.Insert("Services"     , New Array());
	Result.Insert("Specification", New Array());
	
	NodeID        = Constants.mol_NodeId.Get();
	NodeNamespace = Constants.mol_NodeNamespace.Get();
	
	ServiceModuleNames = GetServiceModuleNames();
	For Each ServiceModuleName In ServiceModuleNames Do
		Response = CompileServiceSchema(ServiceModuleName, NodeNamespace);
		If IsError(Response) Then
			mol_Logger.Warn("Internal.GetServiceSchemas", 
				Response.Error.Message,
				Response.Error, 
				Metadata.CommonModules.mol_Internal
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
		
		
		Result.Services.Add(Schema);
		Result.Specification.Add(ServiceSpecification);
	EndDo;                          
	
	Return Result;
	
EndFunction

Function GetPublicSettings(Val Settings) 
    SecureSettings = Settings.Get("$secureSettings"); 
	If TypeOf(SecureSettings) = Type("Array") Then
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

Function CompileServiceSchema(ModuleName, Namespace = "") Export 
	
	BuilderModule = CommonModule("mol_SchemaBuilder");
	
	NewSchema = BuilderModule.NewSchema(ModuleName);
	
	CurrentContext = mol_InternalReuseCalls.GetServiceSchemaContext();
	CurrentContext.Schema     = NewSchema; 
	CurrentContext.ModuleName = ModuleName;
	CurrentContext.Namespace  = Namespace;
	
	Parameters = New Array();
	Parameters.Add(CurrentContext.Schema);
	Parameters.Add(BuilderModule);
	
	Response = NewResponse();
	
	MainProcedureName = "Service"; 
	Try                            
		SetSafeMode(True);
		ExecuteModuleProcedure(ModuleName, MainProcedureName, Parameters);
		Schema = Parameters[0];
		
		If Not StrStartsWith(Schema.Name, "$") Then
			Schema.Name = StrTemplate("%1.%2", Namespace, Schema.Name);
		EndIf;          
		
		If Schema.Settings.Get("$noVersionPrefix") <> True Then
			Schema.FullName = BuilderModule.GetVersionedFullName(
				Schema.Name,
				Schema.Version
			);         
		Else
			Schema.FullName = Schema.Name;
		EndIf;
		
		Response.Result = Schema
	Except                                                 
		ErrorInfo = ErrorInfo();
		ErrorMessage = StrTemplate("Couldn't compile service schema in module %1", ModuleName); 
		Response.Error = mol_Errors.ServiceSchemaError(ErrorMessage, Undefined, ErrorInfo);	
	EndTry; 
	
	CurrentContext.Schema     = Undefined;
	CurrentContext.ModuleName = Undefined;
	CurrentContext.Namespace  = Undefined;
	
	Return Response;
	
EndFunction

#EndRegion

#Region DynamicEvaluation

Function CommonModule(ModuleName) Export
	
	Module = Undefined;
	If Metadata.CommonModules.Find(ModuleName) <> Undefined Then
		SetSafeMode(True);
		Module = Eval(ModuleName);
	EndIf;
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise StrTemplate("Common module ""%1"" doesn't exist", ModuleName);
	EndIf;
	
	Return Module;
	
EndFunction

Function ExecuteModuleProcedure(Val _ModuleName, Val _ProcedureName, Val _Parameters = Undefined) Export
	
	_Args = BuildArgsString(_Parameters, "_Parameters");
	
	Execute StrTemplate("%1.%2(%3)", _ModuleName, _ProcedureName, _Args);
	
EndFunction

Function ExecuteModuleFunction(Val _ModuleName, Val _FunctionName, Val _Parameters = Undefined) Export
	
	_Args = BuildArgsString(_Parameters, "_Parameters");
	
	Return Eval(StrTemplate("%1.%2(%3)", _ModuleName, _FunctionName, _Args));
	
EndFunction

Function BuildArgsString(Args, ArgsVarName)
	Result = "";
	If Args <> Undefined And Args.Count() > 0 Then
		For Index = 0 To Args.UBound() Do
			Result = Result + StrTemplate("%1[%2],", ArgsVarName, XMLString(Index));	
		EndDo; 
		Result = Mid(Result, 1, StrLen(Result) - 1);
	EndIf;
	Return Result;
EndFunction

#EndRegion

#Region Node 

Function NewNodeInfo()

	Result = New Structure();
	Result.Insert("instanceID", Undefined); 
	Result.Insert("metadata"  , Undefined); 
	Result.Insert("gateway"   , Undefined); 
	Result.Insert("client"    , NewNodeClientInfo()); 
	
	Return Result;
	
EndFunction 

Function NewNodeClientInfo() 
	
	Result = New Structure();
	Result.Insert("type"       , Undefined); 
	Result.Insert("version"    , Undefined); 
	Result.Insert("moduleType" , Undefined); 
	Result.Insert("langVersion", Undefined);
	Result.Insert("langCompatibilityVersion", Undefined);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion 

