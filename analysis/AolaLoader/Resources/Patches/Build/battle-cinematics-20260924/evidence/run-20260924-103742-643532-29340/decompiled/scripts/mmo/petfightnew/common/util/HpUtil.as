package mmo.petfightnew.common.util
{
   public class HpUtil
   {
      
      public function HpUtil()
      {
         super();
      }
      
      public static function formatHpNum(param1:int) : Array
      {
         var _loc3_:int = 0;
         var _loc2_:Array = [];
         while(param1 > 0)
         {
            _loc3_ = param1 % 10;
            param1 = int(param1 / 10);
            _loc2_.push(_loc3_);
         }
         _loc2_.reverse();
         return _loc2_;
      }
   }
}

