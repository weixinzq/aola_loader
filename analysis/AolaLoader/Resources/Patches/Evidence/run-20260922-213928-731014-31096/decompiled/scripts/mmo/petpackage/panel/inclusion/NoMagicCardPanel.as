package mmo.petpackage.panel.inclusion
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.AlignType;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.rmbshoppingmall.IRmbShoppingMall;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol365")]
   public class NoMagicCardPanel extends Sprite implements IShowPanel, IDispose
   {
      
      public var btnClose:SimpleButton;
      
      public var btnOk:SimpleButton;
      
      public var txtName:TextField;
      
      public function NoMagicCardPanel(param1:String)
      {
         super();
         var _loc2_:TextField = this.getChildByName("txtName") as TextField;
         _loc2_.mouseEnabled = false;
         _loc2_.text = param1;
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
               ModalDialogManager.getInstance().clearAll();
               this.showShoppingMall();
         }
      }
      
      private function showShoppingMall() : void
      {
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService(IRmbShoppingMall,function(param1:IRmbShoppingMall, param2:Object = null):void
         {
            ProgressFullSprite.close();
            param1.showRmbShoppingPanel(7);
         });
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

