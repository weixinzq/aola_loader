package mmo.petfightnew.common.fightcontroller
{
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   
   public class BattleSmallTurn implements IDispose
   {
      
      private static var _instance:BattleSmallTurn;
      
      private var fightPanel:FightPanel;
      
      private var _myPetStates:Object = {};
      
      public function BattleSmallTurn()
      {
         super();
      }
      
      public static function get instance() : BattleSmallTurn
      {
         if(_instance == null)
         {
            _instance = new BattleSmallTurn();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
      }
      
      public function battleSmallTurn(param1:Object) : void
      {
         this.parseData(param1);
         this.updatePetSoulNum();
         this.handle();
      }
      
      private function parseData(param1:Object) : void
      {
         var _loc5_:* = false;
         var _loc6_:* = false;
         var _loc7_:* = false;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:Boolean = false;
         var _loc12_:int = 0;
         var _loc13_:Array = null;
         var _loc14_:String = null;
         var _loc15_:Array = null;
         this._myPetStates = {};
         var _loc2_:Boolean = FightController.instance.isReplay;
         var _loc3_:int = param1.tt == null ? 0 : int(param1.tt);
         FightData.instance.myInfo.extraTurn = _loc3_;
         var _loc4_:String = param1.desc;
         if(_loc4_ == null || _loc4_.length <= 0)
         {
            _loc5_ = param1.cus == 1;
            _loc6_ = param1.cus == 2;
            _loc7_ = param1.cus == 3;
            _loc8_ = int(param1.csn);
            _loc9_ = int(param1.cln);
            _loc10_ = 0;
            _loc11_ = Boolean(param1.be) && !_loc2_;
            _loc12_ = int(FightData.instance.myInfo.operatingPlayer.slotId);
            FightData.instance.myInfo.setPlayerOperatedState(_loc12_,!_loc11_);
            FightData.instance.myInfo.setAllows(_loc12_,_loc5_);
            FightData.instance.myInfo.setNeedOperates(_loc12_,_loc11_);
            this._myPetStates[_loc12_] = {
               "allow":_loc5_,
               "soulNum":_loc8_,
               "xinghuiSoulNum":_loc9_,
               "GQSoulNum":_loc10_,
               "needOperate":_loc11_,
               "tt":_loc3_,
               "canOnlySwitchPM":_loc6_,
               "needonlyClickPl":_loc7_
            };
         }
         else
         {
            _loc13_ = _loc4_.split(";");
            for each(_loc14_ in _loc13_)
            {
               _loc15_ = _loc14_.split("-");
               _loc12_ = parseInt(_loc15_[0]);
               _loc5_ = parseInt(_loc15_[1]) == 1;
               _loc6_ = parseInt(_loc15_[1]) == 2;
               _loc7_ = parseInt(_loc15_[1]) == 3;
               _loc8_ = parseInt(_loc15_[2]);
               _loc11_ = parseInt(_loc15_[1]) != 0 && !_loc2_;
               _loc9_ = parseInt(_loc15_[5]);
               _loc10_ = parseInt(_loc15_[6]);
               FightData.instance.myInfo.setPlayerOperatedState(_loc12_,!_loc11_);
               FightData.instance.myInfo.setAllows(_loc12_,_loc5_);
               FightData.instance.myInfo.setCanOnlySwitchPMs(_loc12_,_loc6_);
               FightData.instance.myInfo.setNeedOnlyClickPanels(_loc12_,_loc7_);
               FightData.instance.myInfo.setNeedOperates(_loc12_,_loc11_);
               this._myPetStates[_loc12_] = {
                  "allow":_loc5_,
                  "soulNum":_loc8_,
                  "needOperate":_loc11_,
                  "tt":_loc3_,
                  "xinghuiSoulNum":_loc9_,
                  "GQSoulNum":_loc10_,
                  "canOnlySwitchPM":_loc6_,
                  "needonlyClickPl":_loc7_
               };
            }
         }
         if(param1.auto)
         {
            FightController.isAutoUseSkill = param1.auto;
         }
      }
      
      private function updatePetSoulNum() : void
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:PetBriefInfo = null;
         var _loc1_:Array = FightData.instance.myInfo.playerInfos;
         var _loc2_:Object = null;
         for each(_loc3_ in _loc1_)
         {
            _loc2_ = this._myPetStates[_loc3_.slotId];
            if(_loc2_ != null)
            {
               _loc4_ = _loc3_.myPets[0];
               if(_loc4_ != null)
               {
                  _loc4_.curSoulNum = _loc2_["soulNum"];
                  _loc4_.curXinghuiSoulNum = _loc2_["xinghuiSoulNum"];
                  _loc4_.curGQSoulNum = _loc2_["GQSoulNum"];
               }
            }
         }
      }
      
      private function handle() : void
      {
         if(FightData.instance.myInfo.havePlayerCanOperate())
         {
            FightController.instance.dispatchEvent(new PetFightEvent(PetFightEvent.NEXT_SMALL_TURN,{}));
         }
         else if(this._myPetStates[FightData.instance.getSlotId(0)])
         {
            FightController.instance.dispatchEvent(new PetFightEvent(PetFightEvent.NEXT_SMALL_TURN,{
               "turnCount":FightController.instance.turnCount,
               "myPetState":this._myPetStates[FightData.instance.getSlotId(0)]
            }));
         }
         else
         {
            FightController.instance.dispatchEvent(new PetFightEvent(PetFightEvent.NEXT_SMALL_TURN,{"turnCount":FightController.instance.turnCount}));
         }
         if(FightController.instance.isReplay)
         {
            FightController.instance.handle();
            return;
         }
         this.addStopMovie();
         FightController.instance.handle();
      }
      
      private function addStopMovie() : void
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:PetBriefInfo = null;
         var _loc1_:Array = FightData.instance.playerInfo;
         var _loc2_:Object = null;
         for each(_loc3_ in _loc1_)
         {
            _loc2_ = this._myPetStates[_loc3_.slotId];
            if(_loc2_ != null)
            {
               if(!_loc2_.allow && !_loc2_.canOnlySwitchPM)
               {
                  this.fightPanel.removeStopMovie(_loc3_.locaId);
               }
               else if(Boolean(_loc2_.allow) || _loc2_.canOnlySwitchPM == 1)
               {
                  this.fightPanel.addStopMovie(_loc3_.locaId,2);
               }
               else
               {
                  _loc4_ = _loc3_.myPets[0];
                  if(_loc4_ != null && _loc4_.curHp > 0)
                  {
                     this.fightPanel.addStopMovie(_loc3_.locaId,2);
                  }
               }
            }
         }
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         _instance = null;
      }
   }
}

