package mmo.petfightnew.common.fightcontroller
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.FightMovieManager;
   
   public class AoYiMovieHelper
   {
      
      private var _isDisposed:Boolean = false;
      
      public function AoYiMovieHelper()
      {
         super();
      }
      
      public static function preLoadBaseMovie() : void
      {
         ResScheduler.getRes(ResParams.createTempByDomain("pet/aoyitakeeffectmovie/aoyitakeeffectmoviebase",function(param1:MovieClip, param2:ApplicationDomain):void
         {
         },ResDomain.decorate(FightData.instance.applicationDomain),"",ResPriority.LOW));
      }
      
      public function playAoYiTakeEffectMovie(param1:int, param2:Function) : void
      {
         var raceId:int = param1;
         var callBack:Function = param2;
         if(FightData.instance.isLowQuality)
         {
            if(callBack != null)
            {
               callBack.apply();
            }
            return;
         }
         ResScheduler.getRes(ResParams.createTempByDomain("pet/aoyitakeeffectmovie/aoyitakeeffectmoviebase",function(param1:MovieClip, param2:ApplicationDomain):void
         {
            onGetBaseRes(param1,raceId,callBack);
         },ResDomain.decorate(FightData.instance.applicationDomain),"mmo.petfightnew.TakeEffectMovieBase"));
      }
      
      private function onGetBaseRes(param1:MovieClip, param2:int, param3:Function) : void
      {
         var onGetRes:Function;
         var baseMovie:MovieClip = param1;
         var raceId:int = param2;
         var callBack:Function = param3;
         if(this._isDisposed)
         {
            return;
         }
         raceId %= 10000;
         onGetRes = function(param1:Sprite, param2:ApplicationDomain = null):void
         {
            var sp:Sprite = param1;
            var domain:ApplicationDomain = param2;
            if(_isDisposed)
            {
               return;
            }
            baseMovie.mc.addChild(sp);
            FightMovieManager.instance.addMovie(baseMovie);
            baseMovie.addFrameScript(baseMovie.totalFrames - 1,function():void
            {
               FightMovieManager.instance.removeMovie(baseMovie);
               baseMovie.stop();
               ModalDialogManager.getInstance().removeModalDialog(baseMovie);
               callBack.apply();
            });
            ModalDialogManager.getInstance().addModalDialogWithChangLayer(baseMovie,AlignType.NONE);
            baseMovie.gotoAndPlay(1);
         };
         ResScheduler.getRes(ResParams.createTempByDomain("pet/aoyitakeeffectmovie/aoyitakeeffectmovie" + raceId.toString(),onGetRes,ResDomain.decorate(FightData.instance.applicationDomain),"mmo.petfightnew.TakeEffectMovie" + raceId.toString(),ResPriority.NORMAL,function():void
         {
            callBack.apply();
         }));
      }
      
      public function dispose() : void
      {
         this._isDisposed = true;
      }
   }
}

