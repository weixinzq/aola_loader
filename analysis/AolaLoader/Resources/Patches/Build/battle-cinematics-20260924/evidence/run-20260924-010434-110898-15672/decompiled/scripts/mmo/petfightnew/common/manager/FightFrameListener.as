package mmo.petfightnew.common.manager
{
   public class FightFrameListener
   {
      
      private var _totalRepeatTimes:int = 0;
      
      private var _curRepeatTimes:int = 0;
      
      private var _intervalFrame:int = 0;
      
      private var _curFrameIndex:int = 0;
      
      private var _callback:Function = null;
      
      private var _params:Array = null;
      
      private var _isPause:Boolean = false;
      
      private var _canDispose:Boolean = false;
      
      public function FightFrameListener(param1:Function, param2:int, param3:int = 0, param4:Array = null)
      {
         super();
         this._totalRepeatTimes = param3;
         this._intervalFrame = Math.max(param2,1);
         this._callback = param1;
         this._params = param4;
         this._curRepeatTimes = 0;
         this._curFrameIndex = 0;
      }
      
      public function get totalRepeatTimes() : int
      {
         return this._totalRepeatTimes;
      }
      
      public function get curRepeatTimes() : int
      {
         return this._curRepeatTimes;
      }
      
      public function set curRepeatTimes(param1:int) : void
      {
         this._curRepeatTimes = param1;
      }
      
      public function get intervalFrame() : *
      {
         return this._intervalFrame;
      }
      
      public function get params() : Array
      {
         return this._params;
      }
      
      public function onFrame() : void
      {
         if(this._canDispose)
         {
            return;
         }
         if(this._isPause)
         {
            return;
         }
         ++this._curFrameIndex;
         if(this._curFrameIndex % this._intervalFrame == 0)
         {
            this._callback.apply(null,this._params);
            ++this._curRepeatTimes;
         }
         this._canDispose = this._totalRepeatTimes > 0 && this._curRepeatTimes >= this._totalRepeatTimes;
      }
      
      public function dispose() : void
      {
         this._canDispose = true;
      }
      
      public function get canDispose() : Boolean
      {
         return this._canDispose;
      }
      
      public function pause() : void
      {
         this._isPause = true;
      }
      
      public function resume() : void
      {
         this._isPause = false;
      }
   }
}

