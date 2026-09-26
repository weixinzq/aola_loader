package mmo.petfightnew.common.handler
{
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class SkillUseValide
   {
      
      public function SkillUseValide()
      {
         super();
      }
      
      public static function canUseSkill(param1:int, param2:int, param3:int) : Boolean
      {
         if(isPassiveSkill(param1))
         {
            return false;
         }
         if(param2 <= 0)
         {
            return false;
         }
         if(isSkillFreezed(param1,param3))
         {
            return false;
         }
         return true;
      }
      
      private static function isSkillFreezed(param1:int, param2:int) : Boolean
      {
         var _loc3_:Array = getFreezeSkillState(param2);
         var _loc4_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         var _loc5_:Object = _loc4_.getPetSkillMes(param1);
         var _loc6_:int = 0;
         while(_loc6_ < _loc3_.length)
         {
            if(_loc3_[_loc6_] == "58" && int(_loc5_.type) == 0 || _loc3_[_loc6_] == "59" && int(_loc5_.type) == 1)
            {
               return true;
            }
            _loc6_++;
         }
         return false;
      }
      
      private static function isPassiveSkill(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         return _loc2_.customData.pmSkillMap.getSkill(param1).isPassiveSkill;
      }
      
      private static function getFreezeSkillState(param1:int) : Array
      {
         var _loc4_:PlayerBattleInfo = null;
         var _loc5_:PetBriefInfo = null;
         var _loc6_:Array = null;
         var _loc7_:int = 0;
         var _loc2_:Array = [];
         if(FightController.instance.pmmStatuses == null)
         {
            return _loc2_;
         }
         var _loc3_:int = 0;
         while(_loc3_ < FightController.instance.pmmStatuses.length)
         {
            _loc4_ = FightController.instance.pmmStatuses[_loc3_] as PlayerBattleInfo;
            if(!(_loc4_ == null || _loc4_.slotId != param1))
            {
               _loc5_ = _loc4_.myPets[0] as PetBriefInfo;
               if(!(_loc5_ == null || _loc5_.status == null || _loc5_.status == ""))
               {
                  _loc6_ = _loc5_.status.split(",");
                  _loc7_ = 0;
                  while(_loc7_ < _loc2_.length)
                  {
                     if(_loc6_[_loc7_] == "58" || _loc6_[_loc7_] == "59")
                     {
                        _loc2_.push(_loc6_[_loc7_]);
                     }
                     _loc7_++;
                  }
                  break;
               }
            }
            _loc3_++;
         }
         return _loc2_;
      }
   }
}

