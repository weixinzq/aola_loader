package mmo.petfightnew.common.helper
{
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.play.activity.framework.util.CallbackUtil;
   
   public class PlayFightMovieHelper
   {
      
      public function PlayFightMovieHelper()
      {
         super();
      }
      
      public static function playMovie(param1:MovieClip, param2:Function, param3:String = null) : void
      {
         var movie:MovieClip = param1;
         var afterMovie:Function = param2;
         var key:String = param3;
         FightMovieManager.instance.addMovie(movie);
         movie.addFrameScript(movie.totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(movie);
            if(key != null)
            {
               FightMcPool.instance.recycle(movie,key);
            }
            else
            {
               DisplayUtil.stopAndRemove(movie);
            }
            CallbackUtil.apply(afterMovie);
         });
         movie.gotoAndPlay(1);
      }
   }
}

