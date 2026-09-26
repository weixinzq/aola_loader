package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.utils.getDefinitionByName;
   import mmo.common.ProgressFullSprite;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowDataPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.baseservice.skillcomponent.ISkillComponentService;
   import mmo.interfaces.baseservice.skillcomponent.IUserSkillUIInfo;
   import mmo.interfaces.gq.newskill.GQNewSkillConfig;
   import mmo.interfaces.miraclepet.IMiraclePetPanelService;
   import mmo.interfaces.pet.data.IPetBattleEffDataService;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.petcommon.BattleEffHelper;
   import mmo.interfaces.pet.petcommon.DegeneratorBattleEffLevel;
   import mmo.interfaces.pet.petcommon.DegeneratorBattleEffLevelHelper;
   import mmo.interfaces.pet.petcommon.LegendBattleEffLevel;
   import mmo.interfaces.pet.petcommon.LegendBattleEffLevelHelper;
   import mmo.interfaces.pet.petcommon.XinghuiBattleEffLevel;
   import mmo.interfaces.pet.petcommon.XinghuiBattleEffLevelHelper;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.pet.ui.IPetUIService;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petpackage.controller.helper.PetPackageGQNewSkillHelper;
   import mmo.petpackage.controller.helper.SetBattleEffHelper;
   import mmo.petpackage.controller.helper.TabJumpHelper;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.panel.inclusion.ChangeViewIcon;
   import mmo.petpackage.panel.inclusion.CompleteMiraclePMAllSkillComponent;
   import mmo.petpackage.panel.inclusion.MiraclePetAllSkillComponent;
   import mmo.petpackage.service.PetPackageService;
   import mmo.play.activity.framework.util.LinkUtil;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.activity.helper.Pet_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActTipsMc;
   import mmo.play.actthings.skill.ActGQSkillHelper;
   import mmo.play.actthings.skill.ActSkillHelper;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1730")]
   public class PetDetailSkill extends PetDetailBase
   {
      
      private static const SKILL_POINTS:Array = [new Point(595,242),new Point(735,242),new Point(594,295),new Point(734,295)];
      
      public var btnConfigGQSkill:SimpleButton;
      
      public var btnim:SimpleButton;
      
      public var btnskillchange:SimpleButton;
      
      public var btnskilldesc:SimpleButton;
      
      public var compsc:CompleteMiraclePMAllSkillComponent;
      
      public var mcBtnGQNewSkill:MovieClip;
      
      public var mcChangeViewIcon:ChangeViewIcon;
      
      public var mcConfigGQSkillRed:MovieClip;
      
      public var mcPetAttackType:MovieClip;
      
      public var mcSkillLevel:MovieClip;
      
      public var mcbattleeffcontainer:MovieClip;
      
      public var mcdegeneratorskilllist:DegeneratorPetSkillList;
      
      public var mcdetect:PetDetectInfo;
      
      public var mcgqskilllist:MovieClip;
      
      public var mclegendskilllist:LegendPetSkillList;
      
      public var mcmaxbattleeff:MovieClip;
      
      public var mcskillindex:MovieClip;
      
      public var mcxinghuiskilllist:MovieClip;
      
      public var mpasc:MiraclePetAllSkillComponent;
      
      private var attDetail:Sprite = null;
      
      private var mcGenius:MovieClip = null;
      
      private var skillInfoAry:Array = [];
      
      private var isClicking:Boolean = false;
      
      private var psms:IPetSkillMesService = null;
      
      private var pbeds:IPetBattleEffDataService = null;
      
      private var pmService:IPMService;
      
      private var petUIService:IPetUIService = null;
      
      private var iscs:ISkillComponentService = ServiceContainer.getService(ISkillComponentService) as ISkillComponentService;
      
      private var btnSkillChange:SimpleButton;
      
      private var _miraclePetAllSkillComponent:MiraclePetAllSkillComponent;
      
      private var _completeMiraclePMSkillcomponent:CompleteMiraclePMAllSkillComponent;
      
      private var _legendPetSkillList:LegendPetSkillList = null;
      
      private var _degeneratorPetSkillList:DegeneratorPetSkillList = null;
      
      private var _xinghuiPetSkillHelper:ActSkillHelper;
      
      private var _xinghuiPetSkillMc:MovieClip;
      
      private var _gqPetSkillHelper:ActGQSkillHelper;
      
      private var _gqPetSkillMc:MovieClip;
      
      private var _gqPetAttackTypeMc:MovieClip;
      
      private var _skillIndexMc:MovieClip;
      
      private var _actTips:ActTipsMc;
      
      public function PetDetailSkill()
      {
         super();
         this.initPars();
         this.reset();
         this.initFuns();
      }
      
      private function initPars() : void
      {
         var _loc2_:Point = null;
         var _loc3_:IUserSkillUIInfo = null;
         var _loc4_:DisplayObject = null;
         this.mcdetect.visible = true;
         this._miraclePetAllSkillComponent = this.mpasc;
         this._completeMiraclePMSkillcomponent = this.compsc;
         this._skillIndexMc = this.mcskillindex;
         this._legendPetSkillList = this.mclegendskilllist;
         this._degeneratorPetSkillList = this.mcdegeneratorskilllist;
         this._xinghuiPetSkillHelper = new ActSkillHelper();
         this._xinghuiPetSkillMc = this.mcxinghuiskilllist;
         this._gqPetSkillHelper = new ActGQSkillHelper();
         this._gqPetSkillMc = this.mcgqskilllist;
         this._gqPetAttackTypeMc = this.mcPetAttackType;
         this._actTips = new ActTipsMc();
         var _loc1_:int = 0;
         while(_loc1_ < SKILL_POINTS.length)
         {
            _loc2_ = SKILL_POINTS[_loc1_];
            _loc3_ = this.iscs.getUserSkillUI(0);
            this.skillInfoAry.push(_loc3_);
            _loc4_ = _loc3_.view;
            _loc4_.x = _loc2_.x;
            _loc4_.y = _loc2_.y;
            _loc4_.visible = false;
            this.addChildAt(_loc3_.view,this.numChildren - 3);
            _loc1_++;
         }
         this.addChildAt(this.mcChangeViewIcon,this.numChildren - 3);
         this.btnSkillChange = this.btnskillchange as SimpleButton;
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         this.psms = ServiceContainer.getService(IPetSkillMesService) as IPetSkillMesService;
         this.pbeds = ServiceContainer.getService(IPetBattleEffDataService) as IPetBattleEffDataService;
         this.pmService = ServiceContainer.getService(IPMService) as IPMService;
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var id:int = 0;
         var e:MouseEvent = param1;
         switch(e.target.name)
         {
            case "btndetect":
               this.mcdetect.visible = true;
               break;
            case "btnupgradeskill":
               id = int(pdi.id);
               ProgressFullSprite.show();
               ServiceContainer.tryGetService(IMiraclePetPanelService,function(param1:IMiraclePetPanelService, param2:* = null):*
               {
                  ProgressFullSprite.close();
                  param1.showMiraclePetBreakPanel(id);
               });
               ModalDialogManager.getInstance().clearAll();
               break;
            case "btnim":
               id = int(pdi.raceId);
               ModalDialogManager.getInstance().clearAll();
               LinkUtil.showRecommendPetTrainPanel(id);
               break;
            case "btnConfigGQSkill":
               this.onShowGuangQiSelectSkillPl();
         }
      }
      
      private function onShowGuangQiSelectSkillPl() : void
      {
         var self:PetDetailSkill = null;
         self = this;
         var data:Object = {
            "pbi":this.pdi,
            "callback":function():void
            {
               PetDetailDataMap.instance.tryUpdateCachhe(self.pdi.id,true);
            }
         };
         LocalStore.setValue("btnConfigGQSkill_mcConfigGQSkillRed",true,UserInfo.userName);
         Panel_Helper.loadResAndShow("activityres/activity231229/guangqiselectskill/guangqiselectskill_code","mmo.activity231229.guangqiselectskill.panel.GQSS_MainPl",data);
      }
      
      private function initFuns() : void
      {
         this.btnSkillChange.addEventListener(MouseEvent.CLICK,this.onSkillChange);
      }
      
      private function disposeFuns() : void
      {
         var _loc1_:IUserSkillUIInfo = null;
         for each(_loc1_ in this.skillInfoAry)
         {
            _loc1_.dispose();
         }
         this.btnSkillChange.removeEventListener(MouseEvent.CLICK,this.onSkillChange);
         IDispose(this.mcChangeViewIcon).dispose();
      }
      
      private function onClickGeniusUp(param1:MouseEvent) : void
      {
         TabJumpHelper.changeFirstTab(1);
         TabJumpHelper.changeSecondTab(0);
      }
      
      private function onClickHow(param1:MouseEvent) : void
      {
         PetPackageService.currentPanel.closePanel();
         var _loc2_:IPetBattleEffDataService = ServiceContainer.getService(IPetBattleEffDataService) as IPetBattleEffDataService;
         _loc2_.showHowToRaiseBattleEffPanel();
         SundriesClient.logButton(6752);
         SundriesClient.logEvent(15522);
      }
      
      private function refreshBattleEffUI() : void
      {
         var frameIndex:int;
         var battleEffNum:int = 0;
         var mcBattleEff:MovieClip = null;
         var artNums:Array = null;
         var mcBattleEffLevel:MovieClip = null;
         var beLevelInfo:LegendBattleEffLevel = null;
         var beLevelTips:String = null;
         var mcBattleEffLevel1:MovieClip = null;
         var beLevelInfo1:DegeneratorBattleEffLevel = null;
         var tips1Mc:MovieClip = null;
         var mcBattleEffLevel2:MovieClip = null;
         var beLevelInfo2:XinghuiBattleEffLevel = null;
         var tips2Mc:MovieClip = null;
         var mcBattleEffContainer:MovieClip = this.mcbattleeffcontainer;
         battleEffNum = 0;
         if(pdi != null)
         {
            battleEffNum = int(this.pbeds.getPetBattleEffectiveness(pdi));
         }
         if(this.isLegendPet())
         {
            mcBattleEffContainer.gotoAndStop(2);
            mcBattleEffLevel = mcBattleEffContainer.mcbattleefflevel;
            mcBattleEffLevel.visible = this.isLegendPet();
            this._actTips.dispose();
            this._actTips.init(mcBattleEffLevel,mcBattleEffLevel["mctips"]);
            beLevelInfo = LegendBattleEffLevelHelper.getLevelInfoByBattleEff(battleEffNum);
            ActComHelper.setMcFrame(mcBattleEffLevel,"mctips",beLevelInfo.level + 1);
            beLevelTips = "";
            if(beLevelInfo.isMaxLevel())
            {
               beLevelTips = "当前已经是最高战力评级啦！";
            }
            else
            {
               beLevelTips = "下一个战力评级需要" + (beLevelInfo.maxBattleEff + 1) + "战斗力，加油吧！";
            }
            TipsManager.getInstance().replaceTips(mcBattleEffLevel,beLevelTips);
         }
         else if(this.isDegeneratorPet())
         {
            mcBattleEffContainer.gotoAndStop(3);
            mcBattleEffLevel1 = mcBattleEffContainer.getChildByName("mcbattleefflevel1") as MovieClip;
            if(mcBattleEffLevel1 != null)
            {
               mcBattleEffLevel1.visible = this.isDegeneratorPet();
               beLevelInfo1 = DegeneratorBattleEffLevelHelper.getLevelInfoByBattleEff(battleEffNum);
               ActComHelper.setMcFrame(mcBattleEffLevel1,"mctips1",beLevelInfo1.level + 1);
               this._actTips.dispose();
               tips1Mc = mcBattleEffLevel1.getChildByName("mctips1") as MovieClip;
               if(tips1Mc != null)
               {
                  this._actTips.init(mcBattleEffLevel1,tips1Mc);
               }
               beLevelTips = "";
               if(beLevelInfo1.isMaxLevel())
               {
                  beLevelTips = "当前已经是最高战力评级啦！";
               }
               else
               {
                  beLevelTips = "下一个战力评级需要" + (beLevelInfo1.maxBattleEff + 1) + "战斗力，加油吧！";
               }
               TipsManager.getInstance().replaceTips(mcBattleEffLevel1,beLevelTips);
            }
         }
         else if(this.isXinghuiPet())
         {
            mcBattleEffContainer.gotoAndStop(4);
            mcBattleEffLevel2 = mcBattleEffContainer.getChildByName("mcbattleefflevel2") as MovieClip;
            if(mcBattleEffLevel2 != null)
            {
               mcBattleEffLevel2.visible = this.isXinghuiPet();
               beLevelInfo2 = XinghuiBattleEffLevelHelper.getLevelInfoByBattleEff(battleEffNum);
               ActComHelper.setMcFrame(mcBattleEffLevel2,"mctips2",beLevelInfo2.level + 1);
               this._actTips.dispose();
               tips2Mc = mcBattleEffLevel2.getChildByName("mctips2") as MovieClip;
               if(tips2Mc != null)
               {
                  this._actTips.init(mcBattleEffLevel2,tips2Mc);
               }
               beLevelTips = "";
               if(beLevelInfo2.isMaxLevel())
               {
                  beLevelTips = "当前已经是最高战力评级啦！";
               }
               else
               {
                  beLevelTips = "下一个战力评级需要" + (beLevelInfo2.maxBattleEff + 1) + "战斗力，加油吧！每提升1个评级会随机升级1个未满级技能哦！";
               }
               TipsManager.getInstance().replaceTips(mcBattleEffLevel2,beLevelTips);
            }
         }
         else
         {
            mcBattleEffContainer.gotoAndStop(1);
         }
         mcBattleEff = mcBattleEffContainer.mc_battleeff;
         frameIndex = int(BattleEffHelper.getBattleEffFrameIndex(battleEffNum));
         mcBattleEff.gotoAndStop(1);
         artNums = [];
         mcBattleEff.addFrameScript(frameIndex - 1,function():void
         {
            var _loc1_:MovieClip = mcBattleEff.getChildByName("mc") as MovieClip;
            artNums = Panel_Helper.getSubClips(_loc1_,5,"num_");
            ArtNumberManager.setNumber(artNums,battleEffNum);
         });
         mcBattleEff.gotoAndStop(frameIndex);
      }
      
      private function isLegendPet() : Boolean
      {
         return pdi != null && Boolean(this.pmService.getOperationPM(pdi.raceId).pmData.isLegendPM());
      }
      
      private function isDegeneratorPet() : Boolean
      {
         return pdi != null && Boolean(this.pmService.getOperationPM(pdi.raceId).pmData.isDegeneratorPM());
      }
      
      private function isXinghuiPet() : Boolean
      {
         return pdi != null && Boolean(this.pmService.getOperationPM(pdi.raceId).pmData.isXinghuiPM());
      }
      
      private function onSkillChange(param1:MouseEvent) : void
      {
         var pbi:PetBriefInfo = null;
         var evt:MouseEvent = param1;
         pbi = this.pdi;
         ProgressFullSprite.show();
         ResScheduler.getResource("pet/petarousingskills",function(param1:Object):void
         {
            var _loc2_:Class = getDefinitionByName("mmo.pet.petarousingskills.PetArousingSkillsEntrance") as Class;
            var _loc3_:IShowDataPanel = new _loc2_() as IShowDataPanel;
            _loc3_.showPanelByData({"pbi":pbi});
         });
      }
      
      override protected function initUI() : void
      {
         ServiceContainer.instance.tryGetService(IPetUIService,function(param1:IPetUIService, param2:Object):void
         {
            petUIService = param1;
            canUpdateUI = true;
            tryRefreshUI();
         });
      }
      
      override protected function refreshUI() : void
      {
         this.refreshSkillUI();
         this.refreshScoreUI();
      }
      
      private function refreshScoreUI() : void
      {
         var _loc1_:IPetBattleEffDataService = null;
         this.refreshLevelUI();
         this.refreshGeniusUI();
         this.refreshBattleEffUI();
         if(this.pdi != null)
         {
            _loc1_ = ServiceContainer.getService(IPetBattleEffDataService) as IPetBattleEffDataService;
            SetBattleEffHelper.setBattleEff(this.mcmaxbattleeff,_loc1_.getPetMaxBattleEffectivenessByRaceId(pdi.raceId));
         }
      }
      
      private function refreshGeniusUI() : void
      {
      }
      
      private function refreshLevelUI() : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:int = 1;
         if(pdi != null)
         {
            _loc1_ = int(pdi.level);
            _loc2_ = int(pdi.curLvExp);
            _loc3_ = pdi.curLvExp + pdi.toNextLevel;
         }
      }
      
      private function refreshSkillUI() : void
      {
         var _loc3_:IUserSkillUIInfo = null;
         var _loc4_:IUserSkillUIInfo = null;
         var _loc5_:int = 0;
         var _loc6_:SkillInfo = null;
         if(pdi == null)
         {
            for each(_loc4_ in this.skillInfoAry)
            {
               _loc4_.updateSkillId(0);
            }
            return;
         }
         var _loc1_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc2_:PMData = _loc1_.customData.pmDataMap.getPM(pdi.raceId);
         for each(_loc3_ in this.skillInfoAry)
         {
            _loc3_.view.visible = false;
         }
         this._legendPetSkillList.visible = false;
         this._degeneratorPetSkillList.visible = false;
         this._xinghuiPetSkillMc.visible = false;
         this._gqPetSkillMc.visible = false;
         this._gqPetAttackTypeMc.visible = false;
         this.btnskilldesc.visible = false;
         this._completeMiraclePMSkillcomponent.visible = false;
         this._miraclePetAllSkillComponent.visible = false;
         this.btnSkillChange.visible = false;
         this._skillIndexMc.visible = false;
         ActComHelper.setVisible(this,"btnConfigGQSkill",PetPackageGQNewSkillHelper.getInstance().isShowingGQNewSkill());
         ActComHelper.setVisible(this,"mcConfigGQSkillRed",PetPackageGQNewSkillHelper.getInstance().isShowingGQNewSkill() && !LocalStore.getValue("btnConfigGQSkill_mcConfigGQSkillRed",UserInfo.userName));
         if(_loc2_.isLegendPM())
         {
            this._legendPetSkillList.refresh(pdi);
            this._legendPetSkillList.visible = true;
         }
         else if(_loc2_.isDegeneratorPM())
         {
            this._degeneratorPetSkillList.refresh(pdi);
            this._degeneratorPetSkillList.visible = true;
         }
         else if(_loc2_.isXinghuiPM())
         {
            this._xinghuiPetSkillHelper.setXinghuiSkillList(this._xinghuiPetSkillMc,pdi);
            this._xinghuiPetSkillMc.visible = true;
            this.btnskilldesc.visible = true;
         }
         else if(_loc2_.isGQPM())
         {
            this._gqPetSkillHelper.setGQSkillList(this._gqPetSkillMc,pdi,-1,{"isShowingGQNewSkill":pdi.usingGQSkillType == 1});
            this._gqPetSkillMc.visible = true;
            this._gqPetAttackTypeMc.gotoAndStop(Pet_Helper.getAttackType(_loc2_) == Pet_Helper.AttackType_Attack ? 1 : 2);
            this._gqPetAttackTypeMc.visible = true;
            TipsManager.getInstance().addMaterialTips(this._gqPetAttackTypeMc);
            this.btnskilldesc.visible = true;
         }
         else if(Boolean(_loc2_.isCompletePM()) && Boolean(_loc2_.isMiraclePet()))
         {
            this._completeMiraclePMSkillcomponent.visible = true;
            this._completeMiraclePMSkillcomponent.refresh(pdi.raceId,pdi.skills);
         }
         else if(_loc2_.isMiraclePet())
         {
            this._miraclePetAllSkillComponent.refresh(pdi.raceId,pdi.skills);
            this._miraclePetAllSkillComponent.visible = true;
         }
         else
         {
            for each(_loc3_ in this.skillInfoAry)
            {
               _loc3_.view.visible = true;
            }
            _loc5_ = 0;
            while(_loc5_ < SKILL_POINTS.length)
            {
               _loc4_ = this.skillInfoAry[_loc5_] as IUserSkillUIInfo;
               TipsManager.getInstance().removeTips(_loc4_.view as InteractiveObject);
               if(null == pdi.skills || _loc5_ >= pdi.skills.length)
               {
                  _loc4_.updateSkillId(0);
                  _loc4_.view.visible = true;
               }
               else
               {
                  _loc6_ = pdi.skills[_loc5_] as SkillInfo;
                  _loc4_.updateSkillId(_loc6_.id);
                  _loc4_.updateRemainPP(_loc6_.canUseTimes);
                  _loc4_.view.visible = true;
                  TipsManager.getInstance().addComplexTips(_loc4_.view as InteractiveObject,_loc4_.tipsTitle,_loc4_.tipsContext,100,-100,9);
               }
               _loc5_++;
            }
            this.btnSkillChange.visible = true;
            this._skillIndexMc.visible = true;
         }
         this.refreshMcBtnGQNewSkill();
      }
      
      private function refreshMcBtnGQNewSkill() : void
      {
         if(!this.pdi)
         {
            return;
         }
         var _loc1_:Boolean = Boolean(GQNewSkillConfig.isPetHaveNewSkill(this.pdi.raceId));
         var _loc2_:Boolean = Boolean(GQNewSkillConfig.isPetHaveOnlyNewSkill(this.pdi.raceId));
         var _loc3_:Boolean = this.pdi.raceId > 0 && _loc1_ && !_loc2_;
         var _loc4_:int = _loc3_ && this.isShowingGQNewSkill() ? 1 : 2;
         ActComHelper.setVisible(this,"mcBtnGQNewSkill",_loc3_);
         ActComHelper.setMcFrame(this,"mcBtnGQNewSkill",_loc4_);
         TipsManager.getInstance().replaceTips(ActComHelper.getChildNode(this,"mcBtnGQNewSkill") as MovieClip,this.isShowingGQNewSkill() ? "点击后切换使用原技能" : "点击后切换使用新技能");
      }
      
      private function isShowingGQNewSkill() : Boolean
      {
         return PetPackageGQNewSkillHelper.getInstance().isShowingGQNewSkill();
      }
      
      override protected function resetUI() : void
      {
         this.refreshUI();
      }
      
      override public function dispose() : void
      {
         if(this._actTips != null)
         {
            this._actTips.dispose();
            this._actTips = null;
         }
         IDispose(this.mcdetect).dispose();
         this.pdi = null;
         this.reset();
         this.disposeFuns();
         this._miraclePetAllSkillComponent && this._miraclePetAllSkillComponent.dispose();
         this._miraclePetAllSkillComponent = null;
         this._legendPetSkillList && this._legendPetSkillList.dispose();
         this._legendPetSkillList = null;
         this._degeneratorPetSkillList && this._degeneratorPetSkillList.dispose();
         this._degeneratorPetSkillList = null;
         this._xinghuiPetSkillHelper && this._xinghuiPetSkillHelper.setXinghuiSkillList();
         this._gqPetSkillHelper && this._gqPetSkillHelper.setGQSkillList();
         super.dispose();
      }
   }
}

