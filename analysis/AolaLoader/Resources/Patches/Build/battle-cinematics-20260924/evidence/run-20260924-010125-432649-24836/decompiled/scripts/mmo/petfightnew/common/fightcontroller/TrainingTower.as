package mmo.petfightnew.common.fightcontroller
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.datastructure.ConfuseInteger;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.fight.TrainingFightTypes;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightPanel;
   
   public class TrainingTower
   {
      
      private static var _instance:TrainingTower;
      
      public static const NOT_TRAINING:int = -1;
      
      private var fightPanel:FightPanel;
      
      private var count:int;
      
      private var type:int = -1;
      
      private var tipsPanel:MovieClip;
      
      private var countTxt:TextField;
      
      public var status:Array;
      
      public var maxRounds:int = 10;
      
      public var game:int;
      
      public var turns:int;
      
      public var timerInfo:Object;
      
      public var hurt:ConfuseInteger = new ConfuseInteger(0);
      
      public function TrainingTower()
      {
         super();
      }
      
      public static function get instance() : TrainingTower
      {
         if(_instance == null)
         {
            _instance = new TrainingTower();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel, param2:int) : void
      {
         this.type = param2;
         if(param2 == NOT_TRAINING)
         {
            this.dispose();
            return;
         }
         this.fightPanel = param1;
         switch(param2)
         {
            case TrainingFightTypes.ATTACK_TYPE:
               this.tipsPanel = new ConquerPanel();
               break;
            case TrainingFightTypes.DEFEND_TYPE:
               this.tipsPanel = new PersistPanel();
               break;
            case TrainingFightTypes.STATUS_TYPE:
               this.tipsPanel = new StatusPanel();
               this.setStatus();
               break;
            case TrainingFightTypes.TIMER_TYPE:
               this.tipsPanel = new TimerPanel();
               this.setTimer();
               break;
            case TrainingFightTypes.HURT_TYPE:
               this.tipsPanel = new HurtPanel();
               this.setHurt();
               break;
            case TrainingFightTypes.ROUND_TYPE:
               this.tipsPanel = new RoundPanel();
               this.setRound();
         }
         this.tipsPanel.mouseChildren = false;
         this.tipsPanel.mouseEnabled = false;
         this.countTxt = this.tipsPanel.getChildByName("txt") as TextField;
         FightController.instance.addEventListener(PetFightEvent.NEXT_TURN,this.onStartNextTurn);
      }
      
      private function setStatus() : void
      {
         var _loc3_:int = 0;
         var _loc5_:MovieClip = null;
         if(this.status == null)
         {
            return;
         }
         var _loc1_:Number = 617.55;
         var _loc2_:Number = 11.1;
         var _loc4_:int = 0;
         while(_loc4_ < this.status.length)
         {
            _loc5_ = new StatusWords();
            _loc3_ = this.getFrame(this.status[_loc4_]);
            _loc5_.gotoAndStop(_loc3_);
            _loc5_.y = _loc2_;
            _loc1_ += _loc4_ * 10;
            _loc5_.x = _loc1_;
            this.tipsPanel.addChild(_loc5_);
            _loc4_++;
         }
      }
      
      private function setTimer() : void
      {
         var _loc1_:TextField = this.tipsPanel.getChildByName("txtLayer") as TextField;
         _loc1_.mouseEnabled = false;
         _loc1_.text = this.timerInfo.layer.toString();
         var _loc2_:TextField = this.tipsPanel.getChildByName("txtMin") as TextField;
         _loc2_.mouseEnabled = false;
         _loc2_.text = this.timerInfo.min.toString();
         var _loc3_:TextField = this.tipsPanel.getChildByName("txtSec") as TextField;
         _loc3_.mouseEnabled = false;
         _loc3_.text = (100 + this.timerInfo.sec).toString().substr(1);
      }
      
      private function setHurt() : void
      {
         this.tipsPanel.x = 0;
         this.tipsPanel.y = 45;
         TextField(this.tipsPanel.getChildByName("txt")).text = this.hurt.getValue().toString();
      }
      
      public function addHurt(param1:int) : void
      {
         this.hurt.add(param1);
         if(this.type != TrainingFightTypes.HURT_TYPE)
         {
            return;
         }
         TextField(this.tipsPanel.getChildByName("txt")).text = this.hurt.getValue().toString();
      }
      
      private function setRound() : void
      {
         var _loc1_:TextField = this.tipsPanel.getChildByName("txtGame") as TextField;
         _loc1_.mouseEnabled = false;
         _loc1_.text = this.game.toString();
         var _loc2_:TextField = this.tipsPanel.getChildByName("txtTurn") as TextField;
         _loc2_.mouseEnabled = false;
         _loc2_.text = (this.turns - FightController.instance.turnCount).toString();
      }
      
      private function getFrame(param1:String) : int
      {
         var _loc2_:Array = [];
         _loc2_["中毒"] = 1;
         _loc2_["寄生"] = 2;
         _loc2_["害怕"] = 3;
         _loc2_["麻痹"] = 4;
         _loc2_["混乱"] = 5;
         _loc2_["冰冻"] = 6;
         _loc2_["烧伤"] = 7;
         _loc2_["束缚"] = 8;
         _loc2_["睡眠"] = 9;
         return _loc2_[param1];
      }
      
      public function closeTipsPanel() : void
      {
         DisplayUtil.stopAndRemove(this.tipsPanel);
      }
      
      public function addTipsPanel() : void
      {
         if(this.type == NOT_TRAINING)
         {
            return;
         }
         this.fightPanel.layerUI.addChild(this.tipsPanel);
         if(this.type != TrainingFightTypes.TIMER_TYPE && this.type != TrainingFightTypes.HURT_TYPE && this.type != TrainingFightTypes.ROUND_TYPE)
         {
            this.initPanel();
         }
         else if(this.type == TrainingFightTypes.ROUND_TYPE)
         {
            this.setRound();
         }
      }
      
      private function initPanel() : void
      {
         this.tipsPanel.y = 255.4;
         var _loc1_:int = this.maxRounds - FightController.instance.turnCount;
         _loc1_ = _loc1_ >= 0 ? _loc1_ : 0;
         this.countTxt.text = _loc1_.toString();
      }
      
      private function onStartNextTurn(param1:PetFightEvent) : void
      {
         this.addTipsPanel();
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         FightController.instance.removeEventListener(PetFightEvent.NEXT_TURN,this.onStartNextTurn);
         _instance = null;
      }
   }
}

