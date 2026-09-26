package mmo.petfightnew.common
{
   import com.adobe.utils.ArrayUtil;
   import flash.display.DisplayObjectContainer;
   import flash.geom.Point;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.manager.FightEnterFrameManager;
   import mmo.petfightnew.common.manager.FightFrameListener;
   import mmo.petfightnew.common.useskill.SkillResults;
   
   public class SkillResultHandler
   {
      
      private const MAX_MOVIE_FRAME:int = 50;
      
      private const DIVIDED_MOVIE_INTERVAL_FRAME:int = 8;
      
      private var _totalChangedHp:int = 0;
      
      private var _skillResult:int = 0;
      
      private var _isCrit:Boolean = false;
      
      private var _isSkill:Boolean = false;
      
      private var _petPos:Point = null;
      
      private var _hpChangedList:Array = null;
      
      private var _skillEffect:int = 0;
      
      private var _isSuperEffect:Boolean = false;
      
      private var _movieContainer:DisplayObjectContainer = null;
      
      private var _multDecHpFrameListener:FightFrameListener = null;
      
      private var _totalDecHpFrameListener:FightFrameListener = null;
      
      private var _reallyHitDecHpFrameListener:FightFrameListener = null;
      
      private var _dividedMovieIndex:int = 0;
      
      private var _shpList:Array;
      
      private var _reallyMovieIndex:int = 0;
      
      private var _isShowAllHit:Boolean = false;
      
      private var _hpType:Array = [];
      
      public function SkillResultHandler(param1:DisplayObjectContainer, param2:int, param3:int, param4:Boolean, param5:Point, param6:Boolean, param7:Array, param8:int, param9:Boolean, param10:Array, param11:String, param12:Boolean)
      {
         super();
         this._movieContainer = param1;
         this._totalChangedHp = param2;
         this._skillResult = param3;
         this._isCrit = param4;
         this._isSkill = param6;
         this._petPos = param5;
         this._hpChangedList = param7;
         this._skillEffect = param8;
         this._isSuperEffect = param9;
         this._shpList = param10;
         this._isShowAllHit = param12;
         if(Boolean(param11) && param11 != "")
         {
            this._hpType = param11.split(",");
         }
      }
      
      private function onDividedMovie() : void
      {
         var _loc3_:int = 0;
         var _loc1_:SkillResultMovieHandler = new SkillResultMovieHandler(this._movieContainer);
         var _loc2_:Point = new Point(this._petPos.x + 80,this._petPos.y - 70);
         if(this._hpType.length > this._dividedMovieIndex)
         {
            _loc3_ = parseInt(this._hpType[this._dividedMovieIndex]);
            _loc1_.startMovie(this.isMulti(),this._hpChangedList[this._dividedMovieIndex++],this._skillResult,this._isCrit,this._skillEffect,this._isSuperEffect,_loc2_,_loc3_);
         }
         else
         {
            _loc1_.startMovie(this.isMulti(),this._hpChangedList[this._dividedMovieIndex++],this._skillResult,this._isCrit,this._skillEffect,this._isSuperEffect,_loc2_);
         }
         if(this._dividedMovieIndex >= this._hpChangedList.length)
         {
            _loc1_.showMultipleHitTimesMovie(this._hpChangedList.length);
         }
      }
      
      private function onReallyHitMovie() : void
      {
         var _loc1_:SkillResultMovieHandler = new SkillResultMovieHandler(this._movieContainer);
         var _loc2_:Point = new Point(this._petPos.x + 80,this._petPos.y - 70);
         ++this._reallyMovieIndex;
         if(this._shpList[this._reallyMovieIndex] != "" && int(this._shpList[this._reallyMovieIndex]) != 0)
         {
            _loc1_.startMovie(false,this._shpList[this._reallyMovieIndex],SkillResults.REALLY_HIT,false,this._skillEffect,this._isSuperEffect,_loc2_);
         }
      }
      
      private function onComplete() : void
      {
         var _loc5_:int = 0;
         var _loc6_:SkillResultMovieHandler = null;
         FightEnterFrameManager.instance.removeFrameListener(this._multDecHpFrameListener);
         FightEnterFrameManager.instance.removeFrameListener(this._totalDecHpFrameListener);
         FightEnterFrameManager.instance.removeFrameListener(this._reallyHitDecHpFrameListener);
         var _loc1_:SkillResultMovieHandler = new SkillResultMovieHandler(this._movieContainer);
         var _loc2_:Point = new Point(this._petPos.x + 50,this._petPos.y - 50);
         var _loc3_:int = 0;
         this._isCrit = false;
         var _loc4_:int = 0;
         while(_loc4_ < this._hpType.length)
         {
            _loc5_ = parseInt(this._hpType[_loc4_]);
            if(_loc5_ == SkillResultMovieHandler.HPType_ReallyHit)
            {
               _loc3_ += parseInt(this._hpChangedList[_loc4_]);
            }
            else if(_loc5_ == SkillResultMovieHandler.HPType_CriHit)
            {
               this._isCrit = true;
            }
            _loc4_++;
         }
         if(this._isShowAllHit)
         {
            _loc1_.startMovie(false,this._totalChangedHp,SkillResults.ALL_HIT,this._isCrit,this._skillEffect,this._isSuperEffect,_loc2_,-1,-_loc3_);
         }
         if(this._skillResult == SkillResults.MISS && this._totalChangedHp != 0)
         {
            _loc6_ = new SkillResultMovieHandler(this._movieContainer);
            if(this._hpChangedList.length == 1 && this._totalChangedHp == 1)
            {
               _loc6_.startMovie(false,this._totalChangedHp,this._skillResult,this._isCrit,this._skillEffect,this._isSuperEffect,_loc2_);
            }
            else
            {
               _loc6_.startMovie(this.isMulti(),this._totalChangedHp,this._skillResult,this._isCrit,this._skillEffect,this._isSuperEffect,_loc2_);
            }
            if(!ArrayUtil.arrayContainsValue(this._hpType,"5"))
            {
               _loc1_.startMovie(false,this._totalChangedHp,SkillResults.HIT,this._isCrit,this._skillEffect,this._isSuperEffect,_loc2_);
            }
         }
         else if(this._hpChangedList.length <= 0 || !ArrayUtil.arrayContainsValue(this._hpType,"3") && !ArrayUtil.arrayContainsValue(this._hpType,"4"))
         {
            _loc1_.startMovie(false,this._totalChangedHp,this._skillResult,this._isCrit,this._skillEffect,this._isSuperEffect,_loc2_,this._hpType[0]);
         }
         else if(this._hpChangedList.length == 1 && (Boolean(ArrayUtil.arrayContainsValue(this._hpType,"3")) || Boolean(ArrayUtil.arrayContainsValue(this._hpType,"4"))))
         {
            _loc1_.startMovie(false,this._totalChangedHp,this._skillResult,this._isCrit,this._skillEffect,this._isSuperEffect,_loc2_,this._hpType[0]);
         }
      }
      
      private function isMulti() : Boolean
      {
         return this._hpChangedList.length > 0;
      }
      
      private function getChangedCount() : int
      {
         return this._hpChangedList.length;
      }
      
      private function getReallyCount() : int
      {
         return this._shpList.length;
      }
      
      public function start() : void
      {
         var _loc1_:int = this.getChangedCount();
         var _loc2_:int = this.getReallyCount();
         if(_loc1_ <= 0 && _loc2_ <= 0)
         {
            return;
         }
         var _loc3_:int = this.DIVIDED_MOVIE_INTERVAL_FRAME;
         if(_loc1_ > 8 || _loc2_ > 8)
         {
            _loc3_ = Math.ceil(this.MAX_MOVIE_FRAME / _loc1_);
         }
         if(_loc1_ > 1)
         {
            this.dispatchMultiAttackEvent();
            this._multDecHpFrameListener = new FightFrameListener(this.onDividedMovie,_loc3_,_loc1_);
            FightEnterFrameManager.instance.addFrameListener(this._multDecHpFrameListener);
         }
         this._totalDecHpFrameListener = new FightFrameListener(this.onComplete,_loc3_ * _loc1_,1);
         FightEnterFrameManager.instance.addFrameListener(this._totalDecHpFrameListener);
         if(_loc2_ >= 1)
         {
            this._reallyHitDecHpFrameListener = new FightFrameListener(this.onReallyHitMovie,_loc3_,_loc2_);
            FightEnterFrameManager.instance.addFrameListener(this._reallyHitDecHpFrameListener);
         }
      }
      
      private function dispatchMultiAttackEvent() : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.MUTI_ATTACK,{"time":this.getChangedCount()}));
      }
   }
}

