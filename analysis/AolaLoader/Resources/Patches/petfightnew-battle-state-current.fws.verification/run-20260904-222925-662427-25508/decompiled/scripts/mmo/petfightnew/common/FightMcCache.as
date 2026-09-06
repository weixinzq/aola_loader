package mmo.petfightnew.common
{
   import flash.display.MovieClip;
   import mmo.config.ConfigReader;
   
   public class FightMcCache
   {
      
      private static var _instance:FightMcCache;
      
      private static var effects:Object = {};
      
      private static var cacheEffNum:int = 0;
      
      private var _stateMoviePool:Object = {};
      
      public function FightMcCache()
      {
         super();
      }
      
      public static function get instance() : FightMcCache
      {
         if(_instance == null)
         {
            _instance = new FightMcCache();
         }
         return _instance;
      }
      
      public function cacheStateMovie(param1:String, param2:MovieClip) : void
      {
         this._stateMoviePool[param1] = param2;
      }
      
      public function getStateMovie(param1:String) : MovieClip
      {
         var _loc2_:MovieClip = null;
         if(this._stateMoviePool.hasOwnProperty(param1))
         {
            _loc2_ = this._stateMoviePool[param1];
            _loc2_.scaleX = _loc2_.scaleY = 1;
         }
         return _loc2_;
      }
      
      public function getCachedEffect(param1:int) : MovieClip
      {
         var _loc2_:Object = effects[param1];
         if(_loc2_ != null)
         {
            if(MovieClip(_loc2_.eff).scaleX == -1)
            {
               MovieClip(_loc2_.eff).scaleX = 1;
            }
            return _loc2_.eff;
         }
         return null;
      }
      
      public function putCachedEffect(param1:int, param2:MovieClip) : void
      {
         if(cacheEffNum >= ConfigReader.instance.cacheEffectNum)
         {
            this.shiftEffect();
            --cacheEffNum;
         }
         var _loc3_:Object = {
            "eff":param2,
            "scaleX":param2.scaleX
         };
         effects[param1] = _loc3_;
         ++cacheEffNum;
      }
      
      private function disposeOneMovie(param1:MovieClip) : void
      {
         var _loc2_:int = 0;
         if(param1 == null)
         {
            return;
         }
         param1.stop();
         if(param1.parent != null)
         {
            param1.parent.removeChild(param1);
         }
         if(param1.totalFrames > 0)
         {
            _loc2_ = 0;
            while(_loc2_ <= param1.totalFrames)
            {
               param1.addFrameScript(_loc2_,null);
               _loc2_++;
            }
         }
      }
      
      private function shiftEffect() : void
      {
         var _loc2_:* = undefined;
         var _loc3_:Object = null;
         var _loc1_:int = 0;
         for(_loc2_ in effects)
         {
            if(_loc1_ >= 1)
            {
               return;
            }
            _loc3_ = effects[_loc2_];
            if(_loc3_ != null && Boolean(_loc3_.hasOwnProperty("eff")))
            {
               this.disposeOneMovie(_loc3_.eff as MovieClip);
            }
            effects[_loc2_] = null;
            _loc1_++;
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:* = undefined;
         var _loc2_:* = undefined;
         var _loc3_:Object = null;
         for(_loc1_ in effects)
         {
            _loc3_ = effects[_loc1_];
            if(_loc3_ != null && Boolean(_loc3_.hasOwnProperty("eff")))
            {
               this.disposeOneMovie(_loc3_.eff as MovieClip);
            }
            effects[_loc1_] = null;
         }
         effects = {};
         for(_loc2_ in this._stateMoviePool)
         {
            this.disposeOneMovie(this._stateMoviePool[_loc2_] as MovieClip);
            this._stateMoviePool[_loc2_] = null;
         }
         this._stateMoviePool = {};
         cacheEffNum = 0;
         _instance = null;
      }
   }
}

