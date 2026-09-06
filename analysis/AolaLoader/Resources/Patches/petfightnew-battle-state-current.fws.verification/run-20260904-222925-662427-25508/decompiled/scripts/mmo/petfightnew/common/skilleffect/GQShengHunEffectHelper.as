package mmo.petfightnew.common.skilleffect
{
   import flash.display.MovieClip;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.PositionUtil;
   import mmo.play.activity.framework.util.CallbackUtil;
   
   public class GQShengHunEffectHelper
   {
      
      private static const URL:String = "gqpet/shenghun/effect/shenghuneffect_";
      
      private static const AppearCls:String = "mmo.gqpet.shenghun.view.ShengHunAppearEffect_";
      
      private static const AttackCls:String = "mmo.gqpet.shenghun.view.ShengHunAttackEffect_";
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _raceId:int;
      
      private var _pbi:PetBriefInfo;
      
      private var _localId:int;
      
      private var _maxFladId:int;
      
      private var _face:int;
      
      private var _callBack:Function;
      
      public function GQShengHunEffectHelper(param1:PetBriefInfo, param2:int, param3:Boolean)
      {
         super();
         this._pbi = param1;
         this._raceId = this._pbi.raceId;
         this._localId = param2;
         this._maxFladId = this._pmSvr.getOperationPM(this._raceId % 10000).getMaxCommonEvlution().raceId;
         this._face = param3 ? 1 : 0;
      }
      
      public function playAppearAndAttackMv(param1:Function) : void
      {
         this._callBack = param1;
         var _loc2_:String = "shenghun_" + this._pbi.id + "_" + this._localId;
         if(FightData.instance.extData.hasOwnProperty(_loc2_))
         {
            this.playAttackMv();
         }
         else
         {
            FightData.instance.extData[_loc2_] = true;
            this.playAnimation(URL + this._maxFladId,AppearCls + this._maxFladId,this.playAttackMv);
         }
      }
      
      private function playAttackMv() : void
      {
         var attackMv:MovieClip = null;
         var attackCls:Class = FightData.instance.applicationDomain.getDefinition(AttackCls + this._maxFladId + "_" + (this._face + 1)) as Class;
         attackMv = new attackCls() as MovieClip;
         var pos:Point = PositionUtil.getDefaultPosition(this._localId);
         attackMv.x = pos.x;
         attackMv.y = pos.y;
         attackMv.gotoAndPlay(1);
         FightController.instance.fightPanel.layerPetUp.addChild(attackMv);
         ProgressFullSprite.lockScreen();
         attackMv.addFrameScript(attackMv.totalFrames - 1,function():void
         {
            ProgressFullSprite.unlockScreen();
            if(Boolean(attackMv) && Boolean(attackMv.parent))
            {
               DisplayUtil.stopAndRemove(attackMv);
            }
            CallbackUtil.apply(_callBack);
         });
      }
      
      private function playAnimation(param1:String, param2:String, param3:Function = null) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      public function dispose() : void
      {
      }
   }
}

