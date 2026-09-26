package mmo.petfightnew.common.fightcontroller
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import flash.utils.setTimeout;
   import mmo.common.DateUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.petfightnew.common.FightController;
   import mmo.play.petfight.common.client.FightReplayClient;
   
   public class ReplayCmdExtractor_Queue
   {
      
      private const MIN_ADD_SCHEDULER:int = 1;
      
      private const MAX_ADD_SCHEDULER:int = 7;
      
      private const DELAY:int = 500;
      
      private var _isEnd:Boolean = false;
      
      private var _loadingReplayCmdUI:MovieClip = null;
      
      private var _onLoadEnd:Function = null;
      
      private var _scheduler:int = 0;
      
      private var _lastLoadTime:Number = 0;
      
      private var _totalSessionNum:int = 0;
      
      public function ReplayCmdExtractor_Queue()
      {
         super();
      }
      
      public function startLoadReplayCmd(param1:Function) : void
      {
         var onLoadEnd:Function = param1;
         this._onLoadEnd = onLoadEnd;
         this.showReplayUI(function():void
         {
            FightController.instance.addReplayListener();
            SocketClient.instance.addEventListener(FightReplayClient.CMD_LOAD_REPLAY_CMD,onLoadedReplayCmd);
            SocketClient.instance.addEventListener(FightReplayClient.CMD_LOAD_SESSION_COMPLETED,onSessionLoaded);
            SocketClient.instance.addEventListener(PetClient.RSPN_FIN_BATTLE,onLoadedAllReplayCmd);
            loadNextSession();
         });
      }
      
      private function onSessionLoaded(param1:SocketClientEvent) : void
      {
         ++this._totalSessionNum;
         var _loc2_:Number = Number(DateUtil.getServerTime().time);
         var _loc3_:Number = _loc2_ - this._lastLoadTime;
         if(_loc3_ > this.DELAY || _loc3_ <= 0)
         {
            this.loadNextSession();
         }
         else
         {
            setTimeout(this.loadNextSession,this.DELAY - _loc3_);
         }
      }
      
      private function loadNextSession() : void
      {
         if(this._isEnd)
         {
            return;
         }
         this._lastLoadTime = DateUtil.getServerTime().time;
         FightReplayClient.loadReplayCmd();
         this.randomAddScheduler();
         this.refreshScheduler();
      }
      
      private function showReplayUI(param1:Function) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function onLoadedReplayCmd(param1:SocketClientEvent) : void
      {
         var _loc2_:int = int(param1.params.res);
         if(_loc2_ == -1)
         {
            this._isEnd = true;
         }
      }
      
      private function refreshScheduler() : void
      {
         if(this._loadingReplayCmdUI == null)
         {
            return;
         }
         var _loc1_:TextField = this._loadingReplayCmdUI.txtscheduler;
         _loc1_.text = "(" + this._scheduler + "%)";
      }
      
      private function onLoadedAllReplayCmd(param1:SocketClientEvent) : void
      {
         this._scheduler = 100;
         this._isEnd = true;
         this.refreshScheduler();
         setTimeout(this.doLoadEnd,500);
      }
      
      private function doLoadEnd() : void
      {
         if(this._loadingReplayCmdUI)
         {
            ModalDialogManager.getInstance().removeModalDialog(this._loadingReplayCmdUI);
            this._loadingReplayCmdUI = null;
         }
         ProgressFullSprite.show();
         this.dispose();
         this._onLoadEnd.apply();
      }
      
      private function randomAddScheduler() : void
      {
         if(this._isEnd)
         {
            return;
         }
         this._scheduler += Math.random() * this.MAX_ADD_SCHEDULER + this.MIN_ADD_SCHEDULER;
         this._scheduler = Math.min(this._scheduler,99);
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(FightReplayClient.CMD_LOAD_REPLAY_CMD,this.onLoadedReplayCmd);
         SocketClient.instance.removeEventListener(FightReplayClient.CMD_LOAD_SESSION_COMPLETED,this.onSessionLoaded);
         SocketClient.instance.removeEventListener(PetClient.RSPN_FIN_BATTLE,this.onLoadedAllReplayCmd);
      }
   }
}

