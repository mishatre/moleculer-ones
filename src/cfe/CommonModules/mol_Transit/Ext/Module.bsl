
#Region Protected

Function Request(Context) Export 
	
	TraceHeaders = New Map();
	TraceHeaders.Insert("x-trace-span-name", "action " + Context.Action.Name);
	TraceHeaders.Insert("x-trace-parent-id", Context.ParentID);
	TraceHeaders.Insert("x-trace-id", Context.RequestID);

	Payload = New Structure();
	Payload.Insert("id"       , Context.Id);
	Payload.Insert("action"   , Context.Action.Name);
	Payload.Insert("params"   , Context.Params);
	Payload.Insert("meta"     , Context.Meta);
	Payload.Insert("timeout"  , ?(Context.Options.Property("Timeout"), Context.Options.Timeout, Undefined));
	Payload.Insert("level"    , Context.Level);
	Payload.Insert("tracing"  , Context.Tracing);
	Payload.Insert("parentID" , Context.ParentID);
	Payload.Insert("requestID", Context.RequestID);
	Payload.Insert("caller"   , Context.Caller);    
	
	Request = New Structure();
	Request.Insert("action", Context.Action);
	Request.Insert("nodeID", Context.NodeID);
	Request.Insert("Context", Context);
	
	Target = "sidecar";
	Packet = NewPacket("PACKET_REQUEST", Target, Payload);
	
	PendingRequests = mol_InternalReuseCalls.GetPendingRequests();
	PendingRequests.Insert(Context.Id, Request);
	
	Response = Send(Packet, Context.RequestId, TraceHeaders);
 	If mol_Internal.IsError(Response) Then
		mol_Logger.Error("Transporters.Request",
			StrTemplate(
				"Unable to send '%1' response to '%2' node.",
				Context.Id, 
				Target,
			),
			Response.Error,
			Metadata.CommonModules.mol_Transit
		);
		Return Response;
	EndIf;
	mol_Internal.Unwrap(Response);
	
	Return MessageHandler(Response.Type, Response);
		
EndFunction 

Function DiscoverSidecarNode() Export

	Response = Send(NewPacket("PACKET_DISCOVER"));
 	If mol_Internal.IsError(Response) Then
		mol_Logger.Error("Transporters.DiscoverNode",
			"Unable to send DISCOVER packet.",
			Response.Error,
			Metadata.CommonModules.mol_Transit
		);
	EndIf;
	mol_Internal.Unwrap(Response);
	
	Return MessageHandler(Response.Type, Response);
	
EndFunction

Function SendPing(NodeID, Id = Undefined) Export

	Response = Send(NewPacket("PACKET_PING", NodeID, New Structure(
		"time, Nid",
		CurrentUniversalDateInMilliseconds(),
		?(Id <> Undefined, Id, mol_Broker.GenerateUid())
	)));
 	If mol_Internal.IsError(Response) Then
		mol_Logger.Error("Transporters.SendDisconnectPacket",
			StrTemplate("Unable to send PING packet to '%1' node.", NodeID),
			Response.Error,
			Metadata.CommonModules.mol_Transit
		);
	EndIf;
	mol_Internal.Unwrap(Response);
	
	Return Response;
	
EndFunction

#Region MessageHandler

Function NewPacket(Type, Target = Undefined, Payload = Undefined) Export
	
	Result = New Structure();
	Result.Insert("type", ?(Type = Undefined, "PACKET_UNKNOWN", Type));
	Result.Insert("target", Target);
	Result.Insert("payload", ?(Payload = Undefined, New Structure(), Payload));
	
	Return Result;
	
EndFunction

