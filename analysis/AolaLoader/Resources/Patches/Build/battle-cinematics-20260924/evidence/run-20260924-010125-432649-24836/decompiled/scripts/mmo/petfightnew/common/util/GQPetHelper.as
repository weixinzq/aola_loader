package mmo.petfightnew.common.util
{
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class GQPetHelper
   {
      
      public function GQPetHelper()
      {
         super();
      }
      
      public static function getGQPetBigSkill(param1:PetBriefInfo) : PMSkill
      {
         var _loc5_:SkillInfo = null;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:Array = param1.skills;
         var _loc4_:PMSkill = null;
         for each(_loc5_ in _loc3_)
         {
            _loc4_ = _loc2_.customData.pmSkillMap.getSkill(_loc5_.id);
            if(StatusUtil.getIsBuxiuJixingState(param1) && _loc4_.getSkillType() == PMSkillTypes.GQ_BUXIULVTU_KILL_BIG)
            {
               return _loc4_;
            }
            if(!StatusUtil.getIsBuxiuJixingState(param1) && (Boolean(PMSkillTypes.isGQKillBig(_loc4_.getSkillType())) && _loc4_.getSkillType() != PMSkillTypes.GQ_BUXIULVTU_KILL_BIG))
            {
               return _loc4_;
            }
         }
         return null;
      }
      
      public static function getGQCommonSpiritSkills(param1:PetBriefInfo) : Array
      {
         var _loc5_:SkillInfo = null;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:Array = [];
         var _loc4_:PMSkill = null;
         for each(_loc5_ in param1.skills)
         {
            _loc4_ = _loc2_.customData.pmSkillMap.getSkill(_loc5_.id);
            if(PMSkillTypes.isGQCommonSpiritSkill(_loc4_.getSkillType()))
            {
               _loc3_.push(_loc4_);
            }
         }
         return _loc3_;
      }
      
      public static function checkIsGQPet(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         return _loc2_.getOperationPM(param1).pmData.isGQPM();
      }
   }
}

