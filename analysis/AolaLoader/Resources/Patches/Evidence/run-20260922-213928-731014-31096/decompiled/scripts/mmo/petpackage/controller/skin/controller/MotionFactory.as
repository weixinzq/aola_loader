package mmo.petpackage.controller.skin.controller
{
   import flash.display.DisplayObject;
   import flash.geom.Point;
   import mmo.petpackage.controller.skin.constant.StyleTypes;
   
   public class MotionFactory
   {
      
      public function MotionFactory()
      {
         super();
      }
      
      public static function creat(param1:DisplayObject, param2:int, param3:Point = null) : IMotion
      {
         switch(param2)
         {
            case StyleTypes.LEFT:
               return new MotionLeft(param1);
            case StyleTypes.RIGHT:
               return new MotionRight(param1);
            case StyleTypes.UP:
               return new MotionUp(param1);
            case StyleTypes.DOWN:
               return new MotionDown(param1);
            case StyleTypes.NORMAL:
               return new MotionNormal(param1,param3);
            default:
               return null;
         }
      }
   }
}