Function MessageHandler(Cmd, Packet) Export

	Try
		Payload = Packet.Payload;  
		If Payload = Undefined Then
			Return mol_Internal.NewResponse(
				mol_Errors.InvalidPacketData("Missing response payload.")
			);	
		EndIf;
		
		If Not Payload.Property("Ver") Or Payload.Ver <> "1" Then
			Return mol_Internal.NewResponse(
				mol_Errors.ProtocolVersionMismatchError(Undefined, 
					New Structure(
						"NodeID, Actual, Received",
						Payload.Sender,
						"1",
						Payload.Ver
					)
				)
			);  
		EndIf;
		
		If Cmd = "PACKET_REQUEST" Then
			Return RequestHandler(Payload);
		// Response
		ElsIf Cmd = "PACKET_RESPONSE" Then
			Return ResponseHandler(Payload);
		// Event
		ElsIf Cmd = "PACKET_EVENT" Then
			Return EventHandler(payload);
		// Discover
		ElsIf Cmd = "PACKET_DISCOVER" Then
			//NodeInfo = mol_Broker.GetLocalNodeInfo(Payload.Sender);
			//Return Publish(
			//	NewPacket("PACKET_INFO", Payload.Sender, NodeInfo)
			//);
		// Node info
		ElsIf Cmd = "PACKET_INFO" Then
			Return ProcessRemoteNodeInfo(Payload.Sender, Payload);
		// Disconnect
		ElsIf Cmd = "PACKET_DISCONNECT" Then
			//this.discoverer.remoteNodeDisconnected(payload.sender, false);
		// Heartbeat
		ElsIf Cmd = "PACKET_HEARTBEAT" Then
			//this.discoverer.heartbeatReceived(payload.sender, payload);
		// Ping
		ElsIf Cmd = "PACKET_PING" Then
			Return SendPong(Payload);
		// Pong
		ElsIf Cmd = "PACKET_PONG" Then
			//this.processPong(payload);
		EndIf; 
		
		Return mol_Internal.NewResponse("UNKNOWN_PACKET_TYPE");
		
	Except                                                  
		ErrorInfo = ErrorInfo();
		Error = mol_Errors.RequestRejected("Cannot process packet data", , ErrorInfo);
		mol_Logger.Error("Transit.MessageHandler", "Cannot process packet data", Undefined, Metadata.CommonModules.mol_Transit);
		
		Params = New Structure();
		Params.Insert("error" , Error);
		Params.Insert("module", "sidecar-transit");
		Params.Insert("type"  , "FAILED_PROCESSING_PACKET");
		mol_Broker.BroadcastLocal("$sidecar-transit.error", Params);
		
	EndTry;
	
	Return mol_Internal.NewResponse("PACKET_DATA_ERROR");
		
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function Publish(Packet)   
	
	Packet.Payload.Insert("ver"   , "1");
	Packet.Payload.Insert("sender", Constants.mol_NodeId.Get());
	Return Packet;  
	
EndFunction

Function Send(Packet, RequestID = Undefined, TraceHeaders = Undefined)
	
	Response = mol_Transporter_HTTP.Send(Publish(Packet), RequestID, TraceHeaders);
	If mol_Internal.IsError(Response) Then
		Return Response;
	EndIf;    
	mol_Internal.Unwrap(Response);
	
	Response = mol_Broker.Deserialize(Response.GetBodyAsString());
	
	Return Response;
	
EndFunction

Function ProcessRemoteNodeInfo(NodeID, Payload)
	Return mol_Internal.NewResponse(Undefined, Payload);		
EndFunction

Function ResponseHandler(Packet)
	
	Id = Packet.Id;
	
	PendingRequests = mol_InternalReuseCalls.GetPendingRequests();
	Request = PendingRequests.Get(Id);
	
	// If not exists (timed out), we skip response processing
	If Request = Undefined Then
		mol_Logger.Debug(
			"Transit.ResponseHandler",
			StrTemplate(
				"Orphan response is received. Maybe the request is timed out earlier. ID:
				|%1
				|, Sender:
				|%2",
				Packet.Id,
				Packet.Sender
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
			Packet.Sender	
		),
		Undefined,
		Metadata.CommonModules.mol_Transit
	);  
	
	// Update nodeID in context (if it uses external balancer)
	Request.Context.NodeID = Packet.Sender;

	// Merge response meta with original meta
	If TypeOf(Packet.Meta) = Type("Structure") Or TypeOf(Packet.Meta) = Type("Map") Then
		If Request.Context.Meta = Undefined Then
			Request.Context.Meta = New Map();
		EndIf;
		For Each KeyValue In Packet.Meta Do
			Request.Context.Meta.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	// Remove pending request
	PendingRequests.Delete(Id);
	
	If Not Packet.Success Then
		Return mol_Internal.NewResponse(CreateErrorFromPayload(Packet.Error, Packet));
	EndIf;
	
	Return mol_Internal.NewResponse(Undefined, Packet.Data);
          	      
EndFunction 

