
#Region Public

#Region Constructors 

#Region Request

Function NewRequestParameters() Export

	Result = New Structure();    
	Result.Insert("method"    , Undefined);
	Result.Insert("path"      , Undefined);
	Result.Insert("headers"   , Undefined);
	Result.Insert("query"     , Undefined);
	Result.Insert("useSSL"    , Undefined);
	Result.Insert("endpoint"  , Undefined);
	Result.Insert("port"      , Undefined);
	Result.Insert("timeout"   , Undefined);
		
	Return Result;
	
EndFunction

Function NewRequestOptions(Val Options) Export
	
	Method     = Options.Method;    
	Headers    = Options.Headers;
    Query      = Options.Query; 
	Protocol   = ?(Options.UseSSL, "https:", "http:");
			
	ReqOptions = New Structure();
	ReqOptions.Insert("method"  , Method  );
	ReqOptions.Insert("headers" , New Map );
	ReqOptions.Insert("protocol", Protocol);
	ReqOptions.Insert("timeout" , Options.Timeout/1000);    
	
	Host = Options.Endpoint;
	Path = Options.Path;
	
	If StrFind(Host, "/") Then
		HostParts = StrSplit(Host, "/"); 
		Host = HostParts[0];  
		If StrEndsWith(HostParts[1], "/") Then
			HostParts[1] = Left(HostParts[1], StrLen(HostParts[1]) - 1);
		EndIf; 
		If Not StrStartsWith(Path, "/") Then
			Path = "/" + Path;
		EndIf;
		Path = "/" + HostParts[1] + Path;
	EndIf;
	
	Port = Undefined;
	If ValueIsFilled(Options.Port) Then
		Port = Options.Port;
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

#Region Schema

Function NewSchema() Export
	
	// Map is used to allow internal settings ($noVersionPrefix)

	Result = New Structure;
	Result.Insert("name"         , ""       ); 
	Result.Insert("fullName"     , ""       );
	Result.Insert("version"      , Undefined);
	Result.Insert("settings"     , New Map  );
	Result.Insert("dependencies" , New Array);
	Result.Insert("metadata"     , New Map  );
	Result.Insert("actions"      , New Map  );
	Result.Insert("methods"      , New Array);
	Result.Insert("hooks"        , New Array); 
	
	Result.Insert("events"       , New Map);     
	Result.Insert("created"      , Undefined);
	Result.Insert("started"      , Undefined);
	Result.Insert("stopped"      , Undefined);

	Result.Insert("channels"     , New Map  ); 
	
	Return Result;
	
EndFunction

Function NewActionSchema() Export
	
	Result = New Structure();
	Result.Insert("name"          , ""       ); // name?: string;
	Result.Insert("rest"          , Undefined); // rest?: RestSchema | RestSchema[] | string | string[]; 
	// Visibility property to control the visibility & callability of service actions.
	// - published, null - public action. It can be called locally, remotely and can be published via API Gateway
	// - public          - public action, can be called locally & remotely but not published via API GW
	// - protected       - can be called only locally (from local services)
	// - private         - can be called only internally (via this.actions.xy() inside service)
	Result.Insert("visibility"    , Undefined); // visibility?: "published" | "public" | "protected" | "private";
	Result.Insert("params"        , New Structure()); // params?: ActionParams;
	Result.Insert("cache"         , Undefined); // cache?: boolean | ActionCacheOptions;
	Result.Insert("handler"       , ""       );      
	Result.Insert("tracing"       , Undefined); // boolean | TracingActionOptions;
	Result.Insert("bulkhead"      , Undefined); // bulkhead?: BulkheadOptions;
	Result.Insert("circuitBreaker", Undefined); // circuitBreaker?: BrokerCircuitBreakerOptions;
	Result.Insert("retryPolicy"   , Undefined); // retryPolicy?: RetryPolicyOptions;
	Result.Insert("fallback"      , Undefined); // fallback?: string | FallbackHandler;
	Result.Insert("hooks"         , Undefined); // hooks?: ActionHooks;
	Result.Insert("version"       , Undefined);
	
	Result.Insert("description"   , ""       );
	
	Return Result;
	
EndFunction
                         
Function NewEventSchema() Export

	Result = New Structure();
	Result.Insert("name"       , ""       ); // name?: string;
	Result.Insert("group"      , Undefined); // group?: string;
	Result.Insert("params"     , Undefined); // params?: ActionParams;
	Result.Insert("tracing"    , Undefined); // tracing?: boolean | TracingEventOptions;
	Result.Insert("bulkhead"   , Undefined); // bulkhead?: BulkheadOptions;
	Result.Insert("handler"    , ""       );
	Result.Insert("context"    , True     ); // context?: boolean;
		
	Result.Insert("description", ""       );

	Return Result;
	
EndFunction

Function NewRestSchema() Export
	
	Result = New Structure();
	Result.Insert("path"    , Undefined); // path?: string;
	Result.Insert("method"  , Undefined); // method?: "GET" | "POST" | "DELETE" | "PUT" | "PATCH";
	Result.Insert("fullPath", Undefined); // fullPath?: string;
	Result.Insert("basePath", Undefined); // basePath?: string;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Connection

