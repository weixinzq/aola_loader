package mmo.petfightnew.common.skilleffect
{
   import flash.display.MovieClip;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.data.GQTianYiSkillParse;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.common.datastructures.ResourceObject;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.PositionUtil;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActMovieHelper;
   
   public class GQTianYiEffectHelper
   {
      
      private static const URL:String = "gqpet/tianyi/effect/tianyieffect_";
      
      private static const CLS:String = "mmo.gqpet.tianyi.effect.GQTianyiEffectMv_";
      
      private static const AllChessNum:int = 4;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _iconMc:MovieClip;
      
      private var _raceId:int;
      
      private var _pbi:PetBriefInfo;
      
      private var _localId:int;
      
      private var _face:int;
      
      private var _openNum:int;
      
      public function GQTianYiEffectHelper(param1:PetBriefInfo, param2:int, param3:Boolean)
      {
         super();
         this._pbi = param1;
         this._raceId = this._pbi.raceId;
         this._localId = param2;
         this._face = param3 ? 1 : 0;
         this._openNum = 0;
         this.init();
      }
      
      private function init() : void
      {
         this.handleIcon();
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.AFTER_USE_SKILL,this.onAfterUseSkill);
      }
      
      public function handleIcon() : *
      {
         var realId:int = 0;
         if(Boolean(this._pbi) && GQTianYiSkillParse.getSkillOrders(this._pbi).length > 0)
         {
            if(this._iconMc)
            {
               this.addIconMc();
            }
            else
            {
               realId = GQTianYiSkillParse.getWhichRaceId(this._pbi) % 10000;
               SkillEffectLoader.loadObject(new ResourceObject(URL + realId,CLS + realId),function(param1:MovieClip):void
               {
                  _iconMc = param1;
                  addIconMc();
               });
            }
         }
         else
         {
            DisplayUtil.stopAndRemove(this._iconMc);
            this._openNum = 0;
         }
      }
      
      private function addIconMc() : void
      {
         var curOpenNum:int;
         var realId:int = 0;
         var offsetY:int = -200;
         var pos:Point = PositionUtil.getDefaultPosition(this._localId);
         this._iconMc.x = pos.x;
         this._iconMc.y = pos.y;
         curOpenNum = int(GQTianYiSkillParse.getHasOpenNum(this._pbi));
         this.setChessOpenNum(curOpenNum);
         if(this._openNum < AllChessNum && curOpenNum >= AllChessNum)
         {
            realId = GQTianYiSkillParse.getWhichRaceId(this._pbi) % 10000;
            SkillEffectLoader.loadObject(new ResourceObject(URL + realId,"mmo.gqpet.tianyi.effect.GQTianyiOpenAllChessMv_" + realId),function(param1:MovieClip):void
            {
               param1.mouseChildren = param1.mouseEnabled = false;
               ActMovieHelper.showAndPlayMcMv(param1);
            });
         }
         this._openNum = curOpenNum;
         this._iconMc.y += offsetY;
         if(this._iconMc.y < 0)
         {
            this._iconMc.y = 0;
         }
         FightController.instance.fightPanel.layerPetUp.addChild(this._iconMc);
         this._iconMc.mouseEnabled = this._iconMc.mouseChildren = false;
      }
      
      private function setChessOpenNum(param1:int) : void
      {
         var _loc2_:Array = GQTianYiSkillParse.getSkillOrders(this._pbi);
         var _loc3_:int = 0;
         while(_loc3_ < AllChessNum)
         {
            ActComHelper.setMcFrame(this._iconMc,"mcChess" + _loc3_,_loc3_ < param1 ? int(_loc2_[_loc3_] + 1) : 5);
            _loc3_++;
         }
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
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.AFTER_USE_SKILL,this.onAfterUseSkill);
         DisplayUtil.stopAndRemove(this._iconMc);
      }
   }
}