Function RequestHandler(Payload)

	RequestID = ?(Payload.RequestID <> Undefined, "with requestID '" + Payload.RequestID + "' ", "");
	mol_Logger.Debug("Transit.RequestHandler",
		StrTemplate("<= Request '%1' %2received from '%3' node.",
			Payload.Action,                             
			RequestID,
			Payload.Sender
		),
		Payload,
		Metadata.CommonModules.mol_Transit
	);
	
	Try  
		Broker = Eval("mol_Broker");
		Endpoint = Broker.GetLocalActionEndpoint(Payload.Action);
		If Endpoint = Undefined Then
			Error = mol_Errors.ServiceNotAvailable(, New Structure(
				"action, nodeID",
				Payload.Action,
				Payload.Sender
			));
			Return SendResponse(Payload.Sender, Payload.Id, Undefined, mol_Internal.NewResponse(Error));
		EndIf;
		
		
		// Recreate caller context
		Context = mol_ContextFactory.Create(Broker, Undefined);
		mol_ContextFactory.SetEndpoint(Context, Endpoint);
		Context.Id        = Payload.Id;
		mol_ContextFactory.SetParams(Context, Payload.Params);
		Context.ParentID  = Payload.ParentID;
		Context.RequestID = Payload.RequestID;
		Context.Caller    = Payload.Caller;
		Context.Meta      = ?(Payload.Meta <> Undefined, Payload.Meta, New Map());
		Context.Level     = Payload.Level;
		Context.Tracing   = Payload.Tracing;
		Context.NodeID    = Payload.Sender;

		If Payload.Property("Timeout") And Payload.Timeout <> Undefined Then
			Context.Options.Timeout = Payload.Timeout;
		EndIf;
		
		Response = mol_Internal.NewResponse();
		
		Try
			HandlerParts = StrSplit(Endpoint.Action.Handler, ".");      
			Parameters = New Array();
			Parameters.Add(Context);
			Response.Result = mol_Internal.ExecuteModuleFunction(HandlerParts[0], HandlerParts[1], Parameters);
		Except             
			Error = mol_Errors.ServiceError(Undefined,,,, ErrorInfo());
			Error.Insert("context", Context);
			Response.Error = Error;
		EndTry;
			
		// Pointer to Context
		Response.Insert("Context", Context);
		
		Return SendResponse(Payload.Sender, Payload.Id, Context.Meta, Response);
		
	Except                      
		ErrorInfo = ErrorInfo();  
				
		mol_Logger.Debug("Transit.RequestHandler",
			"Request handle error",
			BriefErrorDescription(ErrorInfo),
			Metadata.CommonModules.mol_Transit
		);
		
		Error = mol_Errors.RequestRejected("Request handle error",, ErrorInfo);
		Return SendResponse(Payload.Sender, Payload.Id, Context.Meta, mol_Internal.NewResponse(Error));		
	EndTry;
		
	
EndFunction

Function EventHandler(Payload) 
	
	RequestID = ?(Payload.RequestID <> Undefined, "with requestID '" + Payload.RequestID + "' ", "");
	mol_Logger.Debug("Transit.EventHandler",
		StrTemplate("Event '%1' received from '%2' node.",
			Payload.Event,
			Payload.Sender
		),
		Undefined,
		Metadata.CommonModules.mol_Transit
	);
	
	//this.logger.debug(
	//	`Event '${payload.event}' received from '${payload.sender}' node` +
	//		(payload.groups ? ` in '${payload.groups.join(", ")}' group(s)` : "") +
	//		"."
	//);
	
	Broker = Eval("mol_Broker");
	// Create caller context   
	Context = mol_ContextFactory.Create(Broker, Undefined);
	Context.Id        = Payload.Id; 
	Context.EventName = Payload.Event; 
	If Payload.Property("Data") Then
		mol_ContextFactory.SetParams(Context, Payload.Data);
	EndIf;
	Context.EventGroups  = Payload.Groups;
	Context.EventType    = ?(Payload.Broadcast, "broadcast", "emit");
	Context.Meta         = ?(Payload.Meta <> Undefined, Payload.Meta, New Map());
	Context.Level        = Payload.Level;
	Context.Tracing      = Payload.Tracing;
	Context.ParentID     = Payload.ParentID;
	Context.RequestID    = Payload.RequestID;
	Context.Caller       = Payload.Caller;
	Context.NodeID       = Payload.Sender;
	
	// ensure the eventHandler resolves true when the event was handled successfully
	Return mol_Broker.EmitLocalServices(Context);
	
EndFunction

Function SendResponse(NodeID, Id, Meta, Response) 
	
	IsError = mol_Internal.IsError(Response);

	Payload = New Structure();
	Payload.Insert("id", Id);
	Payload.Insert("meta", Meta);
	Payload.Insert("success", Not IsError);
	Payload.Insert("data", Response.Result);
			
	If IsError Then
		Payload.Insert("error", Response.Error);
	EndIf;
	
	Packet = Publish(NewPacket("PACKET_RESPONSE", NodeID, Payload));	
	
	Result = New Structure();
	Result.Insert("cmd", Packet.Type);
	Result.Insert("packet", Packet);
	Return Result;
	
EndFunction

Function SendPong(Payload)

	Return Publish(
		NewPacket("PACKET_PONG", Payload.Sender, New Structure(
			"time, id, arrived",
			Payload.Time,
			Payload.Id,
			CurrentUniversalDateInMilliseconds()
		))
	);	
		
EndFunction

Function CreateErrorFromPayload(Error, Payload)
	Return Error;	
EndFunction

#EndRegion