Function NewConnectionInfo() Export

	Result = New Structure();
	Result.Insert("endpoint" , "");
	Result.Insert("port"     , "");
	Result.Insert("useSSL"   , ""); 
	Result.Insert("pathStyle", "");
	Result.Insert("secretKey", "");
	Result.Insert("accessKey", "");
	Result.Insert("proxy"    , Undefined);
	Result.Insert("timeout"  , 0 );
	
	Return Result;
	
EndFunction

Function NewProxyConnectionInfo() Export

	Result = New Structure();
	Result.Insert("protocol", "");
	Result.Insert("server"  , "");
	Result.Insert("port"    , "");
	Result.Insert("user"    , "");
	Result.Insert("password", "");
		
	Return Result;
	
EndFunction

Function NewGatewayInfo() Export
	
	Result = New Structure();
	Result.Insert("endpoint");
	Result.Insert("port");
	Result.Insert("path");
	Result.Insert("useSSL");
	
	// See: NewGatewayAuthInfo()
	Result.Insert("auth");
	
	Return Result;
		
EndFunction  

Function NewGatewayAuthInfo(AuthType) Export
	
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

#Region Node 

Function NewNodeInfo() Export

	Result = New Structure();
	Result.Insert("instanceID", Undefined); 
	Result.Insert("metadata"  , Undefined); 
	Result.Insert("gateway"   , Undefined); 
	Result.Insert("client"    , NewNodeClientInfo()); 
	
	Return Result;
	
EndFunction 

Function NewNodeClientInfo() Export
	
	Result = New Structure();
	Result.Insert("type"       , Undefined); 
	Result.Insert("version"    , Undefined); 
	Result.Insert("moduleType" , Undefined); 
	Result.Insert("langVersion", Undefined);
	Result.Insert("langCompatibilityVersion", Undefined);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Response

Function NewResponse(Error = Undefined, Result = Undefined, Meta = Undefined) Export
	Response = New Structure();
	Response.Insert("Error" , Error );
	Response.Insert("Result", Result);
	Response.Insert("Meta"  , Meta  );
	Return Response;
EndFunction 

#EndRegion

#EndRegion

#Region Response

Function IsError(Response) Export

	If IsObject(Response) And 
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

	If IsObject(Response) And 
		Response.Property("Result") And
		Response.Result <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region HTTPConnection

Function GetSidecarHTTPConnection(Val Options = Undefined, Force = False) Export

	If Options = Undefined And Not Force Then
		mol_Reuse.GetSidecarHTTPConnection();	
	EndIf;   
	
	If Options = Undefined Then
		Options = mol_Broker.GetSidecarConnectionSettings();	
	EndIf;
	
	ProxyServer = Undefined;
	If Options.Property("Proxy") And Options.Proxy <> Undefined Then
		ProxyInfo = Options.Proxy;
		ProxyServer = New InternetProxy(False);	   
		ProxyServer.Set(
			ProxyInfo.Protocol,
			ProxyInfo.Server,
			ProxyInfo.Port,
			ProxyInfo.User,
			ProxyInfo.Password
		);	
	EndIf;
	
	SecureConnection = Undefined;
	If Options.UseSSL Then
		SecureConnection = New OpenSSLSecureConnection(); 
	EndIf;  
	
	Endpoint = Options.Endpoint;
	If StrFind(Endpoint, "/") Then
		EndopointParts = StrSplit(Endpoint, "/"); 
		Endpoint = EndopointParts[0];
	EndIf;

	HTTPConnection = New HTTPConnection(
		Endpoint,
		Options.Port,
		, // User
		, // Password
		ProxyServer,
		Options.Timeout,
		SecureConnection
	);
	
	Return HTTPConnection;
	
EndFunction

#EndRegion

#Region AWSSigningV4

// Returns the authorization header
//
// Parameters: 
// Request     - HTTPQuery - HTTP Request
// AccessKey   - String - Access key
// SecretKey   - String - Secret key
// Region      - String - Region
// RequestDate - Date   - Request date    
// Sha256sum   - String - Sha256sum
// ServiceName - String - Service name (optional, default = "")
// 
// Returns - String - Authorization header value
Function SignV4(Request, AccessKey, SecretKey, Region, RequestDate, Sha256sum, ServiceName = "") Export
	
	If Not IsObject(Request) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Request should be of type ""Structure""")
		);	
	EndIf;
	
	If Not IsString(AccessKey) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("AccessKey should be of type ""String""")
		);	
	EndIf;
	
	If Not IsString(SecretKey) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("SecretKey should be of type ""String""")
		);	
	EndIf;
	
	If Not IsString(Region) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf;
	
	If AccessKey = "" Then
		Return mol_Helpers.NewResponse(
			mol_Errors.AccessKeyRequiredError("AccessKey is required for signing")
		);
	EndIf;
	
	If SecretKey = "" Then
		Return mol_Helpers.NewResponse(
			mol_Errors.SecretKeyRequiredError("SecretKey is required for signing")
		);
	EndIf;
	
  	SignedHeaders     = GetSignedHeaders(Request.Headers);
	If SignedHeaders.Error <> Undefined Then Return SignedHeaders; Else SignedHeaders = SignedHeaders.Result; EndIf;
	
  	CanonicalRequest  = GetCanonicalRequest(Request.Method, Request.Path, Request.Headers, SignedHeaders, Sha256sum);
	If CanonicalRequest.Error <> Undefined Then Return CanonicalRequest; Else CanonicalRequest = CanonicalRequest.Result; EndIf;
	
	ServiceIdentifier = ?(ValueIsFilled(ServiceName), ServiceName, "s3");
  	StringToSign      = GetStringToSign(CanonicalRequest, RequestDate, Region, ServiceIdentifier);
	If StringToSign.Error <> Undefined Then Return StringToSign; Else StringToSign = StringToSign.Result; EndIf;	
	
  	SigningKey        = GetSigningKey(RequestDate, Region, SecretKey, ServiceIdentifier);
	If SigningKey.Error <> Undefined Then Return SigningKey; Else SigningKey = SigningKey.Result; EndIf;	
	
  	Credential        = GetCredential(AccessKey, Region, RequestDate, ServiceIdentifier);
	If Credential.Error <> Undefined Then Return Credential; Else Credential = Credential.Result; EndIf;	
	
  	Signature         = Lower(GetHexStringFromBinaryData(CreateHMAC(SigningKey, StringToSign)));

  	Result = StrTemplate(
		"%1 Credential=%2, SignedHeaders=%3, Signature=%4",
		"AWS4-HMAC-SHA256",
		Credential,
		Lower(StrConcat(SignedHeaders, ";")),
		Signature
	); 
	
	Return mol_Helpers.NewResponse(Undefined, Result);
	
