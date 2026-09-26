package mmo.petfightnew.common.panel.skill.big
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.data.custom.PMLegendBigSkillTypes;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.util.LegendPetHelper;
   import mmo.petfightnew.common.util.StatusUtil;
   
   public class BigSkillMCHandler_Legend extends BigSkillMCHandler
   {
      
      public function BigSkillMCHandler_Legend()
      {
         super();
      }
      
      override public function update() : void
      {
         super.update();
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         if(this._pmService.getOperationPM(_loc1_.raceId) == null || this._pmService.getOperationPM(_loc1_.raceId).pmData == null)
         {
            throw new Error("PM数据有问题，应该是没有" + _loc1_.raceId + "的" + _loc1_.name + "这只亚比！");
         }
         var _loc2_:int = int(this._pmService.getOperationPM(_loc1_.raceId).pmData.maxSoulNum);
         var _loc3_:int = int(_loc1_.curSoulNum);
         var _loc4_:PMSkill = LegendPetHelper.getLegendPetBigSkill(_loc1_);
         var _loc5_:int = 9;
         switch(_loc4_.getLegendBigSkillType())
         {
            case PMLegendBigSkillTypes.LEGEND_KILL_BIG:
               _loc5_ = 9;
               break;
            case PMLegendBigSkillTypes.LEGEND_FIELD_BIG:
               _loc5_ = 10;
               break;
            case PMLegendBigSkillTypes.LEGEND_TOTEM_BIG:
               _loc5_ = 11;
         }
         this._mcChangeView.gotoAndStop(_loc5_);
         var _loc6_:MovieClip = this._mcChangeView.getChildByName("mcbig") as MovieClip;
         if(_loc3_ < _loc4_.costSoulNum)
         {
            _loc6_.gotoAndStop(2);
            setMouseChildren(false);
         }
         else
         {
            _loc6_.gotoAndStop(1);
            setMouseChildren(true);
         }
         var _loc7_:MovieClip = this._mcChangeView.getChildByName("mcsouls") as MovieClip;
         _loc7_.gotoAndStop(_loc2_);
         var _loc8_:MovieClip = null;
         var _loc9_:int = 0;
         while(_loc9_ < _loc2_)
         {
            _loc8_ = _loc7_.getChildByName("mcsoul" + _loc9_) as MovieClip;
            if(_loc8_)
            {
               _loc8_.mouseChildren = _loc8_.mouseEnabled = false;
               if(_loc9_ < _loc3_)
               {
                  _loc8_.gotoAndStop(2);
               }
               else
               {
                  _loc8_.gotoAndStop(1);
               }
            }
            _loc9_++;
         }
         var _loc10_:* = _loc4_.clientDesc;
         _loc10_ = _loc10_ + ("\n-------\n当前拥有" + _loc3_ + "魂。");
         var _loc11_:PetBriefInfo = this.getOperatingPetInfo();
         if(StatusUtil.isPetInLegendFieldState(_loc11_))
         {
            _loc10_ += "\n-------\n传奇领域剩余" + StatusUtil.getPetLeftLegendFieldRound(_loc11_) + "回合";
         }
         if(_loc3_ < _loc4_.costSoulNum)
         {
            _loc10_ += "\n-------\n传奇魂不足，不能使用传奇必杀！";
         }
         var _loc12_:String = _loc4_.newCnName + " 威力：" + this.getSkillPowerDesc(_loc4_.power);
         var _loc13_:Sprite = this._mcChangeView.curClip as Sprite;
         TipsManager.getInstance().replaceComplexTips(_loc13_,_loc12_,_loc10_,100,-100,9);
      }
      
      override protected function care() : Boolean
      {
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         return _pmService.getOperationPM(_loc1_.raceId).pmData.isLegendPM();
      }
      
      override public function onClicked(param1:MouseEvent) : void
      {
         var _loc2_:PetBriefInfo = this.getOperatingPetInfo();
         var _loc3_:int = int(_loc2_.curSoulNum);
         var _loc4_:PMSkill = LegendPetHelper.getLegendPetBigSkill(_loc2_);
         if((Boolean(_loc4_)) && _loc3_ >= _loc4_.costSoulNum)
         {
            UseBigSkillHandler.instance.handleUse(_loc2_,_loc4_.skillId,_loc4_.getLegendBigSkillType());
         }
      }
   }
}

