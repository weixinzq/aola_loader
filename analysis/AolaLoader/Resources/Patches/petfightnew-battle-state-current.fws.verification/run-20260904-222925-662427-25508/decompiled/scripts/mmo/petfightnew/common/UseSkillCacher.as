package mmo.petfightnew.common
{
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.fight.PetFightEvent;
   
   public class UseSkillCacher
   {
      
      private var latestUseSkillInfo:Object;
      
      public function UseSkillCacher()
      {
         super();
      }
      
      public function cacheLatestUseSkillInfo(param1:Object) : void
      {
         this.latestUseSkillInfo = param1;
      }
      
      public function dispatchPetDie(param1:Object) : void
      {
         if(this.latestUseSkillInfo == null)
         {
            return;
         }
         var _loc2_:int = int(this.latestUseSkillInfo.reqLocaId);
         var _loc3_:int = int(this.latestUseSkillInfo.killerRaceId);
         var _loc4_:int = FightData.instance.getUserIdByLocalId(_loc2_);
         var _loc5_:int = int(param1.dieLocaId);
         var _loc6_:int = int(param1.raceId);
         var _loc7_:int = FightData.instance.getUserIdByLocalId(_loc5_);
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.PET_BE_KILLED,{
            "killerLocalId":_loc2_,
            "killerRaceId":_loc3_,
            "killerMasterId":_loc4_,
            "diePetLocalId":_loc5_,
            "diePetRaceId":_loc6_,
            "diePetMasterId":_loc7_
         }));
      }
   }
}

