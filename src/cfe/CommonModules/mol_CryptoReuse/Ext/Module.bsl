
#Region Protected

Function GetAlignmentBuffer(BlockSize, Value) Export

	AlignmentBuffer = New BinaryDataBuffer(BlockSize);
	For Index = 0 To BlockSize - 1 Do
		AlignmentBuffer.Set(Index, Value);
	EndDo; 
	
	Return AlignmentBuffer;
	
EndFunction

#EndRegion