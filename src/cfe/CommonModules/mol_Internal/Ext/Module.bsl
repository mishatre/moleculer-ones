
#Region Public

Function RegisterSidecarNode() Export

	Params = NewNodeRegistrationInfo();
	Params.Connection.Endpoint    = Constants.mol_NodeEndpoint.Get();
	Params.Connection.Port        = Constants.mol_NodePort    .Get();
	Params.Connection.UseSSL      = Constants.mol_NodeUseSSL  .Get();  
	Params.Connection.AccessToken = mol_InternalHelpers.CreateOneTimeJWT(
		Constants.mol_NodeSecretKey.Get()
	);
	
	NodePublicationName = Constants.mol_NodePublicationName.Get();
	
	Params.Name    = Constants.mol_NodeName.Get(); 
	Params.Gateway = mol_InternalHelpers.GetGatewayPath(NodePublicationName);
	
	Response = Moleculer.Call("$sidecar.registerSidecarNode", Params);
	If IsError(Response) Then
			
	EndIf; 
	
	Return Response;
	
EndFunction

#EndRegion

#Region Protected

Function HandleIncomingServiceRequest(HTTPServiceRequest) Export

	Type = mol_InternalHelpers.GetURLParameter(HTTPServiceRequest, "Type");
	If Type = Undefined Then 
		Return NewServiceResponse(
			mol_Errors.RequestRejected("Malformed request URL")
		);
	EndIf;
	
	Payload = ExtractRequestPayload(HTTPServiceRequest);
	If IsError(Payload) Then
		Return NewServiceResponse(Payload);
	EndIf;
	Payload = Payload.Result;

	If Lower(Type) = Lower("Request") Then
		Return RequestHandler(Payload);	
	ElsIf Lower(Type) = Lower("Event") Then
	ElsIf Lower(Type) = Lower("Discover") Then
		Return SendLocalServicesInfo();
	EndIf; 
	
	Data = New Structure();
	Data.Insert("type", Type);
	Return NewServiceResponse(
		mol_Errors.RequestRejected("Unknown gateway type", Data)
	);
	
EndFunction

Function ExecuteSidecarAction(ActionParameters, Payload) Export
	
	If Not mol_InternalHelpers.IsObject(ActionParameters) Then
		Return NewResponse(mol_Errors.TypeError("ActionParameters should be of type ""Object"""));	
	EndIf;
	
	If Not mol_InternalHelpers.IsObject(Payload) Then
		Return NewResponse(mol_Errors.TypeError("Payload should be of type ""Object"""));	
	EndIf; 
		
	Headers = New Map();
	Headers.Insert("content-type", "application/json");
	
	RequestParameters = NewRequestParameters();    
	RequestParameters.Method  = ActionParameters.Method;
	RequestParameters.Path    = ActionParameters.Path;
	RequestParameters.Query   = "";                   
	RequestParameters.Headers = Headers;
	
	If Payload.Options.Property("ConnectionInfo") Then
		RequestParameters.ConnectionInfo = Payload.Options.ConnectionInfo;
		Payload.Options.Delete("ConnectionInfo");
	EndIf;
	If Payload.Options.Property("Timeout") Then
		RequestParameters.Timeout = Payload.Options.Timeout; 
		Payload.Options.Delete("Timeout");
	EndIf;
	
	Payload = mol_InternalHelpers.ToString(Payload);
	
	Response = ExecuteSidecarRequest(RequestParameters, Payload);
	
	ThrowErrors = False;
	If IsError(Response) And ThrowErrors = True Then
		Raise Response.Error.Message;	
	EndIf;
	
	Return Response;
	
EndFunction


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

Function HasResult(Response) Export

	If TypeOf(Response) = Type("Structure") And 
		Response.Property("Result") And
		Response.Result <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region Private                    

