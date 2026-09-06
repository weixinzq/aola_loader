package mmo.petfightnew.common.ui
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.manager.FightFrameRateManager;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1437")]
   public class ReplayUI extends Sprite
   {
      
      public var btnclose:SimpleButton;
      
      public var mcReplayTab_0:MovieClip;
      
      public var mcReplayTab_1:MovieClip;
      
      public var mcpause:MovieClip;
      
      public var mcspeed:MovieClip;
      
      public var txtTurn:TextField;
      
      private const SPEED_FRAME_RATE:Array = [12,25,50];
      
      private var _curTurn:int = 0;
      
      private var _fightPanel:FightPanel = null;
      
      private var _totalTurn:int = 0;
      
      private var _curSpeedIndex:int = 1;
      
      private var _curReplayTab:int = 0;
      
      private var _replayTabCount:int = 2;
      
      public function ReplayUI()
      {
         super();
         this.initComponents();
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
      }
      
      private function initComponents() : void
      {
         var _loc1_:MovieClip = this.mcpause;
         _loc1_.gotoAndStop(1);
         _loc1_.addEventListener(MouseEvent.CLICK,this.onClickPause);
         var _loc2_:SimpleButton = this.btnclose;
         _loc2_.addEventListener(MouseEvent.CLICK,this.onClickClose);
         var _loc3_:MovieClip = this.mcspeed;
         _loc3_.buttonMode = true;
         _loc3_.addEventListener(MouseEvent.CLICK,this.onClickSpeed);
         this.changeReplayTab(0);
         this.refresh();
      }
      
      private function onClickSpeed(param1:MouseEvent) : void
      {
         ++this._curSpeedIndex;
         this._curSpeedIndex %= this.SPEED_FRAME_RATE.length;
         FightFrameRateManager.instance.changeFrameRate(this.SPEED_FRAME_RATE[this._curSpeedIndex]);
         this.refresh();
      }
      
      private function onClickClose(param1:MouseEvent) : void
      {
         this._fightPanel.close();
      }
      
      private function onClickTab(param1:MouseEvent) : void
      {
         var _loc2_:int = int(ActComHelper.getNumFromStr(param1.target.parent.name));
         this.changeReplayTab(_loc2_);
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.REPLAY_CHANGE_TALK_TAB,{"tab":_loc2_}));
      }
      
      private function onClickPause(param1:MouseEvent) : void
      {
         var _loc2_:MovieClip = param1.currentTarget as MovieClip;
         if(_loc2_.currentFrame == 1)
         {
            this._fightPanel.pause();
            _loc2_.gotoAndStop(2);
         }
         else
         {
            this._fightPanel.resume();
            _loc2_.gotoAndStop(1);
         }
      }
      
      private function onNextTurn(param1:PetFightEvent) : void
      {
         ++this._curTurn;
         FightController.instance.replayTurnCount;
         this.refresh();
      }
      
      private function refresh() : void
      {
         Panel_Helper.setTextValue(this,"txtTurn",this._curTurn + "/" + this._totalTurn);
         var _loc1_:MovieClip = this.mcspeed;
         _loc1_.gotoAndStop(this._curSpeedIndex + 1);
      }
      
      private function changeReplayTab(param1:int) : void
      {
         var _loc3_:SimpleButton = null;
         this._curReplayTab = param1;
         var _loc2_:int = 0;
         while(_loc2_ < this._replayTabCount)
         {
            ActComHelper.setMcFrame(this,"mcReplayTab_" + _loc2_,this._curReplayTab == _loc2_ ? 2 : 1);
            _loc3_ = this["mcReplayTab_" + _loc2_].btnReplayTab;
            if(_loc3_)
            {
               _loc3_.addEventListener(MouseEvent.CLICK,this.onClickTab);
            }
            _loc2_++;
         }
      }
      
      public function init(param1:int, param2:FightPanel) : void
      {
         this._totalTurn = param1;
         this._fightPanel = param2;
         this.refresh();
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         this._fightPanel = null;
      }
   }
}

