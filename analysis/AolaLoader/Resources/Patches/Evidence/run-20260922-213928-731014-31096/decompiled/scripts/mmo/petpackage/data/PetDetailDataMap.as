package mmo.petpackage.data
{
   import mmo.framework.comm.PetClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   
   public class PetDetailDataMap implements IDispose
   {
      
      private static var _instance:PetDetailDataMap = null;
      
      private var map:Object = {};
      
      private var cachingMap:Object = {};
      
      private var petDataService:IPetDataService = null;
      
      private var _currentPetId:int;
      
      public function PetDetailDataMap()
      {
         super();
         this.petDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         this.petDataService.addEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onPMDetailUpdate,false,int.MAX_VALUE);
         this.petDataService.addEventListener(PetDataServiceEvent.RSPN_PM_REVEAL_HP,this.onRevealHp,false,int.MAX_VALUE);
      }
      
      public static function get instance() : PetDetailDataMap
      {
         if(null == _instance)
         {
            _instance = new PetDetailDataMap();
         }
         return _instance;
      }
      
      public function isCurrentPet(param1:int) : Boolean
      {
         return this.isCurrent(param1);
      }
      
      public function saveCurrentPet(param1:int) : void
      {
         this._currentPetId = param1;
      }
      
      public function getPetDetailInfo(param1:int) : PetDetailedInfo
      {
         var _loc3_:PetDetailedInfo = null;
         var _loc2_:* = this.map[param1];
         if(null != _loc2_)
         {
            _loc3_ = new PetDetailedInfo();
            _loc3_.parseInfo(_loc2_);
            return _loc3_;
         }
         return null;
      }
      
      public function getPetInfo(param1:int) : Object
      {
         return this.map[param1];
      }
      
      public function checkCaching(param1:int) : Boolean
      {
         return this.isCaching(param1);
      }
      
      public function checkCache(param1:int) : Boolean
      {
         return this.hasCache(param1);
      }
      
      public function cleanAllCache() : void
      {
         this.map = {};
         this.cachingMap = {};
      }
      
      public function cleanCacheByPetId(param1:int) : void
      {
         delete this.map[param1];
         this.cleanCaching(param1);
      }
      
      public function tryUpdateCachhe(param1:int, param2:Boolean = false) : void
      {
         if(param2 || !this.hasCache(param1))
         {
            this.updateCaching(param1);
            PetClient.instance.viewSinglePM(param1);
         }
         else if(this.hasCache(param1))
         {
            this.tryDispatcherCurrentDetailedCachedEvent(param1);
         }
      }
      
      private function isCurrent(param1:int) : Boolean
      {
         return param1 == this._currentPetId;
      }
      
      private function isCaching(param1:int) : Boolean
      {
         return this.cachingMap.hasOwnProperty("" + param1);
      }
      
      private function updateCaching(param1:int) : void
      {
         this.cachingMap[param1] = null;
      }
      
      private function cleanCaching(param1:int) : void
      {
         delete this.cachingMap[param1];
      }
      
      private function hasCache(param1:int) : Boolean
      {
         return this.map.hasOwnProperty("" + param1);
      }
      
      private function cleanCache(param1:int) : void
      {
         delete this.map[param1];
      }
      
      private function onPMDetailUpdate(param1:PetDataServiceEvent) : void
      {
         var _loc2_:Object = param1.params.pm;
         var _loc3_:int = int(_loc2_.pmPView.i);
         this.updateCache(_loc3_,_loc2_);
      }
      
      private function updateCache(param1:int, param2:Object) : void
      {
         this.map[param1] = param2;
         this.tryDispatcherCurrentDetailedCachedEvent(param1);
      }
      
      private function tryDispatcherCurrentDetailedCachedEvent(param1:int) : void
      {
         if(this.isCurrent(param1))
         {
            PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_DETAIL_UPDATE,{
               "id":param1,
               "pm":this.map[param1]
            }));
         }
      }
      
      private function onRevealHp(param1:PetDataServiceEvent) : void
      {
         var _loc2_:String = null;
         var _loc3_:Array = null;
         if(param1.params.res)
         {
            _loc2_ = param1.params.pi;
            if(_loc2_.length == 0)
            {
               return;
            }
            _loc3_ = _loc2_.split("#");
            if(_loc3_.length > 1)
            {
               PetClient.instance.viewAllPM();
            }
            else if(1 == _loc3_.length)
            {
               PetClient.instance.viewSinglePM(_loc3_[0]);
            }
         }
      }
      
      public function dispose() : void
      {
         this.disposeEvent();
         _instance = null;
      }
      
      private function disposeEvent() : void
      {
         this.petDataService.removeEventListener(PetDataServiceEvent.RSPN_PM_REVEAL_HP,this.onRevealHp);
         this.petDataService.removeEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onPMDetailUpdate,false);
      }
   }
}

