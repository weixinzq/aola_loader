package mmo.petfightnew
{
   import flash.display.Sprite;
   import flash.external.ExternalInterface;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2710")]
   public class DocPetFight extends Sprite
   {
      
      private static const BRIDGE_VERSION:int = 4;
      
      public static var hideDamageNumbers:Boolean = false;
      
      public static var hideHealingNumbers:Boolean = false;
      
      public static var skipBattlePresentation:Boolean = false;
      
      private static var _aolaBattleBridgeRegistered:Boolean = false;
      
      private static var _readyEpoch:int = 0;
      
      public function DocPetFight()
      {
         super();
      }
      
      public static function ensureAolaBattleBridge() : void
      {
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
            if(!hasRequiredOptions(options) || typeof options.version != "number" || int(options.version) != options.version || int(options.version) != BRIDGE_VERSION || typeof options.revision != "number" || int(options.revision) != options.revision || int(options.revision) < 0 || typeof options.hideDamageNumbers != "boolean" || typeof options.hideHealingNumbers != "boolean" || typeof options.skipBattlePresentation != "boolean")
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
         return Boolean(param1.hasOwnProperty("version")) && Boolean(param1.hasOwnProperty("revision")) && Boolean(param1.hasOwnProperty("hideDamageNumbers")) && Boolean(param1.hasOwnProperty("hideHealingNumbers")) && Boolean(param1.hasOwnProperty("skipBattlePresentation"));
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
      
      private function compileMe() : void
      {
         var service:PetFightService = null;
      }
   }
}

