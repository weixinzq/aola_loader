package mmo.petpackage.panel.other
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceContainerEvent;
   import mmo.interfaces.navigate.INavigateService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol419")]
   public class MessagePanel extends Sprite implements IDispose
   {
      
      public var bgframe0:MovieClip;
      
      public var btnOk:SimpleButton;
      
      public var btnclose:SimpleButton;
      
      public var message:TextField;
      
      public function MessagePanel(param1:String)
      {
         super();
         this.btnOk.addEventListener(MouseEvent.CLICK,this.onClickOk);
         SimpleButton(this.btnclose).addEventListener(MouseEvent.CLICK,this.onClickClose);
         this.message.text = param1;
      }
      
      public function dispose() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      private function onClickClose(param1:MouseEvent) : void
      {
         this.closePanel();
      }
      
      private function onClickOk(param1:MouseEvent) : void
      {
         ServiceContainer.instance.addEventListener(ServiceContainerEvent.onGetService,this.onGetService);
         ServiceContainer.instance.tryGetService("NavigateService");
         this.disposeEvent();
      }
      
      private function onGetService(param1:ServiceContainerEvent) : void
      {
         if(param1.serviceName != "NavigateService")
         {
            return;
         }
         ServiceContainer.instance.removeEventListener(ServiceContainerEvent.onGetService,this.onGetService);
         var _loc2_:INavigateService = param1.service as INavigateService;
         _loc2_.goToBlueDiamond();
      }
      
      private function disposeEvent() : void
      {
         ServiceContainer.instance.removeEventListener(ServiceContainerEvent.onGetService,this.onGetService);
      }
      
      private function closePanel() : void
      {
         this.disposeEvent();
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
   }
}

