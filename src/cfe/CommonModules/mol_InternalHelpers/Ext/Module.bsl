﻿
#Region Public

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
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Request should be of type ""Structure""")
		);	
	EndIf;
	
	If Not IsString(AccessKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("AccessKey should be of type ""String""")
		);	
	EndIf;
	
	If Not IsString(SecretKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("SecretKey should be of type ""String""")
		);	
	EndIf;
	
	If Not IsString(Region) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf;
	
	If AccessKey = "" Then
		Return mol_Internal.NewResponse(
			mol_Errors.AccessKeyRequiredError("AccessKey is required for signing")
		);
	EndIf;
	
	If SecretKey = "" Then
		Return mol_Internal.NewResponse(
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
	
	Return mol_Internal.NewResponse(Undefined, Result);
	
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
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Request should be of type ""Structure""")
		);	
	EndIf;

	If Not IsString(AccessKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("AccessKey should be of type ""String""")
		);	
	EndIf; 

	If Not IsString(SecretKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("SecretKey should be of type ""String""")
		);	
	EndIf; 

	If Not IsString(Region) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf; 
	
	If AccessKey = "" Then
		Return mol_Internal.NewResponse(
			mol_Errors.AccessKeyRequiredError("AccessKey is required for signing")
		);
	EndIf;
	
	If SecretKey = "" Then
		Return mol_Internal.NewResponse(
			mol_Errors.SecretKeyRequiredError("SecretKey is required for signing")
		);
	EndIf;
  
	If Not IsNumber(Expires) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Expires should be of type ""Number""")
		);	
	EndIf;
  
	If Expires < 1 Then
		Return mol_Internal.NewResponse(
			mol_Errors.ExpiresParamError("Expires param cannot be less than 1 seconds")
		);	
	EndIf;

	If Expires > 604800 Then
		Return mol_Internal.NewResponse(
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
	Return mol_Internal.NewResponse(Undefined, Result);

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
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf;
	
	If Not IsValidDate(Date) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Date should be of type ""Date""")
		);	
	EndIf;
	
	If Not IsString(SecretKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("SecretKey should be of type ""String""")
		);	
	EndIf; 
	
	If Not IsString(PolicyBase64) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("PolicyBase64 should be of type ""String""")
		);	
	EndIf;
	
  	SigningKey = GetSigningKey(Date, Region, SecretKey);
	If SigningKey.Error <> Undefined Then Return SigningKey; EndIf;
	SigningKey = SigningKey.Result;
	
  	Result = Lower(GetHexStringFromBinaryData(CreateHMAC(SigningKey, PolicyBase64)));  	
	Return mol_Internal.NewResponse(Undefined, Result);

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

	If TypeOf(Key_) = Type("String") Then
		Key_ = GetBinaryDataFromString(Key_, TextEncoding.UTF8, False);
	EndIf;
	If TypeOf(Message) = Type("String") Then
		Message = GetBinaryDataFromString(Message, TextEncoding.UTF8, False);
	EndIf;

	Return HMAC(Key_, Message, Algorithm);

EndFunction 

Function DataHashing(Val Algorithm, Val Data) Export

	If TypeOf(Data) = Type("String") Then
		Data = GetBinaryDataFromString(Data, TextEncoding.UTF8, False);
	EndIf;

	Hashing = New DataHashing(Algorithm);
	Hashing.Append(Data);

	Return Lower(GetHexStringFromBinaryData(Hashing.HashSum));

EndFunction

#EndRegion

#EndRegion

#Region Protected

Function SetRequestResponseBody(HTTPRequestResponse, Body) Export

	If IsString(Body) Then
		HTTPRequestResponse.SetBodyFromString(Body, "UTF-8", ByteOrderMarkUse.DontUse);	
	ElsIf IsBinaryData(Body) Then
		HTTPRequestResponse.SetBodyFromBinaryData(Body);	
	EndIf;
	
EndFunction

Function Get(Structure, PropertyName, DefaultValue = Undefined) Export
	PropertyValue = Undefined;
	If Structure.Property(PropertyName, PropertyValue) Then
		Return PropertyValue;             
	EndIf;
	Return DefaultValue;
EndFunction

#Region JSONConversion

