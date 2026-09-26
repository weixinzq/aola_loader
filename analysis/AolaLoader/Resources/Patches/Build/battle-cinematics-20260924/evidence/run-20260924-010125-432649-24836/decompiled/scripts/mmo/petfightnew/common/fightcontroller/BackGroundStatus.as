package mmo.petfightnew.common.fightcontroller
{
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.util.BSUtil;
   
   public class BackGroundStatus implements IDispose
   {
      
      private static var _instance:BackGroundStatus;
      
      private var fightPanel:FightPanel;
      
      public function BackGroundStatus()
      {
         super();
      }
      
      public static function get instance() : BackGroundStatus
      {
         if(_instance == null)
         {
            _instance = new BackGroundStatus();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
      }
      
      public function status(param1:Object) : void
      {
         var _loc3_:Object = null;
         var _loc4_:String = null;
         var _loc5_:Array = null;
         var _loc6_:PlayerBattleInfo = null;
         var _loc7_:String = null;
         var _loc8_:String = null;
         var _loc9_:String = null;
         var _loc10_:Array = null;
         var _loc11_:Object = null;
         var _loc12_:Object = null;
         var _loc2_:Array = param1.pmmList;
         FightController.instance.desc = param1.desc;
         FightController.instance.pmmStatuses = [];
         for each(_loc3_ in _loc2_)
         {
            if(Boolean(_loc3_.battleView.pmList) && _loc3_.battleView.pmList.length > 0)
            {
               _loc6_ = new PlayerBattleInfo();
               _loc6_.parseInfo(_loc3_);
               if(_loc6_.slotId >= 0)
               {
                  _loc6_ = FightData.instance.setLocaId(_loc6_);
                  FightData.instance.playerInfo[_loc6_.slotId].myPets[0].updateInfo(_loc6_.myPets[0]);
                  _loc7_ = PetBriefInfo(_loc6_.myPets[0]).status;
                  _loc8_ = _loc3_.hpIncList || "";
                  _loc9_ = _loc3_.shp || "";
                  _loc10_ = _loc3_.cbl || [];
                  _loc11_ = _loc3_.kList || {};
                  _loc12_ = {
                     "hpInc":_loc3_.hpInc,
                     "player":_loc6_,
                     "srt":_loc3_.srt,
                     "aor":0,
                     "cri":_loc3_.cri,
                     "isStatus":true,
                     "status":_loc7_,
                     "hpIncList":_loc8_.split(","),
                     "ifShowStateMovie":false,
                     "hpType":_loc3_.hpType,
                     "shp":_loc9_.split(","),
                     "skillWindWordList":_loc10_,
                     "killList":_loc11_
                  };
                  FightController.instance.pmmStatuses.push(_loc12_);
               }
            }
         }
         _loc4_ = BSUtil.parseBS(param1.bs);
         this.fightPanel.setBS(_loc4_);
         _loc5_ = BSUtil.parseBackGroundUp(param1.bs);
         this.fightPanel.setBackGroundUp(_loc5_);
         this.fightPanel.setPetUp(param1);
         if(_loc4_ != null && _loc4_.length > 0 && _loc2_.length > 0)
         {
            new BackGroundMovieManager().playMC(_loc4_,this.fightPanel);
         }
         this.fightPanel.refreshInfos(FightController.instance.pmmStatuses);
         this.fightPanel.refreshTxt(FightController.instance.desc + " 。");
         if(FightController.instance.pmmStatuses.length > 0)
         {
            FightController.instance.startHandle();
         }
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         _instance = null;
      }
   }
}

