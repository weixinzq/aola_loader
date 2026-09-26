package mmo.petfightnew.common.useskill
{
   import flash.display.MovieClip;
   import mmo.petfightnew.common.component.CachedClip;
   import mmo.petfightnew.common.util.HpUtil;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2489")]
   public class AllHitHp extends HpChangeMovie
   {
      
      public var hp:MovieClip;
      
      public var hp1:MovieClip;
      
      public var mcReallyHitTitle:MovieClip;
      
      protected var _numMCList1:Array = [];
      
      protected var _bitNums1:Array = [];
      
      public function AllHitHp()
      {
         super();
         _numMcStartFrame = 1;
      }
      
      override protected function init() : void
      {
         var _loc3_:MovieClip = null;
         super.init();
         var _loc1_:MovieClip = this.getChildByName("hp1") as MovieClip;
         var _loc2_:int = 0;
         while(_loc2_ < TOTAL_NUM_MC)
         {
            _loc3_ = _loc1_.getChildByName("n" + _loc2_) as MovieClip;
            this._numMCList1[_loc2_] = new CachedClip(_loc3_);
            _loc2_++;
         }
      }
      
      public function startMovie1(param1:int, param2:int, param3:Function) : void
      {
         this._bitNums1 = HpUtil.formatHpNum(param2);
         var _loc4_:MovieClip = this.getChildByName("mcReallyHitTitle") as MovieClip;
         _loc4_.visible = param2 > 0;
         super.startMovie(param1,param3);
      }
      
      override protected function initView() : void
      {
         this.gotoAndStop(1);
         setNums();
         this.setNums1();
         this.startPlay();
      }
      
      protected function setNums1() : void
      {
         var _loc2_:CachedClip = null;
         var _loc3_:int = 0;
         var _loc1_:int = 0;
         while(_loc1_ < TOTAL_NUM_MC)
         {
            _loc2_ = this._numMCList1[_loc1_];
            _loc3_ = int(this._bitNums1[_loc1_]);
            if(_loc1_ >= this._bitNums1.length)
            {
               _loc2_.visible = false;
            }
            else
            {
               _loc2_.visible = true;
               _loc2_.gotoAndStop(_numMcStartFrame + _loc3_);
            }
            _loc1_++;
         }
      }
   }
}

