package mmo.petfightnew.common.fightcontroller
{
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightItemData;
   import mmo.petfightnew.common.FightPanel;
   
   public class UseItem implements IDispose
   {
      
      private static var _instance:UseItem;
      
      private var fightPanel:FightPanel;
      
      public function UseItem()
      {
         super();
      }
      
      public static function get instance() : UseItem
      {
         if(_instance == null)
         {
            _instance = new UseItem();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
      }
      
      public function useItem(param1:Object) : void
      {
         var _loc5_:Object = null;
         var _loc6_:PlayerBattleInfo = null;
         var _loc7_:String = null;
         var _loc8_:String = null;
         var _loc9_:Array = null;
         var _loc10_:Object = null;
         var _loc11_:Object = null;
         var _loc2_:Array = param1.pmmList;
         var _loc3_:int = int(param1.id);
         if(param1.reqId == SocketClient.instance.myUserId)
         {
            FightItemData.instance.useItem(_loc3_,1);
         }
         FightController.instance.desc = param1.desc;
         FightController.instance.pmmStatuses = [];
         var _loc4_:int = 0;
         for each(_loc5_ in _loc2_)
         {
            _loc6_ = new PlayerBattleInfo();
            _loc6_.parseInfo(_loc5_);
            _loc6_ = FightData.instance.setLocaId(_loc6_);
            FightData.instance.playerInfo[_loc6_.slotId].myPets[0].updateInfo(_loc6_.myPets[0]);
            _loc7_ = _loc5_.hpIncList || "";
            _loc8_ = _loc5_.shp || "";
            _loc9_ = _loc5_.cbl || [];
            _loc10_ = _loc5_.kList || {};
            _loc11_ = {
               "hpInc":_loc5_.hpInc,
               "player":_loc6_,
               "srt":_loc5_.srt,
               "aor":0,
               "cri":_loc5_.cri,
               "isItem":true,
               "itemId":_loc3_,
               "hpIncList":_loc7_.split(","),
               "count":_loc4_++,
               "hpType":_loc5_.hpType,
               "shp":_loc8_.split(","),
               "skillWindWordList":_loc9_,
               "killList":_loc10_
            };
            FightController.instance.pmmStatuses.push(_loc11_);
         }
         this.fightPanel.refreshInfos(FightController.instance.pmmStatuses);
         this.fightPanel.refreshTxt(FightController.instance.desc);
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         _instance = null;
      }
   }
}

