package mmo.petfightnew.common.manager
{
   import flash.display.MovieClip;
   import flash.utils.getQualifiedClassName;
   
   public class FightMovieManager
   {
      
      private static var _instance:FightMovieManager = null;
      
      private var _log:Object = {};
      
      private var _movieList:Array = [];
      
      public function FightMovieManager()
      {
         super();
      }
      
      public static function get instance() : FightMovieManager
      {
         return _instance = _instance || new FightMovieManager();
      }
      
      public function removeMovie(param1:MovieClip) : void
      {
         if(param1 == null)
         {
            return;
         }
         var _loc2_:int = int(this._movieList.indexOf(param1));
         if(_loc2_ >= 0)
         {
            this._movieList.splice(_loc2_,1);
         }
         else if(!param1.parent)
         {
         }
      }
      
      public function addMovie(param1:MovieClip) : void
      {
         if(param1 == null)
         {
            return;
         }
         var _loc2_:String = getQualifiedClassName(param1);
         if(this._log[_loc2_] != null)
         {
            ++this._log[_loc2_];
         }
         else
         {
            this._log[_loc2_] = 1;
         }
         if(this._movieList.indexOf(param1) == -1)
         {
            this._movieList.push(param1);
         }
      }
      
      public function pause() : void
      {
         var _loc1_:MovieClip = null;
         for each(_loc1_ in this._movieList)
         {
            _loc1_.stop();
         }
      }
      
      public function play() : void
      {
         var _loc1_:MovieClip = null;
         for each(_loc1_ in this._movieList)
         {
            _loc1_.play();
         }
      }
      
      private function clearFrameScript(param1:MovieClip) : void
      {
         if(param1 == null || param1.totalFrames <= 0)
         {
            return;
         }
         var _loc2_:int = 0;
         while(_loc2_ <= param1.totalFrames)
         {
            param1.addFrameScript(_loc2_,null);
            _loc2_++;
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:MovieClip = null;
         var _loc2_:String = null;
         for each(_loc1_ in this._movieList)
         {
            if(_loc1_ != null)
            {
               this.clearFrameScript(_loc1_);
               _loc1_.stop();
               if(_loc1_.parent != null)
               {
                  _loc1_.parent.removeChild(_loc1_);
               }
            }
         }
         this._movieList = [];
         for(_loc2_ in this._log)
         {
         }
         this._log = null;
         _instance = null;
      }
   }
}

