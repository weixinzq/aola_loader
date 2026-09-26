package mmo.petfightnew.common.config
{
   import mmo.petfightnew.common.FightData;
   
   public class FightConfig
   {
      
      public function FightConfig()
      {
         super();
      }
      
      public static function getTurnOperateSeconds() : int
      {
         if(FightData.instance.isPFS2v2)
         {
            return 20;
         }
         if(FightData.instance.isFetterEffect)
         {
            return 30;
         }
         if(FightData.instance.isMultiControl())
         {
            return 20;
         }
         if(FightData.instance.isPVE)
         {
            return 30;
         }
         return 10;
      }
      
      public static function getTempSwitchOperateSeconds() : int
      {
         return getTurnOperateSeconds();
      }
   }
}