EndFunction

// Returns the authorization header
//
// Parameters: 
// Request       - HTTPQuery - HTTP Request
// AccessKey     - String - Access key
// SecretKey     - String - Secret key
// Region        - String - Region
// RequestDate   - Date   - Request date    
// ContentSha256 - String - Sha256sum
// ServiceName   - String - Service name (optional, default = "s3")
// 
// Returns - String - Authorization header value
Function SignV4ByServiceName(Request, AccessKey, SecretKey, Region, RequestDate, ContentSha256, ServiceName = "s3") Export
	Return SignV4(Request, AccessKey, SecretKey, Region, RequestDate, ContentSha256, ServiceName);
EndFunction

// Returns a presigned URL string
//
// Parameters: 
// Request      - HTTPQuery         - HTTP Request
// AccessKey    - String            - Access key
// SecretKey    - String            - Secret key
// SessionToken - String, Undefined - Session token
// Region       - String            - Region
// RequestDate  - Date              - Request date    
// Expires      - Undefined         - URL expiration in seconds
// 
// Returns - String - URL string
Function PresignSignatureV4(Request, AccessKey, SecretKey, SessionToken = Undefined, Region, RequestDate, Expires) Export
	
	If Not IsObject(Request) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Request should be of type ""Structure""")
		);	
	EndIf;

	If Not IsString(AccessKey) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("AccessKey should be of type ""String""")
		);	
	EndIf; 

	If Not IsString(SecretKey) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("SecretKey should be of type ""String""")
		);	
	EndIf; 

	If Not IsString(Region) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf; 
	
	If AccessKey = "" Then
		Return mol_Helpers.NewResponse(
			mol_Errors.AccessKeyRequiredError("AccessKey is required for signing")
		);
	EndIf;
	
	If SecretKey = "" Then
		Return mol_Helpers.NewResponse(
			mol_Errors.SecretKeyRequiredError("SecretKey is required for signing")
		);
	EndIf;
  
	If Not IsNumber(Expires) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Expires should be of type ""Number""")
		);	
	EndIf;
  
	If Expires < 1 Then
		Return mol_Helpers.NewResponse(
			mol_Errors.ExpiresParamError("Expires param cannot be less than 1 seconds")
		);	
	EndIf;

	If Expires > 604800 Then
		Return mol_Helpers.NewResponse(
			mol_Errors.ExpiresParamError("Expires param cannot be greater than 7 days")
		);	
	EndIf;

	Iso8601Date   = MakeDateLong(RequestDate);
	SignedHeaders = GetSignedHeaders(Request.Headers);
	If SignedHeaders.Error <> Undefined Then Return SignedHeaders; EndIf;
	SignedHeaders = SignedHeaders.Result;
	
	Credential    = GetCredential(AccessKey, Region, RequestDate);
	If Credential.Error <> Undefined Then Return Credential; EndIf;
	Credential = Credential.Result;
	
	HashedPayload = "UNSIGNED-PAYLOAD";
  
	RequestQuery = New Array();
	RequestQuery.Add(StrTemplate("X-Amz-Algorithm=%1"    , "AWS4-HMAC-SHA256"));
	RequestQuery.Add(StrTemplate("X-Amz-Credential=%1"   , UriEscape(Credential)));
	RequestQuery.Add(StrTemplate("X-Amz-Date=%1"         , Iso8601Date));
	RequestQuery.Add(StrTemplate("X-Amz-Expires=%1"      , Format(Expires, "NG=")));
	RequestQuery.Add(StrTemplate("X-Amz-SignedHeaders=%1", UriEscape(Lower(StrConcat(SignedHeaders, ";")))));
	If SessionToken <> Undefined And SessionToken <> "" Then
		RequestQuery.Add(StrTemplate("X-Amz-Security-Token=%1", UriEscape(SessionToken)));
	EndIf;
  
	PathParts = StrSplit(Request.Path, "?");

	Resource = PathParts[0];
	Query = ?(PathParts.Count() = 2, PathParts[1], "");
	If Query <> "" Then
		Query = Query + "&" + StrConcat(RequestQuery, "&");
	Else
		Query = StrConcat(RequestQuery, "&");
	EndIf;
  
	Path = Resource + "?" + Query;
  
	CanonicalRequest = GetCanonicalRequest(Request.Method, Path, Request.Headers, SignedHeaders, HashedPayload);
	If CanonicalRequest.Error <> Undefined Then Return CanonicalRequest; EndIf;
	CanonicalRequest = CanonicalRequest.Result;
  
	StringToSign = GetStringToSign(CanonicalRequest, RequestDate, Region);
	If StringToSign.Error <> Undefined Then Return StringToSign; EndIf;
	StringToSign = StringToSign.Result;
	
	SigningKey   = GetSigningKey(RequestDate, Region, SecretKey);
	If SigningKey.Error <> Undefined Then Return SigningKey; EndIf;
	SigningKey = SigningKey.Result;
	
	Signature    = Lower(GetHexStringFromBinaryData(CreateHMAC(SigningKey, StringToSign)));
	
	Result = Request.Protocol + "//" + Request.Headers["host"] + Path + "&X-Amz-Signature=" + Signature;	
	Return mol_Helpers.NewResponse(Undefined, Result);

EndFunction

// Calculate the signature of the POST policy
//
// Parameters: 
// Region       - String - Region
// Date         - Date   - Request date    
// SecretKey    - String - Secret key
// PolicyBase64 - String - Policy encoded as base64 string
// 
// Returns - String - String signature
Function PostPresignSignatureV4(Region, Date, SecretKey, PolicyBase64) Export
	
	If Not IsString(Region) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf;
	
	If Not IsValidDate(Date) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Date should be of type ""Date""")
		);	
	EndIf;
	
	If Not IsString(SecretKey) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("SecretKey should be of type ""String""")
		);	
	EndIf; 
	
	If Not IsString(PolicyBase64) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("PolicyBase64 should be of type ""String""")
		);	
	EndIf;
	
  	SigningKey = GetSigningKey(Date, Region, SecretKey);
	If SigningKey.Error <> Undefined Then Return SigningKey; EndIf;
	SigningKey = SigningKey.Result;
	
  	Result = Lower(GetHexStringFromBinaryData(CreateHMAC(SigningKey, PolicyBase64)));  	
	Return mol_Helpers.NewResponse(Undefined, Result);

