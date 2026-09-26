package mmo.petfightnew.common.fightcontroller
{
   import flash.geom.Point;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.util.PositionUtil;
   
   public class SummonPetProcessor
   {
      
      private static var _instance:SummonPetProcessor = null;
      
      private var _callBack:Function = null;
      
      private var _fightPanel:FightPanel = null;
      
      public function SummonPetProcessor()
      {
         super();
      }
      
      public static function get instance() : SummonPetProcessor
      {
         if(_instance == null)
         {
            _instance = new SummonPetProcessor();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this._fightPanel = param1;
      }
      
      public function summonPet(param1:Array, param2:Function = null) : void
      {
         this._fightPanel.petLoadeNum -= param1.length;
         this._fightPanel.canStart = true;
         this._fightPanel.whoSwitch = 1;
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            this.initPetContainer(param1[_loc3_]);
            _loc3_++;
         }
      }
      
      private function initPetContainer(param1:PlayerBattleInfo) : void
      {
         var _loc8_:MCPetContainer = null;
         var _loc2_:int = int(param1.locaId);
         var _loc3_:PetBriefInfo = param1.myPets[0];
         var _loc4_:* = !FightData.instance.isMySide(param1.locaId);
         var _loc5_:MCPetContainer = new MCPetContainer(_loc3_,_loc4_,_loc2_,this._fightPanel.layerEffect);
         if(this._fightPanel.petMCList[_loc2_] != null)
         {
            _loc8_ = this._fightPanel.petMCList[_loc2_] as MCPetContainer;
            if(_loc8_.isLoading())
            {
               ++this._fightPanel.petLoadeNum;
               _loc8_.removeEventListener(PetFightEvent.GOT_PET,this.onGotPet);
            }
            _loc8_.dispose();
            MCPetContainer(this._fightPanel.petMCList[_loc2_]).dispose();
         }
         this._fightPanel.petMCList[_loc2_] = _loc5_;
         var _loc6_:Point = PositionUtil.getDefaultPosition(_loc2_);
         _loc5_.x = _loc6_.x;
         _loc5_.y = _loc6_.y;
         _loc5_.addEventListener(PetFightEvent.GOT_PET,this.onGotPet);
         _loc5_.startLoad();
         var _loc7_:int = this.getNewPetIndex(_loc5_.y,_loc2_);
         this._fightPanel.layerPet.addChildAt(_loc5_,_loc7_);
      }
      
      private function onGotPet(param1:PetFightEvent) : void
      {
         param1.stopImmediatePropagation();
         param1.currentTarget.removeEventListener(PetFightEvent.GOT_PET,this.onGotPet);
         this._fightPanel.onGotPet(param1);
         if(this._callBack != null)
         {
            this._callBack();
         }
      }
      
      private function getNewPetIndex(param1:Number, param2:int) : int
      {
         var _loc4_:MCPetContainer = null;
         var _loc5_:int = 0;
         var _loc3_:int = this._fightPanel.layerPet.numChildren - 1;
         for each(_loc4_ in this._fightPanel.petMCList)
         {
            if(Math.abs(param2 - _loc4_.locaId) <= FightData.MARK_LOCA_ID)
            {
               if(param1 < _loc4_.y)
               {
                  _loc5_ = _loc4_.parent.getChildIndex(_loc4_);
                  if(_loc5_ < _loc3_)
                  {
                     _loc3_ = _loc5_;
                  }
               }
            }
         }
         return _loc3_;
      }
      
      public function dispose() : void
      {
         this._fightPanel = null;
         _instance = null;
      }
   }
}

