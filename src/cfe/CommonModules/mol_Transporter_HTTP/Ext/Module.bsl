
#Region Protected

Function Send(Packet, RequestID = Undefined, TraceHeaders = Undefined) Export
	
	ConnectionInfo = mol_Internal.GetSidecarConnectionSettings();
	
	Message = New Structure();
	Message.Insert("cmd", Packet.Type);
	Message.Insert("packet", Packet);
	Payload = GetBinaryDataFromString(
		mol_InternalHelpers.ToJSONString(Message), 
		TextEncoding.UTF8, 
		False
	);
	
	Headers = New Map();
	Headers.Insert("content-type"  , "application/json");
	Headers.Insert("content-length", Format(Payload.Size(), "NG=")); 
	
	If TraceHeaders <> Undefined Then      
		For Each KeyValue In TraceHeaders Do
			Headers.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	RequestParameters = NewRequestParameters();    
	RequestParameters.Method  = "POST";
	RequestParameters.Path    = "/message";
	RequestParameters.Query   = "";                   
	RequestParameters.Headers = Headers; 
	
	ReqOptions = NewRequestOptions(RequestParameters, ConnectionInfo);
	
	#Region AuthHeader
	
	Region      = "main";
	ServiceName = "moleculer";
	Sha256Sum   = mol_InternalHelpers.ToSha256(Payload);
	
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
	If mol_Internal.IsError(AuthorizationHeader) Then
		Return AuthorizationHeader;
	EndIf;   
	mol_Internal.Unwrap(AuthorizationHeader);
	ReqOptions.Headers.Insert("authorization", AuthorizationHeader); 
	
	#EndRegion
	
	Return PostHTTPRequest(ReqOptions, Payload);
	
EndFunction

Function Receive(HTTPServiceRequest) Export

	BodyString = HTTPServiceRequest.GetBodyAsString();
	Response = mol_Broker.Deserialize(BodyString);
	If mol_Internal.IsError(Response) Then
		mol_Logger.Error("Transporter_HTTP.Receive",
			"Malformed request body",
			BodyString,
			Metadata.CommonModules.mol_Transporter_HTTP
		);
		Return NewServiceResponse(
			mol_Errors.RequestRejected("Malformed request body", Response.Error)
		);
	EndIf;
	Request = Response.Result;
	
	Result = mol_Transit.MessageHandler(Request.Cmd, Request.Packet);
	Return NewServiceResponse(Result);
	
EndFunction

#EndRegion 

#Region Private

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
Function PostHTTPRequest(Options, Body)
	
	HTTPConnection = mol_InternalReuse.GetHTTPConnection(
		Options.Protocol,
		Options.Host,
		Options.Port,
		Options.Timeout
	);
	#If Server And Not Server Then
		HTTPConnection = New HTTPConnection();
	#EndIf
	
	HTTPRequest = New HTTPRequest(Options.Path, Options.Headers); 	
	mol_InternalHelpers.SetRequestResponseBody(HTTPRequest, Body);
	
	Response = mol_Internal.NewResponse();
	Try     
		Response.Result = HTTPConnection.Post(HTTPRequest);		
	Except
		Response.Error = mol_Errors.FromErrorInfo(ErrorInfo());
	EndTry;      
	
	Return Response;
	
EndFunction


Function NewRequestParameters()

	Result = New Structure();    
	Result.Insert("Method"    , Undefined);
	Result.Insert("Path"      , Undefined);
	Result.Insert("Headers"   , Undefined);
	Result.Insert("Query"     , Undefined);  
	
	Result.Insert("ConnectionInfo" , Undefined);
	Result.Insert("InvalidateCache", False);
	Result.Insert("Timeout"        , 60000);
	
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

Function NewServiceResponse(Packet)
	
	Headers = New Map();
	Headers.Insert("content-type", "application/json");
	
	HTTPServiceResponse = New HTTPServiceResponse(200, , Headers);
	ResponseString = mol_Broker.Serialize(Packet);
	mol_InternalHelpers.SetRequestResponseBody(HTTPServiceResponse, ResponseString);
		
	Return HTTPServiceResponse;
	
EndFunction

#EndRegion