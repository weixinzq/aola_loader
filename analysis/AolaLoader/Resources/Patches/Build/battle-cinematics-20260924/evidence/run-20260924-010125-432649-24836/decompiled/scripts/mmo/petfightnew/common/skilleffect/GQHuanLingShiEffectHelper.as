package mmo.petfightnew.common.skilleffect
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.util.PositionUtil;
   import mmo.petfightnew.common.util.StatusUtil;
   
   public class GQHuanLingShiEffectHelper
   {
      
      private static const FLA:String = "gqpet/huanlingshi/effect/huanlingshieffect_";
      
      private static const KEY_STAND:String = "stand";
      
      private static const CLS_APPEAR:String = "mmo.gqpet.huanlingshi.effect.GQHuanLingShiAppearEffect_";
      
      private static const CLS_STAND:String = "mmo.gqpet.huanlingshi.effect.GQHuanLingShiStandEffect_";
      
      private static const CLS_ATTACK:String = "mmo.gqpet.huanlingshi.effect.GQHuanLingShiAttackEffect_";
      
      private var _fladId:int;
      
      private var _pbi:PetBriefInfo;
      
      private var _localId:int;
      
      private var _face:int;
      
      public function GQHuanLingShiEffectHelper(param1:PetBriefInfo, param2:int, param3:Boolean)
      {
         super();
         this._pbi = param1;
         this._fladId = PetAssetsMap.getPetFlaId(this._pbi.raceId);
         this._localId = param2;
         this._face = param3 ? 1 : 0;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.AFTER_USE_SKILL,this.onAfterUseSkill);
      }
      
      public static function playAppearMv(param1:int, param2:Function) : void
      {
         var _loc3_:int = int(PetAssetsMap.getPetFlaId(param1));
         playAnimation(FLA + _loc3_,CLS_APPEAR + _loc3_,param2);
      }
      
      public static function playAttackMv(param1:int, param2:Boolean, param3:Function) : void
      {
         var _loc4_:int = int(PetAssetsMap.getPetFlaId(param1));
         var _loc5_:int = param2 ? 1 : 0;
         playAnimation(FLA + _loc4_,CLS_ATTACK + _loc4_ + "_" + _loc5_,param3);
      }
      
      private static function playAnimation(param1:String, param2:String, param3:Function = null) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function onAfterUseSkill(param1:PetFightEvent) : void
      {
         if(!this._pbi)
         {
            return;
         }
         this.addIconMc();
      }
      
      public function dispose() : void
      {
         var _loc3_:* = false;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.AFTER_USE_SKILL,this.onAfterUseSkill);
         var _loc1_:* = KEY_STAND + "_" + this._localId + "_" + "_gqHuanLingShiEffect";
         var _loc2_:Sprite = FightController.instance.fightPanel.layerPetDown;
         if(Boolean(_loc2_) && Boolean(_loc2_.parent))
         {
            _loc3_ = _loc2_.getChildByName(_loc1_) != null;
            if(_loc3_)
            {
               _loc2_.removeChild(_loc2_.getChildByName(_loc1_));
            }
         }
      }
      
      private function addIconMc() : void
      {
         var key:String = null;
         var layer:Sprite = null;
         key = KEY_STAND + "_" + this._localId + "_" + "_gqHuanLingShiEffect";
         layer = FightController.instance.fightPanel.layerPetDown;
         var hasView:Boolean = layer.getChildByName(key) != null;
         var isInHuanLingShiState:Boolean = StatusUtil.getIsHuanLingShiState(this._pbi);
         if(!isInHuanLingShiState)
         {
            if(hasView)
            {
               layer.removeChild(layer.getChildByName(key));
            }
            return;
         }
         if(hasView)
         {
            layer.getChildByName(key).visible = isInHuanLingShiState;
            return;
         }
         ResScheduler.getRes(ResParams.createTempByDomain(FLA + this._fladId,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            var _loc3_:* = PositionUtil.getDefaultPosition(_localId);
            param1.name = key;
            param1.mouseEnabled = param1.mouseChildren = false;
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),CLS_STAND + this._fladId + "_" + this._face,ResPriority.LOW));
      }
   }
}

