package mmo.petfightnew.common.component
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   
   public class StaticButton extends Sprite
   {
      
      public static const STATE_UP:int = 0;
      
      public static const STATE_OVER:int = 1;
      
      public static const STATE_DOWN:int = 2;
      
      private var _upState:DisplayObject;
      
      private var _overState:DisplayObject;
      
      private var _downState:DisplayObject;
      
      private var _stateDisplayArray:Array = [];
      
      private var _currentState:int = 0;
      
      private var _currentDisObj:DisplayObject;
      
      private var _enabled:Boolean = true;
      
      private var _fixedState:int = -1;
      
      public function StaticButton()
      {
         super();
         this.buttonMode = true;
         this.mouseChildren = false;
         this.changeState(STATE_UP);
         this.bindListener();
      }
      
      private function bindListener() : void
      {
         this.addEventListener(MouseEvent.ROLL_OVER,this.onMouseOverListener);
         this.addEventListener(MouseEvent.ROLL_OUT,this.onMouseOutListener);
         this.addEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDownListener);
         this.addEventListener(MouseEvent.MOUSE_UP,this.onMouseUpListener);
      }
      
      private function onMouseDownListener(param1:MouseEvent) : void
      {
         this.changeState(STATE_DOWN);
      }
      
      private function onMouseUpListener(param1:MouseEvent) : void
      {
         this.checkHit(false);
      }
      
      private function checkHit(param1:Boolean) : void
      {
         var _loc2_:Point = this.localToGlobal(new Point(this.mouseX,this.mouseY));
         if(this.hitTestPoint(_loc2_.x,_loc2_.y))
         {
            this.changeState(STATE_OVER,param1);
         }
         else
         {
            this.changeState(STATE_UP,param1);
         }
      }
      
      private function onMouseOutListener(param1:MouseEvent) : void
      {
         if(!this._enabled)
         {
            return;
         }
         this.changeState(STATE_UP);
      }
      
      private function onMouseOverListener(param1:MouseEvent) : void
      {
         if(!this._enabled)
         {
            return;
         }
         this.changeState(STATE_OVER);
      }
      
      private function changeState(param1:int, param2:Boolean = false) : void
      {
         if(!this._enabled)
         {
            param1 = STATE_UP;
         }
         if(this.haveFixedState())
         {
            param1 = this._fixedState;
         }
         if(this._currentState == param1 && !param2)
         {
            return;
         }
         var _loc3_:DisplayObject = this.getStateDisObj(param1);
         this._currentState = param1;
         if(this._currentDisObj != null && this.contains(this._currentDisObj))
         {
            if(!(_loc3_ != this._currentDisObj || param2))
            {
               return;
            }
            this.removeChild(this._currentDisObj);
         }
         if(_loc3_ != null)
         {
            this.addChild(_loc3_);
         }
         this._currentDisObj = _loc3_;
      }
      
      private function getStateDisObj(param1:int) : DisplayObject
      {
         if(this._stateDisplayArray == null)
         {
            return null;
         }
         return this._stateDisplayArray[param1];
      }
      
      public function get upState() : DisplayObject
      {
         return this._upState;
      }
      
      public function set upState(param1:DisplayObject) : void
      {
         this.setStateDisObj(STATE_UP,param1);
      }
      
      public function get overState() : DisplayObject
      {
         return this._overState;
      }
      
      public function set overState(param1:DisplayObject) : void
      {
         this.setStateDisObj(STATE_OVER,param1);
      }
      
      public function get downState() : DisplayObject
      {
         return this._downState;
      }
      
      public function set downState(param1:DisplayObject) : void
      {
         this.setStateDisObj(STATE_DOWN,param1);
      }
      
      private function setStateDisObj(param1:int, param2:DisplayObject) : void
      {
         this._stateDisplayArray[param1] = param2;
         if(param1 == STATE_UP || this._currentState == param1)
         {
            this.changeState(param1,true);
         }
      }
      
      public function fixState(param1:int) : void
      {
         this._fixedState = param1;
         this.changeState(param1,true);
      }
      
      private function haveFixedState() : Boolean
      {
         return this._fixedState >= 0;
      }
      
      public function cancelFix() : void
      {
         this._fixedState = -1;
      }
      
      public function dispose() : void
      {
         this.removeEventListener(MouseEvent.MOUSE_OVER,this.onMouseOverListener);
         this.removeEventListener(MouseEvent.MOUSE_OUT,this.onMouseOutListener);
         this.removeEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDownListener);
         this.removeEventListener(MouseEvent.MOUSE_UP,this.onMouseUpListener);
         DisplayUtil.stopAndRemove(this);
         this._stateDisplayArray = null;
         this._upState = null;
         this._downState = null;
         this._overState = null;
         this._currentDisObj = null;
      }
      
      public function get enabled() : Boolean
      {
         return this._enabled;
      }
      
      public function set enabled(param1:Boolean) : void
      {
         this._enabled = param1;
         this.buttonMode = this._enabled;
      }
   }
}

