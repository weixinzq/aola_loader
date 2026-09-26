package mmo.petfightnew.common.effectmc
{
   import com.greensock.TweenMax;
   import com.greensock.data.TweenLiteVars;
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.fightflauntresource.IFightFlauntResourceService;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.FightTweenMaxManager;
   import mmo.play.activity.framework.util.CallbackUtil;
   
   public class McPetDie1 extends McEffectBase
   {
      
      private var _ffrSvr:IFightFlauntResourceService = ServiceContainer.getService(IFightFlauntResourceService);
      
      private var _dieResId:int;
      
      private var _container:MovieClip;
      
      private var _initCallBack:Function;
      
      public function McPetDie1(param1:int, param2:int, param3:MovieClip, param4:Function, param5:int, param6:MovieClip, param7:Function)
      {
         this._dieResId = param5;
         this._container = param6;
         this._initCallBack = param7;
         super(param1,param2,param3,param4);
      }
      
      override protected function initEffectMc() : void
      {
         var cls:Class;
         super.initEffectMc();
         this.startFrame = 50;
         if(this._dieResId != this._ffrSvr.getDefaultFightFlauntResArr()[1])
         {
            this._ffrSvr.getFightFlauntResourceMovie(this._dieResId,function(param1:MovieClip):void
            {
               mcEffect = param1;
               mcEffect.stop();
               initEndCall();
            });
            return;
         }
         cls = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.McPetDie1") as Class;
         this.mcEffect = new cls() as MovieClip;
         this.mcEffect.stop();
         CallbackUtil.apply(this.initEndCall);
      }
      
      private function initEndCall() : void
      {
         this._container.addChildAt(this,0);
         this.play();
         CallbackUtil.apply(this._initCallBack);
      }
      
      override protected function setPetMc() : void
      {
         super.setPetMc();
         this.shrink();
      }
      
      private function shrink() : void
      {
         var tweenMax:TweenMax = null;
         var tweenVar:TweenLiteVars = new TweenLiteVars();
         tweenMax = null;
         tweenVar.prop("scaleX",0.2);
         tweenVar.prop("scaleY",0.2);
         tweenVar.useFrames(true);
         tweenVar.onComplete(function():void
         {
            FightTweenMaxManager.instance.removeTweenMax(tweenMax);
            removePet();
         });
         tweenMax = new TweenMax(this.mcPet,12,tweenVar);
         FightTweenMaxManager.instance.addTweenMax(tweenMax);
      }
      
      private function removePet() : void
      {
         DisplayUtil.stopAndRemove(this.mcPet);
      }
   }
}

