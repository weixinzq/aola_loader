package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.common.act_operation.PetFunctionShortcut;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.helper.ShowWantChangePanelHelper;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.panel.inclusion.interfaces.IPetView;
   
   public class PetDetailBase extends MovieClip implements IPetView
   {
      
      protected var pdi:PetDetailedInfo;
      
      protected var canUpdateUI:Boolean = false;
      
      public function PetDetailBase()
      {
         super();
         this.addEventListener(MouseEvent.CLICK,this.onClickBase);
         ShowWantChangePanelHelper.setButtonState(this);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onPetDetailedCached);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.ONLY_UPDATE_PANEL,this.onOnlyUpdatePL);
      }
      
      public function updateUI() : void
      {
         if(!this.canUpdateUI)
         {
            this.initUI();
         }
         else
         {
            this.tryRefreshUI();
         }
      }
      
      public function removeUI() : void
      {
      }
      
      public function reset() : void
      {
         if(this.canUpdateUI)
         {
            this.resetUI();
         }
      }
      
      protected function onOnlyUpdatePL(param1:Event) : void
      {
      }
      
      protected function updateOnlyPanel() : void
      {
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.ONLY_UPDATE_PANEL));
      }
      
      public function dispose() : void
      {
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.ONLY_UPDATE_PANEL,this.onOnlyUpdatePL);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onPetDetailedCached);
      }
      
      protected function initUI() : void
      {
      }
      
      protected function refreshUI() : void
      {
      }
      
      protected function resetUI() : void
      {
      }
      
      protected function setCanUpdate() : void
      {
         this.canUpdateUI = true;
         this.tryRefreshUI();
      }
      
      final protected function tryRefreshUI() : void
      {
         if(this.canUpdateUI && null != this.pdi)
         {
            this.refreshUI();
         }
      }
      
      protected function onClickBase(param1:MouseEvent) : void
      {
         switch(param1.target.name)
         {
            case "btn_shareexp":
               PetPackageEventDispatcher.instance.closePackagePanel();
               PetFunctionShortcut.showPetShareExp(this.pdi.id);
               break;
            default:
               ShowWantChangePanelHelper.dealButton(param1.target as DisplayObject);
         }
      }
      
      private function onPetDetailedCached(param1:PetPackageEvent) : void
      {
         this.pdi = PetDetailDataMap.instance.getPetDetailInfo(param1.params.id);
         this.tryRefreshUI();
      }
   }
}

