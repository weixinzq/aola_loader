package mmo.petfightnew.common.skilleffect
{
   import flash.display.MovieClip;
   import flash.geom.Point;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.PositionUtil;
   
   public class GQGuangJinEffectHelper
   {
      
      private static const URL:String = "xinghuipet/annualfee22/effect/xinghuiannual22atall_1";
      
      private static const CLS:String = "mmo.xinghuipet.annualfee22.XingHuiAnnual22AtAllMv_1";
      
      private var _pmService:IPMService = ServicePool.instance.getService(IPMService) as IPMService;
      
      private var _iconMc:MovieClip;
      
      private var _localId:int;
      
      private var _raceId:int;
      
      private var _pbi:PetBriefInfo;
      
      private var _face:int;
      
      public function GQGuangJinEffectHelper(param1:PetBriefInfo, param2:int, param3:Boolean)
      {
         super();
         this._pbi = param1;
         this._raceId = this._pbi.raceId;
         this._localId = param2;
         this._face = param3 ? 1 : 0;
         this.init();
      }
      
      private function init() : void
      {
      }
      
      public function handleIcon() : *
      {
      }
      
      private function addIconMc() : void
      {
         var _loc1_:Point = PositionUtil.getDefaultPosition(this._localId);
         this._iconMc.x = _loc1_.x;
         this._iconMc.y = _loc1_.y;
         FightController.instance.fightPanel.layerPet.addChild(this._iconMc);
      }
      
      private function onNextTurn(param1:PetFightEvent) : void
      {
         this.handleIcon();
      }
      
      public function dispose() : void
      {
      }
   }
}