EndFunction

#EndRegion

#Region JWT

Function CreateOneTimeJWT(SecretKey, MoleculerUser) Export     
	
	ТокенДоступа = Новый ТокенДоступа; 
	ТокенДоступа.Эмитент = "ssl";     
	МассивПолучателей = Новый Массив;
    МассивПолучателей.Добавить(MoleculerUser);
	ТокенДоступа.Получатели = МассивПолучателей;     
	ТокенДоступа.КлючСопоставленияПользователя = MoleculerUser;
	ТокенДоступа.ВремяСоздания = ТекущаяУниверсальнаяДата() - Дата(1970,1,1,0,0,0); 
	ТокенДоступа.ВремяЖизни = 10; 
	ТокенДоступа.Подписать(АлгоритмПодписиТокенаДоступа.HS256, SecretKey); 
	
	Return String(ТокенДоступа);
	
EndFunction

Function CreateJWTAccessKey(SecretKey, MoleculerUser) Export     
	
	ТокенДоступа = Новый ТокенДоступа; 
	ТокенДоступа.Эмитент = "ssl";     
	МассивПолучателей = Новый Массив;
    МассивПолучателей.Добавить(MoleculerUser);
	ТокенДоступа.Получатели = МассивПолучателей;     
	ТокенДоступа.КлючСопоставленияПользователя = MoleculerUser;
	ТокенДоступа.ВремяСоздания = ТекущаяУниверсальнаяДата() - Дата(1970,1,1,0,0,0); 
	ТокенДоступа.ВремяЖизни = 315569520; 
	ТокенДоступа.Подписать(АлгоритмПодписиТокенаДоступа.HS256, SecretKey); 
	
	Return String(ТокенДоступа);
	
EndFunction

#EndRegion

#Region Crypto

Function CreateHMAC(Val Key_, Val Message, Val Algorithm = Undefined) Export

	If Algorithm = Undefined Then
		Algorithm = HashFunction.SHA256;
	EndIf;

	If IsString(Key_) Then
		Key_ = GetBinaryDataFromString(Key_, TextEncoding.UTF8, False);
	EndIf;
	If IsString(Message) Then
		Message = GetBinaryDataFromString(Message, TextEncoding.UTF8, False);
	EndIf;

	Return HMAC(Key_, Message, Algorithm);

EndFunction 

Function DataHashing(Val Algorithm, Val Data) Export

	If IsString(Data) Then
		Data = GetBinaryDataFromString(Data, TextEncoding.UTF8, False);
	EndIf;

	Hashing = New DataHashing(Algorithm);
	Hashing.Append(Data);

	Return Lower(GetHexStringFromBinaryData(Hashing.HashSum));

EndFunction

#EndRegion

#Region JSON

