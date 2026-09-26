package mmo.petfightnew.common.manager
{
   import flash.display.BitmapData;
   import flash.utils.Dictionary;
   import mmo.interfaces.IDispose;
   
   public class FightBitmapDataCache implements IDispose
   {
      
      private static var _instance:FightBitmapDataCache;
      
      private var _cachePool:Dictionary = new Dictionary();
      
      public function FightBitmapDataCache()
      {
         super();
      }
      
      public static function get instance() : FightBitmapDataCache
      {
         if(_instance == null)
         {
            _instance = new FightBitmapDataCache();
         }
         return _instance;
      }
      
      public function getData(param1:String) : BitmapData
      {
         return this._cachePool[param1];
      }
      
      public function cache(param1:String, param2:BitmapData) : void
      {
         if(this._cachePool[param1] == null)
         {
            this._cachePool[param1] = param2;
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:* = undefined;
         for(_loc1_ in this._cachePool)
         {
            if(this._cachePool[_loc1_] != null)
            {
               (this._cachePool[_loc1_] as BitmapData).dispose();
            }
            this._cachePool[_loc1_] = null;
         }
         this._cachePool = null;
         _instance = null;
      }
   }
}

