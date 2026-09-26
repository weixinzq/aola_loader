package mmo.petpackage.panel.other
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.petpackage.controller.skin.constant.Classify;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol229")]
   public class SetLockStatePanel extends Sprite implements IShowPanel, IDispose
   {
      
      public var btnclose:SimpleButton;
      
      public var mcselect_0:MovieClip;
      
      public var mcselect_1:MovieClip;
      
      public var mcselect_2:MovieClip;
      
      private const SHOW_STATE_KEY:String = "Package_PET_Show_State";
      
      private var obj:Object = null;
      
      private var _cbFun:Function = null;
      
      private var _hasBg:Boolean = false;
      
      private var _mcSelect0:MovieClip;
      
      private var _mcSelect1:MovieClip;
      
      private var _mcSelect2:MovieClip;
      
      public function SetLockStatePanel(param1:Boolean, param2:Function, param3:Object)
      {
         super();
         this.obj = param3;
         this._cbFun = param2;
         this._hasBg = param1;
         this.initPanel();
      }
      
      private function initPanel() : void
      {
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         this._mcSelect0 = this.mcselect_0 as MovieClip;
         this._mcSelect1 = this.mcselect_1 as MovieClip;
         this._mcSelect2 = this.mcselect_2 as MovieClip;
         var _loc1_:int = -1;
         if(LocalStore.getValue(this.SHOW_STATE_KEY))
         {
            _loc1_ = int(LocalStore.getValue(this.SHOW_STATE_KEY)["classify"]);
         }
         if(_loc1_ == Classify.NORMAL)
         {
            this._mcSelect0.gotoAndStop(2);
            this._mcSelect1.gotoAndStop(1);
            this._mcSelect2.gotoAndStop(this._hasBg ? 1 : 3);
         }
         else if(_loc1_ == Classify.LEGENDARY)
         {
            this._mcSelect0.gotoAndStop(1);
            this._mcSelect1.gotoAndStop(2);
            this._mcSelect2.gotoAndStop(this._hasBg ? 1 : 3);
         }
         else if(_loc1_ == Classify.FULL_SCRREN)
         {
            this._mcSelect0.gotoAndStop(1);
            this._mcSelect1.gotoAndStop(1);
            this._mcSelect2.gotoAndStop(2);
         }
         else
         {
            this._mcSelect0.gotoAndStop(1);
            this._mcSelect1.gotoAndStop(1);
            this._mcSelect2.gotoAndStop(1);
         }
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnclose")
         {
            this.onClose();
         }
         else if(_loc2_ == "btnselect")
         {
            this.onSelect(param1);
         }
      }
      
      private function onClose() : void
      {
         this.closePanel();
      }
      
      private function onSelect(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.parent.name;
         var _loc3_:Array = _loc2_.split("_");
         var _loc4_:int = int(_loc3_[1]);
         LocalStore.setValue(this.SHOW_STATE_KEY,{"classify":_loc4_});
         this._cbFun.apply(null,[_loc4_,false]);
         this.closePanel();
      }
      
      private function closePanel() : void
      {
         this.disposeEvent();
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      private function disposeEvent() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      public function showPanel() : void
      {
         ModalDialogManager.getInstance().addModalDialog(this);
      }
      
      public function dispose() : void
      {
         this.disposeEvent();
      }
   }
}

