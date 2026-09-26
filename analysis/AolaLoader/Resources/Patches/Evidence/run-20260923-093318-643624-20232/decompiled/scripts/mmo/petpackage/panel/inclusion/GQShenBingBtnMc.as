package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   
   public class GQShenBingBtnMc implements IDispose
   {
      
      private var _pmSvr:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      private var _petDataSvr:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
      
      private var isDisposed:Boolean = false;
      
      private var _currentFirstTab:int;
      
      private var _view:MovieClip;
      
      public function GQShenBingBtnMc(param1:MovieClip)
      {
         super();
         this._view = param1;
         this.init();
      }
      
      private function init() : void
      {
         this.initListeners();
      }
      
      private function initListeners() : void
      {
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_INFO_TAB_CHANGED,this.onChangeFirstTab);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
         var _loc1_:SimpleButton = ActComHelper.getChildNode(this._view,"btnShenBing") as SimpleButton;
         _loc1_.addEventListener(MouseEvent.CLICK,this.onClickShenBing);
      }
      
      private function refresh() : void
      {
         var _loc2_:int = 0;
         var _loc3_:PMData = null;
         var _loc4_:PetBriefInfo = null;
         var _loc1_:int = int(this._petDataSvr.getSelectPetId());
         if(_loc1_ >= 0)
         {
            _loc2_ = int(this._petDataSvr.getPetByPetId(_loc1_).raceId);
            _loc3_ = this._pmSvr.getOperationPM(_loc2_).pmData;
            _loc4_ = this._petDataSvr.getPetByPetId(this._petDataSvr.getSelectPetId());
            this._view.visible = this._currentFirstTab == 0 && Boolean(_loc3_.isGQPM()) && !GQPetType.isShenBing(_loc3_.getGQType());
            this._view.gotoAndStop(_loc4_.isQiyueShenBing ? 2 : 1);
         }
      }
      
      private function onChangeFirstTab(param1:PetPackageEvent) : void
      {
         this._currentFirstTab = param1.params.firstTab;
         this.refresh();
      }
      
      private function onDetailUpdate(param1:PetPackageEvent) : void
      {
         var _loc2_:int = int(this._petDataSvr.getSelectPetId());
         if(param1.params.id == _loc2_)
         {
            this.refresh();
         }
      }
      
      private function onClickShenBing(param1:MouseEvent) : void
      {
         var _loc2_:int = int(this._petDataSvr.getSelectPetId());
         var _loc3_:String = "gqpet/shenbing/shenbingshowpl";
         var _loc4_:String = "mmo.gqpet.shenbing.panel.GQ_SB_AllShenBingPl";
         Panel_Helper.loadResAndShow(_loc3_,_loc4_,{
            "qiyueRaceId":this._petDataSvr.getPetByPetId(_loc2_).raceId,
            "qiyuePetId":_loc2_
         });
      }
      
      public function dispose() : void
      {
         this.isDisposed = true;
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_INFO_TAB_CHANGED,this.onChangeFirstTab);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
         var _loc1_:SimpleButton = ActComHelper.getChildNode(this._view,"btnShenBing") as SimpleButton;
         if(_loc1_)
         {
            _loc1_.removeEventListener(MouseEvent.CLICK,this.onClickShenBing);
         }
      }
   }
}

