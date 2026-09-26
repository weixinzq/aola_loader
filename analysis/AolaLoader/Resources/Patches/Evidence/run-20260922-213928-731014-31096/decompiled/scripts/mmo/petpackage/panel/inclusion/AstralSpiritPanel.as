package mmo.petpackage.panel.inclusion
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.astralspirit.AstralSpiritConfig;
   import mmo.interfaces.material.astralspirit.IAstralSpiritService;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.petpackage.PetPackageTabs;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.uicomponent.mutex.MutexAry;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.helper.TabJumpHelper;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.play.activity.xinghui.XinghuiSoulPanelHandler;
   import mmo.play.astralspirit.AstralSpiritHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol994")]
   public class AstralSpiritPanel extends Sprite implements IDispose
   {
      
      public var btnastralspirit:SimpleButton;
      
      public var mcdetail:MovieClip;
      
      public var mcicon0:MovieClip;
      
      public var mcicon1:MovieClip;
      
      public var mcicon2:MovieClip;
      
      public var mcsuit:MovieClip;
      
      private var _petDataService:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
      
      private var _pmService:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      private var _astralSpiritService:IAstralSpiritService = ServiceContainer.getService(IAstralSpiritService) as IAstralSpiritService;
      
      private var _panelContainer:DisplayObjectContainer = null;
      
      private var _panelHandler:XinghuiSoulPanelHandler = null;
      
      private var _pbi:PetBriefInfo;
      
      private var _mutexTabGroup:MutexAry = null;
      
      public function AstralSpiritPanel()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
         this._panelContainer = this.getChildByName("mcdetail") as DisplayObjectContainer;
         this._panelContainer.visible = false;
         this._panelHandler = new XinghuiSoulPanelHandler(this._panelContainer);
         this.addEventListener(MouseEvent.ROLL_OVER,this.onMouseOverListener);
         this.addEventListener(MouseEvent.ROLL_OUT,this.onMouseOutListener);
         this.addEventListener(MouseEvent.CLICK,this.onMouseClcikListener);
         this.buttonMode = true;
      }
      
      public function initTabHandle(param1:MutexAry) : void
      {
         this._mutexTabGroup = param1;
      }
      
      private function onMouseOverListener(param1:MouseEvent) : void
      {
         this._panelContainer.visible = true;
      }
      
      private function onMouseOutListener(param1:MouseEvent) : void
      {
         this._panelContainer.visible = false;
      }
      
      private function onMouseClcikListener(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnastralspirit")
         {
            TabJumpHelper.changeFirstTab(PetPackageTabs.TAB_ASTARLSPIRIT[0]);
            TabJumpHelper.changeSecondTab(PetPackageTabs.TAB_ASTARLSPIRIT[1]);
         }
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
         var _loc5_:MovieClip = null;
         this._pbi = param1;
         this._panelHandler.setPet(this._pbi);
         var _loc2_:int = 0;
         while(_loc2_ < AstralSpiritConfig.getTotalAstralSpiritPetCanEquip())
         {
            _loc5_ = this.getChildByName("mcicon" + _loc2_) as MovieClip;
            _loc5_.gotoAndStop(1);
            if(_loc2_ < this._pbi.astralSpiritUniqueIds.length)
            {
               _loc5_.visible = true;
               _loc5_.gotoAndStop(this._astralSpiritService.getMyAstralSpiritByUniqueId(this._pbi.astralSpiritUniqueIds[_loc2_]).level);
            }
            else
            {
               _loc5_.visible = false;
            }
            _loc2_++;
         }
         var _loc3_:MovieClip = this.getChildByName("mcsuit") as MovieClip;
         DisplayUtil.clearChildren(_loc3_);
         var _loc4_:int = int(AstralSpiritHelper.getSuitIdOfPet(this._pbi));
         if(_loc4_ > 0)
         {
            _loc3_.addChild(this._astralSpiritService.getSuitView(_loc4_));
         }
      }
      
      public function dispose() : void
      {
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
         this.removeEventListener(MouseEvent.ROLL_OVER,this.onMouseOverListener);
         this.removeEventListener(MouseEvent.ROLL_OUT,this.onMouseOutListener);
         this.removeEventListener(MouseEvent.CLICK,this.onMouseClcikListener);
      }
   }
}

