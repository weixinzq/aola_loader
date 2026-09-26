package mmo.petpackage.controller.skin.controller
{
   import com.greensock.TweenLite;
   import flash.display.DisplayObject;
   import mmo.petpackage.controller.skin.constant.Conf;
   
   public class MotionRight extends MotionBase
   {
      
      public function MotionRight(param1:DisplayObject)
      {
         super(param1);
      }
      
      override public function disappear() : void
      {
         TweenLite.to(this.target,Conf.DURATION,{"x":this.defaultPos.x + Conf.OFF_SET});
      }
      
      override public function disappearImmediately() : void
      {
         this.target.x = this.defaultPos.x + Conf.OFF_SET;
      }
   }
}

