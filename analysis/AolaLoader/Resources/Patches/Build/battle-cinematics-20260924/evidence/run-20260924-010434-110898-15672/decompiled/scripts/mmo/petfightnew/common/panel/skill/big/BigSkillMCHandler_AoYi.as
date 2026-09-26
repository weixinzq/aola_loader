package mmo.petfightnew.common.panel.skill.big
{
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.AoYiConfig;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.play.petfight.common.data.SkillType;
   
   public class BigSkillMCHandler_AoYi extends BigSkillMCHandler
   {
      
      private static const AOYI_NAMES:Array = ["强袭奥义","潜能奥义","战界奥义","神化奥义","BOSS克星"];
      
      private static const AOYI_TYPE_QIANGXI:int = 0;
      
      private static const AOYI_TYPE_QIANNENG:int = 1;
      
      private static const AOYI_TYPE_ZHANJIE:int = 2;
      
      private static const AOYI_TYPE_SHENHUA:int = 3;
      
      private static const AOYI_TYPE_KEXING:int = 4;
      
      private var petInfo:PetBriefInfo;
      
      private var _canUse:Boolean = false;
      
      public function BigSkillMCHandler_AoYi()
      {
         super();
      }
      
      override public function update() : void
      {
         var _loc5_:Sprite = null;
         super.update();
         this._canUse = true;
         this.petInfo = this.getOperatingPetInfo();
         var _loc1_:* = "";
         var _loc2_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(AoYiConfig.getAoYiSkillId(this.petInfo.raceId));
         var _loc3_:* = _loc2_.newCnName + "（" + AOYI_NAMES[_loc2_.aoyiType] + "）";
         if(_loc2_.aoyiType == AOYI_TYPE_KEXING)
         {
            this._mcChangeView.gotoAndStop(8);
            _loc1_ = _loc2_.clientDesc;
         }
         else
         {
            this._mcChangeView.gotoAndStop(7);
            _loc5_ = this._mcChangeView.curClip;
            _loc1_ = "威力：" + (_loc2_.power < 0 ? "-" : _loc2_.power.toString()) + (this.petInfo.isUsedAoYiSkill ? "\t已使用\n" : "\t未使用\n") + _loc2_.clientDesc + "\n每场战斗超奥义仅可使用一次";
            if(this.petInfo.isUsedAoYiSkill)
            {
               this.setMouseChildren(false);
               this._canUse = false;
               DisplayUtil.applyGray(_loc5_);
            }
            else
            {
               DisplayUtil.clearFilters(_loc5_);
            }
         }
         var _loc4_:Sprite = this._mcChangeView.curClip as Sprite;
         TipsManager.getInstance().replaceComplexTips(_loc4_,_loc3_,_loc1_,100,-100,9);
      }
      
      override protected function care() : Boolean
      {
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         return _loc1_.isGetAoYiSkill;
      }
      
      override public function onClicked(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         if(!this._canUse)
         {
            return;
         }
         if(!this.petInfo.isUsedAoYiSkill)
         {
            _loc2_ = int(AoYiConfig.getAoYiSkillId(this.petInfo.raceId));
            UseBigSkillHandler.instance.handleUse(this.petInfo,_loc2_,SkillType.AOYI_BIG);
         }
      }
   }
}

