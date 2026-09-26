package mmo.petpackage.controller.helper
{
   import flash.display.MovieClip;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   public class SetBattleEffHelper
   {
      
      public function SetBattleEffHelper()
      {
         super();
      }
      
      public static function setBattleEff(param1:MovieClip, param2:int) : void
      {
         var _loc5_:MovieClip = null;
         var _loc3_:Array = [];
         var _loc4_:int = 0;
         while(_loc4_ < 5)
         {
            _loc5_ = param1.getChildByName("num_" + _loc4_) as MovieClip;
            _loc3_.push(_loc5_);
            _loc4_++;
         }
         ArtNumberManager.setNumber(_loc3_,param2);
      }
   }
}

