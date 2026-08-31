package mmo.checkversion
{
   import flash.display.Loader;
   import flash.display.LoaderInfo;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.KeyboardEvent;
   import flash.external.ExternalInterface;
   import flash.media.Sound;
   import flash.net.URLLoader;
   import flash.net.URLLoaderDataFormat;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.text.StyleSheet;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.ui.ContextMenu;
   import flash.utils.ByteArray;
   
   public class Load extends Sprite
   {
      private static const ACT_CLIENT_SENDER:String = "mmo.play.actthings.data.ActClientSender";
      
      private static const PANEL_HELPER:String = "mmo.play.activity.helper.Panel_Helper";
      
      private static const MAX_PENDING_COMMANDS:int = 256;
      
      private static const EXTENSIONS:Object = {
         "StartupExtension":true,"UserExtension":true,"TeamExtension":true,
         "BuddyManagerExtension":true,"ScoreManager":true,"Log":true,
         "SurveyExtension":true,"PlayBookExtension":true,"OneOffExtension":true,
         "MemberExtension":true,"GameRealTimeRankManager":true,"GameMessageList":true,
         "UserDisplayExtension":true,"PocketMonsterExtension":true,"PetFightExtension":true,
         "PetExtension":true,"PetExtension2":true,"PetEggExtension":true,
         "AntiAddictionExtension":true,"TowerExtension":true,"SynthesizeExtension":true,
         "MaterialExtension":true,"RobotExtension":true,"MatchExtension":true,
         "FightRingExtension":true,"RobMedalArenaExtension":true,"HouseExtension":true,
         "UserFurntitureInfoExtension":true,"ShootExtension":true,"TaskExtension":true,
         "DailyTaskExtension":true,"GiftBagExtension":true,"AvatarExtension":true,
         "FollowExtension":true,"SundriesExtension":true,"FBExtension":true,
         "AvocationExtension":true,"MidautumnGameExtension":true,"MoveStateExtension":true,
         "UserStateExtension":true,"AchievementExtension":true,"NewAreaExtension":true,
         "HolidayExtension":true,"MailBoxExtension":true,"PTowerExtension":true,
         "PMDailyCollectExtension":true,"VipNickNameExtension":true,"VipTowerExtension":true,
         "PlantExtension":true,"PlantItemExtension":true,"ConnectTestExtension":true,
         "WisdomStarExtension":true,"DonateExtension":true,"BalloonExtension":true,
         "UserGameExtension":true,"PlaneChessGameManager":true,"PeriodicActiveExtension":true,
         "MagicCubicExtension":true,"WarTeamExtension":true,"WTBeatBossExtension":true,
         "HouseOutSideExtension":true,"WarTeamTaskExtension":true,"PiracyTowerExtension":true,
         "MentalHallExtension":true,"ZooExtension":true,"StateExtension":true,
         "HotSpringExtension":true,"MSExtension":true,"LabExtension":true,
         "KOFExtension":true,"FieldGameExtension":true,"HbhBeatBossExtension":true,
         "TeamTowerExtension":true,"LuandouExtension":true,"Sundries2ndExtension":true,
         "GalaxyExtension":true,"PetEquipExtension":true,"BattleGodExtension":true,
         "CorpsExtension":true,"SpeedTestExtension":true,"LightWingExtension":true,
         "XSystemExtension":true,"StarBossExtension":true,"FiveYearPKExtension":true,
         "KaiSaExtension":true,"BurningCrusadeExtension":true,"TrainingExtension":true
      };
      
      private static var _aolaBridgeRegistered:Boolean;
      
      private static var _aolaPending:Object = {};
      
      private static var _aolaPendingCount:int;
      
      internal var mc:MovieClip;
      
      internal var txt:TextField;
      
      private const showMemory:Boolean = false;
      
      private const showCode:String = "showmethememory";
      
      private var startGetCode:Boolean;
      
      private var code:String;
      
      public var version:XML;
      
      public var loaderSwfBtyes:ByteArray;
      
      public function Load()
      {
         var _loc2_:ContextMenu = null;
         super();
         this.ensureAolaBridge();
         if(this.stage.loaderInfo.url.indexOf("www.mygame.com") < 0)
         {
            _loc2_ = new ContextMenu();
            _loc2_.hideBuiltInItems();
            this.contextMenu = _loc2_;
         }
         var _loc1_:Sound = new Sound(new URLRequest(""));
         _loc1_.play();
         _loc1_.close();
         stage.stageFocusRect = false;
         this.loadVersion();
         this.addEventListener(Event.ADDED_TO_STAGE,this.onAddedToStage);
      }
      
      private function ensureAolaBridge() : void
      {
         if(_aolaBridgeRegistered)
         {
            return;
         }
         try
         {
            if(ExternalInterface.available)
            {
               ExternalInterface.addCallback("aolaSendCommand",this.onAolaSendCommand);
               ExternalInterface.addCallback("aolaOpenPanel",this.onAolaOpenPanel);
               ExternalInterface.addCallback("aolaSetPlayback",this.onAolaSetPlayback);
               _aolaBridgeRegistered = true;
            }
         }
         catch(error:Error)
         {
         }
      }
      
      private function onAolaSendCommand(param1:String, param2:String, param3:String, param4:String) : String
      {
         var parameters:Object = null;
         var sender:Object = null;
         var requestId:String = param1 == null ? "" : param1;
         var extension:String = param2 == null ? "" : param2;
         var command:String = param3 == null ? "" : param3;
         var parametersJson:String = param4 == null ? "" : param4;
         if(!/^[a-f0-9]{32}$/.test(requestId) || !EXTENSIONS.hasOwnProperty(extension) ||
            command.length == 0 || command.length > 256 || command != command.replace(/^\s+|\s+$/g,"") ||
            parametersJson.length == 0 || parametersJson.length > 262144 ||
            _aolaPending.hasOwnProperty(requestId) || _aolaPendingCount >= MAX_PENDING_COMMANDS)
         {
            return "FlashRejected";
         }
         try
         {
            parameters = JSON.parse(parametersJson);
            if(parameters == null || parameters is Array || typeof parameters != "object")
            {
               return "FlashRejected";
            }
            if(parameters.hasOwnProperty(":ext_seq;"))
            {
               delete parameters[":ext_seq;"];
            }
            if(!ApplicationDomain.currentDomain.hasDefinition(ACT_CLIENT_SENDER))
            {
               return "BridgeNotReady";
            }
            sender = ApplicationDomain.currentDomain.getDefinition(ACT_CLIENT_SENDER);
            if(sender == null || !(sender["sendMessage"] is Function))
            {
               return "BridgeNotReady";
            }
            _aolaPending[requestId] = true;
            ++_aolaPendingCount;
            sender["sendMessage"](extension,command,parameters,function(param1:Object):void
            {
               onAolaCommandResponse(requestId,param1);
            },false);
            return "SubmittedToFlash";
         }
         catch(error:Error)
         {
            this.removeAolaPending(requestId);
         }
         return "FlashRejected";
      }
      
      private function onAolaCommandResponse(param1:String, param2:Object) : void
      {
         var code:int = 0;
         var hasCode:Boolean = false;
         this.removeAolaPending(param1);
         if(param2 == null)
         {
            return;
         }
         if(param2.hasOwnProperty("r"))
         {
            code = int(param2.r);
            hasCode = true;
         }
         else if(param2.hasOwnProperty("suc"))
         {
            code = int(param2.suc);
            hasCode = true;
         }
         else if(param2.hasOwnProperty("res"))
         {
            code = int(param2.res);
            hasCode = true;
         }
         if(hasCode)
         {
            this.notifyAolaCommandResult(param1,code == 1 ? "ServerSucceeded" : "ServerRejected",code.toString());
         }
      }
      
      private function removeAolaPending(param1:String) : void
      {
         if(_aolaPending.hasOwnProperty(param1))
         {
            delete _aolaPending[param1];
            --_aolaPendingCount;
         }
      }
      
      private function notifyAolaCommandResult(param1:String, param2:String, param3:String) : void
      {
         try
         {
            if(ExternalInterface.available)
            {
               ExternalInterface.call("aolaCommandCompleted",param1,param2,param3);
            }
         }
         catch(error:Error)
         {
         }
      }
      
      private function onAolaOpenPanel(param1:String, param2:String) : String
      {
         var panelHelper:Object = null;
         var resourceUrl:String = param1 == null ? "" : param1;
         var resourceCls:String = param2 == null ? "" : param2;
         if(resourceUrl.length == 0 || resourceUrl.length > 2048 ||
            resourceCls.length == 0 || resourceCls.length > 2048)
         {
            return "PanelRejected";
         }
         try
         {
            if(!ApplicationDomain.currentDomain.hasDefinition(PANEL_HELPER))
            {
               return "PanelUnavailable";
            }
            panelHelper = ApplicationDomain.currentDomain.getDefinition(PANEL_HELPER);
            if(panelHelper == null || !(panelHelper["loadResAndShow"] is Function))
            {
               return "PanelUnavailable";
            }
            panelHelper["loadResAndShow"](resourceUrl,resourceCls);
            return "PanelOpenRequested";
         }
         catch(error:Error)
         {
         }
         return "PanelRejected";
      }
      
      private function onAolaSetPlayback(param1:int, param2:String) : String
      {
         var quality:String = param2 == null ? "" : param2.toLowerCase();
         if((param1 != 0 && param1 != 25 && param1 != 50 && param1 != 75) ||
            (quality != "" && quality != "high" && quality != "best") ||
            (param1 == 0 && quality == ""))
         {
            return "PlaybackRejected";
         }
         if(this.stage == null)
         {
            return "PlaybackUnavailable";
         }
         try
         {
            if(param1 > 0)
            {
               this.stage.frameRate = param1;
            }
            if(quality.length > 0)
            {
               this.stage.quality = quality;
            }
            return "PlaybackApplied|" + int(this.stage.frameRate).toString() + "|" + String(this.stage.quality);
         }
         catch(error:Error)
         {
         }
         return "PlaybackRejected";
      }
      
      private function onAddedToStage(param1:Event) : void
      {
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onAddedToStage);
         var _loc2_:TextField = new TextField();
         var _loc3_:StyleSheet = new StyleSheet();
         _loc3_.setStyle("a:hover",{"textDecoration":"underline"});
         _loc3_.setStyle("a:link",{"color":"#0000FF"});
         _loc2_.styleSheet = _loc3_;
         var _loc4_:String = "即将抵达奥拉星...";
         _loc2_.htmlText = _loc4_;
         _loc2_.autoSize = TextFieldAutoSize.LEFT;
         _loc2_.x = (960 - _loc2_.width) * 0.5;
         _loc2_.y = (560 - _loc2_.height) * 0.5;
         _loc2_.name = "start";
         _loc2_.selectable = false;
         stage.addChild(_loc2_);
      }
      
      private function loadVersion() : void
      {
         var _loc1_:URLRequest = null;
         var _loc3_:Date = null;
         if(this.stage.loaderInfo.url.indexOf("file://") == 0)
         {
            _loc1_ = new URLRequest("start.xml");
         }
         else
         {
            _loc3_ = new Date();
            _loc1_ = new URLRequest("start~" + _loc3_.valueOf().toString() + ".xml");
         }
         var _loc2_:URLLoader = new URLLoader(_loc1_);
         _loc2_.addEventListener(Event.COMPLETE,this.onLoadVersion);
         _loc2_.addEventListener(IOErrorEvent.IO_ERROR,this.onLoadVersionError);
      }
      
      private function jsGetValue(param1:String, param2:*, ... rest) : *
      {
         var result:* = undefined;
         var functionName:String = param1;
         var defaultValue:* = param2;
         var arguments:Array = rest;
         try
         {
            if(!ExternalInterface.available)
            {
               return defaultValue;
            }
            result = ExternalInterface.call(functionName,arguments);
            return result == undefined ? defaultValue : result;
         }
         catch(errObject:Error)
         {
            return defaultValue;
         }
      }
      
      private function getTestCode() : String
      {
         var _loc1_:String = null;
         try
         {
            if(!ExternalInterface.available)
            {
               return null;
            }
            return ExternalInterface.call("getQS","testf");
         }
         catch(errObject:Error)
         {
         }
         return null;
      }
      
      private function onLoadVersionError(param1:IOErrorEvent) : void
      {
         this.loadVersion();
      }
      
      private function onLoadVersion(param1:Event) : void
      {
         this.version = XML(URLLoader(param1.target).data);
         if(this.version.t != "open" && this.getTestCode() == null)
         {
            if(this.version.v.length > 0)
            {
               this.load(String(this.version.t) + "~" + this.version.v + ".swf");
            }
            else
            {
               this.load(String(this.version.t) + ".swf");
            }
            stage.getChildByName("start").visible = false;
            return;
         }
         var _loc2_:String = "";
         if(this.version.lv != undefined)
         {
            _loc2_ = this.version.lv;
         }
         else if(this.version.v != undefined)
         {
            _loc2_ = this.version.v;
         }
         if(_loc2_.length > 0)
         {
            this.load("loader" + "~" + _loc2_ + ".swf");
         }
         else
         {
            this.load("loader.swf");
         }
      }
      
      private function load(param1:String) : void
      {
         var _loc2_:URLRequest = new URLRequest(param1);
         var _loc3_:URLLoader = new URLLoader();
         _loc3_.dataFormat = URLLoaderDataFormat.BINARY;
         _loc3_.addEventListener(Event.COMPLETE,this.onURLLoadSuccess);
         _loc3_.load(_loc2_);
      }
      
      private function onURLLoadSuccess(param1:Event) : void
      {
         var _loc2_:URLLoader = param1.target as URLLoader;
         _loc2_.removeEventListener(Event.COMPLETE,this.onURLLoadSuccess);
         this.loaderSwfBtyes = _loc2_.data;
         var _loc3_:Loader = new Loader();
         _loc3_.contentLoaderInfo.addEventListener(Event.COMPLETE,this.onLoadSuccess);
         _loc3_.loadBytes(this.loaderSwfBtyes,new LoaderContext(false,ApplicationDomain.currentDomain));
      }
      
      private function onLoadSuccess(param1:Event) : void
      {
         var _loc4_:MemoryWatch = null;
         var _loc2_:LoaderInfo = param1.target as LoaderInfo;
         _loc2_.removeEventListener(Event.COMPLETE,this.onLoadSuccess);
         var _loc3_:TextField = stage.getChildByName("start") as TextField;
         if(Boolean(_loc3_) && Boolean(_loc3_.parent))
         {
            _loc3_.parent.removeChild(_loc3_);
         }
         this.addChild(Sprite(_loc2_.content));
         if(this.showMemory)
         {
            _loc4_ = new MemoryWatch();
            this.addChild(_loc4_);
         }
         else
         {
            this.stage.addEventListener(KeyboardEvent.KEY_DOWN,this.onKeyInput);
         }
      }
      
      private function onKeyInput(param1:KeyboardEvent) : void
      {
         var _loc2_:MemoryWatch = null;
         if(param1.ctrlKey && param1.altKey)
         {
            this.startGetCode = true;
            this.code = "";
         }
         else if(this.startGetCode)
         {
            this.code += String.fromCharCode(param1.charCode);
            if(this.code.length == this.showCode.length)
            {
               if(this.code == this.showCode)
               {
                  _loc2_ = new MemoryWatch();
                  this.addChild(_loc2_);
                  this.stage.removeEventListener(KeyboardEvent.KEY_DOWN,this.onKeyInput);
               }
               else
               {
                  this.startGetCode = false;
               }
            }
         }
      }
   }
}
