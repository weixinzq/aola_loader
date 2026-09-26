package mmo.petfightnew.common.manager
{
   import flash.display.Stage;
   import flash.events.Event;
   import mmo.loader.LoaderContainer;
   
   public class FightEnterFrameManager
   {
      
      private static var _instance:FightEnterFrameManager;
      
      private var _stage:Stage;
      
      private var isPause:Boolean;
      
      private var _frameInfoList:Vector.<FightFrameListener> = new Vector.<FightFrameListener>();
      
      public function FightEnterFrameManager()
      {
         super();
         this.initStage();
      }
      
      public static function get instance() : FightEnterFrameManager
      {
         return _instance = _instance || new FightEnterFrameManager();
      }
      
      public function initStage(param1:Stage = null) : void
      {
         this._stage = param1;
         if(this._stage == null)
         {
            this._stage = LoaderContainer.instance.stage;
         }
         this._stage.addEventListener(Event.ENTER_FRAME,this.onFrame);
      }
      
      public function addFrameListener(param1:FightFrameListener) : void
      {
         if(this._frameInfoList.indexOf(param1) == -1)
         {
            this._frameInfoList.push(param1);
         }
      }
      
      public function removeFrameListener(param1:FightFrameListener) : void
      {
         var _loc2_:int = int(this._frameInfoList.indexOf(param1));
         if(_loc2_ >= 0)
         {
            this._frameInfoList[_loc2_].dispose();
         }
      }
      
      public function pause() : void
      {
         this.isPause = true;
      }
      
      public function resume() : void
      {
         this.isPause = false;
      }
      
      public function dispose() : void
      {
         this._frameInfoList = new Vector.<FightFrameListener>();
         this._stage.removeEventListener(Event.ENTER_FRAME,this.onFrame);
         this._stage = null;
         _instance = null;
      }
      
      private function onFrame(param1:Event) : void
      {
         if(this.isPause)
         {
            return;
         }
         this.onListenerFrame();
         this.removeDisposedListener();
      }
      
      private function onListenerFrame() : void
      {
         var _loc1_:int = 0;
         while(_loc1_ < this._frameInfoList.length)
         {
            if(!this._frameInfoList[_loc1_].canDispose)
            {
               this._frameInfoList[_loc1_].onFrame();
            }
            _loc1_++;
         }
      }
      
      private function removeDisposedListener() : void
      {
         var _loc1_:int = int(this._frameInfoList.length - 1);
         while(_loc1_ >= 0)
         {
            if(this._frameInfoList[_loc1_].canDispose)
            {
               this._frameInfoList.splice(_loc1_,1);
            }
            _loc1_--;
         }
      }
   }
}