// Execute Sidecar request
//
// @internal
//
// Parameters:
//  Options   - Structure          - Request options
//  Payload   - String, BinaryData - Request payload
// 
// Returns:
//  Structure:
//  	* Error  - Structure - Error description
//      * Result - Structure - Sidecar request response
Function ExecuteSidecarRequest(Options, Payload)
	
	If Not mol_InternalHelpers.IsObject(Options) Then
		Return NewResponse(mol_Errors.TypeError("Options should be of type ""object"""));	
	EndIf;      
	
	If Not mol_InternalHelpers.IsString(Payload) And Not mol_InternalHelpers.IsBinaryData(Payload) Then
		Return NewResponse(mol_Errors.TypeError("Payload should be of type ""string"" or ""binary data"""));	
	EndIf;   
	
	ConnectionInfo = Undefined;
	If Options.Connectioninfo <> Undefined Then
		ConnectionInfo = Options.ConnectionInfo;	
	Else
		ConnectionInfo = GetSidecarConnectionSettings();
	EndIf;
	
	If Options.Headers = Undefined Then
		Options.Headers = New Map;		
	EndIf; 
	
	If Options.Method = "POST" Or Options.Method = "PUT" Or Options.Method = "DELETE" Then
		PayloadSize = mol_InternalHelpers.GetPayloadSize(Payload);
		Options.Headers.Insert("content-length", Format(PayloadSize, "NG="));	
	EndIf;
	
	Sha256Sum = mol_InternalHelpers.ToSha256(Payload);
	
	ReqOptions = NewRequestOptions(Options, ConnectionInfo);
	
	Region      = "ru-kuba-spb";
	ServiceName = "moleculer";
	
	Date = CurrentUniversalDate();
	ReqOptions.Headers.Insert("x-amz-date"          , mol_InternalHelpers.MakeDateLong(date));
	ReqOptions.Headers.Insert("x-amz-content-sha256", Sha256Sum);
	AuthorizationHeader = mol_InternalHelpers.SignV4(
		ReqOptions, 
		ConnectionInfo.AccessKey, 
		ConnectionInfo.SecretKey, 
		Region, 
		Date, 
		Sha256Sum,
		ServiceName
	);
	If AuthorizationHeader.Error <> Undefined Then Return AuthorizationHeader Else AuthorizationHeader = AuthorizationHeader.Result; EndIf;	
	ReqOptions.Headers.Insert("authorization", AuthorizationHeader);
	
	Response = MakeHTTPRequest(ReqOptions, Payload);
	If IsError(Response) Then
		Return Response;
	EndIf;
	Result = Response.Result;
	
	ResponseData = mol_InternalHelpers.ParseMoleculerResponse(Result.GetBodyAsString());  
	Return NewResponse(ResponseData.Error, ResponseData.Result, Response.Meta);
	
EndFunction

// Execute HTTP request to sidecar server
//
// @internal
//
// Parameters:
//  Options - Structure          - Request options
//  Body    - String, BinaryData - Request body
// 
// Returns:
//  Structure:
//  	* Error  - Structure    - Error description
//      * Result - HTTPResponse - HTTP request response
Function MakeHTTPRequest(Options, Body)

	HTTPConnection = mol_InternalReuse.GetHTTPConnection(
		Options.Protocol,
		Options.Host,
		Options.Port,
		Options.Timeout
	);
	
	HTTPRequest = New HTTPRequest(Options.Path, Options.Headers); 	
	mol_InternalHelpers.SetRequestResponseBody(HTTPRequest, Body);
	
	Result = Undefined;
	Error  = Undefined; 
	Meta   = New Structure();
	Try     
		Time1 = CurrentUniversalDateInMilliseconds();
		Result = HTTPConnection.CallHTTPMethod(Options.Method, HTTPRequest);
		Time2 = CurrentUniversalDateInMilliseconds();		
	Except
		Time2 = CurrentUniversalDateInMilliseconds(); 
		ErrorInfo = ErrorInfo();
		Error = mol_Errors.FromErrorInfo(ErrorInfo);
	EndTry;      
	
    Meta.Insert("elapsedTime", Time2 - Time1);
	Return NewResponse(Error, Result, Meta);
	
EndFunction

Function NewRequestParameters()

	Result = New Structure();    
	Result.Insert("Method"    , Undefined);
	Result.Insert("Path"      , Undefined);
	Result.Insert("Headers"   , Undefined);
	Result.Insert("Query"     , Undefined);  
	
	Result.Insert("ConnectionInfo", Undefined);
	Result.Insert("Timeout"       , 60000);
	
	Return Result;
	
EndFunction

