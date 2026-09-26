package mmo.petfightnew.common.skilleffect
{
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   
   public class GQLianSuoEffectHelper
   {
      
      private static const URL:String = "gqpet/liansuo/effect/liansuobigskillmv";
      
      private static const CLS:String = "mmo.xinghuipet.liansuo.GQLianSuoBigSkillMv";
      
      private static var _instance:GQLianSuoEffectHelper = new GQLianSuoEffectHelper();
      
      private var _pmService:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      public function GQLianSuoEffectHelper()
      {
         super();
      }
      
      public static function getInstance() : GQLianSuoEffectHelper
      {
         if(null == _instance)
         {
            _instance = new GQLianSuoEffectHelper();
         }
         return _instance;
      }
      
      public function playMvHandle(param1:PetBriefInfo, param2:int) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ArrayIndexOutOfBoundsException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
   }
}

