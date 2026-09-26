package mmo.petfightnew.common.useskill
{
   import flash.display.MovieClip;
   import mmo.petfightnew.common.component.CachedClip;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.petfightnew.common.util.HpUtil;
   
   public class HpChangeMovie extends MovieClip
   {
      
      protected const TOTAL_NUM_MC:int = 8;
      
      protected var _numMCList:Array = [];
      
      protected var _bitNums:Array = [];
      
      protected var _onMovieEnd:Function = null;
      
      protected var _numMcStartFrame:int = 0;
      
      public function HpChangeMovie()
      {
         super();
         this.init();
      }
      
      protected function init() : void
      {
         var _loc3_:MovieClip = null;
         this.gotoAndStop(1);
         var _loc1_:MovieClip = this.getChildByName("hp") as MovieClip;
         var _loc2_:int = 0;
         while(_loc2_ < this.TOTAL_NUM_MC)
         {
            _loc3_ = _loc1_.getChildByName("n" + _loc2_) as MovieClip;
            this._numMCList[_loc2_] = new CachedClip(_loc3_);
            _loc2_++;
         }
      }
      
      public function startMovie(param1:int, param2:Function) : void
      {
         this._bitNums = HpUtil.formatHpNum(param1);
         this._onMovieEnd = param2;
         this.initView();
      }
      
      protected function initView() : void
      {
         this.gotoAndStop(1);
         this.setNums();
         this.startPlay();
      }
      
      protected function startPlay() : void
      {
         FightMovieManager.instance.addMovie(this);
         this.addFrameScript(this.totalFrames - 1,this.dispose);
         this.gotoAndPlay(1);
      }
      
      protected function dispose() : void
      {
         FightMovieManager.instance.removeMovie(this);
         this.stop();
         this._onMovieEnd.apply();
      }
      
      protected function setNums() : void
      {
         var _loc2_:CachedClip = null;
         var _loc3_:int = 0;
         var _loc1_:int = 0;
         while(_loc1_ < this.TOTAL_NUM_MC)
         {
            _loc2_ = this._numMCList[_loc1_];
            _loc3_ = int(this._bitNums[_loc1_]);
            if(_loc1_ >= this._bitNums.length)
            {
               _loc2_.visible = false;
            }
            else
            {
               _loc2_.visible = true;
               _loc2_.gotoAndStop(this._numMcStartFrame + _loc3_);
            }
            _loc1_++;
         }
      }
   }
}

