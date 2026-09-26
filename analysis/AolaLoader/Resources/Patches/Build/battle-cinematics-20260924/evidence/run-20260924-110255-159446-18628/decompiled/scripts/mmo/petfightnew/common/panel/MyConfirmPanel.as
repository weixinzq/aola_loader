package mmo.petfightnew.common.panel
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.ModalDialogEvent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol208")]
   public class MyConfirmPanel extends Sprite
   {
      
      public var btnCancel:SimpleButton;
      
      public var btnClose:SimpleButton;
      
      public var btnOK:SimpleButton;
      
      public function MyConfirmPanel(param1:String)
      {
         super();
         SimpleButton(this.btnOK).addEventListener(MouseEvent.CLICK,this.onOK);
         SimpleButton(this.btnCancel).addEventListener(MouseEvent.CLICK,this.onClose);
         SimpleButton(this.btnClose).addEventListener(MouseEvent.CLICK,this.onClose);
      }
      
      private function onOK(param1:MouseEvent) : void
      {
         this.dispatchEvent(new ModalDialogEvent(ModalDialogEvent.OK));
         this.close();
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         this.dispatchEvent(new ModalDialogEvent(ModalDialogEvent.CANCEL));
         this.close();
      }
      
      private function close() : void
      {
         DisplayUtil.stopAndRemove(this);
      }
   }
}