Function ToString(Object, Format = False) Export
	
	If IsString(Object) Then
		Return Object;
	EndIf;  
	
	JSONWriterSettings = New JSONWriterSettings(, ?(Format, Chars.TAB, ""));
	
	JSONWriter = New JSONWriter();
	JSONWriter.SetString(JSONWriterSettings);
	WriteJSON(JSONWriter, Object);
	Return JSONWriter.Close();
	
EndFunction

Function ParseMoleculerResponse(StringResponse) Export
	
	Response = New Structure();
	Response.Insert("result", Undefined);
	Response.Insert("error" , Undefined);
	Response.Insert("meta"  , Undefined);
	
	Try
		JSONReader = New JSONReader();
		JSONReader.SetString(StringResponse);  
		
		While JSONReader.Read() Do
			If JSONReader.CurrentValueType = JSONValueType.PropertyName Then
				If JSONReader.CurrentValue = "result" Then
					Response.result = ReadJSON(JSONReader);	
				ElsIf JSONReader.CurrentValue = "error" Then
					Response.Error = ReadJSON(JSONReader);	
				ElsIf JSONReader.CurrentValue = "meta" Then
					// Meta object can include field name that has incorrect key names (for 1C structure)
					Response.meta = ReadJSON(JSONReader, True);	
				EndIf;
			EndIf;
		EndDo; 
	Except
		Parsed = ParseMoleculerResponseCustom(StringResponse); 
		If Parsed.Property("result") Then 
			Response.Result = Parsed.Result;
		EndIf;
		If Parsed.Property("error") Then 
			Response.Error = Parsed.Error;
		EndIf;
		If Parsed.Property("meta") Then 
			Response.Meta = Parsed.Meta;
		EndIf;
	EndTry;
	
	Return Response;
	
EndFunction

Function ParseMoleculerResponseCustom(StringResponse)
	
	JSONReader = New JSONReader();
	JSONReader.SetString(StringResponse);   
	
	Result = Undefined;
	ParseJSONCustom(JSONReader, Result);
	
	Return Result;
	
EndFunction    

Procedure ParseJSONCustom(JSONReader, Object)

	PropertyName = Undefined;
    
    While JSONReader.Read() Do
        JSONType = JSONReader.CurrentValueType;
        
        If JSONType = JSONValueType.ObjectStart 
        Or JSONType = JSONValueType.ArrayStart Then
            NewObject = ?(JSONType = JSONValueType.ObjectStart, New Structure, New Array);
			If PropertyName <> Undefined And (Lower(PropertyName) = "metadata" Or Lower(PropertyName) = "meta") Then
				NewObject = New Map();
			EndIf;
            
            ParseJSONCustom(JSONReader, NewObject);   
			
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
            If TypeOf(Object) = Type("Array") Then
                Object.Add(JSONReader.CurrentValue);
            ElsIf (IsObject(Object) Or IsMap(Object)) Then
                Object.Insert(PropertyName, JSONReader.CurrentValue);
            EndIf;
        Else
            Return;
        EndIf;
    EndDo;
	
EndProcedure

Function FromString(String) Export
	
	Response = New Structure();
	Response.Insert("result", Undefined);
	Response.Insert("error" , Undefined);
	Response.Insert("meta"  , Undefined);
	
	JSONReader = New JSONReader();
	JSONReader.SetString(String);
	
	While JSONReader.Read() Do
		If JSONReader.CurrentValueType = JSONValueType.PropertyName Then
			If JSONReader.CurrentValue = "result" Then
				Response.result = ReadJSON(JSONReader);	
			ElsIf JSONReader.CurrentValue = "error" Then
				Response.Error = ReadJSON(JSONReader);	
			ElsIf JSONReader.CurrentValue = "meta" Then
				Response.meta = ReadJSON(JSONReader, True);	
			EndIf;
		EndIf;
	EndDo;
	
	//Object = ReadJSON(JSONReader);
	JSONReader.Close();
	
	Return Response;
	
EndFunction

Function BasicFromString(String) Export
	
	JSONReader = New JSONReader();
	JSONReader.SetString(String);
	Object = ReadJSON(JSONReader);	
	JSONReader.Close();
	
	Return Object;
	
EndFunction

#EndRegion

