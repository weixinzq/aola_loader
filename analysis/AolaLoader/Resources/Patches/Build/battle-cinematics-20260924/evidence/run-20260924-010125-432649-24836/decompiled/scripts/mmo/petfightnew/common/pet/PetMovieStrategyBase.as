package mmo.petfightnew.common.pet
{
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.petfightnew.common.AssetsLoaderEvent;
   import mmo.petfightnew.common.FightData;
   
   public class PetMovieStrategyBase
   {
      
      private static const TEST_RACE_IDS:Array = [3,2315,3800,3885,4024,4035];
      
      protected var _raceId:int;
      
      protected var _face:int;
      
      protected var _useDefault:Boolean = false;
      
      protected var _movieCache:Object = {};
      
      protected var _assetsLoader:PetAssetsLoader;
      
      protected var _onResPrepared:Function;
      
      protected var _disposed:Boolean;
      
      public function PetMovieStrategyBase(param1:int, param2:int)
      {
         super();
         this._raceId = param1;
         this._face = param2;
      }
      
      public function prepareRes(param1:Function) : void
      {
         this._onResPrepared = param1;
         var _loc2_:String = this.getTargetPetClsName();
         if(this.haveDefinitionInFightDomain(_loc2_))
         {
            this.tryCallResPrepared();
         }
         else
         {
            this._assetsLoader = new PetAssetsLoader(this._raceId,this._face);
            this._assetsLoader.addEventListener(AssetsLoaderEvent.LOAD_DONE,this.onResLoadDoneListener);
            this._assetsLoader.loadPetFile();
         }
      }
      
      protected function getTargetPetClsName() : String
      {
         return "";
      }
      
      private function onResLoadDoneListener(param1:AssetsLoaderEvent) : void
      {
         this._assetsLoader.removeEventListener(AssetsLoaderEvent.LOAD_DONE,this.onResLoadDoneListener);
         this.tryCallResPrepared();
      }
      
      private function tryCallResPrepared() : void
      {
         if(!this._disposed)
         {
            this.onResPrepared();
         }
      }
      
      protected function onResPrepared() : void
      {
         if(this._onResPrepared != null)
         {
            this._onResPrepared.apply();
         }
      }
      
      public function getActionMovie(param1:int) : MovieClip
      {
         return null;
      }
      
      protected function cacheMovie(param1:int, param2:MovieClip) : void
      {
         this._movieCache[param1] = param2;
      }
      
      protected function getMovieCache(param1:int) : MovieClip
      {
         return this._movieCache[param1];
      }
      
      public function dispose() : void
      {
         var _loc1_:* = undefined;
         var _loc2_:MovieClip = null;
         this._disposed = true;
         for(_loc1_ in this._movieCache)
         {
            _loc2_ = this._movieCache[_loc1_];
            DisplayUtil.stopAndRemove(_loc2_);
         }
         this._movieCache = null;
      }
      
      protected function haveDefinitionInFightDomain(param1:String) : Boolean
      {
         return FightData.instance.getPetViewDomain().applicationDomain.hasDefinition(param1);
      }
      
      protected function getPetMovie(param1:String) : MovieClip
      {
         var _loc2_:Class = FightData.instance.getPetViewDomain().applicationDomain.getDefinition(param1) as Class;
         return new _loc2_();
      }
   }
}

