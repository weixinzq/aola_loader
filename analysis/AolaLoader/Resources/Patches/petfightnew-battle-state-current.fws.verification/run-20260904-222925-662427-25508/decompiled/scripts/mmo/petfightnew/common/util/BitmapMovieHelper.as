package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import mmo.play.util.bitmapmovie.SyncBitmapMovieClip;
   
   public class BitmapMovieHelper
   {
      
      public function BitmapMovieHelper()
      {
         super();
      }
      
      public static function toSyncBitmapMovie(param1:MovieClip) : SyncBitmapMovieClip
      {
         return new SyncBitmapMovieClip(param1);
      }
   }
}

