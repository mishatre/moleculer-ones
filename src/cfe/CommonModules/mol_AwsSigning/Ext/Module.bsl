
#Region Public

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
	
	If Not mol_InternalHelpers.IsObject(Request) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Request should be of type ""Structure""")
		);	
	EndIf;
	
	If Not mol_InternalHelpers.IsString(AccessKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("AccessKey should be of type ""String""")
		);	
	EndIf;
	
	If Not mol_InternalHelpers.IsString(SecretKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("SecretKey should be of type ""String""")
		);	
	EndIf;
	
	If Not mol_InternalHelpers.IsString(Region) Then
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
	
  	Signature         = Lower(GetHexStringFromBinaryData(mol_Crypto.CreateHMAC(SigningKey, StringToSign)));

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
	
	If Not mol_InternalHelpers.IsObject(Request) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Request should be of type ""Structure""")
		);	
	EndIf;

	If Not mol_InternalHelpers.IsString(AccessKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("AccessKey should be of type ""String""")
		);	
	EndIf; 

	If Not mol_InternalHelpers.IsString(SecretKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("SecretKey should be of type ""String""")
		);	
	EndIf; 

	If Not mol_InternalHelpers.IsString(Region) Then
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
  
	If Not mol_InternalHelpers.IsNumber(Expires) Then
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

	Iso8601Date   = mol_InternalHelpers.MakeDateLong(RequestDate);
	SignedHeaders = GetSignedHeaders(Request.Headers);
	If SignedHeaders.Error <> Undefined Then Return SignedHeaders; EndIf;
	SignedHeaders = SignedHeaders.Result;
	
	Credential    = GetCredential(AccessKey, Region, RequestDate);
	If Credential.Error <> Undefined Then Return Credential; EndIf;
	Credential = Credential.Result;
	
	HashedPayload = "UNSIGNED-PAYLOAD";
  
	RequestQuery = New Array();
	RequestQuery.Add(StrTemplate("X-Amz-Algorithm=%1"    , "AWS4-HMAC-SHA256"));
	RequestQuery.Add(StrTemplate("X-Amz-Credential=%1"   , mol_InternalHelpers.UriEscape(Credential)));
	RequestQuery.Add(StrTemplate("X-Amz-Date=%1"         , Iso8601Date));
	RequestQuery.Add(StrTemplate("X-Amz-Expires=%1"      , Format(Expires, "NG=")));
	RequestQuery.Add(StrTemplate("X-Amz-SignedHeaders=%1", mol_InternalHelpers.UriEscape(Lower(StrConcat(SignedHeaders, ";")))));
	If SessionToken <> Undefined And SessionToken <> "" Then
		RequestQuery.Add(StrTemplate("X-Amz-Security-Token=%1", mol_InternalHelpers.UriEscape(SessionToken)));
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
	
	Signature    = Lower(GetHexStringFromBinaryData(mol_Crypto.CreateHMAC(SigningKey, StringToSign)));
	
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
	
	If Not mol_InternalHelpers.IsString(Region) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf;
	
	If Not mol_InternalHelpers.IsValidDate(Date) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Date should be of type ""Date""")
		);	
	EndIf;
	
	If Not mol_InternalHelpers.IsString(SecretKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("SecretKey should be of type ""String""")
		);	
	EndIf; 
	
	If Not mol_InternalHelpers.IsString(PolicyBase64) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("PolicyBase64 should be of type ""String""")
		);	
	EndIf;
	
  	SigningKey = GetSigningKey(Date, Region, SecretKey);
	If SigningKey.Error <> Undefined Then Return SigningKey; EndIf;
	SigningKey = SigningKey.Result;
	
  	Result = Lower(GetHexStringFromBinaryData(mol_Crypto.CreateHMAC(SigningKey, PolicyBase64)));  	
	Return mol_Internal.NewResponse(Undefined, Result);

EndFunction

#EndRegion

#Region Private

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
	
	If Not mol_InternalHelpers.IsString(Method) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Method should be of type ""String""")
		);	
	EndIf;    
	
	If Not mol_InternalHelpers.IsString(Path) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Path should be of type ""String""")
		);	
	EndIf;
	
	If Not mol_InternalHelpers.IsMap(Headers) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Headers should be of type ""Map""")
		);	
	EndIf;
	
	If Not mol_InternalHelpers.IsArray(SignedHeaders) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("SignedHeaders should be of type ""Array""")
		);	
	EndIf;
	
	If Not mol_InternalHelpers.IsString(HashedPayload) Then
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
	
	If Not mol_InternalHelpers.IsString(AccessKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("AccessKey should be of type ""String""")
		);	
	EndIf;     
	
	If Not mol_InternalHelpers.IsString(Region) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf; 
	
	If RequestDate <> Undefined And Not mol_InternalHelpers.IsValidDate(RequestDate) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("RequestDate should be of type ""Date""")
		);	
	EndIf;     
	
	If Not mol_InternalHelpers.IsString(ServiceName) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("ServiceName should be of type ""String""")
		);	
	EndIf;
	
  	Result = StrTemplate("%1/%2", AccessKey, mol_InternalHelpers.GetScope(Region, RequestDate, ServiceName)); 	
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
	
	If Not mol_InternalHelpers.IsMap(Headers) Then
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
	
	If Not mol_InternalHelpers.IsValidDate(Date) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Date should be of type ""Date""")
		);	
	EndIf;
	
	If Not mol_InternalHelpers.IsString(Region) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf;
	
	If Not mol_InternalHelpers.IsString(SecretKey) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("SecretKey should be of type ""String""")
		);	
	EndIf; 
	
	If Not mol_InternalHelpers.IsString(ServiceName) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("ServiceName should be of type ""String""")
		);	
	EndIf;  
	
	DateLine = mol_InternalHelpers.MakeDateShort(Date);
	
	HMAC1 = mol_Crypto.CreateHMAC("AWS4" + SecretKey, DateLine   );
	HMAC2 = mol_Crypto.CreateHMAC(HMAC1             , Region     );
	HMAC3 = mol_Crypto.CreateHMAC(HMAC2             , ServiceName);

	Result = mol_Crypto.CreateHMAC(HMAC3, "aws4_request");
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
	
	If Not mol_InternalHelpers.IsString(CanonicalRequest) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("CanonicalRequest should be of type ""String""")
		);	
	EndIf;
	
	If Not mol_InternalHelpers.IsValidDate(RequestDate) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("RequestDate should be of type ""Date""")
		);	
	EndIf;
	
	If Not mol_InternalHelpers.IsString(Region) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("Region should be of type ""String""")
		);	
	EndIf; 
	
	If Not mol_InternalHelpers.IsString(ServiceName) Then
		Return mol_Internal.NewResponse(
			mol_Errors.TypeError("ServiceName should be of type ""String""")
		);	
	EndIf;
		
	Hash  = mol_Crypto.DataHashing(HashFunction.SHA256, CanonicalRequest);
  	Scope = mol_InternalHelpers.GetScope(Region, RequestDate, ServiceName);

	StringToSignParts = New Array();
	StringToSignParts.Add("AWS4-HMAC-SHA256");
	StringToSignParts.Add(mol_InternalHelpers.MakeDateLong(RequestDate));
	StringToSignParts.Add(Scope);
	StringToSignParts.Add(Hash); 
	
	Result = StrConcat(StringToSignParts, Chars.LF);	      
	Return mol_Internal.NewResponse(Undefined, Result);

EndFunction 

#EndRegion
