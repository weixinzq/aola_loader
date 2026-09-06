package mmo.petfightnew.common.config
{
   public class ShakeSkillConfig
   {
      
      private static const skillArr:Array = [21043,11311];
      
      public function ShakeSkillConfig()
      {
         super();
      }
      
      public static function isShakeSkill(param1:int) : Boolean
      {
         var _loc3_:int = 0;
         var _loc2_:Boolean = false;
         for each(_loc3_ in skillArr)
         {
            if(_loc3_ == param1)
            {
               _loc2_ = true;
               break;
            }
         }
         return _loc2_;
      }
   }
}

