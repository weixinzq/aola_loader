package mmo.petfightnew.common.config
{
   import mmo.interfaces.degenerator.DegeneratorPetType;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class FightCriEffectConfig
   {
      
      private static const specialIdArr:Array = [];
      
      public function FightCriEffectConfig()
      {
         super();
      }
      
      public static function isChaoWei(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         return _loc2_.getOperationPM(param1).pmData.getDegeneratorType() == DegeneratorPetType.CHAOWEI;
      }
      
      public static function getCriEffSuffix(param1:int) : String
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         param1 %= 10000;
         if(_loc2_.getOperationPM(param1).pmData.getDegeneratorType() == DegeneratorPetType.CHAOWEI)
         {
            return "chaowei";
         }
         if(specialIdArr.indexOf(param1) == -1)
         {
            return "normal";
         }
         return param1.toString();
      }
   }
}

