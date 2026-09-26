package mmo.petfightnew.common.pet
{
   import flash.events.EventDispatcher;
   import mmo.loader.LoaderContainer;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.AssetsLoaderEvent;
   import mmo.petfightnew.common.FightData;
   import mmo.play.petfight.common.config.FightResConfig;
   
   public class PetAssetsLoader extends EventDispatcher
   {
      
      private var _viewId:int = -1;
      
      private var _faceId:int;
      
      public function PetAssetsLoader(param1:int, param2:int)
      {
         super();
         this._viewId = param1;
         this._faceId = param2;
      }
      
      public function preLoadPetFile() : void
      {
         var path:String = this.getResPath(this._viewId);
         ResScheduler.getResource(path,function():void
         {
         },"",function():void
         {
         },null,ResPriority.HIGHEST,false,FightData.instance.getPetViewDomain().applicationDomain);
         PetSoundHelper.tryPreLoadPetSound(this._viewId);
      }
      
      private function getResPath(param1:int) : String
      {
         var _loc2_:int = FightData.instance.getPetMovieStrategyType(param1);
         return FightResConfig.getPetMainFilePath(_loc2_,param1,this._faceId);
      }
      
      public function loadPetFile() : void
      {
         this.startLoad(this._viewId,this.loadDefaultPetFile);
      }
      
      private function loadDefaultPetFile() : void
      {
         this.startLoad(FightResConfig.DEFAULT_PET_ID);
      }
      
      private function startLoad(param1:int, param2:Function = null) : void
      {
         var viewId:int = param1;
         var onLoadError:Function = param2;
         var path:String = this.getResPath(viewId);
         ResScheduler.getResource(path,this.onLoadPetCompleted,"",function(param1:*):*
         {
            if(onLoadError != null)
            {
               LoaderContainer.instance.appendLog("[ERROR]加载亚比{" + viewId + "}的形象失败,只能使用默认形象了.");
               onLoadError.apply();
            }
         },null,ResPriority.HIGHEST,false,FightData.instance.getPetViewDomain().applicationDomain);
      }
      
      private function onLoadPetCompleted(param1:*) : void
      {
         this.dispatchEvent(new AssetsLoaderEvent(AssetsLoaderEvent.LOAD_DONE,{"petId":this._viewId}));
      }
   }
}

