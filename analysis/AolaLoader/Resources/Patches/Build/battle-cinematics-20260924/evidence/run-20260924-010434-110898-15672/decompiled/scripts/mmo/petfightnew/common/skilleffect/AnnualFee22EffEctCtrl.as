package mmo.petfightnew.common.skilleffect
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Point;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.PositionUtil;
   
   public class AnnualFee22EffEctCtrl
   {
      
      private static const URL_AtAll:String = "xinghuipet/annualfee22/effect/xinghuiannual22atall";
      
      private static const CLS_AtAll:String = "mmo.xinghuipet.annualfee22.XingHuiAnnual22AtAllMv";
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _raceId:int;
      
      private var _pbi:PetBriefInfo;
      
      private var _locaId:int;
      
      private var _face:int;
      
      private var key:String = "";
      
      public function AnnualFee22EffEctCtrl(param1:PetBriefInfo, param2:int, param3:Boolean)
      {
         super();
         this._pbi = param1;
         this._raceId = this._pbi.raceId;
         this._locaId = param2;
         this._face = param3 ? 1 : 0;
         this.key = "xinghuishenlingmaxleveleffect_" + this._locaId + "_" + this._face;
         if(this._pbi.getXingHuiAnnualFee22SkillParser().isAnnualSummon == false)
         {
            return;
         }
         this.playAtAllEffect();
      }
      
      public function dispose() : void
      {
         var _loc1_:DisplayObject = FightController.instance.fightPanel.layerPet.getChildByName(this.key);
         DisplayUtil.stopAndRemove(_loc1_);
      }
      
      private function playAtAllEffect() : void
      {
         var pRaceId:int;
         var obj:Object;
         var url:String;
         var cls:String;
         var layer:Sprite = null;
         var pos:Point = null;
         layer = FightController.instance.fightPanel.layerPet;
         var hasView:Boolean = layer.getChildByName(this.key) != null;
         if(hasView)
         {
            return;
         }
         pRaceId = int(this._pbi.getXingHuiAnnualFee22SkillParser().summonMasterRaceId);
         if(pRaceId == -1)
         {
            return;
         }
         pos = PositionUtil.getDefaultPosition(this._locaId);
         obj = XinghuiPetType.getAnnualFee22Object(pRaceId);
         if(obj == null)
         {
            return;
         }
         url = URL_AtAll;
         cls = CLS_AtAll;
         url += "_" + obj.fightEffect;
         cls += "_" + obj.fightEffect;
         ResScheduler.getRes(ResParams.createTempByDomain(url,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.x = pos.x;
            param1.y = pos.y;
            param1.name = key;
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),cls,ResPriority.LOW));
      }
   }
}

