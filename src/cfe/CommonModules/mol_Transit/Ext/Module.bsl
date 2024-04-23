
#Region Public

Function DiscoverNodes() Export
	
	Response = Send(mol_PacketFactory.Discover());
 	If mol_Helpers.IsError(Response) Then
		mol_Logger.Error("Transporters.DiscoverNode",
			"Unable to send DISCOVER packet.",
			Response.Error,
			Metadata.CommonModules.mol_Transit
		);
	EndIf;
	mol_Helpers.Unwrap(Response);
	
	Return MessageHandler(Response.Type, Response);
	
EndFunction

Function Disconnect() Export
	
	Response = Send(mol_PacketFactory.Disconnect("sidecar"));
 	If mol_Helpers.IsError(Response) Then
		mol_Logger.Error("Transporters.DiscoverNode",
			"Unable to send DISCOVER packet.",
			Response.Error,
			Metadata.CommonModules.mol_Transit
		);
	EndIf;
	mol_Helpers.Unwrap(Response);
	
	Return Response;
	
EndFunction

Function Request(Context) Export 
		
	Request = New Structure();                              
	Request.Insert("action" , Context.Action);
	Request.Insert("nodeID" , Context.NodeID);
	Request.Insert("context", Context);
	
	PendingRequests = mol_ReuseCalls.GetPendingRequests();
	PendingRequests.Insert(Context.Id, Request);
	
	Response = Send(mol_PacketFactory.Request(Context));
 	If mol_Helpers.IsError(Response) Then
		mol_Logger.Error("Transit.Request",
			StrTemplate(
				"Unable to send '%1' response to '%2' node.",
				Context.Id, 
				Context.NodeID,
			),
			Response.Error,
			Metadata.CommonModules.mol_Transit
		);
		Return Response;
	EndIf;
	mol_Helpers.Unwrap(Response);
	
	Return MessageHandler(Response.Type, Response);
		
EndFunction 

Function SendEvent(Context) Export
	
	Response = Send(mol_PacketFactory.Event(Context));
	If mol_Helpers.IsError(Response) Then
		mol_Logger.Error("Transit.SendEvent",
			StrTemplate(
				"Unable to send '%1' event to '%2' node.",
				Context.Id, 
				Context.NodeID,
			),
			Response.Error,
			Metadata.CommonModules.mol_Transit
		);      
		
		// mol_Broker.BroadcastLocal("$sidecar-transit.error");
	EndIf;
	mol_Helpers.Unwrap(Response);
	
	Return Response;
	
EndFunction

Function SendChannelEvent(ChannelName, Data, Opts = Undefined) Export 
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;
	
	Target = "sidecar";
	Response = Send(mol_PacketFactory.ChannelEvent(Target, ChannelName, Data, Opts));
	If mol_Helpers.IsError(Response) Then
		mol_Logger.Error("Transit.SendChannelEvent",
			StrTemplate(
				"Unable to send '%1' channel event to '%2' node.",
				ChannelName, 
				Target,
			),
			Response.Error,
			Metadata.CommonModules.mol_Transit
		);      
		
		// mol_Broker.BroadcastLocal("$sidecar-transit.error");
	EndIf;
	mol_Helpers.Unwrap(Response);
	
	Return Response;
	
EndFunction

Function SendNodeInfo() Export
	
	Target = "sidecar";
	Response = Send(mol_PacketFactory.Info(Target, mol_Broker.GetNodeInfo()));
	If mol_Helpers.IsError(Response) Then
		mol_Logger.Error("Transit.SendNodeInfo",
			StrTemplate(
				"Unable to send INFO packet to '%2' node.",
				Target,
			),
			Response.Error,
			Metadata.CommonModules.mol_Transit
		);      
		
		// mol_Broker.BroadcastLocal("$sidecar-transit.error");
	EndIf;
	mol_Helpers.Unwrap(Response);
	
	Return Response;
	
EndFunction

Function SendPing(Id = Undefined) Export
	
	Target = "sidecar";
	Response = Send(mol_PacketFactory.Ping(Target, Id));
 	If mol_Helpers.IsError(Response) Then
		mol_Logger.Error("Transit.SendPing",
			StrTemplate("Unable to send PING packet to '%1' node.", Target),
			Response.Error,
			Metadata.CommonModules.mol_Transit
		);
	EndIf;
	mol_Helpers.Unwrap(Response);
	
	Return MessageHandler(Response.Type, Response);
	
