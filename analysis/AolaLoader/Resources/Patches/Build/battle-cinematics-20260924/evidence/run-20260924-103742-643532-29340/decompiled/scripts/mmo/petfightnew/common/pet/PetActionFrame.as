package mmo.petfightnew.common.pet
{
   public class PetActionFrame
   {
      
      public static const FRAME_CRI_HIT:int = 7;
      
      public static const FRAME_CRI_HURT:int = 8;
      
      public static const FRAME_HIT:int = 6;
      
      public static const FRAME_ATTRIBUTE_ATT:int = 6;
      
      public static const FRAME_ATTRIBUTE_ATT_OLD:int = 5;
      
      public static const FRAME_PHRYSICAL_ATT:int = 4;
      
      public static const FRAME_SPECIAL_ATT:int = 3;
      
      public static const FRAME_DEFEND:int = 2;
      
      public static const FRAME_STAND:int = 1;
      
      public static const FRAME_APPEAR:int = 7;
      
      public static const FRAME_LEGEND_BIG:int = 9;
      
      public static const FRAME_DEGENERATOR_XIAN_APPEAR:int = 10;
      
      public static const FRAME_ZHUANGSHU_ATT:int = 11;
      
      public static const ACTION_PRIORITY:Array = [[PetActionFrame.FRAME_STAND],[PetActionFrame.FRAME_DEFEND],[PetActionFrame.FRAME_PHRYSICAL_ATT,PetActionFrame.FRAME_LEGEND_BIG,PetActionFrame.FRAME_SPECIAL_ATT],[PetActionFrame.FRAME_ATTRIBUTE_ATT,PetActionFrame.FRAME_ATTRIBUTE_ATT_OLD],[PetActionFrame.FRAME_DEGENERATOR_XIAN_APPEAR,PetActionFrame.FRAME_ZHUANGSHU_ATT],[PetActionFrame.FRAME_APPEAR],[PetActionFrame.FRAME_LEGEND_BIG,PetActionFrame.FRAME_PHRYSICAL_ATT,PetActionFrame.FRAME_SPECIAL_ATT]];
      
      public function PetActionFrame()
      {
         super();
      }
      
      public static function getActionIndex(param1:int) : int
      {
         var _loc5_:Array = null;
         var _loc6_:int = 0;
         var _loc2_:int = -1;
         var _loc3_:int = -1;
         var _loc4_:int = 0;
         while(_loc4_ < PetActionFrame.ACTION_PRIORITY.length)
         {
            _loc5_ = PetActionFrame.ACTION_PRIORITY[_loc4_];
            _loc6_ = int(_loc5_.indexOf(param1));
            if(_loc6_ >= 0)
            {
               if(_loc3_ == -1 || _loc6_ < _loc3_)
               {
                  _loc3_ = _loc6_;
                  _loc2_ = _loc4_;
               }
            }
            _loc4_++;
         }
         return _loc2_;
      }
   }
}

