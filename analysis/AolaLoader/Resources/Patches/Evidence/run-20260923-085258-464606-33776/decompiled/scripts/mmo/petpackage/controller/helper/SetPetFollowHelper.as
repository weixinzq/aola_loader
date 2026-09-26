package mmo.petpackage.controller.helper
{
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.follow.IPetFollow;
   import mmo.interfaces.pet.ride.IRideService;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.data.PetDetailDataMap;
   
   public class SetPetFollowHelper
   {
      
      public function SetPetFollowHelper()
      {
         super();
      }
      
      public function trySetFollow(param1:PetBriefInfo, param2:int, param3:int) : void
      {
         var _loc4_:IPetFollow = ServiceContainer.instance.getService("PetFollowService") as IPetFollow;
         var _loc5_:IRideService = ServiceContainer.instance.getService("RideService") as IRideService;
         var _loc6_:PetBriefInfo = param1;
         if(PetDetailDataMap.instance.checkCache(_loc6_.id))
         {
            _loc6_ = PetDetailDataMap.instance.getPetDetailInfo(_loc6_.id);
         }
         if(_loc6_.id != param2)
         {
            if(param3 == _loc6_.id)
            {
               _loc5_.unRide(_loc6_);
               PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_RIDE_CHANGE,{"id":-1}));
            }
            if(-1 != param2)
            {
               _loc4_.setBackPackage();
            }
            _loc4_.setFollow(_loc6_.id,_loc6_.viewId);
            PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_FOLLOW_CHANGE,{"id":_loc6_.id}));
         }
         else
         {
            _loc4_.setBackPackage();
            PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_FOLLOW_CHANGE,{"id":-1}));
         }
      }
   }
}

