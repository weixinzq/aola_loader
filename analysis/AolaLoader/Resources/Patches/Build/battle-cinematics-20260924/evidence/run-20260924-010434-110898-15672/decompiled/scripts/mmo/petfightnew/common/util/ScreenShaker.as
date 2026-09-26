package mmo.petfightnew.common.util
{
   import flash.display.DisplayObject;
   import mmo.common.event.EnterFrameManager;
   
   public class ScreenShaker
   {
      
      private static const SHAKE_FRAME:int = 10;
      
      private static const SHAKE_RANGE_X:Number = 20;
      
      private static const SHAKE_RANGE_Y:Number = 10;
      
      private var target:DisplayObject;
      
      private var _onShakeEnd:Function;
      
      private var initX:Number;
      
      private var initY:Number;
      
      private var _currentFrame:int = 0;
      
      private var _isShaking:Boolean = false;
      
      private var _totalShakeFrame:int = 10;
      
      private var _autoDispose:Boolean;
      
      public function ScreenShaker(param1:DisplayObject, param2:Function = null, param3:Boolean = true)
      {
         super();
         this.target = param1;
         this._onShakeEnd = param2;
         this._autoDispose = param3;
         this.initX = this.target.x;
         this.initY = this.target.y;
      }
      
      public function shake() : void
      {
         EnterFrameManager.instance.register(this.shaking,null,1);
      }
      
      private function shaking() : void
      {
         ++this._currentFrame;
         if(this._currentFrame >= this._totalShakeFrame)
         {
            this._isShaking = false;
            this.resetTargetPos();
            if(this._autoDispose)
            {
               this.dispose();
            }
            if(this._onShakeEnd != null)
            {
               this._onShakeEnd.apply();
            }
            return;
         }
         this.target.x = this.initX + Math.random() * ScreenShaker.SHAKE_RANGE_X - ScreenShaker.SHAKE_RANGE_X / 2;
         this.target.y = this.initY + Math.random() * ScreenShaker.SHAKE_RANGE_Y - ScreenShaker.SHAKE_RANGE_Y / 2;
      }
      
      private function resetTargetPos() : void
      {
         if(this.target == null)
         {
            return;
         }
         this.target.x = this.initX;
         this.target.y = this.initY;
      }
      
      public function dispose() : void
      {
         this.resetTargetPos();
         EnterFrameManager.instance.remove(this.shaking);
         this.target = null;
      }
   }
}

