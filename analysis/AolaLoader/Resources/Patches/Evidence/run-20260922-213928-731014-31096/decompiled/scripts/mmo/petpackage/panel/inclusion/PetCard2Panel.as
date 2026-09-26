package mmo.petpackage.panel.inclusion
{
   import flash.display.InteractiveObject;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignKey;
   import mmo.common.DisplayUtil;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.tips.TipsManager;
   import mmo.common.utils.tips.TipsType;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.material.PetCard2Client;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowDataPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.callback.FunCallInfo;
   import mmo.interfaces.changeable.PropertyChangeEvent;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.material.petcard2.IPetCard2Service;
   import mmo.interfaces.material.petcard2.PetCard2TipsMaker;
   import mmo.interfaces.material.petcard2.UserPetCard2;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.secondpwd.ISecondPwdService;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.helper.TabJumpHelper;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.panel.inclusion.petcard2panel.Petcard2Menu;
   import mmo.petpackage.panel.other.DowncardConfirmDialog;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1052")]
   public class PetCard2Panel extends Sprite implements IDispose
   {
      
      private var controlContainer:Sprite = null;
      
      private var viewContainer:Sprite = null;
      
      private var petcard2Service:IPetCard2Service = null;
      
      private var isViewLoading:Boolean = false;
      
      private var upc2:UserPetCard2 = null;
      
      private var petCard2View:InteractiveObject = null;
      
      private var petDataService:IPetDataService = null;
      
      private var hasCard:Boolean = false;
      
      public function PetCard2Panel()
      {
         super();
         this.initPars();
         this.initFuns();
         TipsManager.getInstance().addTips(this,"特性晶石");
      }
      
      private function initPars() : void
      {
         this.viewContainer = new Sprite();
         this.addChild(this.viewContainer);
         this.controlContainer = new Sprite();
         this.controlContainer.addChild(new Petcard2Menu());
         this.controlContainer.visible = false;
         this.addChild(this.controlContainer);
         this.petcard2Service = ServiceContainer.getMaterialService(MaterialTypes.PET_CARD2) as IPetCard2Service;
         this.petDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         this.buttonMode = true;
      }
      
      private function initFuns() : void
      {
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         this.addEventListener(MouseEvent.ROLL_OUT,this.onRollOut);
      }
      
      private function onRollOut(param1:MouseEvent) : void
      {
         if(this.hasCard)
         {
            this.controlContainer.visible = false;
            this.buttonMode = true;
         }
      }
      
      private function onDetailUpdate(param1:PetPackageEvent) : void
      {
         var _loc3_:PetDetailedInfo = null;
         var _loc2_:int = int(this.petDataService.getSelectPetId());
         if(param1.params.id == _loc2_)
         {
            _loc3_ = PetDetailDataMap.instance.getPetDetailInfo(_loc2_);
            this.updatePetDetailedInfo(_loc3_);
         }
      }
      
      private function onPropertyChanged(param1:PropertyChangeEvent) : void
      {
         this.refrshControl();
      }
      
      private function updatePetDetailedInfo(param1:PetDetailedInfo) : void
      {
         this.tryRemoveAndDisposeView();
         this.hasCard = -1 != param1.sc;
         if(this.hasCard)
         {
            this.upc2 = this.petcard2Service.getMyPetCard2BySerial(param1.sc);
            this.upc2.addEventListener(PropertyChangeEvent.onPropertyChanged,this.onPropertyChanged);
            this.tryAddView(param1.sc);
         }
         this.refrshControl();
      }
      
      private function tryAddView(param1:int) : void
      {
         var callback:Function;
         var cardSerial:int = param1;
         this.isViewLoading = true;
         callback = function(param1:int, param2:InteractiveObject):void
         {
            if(isViewLoading)
            {
               addView(param2);
            }
            else
            {
               DisplayUtil.stopAndRemove(param2);
            }
         };
         this.petcard2Service.loadView(this.upc2.materialId,callback,this);
      }
      
      private function addView(param1:InteractiveObject) : void
      {
         DisplayUtil.stopAndRemove(this.petCard2View);
         DisplayUtil.alignDisplay(param1,this.viewContainer,AlignKey.CENTER_BOTTOM,true);
         this.viewContainer.addChild(param1);
         this.petCard2View = param1;
         this.isViewLoading = false;
      }
      
      private function tryRemoveAndDisposeView() : void
      {
         if(null != this.petCard2View)
         {
            DisplayUtil.stopAndRemove(this.petCard2View);
            this.petCard2View = null;
            this.upc2.removeEventListener(PropertyChangeEvent.onPropertyChanged,this.onPropertyChanged);
            this.upc2 = null;
         }
         this.isViewLoading = false;
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         if(this.hasCard)
         {
            if(this.controlContainer.visible)
            {
               this.clickMenu(param1.target as SimpleButton);
            }
            else
            {
               this.controlContainer.visible = true;
               this.buttonMode = false;
            }
         }
         else
         {
            this.changeTab2Petcard2Panel();
         }
      }
      
      private function clickMenu(param1:SimpleButton) : void
      {
         var _loc2_:FunCallInfo = null;
         var _loc3_:ISecondPwdService = null;
         if(null != param1)
         {
            this.controlContainer.visible = false;
            _loc3_ = ServiceContainer.getService(ISecondPwdService) as ISecondPwdService;
            switch(param1.name)
            {
               case "btndown":
                  _loc2_ = new FunCallInfo(this.tryDownCard);
                  _loc3_.verify(_loc2_);
                  break;
               case "btnlevleup":
                  _loc2_ = new FunCallInfo(this.showLevelupPanel);
                  _loc3_.verify(_loc2_);
            }
            this.changeTab2Petcard2Panel();
         }
      }
      
      private function changeTab2Petcard2Panel() : void
      {
         TabJumpHelper.changeFirstTab(2);
         TabJumpHelper.changeSecondTab(2);
      }
      
      private function showLevelupPanel() : void
      {
         SimpleCustomLoader.loadSingleResource("pet/petcard2/petcard2levelup","mmo.petcard2levelup.Petcard2LevelupMain",LoadingSpriteType.DIALOG_WITHOUT_CANCLE,"正在加载……",function(param1:IShowDataPanel):void
         {
            param1.showPanelByData(upc2.serial);
         },this);
      }
      
      private function tryDownCard() : void
      {
         var _loc1_:ModalDialog = null;
         if(!this.petcard2Service.isPackageFull())
         {
            if(this.upc2.experience == 0)
            {
               this.downCard();
            }
            else
            {
               _loc1_ = ModalDialog.getCustomDialog(new DowncardConfirmDialog(this.upc2.discountExp + ""));
               _loc1_.addEventListener(ModalDialogEvent.OK,this.onMDOk);
               _loc1_.addEventListener(ModalDialogEvent.CLOSE,this.onMDClose);
               _loc1_.show();
            }
         }
         else
         {
            NewDialog.showSucceedMessage("你的特性背包" + this.petcard2Service.maxPackagePlace + "个位置已存满，暂时不能拆下特性。");
         }
      }
      
      private function onMDClose(param1:ModalDialogEvent) : void
      {
         var _loc2_:ModalDialog = param1.currentTarget as ModalDialog;
         _loc2_.removeEventListener(ModalDialogEvent.OK,this.onMDOk);
         _loc2_.removeEventListener(ModalDialogEvent.CLOSE,this.onMDClose);
      }
      
      private function onMDOk(param1:ModalDialogEvent) : void
      {
         this.onMDClose(param1);
         this.downCard();
      }
      
      private function downCard() : void
      {
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(PetCard2Client.cmdUnequipPSC,this.onUnequipPSC);
         PetCard2Client.unequipPSC(this.petDataService.getSelectPetId());
      }
      
      private function onUnequipPSC(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(PetCard2Client.cmdUnequipPSC,this.onUnequipPSC);
         ProgressFullSprite.close();
         if(param1.params.ok)
         {
            NewDialog.showSucceedMessage("成功卸下！");
            PetClient.instance.viewSinglePM(this.petDataService.getSelectPetId());
         }
         else
         {
            NewDialog.showSucceedMessage("卸下失败！");
         }
      }
      
      private function refrshControl() : void
      {
         this.clearControl();
         this.initControl();
      }
      
      private function clearControl() : void
      {
         if(this.controlContainer.numChildren > 0)
         {
            DisplayUtil.stopAndRemove(this.controlContainer.getChildAt(0));
         }
         TipsManager.getInstance().removeTips(this);
      }
      
      private function initControl() : void
      {
         var _loc1_:Sprite = null;
         if(null != this.upc2)
         {
            _loc1_ = new Sprite();
            this.controlContainer.addChild(new Petcard2Menu());
            TipsManager.getInstance().addComplexTips(this,PetCard2TipsMaker.getCommonPetCard2Title(this.upc2),PetCard2TipsMaker.getCommonPetCard2HTMLContent(this.upc2),0,9,9,TipsType.HTML);
         }
         else
         {
            TipsManager.getInstance().addTips(this,"特性晶石");
         }
      }
      
      public function dispose() : void
      {
         this.tryRemoveAndDisposeView();
         this.clearControl();
         SocketClient.instance.removeEventListener(PetCard2Client.cmdUnequipPSC,this.onUnequipPSC);
         TipsManager.getInstance().removeTips(this);
         this.removeEventListener(MouseEvent.CLICK,this.onClick);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
      }
   }
}

