package mmo.petfightnew.common.ui
{
   import flash.display.MovieClip;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.common.panel.OperableView;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.GQDiJieShiSkillParse;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   public class GQDijieshiPetIcon extends OperableView
   {
      
      private static const URL:String = "gqpet/dijieshi/effect/dijieshieffect_";
      
      private static const CLS:String = "mmo.gqpet.dijieshi.view.DijieshiIcon_";
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
      
      private var _dijieshiSkillParse:GQDiJieShiSkillParse;
      
      private var _pbi:PetBriefInfo;
      
      private var _iconMc:MovieClip;
      
      private var _beforeRaceId:int = -1;
      
      private var _dijieshiResTurnMc:MovieClip;
      
      private var _changeResTurn:int;
      
      private var _baseTurn:int;
      
      public function GQDijieshiPetIcon(param1:MovieClip)
      {
         super(param1);
         this.init();
      }
      
      override protected function initComponents() : void
      {
         super.initComponents();
         this._dijieshiResTurnMc = this.getChild("mcDiJieShiResTurn");
      }
      
      override protected function addClickFuncs() : void
      {
         super.addClickFuncs();
         this.regClickFunc("btnDijishiChange",this.clickDijieshiChange);
      }
      
      public function refresh(param1:PetBriefInfo) : void
      {
         var _loc3_:PMSkill = null;
         var _loc4_:String = null;
         var _loc5_:String = null;
         var _loc6_:Object = null;
         var _loc7_:String = null;
         var _loc8_:MovieClip = null;
         if(!param1)
         {
            if(!this._pbi)
            {
               DisplayUtil.stop(this._view);
               this.setVisible("",false);
               return;
            }
            param1 = this._pbi;
            if(this._baseTurn < FightController.instance.turnCount)
            {
               --this._changeResTurn;
            }
         }
         else
         {
            this._changeResTurn = GQDiJieShiSkillParse.getChangeViewResTurn(param1);
            this._pbi = param1;
         }
         this._baseTurn = FightController.instance.turnCount;
         this._dijieshiSkillParse = GQDiJieShiSkillParse.getDiJieShiSkillParse(this._pbi.raceId);
         var _loc2_:PMData = this._pmSvr.getOperationPM(this._pbi.raceId).pmData;
         if(GQPetType.isDiJieShi(_loc2_.getGQType()))
         {
            this.setVisible("",true);
            if(GQDiJieShiSkillParse.getIsChangeView(this._pbi))
            {
               this.handleIcon();
               this.setVisible("mcDiJieShiNum",false);
               this.setVisible(this._dijieshiResTurnMc,true);
               this._view.parent.parent.addChild(this._dijieshiResTurnMc);
               this._dijieshiResTurnMc.x = 831.7;
               this._dijieshiResTurnMc.y = 431;
               ArtNumberManager.setMidNumbers(ActComHelper.getDisplayObjArr(this._dijieshiResTurnMc,"mcNum_"),this._changeResTurn);
               _loc6_ = GQPetType.getDiJieShiObject(this._pbi.raceId);
               _loc7_ = _loc6_ ? _loc6_.extraFightTips : "";
               this.setTips(this._dijieshiResTurnMc,"域界剩余回合：" + this._changeResTurn + _loc7_);
            }
            else
            {
               DisplayUtil.clearChildren(this.getChild("mcPetIcon.mcoperatingpeticon"));
               this.setVisible("mcDiJieShiNum",true);
               ArtNumberManager.setMidNumbers(ActComHelper.getDisplayObjArr(this.getChild("mcDiJieShiNum"),"mcNum_"),GQDiJieShiSkillParse.getEnergyValue(param1));
               this.setVisible(this._dijieshiResTurnMc,false);
            }
            this.setFrame("mcProcess",Math.floor(GQDiJieShiSkillParse.getEnergyValue(this._pbi) * 4 / GQPetType.getDijieshiMaxEnergy()) + 1);
            this.setTips("mcProcess","当前域界能量" + GQDiJieShiSkillParse.getEnergyValue(this._pbi) + "/" + GQPetType.getDijieshiMaxEnergy());
            if(GQDiJieShiSkillParse.getEnergyValue(this._pbi) >= GQPetType.getDijieshiMaxEnergy())
            {
               _loc8_ = this.getChild("mcProcess.mvFull");
               if(!GQDiJieShiSkillParse.getIsChangeView(this._pbi))
               {
                  _loc8_.play();
                  this.setVisible(_loc8_,true);
               }
               else
               {
                  _loc8_.stop();
                  this.setVisible(_loc8_,false);
               }
               this.setEnabled(_loc8_,false,null,true);
            }
            _loc3_ = this._pmSvr.customData.pmSkillMap.getSkill(this._dijieshiSkillParse.changeViewSkillId);
            _loc4_ = _loc3_.newCnName + " 威力：" + this.getSkillPowerDesc(_loc3_.power);
            if(this._gameOptionSvr.isGQSimpleSkillView)
            {
               _loc5_ = _loc3_.oldEffectDesc;
            }
            else
            {
               _loc5_ = _loc3_.clientDesc;
            }
            TipsManager.getInstance().replaceComplexTips(this.getChild("btnDijishiChange"),_loc4_,_loc5_,100);
         }
         else
         {
            this._pbi = null;
            this._beforeRaceId = -1;
            this._changeResTurn = -1;
            this._baseTurn = 0;
            DisplayUtil.stop(this._view);
            this.setVisible("",false);
         }
      }
      
      override protected function refreshView() : void
      {
         super.refreshView();
         DisplayUtil.stop(this._view);
         this.setVisible("",false);
      }
      
      private function getSkillPowerDesc(param1:int) : String
      {
         if(param1 > 0)
         {
            return param1.toString();
         }
         return "未知";
      }
      
      private function handleIcon() : *
      {
         var raceId:int = 0;
         raceId = int(PetAssetsMap.getPetFlaId(this._pmSvr.getOperationPM(this._pbi.raceId).getMaxCommonEvlution().raceId));
         if(raceId == this._beforeRaceId)
         {
            this.addIconMc();
         }
         else
         {
            DisplayUtil.clearChildren(this.getChild("mcPetIcon.mcoperatingpeticon"));
            ResScheduler.getRes(ResParams.createTempByDomain(URL + raceId,function(param1:MovieClip, param2:ApplicationDomain):void
            {
               _iconMc = param1;
               addIconMc();
               _beforeRaceId = raceId;
            },ResDomain.decorate(FightData.instance.applicationDomain),CLS + raceId));
         }
      }
      
      private function addIconMc() : void
      {
         if(Boolean(this._view) && Boolean(this._view.parent))
         {
            (this.getChild("mcPetIcon.mcoperatingpeticon") as MovieClip).addChild(this._iconMc);
         }
      }
      
      private function clickDijieshiChange() : void
      {
         var _loc1_:PlayerBattleInfo = null;
         if(Boolean(this._pbi) && (GQDiJieShiSkillParse.getEnergyValue(this._pbi) >= GQPetType.getDijieshiMaxEnergy() && !GQDiJieShiSkillParse.getIsChangeView(this._pbi)))
         {
            _loc1_ = FightData.instance.myInfo.operatingPlayer;
            FightController.instance.useSkill(this._dijieshiSkillParse.changeViewSkillId,_loc1_.slotId,_loc1_.slotId,false);
            this.setVisible("mcProcess.mvFull",false);
         }
      }
      
      override public function dispose() : void
      {
         super.dispose();
         this._beforeRaceId = -1;
      }
   }
}

