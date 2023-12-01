
#Region Protected

Function SetHTTPBody(HTTPRequestResponse, Body) Export

	If IsString(Body) Then
		HTTPRequestResponse.SetBodyFromString(Body);	
	ElsIf IsBinaryData(Body) Then
		HTTPRequestResponse.SetBodyFromBinaryData(Body);	
	EndIf;
	
EndFunction

Function Get(Structure, PropertyName, DefaultValue = Undefined) Export
	PropertyValue = Undefined;
	If Structure.Property(PropertyName, PropertyValue) Then
		Return PropertyValue;             
	EndIf;
	Return DefaultValue;
EndFunction

#Region JSONConversion

Function ToString(Object, Format = False) Export
	
	If IsString(Object) Then
		Return Object;
	EndIf;  
	
	JSONWriterSettings = New JSONWriterSettings(, ?(Format, Chars.TAB, ""));
	
	JSONWriter = New JSONWriter();
	JSONWriter.SetString(JSONWriterSettings);
	WriteJSON(JSONWriter, Object);
	Return JSONWriter.Close();
	
EndFunction

Function FromString(String) Export
	
	Response = New Structure();
	Response.Insert("result", Undefined);
	Response.Insert("error" , Undefined);
	Response.Insert("meta"  , Undefined);
	
	JSONReader = New JSONReader();
	JSONReader.SetString(String);
	
	While JSONReader.Read() Do
		If JSONReader.CurrentValueType = JSONValueType.PropertyName Then
			If JSONReader.CurrentValue = "result" Then
				Response.result = ReadJSON(JSONReader);	
			ElsIf JSONReader.CurrentValue = "error" Then
				Response.Error = ReadJSON(JSONReader);	
			ElsIf JSONReader.CurrentValue = "meta" Then
				Response.meta = ReadJSON(JSONReader, True);	
			EndIf;
		EndIf;
	EndDo;
	
	//Object = ReadJSON(JSONReader);
	JSONReader.Close();
	
	Return Response;
	
EndFunction

Function BasicFromString(String) Export
	
	JSONReader = New JSONReader();
	JSONReader.SetString(String);
	Object = ReadJSON(JSONReader);	
	JSONReader.Close();
	
	Return Object;
	
EndFunction

#EndRegion

#Region Validation

Function IsObject(Value) Export
	Return TypeOf(Value) = Type("Structure");
EndFunction

Function IsString(Value) Export
	Return TypeOf(Value) = Type("String")
EndFunction

Function IsNumber(Value) Export
	Return TypeOf(Value) = Type("Number")	
EndFunction

Function IsBinaryData(Value) Export
	Return TypeOf(Value) = Type("BinaryData")	
EndFunction

Function IsValidDate(Value) Export
	Return TypeOf(Value) = Type("Date")	
EndFunction 

Function IsMap(Value) Export
	Return TypeOf(Value) = Type("Map")	
EndFunction

Function IsArray(Value) Export
	Return TypeOf(Value) = Type("Array")	
EndFunction

Function IsActionEnum(value) Export
	Return TypeOf(Value) = Type("EnumRef.mol_SidecarRegistryActions");	
EndFunction

#EndRegion

Function GetActionRequestParameters(Action) Export 

	ActionString = DerefEnumValue(Action, "Comment");
	ActionParts  = StrSplit(ActionString, " ");
	
	Result = New Structure();
	Result.Insert("Method", ActionParts[0]);
	Result.Insert("Path"  , ActionParts[1]);
	
	Return Result;
	
EndFunction

Function MakeDateLong(Date = Undefined) Export 
	
	If Date = Undefined Then
		Date = CurrentUniversalDate();
	EndIf;
	
	Return Format(Date, "DF=yyyyMMddTHHmmssZ");	 
	
EndFunction 

Function MakeDateShort(Date = Undefined) Export 
	
	If Date = Undefined Then
		Date = CurrentUniversalDate();
	EndIf;
	
	Return Format(Date, "DF=yyyyMMdd");	 
	
EndFunction 

Function ToSha256(Payload) Export
	Return mol_Crypto.DataHashing(HashFunction.SHA256, Payload);
EndFunction

Function GetPayloadSize(Payload) Export
	
	If IsString(Payload) Then
		Return StrLen(Payload);
	EndIf;
	
	Return Payload.Size();
	
EndFunction

Function UriEscape(String) Export  
	Return EncodeString(String, StringEncodingMethod.URLEncoding, "UTF-8");		
EndFunction

Function UriResourceEscape(String) Export
	Return StrReplace(UriEscape(String), "%2F", "/");	
EndFunction

Function GetScope(Region, Date, ServiceName = "s3") Export
	Return StrTemplate("%1/%2/%3/aws4_request", mol_InternalHelpers.MakeDateShort(date), region, serviceName);	
EndFunction

#EndRegion 

#Region Private

Function DerefEnumValue(EnumValue, FieldName = "Comment")
	
	EnumMetadata = EnumValue.Metadata();
	Manager = Enums[EnumMetadata.Name];
	Value   = EnumMetadata.EnumValues.Get(Manager.IndexOf(EnumValue))[FieldName];
	
	Return Value;
	
EndFunction

#EndRegion