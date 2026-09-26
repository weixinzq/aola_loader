package mmo.petfightnew.common.effectmc
{
   import com.greensock.TweenMax;
   import com.greensock.data.TweenLiteVars;
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.FightTweenMaxManager;
   
   public class McMyPetEscape extends McEffectBase
   {
      
      public function McMyPetEscape(param1:int, param2:int, param3:MovieClip, param4:Function)
      {
         super(param1,param2,param3,param4);
      }
      
      override protected function initEffectMc() : void
      {
         super.initEffectMc();
         var _loc1_:Class = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.McMyPetEscape") as Class;
         this.mcEffect = new _loc1_() as MovieClip;
         this.mcEffect.stop();
         this.startFrame = 4;
      }
      
      override protected function setPetMc() : void
      {
         super.setPetMc();
         this.shrink();
      }
      
      private function shrink() : void
      {
         var tm:TweenMax = null;
         var tweenVar:TweenLiteVars = new TweenLiteVars();
         tm = null;
         tweenVar.prop("scaleX",0.1);
         tweenVar.prop("scaleY",0.1);
         tweenVar.useFrames(true);
         tweenVar.onComplete(function():void
         {
            FightTweenMaxManager.instance.removeTweenMax(tm);
            removePet();
         });
         tm = new TweenMax(this.mcPet,4,tweenVar);
         FightTweenMaxManager.instance.addTweenMax(tm);
      }
      
      private function removePet() : void
      {
         DisplayUtil.stopAndRemove(this.mcPet);
      }
   }
}

