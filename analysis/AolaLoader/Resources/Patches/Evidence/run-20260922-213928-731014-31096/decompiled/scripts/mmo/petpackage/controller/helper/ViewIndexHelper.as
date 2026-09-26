package mmo.petpackage.controller.helper
{
   import flash.display.DisplayObject;
   
   public class ViewIndexHelper
   {
      
      public function ViewIndexHelper()
      {
         super();
      }
      
      public static function move2top(param1:DisplayObject) : void
      {
         if(param1.parent != null)
         {
            param1.parent.setChildIndex(param1,param1.parent.numChildren - 1);
         }
      }
   }
}

