package mmo.petpackage.controller.skin.controller
{
   import com.greensock.TweenLite;
   import flash.display.DisplayObject;
   import flash.geom.Point;
   import mmo.petpackage.controller.skin.constant.Conf;
   
   public class MotionBase implements IMotion
   {
      
      protected var defaultPos:Point;
      
      protected var target:DisplayObject;
      
      protected var disappearPos:Point;
      
      public function MotionBase(param1:DisplayObject, param2:Point = null)
      {
         super();
         this.defaultPos = new Point(param1.x,param1.y);
         this.disappearPos = param2;
         this.target = param1;
      }
      
      public function appear() : void
      {
         var _loc1_:Point = null;
         if(this.target.hasOwnProperty("defalutPos"))
         {
            _loc1_ = this.target["defalutPos"];
         }
         if(_loc1_ == null)
         {
            _loc1_ = this.defaultPos;
         }
         TweenLite.to(this.target,Conf.DURATION,{
            "x":_loc1_.x,
            "y":_loc1_.y
         });
      }
      
      public function disappear() : void
      {
      }
      
      public function disappearImmediately() : void
      {
      }
      
      public function dispose() : void
      {
         this.defaultPos = null;
         this.target = null;
      }
   }
}

