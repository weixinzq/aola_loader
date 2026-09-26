package mmo.petfightnew.common.movies
{
   import flash.display.MovieClip;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.component.CachedClip;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.util.DisableUtil;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3851")]
   public class CountMovie extends MovieClip
   {
      
      private static const MAX_NUM_BIT:int = 2;
      
      private static const RED_NUM_START_VALUE:int = 3;
      
      public var mcSub:MovieClip;
      
      private var _numWidth:Number;
      
      private var _onEnd:Function;
      
      private var _numList:Array;
      
      private var _leftSeconds:int = 0;
      
      private var _isPause:Boolean = false;
      
      public function CountMovie()
      {
         var _loc3_:MovieClip = null;
         super();
         DisableUtil.disableAll(this);
         this.stop();
         var _loc1_:MovieClip = this.getChildByName("mcSub") as MovieClip;
         this._numList = [];
         var _loc2_:int = 0;
         while(_loc2_ < MAX_NUM_BIT)
         {
            _loc3_ = _loc1_.getChildByName("mcNum" + _loc2_) as MovieClip;
            if(_loc2_ == 0)
            {
               this._numWidth = _loc3_.width;
            }
            this._numList[_loc2_] = new CachedClip(_loc3_);
            _loc2_++;
         }
         this.addFrameScript(this.totalFrames - 1,this.onOneLoop);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FightCountPause,this.fightCountPause);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FightCountReset,this.fightCountReset);
      }
      
      private function fightCountPause(param1:PetFightEvent) : void
      {
         this._isPause = true;
      }
      
      private function fightCountReset(param1:PetFightEvent) : void
      {
         this._isPause = false;
      }
      
      private function onOneLoop() : void
      {
         if(this._isPause)
         {
            return;
         }
         if(this._leftSeconds >= 0)
         {
            --this._leftSeconds;
            this.updateNum();
            if(this._leftSeconds < 0)
            {
               this.stop();
               ++FightData.instance.forceAutoCount;
               if(!FightData.instance.isPVE && FightController.instance.canAuto)
               {
                  FightController.isAutoUseSkill = true;
               }
               this._onEnd.apply();
            }
            FightEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.ON_COUNTDOWN,{"leftSecond":this._leftSeconds}));
         }
      }
      
      private function updateNum() : void
      {
         var _loc3_:CachedClip = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc1_:String = this._leftSeconds.toString();
         var _loc2_:int = 0;
         while(_loc2_ < MAX_NUM_BIT)
         {
            _loc3_ = this._numList[_loc2_];
            _loc4_ = _loc1_.length;
            if(_loc2_ < _loc4_)
            {
               _loc5_ = parseInt(_loc1_.charAt(_loc4_ - _loc2_ - 1));
               if(this._leftSeconds > RED_NUM_START_VALUE)
               {
                  _loc3_.gotoAndStop(_loc5_ + 1);
               }
               else
               {
                  _loc3_.gotoAndStop(_loc5_ + 11);
               }
               _loc3_.visible = true;
               _loc3_.x = -(_loc2_ + _loc4_ % 2 / 2) * this._numWidth;
            }
            else
            {
               _loc3_.visible = false;
            }
            _loc2_++;
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:CachedClip = null;
         this.stop();
         for each(_loc1_ in this._numList)
         {
            _loc1_.dispose();
         }
         this._numList.length = 0;
         this._numList = null;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FightCountPause,this.fightCountPause);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FightCountReset,this.fightCountReset);
      }
      
      public function startCount(param1:int, param2:Function) : void
      {
         this._leftSeconds = param1;
         this._onEnd = param2;
         this.updateNum();
         this.play();
      }
   }
}

