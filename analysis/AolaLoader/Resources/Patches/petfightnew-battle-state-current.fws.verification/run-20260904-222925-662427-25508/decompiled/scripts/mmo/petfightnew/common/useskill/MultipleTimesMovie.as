package mmo.petfightnew.common.useskill
{
   import flash.display.MovieClip;
   import mmo.petfightnew.common.component.CachedClip;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2433")]
   public class MultipleTimesMovie extends HpChangeMovie
   {
      
      public var hp:MovieClip;
      
      public function MultipleTimesMovie()
      {
         super();
         _numMcStartFrame = 1;
      }
      
      override protected function init() : void
      {
         var _loc3_:MovieClip = null;
         this.gotoAndStop(1);
         var _loc1_:MovieClip = this.getChildByName("hp") as MovieClip;
         var _loc2_:int = 0;
         while(_loc2_ < 2)
         {
            _loc3_ = _loc1_.getChildByName("n" + _loc2_) as MovieClip;
            this._numMCList[_loc2_] = new CachedClip(_loc3_);
            _loc2_++;
         }
      }
      
      override protected function setNums() : void
      {
         var _loc3_:CachedClip = null;
         var _loc4_:int = 0;
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         while(_loc2_ < 2)
         {
            _loc3_ = this._numMCList[_loc2_];
            if(_bitNums.length + _loc2_ < 2)
            {
               _loc3_.visible = false;
            }
            else
            {
               _loc4_ = int(_bitNums[_loc1_]);
               _loc3_.visible = true;
               _loc3_.gotoAndStop(_numMcStartFrame + _loc4_);
               _loc1_++;
            }
            _loc2_++;
         }
      }
   }
}

