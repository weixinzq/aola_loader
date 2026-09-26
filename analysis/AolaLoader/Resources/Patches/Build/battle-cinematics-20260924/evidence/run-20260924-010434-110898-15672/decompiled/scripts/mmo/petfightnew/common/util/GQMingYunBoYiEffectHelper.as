package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.common.datastructures.ResourceObject;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.skilleffect.SkillEffectLoader;
   import mmo.play.actthings.helper.ActComHelper;
   
   public class GQMingYunBoYiEffectHelper
   {
      
      private static const URL:String = "gqpet/mingyunboyi/effect/mingyunboyieffect";
      
      private static const CLS:String = "mmo.gqpet.mingyunboyi.effect.GQMingYunBoYiEffectMv";
      
      private static const AllOrdersNum:int = 4;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _iconMc:MovieClip;
      
      private var _raceId:int;
      
      private var _pbi:PetBriefInfo;
      
      private var _localId:int;
      
      private var _face:int;
      
      public function GQMingYunBoYiEffectHelper(param1:PetBriefInfo, param2:int, param3:Boolean)
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
         this.handleIcon();
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.AFTER_USE_SKILL,this.onAfterUseSkill);
      }
      
      public function handleIcon() : *
      {
         if(Boolean(this._pbi) && StatusUtil.getMingYunBoYiOrderOpenNum(this._pbi) > 0)
         {
            if(this._iconMc)
            {
               this.addIconMc();
            }
            else
            {
               SkillEffectLoader.loadObject(new ResourceObject(URL,CLS),function(param1:MovieClip):void
               {
                  _iconMc = param1;
                  addIconMc();
               });
            }
         }
         else
         {
            DisplayUtil.stopAndRemove(this._iconMc);
         }
      }
      
      private function addIconMc() : void
      {
         var _loc1_:int = -200;
         var _loc2_:Point = PositionUtil.getDefaultPosition(this._localId);
         this._iconMc.x = _loc2_.x;
         this._iconMc.y = _loc2_.y;
         var _loc3_:int = StatusUtil.getMingYunBoYiOrderOpenNum(this._pbi);
         this.setCurrOpenNum(_loc3_);
         this._iconMc.y += _loc1_;
         if(this._iconMc.y < 0)
         {
            this._iconMc.y = 0;
         }
         FightController.instance.fightPanel.layerPet.addChild(this._iconMc);
         this._iconMc.mouseEnabled = this._iconMc.mouseChildren = false;
      }
      
      private function setCurrOpenNum(param1:int) : void
      {
         var _loc2_:Array = StatusUtil.getMingYunBoYiOrders(this._pbi);
         var _loc3_:int = 0;
         while(_loc3_ < AllOrdersNum)
         {
            if(param1 <= _loc3_)
            {
               ActComHelper.setMcFrame(this._iconMc,"mcOrder" + _loc3_,1);
            }
            else
            {
               ActComHelper.setMcFrame(this._iconMc,"mcOrder" + _loc3_,_loc2_[_loc3_]["guess"] * AllOrdersNum + _loc2_[_loc3_]["order"] + 2);
            }
            _loc3_++;
         }
      }
      
      private function onNextTurn(param1:PetFightEvent) : void
      {
         if(!this._pbi)
         {
            return;
         }
         this.handleIcon();
      }
      
      private function onAfterUseSkill(param1:PetFightEvent) : void
      {
         if(!this._pbi)
         {
            return;
         }
         this.handleIcon();
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.AFTER_USE_SKILL,this.onAfterUseSkill);
         DisplayUtil.stopAndRemove(this._iconMc);
      }
   }
}

