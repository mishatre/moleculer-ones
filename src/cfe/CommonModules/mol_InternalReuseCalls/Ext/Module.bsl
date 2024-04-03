
#Region Protected

#Region ServiceBuilder

Function GetServiceSchemaContext() Export
	
	Result = New Structure();
	Result.Insert("Schema"    , Undefined);
	Result.Insert("ModuleName", Undefined);
	Result.Insert("Namespace" , Undefined);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Context

Function GetPendingRequests() Export
	Return New Map();
EndFunction

#EndRegion

#EndRegion

#Region Private

#EndRegion