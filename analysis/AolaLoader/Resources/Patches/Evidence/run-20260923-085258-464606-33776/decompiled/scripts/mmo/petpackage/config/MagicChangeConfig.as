package mmo.petpackage.config
{
   public class MagicChangeConfig
   {
      
      private static const magicChangeMap:Object = {
         1753:{
            "itemId":1264,
            "magicRaceId":2059
         },
         1754:{
            "itemId":1264,
            "magicRaceId":2059
         },
         1925:{
            "itemId":1264,
            "magicRaceId":2059
         },
         1776:{
            "itemId":1265,
            "magicRaceId":2060
         },
         1777:{
            "itemId":1265,
            "magicRaceId":2060
         },
         2023:{
            "itemId":1265,
            "magicRaceId":2060
         },
         1872:{
            "itemId":1284,
            "magicRaceId":2083
         },
         1873:{
            "itemId":1284,
            "magicRaceId":2083
         },
         2080:{
            "itemId":1284,
            "magicRaceId":2083
         },
         1824:{
            "itemId":1341,
            "magicRaceId":2123
         },
         1825:{
            "itemId":1341,
            "magicRaceId":2123
         },
         2114:{
            "itemId":1341,
            "magicRaceId":2123
         }
      };
      
      public function MagicChangeConfig()
      {
         super();
      }
      
      public static function isHaveMagicCard(param1:int) : Boolean
      {
         return magicChangeMap[param1] != null;
      }
      
      public static function getMagicRaceId(param1:int) : int
      {
         var _loc2_:Object = magicChangeMap[param1] as Object;
         return _loc2_.magicRaceId;
      }
      
      public static function getMagicItemId(param1:int) : int
      {
         var _loc2_:Object = magicChangeMap[param1] as Object;
         return _loc2_.itemId;
      }
   }
}

