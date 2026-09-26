package mmo.petfightnew.common.ui
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.manager.FightFrameRateManager;
   import mmo.play.activity.helper.Panel_Helper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3869")]
   public class FightLiveUI extends Sprite
   {
      
      public var btnclose:SimpleButton;
      
      public var mcpause:MovieClip;
      
      public var txtTurn:TextField;
      
      private const SPEED_FRAME_RATE:Array = [12,25,50];
      
      private var _curTurn:int = 0;
      
      private var _fightPanel:FightPanel = null;
      
      private var _totalTurn:int = 0;
      
      private var _curSpeedIndex:int = 1;
      
      public function FightLiveUI()
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
         this.refresh();
      }
      
      private function refresh() : void
      {
         this._totalTurn = Math.max(this._curTurn,this._totalTurn);
         Panel_Helper.setTextValue(this,"txtTurn",this._curTurn + "/" + this._totalTurn);
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

