package mmo.petfightnew.common.util
{
   import mmo.interfaces.pet.XingHuiPetHelperUtil;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class XinghuiPetHelper
   {
      
      public function XinghuiPetHelper()
      {
         super();
      }
      
      public static function checkIsXinghuiPet(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         return _loc2_.getOperationPM(param1).pmData.isXinghuiPM();
      }
      
      public static function getXinghuiPetBigSkill(param1:PetBriefInfo) : PMSkill
      {
         var _loc5_:SkillInfo = null;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:Array = param1.skills;
         var _loc4_:PMSkill = null;
         for each(_loc5_ in _loc3_)
         {
            _loc4_ = _loc2_.customData.pmSkillMap.getSkill(_loc5_.id);
            if(PMSkillTypes.isXinghuiKillBig(_loc4_.getSkillType()))
            {
               return _loc4_;
            }
         }
         return null;
      }
      
      public static function getWangzheRealExtensionPassiveSkill(param1:PetBriefInfo) : PMSkill
      {
         return getPMSkillBySkillType(param1,PMSkillTypes.XINGHUI_WANGZHE_REAL_EXT_PASSIVE_SKILL);
      }
      
      public static function getWangzheRealExtentionSkill(param1:PetBriefInfo) : PMSkill
      {
         return getPMSkillBySkillType(param1,PMSkillTypes.XINGHUI_WANGZHE_REAL_EXTEND_SKILL);
      }
      
      public static function getPMSkillBySkillType(param1:PetBriefInfo, param2:int) : PMSkill
      {
         var _loc6_:SkillInfo = null;
         var _loc3_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc4_:Array = param1.skills;
         var _loc5_:PMSkill = null;
         for each(_loc6_ in _loc4_)
         {
            _loc5_ = _loc3_.customData.pmSkillMap.getSkill(_loc6_.id);
            if(_loc5_.getSkillType() == param2)
            {
               return _loc5_;
            }
         }
         return null;
      }
      
      public static function getXinghuiPetSuperSpiritSkill(param1:PetBriefInfo) : PMSkill
      {
         var _loc5_:SkillInfo = null;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:Array = param1.skills;
         var _loc4_:PMSkill = null;
         for each(_loc5_ in _loc3_)
         {
            _loc4_ = _loc2_.customData.pmSkillMap.getSkill(_loc5_.id);
            if(PMSkillTypes.isXinghuiSuperSpiritSkill(_loc4_.getSkillType()))
            {
               return _loc4_;
            }
         }
         return null;
      }
      
      public static function getSkiilIdsByRaceIdAndSkillName(param1:int, param2:String) : Array
      {
         return XingHuiPetHelperUtil.getSkiilIdsByRaceIdAndSkillName(param1,param2);
      }
      
      public static function getSkillIdsByExtralConfig(param1:String, param2:String) : Array
      {
         return XingHuiPetHelperUtil.getSkillIdsByExtralConfig(param1,param2);
      }
      
      public static function getXingHuiExtraSkillConig(param1:String, param2:String) : String
      {
         return XingHuiPetHelperUtil.getXingHuiExtraSkillConig(param1,param2);
      }
   }
}