EndFunction

#EndRegion

#Region Protected

Function Send(Packet)
		
	Message = mol_Helpers.ToJSONString(Packet);
	
	Response = Undefined;
	If True Then // If Transporter = "Transporter_HTTP" Then 
		
		TraceHeaders = New Map();
		If Packet.Type = "PACKET_REQUEST" Then
			TraceHeaders.Insert("x-trace-span-name", "action " + Packet.Payload.Action);
			TraceHeaders.Insert("x-trace-parent-id", Packet.Payload.ParentID);
			TraceHeaders.Insert("x-trace-id"       , Packet.Payload.RequestID);	   
		EndIf;
		
		Response = Transporter_HTTP_Send(Message, TraceHeaders);
		
	EndIf;
	
	If mol_Helpers.IsError(Response) Then
		Return Response;
	EndIf;    
	mol_Helpers.Unwrap(Response);
	
	Response = mol_Broker.Deserialize(Response.GetBodyAsString());
	
	Return Response;
	
EndFunction

#Region Transporters

#Region TransporterHTTP

Function Transporter_HTTP_Send(Message, Headers = Undefined)
		
	Payload = GetBinaryDataFromString(Message, TextEncoding.UTF8, False);
	
	If Not mol_Helpers.IsMap(Headers) Then
		Headers = New Map();
	EndIf;
	
	Headers.Insert("content-type"  , "application/json");
	Headers.Insert("content-length", Format(Payload.Size(), "NG=")); 
	
	ConnectionInfo = mol_Broker.GetSidecarConnectionSettings();
	
	RequestParameters = mol_Helpers.NewRequestParameters(); 
	RequestParameters.Endpoint = ConnectionInfo.Endpoint;
	RequestParameters.Port     = ConnectionInfo.Port;
	RequestParameters.UseSSL   = ConnectionInfo.UseSSL;
	RequestParameters.Timeout  = ConnectionInfo.Timeout;
	RequestParameters.Headers  = Headers;
	RequestParameters.Method   = "POST";
	RequestParameters.Path     = "/v1/message";
	RequestParameters.Query    = "";                    
	
	Options = mol_Helpers.NewRequestOptions(RequestParameters);
	
	#Region AuthHeader
	
	Region      = "main";
	ServiceName = "moleculer";
	Sha256Sum   = mol_Helpers.ToSha256(Payload);
	
	Date = CurrentUniversalDate(); 
	Options.Headers.Insert("x-amz-date"          , mol_Helpers.MakeDateLong(date));
	Options.Headers.Insert("x-amz-content-sha256", Sha256Sum);
	AuthorizationHeader = mol_Helpers.SignV4(
		Options, 
		ConnectionInfo.AccessKey, 
		ConnectionInfo.SecretKey, 
		Region, 
		Date, 
		Sha256Sum,
		ServiceName
	);      
	If mol_Helpers.IsError(AuthorizationHeader) Then
		Return AuthorizationHeader;
	EndIf;   
	mol_Helpers.Unwrap(AuthorizationHeader);
	Options.Headers.Insert("authorization", AuthorizationHeader); 
	
	#EndRegion
	
	Return PostHTTPRequest(Options, Payload);
	
EndFunction

Function Transporter_HTTP_Receive(HTTPServiceRequest) Export
	
	BodyString = HTTPServiceRequest.GetBodyAsString();
	Response = mol_Broker.Deserialize(BodyString);
	If mol_Helpers.IsError(Response) Then
		mol_Logger.Error("Transporter_HTTP.Receive",
			"Malformed request body",
			BodyString,
			Metadata.CommonModules.mol_Transit
		);
		Return NewServiceResponse(
			mol_Errors.RequestRejected("Malformed request body", Response.Error)
		);
	EndIf;
	Packet = Response.Result;
	
	Result = MessageHandler(Packet.Type, Packet);
	Return NewServiceResponse(Result);
	
EndFunction 

#EndRegion

#EndRegion

#EndRegion

#Region Private

#Region MessageHandler

