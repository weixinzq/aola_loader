package mmo.petfightnew.common.helper
{
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   
   public class SkillHelper
   {
      
      public function SkillHelper()
      {
         super();
      }
      
      public static function getPPDesc(param1:SkillInfo) : String
      {
         if(param1 != null && param1.maxUseTimes > 0)
         {
            return param1.canUseTimes + "/" + param1.maxUseTimes;
         }
         return "--/--";
      }
      
      public static function getPowerDesc(param1:PMSkill) : String
      {
         if(param1 != null && param1.power > 0)
         {
            return param1.power + "";
         }
         return "--";
      }
      
      public static function getSkillTipsTitle(param1:PMSkill) : String
      {
         return param1.newCnName + " 威力：" + getPowerDesc(param1);
      }
      
      public static function getSKillTipsContent(param1:PMSkill) : String
      {
         var _loc3_:String = null;
         var _loc2_:IGameOptionService = ServiceContainer.getService(IGameOptionService);
         if(_loc2_.isGQSimpleSkillView)
         {
            _loc3_ = param1.oldEffectDesc;
         }
         else
         {
            _loc3_ = param1.clientDesc;
         }
         return _loc3_;
      }
      
      public static function getSkillAttackTypeDesc(param1:int) : String
      {
         switch(param1)
         {
            case 0:
               return "(普通攻击)";
            case 1:
               return "(特殊攻击)";
            case 2:
               return "(属性攻击)";
            default:
               return "";
         }
      }
   }
}

