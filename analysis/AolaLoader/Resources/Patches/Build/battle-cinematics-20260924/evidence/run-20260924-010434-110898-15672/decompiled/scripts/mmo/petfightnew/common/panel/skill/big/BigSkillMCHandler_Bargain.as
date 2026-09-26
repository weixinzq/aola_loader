package mmo.petfightnew.common.panel.skill.big
{
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.interfaces.pet.data.BargainPetConfig;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.petfightnew.common.FightController;
   
   public class BigSkillMCHandler_Bargain extends BigSkillMCHandler
   {
      
      private var _canUse:Boolean = false;
      
      public function BigSkillMCHandler_Bargain()
      {
         super();
      }
      
      override public function update() : void
      {
         var _loc3_:TextField = null;
         super.update();
         this._canUse = false;
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         var _loc2_:int = _loc1_.raceId % 10000;
         if(BargainPetConfig.isBargainPet(_loc2_))
         {
            this._canUse = true;
            _mcChangeView.gotoAndStop(4);
            _mcChangeView.curClip.buttonMode = true;
         }
         else if(BargainPetConfig.getBargainIdByTargetId(_loc2_) != -1)
         {
            _mcChangeView.gotoAndStop(5);
            _loc3_ = _mcChangeView.getChildByName("txtSkillName") as TextField;
            _loc3_.mouseEnabled = false;
            _loc3_.text = BargainPetConfig.getBargainSkillName(BargainPetConfig.getBargainIdByTargetId(_loc2_));
         }
      }
      
      override protected function care() : Boolean
      {
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         var _loc2_:int = int(_loc1_.raceId);
         return Boolean(BargainPetConfig.isBargainPet(_loc2_)) || BargainPetConfig.getBargainIdByTargetId(_loc2_) != -1;
      }
      
      override public function onClicked(param1:MouseEvent) : void
      {
         if(this._canUse)
         {
            FightController.instance.changePMView();
         }
      }
   }
}

