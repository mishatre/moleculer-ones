
#Region Protected 

#Region Settings

Function GetSidecarConnectionSettings() Export
	Return mol_Broker.GetSidecarConnectionSettings(True);	
EndFunction

#EndRegion

#Region HTTPConnection

Function GetSidecarHTTPConnection() Export
	mol_Helpers.GetSidecarHTTPConnection(Undefined, True);	
EndFunction

#EndRegion   

#Region Broker

Function NodeID() Export
	Return mol_Broker.NodeID(True);	
EndFunction

#EndRegion

#Region Schema

Function GetServiceSchemas() Export
	Return mol_Broker.GetServiceSchemas(True);	
EndFunction

#EndRegion

#Region Crypto

Function GetAlignmentBuffer(BlockSize, Value) Export

	AlignmentBuffer = New BinaryDataBuffer(BlockSize);
	For Index = 0 To BlockSize - 1 Do
		AlignmentBuffer.Set(Index, Value);
	EndDo; 
	
	Return AlignmentBuffer;
	
EndFunction

#EndRegion

#Region Regex

Function GetRegexCache(Pattern) Export

	If StrStartsWith(Pattern, "$") Then
		Pattern = "\\" + Pattern;
	EndIf;
	
	Pattern = StrReplace(Pattern, "?", ".");
	Pattern = StrReplace(Pattern, "**", "§§§");
	Pattern = StrReplace(Pattern, "*", "[^\\.]*");
	Pattern = StrReplace(Pattern, "§§§", ".*");

	Pattern = "^" + Pattern + "$";
	
	Return Pattern;
	
EndFunction

#EndRegion

#Region Logger

Function GetLogLevel() Export

	Return mol_Logger.GetLogLevel(True);
	
EndFunction

#EndRegion

#EndRegion