Function ToJSONString(Object, Format = False) Export
	
	If IsString(Object) Then
		Return Object;
	EndIf;  
	
	JSONWriterSettings = New JSONWriterSettings(, ?(Format, Chars.TAB, ""));
	
	JSONWriter = New JSONWriter();
	JSONWriter.SetString(JSONWriterSettings);
	WriteJSON(JSONWriter, Object, , "JSONTransfromUnsupportedTypes", mol_Helpers);
	Return JSONWriter.Close();
	
EndFunction

Function FromJSONString(StringResponse) Export
	
	Response = New Structure();
	Response.Insert("result", Undefined);
	Response.Insert("error" , Undefined);
	
	JSONReader = New JSONReader();
	
	Try
		JSONReader.SetString(StringResponse);
		Response.Result = ReadJSON(JSONReader, False);
		JSONReader.Close();
		
		Return Response; 
		 
	Except       
		JSONReader.Close();
		ErrorInfo = ErrorInfo();
		mol_Logger.Info("InternalHelpers.FromJSONString", "Couldn't parse JSON string using basic parser. Trying custom parser...", ErrorInfo, Metadata.CommonModules.mol_Helpers);				
	EndTry;
	
	JSONReader = New JSONReader();
	
	Try 
		JSONReader.SetString(StringResponse);
		Object = Undefined;
		ReadJSONCustom(JSONReader, Object);
		Response.Result = Object;
		JSONReader.Close(); 
		
		Return Response;
		
	Except
		ErrorInfo = ErrorInfo();
		mol_Logger.Info("InternalHelpers.FromJSONString", "Couldn't parse JSON string using custom parser. Bailing...", ErrorInfo, Metadata.CommonModules.mol_Helpers);	
	EndTry;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#Region Protected

Function Get(Structure, PropertyName, DefaultValue = Undefined) Export
	PropertyValue = Undefined;
	If Structure.Property(PropertyName, PropertyValue) Then
		Return PropertyValue;             
	EndIf;
	Return DefaultValue;
EndFunction

Function GetPropertyOr(Object, Property, EmptyValue = Undefined) Export
	
	Value = Undefined;
	If IsObject(Object) Or TypeOf(Object) = Type("FixedStructure") Then
		If Object.Property(Property, Value) Then 
			Return Value;
		EndIf;
	ElsIf IsMap(Object) Or TypeOf(Object) = Type("FixedMap") Then
		Value = Object.Get(Property);
		If Value <> Undefined Then
			Return Value;
		EndIf;
	EndIf;
	
	Return EmptyValue
	
EndFunction

#Region DynamicEvaluation

Function ExecuteModuleProcedure(Val _ModuleName, Val _ProcedureName, Val _Parameters = Undefined) Export
	
	_Args = BuildArgsString(_Parameters, "_Parameters");
	
	Execute StrTemplate("%1.%2(%3)", _ModuleName, _ProcedureName, _Args);
	
EndFunction

Function ExecuteModuleFunction(Val _ModuleName, Val _FunctionName, Val _Parameters = Undefined) Export
	
	_Args = BuildArgsString(_Parameters, "_Parameters");
	
	Return Eval(StrTemplate("%1.%2(%3)", _ModuleName, _FunctionName, _Args));
	
EndFunction

#EndRegion

#Region JSON

Function JSONTransfromUnsupportedTypes(Property, Value, AdditionalParameters, Cancel) Export
	
	If TypeOf(Value) = Type("UUID") Then
		Return String(Value);
	EndIf;  
	
	If TypeOf(Value) = Type("CommonModule") Then
		Return Undefined;
	EndIf;
	
	Return Value;
	
EndFunction

#EndRegion

#Region HTTP

Function GetGatewayPath(NodePublicationName) Export
	
	HTTPServiceMetadata = Metadata.HTTPServices.mol_Moleculer;
	
	RootURL     = HTTPServiceMetadata.RootURL; 
	GatewayPath = HTTPServiceMetadata.URLTemplates.DefaultGateway.Template;
	
	Return StrTemplate(
		"%1/hs/%2%3", 
		NodePublicationName,
		RootURL,
		StrReplace(GatewayPath, "{Type}", "")
	);
	
EndFunction

Function GetURLParameter(Request, ParameterName, DefaultValue = Undefined) Export

	Return GetPropertyOr(Request.URLParameters, ParameterName, DefaultValue);			
	
EndFunction

Function SetRequestResponseBody(HTTPRequestResponse, Body) Export

	If IsString(Body) Then
		HTTPRequestResponse.SetBodyFromString(Body, "UTF-8", ByteOrderMarkUse.DontUse);	
	ElsIf IsBinaryData(Body) Then
		HTTPRequestResponse.SetBodyFromBinaryData(Body);	
	EndIf;
	
EndFunction

#EndRegion

#Region Validation

Function IsObject(Value) Export
	Return TypeOf(Value) = Type("Structure");
EndFunction

Function IsString(Value) Export
	Return TypeOf(Value) = Type("String")
EndFunction

Function IsNumber(Value) Export
	Return TypeOf(Value) = Type("Number")	
EndFunction

Function IsBinaryData(Value) Export
	Return TypeOf(Value) = Type("BinaryData")	
EndFunction

Function IsValidDate(Value) Export
	Return TypeOf(Value) = Type("Date")	
EndFunction 

Function IsMap(Value) Export
	Return TypeOf(Value) = Type("Map")	
EndFunction

Function IsArray(Value) Export
	Return TypeOf(Value) = Type("Array")	
