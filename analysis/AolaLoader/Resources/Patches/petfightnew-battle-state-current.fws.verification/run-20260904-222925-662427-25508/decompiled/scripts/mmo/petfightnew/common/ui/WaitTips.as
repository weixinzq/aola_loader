package mmo.petfightnew.common.ui
{
   import flash.display.MovieClip;
   import mmo.common.bitmapmovie.BitmapMovieClip;
   import mmo.common.bitmapmovie.BitmapMovieClipParser;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.component.CachedClip;
   import mmo.petfightnew.common.util.DisableUtil;
   import mmo.play.petfight.common.config.FightResConfig;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3579")]
   public class WaitTips extends MovieClip
   {
      
      public static const VS_SELECTING_PET:int = 1;
      
      public static const VS_SELECTING_SKILL:int = 2;
      
      public static const TEAMMATE_OPERATING:int = 3;
      
      public var mcBG:MovieClip;
      
      public var mcWord:MovieClip;
      
      private var _mcBG:MovieClip;
      
      private var _mcWord:CachedClip;
      
      public function WaitTips()
      {
         addFrameScript(0,this.frame1);
         super();
         DisableUtil.disableAll(this);
         this._mcBG = this.getChildByName("mcBG") as MovieClip;
         var _loc1_:MovieClip = this.getChildByName("mcWord") as MovieClip;
         this._mcWord = new CachedClip(_loc1_);
         this.insteadBG();
      }
      
      public function setTips(param1:int) : void
      {
         this._mcWord.gotoAndStop(param1);
         this.insteadBG();
      }
      
      private function insteadBG() : void
      {
         if(this._mcBG is BitmapMovieClip)
         {
            return;
         }
         var _loc1_:BitmapMovieClip = BitmapMovieClipParser.getBitmapMovieClip(FightResConfig.WAIT_BG_MOVIE_CLSNAME,FightData.instance.applicationDomain,false);
         if(_loc1_ == null)
         {
            return;
         }
         _loc1_.x = this._mcBG.x;
         _loc1_.y = this._mcBG.y;
         var _loc2_:int = this.getChildIndex(this._mcBG);
         this.addChildAt(_loc1_,_loc2_);
         this._mcBG.visible = false;
         _loc1_.play();
         this._mcBG = _loc1_;
      }
      
      public function dispose() : void
      {
         this._mcWord.dispose();
         this._mcWord = null;
         if(this._mcBG is BitmapMovieClip)
         {
            (this._mcBG as BitmapMovieClip).dispose();
         }
         this._mcBG = null;
      }
      
      internal function frame1() : *
      {
         stop();
      }
   }
}