Function MessageHandler(Cmd, Packet)
	
	Payload = mol_Helpers.Get(Packet, "Payload");  
	If Payload = Undefined Then
		Return mol_Helpers.NewResponse(
			mol_Errors.InvalidPacketData("Missing response payload.")
		);	
	EndIf;
	
	If Packet.Ver <> "1" Then 
		Data = New Structure();
		Data.Insert("nodeID"  , Packet.Sender);
		Data.Insert("actual"  , "1");
		Data.Insert("received", Packet.Ver);
		Error = mol_Errors.ProtocolVersionMismatchError(Data);
		Return mol_Helpers.NewResponse(Error);  
	EndIf;
	
	Try			
		If Packet.Type = "PACKET_REQUEST" Then
			Return RequestHandler(Packet);
		ElsIf Packet.Type = "PACKET_RESPONSE" Then
			Return ResponseHandler(Packet);
		ElsIf Packet.Type = "PACKET_EVENT" Then
			Return EventHandler(Packet);
		ElsIf Packet.Type = "PACKET_CHANNEL_EVENT" Then
			Return ChannelEventHandler(Packet);
		ElsIf Packet.Type = "PACKET_DISCOVER" Then
		   	Return ProcessDiscover(Packet.Sender);
		ElsIf Packet.Type = "PACKET_DISCOVER_SERVICES" Then
		   	Return ProcessDiscoverServices(Packet.Sender);
		ElsIf Packet.Type = "PACKET_INFO" Then
			Return Packet.Payload;
		ElsIf Packet.Type = "PACKET_DISCONNECT" Then
			Return ProcessDisconnect(Packet.Sender);
		ElsIf Packet.Type = "PACKET_REQUEST_HEARTBEAT" Then
			Return ProcessHeartbeatRequest(Packet.Sender);
		ElsIf Packet.Type = "PACKET_PING" Then
			Return SendPong(Packet);
		ElsIf Packet.Type = "PACKET_PONG" Then
			Return ProcessPong(Packet);
		EndIf; 
		
		Return mol_Helpers.NewResponse("UNKNOWN_PACKET_TYPE");
		
	Except                                                  
		ErrorInfo = ErrorInfo();
		Error = mol_Errors.RequestRejected("Cannot process packet data", , ErrorInfo);
		mol_Logger.Error("Transit.MessageHandler", "Cannot process packet data", Error, Metadata.CommonModules.mol_Transit);
		
		Params = New Structure();
		Params.Insert("error" , Error);
		Params.Insert("module", "sidecar-transit");
		Params.Insert("type"  , "FAILED_PROCESSING_PACKET");
		mol_Broker.BroadcastLocal("$sidecar-transit.error", Params);
		
	EndTry;
	
	Return mol_Helpers.NewResponse("PACKET_DATA_ERROR");
		
	
EndFunction

#Region Handlers

Function RequestHandler(Packet)
	
	Payload = Packet.Payload;
	Sender  = Packet.Sender;
	
	RequestID = ?(Payload.RequestID <> Undefined, "with requestID '" + Payload.RequestID + "' ", "");
	mol_Logger.Debug("Transit.RequestHandler",
		StrTemplate("<= Request '%1' %2received from '%3' node.",
			Payload.Action,                             
			RequestID,
			Sender
		),
		Payload,
		Metadata.CommonModules.mol_Transit
	);  
	
	Error = Undefined;
	Data  = Undefined;
	Meta  = Undefined;
	
	Try  
		
		// Recreate caller context
		Context = mol_ContextFactory.Create(mol_Broker);
		Context.Id        = Payload.Id;
		mol_ContextFactory.SetParams(Context, Payload.Params);
		Context.ParentID  = Payload.ParentID;
		Context.RequestID = Payload.RequestID;
		Context.Caller    = Payload.Caller;
		Context.Meta      = ?(Payload.Meta <> Undefined, Payload.Meta, New Map());
		Context.Level     = Payload.Level;
		Context.Tracing   = Payload.Tracing;
		Context.NodeID    = Sender;

		If Payload.Property("Timeout") And Payload.Timeout <> Undefined Then
			Context.Options.Timeout = Payload.Timeout;
		EndIf;
		
		ContextCache = mol_ReuseCalls.GetContextCache();
		ContextCache.Add(Context);
		
		Data = Undefined;
		Try
			HandlerParts = StrSplit(Payload.Handler, ".");      
			Parameters = New Array();
			Parameters.Add(Context);
			Data = mol_Helpers.ExecuteModuleFunction(HandlerParts[0], HandlerParts[1], Parameters);
		Except             
			Error = mol_Errors.ServiceError(Undefined,,,, ErrorInfo());
			Error.Insert("context", Context);
		EndTry;   
		
		ContextCache.Delete(ContextCache.UBound());
		
		Meta = Context.Meta;
		
	Except                      
		ErrorInfo = ErrorInfo();  
				
		mol_Logger.Debug("Transit.RequestHandler",
			"Request handle error",
			DetailErrorDescription(ErrorInfo),
			Metadata.CommonModules.mol_Transit
		);
		
		Error = mol_Errors.RequestRejected("Request handle error",, ErrorInfo);		
	EndTry;                                                                    
	
	Return mol_PacketFactory.Response(
		Sender, 
		Payload.Id, 
		Error, 
		Data, 
		Meta
	);
		
	
