
#Region Protected

#Region Crypto

Function GetAlignmentBuffer(BlockSize, Value) Export

	AlignmentBuffer = New BinaryDataBuffer(BlockSize);
	For Index = 0 To BlockSize - 1 Do
		AlignmentBuffer.Set(Index, Value);
	EndDo; 
	
	Return AlignmentBuffer;
	
EndFunction

#EndRegion

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