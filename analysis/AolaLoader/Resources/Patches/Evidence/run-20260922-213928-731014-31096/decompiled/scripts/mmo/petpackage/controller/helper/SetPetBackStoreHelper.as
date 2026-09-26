package mmo.petpackage.controller.helper
{
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.follow.IPetFollow;
   import mmo.interfaces.pet.ride.IRideService;
   import mmo.interfaces.task.ITaskService;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.panel.other.BackStoreMessagePanel;
   
   public class SetPetBackStoreHelper
   {
      
      private var pbi:PetBriefInfo = null;
      
      private var index:int = -1;
      
      private var followId:int = -1;
      
      private var rideId:int = -1;
      
      public function SetPetBackStoreHelper()
      {
         super();
      }
      
      public function trySetPetBackStore(param1:PetBriefInfo, param2:int, param3:int, param4:int, param5:int) : void
      {
         this.pbi = param1;
         if(PetDetailDataMap.instance.checkCache(this.pbi.id))
         {
            this.pbi = PetDetailDataMap.instance.getPetDetailInfo(this.pbi.id);
         }
         this.index = param2;
         this.followId = param4;
         this.rideId = param5;
         if(param3 <= 1)
         {
            NewDialog.showFailMessage("星际探险是很危险的，背包里还是留一只亚比更安全哦！");
            return;
         }
         var _loc6_:ITaskService = ServiceContainer.getService(ITaskService) as ITaskService;
         if(!_loc6_.isUserTaskFinish(150))
         {
            NewDialog.showFailMessage("你的亚比很喜欢你，把它放到仓库会很孤单！");
            return;
         }
         new BackStoreMessagePanel(param1,this.okFun,this).showPanel();
      }
      
      private function okFun() : void
      {
         this.backToPackage();
      }
      
      private function backToPackage() : void
      {
         var _loc1_:IPetFollow = null;
         var _loc2_:IRideService = null;
         if(this.followId == this.pbi.id)
         {
            _loc1_ = ServiceContainer.getService(IPetFollow) as IPetFollow;
            _loc1_.setBackPackage();
         }
         if(this.rideId == this.pbi.id)
         {
            _loc2_ = ServiceContainer.getService(IRideService) as IRideService;
            _loc2_.unRide(this.pbi);
         }
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_BACK2STORE,{
            "id":this.pbi.id,
            "index":this.index
         }));
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent(CommonEvent.PET_BACK2STORE,{
            "id":this.pbi.id,
            "index":this.index
         }));
      }
   }
}