EndFunction

Function ResponseHandler(Packet) 
	
	Payload = Packet.Payload;
	Sender  = Packet.Sender;
	
	PendingRequests = mol_ReuseCalls.GetPendingRequests();
	Request = PendingRequests.Get(Payload.Id);
	
	// If not exists (timed out), we skip response processing
	If Request = Undefined Then
		mol_Logger.Debug(
			"Transit.ResponseHandler",
			StrTemplate(
				"Orphan response is received. Maybe the request is timed out earlier. ID:
				|%1
				|, Sender:
				|%2",
				Payload.Id,
				Sender
			),
			Undefined,
			Metadata.CommonModules.mol_Transit
		);
		//this.metrics.increment(METRIC.MOLECULER_TRANSIT_ORPHAN_RESPONSE_TOTAL);
		Return Undefined;
	EndIf;
	
	mol_Logger.Debug(
		"Transit.ResponseHandler",
		StrTemplate(
			"<= Response '%1' is received from '%2'.",
			Request.Action.Name,
			Sender	
		),
		Undefined,
		Metadata.CommonModules.mol_Transit
	);  
	
	// Update nodeID in context (if it uses external balancer)
	Request.Context.NodeID = Sender;

	// Merge response meta with original meta
	If mol_Helpers.IsObject(Payload.Meta) Or mol_Helpers.IsMap(Payload.Meta) Then
		If Request.Context.Meta = Undefined Then
			Request.Context.Meta = New Map();
		EndIf;
		For Each KeyValue In Payload.Meta Do
			Request.Context.Meta.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	// Remove pending request
	PendingRequests.Delete(Payload.Id);
	
	If Not Payload.Success Then
		Return mol_Helpers.NewResponse(Payload.Error);
	EndIf;
	
	Return mol_Helpers.NewResponse(Undefined, Payload.Data);
          	      
EndFunction 

Function EventHandler(Packet)
	
	Payload = Packet.Payload;
	Sender  = Packet.Sender;
	
	RequestID = ?(Payload.RequestID <> Undefined, "with requestID '" + Payload.RequestID + "' ", "");
	mol_Logger.Debug("Transit.EventHandler",
		StrTemplate("Event '%1' received from '%2' node.",
			Payload.Event,
			Sender
		),
		Undefined,
		Metadata.CommonModules.mol_Transit
	);
	
	//this.logger.debug(
	//	`Event '${payload.event}' received from '${payload.sender}' node` +
	//		(payload.groups ? ` in '${payload.groups.join(", ")}' group(s)` : "") +
	//		"."
	//);
	
	// Create caller context   
	Context = mol_ContextFactory.Create(mol_Broker);
	Context.Id        = Payload.Id; 
	Context.EventName = Payload.Event; 
	If Payload.Property("Data") Then
		mol_ContextFactory.SetParams(Context, Payload.Data);
	EndIf;
	Context.EventGroups  = Payload.Groups;
	Context.EventType    = Payload.EventType;
	Context.Meta         = ?(Payload.Meta <> Undefined, Payload.Meta, New Map());
	Context.Level        = Payload.Level;
	Context.Tracing      = Payload.Tracing;
	Context.ParentID     = Payload.ParentID;
	Context.RequestID    = Payload.RequestID;
	Context.Caller       = Payload.Caller;
	Context.NodeID       = Sender;
	
	ContextCache = mol_ReuseCalls.GetContextCache();
	ContextCache.Add(Context);
	
	Error = Undefined;
	Try
		HandlerParts = StrSplit(Payload.Handler, ".");      
		Parameters = New Array();
		Parameters.Add(Context);
		mol_Helpers.ExecuteModuleProcedure(HandlerParts[0], HandlerParts[1], Parameters);
	Except             
		Error = mol_Errors.ServiceError(Undefined,,,, ErrorInfo());
		Error.Insert("context", Context);
	EndTry;
	
	ContextCache.Delete(ContextCache.UBound());
	
	Return mol_PacketFactory.Response(Sender, Payload.Id, Error, Undefined, Context.Meta,);
	
