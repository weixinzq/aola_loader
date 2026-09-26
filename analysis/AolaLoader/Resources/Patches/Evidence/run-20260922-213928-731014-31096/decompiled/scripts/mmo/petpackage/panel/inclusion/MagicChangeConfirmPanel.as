package mmo.petpackage.panel.inclusion
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol391")]
   public class MagicChangeConfirmPanel extends Sprite implements IShowPanel, IDispose
   {
      
      public var btnClose:SimpleButton;
      
      public var btnOk:SimpleButton;
      
      public var txtBeginName:TextField;
      
      public var txtEndName:TextField;
      
      private var callBack:Function;
      
      public function MagicChangeConfirmPanel(param1:String, param2:String, param3:Function = null)
      {
         super();
         this.callBack = param3;
         var _loc4_:TextField = this.getChildByName("txtBeginName") as TextField;
         _loc4_.mouseEnabled = false;
         _loc4_.text = param1;
         var _loc5_:TextField = this.getChildByName("txtEndName") as TextField;
         _loc5_.mouseEnabled = false;
         _loc5_.text = param2;
         this.init();
      }
      
      private function init() : void
      {
         this.addEventListener(MouseEvent.CLICK,this.onClickPanel);
      }
      
      private function onClickPanel(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name as String;
         if(_loc2_ == null)
         {
            return;
         }
         switch(_loc2_)
         {
            case "btnClose":
               this.closePanel();
               break;
            case "btnOk":
               this.closePanel();
               if(this.callBack != null)
               {
                  this.callBack.apply();
                  this.callBack = null;
               }
         }
      }
      
      private function closePanel() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      public function showPanel() : void
      {
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this,AlignType.NONE);
      }
      
      public function dispose() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClickPanel);
      }
   }
}

