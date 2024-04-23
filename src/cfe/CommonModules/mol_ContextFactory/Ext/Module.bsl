
#Region Public 

Function Broker() Export
	Return mol_Broker;	
EndFunction

Function Call(ActionName, Params = Undefined, Opts = Undefined) Export 
	
	Context = GetCurrentContext();
	
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;
	Opts.Insert("parentCtx", Context);
		
	Response = mol_Broker.Call(ActionName, Params, Opts);
	
	If Response.Property("Context") Then
		If Response.Context.Meta <> Undefined Then
			For Each KeyValue In Response.Context.Meta Do
				Context.Meta.Insert(KeyValue.Key, KeyValue.Value);
			EndDo;
		EndIf;
	EndIf; 
	
	Return Response;
	
EndFunction 

Function MCall(Def, Opts = Undefined) Export

	Context = GetCurrentContext();
	
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;
	Opts.Insert("parentCtx", Context);
		
	Response = mol_Broker.MCall(Def, Opts);
	
	Return Response;
	
EndFunction

Function Emit(EventName, Data = Undefined, Opts = Undefined) Export

	Context = GetCurrentContext();
	
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;
	Opts.Insert("parentCtx", Context);
		
	Response = mol_Broker.Emit(EventName, Data, Opts);
		
	Return Response;

	
EndFunction

#Region Span

Function StartSpan(Ctx, Name, Opts) Export
	
EndFunction

Function FinishSpan(Ctx, Span, Time) Export
	
EndFunction

#EndRegion

Function ToJSON(Ctx) Export
	
EndFunction

#EndRegion

#Region Protected

Function GetCurrentContext() Export
	ContextCache = mol_ReuseCalls.GetContextCache();  
	If ContextCache.Count() = 0 Then
		Return Null;
	EndIf;
	Return ContextCache.Get(ContextCache.UBound());
EndFunction

Function Create(Broker, Params = Undefined, Opts = Undefined) Export
	
	If Opts = Undefined Then
		Opts = New Structure();
	EndIf;

	Context = ContextConstructor(Broker);
	
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
	ElsIf Opts.Property("ParentCtx") And mol_Helpers.IsObject(Opts.ParentCtx) 
			And Opts.ParentCtx.Property("RequestID") And Opts.ParentCtx.RequestID <> Undefined Then
		Context.RequestID = Opts.ParentCtx.RequestID;
	EndIf;

	// Meta          
	If Opts.Property("ParentCtx") And mol_Helpers.IsObject(Opts.ParentCtx)
			And Opts.ParentCtx.Property("Meta") And Opts.ParentCtx.Meta <> Undefined Then
		For Each KeyValue In Opts.ParentCtx.Meta Do 
			Context.Meta.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;     
	EndIf;
		
	If Opts.Property("Meta") And (mol_Helpers.IsObject(Opts.Meta) Or mol_Helpers.IsMap(Opts.Meta)) Then
		For Each KeyValue In Opts.Meta Do 
			Context.Meta.Insert(KeyValue.Key, KeyValue.Value);
		EndDo;            
	EndIf;
	
	// ParentID, Level, Caller, Tracing
	If Opts.Property("ParentCtx") And mol_Helpers.IsObject(Opts.ParentCtx) Then
		Context.Tracing = Opts.ParentCtx.Tracing;
		Context.Level = Opts.ParentCtx.Level + 1;
		
		If Opts.ParentCtx.Property("Span") And mol_Helpers.IsObject(Opts.ParentCtx.Span) Then
			Context.ParentID = Opts.ParentCtx.Span.Id;
		Else
			Context.ParentID = Opts.ParentCtx.Id;
		EndIf;
		
		If Opts.ParentCtx.Property("Service") And mol_Helpers.IsObject(Opts.ParentCtx.Service) Then 
			Context.Caller = Opts.ParentCtx.Service.FullName;
		EndIf;
	EndIf;
			
	// caller
	If Opts.Property("Caller") Then
		Context.Caller = Opts.Caller;
	EndIf;

	// Parent span            
	If Opts.Property("ParentSpan") And mol_Helpers.IsObject(Opts.ParentSpan) Then 
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
	If mol_Helpers.IsObject(Endpoint) Then
		Context.NodeID = Endpoint.Id;
		If Endpoint.Property("Action") And mol_Helpers.IsObject(Endpoint.Action) Then
			Context.Action = Endpoint.Action;
			Context.Service = Context.Action.Service;
			Context.Event = Undefined;
		ElsIf Endpoint.Property("Event") And mol_Helpers.IsObject(Endpoint.Event) Then
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

Function ContextConstructor(Broker)
	
	Context = NewContext(); 
	Context.This = mol_ContextFactory; 
	Context.Broker = Broker;

	If Context.Broker <> Undefined Then
		Context.NodeID = Context.Broker.NodeID();
		Context.Id     = Context.Broker.GenerateUid();
	EndIf;                                     
		
	Context.Level = 1;

	Context.RequestID = Context.Id;
	Context.Caller = Context.Broker.NodeID();

	Return Context;
	
EndFunction

Function NewContext()

	Result = new Structure();          
	Result.Insert("this"  , Undefined);
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