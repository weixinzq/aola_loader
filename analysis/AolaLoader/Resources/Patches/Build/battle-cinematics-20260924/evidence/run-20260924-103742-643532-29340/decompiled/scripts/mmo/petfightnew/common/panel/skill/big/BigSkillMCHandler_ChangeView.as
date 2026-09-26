package mmo.petfightnew.common.panel.skill.big
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetChangeViewConfig;
   import mmo.petfightnew.common.FightController;
   
   public class BigSkillMCHandler_ChangeView extends BigSkillMCHandler
   {
      
      private var _canUse:Boolean = false;
      
      public function BigSkillMCHandler_ChangeView()
      {
         super();
      }
      
      override public function update() : void
      {
         var _loc2_:MovieClip = null;
         super.update();
         this._canUse = false;
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         if(_loc1_.isChangingView())
         {
            _mcChangeView.gotoAndStop(3);
            _mcChangeView.curClip.buttonMode = false;
            _loc2_ = _mcChangeView.getChildByName("mcNum") as MovieClip;
            _loc2_.gotoAndStop(_loc1_.changeViewRound + _loc1_.persistRound + 1 - FightController.instance.turnCount);
         }
         else if(_loc1_.appearRound + _loc1_.chargeRound > FightController.instance.turnCount)
         {
            _mcChangeView.gotoAndStop(1);
            _mcChangeView.curClip.buttonMode = false;
         }
         else
         {
            _mcChangeView.gotoAndStop(2);
            _mcChangeView.curClip.buttonMode = true;
            this._canUse = true;
         }
      }
      
      override protected function care() : Boolean
      {
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         return Boolean(PetChangeViewConfig.isChangeViewPet(_loc1_.raceId)) || Boolean(_loc1_.isChangingView());
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

