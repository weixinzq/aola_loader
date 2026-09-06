package mmo.petfightnew.common.effectmc
{
   import com.greensock.TweenMax;
   import com.greensock.data.TweenLiteVars;
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.FightTweenMaxManager;
   
   public class McMySwitch extends McEffectBase
   {
      
      public function McMySwitch(param1:int, param2:int, param3:MovieClip, param4:Function)
      {
         super(param1,param2,param3,param4);
      }
      
      override protected function initEffectMc() : void
      {
         super.initEffectMc();
         var _loc1_:Class = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.McMySwitch") as Class;
         this.mcEffect = new _loc1_() as MovieClip;
         this.mcEffect.stop();
         this.startFrame = 8;
      }
      
      override protected function setPetMc() : void
      {
         super.setPetMc();
         this.shrink();
      }
      
      private function shrink() : void
      {
         var tweenMax:TweenMax = null;
         var tweenVar:TweenLiteVars = new TweenLiteVars();
         tweenMax = null;
         tweenVar.prop("scaleX",0.1);
         tweenVar.prop("scaleY",0.1);
         tweenVar.useFrames(true);
         tweenVar.onComplete(function():void
         {
            FightTweenMaxManager.instance.removeTweenMax(tweenMax);
            removePet();
         });
         tweenMax = new TweenMax(this.mcPet,7,tweenVar);
         FightTweenMaxManager.instance.addTweenMax(tweenMax);
      }
      
      private function removePet() : void
      {
         DisplayUtil.stopAndRemove(this.mcPet);
      }
   }
}

