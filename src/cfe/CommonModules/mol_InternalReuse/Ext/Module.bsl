
#Region Protected

Function GetHTTPConnection(Protocol, Host, Port, Timeout) Export
	
	ProxyServer = Undefined;
	If GetFunctionalOption("mol_UseProxyForConnection") Then
		ProxyServer = New InternetProxy(False);	   
		ProxyServer.Set(
			Constants.mol_ProxyProtocol.Get(),
			Constants.mol_ProxyServer.Get(),
			Constants.mol_ProxyPort.Get(),
			Constants.mol_ProxyUser.Get(),
			Constants.mol_ProxyPassword.Get()
		);	
	EndIf;
	
	SecureConnection = Undefined;
	If Protocol = "https:" Then
		SecureConnection = New OpenSSLSecureConnection(); 
	EndIf;

	HTTPConnection = New HTTPConnection(
		Host,
		Port,
		, // User
		, // Password
		ProxyServer,
		Timeout,
		SecureConnection
	);
	
	Return HTTPConnection;
	
EndFunction

#Region Settings

Function GetSidecarConnectionSettings() Export
	Return mol_Internal.GetSidecarConnectionSettings(True);	
EndFunction

#EndRegion  

#Region Schema

Function GetServiceModuleNames(ServiceModulePrefix) Export
	
	Return mol_Internal.GetServiceModuleNames(ServiceModulePrefix, True);
	
EndFunction

Function GetServiceSchemas() Export
	Return mol_Internal.GetServiceSchemas(True);	
EndFunction

#EndRegion

#EndRegion

#Region Private

#EndRegion