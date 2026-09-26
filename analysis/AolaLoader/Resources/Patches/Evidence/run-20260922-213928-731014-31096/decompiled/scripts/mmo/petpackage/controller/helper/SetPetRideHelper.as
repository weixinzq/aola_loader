package mmo.petpackage.controller.helper
{
   import mmo.common.dialog.NewDialog;
   import mmo.common.member.MemberManager;
   import mmo.interfaces.IShowDataPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fly.IFlyService;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetRideInfo;
   import mmo.interfaces.pet.data.PetRideInfosMap;
   import mmo.interfaces.pet.follow.IPetFollow;
   import mmo.interfaces.pet.ride.IRideService;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.data.PetDetailDataMap;
   
   public class SetPetRideHelper
   {
      
      public function SetPetRideHelper()
      {
         super();
      }
      
      private static function showPetRideNoCardPanel(param1:int) : void
      {
         var petId:int = param1;
         var clsName:String = "mmo.petridepanel.petride.PetRideNoCardPanel";
         var urlName:String = "pet/petride/petridepanel/petridepanel";
         SimpleCustomLoader.loadSingleResource(urlName,clsName,LoadingSpriteType.DIALOG_WITHOUT_CANCLE,"请稍候……",function(param1:IShowDataPanel):void
         {
            param1.showPanelByData(petId);
         });
      }
      
      private static function showPetRidePanel(param1:Boolean, param2:int) : void
      {
         var isVip:Boolean = param1;
         var petId:int = param2;
         var petDataService:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         var clsName:String = isVip ? "mmo.petridepanel.petride.PetRideVipRightPanel" : "mmo.petridepanel.petride.PetRideNoVipRightPanel";
         var pbi:PetBriefInfo = petDataService.getPetByPetId(petId);
         var checkId:int = pbi.skinId > 0 ? int(pbi.skinId) : int(pbi.raceId);
         var rideViewNum:int = int(PetRideInfosMap.instance.getPetRideViewNum(checkId));
         clsName = isVip && rideViewNum > 1 ? "mmo.petridepanel.petride.PetRideVipTwoRightPanel" : clsName;
         var urlName:String = "pet/petride/petridepanel/petridepanel";
         SimpleCustomLoader.loadSingleResource(urlName,clsName,LoadingSpriteType.DIALOG_WITHOUT_CANCLE,"请稍候……",function(param1:IShowDataPanel):void
         {
            param1.showPanelByData(petId);
         });
      }
      
      public function trySetPetRide(param1:PetBriefInfo, param2:int, param3:int, param4:Boolean, param5:Boolean) : void
      {
         var _loc8_:int = 0;
         var _loc9_:PetRideInfo = null;
         var _loc10_:IFlyService = null;
         var _loc11_:int = 0;
         var _loc12_:IPetFollow = null;
         var _loc13_:Boolean = false;
         var _loc6_:IRideService = ServiceContainer.getService(IRideService) as IRideService;
         if(!_loc6_.rideServieIsEffect || Boolean(_loc6_.isClientRideWithOutPet()))
         {
            return;
         }
         var _loc7_:PetBriefInfo = param1;
         if(PetDetailDataMap.instance.checkCache(_loc7_.id))
         {
            _loc7_ = PetDetailDataMap.instance.getPetDetailInfo(_loc7_.id);
         }
         if(param2 == _loc7_.id)
         {
            _loc6_.unRide(_loc7_);
            PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_RIDE_CHANGE,{"id":-1}));
         }
         else
         {
            _loc8_ = _loc7_.skinId > 0 ? int(_loc7_.skinId) : int(_loc7_.raceId);
            _loc9_ = PetRideInfosMap.instance.getPetRideInfo(_loc8_);
            if(param4)
            {
               if(param5)
               {
                  _loc10_ = ServiceContainer.getService(IFlyService) as IFlyService;
                  if(_loc10_.isFlying())
                  {
                     NewDialog.showFailMessage("飞行的时候不能骑宠哦！找个地方降落吧！");
                     return;
                  }
                  if(param3 == _loc7_.id)
                  {
                     _loc12_ = ServiceContainer.getService(IPetFollow) as IPetFollow;
                     _loc12_.setBackPackage();
                     PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_FOLLOW_CHANGE,{"id":-1}));
                  }
                  _loc11_ = int(PetRideInfosMap.instance.getPetRideViewNum(_loc8_));
                  if(_loc11_ > 1)
                  {
                     showPetRidePanel(true,param1.id);
                     return;
                  }
                  _loc6_.ride(_loc7_);
                  PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_RIDE_CHANGE,{"id":_loc7_.id}));
               }
               else if(null != _loc9_)
               {
                  showPetRidePanel(true,param1.id);
               }
            }
            else if(null != _loc9_)
            {
               _loc13_ = Boolean(MemberManager.instance.isMember()) || Boolean(MemberManager.instance.isTrialMember());
               if(_loc13_)
               {
                  showPetRideNoCardPanel(param1.id);
               }
               else
               {
                  showPetRidePanel(false,param1.id);
               }
            }
         }
      }
   }
}

