package mmo.petpackage.panel.other
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol103")]
   public class XinghuiTipsPanel extends Sprite implements IShowPanel, IDispose
   {
      
      public var btnclose:SimpleButton;
      
      private var _clickHandler:Object;
      
      private var _eventHandler:Object = {};
      
      private var _preHandler:Object = {};
      
      private var _parentPreHandler:Object = {};
      
      public function XinghuiTipsPanel()
      {
         this._clickHandler = {"btnclose":this.onClickClose};
         super();
      }
      
      public function showPanel() : void
      {
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this,AlignType.NONE);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc3_:int = 0;
         var _loc4_:String = null;
         var _loc5_:int = 0;
         var _loc2_:String = param1.target.name;
         if(this._clickHandler.hasOwnProperty(_loc2_))
         {
            this._clickHandler[_loc2_].apply();
         }
         else if(this._eventHandler.hasOwnProperty(_loc2_))
         {
            this._eventHandler[_loc2_].apply(null,[param1]);
         }
         else if(this._parentPreHandler.hasOwnProperty(_loc2_))
         {
            _loc3_ = parseInt(param1.target.parent.name.split("_")[1]);
            this._parentPreHandler[_loc2_].apply(null,[_loc3_]);
         }
         else
         {
            _loc4_ = _loc2_.split("_")[0];
            if(this._preHandler.hasOwnProperty(_loc4_))
            {
               _loc5_ = parseInt(_loc2_.split("_")[1]);
               this._preHandler[_loc4_].apply(null,[_loc5_]);
            }
            else
            {
               this.onClickTargetEvt(param1);
            }
         }
      }
      
      private function onClickTargetEvt(param1:MouseEvent) : void
      {
      }
      
      private function onClickClose() : void
      {
         this.closePanel();
      }
      
      public function dispose() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      public function closePanel() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
   }
}

