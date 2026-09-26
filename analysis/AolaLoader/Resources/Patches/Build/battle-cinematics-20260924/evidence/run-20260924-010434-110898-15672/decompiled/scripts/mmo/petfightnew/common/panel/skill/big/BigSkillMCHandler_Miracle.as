package mmo.petfightnew.common.panel.skill.big
{
   import flash.display.Sprite;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.miraclepet.IMiraclePetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class BigSkillMCHandler_Miracle extends BigSkillMCHandler
   {
      
      private var miracleService:IMiraclePetDataService = ServicePool.instance.getService(IMiraclePetDataService);
      
      public function BigSkillMCHandler_Miracle()
      {
         super();
      }
      
      override public function update() : void
      {
         var _loc8_:int = 0;
         super.update();
         this._mcChangeView.gotoAndStop(6);
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         var _loc2_:int = int(_loc1_.raceId);
         var _loc3_:Boolean = Boolean(this._pmService.getOperationPM(_loc2_).pmData.isCompletePM());
         var _loc4_:int = _loc2_ % 10000;
         if(_loc3_)
         {
            _loc8_ = int(this._pmService.getCompleteMiraclePMData(_loc4_).skillId);
         }
         else
         {
            _loc8_ = int(this.miracleService.getMiraclePetInfo(_loc4_).passiveSkillIdList[0]);
         }
         var _loc5_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(_loc8_);
         var _loc6_:String = "类型：神迹天赋技\n效果：" + _loc5_.clientDesc;
         var _loc7_:Sprite = this._mcChangeView.curClip as Sprite;
         TipsManager.getInstance().replaceComplexTips(_loc7_,_loc5_.newCnName,_loc6_,100,-100,9);
      }
      
      override protected function care() : Boolean
      {
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         return _pmService.getOperationPM(_loc1_.raceId).pmData.isMiraclePet();
      }
   }
}

