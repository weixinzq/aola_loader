package mmo.petfightnew.common.fightcontroller
{
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.fighttalk.FightTalkEvent;
   import mmo.interfaces.fighttalk.FightTalkEventDispatcher;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   
   public class FightTalk
   {
      
      private static var _instance:FightTalk;
      
      private var fightPanel:FightPanel;
      
      private var curMsg:String;
      
      private var curUserId:int;
      
      public function FightTalk()
      {
         super();
      }
      
      public static function get instance() : FightTalk
      {
         if(_instance == null)
         {
            _instance = new FightTalk();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
         FightTalkEventDispatcher.instance.addEventListener(FightTalkEvent.FightingPersonTalk,this.onTalk);
      }
      
      public function dispose() : void
      {
         FightTalkEventDispatcher.instance.removeEventListener(FightTalkEvent.FightingPersonTalk,this.onTalk);
         this.fightPanel = null;
         _instance = null;
      }
      
      private function onTalk(param1:FightTalkEvent) : void
      {
         this.curMsg = param1.params.mes;
         this.curUserId = param1.params.uid;
         var _loc2_:int = FightData.instance.getLocaIdByUserId(this.curUserId);
         var _loc3_:int = int(param1.params.second);
         this.fightPanel.petSay(_loc2_,this.curMsg,_loc3_);
      }
      
      public function onPetTalk(param1:Object) : void
      {
         var _loc3_:Object = null;
         var _loc2_:Array = param1.extTalk.msg;
         if(Boolean(_loc2_) && _loc2_.length > 0)
         {
            for each(_loc3_ in _loc2_)
            {
               SocketClient.instance.dispatchEvent(new SocketClientEvent("extTalk",{
                  "t":_loc3_.t,
                  "msg":_loc3_.msg,
                  "un":_loc3_.un,
                  "nn":_loc3_.nn,
                  "id":_loc3_.id,
                  "second":30
               }));
            }
         }
      }
   }
}

