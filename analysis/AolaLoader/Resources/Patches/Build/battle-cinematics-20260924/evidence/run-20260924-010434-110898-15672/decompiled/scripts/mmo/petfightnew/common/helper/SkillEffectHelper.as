package mmo.petfightnew.common.helper
{
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.common.bitmapmovie.BitmapMovieClip;
   import mmo.common.bitmapmovie.BitmapMovieClipParser;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.PreloadListManager;
   import mmo.play.petfight.common.config.FightResConfig;
   import mmo.play.petfight.common.config.SkillMap;
   
   public class SkillEffectHelper
   {
      
      public function SkillEffectHelper()
      {
         super();
      }
      
      public static function getCacheKey(param1:int) : String
      {
         return "SkillEffect" + param1;
      }
      
      public static function getBitmapMovie(param1:int) : BitmapMovieClip
      {
         var _loc4_:String = null;
         var _loc2_:String = getCacheKey(param1);
         var _loc3_:BitmapMovieClip = FightMcPool.instance.getRes(_loc2_,false);
         if(_loc3_ == null)
         {
            _loc4_ = FightResConfig.getBitmapEffectMovieClsName(param1);
            _loc3_ = BitmapMovieClipParser.getBitmapMovieClip(_loc4_,FightData.instance.applicationDomain,false);
            if(_loc3_ == null)
            {
               PreloadListManager.instance.preloadEffect(param1);
            }
         }
         return _loc3_;
      }
      
      public static function recycleEffect(param1:MovieClip, param2:int) : void
      {
         if(!SkillMap.instance.isBitmapSkillEffect(param2))
         {
            DisplayUtil.stopAndRemove(param1);
            return;
         }
         var _loc3_:String = getCacheKey(param2);
         FightMcPool.instance.recycle(param1,_loc3_);
      }
   }
}

