      // 本地显示覆盖，不调用 ControlBarSkinClient.setSkin。
      private var _aolaThemeId:int = 0;
      private var _aolaWantedTheme:int = 0;
      private var _aolaRequest:int = -1;
      private var _aolaStatus:String = "NotReady";
      private var _aolaError:String = "";
      private var _aolaLoading:Boolean = false;
      private var _aolaThemes:Object = {};
      private var _aolaLoaders:Array = [];
      private static var _aolaListeners:flash.utils.Dictionary = new flash.utils.Dictionary(true);
      private static var _aolaBuilding:Boolean = false;
      private static var _aolaBuildingOwner:Object;
      private static var _aolaOwner:Object;
      private static var _aolaOwners:flash.utils.Dictionary = new flash.utils.Dictionary(true);
      private static var _aolaLocks:flash.utils.Dictionary = new flash.utils.Dictionary(true);

      public static function beginThemeOwner(owner:Object) : void
      {
         _aolaOwner = owner; _aolaOwners[owner] = owner;
         if(_aolaBuilding) _aolaBuildingOwner = owner;
      }

      public static function endThemeOwner() : void { _aolaOwner = null; }

      public static function initThemeLock(owner:Object, view:MovieClip) : void
      {
         if(_aolaLocks[owner] == null) _aolaLocks[owner] = new mmo.controlv2.lock.ControlBarLockHelper(view);
         else _aolaLocks[owner].updteLockState();
      }

      private static function themeOwner(owner:Object) : Object
      {
         if(_aolaOwners[owner] != null) return _aolaOwners[owner];
         if(_aolaOwner != null) { _aolaOwners[owner] = _aolaOwner; return _aolaOwner; }
         return null;
      }

      public static function applyTheme(themeId:int, requestId:int) : String
      {
         if(_instance == null) return JSON.stringify({status:"NotReady",requestId:requestId,themeId:themeId,message:""});
         return _instance.applyLocalTheme(themeId,requestId);
      }

      public static function trackAddListener(owner:Object, dispatcher:Object, type:String, listener:Function,
         capture:Boolean = false, priority:int = 0, weak:Boolean = false) : void
      {
         owner = themeOwner(owner);
         if(owner == null) { dispatcher.addEventListener(type,listener,capture,priority,weak); return; }
         var state:Object = _aolaListeners[owner];
         if(state == null)
         {
            state = {active:true, entries:[]};
            _aolaListeners[owner] = state;
         }
         for each(var item:Object in state.entries)
         {
            if(item.dispatcher === dispatcher && item.type == type && item.listener === listener && item.capture == capture) return;
         }
         state.entries.push({dispatcher:dispatcher,type:type,listener:listener,capture:capture,priority:priority,weak:weak});
         if(state.active) dispatcher.addEventListener(type,listener,capture,priority,weak);
      }

      public static function trackRemoveListener(owner:Object, dispatcher:Object, type:String, listener:Function,
         capture:Boolean = false) : void
      {
         dispatcher.removeEventListener(type,listener,capture);
         owner = themeOwner(owner);
         if(owner == null) return;
         var state:Object = _aolaListeners[owner];
         if(state == null) return;
         for(var i:int = state.entries.length - 1; i >= 0; --i)
         {
            var item:Object = state.entries[i];
            if(item.dispatcher === dispatcher && item.type == type && item.listener === listener && item.capture == capture) state.entries.splice(i,1);
         }
      }

      private static function setThemeListeners(owner:Object, active:Boolean) : void
      {
         var state:Object = _aolaListeners[owner];
         if(state == null || state.active == active) return;
         state.active = active;
         for each(var item:Object in state.entries)
         {
            if(active) item.dispatcher.addEventListener(item.type,item.listener,item.capture,item.priority,item.weak);
            else item.dispatcher.removeEventListener(item.type,item.listener,item.capture);
         }
      }

      public function applyLocalTheme(themeId:int, requestId:int) : String
      {
         if(requestId < _aolaRequest) return themeResult("Superseded",requestId,themeId);
         if(requestId != _aolaRequest)
         {
            _aolaRequest = requestId; _aolaWantedTheme = themeId; _aolaError = ""; _aolaStatus = "NotReady";
         }
         if(_aolaStatus == "Failed") return themeResult(_aolaStatus,_aolaRequest,_aolaWantedTheme);
         var current:ControlBarSkinBase = getCurrentSkin();
         var fight:Object = ServiceContainer.getService(flash.utils.getDefinitionByName("mmo.interfaces.pet.fight.IPetFight"));
         if(fight != null && fight.isFighting()) return themeResult("WaitingBattleEnd",requestId,themeId);
         if(current == null || current.stage == null) return themeResult("NotReady",requestId,themeId);
         for(var ancestor:flash.display.DisplayObject = current.controlBarView; ancestor != null; ancestor = ancestor.parent)
            if(!ancestor.visible) return themeResult("NotReady",requestId,themeId);
         if(_aolaLoading) return themeResult("Loading",requestId,themeId);
         if(themeId == _aolaThemeId) { _aolaStatus = "Applied"; return themeResult(_aolaStatus,requestId,themeId); }
         if(themeId == 0 || _aolaThemes.hasOwnProperty(String(themeId)))
         {
            activateLocalTheme(themeId);
            return themeResult(_aolaStatus,requestId,themeId);
         }
         _aolaLoading = true; _aolaStatus = "Loading";
         var loader:flash.display.Loader = new flash.display.Loader();
         var self:ControlBarSkinHandler = this;
         var onError:Function = function(event:flash.events.Event):void
         {
            loader.contentLoaderInfo.removeEventListener(flash.events.Event.COMPLETE,onComplete);
            loader.contentLoaderInfo.removeEventListener(flash.events.IOErrorEvent.IO_ERROR,onError);
            loader.contentLoaderInfo.removeEventListener(flash.events.SecurityErrorEvent.SECURITY_ERROR,onError);
            self._aolaLoading = false;
            if(self._aolaWantedTheme == themeId) { self._aolaStatus = "Failed"; self._aolaError = event.toString(); }
            self.notifyThemeResult();
         };
         var onComplete:Function = function(event:flash.events.Event):void
         {
            loader.contentLoaderInfo.removeEventListener(flash.events.Event.COMPLETE,onComplete);
            loader.contentLoaderInfo.removeEventListener(flash.events.IOErrorEvent.IO_ERROR,onError);
            loader.contentLoaderInfo.removeEventListener(flash.events.SecurityErrorEvent.SECURITY_ERROR,onError);
            self._aolaLoading = false;
            try
            {
               var cls:Class = loader.contentLoaderInfo.applicationDomain.getDefinition(
                  "aola.theme.t" + themeId + ".mmo.controlv2.controlbarskin.skin.Skin" + themeId) as Class;
               var view:MovieClip = new cls() as MovieClip;
               _aolaBuilding = true;
               _aolaBuildingOwner = null;
               var skin:ControlBarSkinBase = new ControlBarSkinBase(self._usingSkinId,view);
               _aolaBuilding = false;
               _aolaBuildingOwner = null;
               setThemeListeners(skin,false);
               self._aolaThemes[String(themeId)] = skin;
               self._aolaLoaders.push(loader);
               self.applyLocalTheme(self._aolaWantedTheme,self._aolaRequest);
            }
            catch(error:Error)
            {
               if(_aolaBuildingOwner != null) setThemeListeners(_aolaBuildingOwner,false);
               _aolaBuilding = false; _aolaBuildingOwner = null; _aolaOwner = null;
               if(self._aolaWantedTheme == themeId) { self._aolaStatus = "Failed"; self._aolaError = error.message; }
            }
            self.notifyThemeResult();
         };
         loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE,onComplete);
         loader.contentLoaderInfo.addEventListener(flash.events.IOErrorEvent.IO_ERROR,onError);
         loader.contentLoaderInfo.addEventListener(flash.events.SecurityErrorEvent.SECURITY_ERROR,onError);
         try
         {
            loader.load(new flash.net.URLRequest("https://aola.100bt.com/play/aola-helper/theme/skin" + themeId + ".swf"),
               new flash.system.LoaderContext(false,new flash.system.ApplicationDomain(flash.system.ApplicationDomain.currentDomain)));
         }
         catch(error:Error)
         {
            _aolaLoading = false; _aolaStatus = "Failed"; _aolaError = error.message;
         }
         return themeResult(_aolaStatus,requestId,themeId);
      }

      private function activateLocalTheme(themeId:int) : void
      {
         var previousId:int = _aolaThemeId;
         var previous:ControlBarSkinBase = getCurrentSkin();
         var next:ControlBarSkinBase = themeId == 0 ? getNativeSkin() : _aolaThemes[String(themeId)];
         try
         {
            previous.removeFromStage(); setThemeListeners(previous,false);
            _aolaThemeId = themeId;
            setThemeListeners(next,true); next.addToStage();
            _aolaStatus = "Applied";
         }
         catch(error:Error)
         {
            if(next != null) { next.removeFromStage(); setThemeListeners(next,false); }
            _aolaThemeId = previousId;
            setThemeListeners(previous,true); previous.addToStage();
            _aolaStatus = "Failed"; _aolaError = error.message;
         }
      }

      private function themeResult(status:String, requestId:int, themeId:int) : String
      {
         if(requestId == _aolaRequest && themeId == _aolaWantedTheme && status != "Superseded") _aolaStatus = status;
         return JSON.stringify({status:status,requestId:requestId,themeId:themeId,message:_aolaError});
      }

      private function notifyThemeResult() : void
      {
         if(flash.external.ExternalInterface.available)
            flash.external.ExternalInterface.call("aolaThemeCompleted",_aolaRequest,themeResult(_aolaStatus,_aolaRequest,_aolaWantedTheme));
      }
