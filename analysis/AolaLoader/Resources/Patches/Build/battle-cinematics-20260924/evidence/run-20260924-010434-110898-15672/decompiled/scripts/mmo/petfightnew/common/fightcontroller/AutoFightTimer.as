package mmo.petfightnew.common.fightcontroller
{
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.manager.FightEnterFrameManager;
   import mmo.petfightnew.common.manager.FightFrameListener;
   
   public class AutoFightTimer
   {
      
      private static var _instance:AutoFightTimer;
      
      private var _frameListener:FightFrameListener = null;
      
      private var callBack:Function;
      
      public function AutoFightTimer()
      {
         super();
      }
      
      public static function get instance() : AutoFightTimer
      {
         if(_instance == null)
         {
            _instance = new AutoFightTimer();
         }
         return _instance;
      }
      
      public static function dispose() : void
      {
         if(_instance == null)
         {
            return;
         }
         _instance.disposeTimer();
         _instance = null;
      }
      
      public function registerTimer(param1:Function) : void
      {
         if(this._frameListener != null)
         {
            return;
         }
         this.callBack = param1;
         this._frameListener = new FightFrameListener(this.onTimerCompleted,1 * 25,1);
         FightEnterFrameManager.instance.addFrameListener(this._frameListener);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FightCountPause,this.fightCountPause);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FightCountReset,this.fightCountReset);
      }
      
      public function disposeTimer() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FightCountPause,this.fightCountPause);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FightCountReset,this.fightCountReset);
         if(this._frameListener == null)
         {
            return;
         }
         this._frameListener.dispose();
         FightEnterFrameManager.instance.removeFrameListener(this._frameListener);
         this._frameListener = null;
         this.callBack = null;
      }
      
      private function onTimerCompleted() : void
      {
         this.callBack.apply();
         this.disposeTimer();
      }
      
      public function pause() : void
      {
         if(this._frameListener)
         {
            this._frameListener.pause();
         }
      }
      
      public function resume() : void
      {
         if(this._frameListener)
         {
            this._frameListener.resume();
         }
      }
      
      private function fightCountPause(param1:PetFightEvent) : void
      {
         this.pause();
      }
      
      private function fightCountReset(param1:PetFightEvent) : void
      {
         this.resume();
      }
   }
}

