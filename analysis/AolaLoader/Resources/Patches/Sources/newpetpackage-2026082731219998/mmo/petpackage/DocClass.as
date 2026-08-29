package mmo.petpackage
{
   import flash.display.MovieClip;
   import flash.external.ExternalInterface;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.data.ActClientSender;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.service.PetPackageService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol401")]
   public class DocClass extends MovieClip
   {

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

      private static var _aolaCommandBridgeRegistered:Boolean = false;

      private static var _aolaPending:Object = {};
      
      public function DocClass()
      {
         super();
         ensureAolaCommandBridge();
      }

      public static function ensureAolaCommandBridge() : void
      {
         if(_aolaCommandBridgeRegistered)
         {
            return;
         }
         try
         {
            if(ExternalInterface.available)
            {
               ExternalInterface.addCallback("aolaSendCommand",onAolaSendCommand);
               ExternalInterface.addCallback("aolaOpenPanel",onAolaOpenPanel);
               _aolaCommandBridgeRegistered = true;
            }
         }
         catch(error:Error)
         {
         }
      }

      private static function onAolaOpenPanel(param1:String, param2:String) : String
      {
         var resourceUrl:String = param1 == null ? "" : param1;
         var resourceCls:String = param2 == null ? "" : param2;
         if(resourceUrl.length == 0 || resourceUrl.length > 2048 ||
            resourceCls.length == 0 || resourceCls.length > 2048)
         {
            return "PanelRejected";
         }
         try
         {
            Panel_Helper.loadResAndShow(resourceUrl,resourceCls);
            return "PanelOpenRequested";
         }
         catch(error:Error)
         {
         }
         return "PanelRejected";
      }

      private static function onAolaSendCommand(param1:String, param2:String, param3:String, param4:String) : String
      {
         var parameters:Object = null;
         var requestId:String = param1 == null ? "" : param1;
         var extension:String = param2 == null ? "" : param2;
         var command:String = param3 == null ? "" : param3;
         var parametersJson:String = param4 == null ? "" : param4;
         if(!/^[a-f0-9]{32}$/.test(requestId) || !EXTENSIONS.hasOwnProperty(extension) ||
            command.length == 0 || command.length > 256 || command != command.replace(/^\s+|\s+$/g,"") ||
            parametersJson.length == 0 || parametersJson.length > 262144 || _aolaPending.hasOwnProperty(requestId))
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
            _aolaPending[requestId] = true;
            ActClientSender.sendMessage(extension,command,parameters,function(param1:Object):void
            {
               onAolaCommandResponse(requestId,param1);
            },false);
            return "SubmittedToFlash";
         }
         catch(error:Error)
         {
            delete _aolaPending[requestId];
         }
         return "FlashRejected";
      }

      private static function onAolaCommandResponse(param1:String, param2:Object) : void
      {
         var code:int = 1;
         var hasCode:Boolean = false;
         delete _aolaPending[param1];
         if(param2 == null)
         {
            notifyAolaCommandResult(param1,"ServerRejected","invalid-response");
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
         notifyAolaCommandResult(param1,code == 1 ? "ServerSucceeded" : "ServerRejected",
            hasCode ? code.toString() : "");
      }

      private static function notifyAolaCommandResult(param1:String, param2:String, param3:String) : void
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
      
      private function compile() : void
      {
         var _loc1_:PetPackageService = null;
         var _loc2_:PetDetailDataMap = null;
      }
   }
}

