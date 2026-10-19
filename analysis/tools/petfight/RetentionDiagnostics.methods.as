      private static var _retentionObjects:Dictionary = new Dictionary(true);
      private static var _retentionSnapshotAt:int = -5000;

      private static function watchRetention(target:Object, kind:String, owner:int = 0) : Object
      {
         if(target == null) return null;
         var state:Object = _retentionObjects[target];
         if(state == null)
         {
            state = {id:nextDiagnosticObjectId(),kind:kind,owner:owner,createdAt:getTimer(),disposedAt:-1};
            _retentionObjects[target] = state;
         }
         return state;
      }

      private static function retentionId(target:Object, kind:String, owner:int) : int
      {
         var state:Object = watchRetention(target,kind,owner);
         return state == null ? 0 : int(state.id);
      }

      private static function retentionFailure(phase:String, error:Error) : void
      {
         addDiagnosticTrace("retention-read-error",phase + ";error=" + error.errorID,-1,0);
      }

      public static function noteRetentionModel(target:Object, race:int, face:int) : void
      {
         try
         {
            var state:Object = watchRetention(target,"model");
            state.race = race;
            state.face = face;
            addDiagnosticTrace("retention-model-created","id=" + state.id + ";race=" + race + ";face=" + face,-1,int(state.id));
         }
         catch(error:Error) { retentionFailure("model-create",error); }
      }

      public static function noteRetentionMovie(owner:Object, movie:Object, action:int) : void
      {
         try
         {
            var ownerState:Object = watchRetention(owner,"model");
            var state:Object = watchRetention(movie,"model-movie",int(ownerState.id));
            if(state != null)
               addDiagnosticTrace("retention-cache-link","owner=" + ownerState.id + ";movie=" + state.id + ";action=" + action,-1,int(state.id));
         }
         catch(error:Error) { retentionFailure("cache-link",error); }
      }

      public static function noteRetentionModelDisposed(target:Object, baseDisposed:Boolean, callback:Function, loader:Object, config:Object) : void
      {
         try
         {
            var state:Object = watchRetention(target,"model");
            state.disposedAt = getTimer();
            state.baseDisposed = baseDisposed;
            state.callbackHeld = callback != null;
            state.loaderId = retentionId(loader,"model-loader",int(state.id));
            state.configId = retentionId(config,"model-config",int(state.id));
            state.configEntries = 0;
            if(config != null)
               for(var key:String in config) ++state.configEntries;
            addDiagnosticTrace("retention-model-disposed",modelRetentionText(state),-1,int(state.id));
         }
         catch(error:Error) { retentionFailure("model-dispose",error); }
      }

      private static function modelRetentionText(state:Object) : String
      {
         return "id=" + state.id + ";race=" + state.race + ";face=" + state.face +
            ";baseDisposed=" + int(Boolean(state.baseDisposed)) + ";callbackHeld=" + int(Boolean(state.callbackHeld)) +
            ";loader=" + state.loaderId + ";config=" + state.configId + ";configEntries=" + state.configEntries;
      }

      public static function noteRetentionStartDisposed(target:Object, timer:Object, tasks:Object, view:Object, role:Object, other:Object, signs:Object) : void
      {
         try
         {
            var state:Object = _diagnosticStartMovies[target];
            state.disposedAt = getTimer();
            state.fields = ";timerHeld=" + int(timer != null) + ";tasksHeld=" + int(tasks != null) +
               ";view=" + retentionId(view,"start-view",int(state.id)) +
               ";role=" + retentionId(role,"start-role",int(state.id)) +
               ";other=" + retentionId(other,"start-role",int(state.id)) +
               ";signs=" + retentionId(signs,"start-signs",int(state.id));
            addDiagnosticTrace("retention-start-disposed","id=" + state.id + state.fields,-1,int(state.id));
         }
         catch(error:Error) { retentionFailure("start-dispose",error); }
      }

      private static function recordRetentionSnapshots() : void
      {
         var now:int = getTimer();
         if(now - _retentionSnapshotAt < 5000) return;
         _retentionSnapshotAt = now;
         var target:Object;
         var state:Object;
         var display:flash.display.DisplayObjectContainer;
         var child:flash.display.DisplayObject;
         var domainState:Object;
         var domainIds:String;
         var age:int;
         try
         {
            for(target in _diagnosticStartMovies)
            {
               state = _diagnosticStartMovies[target];
               if(!Boolean(state.disposed)) continue;
               display = target as flash.display.DisplayObjectContainer;
               age = now - int(state.disposedAt);
               domainIds = "";
               for(var index:int = 0; index < display.numChildren; ++index)
               {
                  child = display.getChildAt(index);
                  domainState = child.loaderInfo == null ? null : _diagnosticApplicationDomains[child.loaderInfo.applicationDomain];
                  if(domainState != null && domainIds.indexOf("," + domainState.id + ",") < 0)
                     domainIds += "," + domainState.id + ",";
               }
               addDiagnosticTrace("retention-start-alive","id=" + state.id + ";parent=" + int(display.parent != null) +
                  ";children=" + display.numChildren + ";childDomains=" + domainIds + state.fields,age,int(state.id));
            }
         }
         catch(startError:Error) { retentionFailure("start-snapshot",startError); }
         try
         {
            for(target in _diagnosticApplicationDomains)
            {
               state = _diagnosticApplicationDomains[target];
               if(!Boolean(state.released)) continue;
               if(int(state.definitions) < 0) state.definitions = target.getQualifiedDefinitionNames().length;
               domainState = _diagnosticApplicationDomains[target.parentDomain];
               addDiagnosticTrace("retention-domain-alive","id=" + state.id + ";parent=" + (domainState == null ? 0 : int(domainState.id)) +
                  ";definitions=" + state.definitions,now - int(state.releasedAt),int(state.id));
            }
         }
         catch(domainError:Error) { retentionFailure("domain-snapshot",domainError); }
         try
         {
            for(target in _retentionObjects)
            {
               state = _retentionObjects[target];
               if(state.kind == "model")
               {
                  if(int(state.disposedAt) < 0) continue;
                  addDiagnosticTrace("retention-model-alive",modelRetentionText(state),now - int(state.disposedAt),int(state.id));
               }
               else
               {
                  display = target as flash.display.DisplayObjectContainer;
                  addDiagnosticTrace("retention-object-alive","id=" + state.id + ";kind=" + state.kind + ";owner=" + state.owner +
                     ";parent=" + (display == null ? -1 : int(display.parent != null)) +
                     ";children=" + (display == null ? -1 : display.numChildren),now - int(state.createdAt),int(state.id));
               }
            }
         }
         catch(objectError:Error) { retentionFailure("object-snapshot",objectError); }
      }