EndFunction

#EndRegion

Function MakeDateLong(Date = Undefined) Export 
	
	If Date = Undefined Then
		Date = CurrentUniversalDate();
	EndIf;
	
	Return Format(Date, "DF=yyyyMMddTHHmmssZ");	 
	
EndFunction 

Function MakeDateShort(Date = Undefined) Export 
	
	If Date = Undefined Then
		Date = CurrentUniversalDate();
	EndIf;
	
	Return Format(Date, "DF=yyyyMMdd");	 
	
EndFunction 

Function ToSha256(Payload) Export
	Return DataHashing(HashFunction.SHA256, Payload);
EndFunction

Function UriEscape(String) Export  
	Return EncodeString(String, StringEncodingMethod.URLEncoding, "UTF-8");		
EndFunction

Function UriResourceEscape(String) Export
	Return StrReplace(UriEscape(String), "%2F", "/");	
EndFunction

Function GetScope(Region, Date, ServiceName = "s3") Export
	Return StrTemplate("%1/%2/%3/aws4_request", MakeDateShort(date), region, serviceName);	
EndFunction

Function Match(Text, Pattern) Export

	// Simple patterns
	If StrFind(Pattern, "?") = 0 Then
		// Exact match (eg. "prefix.event")
		FirstStarPosition = StrFind(Pattern, "*");
		If FirstStarPosition = 0 Then 
			Return Pattern = Text;
		EndIf;
		
		// Eg. "prefix**"
		Length = StrLen(Pattern);
		If Length > 2 And Right(Pattern, 2) = "**" And FirstStarPosition > Length - 3 Then
			Pattern = Left(Pattern, Length - 2);
			Return StrStartsWith(Text, Pattern);
		EndIf;
		
		// Eg. "prefix*"
		If Length > 1 And Right(Pattern, 1) = "*" And FirstStarPosition > Length - 2 Then
			Pattern = Left(Pattern, Length - 1);
			If StrStartsWith(Text, Pattern) Then
				Return StrFind(Text, ".") = 0;
			EndIf;
			Return False;
		EndIf;

		// Accept simple text, without point character (*)
		If Length = 1 And FirstStarPosition = 0 Then
			Return StrFind(Text, ".") = 0;
		EndIf;

		// Accept all inputs (**)
		If Length = 2 And FirstStarPosition = 0 And Right(Pattern, 1) = 1 Then
			Return True;
		EndIf;
		
	EndIf;    
	
	// Regex (eg. "prefix.ab?cd.*.foo")
	RegEx = mol_Reuse.GetRegexCache(Pattern); 
	Return False;    
	//Result = StrFindAllByRegularExpression(Text, RegEx);
	//
	//Return Result.Count() <> 0;
	
EndFunction

#EndRegion 

#Region Private

#Region AWSSigningV4

// GetCanonicalRequest generate a canonical request of style.
// 
// Parameters:
// Method        - String          - HTTP Request method ("GET", "POST", "PUT", etc)
// Path          - String          - URL Path
// Headers       - Map             - Request headers
// SignedHeaders - Array Of String - Array of headers that must be signed
// HashedPayload - String          - Hashed payload
// 
// Returns:
//  String - Canonical request -
//    <HTTPMethod>\n
//    <CanonicalURI>\n
//    <CanonicalQueryString>\n
//    <CanonicalHeaders>\n
//    <SignedHeaders>\n
//    <HashedPayload>
//
Function GetCanonicalRequest(Method, Path, Headers, SignedHeaders, HashedPayload)
	
	If Not IsString(Method) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Method should be of type ""String""")
		);	
	EndIf;    
	
	If Not IsString(Path) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Path should be of type ""String""")
		);	
	EndIf;
	
	If Not IsMap(Headers) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Headers should be of type ""Map""")
		);	
	EndIf;
	
	If Not IsArray(SignedHeaders) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("SignedHeaders should be of type ""Array""")
		);	
	EndIf;
	
	If Not IsString(HashedPayload) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("HashedPayloa should be of type ""String""")
		);	
	EndIf; 
	
	HeadersArray = New Array();
	For Each HeaderName In SignedHeaders Do
		// Trim spaces from the value (required by V4 spec)
		Value = TrimAll(Headers[HeaderName]);
		HeadersArray.Add(StrTemplate("%1:%2", Lower(HeaderName), Value));
	EndDo;

	PathParts = StrSplit(Path, "?");
	
	FULL_QUERY_PARTS = 2;
	RequestResource = PathParts[0];
	RequestQuery = ?(PathParts.Count() = FULL_QUERY_PARTS, PathParts[1], "");   
	
	If RequestQuery <> "" Then
		
		QueryParts = StrSplit(RequestQuery, "&");
		QueryList  = New ValueList;
		For Each QueryPart In QueryParts Do
			KeyValue = StrSplit(QueryPart, "=");
			QueryList.Add(KeyValue[0], ?(KeyValue.Count() = FULL_QUERY_PARTS, KeyValue[1], ""));	
		EndDo;
		
		QueryList.SortByValue(SortDirection.Asc);  
		QueryParts = New Array();
		
		For Each QueryItem In QueryList Do
			QueryParts.Add(
				QueryItem.Value + "=" + ?(QueryItem.Presentation <> "", QueryItem.Presentation, "")
			);
		EndDo;
		
		RequestQuery = StrConcat(QueryParts, "&");
		
	EndIf; 
	
	RequestParts = New Array();
	RequestParts.Add(Upper(Method));
	RequestParts.Add(RequestResource);
	RequestParts.Add(RequestQuery);
	RequestParts.Add(StrConcat(HeadersArray, Chars.LF));
	RequestParts.Add("");
	RequestParts.Add(Lower(StrConcat(SignedHeaders, ";")));
	RequestParts.Add(HashedPayload);
	
	Result = StrConcat(RequestParts, Chars.LF);	
	Return mol_Helpers.NewResponse(Undefined, Result);
		
