package mmo.petfightnew.common.util
{
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class LegendPetHelper
   {
      
      public function LegendPetHelper()
      {
         super();
      }
      
      public static function getLegendPetBigSkill(param1:PetBriefInfo) : PMSkill
      {
         var _loc5_:SkillInfo = null;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:Array = param1.skills;
         var _loc4_:PMSkill = null;
         for each(_loc5_ in _loc3_)
         {
            _loc4_ = _loc2_.customData.pmSkillMap.getSkill(_loc5_.id);
            if(_loc4_.isLegendBigSkill())
            {
               return _loc4_;
            }
         }
         return null;
      }
      
      public static function checkIsLegendBig(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         return _loc2_.customData.pmSkillMap.getSkill(param1).isLegendBigSkill();
      }
      
      public static function checkIsLegendPet(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         return _loc2_.getOperationPM(param1).pmData.isLegendPM();
      }
   }
}

