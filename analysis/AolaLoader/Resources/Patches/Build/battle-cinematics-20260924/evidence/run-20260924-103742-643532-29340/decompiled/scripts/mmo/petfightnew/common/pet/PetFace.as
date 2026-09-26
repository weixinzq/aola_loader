package mmo.petfightnew.common.pet
{
   public class PetFace
   {
      
      public static const POSITIVE:int = 1;
      
      public static const BACK:int = 2;
      
      public function PetFace()
      {
         super();
      }
      
      public static function getFaceId(param1:Boolean) : int
      {
         return param1 ? POSITIVE : BACK;
      }
      
      public static function isPositive(param1:int) : Boolean
      {
         return param1 == POSITIVE;
      }
   }
}

