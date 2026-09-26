package mmo.petfightnew.common.effectmc
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.loader.LoaderContainer;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.FightFrameRateManager;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class McEffectBase extends Sprite implements IDispose
   {
      
      private var _gameOptionSvr:IGameOptionService;
      
      protected var onEnd:Function;
      
      protected var raceId:int;
      
      protected var locaId:int;
      
      protected var mcPet:MovieClip;
      
      public var mcEffect:MovieClip;
      
      protected var startFrame:int;
      
      public function McEffectBase(param1:int, param2:int, param3:MovieClip, param4:Function)
      {
         var raceId:int = param1;
         var locaId:int = param2;
         var mcPet:MovieClip = param3;
         var onEnd:Function = param4;
         this._gameOptionSvr = ServicePool.instance.getService(IGameOptionService);
         super();
         this.raceId = raceId;
         this.locaId = locaId;
         this.mcPet = mcPet;
         this.onEnd = onEnd;
         try
         {
            this.initEffectMc();
         }
         catch(e:Error)
         {
            onPlayEnd();
         }
         this.x = 0;
         this.y = 0;
      }
      
      public function dispose() : void
      {
         FightMovieManager.instance.removeMovie(this.mcEffect);
         DisplayUtil.stopAndRemove(this);
      }
      
      public function play() : void
      {
         var _loc1_:int = FightFrameRateManager.instance.defaultFrameRate;
         if(Boolean(this._gameOptionSvr.isSpeedUpFight) || !FightData.instance.isPVE)
         {
            LoaderContainer.instance.stage.frameRate = _loc1_ * 2;
         }
         FightMovieManager.instance.addMovie(this.mcEffect);
         this.mcEffect.addFrameScript(this.startFrame,this.setPetMc,this.mcEffect.totalFrames - 1,this.onPlayEnd);
         this.mcEffect.gotoAndPlay(1);
         this.addChild(this.mcEffect);
      }
      
      protected function setPetMc() : void
      {
      }
      
      protected function initEffectMc() : void
      {
      }
      
      protected function onPlayEnd() : void
      {
         FightFrameRateManager.instance.correctFrameRate();
         if(this.onEnd != null)
         {
            this.onEnd.apply(this,[this.locaId]);
         }
         this.dispose();
      }
   }
}

