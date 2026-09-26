package mmo.petfightnew.common.handler
{
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.useskill.SkillRange;
   
   public class SkillTargetSelecter
   {
      
      public function SkillTargetSelecter()
      {
         super();
      }
      
      public static function getDefaultSkillTarget(param1:int, param2:int) : int
      {
         var _loc6_:PlayerBattleInfo = null;
         var _loc3_:int = param2;
         var _loc4_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         var _loc5_:int = int(_loc4_.getPetSkillMes(param1).range);
         if(_loc5_ != SkillRange.TEAMMATE)
         {
            for each(_loc6_ in FightData.instance.playerInfo)
            {
               if(FightData.instance.myInfo.isLocalIdAndSlotIdSame() && !FightData.instance.isMySide(_loc6_.slotId) && _loc6_.myPets[0].curHp > 0)
               {
                  _loc3_ = int(_loc6_.slotId);
                  break;
               }
               if(!FightData.instance.myInfo.isLocalIdAndSlotIdSame() && FightData.instance.isMySide(_loc6_.slotId) && _loc6_.myPets[0].curHp > 0)
               {
                  _loc3_ = int(_loc6_.slotId);
                  break;
               }
            }
         }
         return _loc3_;
      }
   }
}

