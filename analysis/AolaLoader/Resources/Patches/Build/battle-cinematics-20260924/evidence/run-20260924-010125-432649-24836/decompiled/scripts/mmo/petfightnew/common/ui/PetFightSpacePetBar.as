package mmo.petfightnew.common.ui
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.data.PmInBagData;
   import mmo.petfightnew.common.handler.PetHeadIconHandler;
   import mmo.play.actthings.helper.ActComHelper;
   
   public class PetFightSpacePetBar extends Sprite
   {
      
      private static const MAX_PET_NUM:int = 6;
      
      private var _myPetHeadIcons:Array = [];
      
      private var _opponentPetHeadIcons:Array = [];
      
      private var _myPets:Array = [];
      
      private var _opponentPets:Array = [];
      
      private var _container:MovieClip;
      
      public function PetFightSpacePetBar(param1:MovieClip)
      {
         super();
         this._container = param1;
         this.init();
         this.update();
      }
      
      private function init() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:PetHeadIconHandler = null;
         var _loc4_:MovieClip = null;
         this._myPets = FightData.instance.getMySidePetList().concat();
         this._opponentPets = FightData.instance.getOpponentSidePetList().concat();
         var _loc1_:int = 0;
         while(_loc1_ < MAX_PET_NUM)
         {
            if(_loc1_ < this._myPets.length)
            {
               _loc2_ = ActComHelper.getChildNode(this._container,"mcMyPetIcon" + _loc1_ + ".mcPetHead") as MovieClip;
               _loc3_ = new PetHeadIconHandler(_loc2_,0.6);
               _loc3_.setIcon(this._myPets[_loc1_].viewId);
               this._myPetHeadIcons.push(_loc3_);
            }
            if(_loc1_ < this._opponentPets.length)
            {
               _loc4_ = ActComHelper.getChildNode(this._container,"mcOpponentPetIcon" + _loc1_ + ".mcPetHead") as MovieClip;
               _loc3_ = new PetHeadIconHandler(_loc4_,0.6);
               _loc3_.setIcon(this._opponentPets[_loc1_].viewId);
               this._opponentPetHeadIcons.push(_loc3_);
            }
            _loc1_++;
         }
      }
      
      public function update() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:MovieClip = null;
         var _loc4_:PetBriefInfo = null;
         var _loc5_:PetBriefInfo = null;
         var _loc6_:String = null;
         var _loc7_:Boolean = false;
         var _loc8_:PetBriefInfo = null;
         var _loc9_:PetBriefInfo = null;
         var _loc10_:String = null;
         var _loc11_:Boolean = false;
         var _loc1_:int = 0;
         while(_loc1_ < MAX_PET_NUM)
         {
            _loc2_ = ActComHelper.getChildNode(this._container,"mcMyPetIcon" + _loc1_ + ".mcPetIconBG") as MovieClip;
            ActComHelper.refreshObj(this._container,"mcMyPetIcon" + _loc1_,false);
            if(_loc1_ < this._myPets.length)
            {
               _loc4_ = this._myPets[_loc1_];
               _loc5_ = this.getInBattleFiledPet(_loc4_.uqi);
               _loc6_ = "";
               if(_loc5_)
               {
                  _loc2_.gotoAndStop(2);
                  _loc6_ = "当前出战：";
               }
               else
               {
                  _loc2_.gotoAndStop(1);
                  _loc7_ = this.isDeadByUqi(_loc4_.uqi) || _loc4_.curHp <= 0;
                  ActComHelper.refreshObj(this._container,"mcMyPetIcon" + _loc1_,_loc7_);
                  if(_loc7_)
                  {
                     _loc6_ = "已阵亡：";
                  }
               }
               _loc6_ += _loc4_.name;
               TipsManager.getInstance().replaceTips(ActComHelper.getChildNode(this._container,"mcMyPetIcon" + _loc1_) as MovieClip,_loc6_);
            }
            else
            {
               _loc2_.gotoAndStop(1);
            }
            _loc3_ = ActComHelper.getChildNode(this._container,"mcOpponentPetIcon" + _loc1_ + ".mcPetIconBG") as MovieClip;
            ActComHelper.refreshObj(this._container,"mcOpponentPetIcon" + _loc1_,false);
            if(_loc1_ < this._opponentPets.length)
            {
               _loc8_ = this._opponentPets[_loc1_];
               _loc9_ = this.getInBattleFiledPet(_loc8_.uqi);
               _loc10_ = "";
               if(_loc9_)
               {
                  _loc3_.gotoAndStop(2);
                  _loc10_ = "当前出战：";
               }
               else
               {
                  _loc3_.gotoAndStop(1);
                  _loc11_ = this.isDeadByUqi(_loc8_.uqi) || _loc8_.curHp <= 0;
                  ActComHelper.refreshObj(this._container,"mcOpponentPetIcon" + _loc1_,_loc11_);
                  if(_loc11_)
                  {
                     _loc10_ = "已阵亡：";
                  }
               }
               _loc10_ += _loc8_.name;
               TipsManager.getInstance().replaceTips(ActComHelper.getChildNode(this._container,"mcOpponentPetIcon" + _loc1_) as MovieClip,_loc10_);
            }
            else
            {
               _loc3_.gotoAndStop(1);
            }
            _loc1_++;
         }
      }
      
      private function getInBattleFiledPet(param1:int) : PetBriefInfo
      {
         var _loc2_:PlayerBattleInfo = null;
         for each(_loc2_ in FightData.instance.playerInfo)
         {
            if((_loc2_.myPets[0] as PetBriefInfo).uqi == param1)
            {
               return _loc2_.myPets[0];
            }
         }
         return null;
      }
      
      private function isDeadByUqi(param1:int) : Boolean
      {
         var _loc2_:PmInBagData = FightData.instance.myInfo.getRealTimeRoleHpData(param1);
         if(_loc2_)
         {
            return _loc2_.curHp <= 0;
         }
         return false;
      }
      
      public function dispose() : void
      {
         var _loc1_:PetHeadIconHandler = null;
         for each(_loc1_ in this._myPetHeadIcons)
         {
            _loc1_.dispose();
         }
         for each(_loc1_ in this._opponentPetHeadIcons)
         {
            _loc1_.dispose();
         }
         this._myPetHeadIcons = null;
         this._opponentPetHeadIcons = null;
      }
   }
}