EndFunction

// Generate a credential string
//
// Parameters:
// AccessKey   - String            - Access key ID
// Region      - String            - Region
// RequestDate - Date              - Request date (optional)
// ServiceName - String, Undefined - Service name (optional, default "s3")
// 
// Returns:
//  String - Credential string
Function GetCredential(AccessKey, Region, RequestDate = Undefined, ServiceName = "s3")
	
	If Not IsString(AccessKey) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("AccessKey should be of type ""String""")
		);	
	EndIf;     
	
	If Not IsString(Region) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf; 
	
	If RequestDate <> Undefined And Not IsValidDate(RequestDate) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("RequestDate should be of type ""Date""")
		);	
	EndIf;     
	
	If Not IsString(ServiceName) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("ServiceName should be of type ""String""")
		);	
	EndIf;
	
  	Result = StrTemplate("%1/%2", AccessKey, GetScope(Region, RequestDate, ServiceName)); 	
	Return mol_Helpers.NewResponse(Undefined, Result);

EndFunction

// Returns signed headers array - alphabetically sorted
//
// Parameters:
// Headers - Map - Request headers
// 
// Returns:
//	Array Of String - Array of Names of signed headers
Function GetSignedHeaders(Headers)
	
	If Not IsMap(Headers) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Headers should be of type ""Map""")
		);	
	EndIf;
	
	// Excerpts from @lsegal - https://github.com/aws/aws-sdk-js/issues/659#issuecomment-120477258
	//
	//  User-Agent:
	//
	//      This is ignored from signing because signing this causes problems with generating pre-signed URLs
	//      (that are executed by other agents) or when customers pass requests through proxies, which may
	//      modify the user-agent.
	//
	//  Content-Length:
	//
	//      This is ignored from signing because generating a pre-signed URL should not provide a content-length
	//      constraint, specifically when vending a S3 pre-signed PUT URL. The corollary to this is that when
	//      sending regular requests (non-pre-signed), the signature contains a checksum of the body, which
	//      implicitly validates the payload length (since changing the number of bytes would change the checksum)
	//      and therefore this header is not valuable in the signature.
	//
	//  Content-Type:
	//
	//      Signing this header causes quite a number of problems in browser environments, where browsers
	//      like to modify and normalize the content-type header in different ways. There is more information
	//      on this in https://github.com/aws/aws-sdk-js/issues/244. Avoiding this field simplifies logic
	//      and reduces the possibility of future bugs
	//
	//  Authorization:
	//
	//      Is skipped for obvious reasons
	IgnoredHeaders = New Array();
	IgnoredHeaders.Add("authorization" );
	IgnoredHeaders.Add("content-length");
	IgnoredHeaders.Add("content-type"  );
	IgnoredHeaders.Add("user-agent"    ); 
	
	HeadersList = New ValueList;
	For Each KeyValue In Headers Do
		Header = KeyValue.Key;
		If IgnoredHeaders.Find(Header) = Undefined Then
			HeadersList.Add(Header);
		EndIf;
	EndDo;
	
	HeadersList.SortByValue(SortDirection.Asc);
	
	Result = HeadersList.UnloadValues(); 	
	Return mol_Helpers.NewResponse(Undefined, Result);

EndFunction 

// Returns the key used for calculating signature  
//
// Parameters:
// Date        - Date   - Request date    
// Region      - String - Region
// SecretKey   - String - S3 Secret key
// ServiceName - String - Service name (optional, default = "s3")
// 
// Returns:
//  BinaryData - 
Function GetSigningKey(Date, Region, SecretKey, ServiceName = "s3")
	
	If Not IsValidDate(Date) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Date should be of type ""Date""")
		);	
	EndIf;
	
	If Not IsString(Region) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf;
	
	If Not IsString(SecretKey) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("SecretKey should be of type ""String""")
		);	
	EndIf; 
	
	If Not IsString(ServiceName) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("ServiceName should be of type ""String""")
		);	
	EndIf;  
	
	DateLine = MakeDateShort(Date);
	
	HMAC1 = CreateHMAC("AWS4" + SecretKey, DateLine   );
	HMAC2 = CreateHMAC(HMAC1             , Region     );
	HMAC3 = CreateHMAC(HMAC2             , ServiceName);

	Result = CreateHMAC(HMAC3, "aws4_request");
	Return mol_Helpers.NewResponse(Undefined, Result);
	
EndFunction

