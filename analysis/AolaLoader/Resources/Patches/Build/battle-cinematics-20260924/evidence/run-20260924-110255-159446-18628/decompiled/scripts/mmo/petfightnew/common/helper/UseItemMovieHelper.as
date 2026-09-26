package mmo.petfightnew.common.helper
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.bitmapmovie.BitmapMovieClip;
   import mmo.common.bitmapmovie.BitmapMovieClipParser;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.play.activity.framework.util.CallbackUtil;
   import mmo.play.petfight.common.config.FightResConfig;
   
   public class UseItemMovieHelper
   {
      
      private static const REVERT_PP_ITEM_IDS:Array = [31,103,104];
      
      public function UseItemMovieHelper()
      {
         super();
      }
      
      private static function isRevertPPItem(param1:int) : Boolean
      {
         return REVERT_PP_ITEM_IDS.indexOf(param1) >= 0;
      }
      
      private static function getRevertMovie(param1:String, param2:Function) : void
      {
         var movie:BitmapMovieClip = null;
         var url:String = null;
         var key:String = param1;
         var callBack:Function = param2;
         movie = FightMcPool.instance.getRes(key,false);
         if(movie == null)
         {
            url = key == FightResConfig.REVERT_PP_MOVIE_CLSNAME ? "pet/fightasyncres/revertppmovie/movie" : "pet/fightasyncres/reverthpmovie/movie";
            ResScheduler.getRes(ResParams.create(url,function():void
            {
               movie = BitmapMovieClipParser.getBitmapMovieClip(key,FightData.instance.applicationDomain,false);
               CallbackUtil.apply(callBack,[movie]);
            },new ResDomain(FightData.instance.applicationDomain)));
         }
         else
         {
            CallbackUtil.apply(callBack,[movie]);
         }
      }
      
      public static function showMcUseItem(param1:Sprite, param2:int, param3:Number, param4:Number, param5:Function) : void
      {
         var movie:MovieClip = null;
         var key:String = null;
         var container:Sprite = param1;
         var itemId:int = param2;
         var posX:Number = param3;
         var posY:Number = param4;
         var onMovieEnd:Function = param5;
         if(isRevertPPItem(itemId))
         {
            key = FightResConfig.REVERT_PP_MOVIE_CLSNAME;
         }
         else
         {
            key = FightResConfig.REVERT_HP_MOVIE_CLSNAME;
         }
         getRevertMovie(key,function(param1:BitmapMovieClip):void
         {
            var movie:BitmapMovieClip = param1;
            if(movie == null)
            {
               onMovieEnd.apply();
               return;
            }
            movie.x = posX;
            movie.y = posY;
            FightMovieManager.instance.addMovie(movie);
            movie.addFrameScript(movie.totalFrames - 1,function():*
            {
               FightMovieManager.instance.removeMovie(movie);
               FightMcPool.instance.recycle(movie,key);
               onMovieEnd.apply();
            });
            container.addChild(movie);
            movie.gotoAndPlay(1);
         });
      }
   }
}

