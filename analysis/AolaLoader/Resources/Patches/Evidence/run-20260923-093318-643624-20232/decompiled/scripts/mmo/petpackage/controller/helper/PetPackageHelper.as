package mmo.petpackage.controller.helper
{
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetHolySpaceConfig;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.common.datastructures.ResourceObject;
   
   public class PetPackageHelper
   {
      
      public function PetPackageHelper()
      {
         super();
      }
      
      public static function isHolyPet(param1:int) : Boolean
      {
         var _loc4_:Array = null;
         var _loc7_:int = 0;
         var _loc2_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc3_:String = _loc2_.customData.pmDataMap.getPM(param1).pmImmunities;
         var _loc5_:int = -1;
         if(_loc3_ != "-1")
         {
            _loc4_ = _loc3_.split("#");
            _loc7_ = 0;
            while(_loc7_ < _loc4_.length)
            {
               if(PetHolySpaceConfig.isHolySpace(parseInt(_loc4_[_loc7_])))
               {
                  _loc5_ = parseInt(_loc4_[_loc7_]);
                  break;
               }
               _loc7_++;
            }
         }
         _loc3_ = _loc2_.customData.pmDataMap.getPM(param1).pmHolySpaceInfo;
         var _loc6_:int = -1;
         if(_loc3_ != "")
         {
            _loc4_ = _loc3_.split("-");
            if(PetHolySpaceConfig.isHolySkill(parseInt(_loc4_[1])))
            {
               _loc6_ = parseInt(_loc4_[1]);
            }
         }
         return _loc5_ != -1 || _loc6_ != -1;
      }
      
      public static function loadObject(param1:ResourceObject, param2:Function) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
   }
}

