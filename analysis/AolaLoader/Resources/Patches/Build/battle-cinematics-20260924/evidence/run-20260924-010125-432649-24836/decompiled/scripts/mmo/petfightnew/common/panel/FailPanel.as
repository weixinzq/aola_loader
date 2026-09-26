package mmo.petfightnew.common.panel
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.pet.fight.PetFightEvent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2929")]
   public class FailPanel extends Sprite
   {
      
      public var btnClose:SimpleButton;
      
      public var btnOK:SimpleButton;
      
      public var txt:TextField;
      
      public function FailPanel(param1:String)
      {
         super();
         TextField(this.txt).text = param1;
         SimpleButton(this.btnClose).addEventListener(MouseEvent.CLICK,this.onClose);
         SimpleButton(this.btnOK).addEventListener(MouseEvent.CLICK,this.onClose);
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.CLICK_RESULT_PANEL));
      }
   }
}

