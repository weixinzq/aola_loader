package mmo.petpackage.panel.other
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.peticon.IPetIcon;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.loader.scheduler.ResScheduler;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol445")]
   public class BackStoreMessagePanel extends Sprite implements IShowPanel, IDispose
   {
      
      public var btncancel:SimpleButton;
      
      public var btnclose:SimpleButton;
      
      public var btnoK:SimpleButton;
      
      public var info:TextField;
      
      public var petcontainer:MovieClip;
      
      private var btnClose:SimpleButton = null;
      
      private var btnOk:SimpleButton = null;
      
      private var btnCancel:SimpleButton = null;
      
      private var petContainer:Sprite = null;
      
      private var petIcon:PetIconContainer = null;
      
      private var petIconService:IPetIcon = null;
      
      private var pbi:PetBriefInfo = null;
      
      private var okFun:Function = null;
      
      private var obj:Object = null;
      
      public function BackStoreMessagePanel(param1:PetBriefInfo, param2:Function, param3:Object)
      {
         super();
         this.pbi = param1;
         this.okFun = param2;
         this.obj = param3;
         var _loc4_:String = this.pbi.name == this.pbi.nickname ? this.pbi.name : this.pbi.name + "(" + this.pbi.nickname + ")";
         TextField(this.info).text = _loc4_;
         this.initPars();
         this.initFuns();
         this.loadIcon();
      }
      
      private function initPars() : void
      {
         this.btnClose = this.btnclose as SimpleButton;
         this.btnCancel = this.btncancel as SimpleButton;
         this.btnOk = this.btnoK as SimpleButton;
         this.petContainer = this.petcontainer.mcView as Sprite;
         this.petIconService = ServiceContainer.getService("PetIconService") as IPetIcon;
      }
      
      private function initFuns() : void
      {
         this.btnCancel.addEventListener(MouseEvent.CLICK,this.onCancel);
         this.btnClose.addEventListener(MouseEvent.CLICK,this.onCancel);
         this.btnOk.addEventListener(MouseEvent.CLICK,this.onOk);
      }
      
      private function loadIcon() : void
      {
         this.petIcon = this.petIconService.getPetIcon(this.pbi.viewId,PetIconType.FIGHT,false);
         this.petIcon.addEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoaded);
         this.petIcon.startLoad();
      }
      
      private function onLoaded(param1:PetIconEvent) : void
      {
         this.petIcon.removeEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoaded);
         this.petContainer.addChild(this.petIcon);
      }
      
      private function onOk(param1:MouseEvent) : void
      {
         this.closePanel();
         if(null != this.okFun && null != this.obj)
         {
            this.okFun.apply(this.obj,[]);
         }
      }
      
      private function onCancel(param1:MouseEvent) : void
      {
         this.closePanel();
      }
      
      private function onWhere(param1:MouseEvent) : void
      {
         var e:MouseEvent = param1;
         ProgressFullSprite.show();
         ResScheduler.getResource("pet/petpackagehelper",function(param1:IShowPanel):void
         {
            ProgressFullSprite.close();
            param1.showPanel();
         },"mmo.petpackagehelper.HelpPanel");
      }
      
      public function showPanel() : void
      {
         ModalDialogManager.getInstance().addModalDialog(this);
      }
      
      private function closePanel() : void
      {
         this.disposeEvent();
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      private function disposeEvent() : void
      {
         this.btnCancel.removeEventListener(MouseEvent.CLICK,this.onCancel);
         this.btnClose.removeEventListener(MouseEvent.CLICK,this.onCancel);
         this.btnOk.removeEventListener(MouseEvent.CLICK,this.onOk);
      }
      
      public function dispose() : void
      {
         this.disposeEvent();
      }
   }
}

