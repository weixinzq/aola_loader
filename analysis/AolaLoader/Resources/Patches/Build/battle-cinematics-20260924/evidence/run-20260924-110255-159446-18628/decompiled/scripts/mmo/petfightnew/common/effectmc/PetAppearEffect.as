package mmo.petfightnew.common.effectmc
{
   import com.greensock.TweenMax;
   import com.greensock.data.TweenLiteVars;
   import flash.display.MovieClip;
   import mmo.petfightnew.common.manager.FightTweenMaxManager;
   
   public class PetAppearEffect extends McEffectBase
   {
      
      public function PetAppearEffect(param1:int, param2:int, param3:MovieClip, param4:Function)
      {
         super(param1,param2,param3,param4);
         this.hidePet();
      }
      
      protected function hidePet() : void
      {
         if(Boolean(this.mcPet) && Boolean(this.mcPet.parent))
         {
            this.mcPet.visible = false;
            this.mcPet.y += 1000;
         }
      }
      
      override public function play() : void
      {
         super.play();
      }
      
      override protected function setPetMc() : void
      {
         this.magnify();
      }
      
      protected function showPet() : void
      {
         if(Boolean(this.mcPet) && Boolean(this.mcPet.parent))
         {
            this.mcPet.visible = true;
            this.mcPet.y -= 1000;
         }
      }
      
      private function magnify() : void
      {
         var scale:Number = NaN;
         var tm:TweenMax = null;
         var tweenVar:TweenLiteVars = null;
         if(Boolean(this.mcPet) && Boolean(this.mcPet.parent))
         {
            this.showPet();
            scale = this.mcPet.scaleX;
            this.mcPet.scaleX = 0.1;
            this.mcPet.scaleY = 0.1;
            tm = null;
            tweenVar = new TweenLiteVars();
            tweenVar.prop("scaleX",scale);
            tweenVar.prop("scaleY",scale);
            tweenVar.useFrames(true);
            tweenVar.onComplete(function():void
            {
               FightTweenMaxManager.instance.removeTweenMax(tm);
            });
            tm = new TweenMax(this.mcPet,7,tweenVar);
            FightTweenMaxManager.instance.addTweenMax(tm);
         }
      }
   }
}