Function GetPropertyOr(Object, Property, EmptyValue = Undefined) Export
	
	Value = Undefined;
	If TypeOf(Object) = Type("Structure") Or TypeOf(Object) = Type("FixedStructure") Then
		If Object.Property(Property, Value) Then 
			Return Value;
		EndIf;
	ElsIf TypeOf(Object) = Type("Map") Or TypeOf(Object) = Type("FixedMap") Then
		Value = Object.Get(Property);
		If Value <> Undefined Then
			Return Value;
		EndIf;
	EndIf;
	
	Return EmptyValue
	
EndFunction

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

Function IsActionEnum(value) Export
	Return TypeOf(Value) = Type("EnumRef.mol_SidecarRegistryActions");	
EndFunction

#EndRegion

Function GetActionRequestParameters(Action) Export 

	ActionString = DerefEnumValue(Action, "Comment");
	ActionParts  = StrSplit(ActionString, " ");
	
	Result = New Structure();
	Result.Insert("Method", ActionParts[0]);
	Result.Insert("Path"  , ActionParts[1]);
	
	Return Result;
	
EndFunction

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

Function GetPayloadSize(Payload) Export
	
	If IsString(Payload) Then
		Return StrLen(Payload);
	EndIf;
	
	Return Payload.Size();
	
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

#EndRegion 

#Region Private

Function DerefEnumValue(EnumValue, FieldName = "Comment")
	
	EnumMetadata = EnumValue.Metadata();
	Manager = Enums[EnumMetadata.Name];
	Value   = EnumMetadata.EnumValues.Get(Manager.IndexOf(EnumValue))[FieldName];
	
	Return Value;
	
EndFunction

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
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Method should be of type ""String""")
		);	
	EndIf;    
	
	If Not IsString(Path) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Path should be of type ""String""")
		);	
	EndIf;
	
	If Not IsMap(Headers) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Headers should be of type ""Map""")
		);	
	EndIf;
	
	If Not IsArray(SignedHeaders) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("SignedHeaders should be of type ""Array""")
		);	
	EndIf;
	
	If Not IsString(HashedPayload) Then
		Return mol_Internal.NewResponse(
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
	Return mol_Internal.NewResponse(Undefined, Result);
		
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
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("AccessKey should be of type ""String""")
		);	
	EndIf;     
	
	If Not IsString(Region) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf; 
	
	If RequestDate <> Undefined And Not IsValidDate(RequestDate) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("RequestDate should be of type ""Date""")
		);	
	EndIf;     
	
	If Not IsString(ServiceName) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("ServiceName should be of type ""String""")
		);	
	EndIf;
	
  	Result = StrTemplate("%1/%2", AccessKey, GetScope(Region, RequestDate, ServiceName)); 	
	Return mol_Internal.NewResponse(Undefined, Result);

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
		Return mol_Internal.NewResponse(
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
	Return mol_Internal.NewResponse(Undefined, Result);

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
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Date should be of type ""Date""")
		);	
	EndIf;
	
	If Not IsString(Region) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf;
	
	If Not IsString(SecretKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("SecretKey should be of type ""String""")
		);	
	EndIf; 
	
	If Not IsString(ServiceName) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("ServiceName should be of type ""String""")
		);	
	EndIf;  
	
	DateLine = MakeDateShort(Date);
	
	HMAC1 = CreateHMAC("AWS4" + SecretKey, DateLine   );
	HMAC2 = CreateHMAC(HMAC1             , Region     );
	HMAC3 = CreateHMAC(HMAC2             , ServiceName);

	Result = CreateHMAC(HMAC3, "aws4_request");
	Return mol_Internal.NewResponse(Undefined, Result);
	
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
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("CanonicalRequest should be of type ""String""")
		);	
	EndIf;
	
	If Not IsValidDate(RequestDate) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("RequestDate should be of type ""Date""")
		);	
	EndIf;
	
	If Not IsString(Region) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf; 
	
	If Not IsString(ServiceName) Then
		Return mol_Internal.NewResponse(
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
	Return mol_Internal.NewResponse(Undefined, Result);

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
                         
	InternalAlignment = mol_InternalHelpersReuse.GetAlignmentBuffer(BlockSize, 54); 
	ExternalAlignment = mol_InternalHelpersReuse.GetAlignmentBuffer(BlockSize, 92); 

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

#EndRegion