// Returns the string that needs to be signed      
//
// Parameters:       
// CanonicalRequest - String - Canonical request
// RequestDate      - Date   - Request date    
// Region           - String - Region
// ServiceName      - String - Service name (optional, default = "s3")
// 
// Returns:
//  String - String that needs to be signed
Function GetStringToSign(CanonicalRequest, RequestDate, Region, ServiceName = "s3") 
	
	If Not IsString(CanonicalRequest) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("CanonicalRequest should be of type ""String""")
		);	
	EndIf;
	
	If Not IsValidDate(RequestDate) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("RequestDate should be of type ""Date""")
		);	
	EndIf;
	
	If Not IsString(Region) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf; 
	
	If Not IsString(ServiceName) Then
		Return mol_Helpers.NewResponse(
			mol_Errors.TypeError("ServiceName should be of type ""String""")
		);	
	EndIf;
		
	Hash  = DataHashing(HashFunction.SHA256, CanonicalRequest);
  	Scope = GetScope(Region, RequestDate, ServiceName);

	StringToSignParts = New Array();
	StringToSignParts.Add("AWS4-HMAC-SHA256");
	StringToSignParts.Add(MakeDateLong(RequestDate));
	StringToSignParts.Add(Scope);
	StringToSignParts.Add(Hash); 
	
	Result = StrConcat(StringToSignParts, Chars.LF);	      
	Return mol_Helpers.NewResponse(Undefined, Result);

EndFunction 

#EndRegion

#Region Crypto

// Calculates HMAC (hash-based message authentication code).
//
// Parameters:
//   Key_      - BinaryData   - secret key.
//   Data      - BinaryData   - data to calculate HMAC.
//   Algorithm - HashFunction - Defines method for calculating the hash-sum.
//
// Returns:
//   BinaryData - calculated HMAC value.
//
Function HMAC(Key_, Data, Algorithm)

	BlockSize = 64;

	If Key_.Size() > BlockSize Then
		Hashing = New DataHashing(Algorithm);
		Hashing.Append(Key_);

		BufferKey = GetBinaryDataBufferFromBinaryData(Hashing.HashSum);
	Else
		BufferKey = GetBinaryDataBufferFromBinaryData(Key_);
	EndIf;

	ModifiedKey = New BinaryDataBuffer(BlockSize);
	ModifiedKey.Write(0, BufferKey);

	InternalKey = ModifiedKey.Copy();
	ExternalKey = ModifiedKey;
                         
	InternalAlignment = mol_Reuse.GetAlignmentBuffer(BlockSize, 54); 
	ExternalAlignment = mol_Reuse.GetAlignmentBuffer(BlockSize, 92); 

	InternalHashing = New DataHashing(Algorithm);
	ExternalHashing = New DataHashing(Algorithm);

	InternalKey.WriteBitwiseXor(0, InternalAlignment);
	ExternalKey.WriteBitwiseXor(0, ExternalAlignment);

	ExternalHashing.Append(GetBinaryDataFromBinaryDataBuffer(ExternalKey));
	InternalHashing.Append(GetBinaryDataFromBinaryDataBuffer(InternalKey));

	If ValueIsFilled(Data) Then
		InternalHashing.Append(Data);
	EndIf;

	ExternalHashing.Append(InternalHashing.HashSum);

	Return ExternalHashing.HashSum;

EndFunction

#EndRegion

#Region JSON

Procedure ReadJSONCustom(JSONReader, Object)

	PropertyName = Undefined;
    
    While JSONReader.Read() Do
        JSONType = JSONReader.CurrentValueType;
        
        If JSONType = JSONValueType.ObjectStart 
        Or JSONType = JSONValueType.ArrayStart Then
            NewObject = ?(JSONType = JSONValueType.ObjectStart, New Structure, New Array);
			If PropertyName <> Undefined And (Lower(PropertyName) = "metadata" Or Lower(PropertyName) = "meta") Then
				NewObject = New Map();
			EndIf;
            
            ReadJSONCustom(JSONReader, NewObject);   
			
			If IsArray(Object) Then
                Object.Add(NewObject);
            ElsIf (IsObject(Object) Or IsMap(Object)) And ValueIsFilled(PropertyName) Then
                Object.Insert(PropertyName, NewObject);
            EndIf;
            
            If Object = Undefined Then
                Object = NewObject;
            EndIf;
        ElsIf JSONType = JSONValueType.PropertyName Then
            PropertyName = JSONReader.CurrentValue;     
			If IsObject(Object) And Not IsValidStructureName(PropertyName) Then
				NewMap = New Map();
				For Each KeyValue In Object Do
					NewMap.Insert(KeyValue.Key, KeyValue.Value); 	
				EndDo;
				Object = NewMap;
			EndIf;		
        ElsIf IsJSONPrimitive(JSONType) Then
            If IsArray(Object) Then
                Object.Add(JSONReader.CurrentValue);
            ElsIf (IsObject(Object) Or IsMap(Object)) Then
                Object.Insert(PropertyName, JSONReader.CurrentValue);
            EndIf;
        Else
            Return;
        EndIf;
    EndDo;
	
EndProcedure

Function IsJSONPrimitive(JSONType)
	Return JSONType = JSONValueType.Number 
        Or JSONType = JSONValueType.String 
        Or JSONType = JSONValueType.Boolean 
        Or JSONType = JSONValueType.Null;	
EndFunction  

Function IsValidStructureName(PropertyName)

	TempStructure = New Structure();
	Try
		TempStructure.Insert(PropertyName, Undefined);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Region DynamicEvaluation

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

#EndRegion