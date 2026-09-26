package mmo.petpackage.panel.inclusion
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetBattleEffDataService;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.play.activity.legend.LegendSoulIconHandler;
   import mmo.play.activity.legend.LegendSoulLevelUpPanel;
   import mmo.play.activity.legend.LegendSoulPanelHandler;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1021")]
   public class LegendSoulPanel extends Sprite implements IDispose
   {
      
      public var mcdetail:MovieClip;
      
      public var mcicon:MovieClip;
      
      public var mcnum:MovieClip;
      
      private var _petDataService:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
      
      private var _pmService:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      private var _petBattleEffService:IPetBattleEffDataService = ServiceContainer.getService(IPetBattleEffDataService) as IPetBattleEffDataService;
      
      private var _iconHandler:LegendSoulIconHandler = null;
      
      private var _panelContainer:DisplayObjectContainer = null;
      
      private var _panelHandler:LegendSoulPanelHandler = null;
      
      private var _pbi:PetBriefInfo;
      
      public function LegendSoulPanel()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
         var _loc1_:MovieClip = this.mcicon;
         this._iconHandler = new LegendSoulIconHandler(_loc1_,_loc1_.width,_loc1_.height);
         this._panelContainer = this.mcdetail;
         this._panelContainer.visible = false;
         this._panelHandler = new LegendSoulPanelHandler(this._panelContainer);
         this.addEventListener(MouseEvent.ROLL_OVER,this.onMouseOverListener);
         this.addEventListener(MouseEvent.ROLL_OUT,this.onMouseOutListener);
         this.addEventListener(MouseEvent.CLICK,this.onMouseClickListener);
         this.buttonMode = true;
      }
      
      private function onMouseOverListener(param1:MouseEvent) : void
      {
         this._panelContainer.visible = true;
      }
      
      private function onMouseOutListener(param1:MouseEvent) : void
      {
         this._panelContainer.visible = false;
      }
      
      private function onMouseClickListener(param1:MouseEvent) : void
      {
         new LegendSoulLevelUpPanel(this._pbi).showPanel();
      }
      
      private function onDetailUpdate(param1:PetPackageEvent) : void
      {
         var _loc2_:int = int(this._petDataService.getSelectPetId());
         if(param1.params.id == _loc2_)
         {
            this._pbi = PetDetailDataMap.instance.getPetDetailInfo(_loc2_);
            this.updatePanel(this._pbi);
         }
      }
      
      private function updatePanel(param1:PetBriefInfo) : void
      {
         this._pbi = param1;
         this._iconHandler.setPetSoul(param1.raceId);
         this._panelHandler.setPet(param1);
         ArtNumberManager.setNumber([this.mcnum],this._pbi.legendSoulLv);
      }
      
      public function dispose() : void
      {
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
         this.removeEventListener(MouseEvent.ROLL_OVER,this.onMouseOverListener);
         this.removeEventListener(MouseEvent.ROLL_OUT,this.onMouseOutListener);
         this.removeEventListener(MouseEvent.CLICK,this.onMouseClickListener);
      }
   }
}