Function NewRequestOptions(Options, ConnectionInfo)
	
	PATH_PREFIX = "/v1"; 
	
	Method     = Options.Method;    
	Headers    = Options.Headers;
    Query      = Options.Query; 
	Protocol   = ?(ConnectionInfo.UseSSL, "https:", "http:");
			
	ReqOptions = New Structure();
	ReqOptions.Insert("Method"  , Method  );
	ReqOptions.Insert("Headers" , New Map );
	ReqOptions.Insert("Protocol", Protocol);
	ReqOptions.Insert("Timeout" , Options.Timeout/1000);
	
	Path = PATH_PREFIX + Options.Path;
	Host = ConnectionInfo.Endpoint;
	
	Port = Undefined;
	If ValueIsFilled(ConnectionInfo.Port) Then
		Port = ConnectionInfo.Port;
	EndIf;
	
	If ValueIsFilled(Query) Then
		Path = StrTemplate("%1?%2", Path, Query);
	EndIf;
	ReqOptions.Headers.Insert("host", Host);	
	If (ReqOptions.Protocol = "http:" And Port <> 80) Or (ReqOptions.Protocol = "https:" And Port <> 443) Then
		ReqOptions.Headers["host"] = StrTemplate("%1:%2", Host, Format(Port, "NG="));
	EndIf;
	
	//ReqOptions.Headers.Insert("user-agent", "1C");
	If Headers <> Undefined Then
		// have all header keys in lower case - to make signing easy
		For Each KeyValue In Headers Do
			ReqOptions.Headers.Insert(Lower(KeyValue.Key), KeyValue.Value);
		EndDo;
	EndIf;
	
	ReqOptions.Insert("Host", Host);
	ReqOptions.Insert("Port", Port);
	ReqOptions.Insert("Path", Path);
	
	Return ReqOptions;
	
EndFunction

#Region Settings

Function NewConnectionInfo() Export 

	Result = New Structure();
	Result.Insert("endpoint" , "");
	Result.Insert("port"     , "");
	Result.Insert("useSSL"   , "");
	Result.Insert("secretKey", "");
	Result.Insert("accessKey", "");
	
	Return Result;
	
EndFunction

Function GetSidecarConnectionSettings(ForceUpdate = False) Export
	
	If ForceUpdate = False Then
		Return mol_InternalReuse.GetSidecarConnectionSettings();    
	EndIf;
	
	Result = NewConnectionInfo();
	
	Result.Endpoint  = Constants.mol_Endpoint .Get();
	Result.Port      = Constants.mol_Port     .Get();
	Result.UseSSL    = Constants.mol_UseSSL   .Get();
	Result.SecretKey = Constants.mol_SecretKey.Get();
	Result.AccessKey = Constants.mol_AccessKey.Get();
	
	Return Result;
	
EndFunction

#EndRegion

#Region IncomingRequest

Function ExtractRequestPayload(HTTPServiceRequest)
	
	Error  = Undefined;
	Result = Undefined;
	
	BodyString = HTTPServiceRequest.GetBodyAsString();

	Try
		Result = mol_InternalHelpers.BasicFromString(BodyString);	
	Except
		Data = New Structure();
		Data.Insert("body", BodyString);
		Error = mol_Errors.RequestRejected("Malformed sidecar request body", Data);	
	EndTry; 
	
	Return NewResponse(Error, Result);
	
EndFunction

Function RequestHandler(Payload)

	Endpoint = GetLocalActionEndpoint(Payload.Action);
	
	// Recreate caller context
	Context = CreateNewContext();
	
	SetContextEndpoint(Context, Endpoint);
	LifecycleAction = Endpoint.Action.Name = "started" Or Endpoint.Action.Name = "stopped";
	If Not LifecycleAction Then
		Context.Id        = Payload.Id;
		SetContextParams(Context, Payload.Params);
		Context.ParentID  = Payload.ParentID;
		Context.RequestID = Payload.RequestID;
		Context.Caller    = Payload.Caller;
		Context.Meta      = GetPropertyOr(Payload, "Meta", New Map());
		Context.Level     = Payload.Level;
		//Context.Tracing   = Payload.Tracing;
		Context.NodeID    = Payload.NodeID;
		
		If GetPropertyOr(Payload, "Timeout") <> Undefined Then
			Context.Options.Timeout = Payload.Timeout;
		EndIf;
	EndIf;
	
	Response = CallEndpointHandler(Endpoint.Action.Handler, Context, LifecycleAction);
	
	Return NewServiceResponse(Response);
	
