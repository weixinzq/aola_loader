package mmo.petfightnew.common.util
{
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   
   public class DisableUtil
   {
      
      public function DisableUtil()
      {
         super();
      }
      
      public static function disableAll(param1:DisplayObjectContainer) : void
      {
         param1.mouseChildren = param1.mouseEnabled = param1.tabChildren = param1.tabEnabled = false;
      }
      
      public static function disableChildren(param1:Sprite) : void
      {
         param1.mouseChildren = param1.tabChildren = param1.tabEnabled = false;
      }
   }
}

