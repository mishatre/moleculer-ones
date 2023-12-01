
Function NewConnectionInfo() Export 

	Result = New Structure();
	Result.Insert("endpoint" , "");
	Result.Insert("port"     , "");
	Result.Insert("useSSL"   , "");
	Result.Insert("secretKey", "");
	Result.Insert("accessKey", "");
	
	Return Result;
	
EndFunction

Function GetConnectionInfo() Export
	
	Result = NewConnectionInfo();
	
	Result.Endpoint  = Constants.mol_Endpoint.Get();
	Result.Port      = Constants.mol_Port.Get();
	Result.UseSSL    = Constants.mol_UseSSL.Get();
	Result.SecretKey = Constants.mol_SecretKey.Get();
	Result.AccessKey = Constants.mol_AccessKey.Get();
	
	Return Result;
	
EndFunction

Function GetNodeConnectionInfo() Export
	
	Result = NewConnectionInfo();
	
	Result.Endpoint  = Constants.mol_NodeEndpoint.Get();
	Result.Port      = Constants.mol_NodePort.Get();
	Result.UseSSL    = Constants.mol_NodeUseSSL.Get();
	//Result.SecretKey = Constants.mol_SecretKey.Get();
	//Result.AccessKey = Constants.mol_AccessKey.Get();
	
	Return Result;
	
EndFunction

#Region Protected

Function NewResponse(Error = Undefined, Result = Undefined, AdditionalData = Undefined) Export
	Response = New Structure();
	Response.Insert("Error"         , Error         );
	Response.Insert("Result"        , Result        );
	Response.Insert("AdditionalData", AdditionalData);
	Return Response;
EndFunction 

Function IsError(Response) Export
	
	If Response.Error <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
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
		ConnectionInfo = GetConnectionInfo();
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
	AuthorizationHeader = mol_AwsSigning.SignV4(
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
	
	ResponseData = mol_InternalHelpers.FromString(Result.GetBodyAsString());  
	Return NewResponse(ResponseData.Error, ResponseData.Result, Response.AdditionalData);
	
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
	mol_InternalHelpers.SetHTTPBody(HTTPRequest, Body);
	
	Result         = Undefined;
	Error          = Undefined; 
	AdditionalData = New Structure();
	Try     
		Time1 = CurrentUniversalDateInMilliseconds();
		Result = HTTPConnection.CallHTTPMethod(Options.Method, HTTPRequest);
		Time2 = CurrentUniversalDateInMilliseconds();		
	Except
		Time2 = CurrentUniversalDateInMilliseconds(); 
		ErrorInfo = ErrorInfo();
		Error = mol_Errors.FromErrorInfo(ErrorInfo);
	EndTry;      
	
    AdditionalData.Insert("elapsedTime", Time2 - Time1);
	Return NewResponse(Error, Result, AdditionalData);
	
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



#EndRegion 

