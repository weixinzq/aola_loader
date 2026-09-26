package mmo.petpackage.controller.skin.controller
{
   import com.greensock.TweenLite;
   import flash.display.DisplayObject;
   import mmo.petpackage.controller.skin.constant.Conf;
   
   public class MotionDown extends MotionBase
   {
      
      public function MotionDown(param1:DisplayObject)
      {
         super(param1);
      }
      
      override public function disappear() : void
      {
         TweenLite.to(this.target,Conf.DURATION,{"y":this.defaultPos.y + Conf.OFF_SET});
      }
      
      override public function disappearImmediately() : void
      {
         super.disappearImmediately();
         this.target.y = this.defaultPos.y + Conf.OFF_SET;
      }
   }
}