EndFunction

Function EventHandler(Payload)
	
EndFunction

Function SendLocalServicesInfo()        
	
	Services = GetServiceSchemas();
	
	Result = New Structure();
	Result.Insert("services", Services);
	
	Return NewServiceResponse(NewResponse(Undefined, Result));
	
EndFunction

Function NewServiceResponse(Response, Context = Undefined)
	
	IsError = IsError(Response);
	StatusCode = ?(IsError, Response.Error.Code, 200);

	ResponseBody = New Structure();
	If IsError Then
		ResponseBody.Insert("error", Response.Error);
	Else
		ResponseBody.Insert("result", Response.Result);
	EndIf;
	
	If Context <> Undefined Then      
		If Context.Property("Meta") Then
			ResponseBody.Insert("meta", Context.Meta);
		EndIf;
		ResponseBody.Insert("context", Context);	
	EndIf;
	
	Headers = New Map();
	Headers.Insert("content-type", "application/json");
	
	HTTPServiceResponse = New HTTPServiceResponse(StatusCode, , Headers); 
	ResponseString = mol_InternalHelpers.ToString(ResponseBody);
	mol_InternalHelpers.SetRequestResponseBody(HTTPServiceResponse, ResponseString);
		
	Return HTTPServiceResponse;
	
EndFunction
	
#EndRegion

#Region Broker

Function GetLocalActionEndpoint(Action)

	Result = New Structure();
	Result.Insert("Action", Action);
	
	Return Result;
		
EndFunction  

Function CallEndpointHandler(Handler, Context, Lifecycle = False)
	
	HandlerParts = StrSplit(Handler, ".");

	Parameters = New Array();
	Parameters.Add(Context);                              
	
	Result = Undefined;
	Error  = Undefined;
	
	Try
		If Lifecycle Then
			ExecuteModuleProcedure(HandlerParts[0], HandlerParts[1], Parameters); 		
		Else
			CallResult = ExecuteModuleFunction(HandlerParts[0], HandlerParts[1], Parameters);
			If IsError(CallResult) Then
				Error = Result.Error;
			ElsIf HasResult(CallResult) Then
				Result = CallResult.Result;
			Else
				Result = CallResult;
			EndIf;
		EndIf;
	Except   
		ErrorInfo = ErrorInfo();            
		Data = New Structure();
		Data.Insert("handler", Handler);
		Error = mol_Errors.RequestRejected("Service call endpoint error", Data, ErrorInfo);	
	EndTry; 
	
	Return NewResponse(Error, Result);
	
EndFunction

#EndRegion

#Region Context

Function CreateNewContext()

	Result = New Structure();
    // String - Context ID
    Result.Insert("id"         , ""); 
    // ServiceBroker - Instance of the broker.
    Result.Insert("broker"     , Undefined); 
    // String - The caller or target Node ID.
    Result.Insert("nodeID"     , ""); 
    // Object - Instance of action definition.
    Result.Insert("action"     , Undefined); 
    // Object - Instance of event definition.
    Result.Insert("event"      , Undefined); 
    // Object - The emitted event name.
    Result.Insert("eventName"  , Undefined); 
    // String - Type of event (“emit” or “broadcast”).
    Result.Insert("eventType"  , ""); 
    // Array<String> - Groups of event.
    Result.Insert("eventGroups", New Array()); 
    // String - Service full name of the caller. E.g.: v3.myService
    Result.Insert("caller"     , ""); 
    // String - Request ID. If you make nested-calls, it will be the same ID.
    Result.Insert("requestID"  , ""); 
    // String - Parent context ID (in nested-calls).
    Result.Insert("parentID"   , ""); 
    // Any - Request params. Second argument from broker.call.
    Result.Insert("params"     , Undefined); 
    // Any - Request metadata. It will be also transferred to nested-calls.
    Result.Insert("meta"       , Undefined); 
    // Any - Local data.
    Result.Insert("locals"     , Undefined); 
    // Number - Request level (in nested-calls). The first level is 1.
    Result.Insert("level"      , 1); 
    // Span - Current active span.
    Result.Insert("span"       , Undefined); 
	
	Result.Insert("tracing"    , Undefined);
	
	Result.Insert("options", New Structure());
	Result.Options.Insert("timeout", Undefined);
	
	Return Result;
	
