package mmo.petfightnew.common.effectmc
{
   import flash.display.MovieClip;
   import mmo.interfaces.pet.petcommon.SuperPetHelper;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   
   public class McAIPetAppear extends PetAppearEffect
   {
      
      private var _needShakeScreen:Boolean = false;
      
      private var _isSummoned:Boolean = false;
      
      public function McAIPetAppear(param1:int, param2:int, param3:MovieClip, param4:Function, param5:Boolean)
      {
         super(param1,param2,param3,param4);
         this._isSummoned = param5;
      }
      
      override protected function initEffectMc() : void
      {
         var _loc1_:Class = null;
         super.initEffectMc();
         if(this._isSummoned)
         {
            this._needShakeScreen = true;
            this.startFrame = 7;
            _loc1_ = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.McAITotenPetAppear") as Class;
         }
         else if(SuperPetHelper.isSuperPet(this.raceId))
         {
            this.startFrame = 8;
            _loc1_ = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.McAISuperPetAppear") as Class;
         }
         else
         {
            this.startFrame = 4;
            _loc1_ = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.McAIPetAppear") as Class;
         }
         this.mcEffect = new _loc1_() as MovieClip;
         this.mcEffect.stop();
      }
      
      override protected function setPetMc() : void
      {
         super.setPetMc();
         if(this._needShakeScreen)
         {
            FightController.instance.fightPanel.shake();
         }
      }
   }
}

