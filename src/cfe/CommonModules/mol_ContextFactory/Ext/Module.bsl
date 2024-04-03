
#Region Public 

Function Broker() Export
	Return Eval("mol_Broker");	
EndFunction

Function Call(Ctx, ActionName, Params = Undefined, _Opts = Undefined) Export 
	Opts = New Structure();
	Opts.Insert("parentCtx", Ctx);
	If _Opts <> Undefined Then
		For Each KeyValue In _Opts Do
			Opts.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
		
	Response = mol_Broker.Call(ActionName, Params, Opts);
	
	If Response.Property("Context") Then
		If Response.Context.Meta <> Undefined Then
			For Each KeyValue In Response.Context.Meta Do
				Ctx.Meta.Insert(KeyValue.Key, KeyValue.Value);
			EndDo;
		EndIf;
	EndIf; 
	
	Return Response;
	
EndFunction 

Function MCall(Ctx, Def, _Opts) Export
	
EndFunction

Function Emit(Ctx, EventName, Data, Opts) Export
	
EndFunction

Function Broadcast(Ctx, EventName, Data, Opts) Export
	
EndFunction

Function StartSpan(Ctx, Name, Opts) Export
	
EndFunction

Function FinishSpan(Ctx, Span, Time) Export
	
EndFunction

Function ToJSON(Ctx) Export
	
EndFunction

#EndRegion

#Region Protected

Function Create(Broker, Endpoint, Params = Undefined, Opts = Undefined) Export
	
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;

	Context = ContextConstructor(Broker, Endpoint);
	
	If Params <> Undefined Then
		SetParams(Context, Params);	
	EndIf; 
	
	If Opts <> Undefined Then
		For Each KeyValue In Opts Do
			Context.Options.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	// RequestID
	If Opts.Property("RequestID") And Opts.RequestID <> Undefined Then
		Context.RequestID = Opts.RequestID;
	ElsIf Opts.Property("ParentCtx") And TypeOf(Opts.ParentCtx) = Type("Structure") 
			And Opts.ParentCtx.Property("RequestID") And Opts.ParentCtx.RequestID <> Undefined Then
		Context.RequestID = Opts.ParentCtx.RequestID;
	EndIf;

	// Meta          
	If Opts.Property("ParentCtx") And TypeOf(Opts.ParentCtx) = Type("Structure")
			And Opts.ParentCtx.Property("Meta") And Opts.ParentCtx.Meta <> Undefined Then
		For Each KeyValue In Opts.ParentCtx.Meta Do 
			Context.Meta.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;     
	EndIf;
		
	If Opts.Property("Meta") And (TypeOf(Opts.Meta) = Type("Structure") Or TypeOf(Opts.Meta) = Type("Map")) Then
		For Each KeyValue In Opts.Meta Do 
			Context.Meta.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;            
	EndIf;
	
	// ParentID, Level, Caller, Tracing
	If Opts.Property("ParentCtx") And TypeOf(Opts.ParentCtx) = Type("Structure") Then
		Context.Tracing = Opts.ParentCtx.Tracing;
		Context.Level = Opts.ParentCtx.Level + 1;
		
		If Opts.ParentCtx.Property("Span") And TypeOf(Opts.ParentCtx.Span) = Type("Structure") Then
			Context.ParentID = Opts.ParentCtx.Span.Id;
		Else
			Context.ParentID = Opts.ParentCtx.Id;
		EndIf;
		
		If Opts.ParentCtx.Property("Service") And TypeOf(Opts.ParentCtx.Service) = Type("Structure") Then 
			Context.Caller = Opts.ParentCtx.Service.FullName;
		EndIf;
	EndIf;
			
	// caller
	If Opts.Property("Caller") Then
		Context.Caller = Opts.Caller;
	EndIf;

	// Parent span            
	If Opts.Property("ParentSpan") And TypeOf(Opts.ParentSpan) = Type("Structure") Then 
		Context.ParentID = Opts.ParentSpan.Id;
		Context.RequestID = Opts.ParentSpan.TraceID;
		Context.Tracing = Opts.ParentSpan.Sampled;
	EndIf;

	// Event acknowledgement
	If Opts.Property("NeedAck") Then
		Context.NeedAck = Opts.NeedAck;
	EndIf;
	
	Return Context;
	
EndFunction

Function SetEndpoint(Context, Endpoint) Export

	Context.Endpoint = Endpoint;
	If TypeOf(Endpoint) = Type("Structure") Then
		Context.NodeID = Endpoint.Id;
		If Endpoint.Property("Action") And TypeOf(Endpoint.Action) = Type("Structure") Then
			Context.Action = Endpoint.Action;
			Context.Service = Context.Action.Service;
			Context.Event = Undefined;
		ElsIf Endpoint.Property("Event") And TypeOf(Endpoint.Event) = Type("Structure") Then
			Context.Event = Endpoint.Event;
			Context.Service = Context.Event.Service;
			Context.Action = Undefined;
		EndIf;
	EndIf;
	
EndFunction 

Function SetParams(Context, Params) Export
	
	If Params <> Undefined Then
		Context.Params = New Structure();
		For Each KeyValue In Params Do
			Context.Params.Insert(KeyValue.Key, KeyValue.Value);
		EndDo; 
	EndIf;
	
EndFunction

#EndRegion

#Region Private

Function ContextConstructor(Broker, Endpoint)
	
	Context = NewContext();
	Context.Broker = Broker;

	If Context.Broker <> Undefined Then
		Context.NodeID = Context.Broker.NodeID();
		Context.Id     = Context.Broker.GenerateUid();
	EndIf;                                     
	
	If TypeOf(Endpoint) = Type("Structure") Then
		SetEndpoint(Context, Endpoint);
	EndIf;
		
	Context.Level = 1;

	Context.RequestID = Context.Id;

	Return Context;
	
EndFunction

Function NewContext()

	Result = new Structure();
	Result.Insert("broker", Undefined);
	Result.Insert("nodeID", Undefined);
	Result.Insert("id"    , Undefined);
	
	Result.Insert("endpoint", Undefined);
	Result.Insert("service" , Undefined);
	Result.Insert("action"  , Undefined);
	Result.Insert("event"   , Undefined);
	
	// The emitted event "user.created" because `ctx.event.name` can be "user.**" 
	Result.Insert("eventName"  , Undefined);
	// Type of event ("emit" or "broadcast")
	Result.Insert("eventType"  , Undefined);
	// The groups of event  
	Result.Insert("eventGroups", Undefined);
	
	Result.Insert("options", New Structure());
	Result.Options.Insert("timeout", Undefined);
	Result.Options.Insert("retries", Undefined);

	Result.Insert("parentID", Undefined);
	Result.Insert("caller"  , Undefined);

	Result.Insert("level", 1);
	
	Result.Insert("params", Undefined);
	Result.Insert("meta"  , New Map());
	Result.Insert("locals", New Structure());
	
	Result.Insert("requestID", Undefined);
	
	Result.Insert("tracing"   , Undefined);
	Result.Insert("span"      , Undefined);
	Result.Insert("_spanStack", New Array());

    Result.Insert("needAck", Undefined);
	Result.Insert("ackID"  , Undefined);

	Result.Insert("cachedResult", False);
	
	Return Result;
	
EndFunction


#EndRegion