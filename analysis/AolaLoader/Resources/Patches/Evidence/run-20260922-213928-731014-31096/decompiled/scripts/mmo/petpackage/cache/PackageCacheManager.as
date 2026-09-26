package mmo.petpackage.cache
{
   import mmo.interfaces.IDispose;
   import mmo.play.util.bitmapmovie.SyncBitmapMovieClip;
   
   public class PackageCacheManager implements IDispose
   {
      
      private static var _instance:PackageCacheManager;
      
      private var _cache:Object = {};
      
      public function PackageCacheManager()
      {
         super();
      }
      
      public static function get instance() : PackageCacheManager
      {
         if(_instance == null)
         {
            _instance = new PackageCacheManager();
         }
         return _instance;
      }
      
      public function hasCache(param1:int) : SyncBitmapMovieClip
      {
         if(this._cache[param1] == null)
         {
            return null;
         }
         return this._cache[param1] as SyncBitmapMovieClip;
      }
      
      public function cache(param1:int, param2:SyncBitmapMovieClip) : void
      {
         this._cache[param1] = param2;
      }
      
      public function dispose() : void
      {
         var _loc1_:IDispose = null;
         for each(_loc1_ in this._cache)
         {
            _loc1_.dispose();
         }
         _instance = null;
         this._cache = null;
      }
   }
}

