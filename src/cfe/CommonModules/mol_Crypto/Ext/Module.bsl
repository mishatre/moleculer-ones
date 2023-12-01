
#Region Public

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

#Region Private

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
                         
	InternalAlignment = mol_CryptoReuse.GetAlignmentBuffer(BlockSize, 54); // New BinaryDataBuffer(BlockSize);
	ExternalAlignment = mol_CryptoReuse.GetAlignmentBuffer(BlockSize, 92); // New BinaryDataBuffer(BlockSize);
	//For Index = 0 To BlockSize - 1 Do
	//	InternalAlignment.Set(Index, 54);
	//	ExternalAlignment.Set(Index, 92);
	//EndDo;

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