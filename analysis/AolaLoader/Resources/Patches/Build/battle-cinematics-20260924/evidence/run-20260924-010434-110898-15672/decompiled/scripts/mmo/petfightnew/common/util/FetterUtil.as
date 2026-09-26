package mmo.petfightnew.common.util
{
   import mmo.common.fetter.Fetter;
   import mmo.common.fetter.FetterConfig;
   import mmo.petfightnew.common.data.ActivedFetter;
   
   public class FetterUtil
   {
      
      public function FetterUtil()
      {
         super();
      }
      
      public static function getAllActivedFetters(param1:String) : Array
      {
         var _loc5_:Array = null;
         var _loc6_:int = 0;
         var _loc2_:Array = param1.split("#");
         var _loc3_:Array = [];
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc3_[_loc4_] = [];
            if((_loc2_[_loc4_] as String).length > 0)
            {
               _loc5_ = (_loc2_[_loc4_] as String).split(",");
               _loc6_ = 0;
               while(_loc6_ < _loc5_.length)
               {
                  if(_loc5_[_loc6_].length > 0)
                  {
                     (_loc3_[_loc4_] as Array).push(parseSingleFetter(_loc5_[_loc6_]));
                  }
                  _loc6_++;
               }
            }
            _loc4_++;
         }
         return _loc3_;
      }
      
      private static function parseSingleFetter(param1:String) : ActivedFetter
      {
         var _loc2_:Array = param1.split("-");
         var _loc3_:int = parseInt(_loc2_[0]);
         var _loc4_:int = parseInt(_loc2_[1]);
         var _loc5_:int = parseInt(_loc2_[2]);
         var _loc6_:Fetter = FetterConfig.getFetterByKey(_loc3_,_loc4_);
         return new ActivedFetter(_loc6_,_loc5_);
      }
   }
}

