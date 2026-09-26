package mmo.petfightnew.common.skilleffect
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
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
   
   public class GQYanhuaZhiyaoEffectHelper
   {
      
      private static const FLA:String = "gqpet/yanhuazhiyao/yanhuazhiyaoeffect";
      
      private static const KEY_STAND:String = "stand";
      
      private static const CLS_STAND:String = "mmo.gqpet.yanhuazhiyao.effect.GQYanhuaZhiyaoEffectMv";
      
      private var _iconMc:MovieClip;
      
      private var _raceId:int;
      
      private var _pbi:PetBriefInfo;
      
      private var _localId:int;
      
      private var _face:int;
      
      public function GQYanhuaZhiyaoEffectHelper(param1:PetBriefInfo, param2:int, param3:Boolean)
      {
         super();
         this._pbi = param1;
         this._raceId = this._pbi.raceId;
         this._localId = param2;
         this._face = param3 ? 1 : 0;
         this.addIconMc();
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
      }
      
      private function addIconMc() : void
      {
         var key:String = null;
         var layer:Sprite = null;
         key = KEY_STAND + "_" + this._localId + "_" + "_gqYanhuaZhiyaoEffect";
         layer = FightController.instance.fightPanel.layerPetUp;
         var hasView:Boolean = layer.getChildByName(key) != null;
         var isYanhuaZhiyaoEffect:Boolean = StatusUtil.getIsInLockByJueduiWeiduState(this._pbi) || StatusUtil.getIsInLiangziXinglianState(this._pbi);
         if(!isYanhuaZhiyaoEffect)
         {
            if(hasView)
            {
               layer.removeChild(layer.getChildByName(key));
            }
            return;
         }
         if(hasView)
         {
            layer.getChildByName(key).visible = isYanhuaZhiyaoEffect;
            return;
         }
         ResScheduler.getRes(ResParams.createTempByDomain(FLA,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            var _loc3_:* = PositionUtil.getDefaultPosition(_localId);
            param1.name = key;
            param1.mouseEnabled = param1.mouseChildren = false;
            param1.x = _loc3_.x;
            param1.y = _loc3_.y;
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),CLS_STAND,ResPriority.LOW));
      }
      
      private function onNextTurn(param1:PetFightEvent) : void
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
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         var _loc1_:* = KEY_STAND + "_" + this._localId + "_" + "_gqYanhuaZhiyaoEffect";
         var _loc2_:Sprite = FightController.instance.fightPanel.layerPetUp;
         if(Boolean(_loc2_) && Boolean(_loc2_.parent))
         {
            _loc3_ = _loc2_.getChildByName(_loc1_) != null;
            if(_loc3_)
            {
               _loc2_.removeChild(_loc2_.getChildByName(_loc1_));
            }
         }
      }
   }
}

