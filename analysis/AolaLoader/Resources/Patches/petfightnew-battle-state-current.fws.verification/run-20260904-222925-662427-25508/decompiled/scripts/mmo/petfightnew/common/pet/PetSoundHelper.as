package mmo.petfightnew.common.pet
{
   import mmo.interfaces.pet.data.skin.IPetSkinDataService;
   import mmo.interfaces.pet.data.skin.PetSkinInfo;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.play.petfight.common.config.FightResConfig;
   
   public class PetSoundHelper
   {
      
      private static var petSkinDataSvr:IPetSkinDataService;
      
      public function PetSoundHelper()
      {
         super();
      }
      
      private static function haveFightMusic(param1:int) : Boolean
      {
         if(petSkinDataSvr == null)
         {
            petSkinDataSvr = ServicePool.instance.getService(IPetSkinDataService);
         }
         var _loc2_:PetSkinInfo = petSkinDataSvr.getPetSkinInfoBySkinId(param1);
         return Boolean(_loc2_) && Boolean(_loc2_.isFightMusic);
      }
      
      public static function tryPreLoadPetSound(param1:int) : void
      {
         if(!haveFightMusic(param1))
         {
            return;
         }
         preLoadPetSound(param1);
      }
      
      private static function preLoadPetSound(param1:int) : void
      {
         var viewId:int = param1;
         var url:String = FightResConfig.getPetBigSkillSoundFileURL(viewId);
         ResScheduler.getRes(ResParams.create(url,null,new ResDomain(FightData.instance.applicationDomain),ResPriority.PRELOAD,null,function():*
         {
         }));
      }
   }
}

