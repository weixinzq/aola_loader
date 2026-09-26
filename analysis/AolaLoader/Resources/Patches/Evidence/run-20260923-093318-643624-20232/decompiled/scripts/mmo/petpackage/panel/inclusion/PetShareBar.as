package mmo.petpackage.panel.inclusion
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.share.IShareService;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.service.PetPackageService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1058")]
   public class PetShareBar extends Sprite
   {
      
      public var btnShareAll:SimpleButton;
      
      private var selectedPet:PetBriefInfo;
      
      private var shareSerivce:IShareService = null;
      
      public function PetShareBar()
      {
         super();
         this.initPars();
         this.initFuns();
         var _loc1_:SimpleButton = this.getChildByName("btnShareAll") as SimpleButton;
         TipsManager.getInstance().addTips(_loc1_,"分享亚比背包");
      }
      
      private function initPars() : void
      {
      }
      
      private function initFuns() : void
      {
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onSelectedData);
         this.addEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      private function disposeFuns() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClick);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onSelectedData);
      }
      
      private function onSelectedData(param1:PetPackageEvent) : void
      {
         this.selectedPet = PetDetailDataMap.instance.getPetDetailInfo(param1.params.id);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnShare")
         {
            this.shareSerivce = ServiceContainer.instance.getService(IShareService) as IShareService;
            this.shareSerivce.showOnePetPackageSharePanel(this.selectedPet);
         }
         else if(_loc2_ == "btnShareAll")
         {
            this.shareSerivce = ServiceContainer.instance.getService(IShareService) as IShareService;
            this.shareSerivce.showMyPetPackageSharePanel();
         }
         else if("btnunfurl" == _loc2_)
         {
            this.unfurl();
         }
      }
      
      private function unfurl() : void
      {
         ProgressFullSprite.show();
         ResScheduler.getRes(ResParams.createTemp("talk/showpettalkpanel",function(param1:*, param2:ApplicationDomain):void
         {
            ProgressFullSprite.close();
            var _loc3_:* = param2.getDefinition("mmo.showpettalk.ShowPetTalkPanel") as Class;
            var _loc4_:* = new _loc3_(selectedPet.id,selectedPet.name) as IShowPanel;
            PetPackageService.currentPanel.closePanel();
            _loc4_.showPanel();
         },""));
      }
      
      public function dispose() : void
      {
         this.disposeFuns();
      }
   }
}

