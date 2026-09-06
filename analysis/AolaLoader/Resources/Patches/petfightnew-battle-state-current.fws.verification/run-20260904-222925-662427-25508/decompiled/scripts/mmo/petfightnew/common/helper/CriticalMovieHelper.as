package mmo.petfightnew.common.helper
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.common.bitmapmovie.BitmapMovieClipParser;
   import mmo.interfaces.pet.data.skin.IPetSkinDataService;
   import mmo.interfaces.pet.data.skin.PetSkinInfo;
   import mmo.loader.LoaderContainer;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.config.FightCriEffectConfig;
   import mmo.petfightnew.common.manager.FightFrameRateManager;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.pet.PetFace;
   import mmo.play.petfight.common.config.FightResConfig;
   
   public class CriticalMovieHelper
   {
      
      public function CriticalMovieHelper()
      {
         super();
      }
      
      public static function showCriEffMovie(param1:int, param2:Boolean, param3:int, param4:MCPetContainer, param5:Function) : void
      {
         var raceId:int = param1;
         var isFace:Boolean = param2;
         var fladId:int = param3;
         var mcPetContainer:MCPetContainer = param4;
         var afterMovie:Function = param5;
         var petSkinDataSvr:IPetSkinDataService = ServicePool.instance.getService(IPetSkinDataService);
         var isChaoWei:Boolean = FightCriEffectConfig.isChaoWei(raceId);
         var faceId:int = PetFace.getFaceId(isFace);
         var petSkinInfo:PetSkinInfo = petSkinDataSvr.getPetSkinInfoBySkinId(fladId);
         var onMovieEnd:Function = function():*
         {
            DisplayUtil.clearFilters(FightController.instance.fightPanel.layerBackground);
            var _loc1_:int = FightFrameRateManager.instance.defaultFrameRate;
            LoaderContainer.instance.stage.frameRate = _loc1_ * 2;
            afterMovie.apply();
         };
         DisplayUtil.setBrightHalf(FightController.instance.fightPanel.layerBackground);
         if(isChaoWei)
         {
            playChaoWeiMovie(raceId,faceId,onMovieEnd);
         }
         else
         {
            playNormalMovie(mcPetContainer,faceId,onMovieEnd);
         }
      }
      
      private static function playChaoWeiMovie(param1:int, param2:int, param3:Function) : void
      {
         var movieContainer:Sprite = null;
         var raceId:int = param1;
         var faceId:int = param2;
         var afterMovie:Function = param3;
         movieContainer = FightController.instance.fightPanel.layerEffect;
         var url:String = "pet/criticalhiteffect/crieffect_chaowei";
         var cls:String = "mmo.petfightnew.CriEffect_chaowei_" + faceId;
         ResScheduler.getRes(ResParams.createTempByDomain(url,function(param1:MovieClip, param2:ApplicationDomain = null):void
         {
            var maxFlaId:* = undefined;
            var durl:* = undefined;
            var dcls:* = undefined;
            var movie:MovieClip = param1;
            var domain:ApplicationDomain = param2;
            if(!FightData.instance.isLowQuality)
            {
               maxFlaId = raceId % 10000;
               durl = "pet/degeneratorsuperpomovie/degeneratorpet" + maxFlaId;
               dcls = "mmo.petfightnew.DegeneratorSuperPoMovie" + maxFlaId + "_" + faceId;
               ResScheduler.getRes(ResParams.createTempByDomain(durl,function(param1:MovieClip, param2:ApplicationDomain = null):void
               {
                  movie.container.addChild(param1);
                  movieContainer.addChild(movie);
                  PlayFightMovieHelper.playMovie(movie,afterMovie);
               },ResDomain.decorate(FightData.instance.applicationDomain),dcls));
            }
            else
            {
               movieContainer.addChild(movie);
               PlayFightMovieHelper.playMovie(movie,afterMovie);
            }
         },ResDomain.decorate(FightData.instance.applicationDomain),cls));
      }
      
      private static function playNormalMovie(param1:Sprite, param2:int, param3:Function) : void
      {
         var _loc4_:String = FightResConfig.getCriticalNormalMovieClsName(param2);
         var _loc5_:MovieClip = FightMcPool.instance.getMcByKey(_loc4_) || BitmapMovieClipParser.getBitmapMovieClip(_loc4_,FightData.instance.applicationDomain,false);
         if(_loc5_ == null)
         {
            param3.apply();
            return;
         }
         playMovie(param1,_loc5_,param3,_loc4_);
      }
      
      private static function playMovie(param1:Sprite, param2:MovieClip, param3:Function, param4:String = null) : void
      {
         param1.addChild(param2);
         param2.scaleX = FightData.instance.getPetVisionScale();
         param2.scaleY = FightData.instance.getPetVisionScale();
         PlayFightMovieHelper.playMovie(param2,param3,param4);
      }
   }
}