EndFunction

Function ChannelEventHandler(Packet)  
	
	Payload = Packet.Payload;
	Sender  = Packet.Sender;
	
	RequestID = ?(Payload.RequestID <> Undefined, "with requestID '" + Payload.RequestID + "' ", "");
	mol_Logger.Debug("Transit.ChannelEventHandler",
		StrTemplate("Channel event received from '%1' node.",
			Sender
		),
		Undefined,
		Metadata.CommonModules.mol_Transit
	);
		
	// Create caller context   
	Context = mol_ContextFactory.Create(mol_Broker);
	Context.Id        = Payload.Id;  
	If Payload.Property("Data") Then
		mol_ContextFactory.SetParams(Context, Payload.Data);
	EndIf;
	Context.Meta         = ?(Payload.Meta <> Undefined, Payload.Meta, New Map());
	Context.Tracing      = Payload.Tracing;
	Context.RequestID    = Payload.RequestID;
	Context.NodeID       = Sender;
	
	ContextCache = mol_ReuseCalls.GetContextCache();
	ContextCache.Add(Context);
	
	Error = Undefined;
	Try
		HandlerParts = StrSplit(Payload.Handler, ".");      
		Parameters = New Array();
		Parameters.Add(Context);
		Parameters.Add(Payload.Raw);
		mol_Helpers.ExecuteModuleProcedure(HandlerParts[0], HandlerParts[1], Parameters);
	Except             
		Error = mol_Errors.ServiceError(Undefined,,,, ErrorInfo());
		Error.Insert("context", Context);
	EndTry;
	
	ContextCache.Delete(ContextCache.UBound());
	
	Return mol_PacketFactory.Response(Sender, Payload.Id, Error, Undefined, Context.Meta);
	
EndFunction


Function ProcessDiscover(Sender)

	Return mol_PacketFactory.Info(Sender, mol_Broker.GetNodeInfo());
	
EndFunction

Function ProcessDiscoverServices(Sender)
	
	Services = New Array();
	
	Result = mol_Broker.GetServiceSchemas(True);
	For Each ServiceSchema In Result.Services Do
		If ServiceSchema.Name <> "$node" Then
			Services.Add(ServiceSchema);
		EndIf;
	EndDo;           
	
	Target = "sidecar";
	Return mol_PacketFactory.ServicesInfo(Target, Services);
	
EndFunction

Function ProcessDisconnect(Sender)
	
EndFunction

Function ProcessHeartbeatRequest(Target) Export

	Return mol_PacketFactory.Heartbeat(Target);

EndFunction

Function SendPong(Packet)                  
	
	Return mol_PacketFactory.Pong(Packet.Sender, Packet.Payload.Time, Packet.Payload.Id);	
		
EndFunction

Function ProcessPong(Packet)
	
EndFunction

#EndRegion

#EndRegion

#Region Transporters

#Region TransporterHTTP

// Execute HTTP request to sidecar server
//
// @internal
//
// Parameters:
//  Options - Structure          - Request options
//  Body    - String, BinaryData - Request body
// 
// Returns:
//  Structure:
//  	* Error  - Structure    - Error description
//      * Result - HTTPResponse - HTTP request response
Function PostHTTPRequest(Options, Body)
	
	HTTPConnection = mol_Helpers.GetSidecarHTTPConnection();
	#If Server And Not Server Then
		HTTPConnection = New HTTPConnection();
	#EndIf
	
	HTTPRequest = New HTTPRequest(Options.Path, Options.Headers); 	
	mol_Helpers.SetRequestResponseBody(HTTPRequest, Body);
	
	Response = mol_Helpers.NewResponse();
	Try     
		Response.Result = HTTPConnection.Post(HTTPRequest);		
	Except
		Response.Error = mol_Errors.FromErrorInfo(ErrorInfo());
	EndTry;      
	
	Return Response;
	
EndFunction

Function NewServiceResponse(Packet)
	
	Headers = New Map();
	Headers.Insert("content-type", "application/json");
	
	HTTPServiceResponse = New HTTPServiceResponse(200, , Headers);
	ResponseString = mol_Broker.Serialize(Packet);
	mol_Helpers.SetRequestResponseBody(HTTPServiceResponse, ResponseString);
		
	Return HTTPServiceResponse;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion