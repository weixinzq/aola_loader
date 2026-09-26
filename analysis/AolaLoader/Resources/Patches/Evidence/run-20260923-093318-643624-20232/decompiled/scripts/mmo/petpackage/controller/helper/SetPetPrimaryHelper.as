package mmo.petpackage.controller.helper
{
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   
   public class SetPetPrimaryHelper
   {
      
      private var index:int = -1;
      
      public function SetPetPrimaryHelper()
      {
         super();
      }
      
      public function setPrimary(param1:int, param2:int) : void
      {
         this.index = param2;
         SocketClient.instance.addEventListener(PetClient.RSPN_SET_CURRENT_PM,this.onSocketPrimaryPet);
         PetClient.instance.setCurPM(param1);
      }
      
      private function onSocketPrimaryPet(param1:SocketClientEvent) : void
      {
         var _loc2_:int = int(param1.params.id);
         SocketClient.instance.removeEventListener(PetClient.RSPN_SET_CURRENT_PM,this.onSocketPrimaryPet);
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_SETPRI,{
            "id":_loc2_,
            "index":this.index
         }));
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent(CommonEvent.PET_SET_FIRST_PET,{
            "id":_loc2_,
            "index":this.index
         }));
      }
   }
}

