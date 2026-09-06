package mmo.petfightnew.common.fightcontroller
{
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   
   public class FinBattleTimer
   {
      
      private static var _instance:FinBattleTimer;
      
      private var isOverTime:Boolean;
      
      private var timer:Timer;
      
      public function FinBattleTimer()
      {
         super();
      }
      
      public static function get instance() : FinBattleTimer
      {
         if(_instance == null)
         {
            _instance = new FinBattleTimer();
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
      
      public function addTimer() : void
      {
         if(this.timer != null)
         {
            return;
         }
         this.isOverTime = false;
         this.timer = new Timer(30000,1);
         this.timer.addEventListener(TimerEvent.TIMER,this.onTimer);
         this.timer.start();
      }
      
      private function onTimer(param1:TimerEvent) : void
      {
         this.isOverTime = true;
         this.disposeTimer();
      }
      
      private function disposeTimer() : void
      {
         if(this.timer == null)
         {
            return;
         }
         this.timer.stop();
         this.timer.removeEventListener(TimerEvent.TIMER,this.onTimer);
         this.timer = null;
      }
      
      public function checkIsOverTime() : Boolean
      {
         return this.isOverTime;
      }
   }
}

