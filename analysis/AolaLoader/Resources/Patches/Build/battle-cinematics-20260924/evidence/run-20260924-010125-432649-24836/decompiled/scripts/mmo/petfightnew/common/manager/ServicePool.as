package mmo.petfightnew.common.manager
{
   import flash.utils.Dictionary;
   import mmo.interfaces.ServiceContainer;
   
   public class ServicePool
   {
      
      private static var _instance:ServicePool;
      
      private var _serviceMap:Dictionary = new Dictionary();
      
      public function ServicePool()
      {
         super();
      }
      
      public static function get instance() : ServicePool
      {
         if(_instance == null)
         {
            _instance = new ServicePool();
         }
         return _instance;
      }
      
      public function getService(param1:*) : *
      {
         if(this._serviceMap[param1] == null)
         {
            this._serviceMap[param1] = ServiceContainer.getService(param1);
         }
         return this._serviceMap[param1];
      }
      
      public function dispose() : void
      {
         var _loc1_:* = undefined;
         if(this._serviceMap != null)
         {
            for(_loc1_ in this._serviceMap)
            {
               delete this._serviceMap[_loc1_];
            }
         }
         this._serviceMap = null;
         _instance = null;
      }
   }
}

