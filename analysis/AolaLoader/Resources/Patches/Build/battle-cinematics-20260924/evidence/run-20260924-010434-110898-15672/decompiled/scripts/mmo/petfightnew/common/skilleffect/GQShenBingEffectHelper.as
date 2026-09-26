package mmo.petfightnew.common.skilleffect
{
   import flash.display.MovieClip;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.gq.shenbing.GQShenBingObjHelper;
   import mmo.interfaces.gq.shenbing.GQShenBingType;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.common.datastructures.ResourceObject;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.PositionUtil;
   
   public class GQShenBingEffectHelper
   {
      
      private static const URL:String = "gqpet/shenbing/effect/shenbingeffect_";
      
      private static const CLS:String = "mmo.gqpet.shenbing.view.ShenBingEffect_";
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _iconMc:MovieClip;
      
      private var _raceId:int;
      
      private var _pbi:PetBriefInfo;
      
      private var _localId:int;
      
      private var _face:int;
      
      private var _shenBingId:int;
      
      private var _shenBingType:int;
      
      public function GQShenBingEffectHelper(param1:PetBriefInfo, param2:int, param3:Boolean)
      {
         super();
         var _loc4_:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
         if(_loc4_.isFightLowQuality)
         {
            return;
         }
         this._pbi = param1;
         this._raceId = this._pbi.raceId;
         this._localId = param2;
         this._face = param3 ? 1 : 0;
         this._shenBingId = this._pbi.shenBingRaceId;
         this._shenBingType = GQShenBingObjHelper.getShenBingObjByRaceId(this._pbi.shenBingRaceId).type;
         this.init();
      }
      
      private function init() : void
      {
         this.handleIcon();
      }
      
      public function handleIcon() : *
      {
         if(Boolean(this._pbi) && Boolean(this._pbi.isQiyueShenBing))
         {
            if(!this._iconMc)
            {
               SkillEffectLoader.loadObject(new ResourceObject(URL + this._shenBingId,CLS + this._shenBingId + "_" + (this._face + 1)),function(param1:MovieClip):void
               {
                  _iconMc = param1;
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
         var _loc1_:int = 20;
         var _loc2_:int = 100;
         var _loc3_:Point = PositionUtil.getDefaultPosition(this._localId);
         if(this._iconMc)
         {
            this._iconMc.x = _loc3_.x;
            this._iconMc.y = _loc3_.y;
            if(this._face == 0)
            {
               if(this._shenBingType == 1)
               {
                  this._iconMc.x += _loc1_;
               }
               else
               {
                  this._iconMc.x -= _loc1_;
               }
            }
            else if(this._shenBingType == 1)
            {
               this._iconMc.x -= _loc1_;
            }
            else
            {
               this._iconMc.x += _loc1_;
            }
            this._iconMc.y -= _loc2_;
            this._iconMc.mouseEnabled = this._iconMc.mouseChildren = false;
            if(FightController.instance.fightPanel)
            {
               FightController.instance.fightPanel.layerPetUp.addChild(this._iconMc);
            }
         }
      }
      
      public function attack(param1:Point, param2:Point) : void
      {
         var atk:Point = param1;
         var def:Point = param2;
         if(this._shenBingType == GQShenBingType.ATTACK)
         {
            this.addIconMc();
            this._iconMc.gotoAndPlay(1);
            this._iconMc.addFrameScript(this._iconMc.totalFrames - 1,function():void
            {
               if(Boolean(_iconMc) && Boolean(_iconMc.parent))
               {
                  DisplayUtil.stopAndRemove(_iconMc);
               }
            });
         }
      }
      
      public function hurt() : void
      {
         if(this._shenBingType == GQShenBingType.DEFEND)
         {
            this.addIconMc();
            this._iconMc.gotoAndPlay(1);
            this._iconMc.addFrameScript(this._iconMc.totalFrames - 1,function():void
            {
               if(Boolean(_iconMc) && Boolean(_iconMc.parent))
               {
                  DisplayUtil.stopAndRemove(_iconMc);
               }
            });
         }
      }
      
      public function dispose() : void
      {
         DisplayUtil.stopAndRemove(this._iconMc);
      }
   }
}

