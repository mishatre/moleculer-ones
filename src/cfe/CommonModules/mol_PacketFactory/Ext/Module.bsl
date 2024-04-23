
#Region Public

Function Discover(Target = Undefined) Export
	Return NewPacket("PACKET_DISCOVER", Target);		
EndFunction    

Function Disconnect(Target = Undefined) Export
	Return NewPacket("PACKET_DISCONNECT", Target);		
EndFunction

Function Request(Context) Export
	
	Payload = New Structure();
	Payload.Insert("id"       , Context.Id);
	Payload.Insert("action"   , Context.Action.Name);
	Payload.Insert("params"   , Context.Params);
	Payload.Insert("meta"     , Context.Meta);
	Payload.Insert("timeout"  , mol_Helpers.Get(Context.Options, "Timeout"));
	Payload.Insert("level"    , Context.Level);
	Payload.Insert("tracing"  , Context.Tracing);
	Payload.Insert("parentID" , Context.ParentID);
	Payload.Insert("requestID", Context.RequestID);
	Payload.Insert("caller"   , Context.Caller);
	
	Return NewPacket("PACKET_REQUEST", Context.NodeID, Payload);	
	
EndFunction 

Function Event(Context) Export
	
	Payload = New Structure();
	Payload.Insert("id"       , Context.Id);
	Payload.Insert("event"    , Context.EventName);
	Payload.Insert("data"     , Context.Params);
	Payload.Insert("groups"   , Context.EventGroups);
	Payload.Insert("eventType", Context.EventType);
	Payload.Insert("meta"     , Context.Meta);
	Payload.Insert("level"    , Context.Level);
	Payload.Insert("tracing"  , Context.Tracing);
	Payload.Insert("parentID" , Context.ParentID);
	Payload.Insert("requestID", Context.RequestID);
	Payload.Insert("caller"   , Context.Caller);
	Payload.Insert("needAck"  , Context.NeedAck);
	
	Return NewPacket("PACKET_EVENT", Context.NodeID, Payload);	
	
EndFunction

Function ChannelEvent(Target, ChannelName, Data, Opts) Export
	
	Payload = New Structure();
	Payload.Insert("channelName", ChannelName);
	Payload.Insert("data"       , Data);
	Payload.Insert("opts"       , Opts);
	
	Return NewPacket("PACKET_CHANNEL_EVENT_REQUEST", Target, Payload);	
	
EndFunction

Function Info(NodeID, Info) Export
	
	Return NewPacket("PACKET_INFO", NodeID, Info);	
	
EndFunction  

Function ServicesInfo(NodeID, Services) Export
	
	Payload = New Structure();
	Payload.Insert("services", Services);
	
	Return NewPacket("PACKET_SERVICES_INFO", NodeID, Payload);	
	
EndFunction

Function Ping(NodeID, Id = Undefined) Export
	
	Payload = New Structure();
	Payload.Insert("time", CurrentUniversalDateInMilliseconds());
	Payload.Insert("id"  , ?(Id <> Undefined, Id, mol_Broker.GenerateUid()));
	
	Return NewPacket("PACKET_PING", NodeID, Payload);	
	
EndFunction

Function Pong(NodeID, Time, Id) Export
	
	Payload = New Structure();
	Payload.Insert("time"   , Time);
	Payload.Insert("id"     , Id);
	Payload.Insert("arrived", CurrentUniversalDateInMilliseconds());
	
	Return NewPacket("PACKET_PONG", NodeID, Payload);	
	
EndFunction

Function Heartbeat(NodeID) Export
	
	Payload = New Structure();
	Payload.Insert("cpu", "");
	
	Return NewPacket("PACKET_HEARTBEAT", NodeID, Payload);	
	
EndFunction

Function Response(Target, Id, Error, Data, Meta = Undefined) Export

	Payload = New Structure();
	Payload.Insert("id"     , Id);
	Payload.Insert("meta"   , Meta);
	Payload.Insert("success", Error = Undefined);
	Payload.Insert("data"   , Data);
	Payload.Insert("error"  , Error);
				
	Return NewPacket("PACKET_RESPONSE", Target, Payload);
	
EndFunction

#EndRegion

#Region Private

Function NewPacket(Type, Target = Undefined, Payload = Undefined) Export
	
	Result = New Structure();
	Result.Insert("type"   , ?(Type = Undefined, "PACKET_UNKNOWN", Type));
	Result.Insert("target" , Target);
	Result.Insert("payload", ?(Payload = Undefined, New Structure(), Payload));
	Result.Insert("sender" , mol_Broker.NodeID());                              
	Result.Insert("ver"    , "1");
	
	Return Result;
	
EndFunction                                  

#EndRegion