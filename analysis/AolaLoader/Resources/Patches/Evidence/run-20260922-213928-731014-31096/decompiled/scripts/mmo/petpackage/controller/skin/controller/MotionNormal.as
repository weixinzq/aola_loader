package mmo.petpackage.controller.skin.controller
{
   import com.greensock.TweenLite;
   import flash.display.DisplayObject;
   import flash.geom.Point;
   import mmo.petpackage.controller.skin.constant.Conf;
   
   public class MotionNormal extends MotionBase
   {
      
      public function MotionNormal(param1:DisplayObject, param2:Point)
      {
         super(param1,param2);
      }
      
      override public function disappear() : void
      {
         TweenLite.to(this.target,Conf.DURATION,{
            "x":this.disappearPos.x,
            "y":this.disappearPos.y
         });
      }
   }
}

