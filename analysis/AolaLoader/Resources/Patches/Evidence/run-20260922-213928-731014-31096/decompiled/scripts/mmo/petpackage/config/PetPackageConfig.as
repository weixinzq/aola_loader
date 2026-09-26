package mmo.petpackage.config
{
   public class PetPackageConfig
   {
      
      public function PetPackageConfig()
      {
         super();
      }
      
      public static function getMaxLevel() : int
      {
         return 100;
      }
      
      public static function getMaxStudy() : int
      {
         return 510;
      }
      
      public static function openZhenRongNeedPower() : int
      {
         return 200000;
      }
      
      public static function openZhenRongNeedPowerTips() : String
      {
         return "最高战斗力达到20W后开启";
      }
   }
}

