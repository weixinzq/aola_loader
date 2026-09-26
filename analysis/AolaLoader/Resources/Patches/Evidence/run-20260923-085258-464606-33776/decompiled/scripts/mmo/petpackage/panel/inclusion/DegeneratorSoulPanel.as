package mmo.petpackage.panel.inclusion
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.inscription.IInscriptionService;
   import mmo.interfaces.pet.data.IPetBattleEffDataService;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.petpackage.PetPackageTabs;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.uicomponent.mutex.MutexAry;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.helper.TabJumpHelper;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.play.activity.degenerator.DegeneratorSoulPanelHandler;
   
   public class DegeneratorSoulPanel extends Sprite implements IDispose
   {
      
      public var btnincription:SimpleButton;
      
      public var mcdetail:MovieClip;
      
      public var mcicon0:MovieClip;
      
      public var mcicon1:MovieClip;
      
      private var _petDataService:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
      
      private var _pmService:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      private var _petBattleEffService:IPetBattleEffDataService = ServiceContainer.getService(IPetBattleEffDataService) as IPetBattleEffDataService;
      
      private var _inscriptionService:IInscriptionService = ServiceContainer.getService(IInscriptionService) as IInscriptionService;
      
      private var _panelContainer:DisplayObjectContainer = null;
      
      private var _panelHandler:DegeneratorSoulPanelHandler = null;
      
      private var _pbi:PetBriefInfo;
      
      private var _mutexTabGroup:MutexAry = null;
      
      public function DegeneratorSoulPanel()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
         this._panelContainer = this.mcdetail;
         this._panelContainer.visible = false;
         this._panelHandler = new DegeneratorSoulPanelHandler(this._panelContainer);
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
         if(_loc2_ == "btnincription")
         {
            TabJumpHelper.changeFirstTab(PetPackageTabs.TAB_INS[0]);
            TabJumpHelper.changeSecondTab(PetPackageTabs.TAB_INS[1]);
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
         var _loc3_:MovieClip = null;
         var _loc4_:int = 0;
         this._pbi = param1;
         this._panelHandler.setPet(param1);
         var _loc2_:int = 0;
         while(_loc2_ < 2)
         {
            _loc3_ = this.getChildByName("mcicon" + _loc2_) as MovieClip;
            _loc4_ = int(this._pbi.getInscriptionByType(_loc2_));
            _loc3_.gotoAndStop(1);
            if(_loc4_ > 0)
            {
               _loc3_.visible = true;
               _loc3_.gotoAndStop(this._inscriptionService.getInscriptionById(_loc4_).level + 1);
            }
            else
            {
               _loc3_.visible = false;
            }
            _loc2_++;
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

