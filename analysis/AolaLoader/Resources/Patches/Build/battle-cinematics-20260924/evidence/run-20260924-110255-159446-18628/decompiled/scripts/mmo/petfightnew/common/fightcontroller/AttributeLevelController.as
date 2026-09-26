package mmo.petfightnew.common.fightcontroller
{
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.panel.AttributeLevelPanel;
   
   public class AttributeLevelController
   {
      
      private static var _instance:AttributeLevelController;
      
      private var _panel:AttributeLevelPanel;
      
      public function AttributeLevelController()
      {
         super();
      }
      
      public static function get instance() : AttributeLevelController
      {
         if(_instance == null)
         {
            _instance = new AttributeLevelController();
         }
         return _instance;
      }
      
      public function addAttributeLevelPanel(param1:int) : void
      {
         var _loc2_:int = FightData.instance.getSlotId(param1);
         var _loc3_:PlayerBattleInfo = FightData.instance.playerInfo[_loc2_] as PlayerBattleInfo;
         if(_loc3_ == null)
         {
            return;
         }
         var _loc4_:PetBriefInfo = _loc3_.myPets[0] as PetBriefInfo;
         if(_loc4_ == null)
         {
            return;
         }
         if(this._panel == null)
         {
            this._panel = new AttributeLevelPanel();
         }
         this._panel.setPet(_loc4_);
         var _loc5_:MCPetContainer = FightController.instance.fightPanel.petMCList[param1] as MCPetContainer;
         this._panel.x = _loc5_.x + 10;
         this._panel.y = _loc5_.y - 150;
         FightController.instance.fightPanel.layerUIAndReplay.addChild(this._panel);
      }
      
      public function removeAttributeLevelPanel(param1:int) : void
      {
         DisplayUtil.stopAndRemove(this._panel);
      }
      
      public function dispose() : void
      {
         this._panel = null;
         _instance = null;
      }
   }
}

