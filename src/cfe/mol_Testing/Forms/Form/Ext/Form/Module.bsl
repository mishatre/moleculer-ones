
&AtServer
Procedure SendDiscoverAtServer()
	Response = mol_Transit.DiscoverNodes();
	
	JSONResponse.SetText(mol_Helpers.ToJSONString(Response, True));
	
EndProcedure

&AtClient
Procedure SendDiscover(Command)
	SendDiscoverAtServer();
EndProcedure

&AtServer
Procedure ConnectNodeAtServer()
	Response = mol_Transit.SendNodeInfo();
	
	JSONResponse.SetText(mol_Helpers.ToJSONString(Response, True));
EndProcedure

&AtClient
Procedure ConnectNode(Command)
	ConnectNodeAtServer();
EndProcedure

&AtServer
Procedure DisconnectAtServer()
	Response = mol_Transit.Disconnect();
	
	JSONResponse.SetText(mol_Helpers.ToJSONString(Response, True));
EndProcedure

&AtClient
Procedure Disconnect(Command)
	DisconnectAtServer();
EndProcedure
