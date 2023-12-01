
Function GetHTTPConnection(Protocol, Host, Port, Timeout) Export

	SecureConnection = Undefined;
	If Protocol = "https:" Then
		SecureConnection = New OpenSSLSecureConnection(); 
	EndIf;

	HTTPConnection = New HTTPConnection(
		Host,
		Port,
		, // User
		, // Password
		, // Proxy
		Timeout,
		SecureConnection
	);
	
	Return HTTPConnection;
	
EndFunction