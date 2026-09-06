package mmo.petfightnew.common.util
{
   import mmo.interfaces.degenerator.DegeneratorPetType;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class DegeneratorPetHelper
   {
      
      public function DegeneratorPetHelper()
      {
         super();
      }
      
      public static function getDegeneratorPetBigSkill(param1:PetBriefInfo) : PMSkill
      {
         var _loc5_:SkillInfo = null;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:Array = param1.skills;
         var _loc4_:PMSkill = null;
         for each(_loc5_ in _loc3_)
         {
            _loc4_ = _loc2_.customData.pmSkillMap.getSkill(_loc5_.id);
            if(PMSkillTypes.isDegeneratorKillBig(_loc4_.getSkillType()))
            {
               return _loc4_;
            }
         }
         return null;
      }
      
      public static function getDegeneratorPetSuperSkill(param1:PetBriefInfo) : PMSkill
      {
         var _loc5_:SkillInfo = null;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:Array = param1.skills;
         var _loc4_:PMSkill = null;
         for each(_loc5_ in _loc3_)
         {
            _loc4_ = _loc2_.customData.pmSkillMap.getSkill(_loc5_.id);
            if(PMSkillTypes.isDegeneratorSuperSpiritSkill(_loc4_.getSkillType()))
            {
               return _loc4_;
            }
         }
         return null;
      }
      
      public static function checkIsShikigamiPet(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         return _loc2_.getOperationPM(param1).pmData.isShikigamiPet;
      }
      
      public static function checkIsDegeneratorPet(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         return _loc2_.getOperationPM(param1).pmData.isDegeneratorPM();
      }
      
      public static function checkIsDegeneratorXianPet(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:PMData = _loc2_.getOperationPM(param1).pmData;
         return _loc3_.getDegeneratorType() == DegeneratorPetType.XIAN;
      }
      
      public static function checkIsDegeneratorBig(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         return _loc2_.customData.pmSkillMap.getSkill(param1).getSkillType() == PMSkillTypes.DEGENERATOR_KILL_BIG;
      }
      
      public static function checkIsDegeneratorSuperPo(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         return _loc2_.customData.pmSkillMap.getSkill(param1).getSkillType() == PMSkillTypes.DEGENERATOR_COMMON_SPIRIT_PO;
      }
   }
}