EndFunction

Function SetContextEndpoint(Context, Endpoint)

	If Endpoint.Property("action") Then
		Context.Action = Endpoint.Action;
		Context.Event  = Undefined;
	ElsIf Endpoint.Property("event") Then 
		Context.Event  = Endpoint.Event;
		Context.Action = Undefined;	
	EndIf;
	
EndFunction

Function SetContextParams(Context, Params)
	Context.Params = Params;	
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
		If StrStartsWith(ModuleMetadata.Name, ServiceModulePrefix) Then
			If Not ModuleMetadata.Server Then  
				Message = StrTemplate(
					"Service module name ""%1"" does not have ""server"" flag and was skipped",
					ModuleMetadata.Name	
				);
				mol_Logger.Warn(Message);
				Continue;
			EndIf;
			Result.Add(ModuleMetadata.Name);		
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction
	
Function GetServiceSchemas(ForceUpdate = False) Export

	If ForceUpdate = False Then
		Return mol_InternalReuse.GetServiceSchemas();
	EndIf;
	
	Result = New Array(); 
	NodePrefix = Constants.mol_NodeName.Get();
	
	ModuleNames = GetServiceModuleNames();
	For Each ModuleName In ModuleNames Do
		Response = CompileServiceSchema(ModuleName);
		If IsError(Response) Then
			mol_Logger.Warn(Response.Error.Message, Response.Error.Data);
		    Continue;
		EndIf;   
		Schema = Response.Result;
		Schema.Name = NodePrefix + "." + Schema.Name; 
		
		Result.Add(Schema);
	EndDo;                          
	
	Return Result;
	
EndFunction


Function CompileServiceSchema(ModuleName) 
	
	BuilderModule = CommonModule("mol_SchemaBuilder");
	
	Parameters = New Array();
	Parameters.Add(BuilderModule.NewSchema(ModuleName));
	Parameters.Add(BuilderModule);

	Result = Undefined;
	Error  = Undefined;
	
	MainProcedureName = "Service"; 
	Try                            
		SetSafeMode(True);
		ExecuteModuleProcedure(ModuleName, MainProcedureName, Parameters);
		Schema = Parameters[0];		
		Schema.Delete("_ModuleName");
		
		// TODO: Validate service Schema
		Result = Schema
	Except                                                 
		ErrorInfo = ErrorInfo();
		ErrorMessage = StrTemplate("Couldn't compile service schema in module %1", ModuleName); 
		Error = mol_Errors.ServiceSchemaError(ErrorMessage, Undefined, ErrorInfo);	
	EndTry;
	
	Return NewResponse(Error, Result);
	
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

Function ExecuteModuleProcedure(Val _ModuleName, Val _ProcedureName, Val _Parameters = Undefined)
	
	_Args = BuildArgsString(_Parameters, "_Parameters");
	
	Execute StrTemplate("%1.%2(%3)", _ModuleName, _ProcedureName, _Args);
	
EndFunction

Function ExecuteModuleFunction(Val _ModuleName, Val _FunctionName, Val _Parameters = Undefined)
	
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

#Region Registration

Function NewNodeRegistrationInfo()

	Result = New Structure();
	Result.Insert("name"      , "");
	Result.Insert("connection", NewSidecarNodeConnectionInfo());
	Result.Insert("gateway"   , "");

	Return Result;
	
EndFunction   

Function NewSidecarNodeConnectionInfo()

	Result = New Structure();
	Result.Insert("endpoint" , "");
	Result.Insert("port"     , "");
	Result.Insert("useSSL"   , "");

	Result.Insert("accessToken", "");
	
	Return Result;

	Return Result;
	
EndFunction

#EndRegion

#Region Utils

Function GetPropertyOr(Object, Property, EmptyValue = Undefined)
	
	Value = Undefined;
	If TypeOf(Object) = Type("Structure") Then
		If Object.Property(Property, Value) Then 
			Return Value;
		EndIf;
	ElsIf TypeOf(Object) = Type("Map") Then
		Value = Object.Get(Property);
		If Value <> Undefined Then
			Return Value;
		EndIf;
	EndIf;
	
	Return EmptyValue
	
EndFunction

#EndRegion

#EndRegion 

