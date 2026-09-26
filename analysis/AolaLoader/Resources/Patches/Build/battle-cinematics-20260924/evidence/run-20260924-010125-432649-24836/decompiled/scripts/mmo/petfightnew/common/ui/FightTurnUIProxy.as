package mmo.petfightnew.common.ui
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.fight.PetFightEvent;
   
   public class FightTurnUIProxy implements IDispose
   {
      
      protected var _uiView:MovieClip;
      
      protected var _isRes:Boolean;
      
      protected var _frame:int;
      
      protected var _currTurn:int = 1;
      
      protected var _maxTurn:int;
      
      protected var _isStop:Boolean;
      
      public function FightTurnUIProxy()
      {
         super();
      }
      
      public function init(param1:MovieClip, param2:int = 99999, param3:Boolean = false, param4:Boolean = false, param5:int = 1) : void
      {
         this._uiView = param1;
         this._maxTurn = param2;
         this._isRes = param3;
         this._frame = param5;
         this._isStop = param4;
         this.addListener();
         this.updateText();
      }
      
      protected function addListener() : void
      {
         this.removeListeners();
         if(this._isRes)
         {
            this._currTurn = this._maxTurn;
            CommonEventDispatcher.instance.addEventListener(PetFightEvent.NEXT_TURN,this.onNextTurnRes);
         }
         else
         {
            CommonEventDispatcher.instance.addEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         }
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.PET_BE_KILLED,this.onPetKill);
      }
      
      protected function onPetKill(param1:PetFightEvent) : void
      {
         var _loc2_:int = int(param1.params.diePetLocalId);
      }
      
      protected function onNextTurn(param1:PetFightEvent) : void
      {
         this._currTurn += 1;
         if(this._currTurn > this._maxTurn)
         {
            this._currTurn = this._isStop ? this._currTurn : 1;
         }
         this.updateText();
      }
      
      protected function onNextTurnRes(param1:PetFightEvent) : void
      {
         --this._currTurn;
         if(this._currTurn <= 0)
         {
            this._currTurn = this._isStop ? 0 : this._maxTurn;
         }
         this.updateText();
      }
      
      protected function setTxtValue(param1:String, param2:String) : void
      {
         var _loc3_:TextField = this._uiView.getChildByName(param1) as TextField;
         if(_loc3_ != null)
         {
            _loc3_.text = param2;
         }
      }
      
      public function setVisible(param1:Boolean) : void
      {
         if(this._uiView == null)
         {
            return;
         }
         this._uiView.visible = param1;
      }
      
      protected function updateText() : void
      {
         this.setTxtValue("txtTurn",this._currTurn + "");
      }
      
      private function removeListeners() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.NEXT_TURN,this.onNextTurnRes);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.PET_BE_KILLED,this.onPetKill);
      }
      
      public function dispose() : void
      {
         this.removeListeners();
         this._uiView = null;
      }
   }
}

