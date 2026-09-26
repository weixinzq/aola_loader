package mmo.petfightnew.common.handler.attributeicon
{
   public class FightAttributeIconCacheKey
   {
      
      public static const SMALL:String = "_small_attribute_icon";
      
      public static const MIDDLE:String = "_middle_attribute_icon";
      
      public static const LARGE:String = "_large_attribute_icon";
      
      public function FightAttributeIconCacheKey()
      {
         super();
      }
      
      public static function getIconSize(param1:String) : Number
      {
         if(param1 == SMALL)
         {
            return 30;
         }
         if(param1 == MIDDLE)
         {
            return 45;
         }
         return 60;
      }
   }
}

