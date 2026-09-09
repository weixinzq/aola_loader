package mmo.petfightnew
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.external.ExternalInterface;
   import flash.system.System;
   import flash.utils.Dictionary;
   import flash.utils.getTimer;
   import mmo.loader.LoaderContainer;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;

   [Embed(source="/_assets/assets.swf", symbol="__EMBED_SYMBOL__")]
   public class DocPetFight extends Sprite
   {
      private static const BRIDGE_VERSION:int = 5;

      private static const DIAGNOSTICS_VERSION:int = 3;

      private static const TRACE_VERSION:int = 1;

      private static const MAX_TRACE_EVENTS:int = 512;

      private static const MAX_TRACE_RESOURCE_LENGTH:int = 512;

      public static var hideDamageNumbers:Boolean = false;

      public static var hideHealingNumbers:Boolean = false;

      public static var skipBattlePresentation:Boolean = false;

      private static var _aolaBattleBridgeRegistered:Boolean = false;

      private static var _readyEpoch:int = 0;

      private static var _diagnosticPanels:Dictionary = new Dictionary(true);

      private static var _diagnosticPanelCreatedCount:int = 0;

      private static var _diagnosticPanelDisposeStartedCount:int = 0;

      private static var _diagnosticPanelDisposedCount:int = 0;

      private static var _diagnosticStartMovies:Dictionary = new Dictionary(true);

      private static var _diagnosticStartMovieCreatedCount:int = 0;

      private static var _diagnosticStartMovieDisposedCount:int = 0;

      private static var _diagnosticApplicationDomains:Dictionary = new Dictionary(true);

      private static var _diagnosticApplicationDomainCreatedCount:int = 0;

      private static var _diagnosticApplicationDomainReleasedCount:int = 0;

      private static var _diagnosticPreloaders:Dictionary = new Dictionary(true);

      private static var _diagnosticPreloadStartedCount:int = 0;

      private static var _diagnosticPreloadCompletedCount:int = 0;

      private static var _diagnosticPreloadDisposedWhileLoadingCount:int = 0;

      private static var _diagnosticNextObjectId:int = 1;

      private static var _diagnosticTraceSequence:int = 0;

      private static var _diagnosticTraceDroppedCount:int = 0;

      private static var _diagnosticTraceEvents:Array = new Array(MAX_TRACE_EVENTS);

      private static var _diagnosticTraceHead:int = 0;

      private static var _diagnosticTraceCount:int = 0;

      private static var _diagnosticFrameStarted:Boolean = false;

      private static var _diagnosticFrameWindowStart:int = -1;

      private static var _diagnosticLastFrameTime:int = -1;

      private static var _diagnosticFrameSampleCount:int = 0;

      private static var _diagnosticLongFrame50Count:int = 0;

      private static var _diagnosticLongFrame100Count:int = 0;

      private static var _diagnosticLongFrame200Count:int = 0;

      private static var _diagnosticMaxFrameGapMs:int = 0;

      public function DocPetFight()
      {
         super();
      }

      public static function ensureAolaBattleBridge() : void
      {
         startDiagnosticFrames();
         if(_aolaBattleBridgeRegistered)
         {
            return;
         }
         try
         {
            if(ExternalInterface.available)
            {
               ExternalInterface.addCallback("aolaBattleBridgeReady",onAolaBattleBridgeReady);
               ExternalInterface.addCallback("aolaBattleApplyOptions",onAolaBattleApplyOptions);
               ExternalInterface.addCallback("aolaBattleGetState",onAolaBattleGetState);
               ExternalInterface.addCallback("aolaBattleGetDiagnostics",onAolaBattleGetDiagnostics);
               ExternalInterface.addCallback("aolaBattleDrainTraceEvents",onAolaBattleDrainTraceEvents);
               _aolaBattleBridgeRegistered = true;
            }
         }
         catch(error:Error)
         {
         }
      }

      public static function noteInputReady() : void
      {
         if(_readyEpoch < int.MAX_VALUE)
         {
            ++_readyEpoch;
         }
      }

      private static function onAolaBattleBridgeReady() : String
      {
         return "BattleBridgeReady|" + BRIDGE_VERSION.toString();
      }

      private static function onAolaBattleApplyOptions(param1:String) : String
      {
         var options:Object = null;
         var key:String = null;
         var allowed:Object = {
            "version":true,
            "revision":true,
            "hideDamageNumbers":true,
            "hideHealingNumbers":true,
            "skipBattlePresentation":true
         };
         if(param1 == null || param1.length == 0 || param1.length > 4096)
         {
            return "BattleOptionsRejected";
         }
         try
         {
            options = JSON.parse(param1);
            if(options == null || options is Array || typeof options != "object")
            {
               return "BattleOptionsRejected";
            }
            for(key in options)
            {
               if(!allowed.hasOwnProperty(key))
               {
                  return "BattleOptionsRejected";
               }
            }
            if(!hasRequiredOptions(options) ||
               typeof options.version != "number" || int(options.version) != options.version ||
               int(options.version) != BRIDGE_VERSION ||
               typeof options.revision != "number" || int(options.revision) != options.revision ||
               int(options.revision) < 0 ||
               typeof options.hideDamageNumbers != "boolean" ||
               typeof options.hideHealingNumbers != "boolean" ||
               typeof options.skipBattlePresentation != "boolean")
            {
               return "BattleOptionsRejected";
            }
            hideDamageNumbers = Boolean(options.hideDamageNumbers);
            hideHealingNumbers = Boolean(options.hideHealingNumbers);
            skipBattlePresentation = Boolean(options.skipBattlePresentation);
            return "BattleOptionsApplied|" + int(options.revision).toString();
         }
         catch(error:Error)
         {
         }
         return "BattleOptionsRejected";
      }

      private static function hasRequiredOptions(param1:Object) : Boolean
      {
         return param1.hasOwnProperty("version") &&
            param1.hasOwnProperty("revision") &&
            param1.hasOwnProperty("hideDamageNumbers") &&
            param1.hasOwnProperty("hideHealingNumbers") &&
            param1.hasOwnProperty("skipBattlePresentation");
      }

      private static function onAolaBattleGetState() : String
      {
         var controller:FightController = null;
         var panel:FightPanel = null;
         var ended:Boolean = false;
         var active:Boolean = false;
         var inputReady:Boolean = false;
         var battleId:int = 0;
         var turn:int = 0;
         try
         {
            controller = FightController.instance;
            panel = controller.fightPanel;
            ended = controller.whoWon != -1;
            active = panel != null && !ended;
            inputReady = active && !panel.canStart && panel.mouseEnabled && panel.mouseChildren;
            battleId = FightData.instance.battleId;
            turn = controller.turnCount;
         }
         catch(error:Error)
         {
            active = false;
            inputReady = false;
         }
         return JSON.stringify({
            "version":BRIDGE_VERSION,
            "active":active,
            "battleId":battleId,
            "turn":turn,
            "inputReady":inputReady,
            "readyEpoch":_readyEpoch,
            "ended":ended
         });
      }

      public static function noteDiagnosticPanel(param1:FightPanel) : void
      {
         if(param1 == null || param1 in _diagnosticPanels)
         {
            return;
         }
         _diagnosticPanels[param1] = 0;
         if(_diagnosticPanelCreatedCount < int.MAX_VALUE)
         {
            ++_diagnosticPanelCreatedCount;
         }
      }

      public static function noteDiagnosticPanelDisposeStarted(param1:FightPanel) : void
      {
         noteDiagnosticPanel(param1);
         if(param1 == null || int(_diagnosticPanels[param1]) >= 1)
         {
            return;
         }
         _diagnosticPanels[param1] = 1;
         if(_diagnosticPanelDisposeStartedCount < int.MAX_VALUE)
         {
            ++_diagnosticPanelDisposeStartedCount;
         }
      }

      public static function noteDiagnosticPanelDisposed(param1:FightPanel) : void
      {
         noteDiagnosticPanel(param1);
         if(param1 == null || int(_diagnosticPanels[param1]) >= 2)
         {
            return;
         }
         _diagnosticPanels[param1] = 2;
         if(_diagnosticPanelDisposedCount < int.MAX_VALUE)
         {
            ++_diagnosticPanelDisposedCount;
         }
      }

      public static function noteDiagnosticStartMovie(param1:Object) : void
      {
         var state:Object = null;
         if(param1 == null || param1 in _diagnosticStartMovies)
         {
            return;
         }
         state = {
            "id":nextDiagnosticObjectId(),
            "disposed":false
         };
         _diagnosticStartMovies[param1] = state;
         incrementDiagnosticCounter("startMovieCreated");
         addDiagnosticTrace("start-movie-created","",-1,int(state.id));
      }

      public static function noteDiagnosticStartMovieDisposed(param1:Object) : void
      {
         var state:Object = null;
         noteDiagnosticStartMovie(param1);
         if(param1 == null)
         {
            return;
         }
         state = _diagnosticStartMovies[param1];
         if(state == null || Boolean(state.disposed))
         {
            return;
         }
         state.disposed = true;
         incrementDiagnosticCounter("startMovieDisposed");
         addDiagnosticTrace("start-movie-disposed","",-1,int(state.id));
      }

      public static function noteDiagnosticApplicationDomain(param1:Object) : void
      {
         var state:Object = null;
         if(param1 == null || param1 in _diagnosticApplicationDomains)
         {
            return;
         }
         state = {
            "id":nextDiagnosticObjectId(),
            "released":false
         };
         _diagnosticApplicationDomains[param1] = state;
         incrementDiagnosticCounter("applicationDomainCreated");
         addDiagnosticTrace("application-domain-created","",-1,int(state.id));
      }

      public static function noteDiagnosticApplicationDomainReleased(param1:Object) : void
      {
         var state:Object = null;
         noteDiagnosticApplicationDomain(param1);
         if(param1 == null)
         {
            return;
         }
         state = _diagnosticApplicationDomains[param1];
         if(state == null || Boolean(state.released))
         {
            return;
         }
         state.released = true;
         incrementDiagnosticCounter("applicationDomainReleased");
         addDiagnosticTrace("application-domain-released","",-1,int(state.id));
      }

      public static function noteDiagnosticPreloadStarted(param1:Object) : void
      {
         var state:Object = null;
         if(param1 == null)
         {
            return;
         }
         state = {
            "id":nextDiagnosticObjectId(),
            "status":0,
            "pending":0,
            "resource":"",
            "resourceStartedAt":-1
         };
         _diagnosticPreloaders[param1] = state;
         incrementDiagnosticCounter("preloadStarted");
         addDiagnosticTrace("preload-started","",-1,int(state.id));
      }

      public static function noteDiagnosticResourceStarted(param1:Object, param2:String, param3:int) : void
      {
         var state:Object = getDiagnosticPreloadState(param1);
         var resource:String = sanitizeDiagnosticResource(param2);
         if(state == null)
         {
            return;
         }
         state.status = 0;
         state.pending = param3 >= 0 && param3 < int.MAX_VALUE ? param3 + 1 : -1;
         state.resource = resource;
         state.resourceStartedAt = getTimer();
         addDiagnosticTrace("resource-started",resource,-1,int(state.id));
      }

      public static function noteDiagnosticResourceEnded(param1:Object) : void
      {
         var state:Object = getDiagnosticPreloadState(param1);
         var now:int = getTimer();
         var duration:int = -1;
         var resource:String = "";
         if(state == null)
         {
            return;
         }
         resource = String(state.resource);
         if(int(state.resourceStartedAt) >= 0 && now >= int(state.resourceStartedAt))
         {
            duration = now - int(state.resourceStartedAt);
         }
         if(int(state.pending) > 0)
         {
            state.pending = int(state.pending) - 1;
         }
         state.resource = "";
         state.resourceStartedAt = -1;
         addDiagnosticTrace("resource-ended",resource,duration,int(state.id));
      }

      public static function noteDiagnosticPreloadCompleted(param1:Object) : void
      {
         var state:Object = getDiagnosticPreloadState(param1);
         if(state == null || int(state.status) == 1)
         {
            return;
         }
         state.status = 1;
         state.pending = 0;
         state.resource = "";
         state.resourceStartedAt = -1;
         incrementDiagnosticCounter("preloadCompleted");
         addDiagnosticTrace("preload-completed","",-1,int(state.id));
      }

      public static function noteDiagnosticPreloadDisposed(param1:Object) : void
      {
         var state:Object = getDiagnosticPreloadState(param1);
         var wasLoading:Boolean = false;
         if(state == null || int(state.status) == 2)
         {
            return;
         }
         wasLoading = int(state.status) == 0;
         state.status = 2;
         state.pending = 0;
         if(wasLoading)
         {
            incrementDiagnosticCounter("preloadDisposedWhileLoading");
         }
         addDiagnosticTrace("preload-disposed","",-1,int(state.id));
      }

      private static function getDiagnosticPreloadState(param1:Object) : Object
      {
         if(param1 == null || !(param1 in _diagnosticPreloaders))
         {
            return null;
         }
         return _diagnosticPreloaders[param1];
      }

      private static function nextDiagnosticObjectId() : int
      {
         var result:int = _diagnosticNextObjectId;
         if(_diagnosticNextObjectId < int.MAX_VALUE)
         {
            ++_diagnosticNextObjectId;
         }
         return result;
      }

      private static function incrementDiagnosticCounter(param1:String) : void
      {
         if(param1 == "startMovieCreated" && _diagnosticStartMovieCreatedCount < int.MAX_VALUE)
         {
            ++_diagnosticStartMovieCreatedCount;
         }
         else if(param1 == "startMovieDisposed" && _diagnosticStartMovieDisposedCount < int.MAX_VALUE)
         {
            ++_diagnosticStartMovieDisposedCount;
         }
         else if(param1 == "applicationDomainCreated" && _diagnosticApplicationDomainCreatedCount < int.MAX_VALUE)
         {
            ++_diagnosticApplicationDomainCreatedCount;
         }
         else if(param1 == "applicationDomainReleased" && _diagnosticApplicationDomainReleasedCount < int.MAX_VALUE)
         {
            ++_diagnosticApplicationDomainReleasedCount;
         }
         else if(param1 == "preloadStarted" && _diagnosticPreloadStartedCount < int.MAX_VALUE)
         {
            ++_diagnosticPreloadStartedCount;
         }
         else if(param1 == "preloadCompleted" && _diagnosticPreloadCompletedCount < int.MAX_VALUE)
         {
            ++_diagnosticPreloadCompletedCount;
         }
         else if(param1 == "preloadDisposedWhileLoading" && _diagnosticPreloadDisposedWhileLoadingCount < int.MAX_VALUE)
         {
            ++_diagnosticPreloadDisposedWhileLoadingCount;
         }
      }

      private static function sanitizeDiagnosticResource(param1:String) : String
      {
         var result:String = param1 == null ? "" : param1;
         var delimiter:int = result.indexOf("?");
         if(delimiter >= 0)
         {
            result = result.substr(0,delimiter);
         }
         delimiter = result.indexOf("#");
         if(delimiter >= 0)
         {
            result = result.substr(0,delimiter);
         }
         if(result.length > MAX_TRACE_RESOURCE_LENGTH)
         {
            result = result.substr(0,MAX_TRACE_RESOURCE_LENGTH);
         }
         return result;
      }

      private static function addDiagnosticTrace(param1:String, param2:String, param3:int, param4:int) : void
      {
         var item:Object = null;
         var index:int = 0;
         if(_diagnosticTraceSequence < int.MAX_VALUE)
         {
            ++_diagnosticTraceSequence;
         }
         item = {
            "sequence":_diagnosticTraceSequence,
            "atMs":getTimer(),
            "type":param1,
            "resource":sanitizeDiagnosticResource(param2),
            "durationMs":param3,
            "value":param4
         };
         if(_diagnosticTraceCount >= MAX_TRACE_EVENTS)
         {
            if(_diagnosticTraceDroppedCount < int.MAX_VALUE)
            {
               ++_diagnosticTraceDroppedCount;
            }
            _diagnosticTraceEvents[_diagnosticTraceHead] = item;
            _diagnosticTraceHead = (_diagnosticTraceHead + 1) % MAX_TRACE_EVENTS;
            return;
         }
         index = (_diagnosticTraceHead + _diagnosticTraceCount) % MAX_TRACE_EVENTS;
         _diagnosticTraceEvents[index] = item;
         ++_diagnosticTraceCount;
      }

      private static function startDiagnosticFrames() : void
      {
         if(_diagnosticFrameStarted)
         {
            return;
         }
         try
         {
            _diagnosticFrameStarted = true;
            _diagnosticFrameWindowStart = getTimer();
            _diagnosticLastFrameTime = _diagnosticFrameWindowStart;
            LoaderContainer.instance.addEventListener(Event.ENTER_FRAME,onDiagnosticFrame,false,0,true);
         }
         catch(error:Error)
         {
            _diagnosticFrameStarted = false;
            _diagnosticFrameWindowStart = -1;
            _diagnosticLastFrameTime = -1;
         }
      }

      private static function onDiagnosticFrame(param1:Event) : void
      {
         var now:int = getTimer();
         var gap:int = 0;
         if(_diagnosticLastFrameTime >= 0)
         {
            gap = now - _diagnosticLastFrameTime;
            if(gap >= 0)
            {
               if(_diagnosticFrameSampleCount < int.MAX_VALUE)
               {
                  ++_diagnosticFrameSampleCount;
               }
               if(gap >= 50 && _diagnosticLongFrame50Count < int.MAX_VALUE)
               {
                  ++_diagnosticLongFrame50Count;
                  addDiagnosticTrace("frame-gap","",gap,gap);
               }
               if(gap >= 100 && _diagnosticLongFrame100Count < int.MAX_VALUE)
               {
                  ++_diagnosticLongFrame100Count;
               }
               if(gap >= 200 && _diagnosticLongFrame200Count < int.MAX_VALUE)
               {
                  ++_diagnosticLongFrame200Count;
               }
               if(gap > _diagnosticMaxFrameGapMs)
               {
                  _diagnosticMaxFrameGapMs = gap;
               }
            }
         }
         _diagnosticLastFrameTime = now;
      }

      private static function onAolaBattleGetDiagnostics() : String
      {
         var panel:FightPanel = null;
         var panelState:int = 0;
         var state:Object = null;
         var totalMemory:Number = -1;
         var privateMemory:Number = -1;
         var freeMemory:Number = -1;
         var liveFightPanels:int = 0;
         var disposedFightPanels:int = 0;
         var liveStartMovies:int = 0;
         var disposedStartMovies:int = 0;
         var liveApplicationDomains:int = 0;
         var releasedApplicationDomains:int = 0;
         var livePreloadSessions:int = 0;
         var activePreloadSessions:int = 0;
         var disposedPreloadSessions:int = 0;
         var preloadInFlightCount:int = 0;
         var preloadPendingCount:int = 0;
         var currentResourceAgeMs:int = -1;
         var stageChildren:int = -1;
         var panelChildren:int = -1;
         var stageFrameRate:Number = -1;
         var frameWindowMs:int = -1;
         var frameSampleCount:int = _diagnosticFrameSampleCount;
         var longFrame50Count:int = _diagnosticLongFrame50Count;
         var longFrame100Count:int = _diagnosticLongFrame100Count;
         var longFrame200Count:int = _diagnosticLongFrame200Count;
         var maxFrameGapMs:int = _diagnosticMaxFrameGapMs;
         var now:int = getTimer();
         try
         {
            totalMemory = Number(System.totalMemory);
            privateMemory = System.privateMemory;
            freeMemory = System.freeMemory;
         }
         catch(error:Error)
         {
         }
         try
         {
            panelChildren = 0;
            for(var item:Object in _diagnosticPanels)
            {
               panel = item as FightPanel;
               if(panel != null)
               {
                  ++liveFightPanels;
                  panelState = int(_diagnosticPanels[panel]);
                  if(panelState >= 2)
                  {
                     ++disposedFightPanels;
                  }
                  panelChildren += panel.numChildren;
                  if(panel.stage != null)
                  {
                     stageChildren = panel.stage.numChildren;
                     stageFrameRate = panel.stage.frameRate;
                  }
               }
            }
         }
         catch(error:Error)
         {
            liveFightPanels = -1;
            stageChildren = -1;
            panelChildren = -1;
         }
         try
         {
            for(var startMovieItem:Object in _diagnosticStartMovies)
            {
               ++liveStartMovies;
               state = _diagnosticStartMovies[startMovieItem];
               if(state != null && Boolean(state.disposed))
               {
                  ++disposedStartMovies;
               }
            }
         }
         catch(error:Error)
         {
            liveStartMovies = -1;
            disposedStartMovies = -1;
         }
         try
         {
            for(var domainItem:Object in _diagnosticApplicationDomains)
            {
               ++liveApplicationDomains;
               state = _diagnosticApplicationDomains[domainItem];
               if(state != null && Boolean(state.released))
               {
                  ++releasedApplicationDomains;
               }
            }
         }
         catch(error:Error)
         {
            liveApplicationDomains = -1;
            releasedApplicationDomains = -1;
         }
         try
         {
            for(var preloadItem:Object in _diagnosticPreloaders)
            {
               ++livePreloadSessions;
               state = _diagnosticPreloaders[preloadItem];
               if(state == null)
               {
                  continue;
               }
               if(int(state.status) == 0)
               {
                  ++activePreloadSessions;
               }
               else if(int(state.status) == 2)
               {
                  ++disposedPreloadSessions;
               }
               if(int(state.pending) > 0 && preloadPendingCount <= int.MAX_VALUE - int(state.pending))
               {
                  preloadPendingCount += int(state.pending);
               }
               if(String(state.resource).length > 0)
               {
                  ++preloadInFlightCount;
                  if(int(state.resourceStartedAt) >= 0 && now >= int(state.resourceStartedAt) &&
                     now - int(state.resourceStartedAt) > currentResourceAgeMs)
                  {
                     currentResourceAgeMs = now - int(state.resourceStartedAt);
                  }
               }
            }
         }
         catch(error:Error)
         {
            livePreloadSessions = -1;
            activePreloadSessions = -1;
            disposedPreloadSessions = -1;
            preloadInFlightCount = -1;
            preloadPendingCount = -1;
            currentResourceAgeMs = -1;
         }
         if(stageFrameRate < 0)
         {
            try
            {
               if(LoaderContainer.instance.stage != null)
               {
                  stageChildren = LoaderContainer.instance.stage.numChildren;
                  stageFrameRate = LoaderContainer.instance.stage.frameRate;
               }
            }
            catch(error:Error)
            {
               stageFrameRate = -1;
            }
         }
         if(_diagnosticFrameWindowStart >= 0 && now >= _diagnosticFrameWindowStart)
         {
            frameWindowMs = now - _diagnosticFrameWindowStart;
         }
         _diagnosticFrameWindowStart = now;
         _diagnosticFrameSampleCount = 0;
         _diagnosticLongFrame50Count = 0;
         _diagnosticLongFrame100Count = 0;
         _diagnosticLongFrame200Count = 0;
         _diagnosticMaxFrameGapMs = 0;
         return JSON.stringify({
            "version":DIAGNOSTICS_VERSION,
            "flashUptimeMs":now,
            "totalMemory":totalMemory,
            "privateMemory":privateMemory,
            "freeMemory":freeMemory,
            "liveFightPanels":liveFightPanels,
            "disposedFightPanels":disposedFightPanels,
            "panelCreatedCount":_diagnosticPanelCreatedCount,
            "panelDisposeStartedCount":_diagnosticPanelDisposeStartedCount,
            "panelDisposedCount":_diagnosticPanelDisposedCount,
            "liveStartMovies":liveStartMovies,
            "disposedStartMovies":disposedStartMovies,
            "startMovieCreatedCount":_diagnosticStartMovieCreatedCount,
            "startMovieDisposedCount":_diagnosticStartMovieDisposedCount,
            "liveApplicationDomains":liveApplicationDomains,
            "releasedApplicationDomains":releasedApplicationDomains,
            "applicationDomainCreatedCount":_diagnosticApplicationDomainCreatedCount,
            "applicationDomainReleasedCount":_diagnosticApplicationDomainReleasedCount,
            "livePreloadSessions":livePreloadSessions,
            "activePreloadSessions":activePreloadSessions,
            "disposedPreloadSessions":disposedPreloadSessions,
            "preloadInFlightCount":preloadInFlightCount,
            "preloadPendingCount":preloadPendingCount,
            "preloadStartedCount":_diagnosticPreloadStartedCount,
            "preloadCompletedCount":_diagnosticPreloadCompletedCount,
            "preloadDisposedWhileLoadingCount":_diagnosticPreloadDisposedWhileLoadingCount,
            "currentResourceAgeMs":currentResourceAgeMs,
            "traceDroppedCount":_diagnosticTraceDroppedCount,
            "stageChildren":stageChildren,
            "panelChildren":panelChildren,
            "stageFrameRate":stageFrameRate,
            "frameWindowMs":frameWindowMs,
            "frameSampleCount":frameSampleCount,
            "longFrame50Count":longFrame50Count,
            "longFrame100Count":longFrame100Count,
            "longFrame200Count":longFrame200Count,
            "maxFrameGapMs":maxFrameGapMs
         });
      }

      private static function onAolaBattleDrainTraceEvents() : String
      {
         var events:Array = [];
         var index:int = 0;
         var position:int = 0;
         while(index < _diagnosticTraceCount)
         {
            position = (_diagnosticTraceHead + index) % MAX_TRACE_EVENTS;
            events.push(_diagnosticTraceEvents[position]);
            _diagnosticTraceEvents[position] = null;
            ++index;
         }
         _diagnosticTraceHead = 0;
         _diagnosticTraceCount = 0;
         return JSON.stringify({
            "version":TRACE_VERSION,
            "droppedEventCount":_diagnosticTraceDroppedCount,
            "events":events
         });
      }

      private function compileMe() : void
      {
         var service:PetFightService = null;
      }
   }
}
