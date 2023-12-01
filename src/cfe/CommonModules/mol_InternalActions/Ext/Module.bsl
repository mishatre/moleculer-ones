
#Region Protected

Function RegisterSidecarNode() Export 
	
	RegistrationInfo   = NewRegistrationInfo();      
	ConnectionInfo     = mol_Internal.GetConnectionInfo();
	NodeConnectionInfo = mol_Internal.GetNodeConnectionInfo();
	
	RegistrationInfo.NodeID = Constants.mol_NodeID.Get(); 
	RegistrationInfo.Path   = mol_Gateway.BuildGatewayPath(RegistrationInfo.NodeID);   
	
	FillPropertyValues(RegistrationInfo, NodeConnectionInfo);
	RegistrationInfo.access_token = mol_JWTSigning.CreateOneTimeToken(ConnectionInfo.SecretKey);
		
	Params = New Structure();
	Response = Mol.Call("$sidecar.registerExternalNode", RegistrationInfo);
		
	Return Response;
	
EndFunction

#EndRegion

#Region Private

Function NewRegistrationInfo()
	
	Result = New Structure();
	Result.Insert("nodeId"      , "");
	Result.Insert("endpoint"    , "");
	Result.Insert("port"        , 80);
	Result.Insert("useSSL"      , False);
	Result.Insert("path"        , "");  
	Result.Insert("access_token", "");
	
	Return Result;
	
EndFunction     

#EndRegion