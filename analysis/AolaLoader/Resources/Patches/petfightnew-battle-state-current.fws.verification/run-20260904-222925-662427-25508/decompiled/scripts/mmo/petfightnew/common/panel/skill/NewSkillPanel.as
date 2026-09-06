package mmo.petfightnew.common.panel.skill
{
   import com.adobe.utils.ArrayUtil;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.PetClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.degenerator.DegeneratorPetType;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.gq.shenbing.GQShenBingObj;
   import mmo.interfaces.gq.shenbing.GQShenBingObjHelper;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.XingHuiPetHelperUtil;
   import mmo.interfaces.pet.data.GQArmorBurstSkillParse;
   import mmo.interfaces.pet.data.GQBuxiuLvtuSkillParse;
   import mmo.interfaces.pet.data.GQDengShenChangJieSkillParse;
   import mmo.interfaces.pet.data.GQDiJieShiSkillParse;
   import mmo.interfaces.pet.data.GQEternityZhanyiSkillParse;
   import mmo.interfaces.pet.data.GQGuangJinSkillParse;
   import mmo.interfaces.pet.data.GQHuanLingShiSkillParse;
   import mmo.interfaces.pet.data.GQHunDunJueDouSkillParse;
   import mmo.interfaces.pet.data.GQJiangShenSkillParse;
   import mmo.interfaces.pet.data.GQJiuRiChongXianSkillParse;
   import mmo.interfaces.pet.data.GQJueXingSkillParse;
   import mmo.interfaces.pet.data.GQLianSuoSkillParse;
   import mmo.interfaces.pet.data.GQLieJieZhiXiSkillParse;
   import mmo.interfaces.pet.data.GQMiBaoSkillParse;
   import mmo.interfaces.pet.data.GQMingYunBoYiSkillParse;
   import mmo.interfaces.pet.data.GQQiYuanSkillParse;
   import mmo.interfaces.pet.data.GQQunxingZhiyuSkillParse;
   import mmo.interfaces.pet.data.GQShenQiSkillParse;
   import mmo.interfaces.pet.data.GQShenXuSkillParse;
   import mmo.interfaces.pet.data.GQShenYuTianGangSkillParse;
   import mmo.interfaces.pet.data.GQShiKongFangZhuSkillParse;
   import mmo.interfaces.pet.data.GQTianYiSkillParse;
   import mmo.interfaces.pet.data.GQWanyuZhichaoSkillParse;
   import mmo.interfaces.pet.data.GQWumangXingjiSkillParse;
   import mmo.interfaces.pet.data.GQXingHuanShiSkillParse;
   import mmo.interfaces.pet.data.GQXingZhiYuSkillParse;
   import mmo.interfaces.pet.data.GQYanhuaZhiyaoGongmingZhongduanSkillParse;
   import mmo.interfaces.pet.data.GQYiRenWujinMingtuSkillParse;
   import mmo.interfaces.pet.data.GQYinghunYingjiemengyueSkillParse;
   import mmo.interfaces.pet.data.GQZhenLiFaDianSkillParse;
   import mmo.interfaces.pet.data.GQZhigaoRongyaoSkillParse;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.data.XHCheckerBoardSkillParse;
   import mmo.interfaces.pet.data.XHFaHuanSkillParse;
   import mmo.interfaces.pet.data.XHLunhuiShiyueSkillParse;
   import mmo.interfaces.pet.data.XHZhanJiSkillParse;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.operation.IPMSkillInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.layer.LayerManager;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.data.PetState;
   import mmo.petfightnew.common.data.PetType;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.handler.SkillTargetSelecter;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.panel.*;
   import mmo.petfightnew.common.panel.skill.big.BigSkillMC;
   import mmo.petfightnew.common.panel.skill.espskillpanel.XH_ShenLingExtraPanel;
   import mmo.petfightnew.common.panel.skill.small.EmptySkillMC;
   import mmo.petfightnew.common.panel.skill.small.SmallSkillMC;
   import mmo.petfightnew.common.useskill.NewOrderlySkillStrategy;
   import mmo.petfightnew.common.util.BSUtil;
   import mmo.petfightnew.common.util.GQPetHelper;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.petfightnew.common.util.XinghuiPetHelper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.petfight.common.config.SkillMap;
   import mmo.play.petfight.common.data.SkillType;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1066")]
   public class NewSkillPanel extends UIPanelBase implements IDispose
   {
      
      private static const TOTAL_SKILL_SLOT_NUM:int = 5;
      
      private static const MAX_SMALL_SKILL_NUM:int = 4;
      
      public var mcBG:MovieClip;
      
      public var mcBGFrame:MovieClip;
      
      public var mcChangeView:BigSkillMC;
      
      public var mcGQBg:MovieClip;
      
      public var mcGQSoulContainer:MovieClip;
      
      public var mcOverFrame:MovieClip;
      
      public var mcShenBingSkill:MovieClip;
      
      public var mcShenLingSkill:MovieClip;
      
      public var mcSmall:MovieClip;
      
      public var mcautouseskill:MovieClip;
      
      private var pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      private var petSkillMesService:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
      
      private var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
      
      private var mcAutoUseSkill:MovieClip;
      
      private var _autoUseSkillMCPosInLocal:Point;
      
      private var _autoUseSkillMCPosInGlobal:Point;
      
      private var _extraPassiveSkillList:Array = [];
      
      private var _myPassiveSkill:SkillInfo;
      
      private var _smallSkills:Array = [];
      
      private var _bigSkillMC:BigSkillMC;
      
      private var _skillMCPosList:Array = [];
      
      private var _skillMCStartPos:int = 0;
      
      private var _smallSkillMCList:Array = [];
      
      private var _emptySkillMCList:Array = [];
      
      private var _smallSkillMCContainer:Sprite;
      
      private var _extraSkillPanel:XinghuiExtraSkillPanel;
      
      private var _extraGQSkillpanel:GQExtraSkillPanel;
      
      private var _nianFeiExtSmallSkill:SkillInfo;
      
      private var _nianFeiSkillMC:SmallSkillMC;
      
      private var _petInfo:PetBriefInfo;
      
      private var _petType:int;
      
      private var _petState:int;
      
      private var _shenLingPanel:XH_ShenLingExtraPanel;
      
      private var _gqShenBingSkillMc:MovieClip;
      
      private var _gqShenBingSkillInfo:SkillInfo = null;
      
      private var _xianJingJiMc:MovieClip;
      
      private var _xianJingJiBtn:SimpleButton;
      
      private var _currTurnUpdate:int = -1;
      
      private var _skillIdArr:Array = [];
      
      public function NewSkillPanel()
      {
         super();
         this.init();
         this.update();
      }
      
      override public function dispose() : void
      {
         var _loc1_:SmallSkillMC = null;
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onAdd2Stage);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.END_AUTO_FIGHT,this.refreshAutoView);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.USE_SKILL,this.onUseSkill);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FightUseCustomSkill,this.fightUseCustomSkill);
         if(Boolean(this._xianJingJiBtn) && Boolean(this._xianJingJiBtn.parent))
         {
            this._xianJingJiBtn.removeEventListener(MouseEvent.CLICK,this.onClickXianJingJi);
         }
         this._xianJingJiBtn = null;
         UseBigSkillHandler.instance.cancelUse();
         if(this.mcAutoUseSkill)
         {
            this.mcAutoUseSkill.removeEventListener(MouseEvent.CLICK,this.changeBtnState);
            DisplayUtil.stopAndRemove(this.mcAutoUseSkill);
         }
         for each(_loc1_ in this._smallSkillMCList)
         {
            _loc1_.cancelUse();
            _loc1_.dispose();
            DisplayUtil.stopAndRemove(_loc1_);
         }
         this._smallSkillMCList.length = 0;
         this._smallSkillMCList = null;
         this._bigSkillMC.dispose();
         this._bigSkillMC = null;
         if(this._shenLingPanel)
         {
            this._shenLingPanel.dispose();
            this._shenLingPanel = null;
         }
      }
      
      override public function update() : void
      {
         this._petInfo = this.getOperatingPetInfo();
         this.resetVars();
         this.parseSkills();
         this.refreshBG();
         this._skillIdArr = [];
         var _loc1_:Array = [];
         this._bigSkillMC.update();
         var _loc2_:PMSkill = GQPetHelper.getGQPetBigSkill(this._petInfo);
         if(_loc2_)
         {
            this._skillIdArr.push(_loc2_.skillId);
            _loc1_.push(this._bigSkillMC.cachedView);
         }
         this.refreshSmallSkillMC(this._skillIdArr,_loc1_);
         if(this._skillIdArr.length > 0 && _loc1_.length > 0 && this._currTurnUpdate != FightController.instance.turnCount)
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FIGHT_SKILL_OBJECT_UPDATE,{
               "skillIds":this._skillIdArr,
               "skillMcs":_loc1_
            }));
            this._currTurnUpdate = FightController.instance.turnCount;
         }
         this.refreshNianFei2021ExtSkill();
         this.refreshExtraPassiveSkill();
         this.refreshAutoView();
         this._shenLingPanel.update(this._petInfo);
         this.refreshGQSoul();
         this.refreshXianJingJiSkill();
      }
      
      private function resetVars() : void
      {
         this._petType = PetType.getPetType(this._petInfo);
         this._petState = PetState.getPetState(this._petInfo);
         var _loc1_:PMData = this.pmService.getOperationPM(this._petInfo.raceId).pmData;
         if(_loc1_.getDegeneratorType() == DegeneratorPetType.SHEN && _loc1_.ShenRaceId < 0)
         {
            this._skillMCStartPos = 1;
         }
         else
         {
            this._skillMCStartPos = 0;
         }
      }
      
      private function initSkillMCPosList() : void
      {
         var _loc1_:DisplayObject = null;
         this._petInfo = this.getOperatingPetInfo();
         this._smallSkillMCContainer = this.getChildByName("mcSmall") as Sprite;
         var _loc2_:int = 0;
         while(_loc2_ < TOTAL_SKILL_SLOT_NUM)
         {
            _loc1_ = this._smallSkillMCContainer.getChildByName("attHD" + _loc2_);
            this._skillMCPosList[_loc2_] = new Point(_loc1_.x,_loc1_.y);
            DisplayUtil.stopAndRemove(_loc1_);
            _loc2_++;
         }
      }
      
      private function init() : void
      {
         var _loc1_:Class = null;
         var _loc2_:MovieClip = null;
         this.initSkillMCPosList();
         this.initMCChangeViewWithCatchError();
         this.initListeners();
         if(this.stage == null)
         {
            this.addEventListener(Event.ADDED_TO_STAGE,this.onAdd2Stage);
         }
         else
         {
            this.initAutoUseSkillMC();
         }
         this._shenLingPanel = new XH_ShenLingExtraPanel(this.getChildByName("mcShenLingSkill") as MovieClip);
         this._gqShenBingSkillMc = this.getChildByName("mcShenBingSkill") as MovieClip;
         this._xianJingJiMc = this.getChildByName("mcXianJingJi") as MovieClip;
         if(this._xianJingJiMc == null)
         {
            _loc1_ = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.common.panel.view.GQXianJingJiMc") as Class;
            _loc2_ = new _loc1_() as MovieClip;
            _loc2_.name = "mcXianJingJi";
            _loc2_.x = -105.2;
            _loc2_.y = 345.1;
            this.addChild(_loc2_);
            this._xianJingJiMc = _loc2_;
         }
      }
      
      private function onAdd2Stage(param1:Event) : void
      {
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onAdd2Stage);
         this.initAutoUseSkillMC();
      }
      
      private function initAutoUseSkillMC() : void
      {
         this.mcAutoUseSkill = this.getChildByName("mcautouseskill") as MovieClip;
         this.mcAutoUseSkill.addEventListener(MouseEvent.CLICK,this.changeBtnState);
         this._autoUseSkillMCPosInLocal = new Point(this.mcAutoUseSkill.x,this.mcAutoUseSkill.y);
         this._autoUseSkillMCPosInGlobal = this.mcAutoUseSkill.localToGlobal(new Point());
         this.refreshAutoView();
      }
      
      private function initListeners() : void
      {
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.END_AUTO_FIGHT,this.refreshAutoView);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.USE_SKILL,this.onUseSkill);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FightUseCustomSkill,this.fightUseCustomSkill);
      }
      
      public function show() : void
      {
      }
      
      private function onNextTurn(param1:PetFightEvent) : void
      {
         this.getOperatingPetInfo().getXingHuiChuangShuoParser().isUseSkillThisTurn = false;
         this._bigSkillMC.update();
      }
      
      private function onUseSkill(param1:PetFightEvent) : void
      {
         var _loc2_:PlayerBattleInfo = param1.params.playerInfo;
         var _loc3_:int = int(param1.params.skillId);
         if(_loc2_ == null || _loc2_.PMMasterId < 0 || _loc2_.PMMasterId != FightData.instance.myInfo.PMMasterId)
         {
            return;
         }
         var _loc4_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         if(Boolean(_loc4_.isSummoned()) || _loc4_.PMMasterId < 0)
         {
            return;
         }
         if(this.checkIsBigKill(_loc3_) || this.checkIsSuperSpiriteSkill(_loc3_))
         {
            this.initMCChangeViewWithCatchError();
         }
         this._bigSkillMC.setMouseRollOut();
      }
      
      private function refreshAutoView(param1:PetFightEvent = null) : void
      {
         var _loc2_:Point = null;
         if(this.mcAutoUseSkill == null)
         {
            return;
         }
         if(FightController.instance.useAiType == 2)
         {
            this.mcAutoUseSkill.gotoAndStop(2);
            if(this.contains(this.mcAutoUseSkill) && !FightController.instance.isReplay)
            {
               _loc2_ = this._autoUseSkillMCPosInGlobal;
               LayerManager.getFightingTop().addChildAt(this.mcAutoUseSkill,this.getFightPanelIndex() + 1);
            }
         }
         else if(FightController.instance.useAiType == 3)
         {
            this.mcAutoUseSkill.gotoAndStop(1);
            if(this.contains(this.mcAutoUseSkill) && !FightController.instance.isReplay)
            {
               _loc2_ = this._autoUseSkillMCPosInGlobal;
               LayerManager.getFightingTop().addChildAt(this.mcAutoUseSkill,this.getFightPanelIndex() + 1);
            }
         }
         else if(FightController.isAutoUseSkill)
         {
            this.mcAutoUseSkill.gotoAndStop(2);
            if(this.contains(this.mcAutoUseSkill) && !FightController.instance.isReplay)
            {
               _loc2_ = this._autoUseSkillMCPosInGlobal;
               LayerManager.getFightingTop().addChildAt(this.mcAutoUseSkill,this.getFightPanelIndex() + 1);
            }
         }
         else
         {
            this.mcAutoUseSkill.gotoAndStop(1);
            if(!this.contains(this.mcAutoUseSkill))
            {
               _loc2_ = this._autoUseSkillMCPosInLocal;
               this.addChildAt(this.mcAutoUseSkill,0);
            }
         }
         if(_loc2_ != null)
         {
            this.mcAutoUseSkill.x = _loc2_.x;
            this.mcAutoUseSkill.y = _loc2_.y;
         }
         this.mcAutoUseSkill.mouseEnabled = !FightController.instance.isAuto && FightController.instance.useAiType != 2 && FightController.instance.useAiType != 3;
         this.mcAutoUseSkill.mouseChildren = !FightController.instance.isAuto && FightController.instance.useAiType != 2 && FightController.instance.useAiType != 3;
         if(!FightController.instance.canAuto)
         {
            this.mcAutoUseSkill.mouseEnabled = this.mcAutoUseSkill.mouseChildren = false;
            ActComHelper.refreshObj(this.mcAutoUseSkill.parent,this.mcAutoUseSkill.name,true);
         }
         else if(FightData.instance.isPVPForceAuto)
         {
            FightController.isAutoUseSkill = true;
            this.mcAutoUseSkill.gotoAndStop(2);
            this.mcAutoUseSkill.mouseEnabled = this.mcAutoUseSkill.mouseChildren = false;
         }
      }
      
      private function refreshGQSoul() : void
      {
         var _loc3_:MovieClip = null;
         var _loc4_:MovieClip = null;
         var _loc5_:int = 0;
         var _loc6_:MovieClip = null;
         var _loc7_:GQGuangJinSkillParse = null;
         var _loc1_:MovieClip = this.getChildByName("mcGQSoulContainer") as MovieClip;
         _loc1_.mouseEnabled = _loc1_.mouseChildren = false;
         if(!GQPetHelper.checkIsGQPet(this._petInfo.raceId))
         {
            _loc1_.visible = false;
            return;
         }
         _loc1_.visible = true;
         var _loc2_:PMData = this.pmService.getOperationPM(this._petInfo.raceId).pmData;
         if(StatusUtil.getIsAtMiBaoStrollState(this._petInfo))
         {
            this.refreshMiBaoGQSoul(_loc1_);
         }
         else if(StatusUtil.getHunDunJueDouHp(this._petInfo) >= 0)
         {
            _loc1_.gotoAndStop(3);
            ActComHelper.setMcNum(_loc1_,"mcNum",StatusUtil.getHunDunJueDouHp(this._petInfo));
         }
         else if(StatusUtil.getIsInYuXiangState(this._petInfo))
         {
            _loc1_.gotoAndStop(4);
            ActComHelper.setMcNum(_loc1_,"mcnum",this._petInfo.curGQSoulNum);
            ActComHelper.setMcNum(_loc1_,"mcmax",20);
         }
         else
         {
            _loc1_.gotoAndStop(1);
            _loc3_ = _loc1_.getChildByName("mcSoulNum") as MovieClip;
            ArtNumberManager.setNumber([_loc3_],this._petInfo.curGQSoulNum);
            _loc4_ = _loc1_.getChildByName("mcGuangjinLock") as MovieClip;
            _loc5_ = int(_loc2_.maxGQSoulNum);
            if(GQPetType.isGuangJin(_loc2_.getGQType()))
            {
               _loc7_ = GQGuangJinSkillParse.getGuangJinSkillData(this._petInfo.raceId);
               _loc5_ -= _loc7_.getUseSkillTimes(this._petInfo);
               _loc5_ = Math.max(_loc5_,0);
               _loc4_.visible = GQGuangJinSkillParse.getGuangJinSkillData(this._petInfo.raceId).getUseSkillTimes(this._petInfo) > 0;
            }
            else
            {
               _loc4_.visible = false;
            }
            _loc6_ = _loc1_.getChildByName("mcMaxSoulNum") as MovieClip;
            ArtNumberManager.setNumber([_loc6_],_loc5_);
         }
      }
      
      private function refreshXianJingJiSkill() : void
      {
         var _loc2_:Object = null;
         var _loc3_:MovieClip = null;
         var _loc4_:PMSkill = null;
         var _loc5_:String = null;
         var _loc6_:String = null;
         var _loc1_:Object = BSUtil.parseXianJingJi(FightData.instance.curBs);
         if(_loc1_.skillId <= 0)
         {
            this._xianJingJiMc.visible = false;
         }
         else
         {
            this._xianJingJiMc.visible = true;
            _loc2_ = GQPetType.getXianJingJiObject(PetAssetsMap.getPetFlaId(_loc1_.raceId));
            if(_loc2_)
            {
               this._xianJingJiMc.gotoAndStop(_loc2_.extraSkillFrame);
            }
            else
            {
               this._xianJingJiMc.gotoAndStop(1);
            }
            _loc3_ = this._xianJingJiMc.getChildByName("mcSubXianJingJi") as MovieClip;
            _loc4_ = this.pmService.customData.pmSkillMap.getSkill(_loc1_.skillId);
            if(this._gameOptionSvr.isGQSimpleSkillView)
            {
               _loc5_ = _loc4_.oldEffectDesc;
            }
            else
            {
               _loc5_ = _loc4_.clientDesc;
            }
            _loc6_ = _loc4_.newCnName;
            if(_loc1_.curCD > 0)
            {
               ActComHelper.refreshObj(_loc3_,"",false,"",_loc1_.curCD + "回合后可使用！",_loc1_.curCD + 1);
            }
            else if(FightData.instance.myInfo.isSkillUsed(this._petInfo.id,_loc1_.skillId))
            {
               ActComHelper.refreshObj(_loc3_,"",false,"","本回合已用",_loc3_.totalFrames);
            }
            else
            {
               ActComHelper.refreshObj(_loc3_,"",false,"","",1);
               this._xianJingJiBtn = _loc3_.getChildByName("btnXianJingJi") as SimpleButton;
               TipsManager.getInstance().replaceComplexTips(this._xianJingJiBtn,_loc6_,_loc5_,100,-100,9);
               this._xianJingJiBtn.addEventListener(MouseEvent.CLICK,this.onClickXianJingJi);
            }
         }
      }
      
      private function refreshMiBaoGQSoul(param1:MovieClip) : void
      {
         param1.gotoAndStop(2);
         var _loc2_:Object = GQPetType.getMiBaoObject(this._petInfo.raceId);
         var _loc3_:int = _loc2_ == null ? 1 : int(_loc2_["iconFrame"]);
         var _loc4_:MovieClip = param1.getChildByName("mcItem") as MovieClip;
         if(_loc4_)
         {
            _loc4_.gotoAndStop(_loc3_);
            ActComHelper.setTxtValue(_loc4_,"txtCurNum",this._petInfo.curGQSoulNum + "/99");
            ActComHelper.setMcNum(_loc4_,"mcnum",this._petInfo.curGQSoulNum);
            ActComHelper.setMcNum(_loc4_,"mcmax",99);
         }
      }
      
      override public function setClickable(param1:Boolean) : void
      {
         var _loc2_:SmallSkillMC = null;
         for each(_loc2_ in this._smallSkillMCList)
         {
            _loc2_.enabled = param1;
         }
         this._bigSkillMC.clickable = param1;
         if(Boolean(this._xianJingJiBtn) && Boolean(this._xianJingJiBtn.parent))
         {
            this._xianJingJiBtn.enabled = param1;
         }
         var _loc3_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FightSkillStateChange,{
            "clickable":param1,
            "locaId":_loc3_.locaId
         }));
      }
      
      private function getFightPanelIndex() : int
      {
         var _loc1_:int = -1;
         var _loc2_:int = 0;
         while(_loc2_ < LayerManager.getFightingTop().numChildren)
         {
            if(LayerManager.getFightingTop().getChildAt(_loc2_) is FightPanel)
            {
               _loc1_ = _loc2_;
               break;
            }
            _loc2_++;
         }
         return _loc1_;
      }
      
      private function changeBtnState(param1:MouseEvent) : void
      {
         FightController.isAutoUseSkill = !FightController.isAutoUseSkill;
         PetClient.instance.autoUseAI(FightController.isAutoUseSkill ? 1 : 0);
         if(!FightController.isAutoUseSkill)
         {
            CommonEventDispatcher.instance.dispatchEvent(new Event("newlearn_on_fight_auto_close"));
            PetClient.instance.changeAutoUseSkillState(false);
         }
         NewOrderlySkillStrategy.reset();
         this.refreshAutoView();
      }
      
      private function onClickXianJingJi(param1:MouseEvent) : void
      {
         var _loc2_:Object = BSUtil.parseXianJingJi(FightData.instance.curBs);
         if(_loc2_.skillId > 0 && _loc2_.curCD <= 0)
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FightUseCustomSkill,{"skillId":_loc2_.skillId}));
         }
      }
      
      private function refreshBG() : void
      {
         var _loc1_:int = PetType.getPetType(this._petInfo);
         var _loc2_:Boolean = _loc1_ != PetType.DEGENERATOR && _loc1_ != PetType.XINGHUI && _loc1_ != PetType.GQ;
         var _loc3_:Sprite = this.getChildByName("mcOverFrame") as Sprite;
         _loc3_.visible = _loc2_;
         var _loc4_:Sprite = this.getChildByName("mcBG") as Sprite;
         _loc4_.visible = _loc1_ != PetType.XINGHUI && _loc1_ != PetType.GQ;
         _loc4_.mouseEnabled = _loc4_.mouseChildren = false;
         var _loc5_:Sprite = this.getChildByName("mcBGFrame") as Sprite;
         _loc5_.visible = _loc2_;
         _loc5_.mouseEnabled = _loc5_.mouseChildren = false;
         var _loc6_:Sprite = this.getChildByName("mcGQBg") as Sprite;
         _loc6_.visible = _loc1_ == PetType.GQ;
         _loc6_.mouseEnabled = _loc6_.mouseChildren = false;
      }
      
      private function refreshExtraPassiveSkill() : void
      {
         var _loc1_:PMData = this.pmService.getOperationPM(this._petInfo.raceId).pmData;
         var _loc2_:Array = [];
         var _loc3_:int = int(_loc1_.getXinghuiType());
         if(this.extraSkillEspHandle(_loc3_))
         {
            return;
         }
         if(_loc1_.getXinghuiType() == XinghuiPetType.SP_AND_CHAOWEI)
         {
            _loc2_ = this._extraPassiveSkillList.concat(this._myPassiveSkill);
         }
         else if(_loc1_.getXinghuiType() == XinghuiPetType.SHENQI_QIYUAN)
         {
            _loc2_ = this._extraPassiveSkillList.concat(this._myPassiveSkill);
         }
         else if(_loc1_.getXinghuiType() == XinghuiPetType.DOUBLEGOD_AND_SP || _loc1_.getXinghuiType() == XinghuiPetType.DOUBLEGOD_AND_SHEN_LI)
         {
            _loc2_ = this._extraPassiveSkillList.concat(this._myPassiveSkill);
         }
         else if(XinghuiPetType.getIsSpecialWangzhePetByRaceid(this._petInfo.raceId))
         {
            if(this._petInfo.getGongmingArr().length == 0 || this._petInfo.getGongmingArr()[0] == -1)
            {
               _loc2_ = this._extraPassiveSkillList;
            }
            else
            {
               _loc2_ = this._extraPassiveSkillList.concat(this._myPassiveSkill);
            }
         }
         else if(_loc1_.getXinghuiType() == XinghuiPetType.QIYUAN || _loc1_.getXinghuiType() == XinghuiPetType.WANGZHE || _loc1_.getXinghuiType() == XinghuiPetType.SHENQI || _loc1_.getXinghuiType() == XinghuiPetType.LINGHUN || _loc1_.getXinghuiType() == XinghuiPetType.WAN_WU_JU_YUAN || _loc1_.getXinghuiType() == XinghuiPetType.CHAOWEI || _loc1_.getXinghuiType() == XinghuiPetType.WANGZHE_REAL || _loc1_.getXinghuiType() == XinghuiPetType.SHEN_WANGZHE_REAL || _loc1_.getXinghuiType() == XinghuiPetType.JIBANQIYUAN || _loc1_.getXinghuiType() == XinghuiPetType.LIUWEIYITI || _loc1_.getXinghuiType() == XinghuiPetType.SHENYUANHUIXIANG || _loc1_.getXinghuiType() == XinghuiPetType.JUEXING || _loc1_.getXinghuiType() == XinghuiPetType.ZHENGNI_JIBAN || Boolean(XinghuiPetType.isSpPet(_loc1_.getXinghuiType())) || Boolean(XinghuiPetType.isChuanShuo(_loc1_.getXinghuiType())) || _loc1_.getXinghuiType() == XinghuiPetType.SHEN_LI || _loc1_.getXinghuiType() == XinghuiPetType.ZHAN_YI || Boolean(XinghuiPetType.isShiflePro(_loc1_
         .getXinghuiType())) || Boolean(XinghuiPetType.isShenLingPassive(_loc1_.getXinghuiType())) || Boolean(XinghuiPetType.isTongLing(_loc1_.getXinghuiType())) || Boolean(XinghuiPetType.isANNUAL_FEE_22(_loc1_.getXinghuiType())) || Boolean(XinghuiPetType.isZhanJiType(_loc1_.getXinghuiType())) || _loc1_.getXinghuiType() == XinghuiPetType.SHEN_CHAOWEI || _loc1_.getXinghuiType() == XinghuiPetType.SHEN_LINGHUN || _loc1_.getXinghuiType() == XinghuiPetType.FA_HUAN || _loc1_.getXinghuiType() == XinghuiPetType.LUNHUI_SHIYUE || Boolean(GQPetType.isEternityContract(_loc1_.getGQType())) || Boolean(GQPetType.isMingZuo(_loc1_.getGQType())) || Boolean(GQPetType.isChaoWei(_loc1_.getGQType())) || Boolean(GQPetType.isOutburstCopy(_loc1_.getGQType())) || Boolean(GQPetType.isTianYi(_loc1_.getGQType())) || Boolean(GQPetType.isShengHun(_loc1_.getGQType())) || Boolean(GQPetType.isQuanNeng(_loc1_.getGQType())) || Boolean(GQPetType.isXingyueTongxing(_loc1_.getGQType())) || Boolean(GQPetType.isMenghuanDiyue(_loc1_.getGQType())) || Boolean(GQPetType
         .isShuangShenGe(_loc1_.getGQType())) || Boolean(GQPetType.isYuXiangShi(_loc1_.getGQType())))
         {
            _loc2_ = this._extraPassiveSkillList;
         }
         else if(_loc1_.getXinghuiType() == XinghuiPetType.DOUBLEGOD)
         {
            _loc2_ = [this._myPassiveSkill];
         }
         if((Boolean(XinghuiPetType.isSpPet(_loc1_.getXinghuiType())) || Boolean(GQPetType.isMingZuo(_loc1_.getGQType())) || Boolean(GQPetType.isShenYuTianGang(_loc1_.getGQType()))) && _loc2_.length <= 0)
         {
            _loc2_ = [null];
         }
         if(_loc2_.length > 0)
         {
            this.extraSkillSetSkill(_loc2_);
         }
         else
         {
            if(this._extraSkillPanel != null && this._extraSkillPanel.parent != null)
            {
               this._extraSkillPanel.parent.removeChild(this._extraSkillPanel);
            }
            if(this._extraGQSkillpanel != null && this._extraGQSkillpanel.parent != null)
            {
               this._extraGQSkillpanel.parent.removeChild(this._extraGQSkillpanel);
            }
         }
      }
      
      private function newExtraSkillPanel() : void
      {
         if(PetType.isXinghuiPet(this._petType))
         {
            if(this._extraSkillPanel == null)
            {
               this._extraSkillPanel = new XinghuiExtraSkillPanel();
               this._extraSkillPanel.x = -6.3;
               this._extraSkillPanel.y = 265.96;
            }
            this.addChild(this._extraSkillPanel);
            if(this._extraGQSkillpanel != null && this._extraGQSkillpanel.parent != null)
            {
               this._extraGQSkillpanel.parent.removeChild(this._extraGQSkillpanel);
            }
         }
         else
         {
            if(this._extraGQSkillpanel == null)
            {
               this._extraGQSkillpanel = new GQExtraSkillPanel();
               this._extraGQSkillpanel.x = -6.3;
               this._extraGQSkillpanel.y = 273.96;
            }
            this.addChild(this._extraGQSkillpanel);
            if(this._extraSkillPanel != null && this._extraSkillPanel.parent != null)
            {
               this._extraSkillPanel.parent.removeChild(this._extraSkillPanel);
            }
         }
      }
      
      private function extraSkillSetSkill(param1:Array) : void
      {
         this.newExtraSkillPanel();
         if(PetType.isXinghuiPet(this._petType))
         {
            this._extraSkillPanel.setSkill(this._petInfo,param1);
         }
         else
         {
            this._extraGQSkillpanel.setSkill(this._petInfo,param1);
         }
      }
      
      private function extraSkillEspHandle(param1:int) : Boolean
      {
         var _loc2_:Array = [XinghuiPetType.CHECKER_BOARD];
         if(_loc2_.indexOf(param1) == -1)
         {
            return false;
         }
         this.newExtraSkillPanel();
         this._extraSkillPanel.espHandle(this._petInfo);
         return true;
      }
      
      private function refreshSmallSkillMC(param1:Array, param2:Array) : void
      {
         var _loc5_:SmallSkillMC = null;
         var _loc6_:EmptySkillMC = null;
         var _loc12_:int = 0;
         var _loc13_:Point = null;
         var _loc14_:PMSkill = null;
         var _loc15_:GQShenBingObj = null;
         var _loc3_:Array = this._smallSkills;
         var _loc4_:SkillInfo = null;
         var _loc7_:Array = [];
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         this.hundunSortTail();
         this.sortGQSkill();
         var _loc11_:int = 0;
         while(_loc11_ < MAX_SMALL_SKILL_NUM)
         {
            _loc4_ = _loc3_[_loc11_];
            _loc12_ = this._skillMCStartPos + _loc11_;
            _loc13_ = this._skillMCPosList[_loc12_];
            if(_loc4_ == null)
            {
               if(_loc12_ < MAX_SMALL_SKILL_NUM)
               {
                  if(this._emptySkillMCList[_loc9_] == null)
                  {
                     this._emptySkillMCList[_loc9_] = FightMcPool.instance.getRes(EmptySkillMC,true);
                     this._smallSkillMCContainer.addChild(this._emptySkillMCList[_loc9_]);
                  }
                  _loc6_ = this._emptySkillMCList[_loc9_];
                  _loc6_.x = _loc13_.x;
                  _loc6_.y = _loc13_.y;
                  _loc6_.update(this._petInfo);
                  _loc7_.push(_loc6_);
               }
               _loc9_++;
               _loc10_ = MAX_SMALL_SKILL_NUM - _loc9_;
               if(this._smallSkillMCList[_loc10_] != null)
               {
                  FightMcPool.instance.recycle(this._smallSkillMCList[_loc10_]);
                  this._smallSkillMCList.splice(_loc10_,_loc11_);
               }
            }
            else
            {
               if(this._smallSkillMCList[_loc8_] == null)
               {
                  this._smallSkillMCList[_loc8_] = FightMcPool.instance.getRes(SmallSkillMC,true);
                  this._smallSkillMCContainer.addChild(this._smallSkillMCList[_loc8_]);
               }
               _loc5_ = this._smallSkillMCList[_loc8_];
               _loc5_.x = _loc13_.x;
               _loc14_ = this.pmService.customData.pmSkillMap.getSkill(_loc4_.id);
               if(PMSkillTypes.isGQSkill(_loc14_.getSkillType()))
               {
                  _loc5_.y = _loc13_.y + _loc11_ * 5;
               }
               else
               {
                  _loc5_.y = _loc13_.y;
               }
               _loc7_.push(_loc5_);
               _loc5_.setSkill(_loc4_,this._petInfo,this.refreshGQSoul);
               this._skillIdArr.push(_loc4_.id);
               param2.push(_loc5_);
               _loc8_++;
               _loc10_ = MAX_SMALL_SKILL_NUM - _loc8_;
               if(this._emptySkillMCList[_loc10_] != null)
               {
                  FightMcPool.instance.recycle(this._emptySkillMCList[_loc10_]);
                  this._emptySkillMCList.splice(_loc10_,_loc11_);
               }
            }
            _loc11_++;
         }
         if(this._gqShenBingSkillInfo == null)
         {
            this._gqShenBingSkillMc.stop();
            this._gqShenBingSkillMc.visible = false;
         }
         else
         {
            _loc15_ = GQShenBingObjHelper.getShenBingObjBySkillId(this._gqShenBingSkillInfo.id);
            this._gqShenBingSkillMc.visible = true;
            this._gqShenBingSkillMc.gotoAndStop(_loc15_.type);
            this.addSkillTips(this._gqShenBingSkillInfo,this._gqShenBingSkillMc);
         }
      }
      
      private function addSkillTips(param1:SkillInfo, param2:MovieClip) : void
      {
         var _loc3_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         var _loc4_:Object = _loc3_.getPetSkillMes(param1.id);
         var _loc5_:String = "(神兵祝福)";
         TipsManager.getInstance().addComplexTips(param2,_loc4_.pname + _loc5_,_loc4_.descriptor);
      }
      
      private function filterShenBingSkill(param1:Array) : SkillInfo
      {
         var _loc3_:PMSkill = null;
         var _loc2_:int = 0;
         while(_loc2_ < param1.length)
         {
            _loc3_ = this.pmService.customData.pmSkillMap.getSkill(param1[_loc2_].id);
            if(_loc3_.getSkillType() == PMSkillTypes.GQ_SHENBING_PASSIVE)
            {
               return param1.splice(_loc2_,1)[0];
            }
            _loc2_++;
         }
         return null;
      }
      
      private function removeFaZhenSkill(param1:Array) : Array
      {
         var _loc4_:SkillInfo = null;
         var _loc5_:int = 0;
         var _loc2_:Array = param1.concat();
         var _loc3_:int = int(_loc2_.length - 1);
         while(_loc3_ >= 0)
         {
            _loc4_ = _loc2_[_loc3_];
            _loc5_ = int(this.pmService.customData.pmSkillMap.getSkill(_loc4_.id).getSkillType());
            if(_loc5_ == PMSkillTypes.LING_YU_FA_ZHEN_SKILL)
            {
               _loc2_.splice(_loc3_,1);
            }
            _loc3_--;
         }
         return _loc2_;
      }
      
      private function removeShenLingSkill(param1:Array) : Array
      {
         var _loc4_:SkillInfo = null;
         var _loc5_:int = 0;
         var _loc2_:Array = param1.concat();
         var _loc3_:int = int(_loc2_.length - 1);
         while(_loc3_ >= 0)
         {
            _loc4_ = _loc2_[_loc3_];
            _loc5_ = int(this.pmService.customData.pmSkillMap.getSkill(_loc4_.id).getSkillType());
            if(_loc5_ == PMSkillTypes.SHENG_LING_PASSIVE)
            {
               this._extraPassiveSkillList.push(_loc4_);
               _loc2_.splice(_loc3_,1);
            }
            if(_loc5_ == PMSkillTypes.SHENG_LING_BUFF)
            {
               _loc2_.splice(_loc3_,1);
            }
            _loc3_--;
         }
         return _loc2_;
      }
      
      private function removeTongLingSkill(param1:Array) : Array
      {
         var _loc4_:SkillInfo = null;
         var _loc5_:int = 0;
         var _loc2_:Array = param1.concat();
         var _loc3_:int = int(_loc2_.length - 1);
         while(_loc3_ >= 0)
         {
            _loc4_ = _loc2_[_loc3_];
            _loc5_ = int(this.pmService.customData.pmSkillMap.getSkill(_loc4_.id).getSkillType());
            if(_loc5_ == PMSkillTypes.TONG_LING_PASSIVE)
            {
               this._extraPassiveSkillList.push(_loc4_);
               _loc2_.splice(_loc3_,1);
            }
            if(_loc5_ == PMSkillTypes.TONG_LING_ACTIVE)
            {
               _loc2_.splice(_loc3_,1);
            }
            _loc3_--;
         }
         return _loc2_;
      }
      
      private function removeAnnualFee22Skill(param1:Array) : Array
      {
         var _loc4_:SkillInfo = null;
         var _loc5_:int = 0;
         var _loc7_:int = 0;
         var _loc2_:Array = param1.concat();
         var _loc3_:Boolean = false;
         var _loc6_:int = int(_loc2_.length - 1);
         while(_loc6_ >= 0)
         {
            _loc4_ = _loc2_[_loc6_];
            _loc5_ = int(this.pmService.customData.pmSkillMap.getSkill(_loc4_.id).getSkillType());
            if(_loc5_ == PMSkillTypes.ANNUAL_FEE_22_ACTIVE)
            {
               _loc3_ = true;
            }
            if(_loc5_ == PMSkillTypes.ANNUAL_FEE_22_PASSIVE)
            {
               this._extraPassiveSkillList.push(_loc4_);
               _loc2_.splice(_loc6_,1);
            }
            if(_loc5_ == PMSkillTypes.ANNUAL_FEE_22_EIGHT_SKILL)
            {
               _loc2_.splice(_loc6_,1);
            }
            _loc6_--;
         }
         if(_loc3_)
         {
            _loc7_ = int(_loc2_.length - 1);
            while(_loc7_ >= 0)
            {
               _loc4_ = _loc2_[_loc7_];
               _loc5_ = int(this.pmService.customData.pmSkillMap.getSkill(_loc4_.id).getSkillType());
               if(_loc5_ == PMSkillTypes.XINGHUI_PASSIVE_SKILL)
               {
                  this._extraPassiveSkillList.push(_loc4_);
                  _loc2_.splice(_loc7_,1);
               }
               _loc7_--;
            }
         }
         return _loc2_;
      }
      
      private function removeShenHuanSkill(param1:Array) : Array
      {
         var _loc3_:SkillInfo = null;
         var _loc4_:int = 0;
         var _loc2_:Array = param1.concat();
         var _loc5_:int = int(_loc2_.length - 1);
         while(_loc5_ >= 0)
         {
            _loc3_ = _loc2_[_loc5_];
            _loc4_ = int(this.pmService.customData.pmSkillMap.getSkill(_loc3_.id).getSkillType());
            if(_loc4_ == PMSkillTypes.GQ_SHEN_HUAN_SKILL)
            {
               _loc2_.splice(_loc5_,1);
            }
            _loc5_--;
         }
         return _loc2_;
      }
      
      private function removeEternityContractSkill(param1:Array) : Array
      {
         var _loc3_:SkillInfo = null;
         var _loc4_:int = 0;
         var _loc2_:Array = param1.concat();
         var _loc5_:int = int(_loc2_.length - 1);
         while(_loc5_ >= 0)
         {
            _loc3_ = _loc2_[_loc5_];
            _loc4_ = int(this.pmService.customData.pmSkillMap.getSkill(_loc3_.id).getSkillType());
            if(_loc4_ == PMSkillTypes.GQ_ETERNITYCONTRACT_PASSIVE)
            {
               this._extraPassiveSkillList.push(_loc3_);
               _loc2_.splice(_loc5_,1);
            }
            if(_loc4_ == PMSkillTypes.GQ_ETERNITYCONTRACT_COMMON)
            {
               _loc2_.splice(_loc5_,1);
            }
            _loc5_--;
         }
         return _loc2_;
      }
      
      private function removeGQXingZhiYuSkill(param1:Array) : Array
      {
         var _loc4_:int = 0;
         var _loc5_:SkillInfo = null;
         var _loc6_:String = null;
         var _loc2_:Array = param1.concat();
         var _loc3_:GQXingZhiYuSkillParse = GQXingZhiYuSkillParse.getGQXingZhiYuSkillParse(this._petInfo.raceId);
         if(_loc3_)
         {
            _loc4_ = int(_loc2_.length - 1);
            while(_loc4_ >= 0)
            {
               _loc5_ = _loc2_[_loc4_];
               if(Boolean(_loc3_) && _loc3_.zhuanshuSkillIds.indexOf(_loc5_.id) != -1)
               {
                  _loc2_.splice(_loc4_,1);
               }
               for(_loc6_ in _loc3_.killBigSkillIdObj)
               {
                  if(_loc3_.killBigSkillIdObj[_loc6_].indexOf(_loc5_.id) != -1)
                  {
                     _loc2_.splice(_loc4_,1);
                     break;
                  }
               }
               _loc4_--;
            }
         }
         return _loc2_;
      }
      
      private function removeGQBuxiuLvtuSkill(param1:PetBriefInfo, param2:Array) : Array
      {
         var _loc3_:GQBuxiuLvtuSkillParse = GQBuxiuLvtuSkillParse.getBuxiuLvtuSkillData(this._petInfo.raceId);
         if(_loc3_)
         {
            param2 = _loc3_.removeSkill(param2,param1,StatusUtil.getIsBuxiuJixingState(this._petInfo));
         }
         return param2;
      }
      
      private function parseSkills() : void
      {
         var _loc16_:int = 0;
         var _loc17_:int = 0;
         var _loc18_:IPMSkillInfo = null;
         var _loc19_:IPMSkillInfo = null;
         this._smallSkills.length = 0;
         this._extraPassiveSkillList.length = 0;
         this._nianFeiExtSmallSkill = null;
         var _loc1_:Array = XHCheckerBoardSkillParse.removeCheckerBoardSkill(this._petInfo).concat();
         this._gqShenBingSkillInfo = this.filterShenBingSkill(_loc1_);
         _loc1_ = this.removeXingHuiChuanShuoSkill(_loc1_);
         _loc1_ = this.removeXingHuiHuanXiangSkill(_loc1_);
         _loc1_ = this.removeEWaiTeJiSkill(_loc1_);
         _loc1_ = this.removeFaZhenSkill(_loc1_);
         _loc1_ = this.removeShenLingSkill(_loc1_);
         _loc1_ = this.removeTongLingSkill(_loc1_);
         _loc1_ = this.removeAnnualFee22Skill(_loc1_);
         _loc1_ = this.removeShenHuanSkill(_loc1_);
         _loc1_ = XHZhanJiSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = XHFaHuanSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = XHLunhuiShiyueSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = this.removeEternityContractSkill(_loc1_);
         _loc1_ = GQArmorBurstSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQLianSuoSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQGuangJinSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQQiYuanSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQTianYiSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQQunxingZhiyuSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQYiRenWujinMingtuSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQShenXuSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQDiJieShiSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQXingZhiYuSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = this.removeGQXingZhiYuSkill(_loc1_);
         _loc1_ = GQJueXingSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQYinghunYingjiemengyueSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQWumangXingjiSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQEternityZhanyiSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQShenQiSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQYanhuaZhiyaoGongmingZhongduanSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQZhigaoRongyaoSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQMiBaoSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQMingYunBoYiSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQJiuRiChongXianSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQHuanLingShiSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQXingHuanShiSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQDengShenChangJieSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQWanyuZhichaoSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = this.removeGQBuxiuLvtuSkill(this._petInfo,_loc1_);
         _loc1_ = GQHunDunJueDouSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQShiKongFangZhuSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQJiangShenSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQShenYuTianGangSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQZhenLiFaDianSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         _loc1_ = GQLieJieZhiXiSkillParse.removeSkill(this._petInfo.raceId,_loc1_);
         var _loc2_:PetBriefInfo = this.getOperatingPetInfo();
         var _loc3_:PMData = this.pmService.getOperationPM(_loc2_.raceId).pmData;
         var _loc4_:Array = [];
         var _loc5_:Array = [];
         var _loc6_:Array = [];
         var _loc7_:Array = [];
         var _loc8_:Array = [];
         var _loc9_:Array = [];
         var _loc10_:Array = [];
         var _loc11_:Array = [];
         var _loc12_:Vector.<IPMSkillInfo> = this.pmService.getOperationPM(this.getOperatingPetInfo().raceId).getCommonSkillList();
         var _loc13_:SkillInfo = null;
         var _loc14_:Array = [];
         var _loc15_:int = 0;
         while(_loc15_ < _loc1_.length)
         {
            _loc13_ = _loc1_[_loc15_];
            _loc16_ = int(_loc13_.id);
            _loc17_ = int(this.pmService.customData.pmSkillMap.getSkill(_loc16_).getSkillType());
            if(!this.checkIsBigKill(_loc16_))
            {
               if(_loc17_ == PMSkillTypes.XINGHUI_MING_XING_EXT_SMALL_SKILL)
               {
                  this._nianFeiExtSmallSkill = _loc13_;
               }
               else if(Boolean(XinghuiPetType.isSpPet(_loc3_.getXinghuiType())) && _loc17_ == SkillType.XINGHUI_SUPER_SPIRIT_TEJI)
               {
                  if(_loc3_.getXinghuiType() != XinghuiPetType.SP_WANGZHE)
                  {
                     if(_loc14_.length <= 0)
                     {
                        _loc14_.push(_loc13_);
                     }
                  }
               }
               else if(this.checkIsCommonSpritePoSkill(_loc16_) || this.checkIsSuperSpiriteSkill(_loc16_))
               {
                  if(_loc17_ == PMSkillTypes.XINGHUI_WANGZHE_SPIRIT_TEJI && !XinghuiPetType.isFuBloodPet(_loc3_.getXinghuiType()))
                  {
                     for each(_loc18_ in _loc12_)
                     {
                        if(this.checkIsSuperSpiriteSkill(_loc18_.skillId))
                        {
                           if(ArrayUtil.arrayContainsValue(this.pmService.customData.pmSkillMap.getSkill(_loc18_.skillId).skillSerials,_loc16_))
                           {
                              _loc4_.unshift(_loc13_);
                           }
                           break;
                        }
                     }
                  }
                  else
                  {
                     _loc4_.unshift(_loc13_);
                  }
               }
               else if(this.checkIsYuNotBigSkill(_loc16_))
               {
                  _loc5_.unshift(_loc13_);
               }
               else if(this.checkIsDoublegodSkill(_loc16_))
               {
                  _loc7_.push(_loc13_);
               }
               else if(this.checkIsQiyuanPassiveSkill(_loc16_))
               {
                  _loc9_.unshift(_loc13_);
                  this._extraPassiveSkillList.push(_loc13_);
               }
               else if(this.checkIsWangzheRealPassiveSkill(_loc16_))
               {
                  _loc10_.unshift(_loc13_);
                  this._extraPassiveSkillList.push(_loc13_);
               }
               else if(this.checkIsWangzheRealExtPassiveSkill(_loc16_))
               {
                  _loc10_.push(_loc13_);
               }
               else if(this.checkIsWangzheRealExtSkill(_loc16_))
               {
                  _loc10_.push(_loc13_);
               }
               else if(this.checkIsJuexingExtSkill(_loc16_))
               {
                  this._extraPassiveSkillList.push(_loc13_);
               }
               else if(this.checkIsXingHuiSpPassiveSkill(_loc16_))
               {
                  this._extraPassiveSkillList.push(_loc13_);
               }
               else if(this.checkIsShenliExtSkill(_loc16_))
               {
                  this._extraPassiveSkillList.push(_loc13_);
               }
               else if(this.checkIsZhanYiSkill(_loc16_))
               {
                  this._extraPassiveSkillList.push(_loc13_);
               }
               else if(this.checkIsShifleProExtSkill(_loc16_))
               {
                  this._extraPassiveSkillList.push(_loc13_);
               }
               else if(this.checkIsZhanJiPassiveSkill(_loc16_))
               {
                  this._extraPassiveSkillList.push(_loc13_);
               }
               else if(this.checkIsFaHuanPassiveSkill(_loc16_))
               {
                  this._extraPassiveSkillList.push(_loc13_);
               }
               else if(this.checkIsLunhuiQiYuePassiveSkill(_loc16_))
               {
                  this._extraPassiveSkillList.push(_loc13_);
               }
               else if(PMSkillTypes.getIsGQConditionSkill(_loc17_))
               {
                  this._extraPassiveSkillList.push(_loc13_);
               }
               else if(this.checkIsOtherGQExtraSkill(_loc16_))
               {
                  this._extraPassiveSkillList.push(_loc13_);
               }
               else if(this.checkIsPassiveSkill(_loc16_))
               {
                  _loc8_.push(_loc13_);
                  for each(_loc19_ in _loc12_)
                  {
                     if(this.checkIsPassiveSkill(_loc19_.skillId))
                     {
                        if(!ArrayUtil.arrayContainsValue(this.pmService.customData.pmSkillMap.getSkill(_loc19_.skillId).skillSerials,_loc16_))
                        {
                           if(_loc3_.getXinghuiType() == XinghuiPetType.WAN_WU_JU_YUAN_AND_SP)
                           {
                              this._extraPassiveSkillList.push(_loc13_);
                              break;
                           }
                           if(_loc3_.getXinghuiType() == XinghuiPetType.SP_AND_CHAOWEI || _loc3_.getXinghuiType() == XinghuiPetType.ZHENGNI_JIBAN || _loc3_.getXinghuiType() == XinghuiPetType.SP_WANGZHE)
                           {
                              this._extraPassiveSkillList.push(_loc13_);
                              break;
                           }
                           if(!XinghuiPetType.isSpPet(_loc3_.getXinghuiType()))
                           {
                              this._extraPassiveSkillList.push(_loc13_);
                           }
                           break;
                        }
                        this._myPassiveSkill = _loc13_;
                        break;
                     }
                  }
               }
               else
               {
                  _loc6_.unshift(_loc13_);
               }
            }
            _loc15_++;
         }
         _loc6_.sortOn("id",Array.NUMERIC);
         this._smallSkills = this._smallSkills.concat(_loc14_).concat(_loc4_).concat(_loc5_).concat(_loc6_).concat(_loc7_).concat(_loc8_).concat(_loc9_).concat(_loc10_).concat(_loc11_);
      }
      
      private function refreshNianFei2021ExtSkill() : void
      {
         var _loc1_:Point = this._skillMCPosList[this._skillMCPosList.length - 1];
         if(this._nianFeiExtSmallSkill == null)
         {
            if(this._nianFeiSkillMC)
            {
               FightMcPool.instance.recycle(this._nianFeiSkillMC);
               this._nianFeiSkillMC = null;
            }
         }
         else
         {
            if(this._nianFeiSkillMC == null)
            {
               this._nianFeiSkillMC = FightMcPool.instance.getRes(SmallSkillMC,true) as SmallSkillMC;
            }
            this._nianFeiSkillMC.x = _loc1_.x;
            this._nianFeiSkillMC.y = _loc1_.y;
            this._nianFeiSkillMC.setSkill(this._nianFeiExtSmallSkill,this._petInfo);
            this._smallSkillMCContainer.addChild(this._nianFeiSkillMC);
         }
      }
      
      private function removeXingHuiChuanShuoSkill(param1:Array) : Array
      {
         var _loc6_:int = 0;
         var _loc7_:SkillInfo = null;
         var _loc9_:int = 0;
         var _loc10_:Array = null;
         var _loc2_:PetBriefInfo = this.getOperatingPetInfo();
         var _loc3_:PMData = this.pmService.getOperationPM(_loc2_.raceId).pmData;
         if(!XinghuiPetType.isChuanShuo(_loc3_.getXinghuiType()))
         {
            return param1;
         }
         var _loc4_:Array = param1.concat();
         var _loc5_:Array = XinghuiPetHelper.getSkiilIdsByRaceIdAndSkillName(_loc2_.raceId,"传说技能");
         _loc6_ = int(_loc4_.length - 1);
         while(_loc6_ >= 0)
         {
            _loc7_ = _loc4_[_loc6_];
            if(_loc5_.indexOf(_loc7_.id + "") >= 0)
            {
               _loc4_.splice(_loc6_,1);
            }
            _loc6_--;
         }
         var _loc8_:Array = XingHuiPetHelperUtil.getSkiilIdsByRaceIdAndSkillName(_loc2_.raceId,"额外特技");
         _loc6_ = int(_loc4_.length - 1);
         while(_loc6_ >= 0)
         {
            _loc7_ = _loc4_[_loc6_];
            _loc9_ = 0;
            while(_loc9_ < _loc8_.length)
            {
               _loc10_ = _loc8_[_loc9_];
               if(_loc10_.indexOf(_loc7_.id + "") >= 0)
               {
                  _loc4_.splice(_loc6_,1);
               }
               _loc9_++;
            }
            _loc6_--;
         }
         return _loc4_;
      }
      
      private function removeXingHuiHuanXiangSkill(param1:Array) : Array
      {
         var _loc7_:SkillInfo = null;
         var _loc2_:PetBriefInfo = this.getOperatingPetInfo();
         var _loc3_:PMData = this.pmService.getOperationPM(_loc2_.raceId).pmData;
         if(!XinghuiPetType.isHuanXiang(_loc3_.getXinghuiType()))
         {
            return param1;
         }
         var _loc4_:Array = param1.concat();
         var _loc5_:Array = XinghuiPetHelper.getSkiilIdsByRaceIdAndSkillName(_loc2_.raceId,"幻象系统");
         _loc5_.shift();
         _loc5_.pop();
         var _loc6_:int = int(_loc4_.length - 1);
         while(_loc6_ >= 0)
         {
            _loc7_ = _loc4_[_loc6_];
            if(_loc5_.indexOf(_loc7_.id + "") >= 0)
            {
               _loc4_.splice(_loc6_,1);
            }
            _loc6_--;
         }
         return _loc4_;
      }
      
      private function removeEWaiTeJiSkill(param1:Array) : Array
      {
         var _loc7_:Array = null;
         var _loc8_:SkillInfo = null;
         var _loc2_:PetBriefInfo = this.getOperatingPetInfo();
         var _loc3_:PMData = this.pmService.getOperationPM(_loc2_.raceId).pmData;
         var _loc4_:Array = XingHuiPetHelperUtil.getSkiilIdsByRaceIdAndSkillName(_loc2_.raceId,"额外特技");
         if(_loc4_.length <= 0)
         {
            return param1;
         }
         var _loc5_:Array = param1.concat();
         var _loc6_:int = int(_loc5_.length - 1);
         while(_loc6_ >= 0)
         {
            _loc7_ = _loc4_[_loc6_];
            _loc8_ = _loc5_[_loc6_];
            if(this.isInArray2d(_loc8_.id,_loc4_))
            {
               _loc5_.splice(_loc6_,1);
            }
            _loc6_--;
         }
         return _loc5_;
      }
      
      private function isInArray2d(param1:int, param2:Array) : Boolean
      {
         var _loc4_:Array = null;
         var _loc5_:int = 0;
         var _loc3_:int = 0;
         while(_loc3_ < param2.length)
         {
            _loc4_ = param2[_loc3_];
            _loc5_ = 0;
            while(_loc5_ < _loc4_.length)
            {
               if(_loc4_[_loc5_] + "" == param1 + "")
               {
                  return true;
               }
               _loc5_++;
            }
            _loc3_++;
         }
         return false;
      }
      
      private function getOperatingPetInfo() : PetBriefInfo
      {
         return FightData.instance.myInfo.operatingPlayer.myPets[0];
      }
      
      private function checkIsBigKill(param1:int) : Boolean
      {
         return Boolean(this.pmService.customData.pmSkillMap.getSkill(param1).isBigSkill()) && !this.checkIsSuperSpiriteSkill(param1) || this.pmService.customData.pmSkillMap.getSkill(param1).getSkillType() == PMSkillTypes.DEGENERATOR_SHEN_KILL_BIG;
      }
      
      private function checkIsCommonSpritePoSkill(param1:int) : Boolean
      {
         var _loc2_:int = int(this.pmService.customData.pmSkillMap.getSkill(param1).getSkillType());
         return _loc2_ == PMSkillTypes.DEGENERATOR_COMMON_SPIRIT_PO || _loc2_ == PMSkillTypes.DEGENERATOR_LOCK_SKILL || _loc2_ == PMSkillTypes.XINGHUI_LOCK_SKILL;
      }
      
      private function checkIsSuperSpiriteSkill(param1:int) : Boolean
      {
         var _loc2_:int = int(this.pmService.customData.pmSkillMap.getSkill(param1).getSkillType());
         return Boolean(PMSkillTypes.isDegeneratorSuperSpiritSkill(_loc2_)) || Boolean(PMSkillTypes.isXinghuiSuperSpiritSkill(_loc2_)) || Boolean(PMSkillTypes.isGQCommonSpiritSkill(_loc2_));
      }
      
      private function checkIsCompletedSkill(param1:int) : Boolean
      {
         return SkillMap.instance.checkIsCompletedSkill(param1);
      }
      
      private function checkIsBigSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return Boolean(_loc2_.isBigSkill()) || _loc2_.getSkillType() == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_YU_PASSIVE || _loc2_.getSkillType() == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_BAO_PASSIVE;
      }
      
      private function checkIsYuNotBigSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.DEGENERATOR_YU_NOT_BIG_SKILL;
      }
      
      private function checkIsDoublegodSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.XINGHUI_DOUBLEGOD_CHANGE;
      }
      
      private function checkIsQiyuanPassiveSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.XINGHUI_QIYUAN_PASSIVE_SKILL;
      }
      
      private function checkIsXingHuiSpPassiveSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.XINGHUI_SP_PASSIVE_SKILL;
      }
      
      private function checkIsWangzheRealPassiveSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.XINGHUI_WANGZHE_REAL_PASSIVE_SKILL || _loc2_.getSkillType() == PMSkillTypes.SHEN_WANGZHE_REAL_PASSIVE;
      }
      
      private function checkIsWangzheRealExtPassiveSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.XINGHUI_WANGZHE_REAL_EXT_PASSIVE_SKILL;
      }
      
      private function checkIsWangzheRealExtSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.XINGHUI_WANGZHE_REAL_EXTEND_SKILL;
      }
      
      private function checkIsJuexingExtSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.XINGHUI_JUEXING_EXTEND_SKILL;
      }
      
      private function checkIsShenliExtSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.SHEN_LI_SKILL;
      }
      
      private function checkIsZhanYiSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.ZHANYI_BURST_PASSIVE || _loc2_.getSkillType() == PMSkillTypes.ZHANYI_COMMON_PASSIVE;
      }
      
      private function checkIsPassiveSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return Boolean(_loc2_.isPassiveSkill) || _loc2_.getSkillType() == PMSkillTypes.DEGENERATOR_PASSIVE_SKILL || _loc2_.getSkillType() == PMSkillTypes.XINGHUI_PASSIVE_SKILL || _loc2_.getSkillType() == PMSkillTypes.XINGHUI_QIYUAN_PASSIVE_SKILL || _loc2_.getSkillType() == PMSkillTypes.GQ_DIJIESHI_PASSIVE || _loc2_.getSkillType() == PMSkillTypes.GQ_JUEXING_YUANMAO_PASSIVE || _loc2_.getSkillType() == PMSkillTypes.GQ_JUEXING_ZHENSHEN_PASSIVE;
      }
      
      private function checkIsShifleProExtSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.SHIELD_PROTECTION_SKILL;
      }
      
      private function checkIsZhanJiPassiveSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.ZHAN_JI_PASSIVE;
      }
      
      private function checkIsFaHuanPassiveSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.FA_HUAN_PASSIVE;
      }
      
      private function checkIsLunhuiQiYuePassiveSkill(param1:int) : Boolean
      {
         var _loc2_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1);
         return _loc2_.getSkillType() == PMSkillTypes.XINGHUI_LUNHUI_SHIYUE_PASSIVE;
      }
      
      private function checkIsOtherGQExtraSkill(param1:int) : Boolean
      {
         var _loc2_:int = int(this.pmService.customData.pmSkillMap.getSkill(param1).getSkillType());
         return _loc2_ == PMSkillTypes.GQ_MINGZUO_PASSIVE || _loc2_ == PMSkillTypes.GQ_CHAOWEI_PASSIVE || _loc2_ == PMSkillTypes.GQ_OUTBURSTCOPY_PASSIVE || _loc2_ == PMSkillTypes.GQ_TIANYI_PASSIVE || _loc2_ == PMSkillTypes.GQ_QUANNENG_PASSIVE || _loc2_ == PMSkillTypes.GQ_XINGYUETONGXING_EXTRA_SKILL || _loc2_ == PMSkillTypes.GQ_MENGHUAN_DIYUE_SKILL || _loc2_ == PMSkillTypes.GQ_SHUANGSHENGE_EXTRA_SKILL || _loc2_ == PMSkillTypes.GQ_YUXIANGSHI_FIRST_SKILL || _loc2_ == PMSkillTypes.GQ_YUXIANGSHI_SECOND_SKILL;
      }
      
      private function initMCChangeViewWithCatchError() : void
      {
         var operatingPlayer:PlayerBattleInfo = null;
         var petInfo:PetBriefInfo = null;
         var errorInfo:String = null;
         try
         {
            this.initMCChangeView();
         }
         catch(e:Error)
         {
            operatingPlayer = FightData.instance.myInfo.operatingPlayer;
            petInfo = getOperatingPetInfo();
            errorInfo = operatingPlayer.PMMasterId + "," + operatingPlayer.isSummoned() + "," + operatingPlayer.slotId;
            errorInfo += "," + petInfo.raceId;
            errorInfo += "," + FightData.instance.fightSize;
            throw new Error("initMCChangeView报错：" + errorInfo);
         }
      }
      
      private function initMCChangeView() : void
      {
         this._bigSkillMC = this.getChildByName("mcChangeView") as BigSkillMC;
      }
      
      public function autoUseSkill(param1:int) : void
      {
         var _loc4_:SmallSkillMC = null;
         var _loc2_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         FightData.instance.targetSlot = SkillTargetSelecter.getDefaultSkillTarget(param1,_loc2_.slotId);
         var _loc3_:SmallSkillMC = null;
         for each(_loc4_ in this._smallSkillMCList)
         {
            if(_loc4_.id == param1)
            {
               _loc3_ = _loc4_;
               break;
            }
         }
         if(Boolean(_loc3_) && _loc4_.useSkill())
         {
            _loc4_.startUseSkill(true);
         }
         else
         {
            this.autoUseRandomSkill();
         }
      }
      
      private function autoUseRandomSkill() : void
      {
         var _loc3_:SmallSkillMC = null;
         var _loc4_:PlayerBattleInfo = null;
         var _loc1_:Boolean = false;
         var _loc2_:int = 0;
         while(_loc2_ < this._smallSkillMCList.length)
         {
            _loc3_ = this._smallSkillMCList[_loc2_] as SmallSkillMC;
            if(_loc3_.useSkill())
            {
               _loc3_.startUseSkill(true);
               _loc1_ = true;
               break;
            }
            _loc2_++;
         }
         if(!_loc1_)
         {
            FightController.instance.fightPanel.stopTimer();
            _loc4_ = FightData.instance.myInfo.operatingPlayer;
            PetClient.instance.standby(FightController.instance.turnCount,FightController.instance.isAuto,_loc4_.slotId);
         }
      }
      
      public function cancelUseSkill() : void
      {
         var _loc1_:SmallSkillMC = null;
         for each(_loc1_ in this._smallSkillMCList)
         {
            _loc1_.cancelUse();
         }
         UseBigSkillHandler.instance.cancelUse();
      }
      
      public function switchSkill() : void
      {
         NewOrderlySkillStrategy.reset();
         this.update();
      }
      
      private function hundunSortTail() : void
      {
         var _loc1_:Object = null;
         var _loc3_:SkillInfo = null;
         var _loc4_:int = 0;
         var _loc2_:int = 0;
         while(_loc2_ < MAX_SMALL_SKILL_NUM)
         {
            _loc3_ = this._smallSkills[_loc2_];
            if(_loc3_ != null)
            {
               _loc4_ = int(this.pmService.customData.pmSkillMap.getSkill(_loc3_.id).getSkillType());
               if(_loc4_ == PMSkillTypes.HUN_DUN_XINGHUI_SKILL)
               {
                  _loc1_ = _loc3_;
                  this._smallSkills.splice(_loc2_,1);
                  break;
               }
            }
            _loc2_++;
         }
         if(_loc1_)
         {
            this._smallSkills.push(_loc1_);
         }
      }
      
      private function sortGQSkill() : void
      {
         if(!GQPetHelper.checkIsGQPet(this._petInfo.raceId))
         {
            return;
         }
         this._smallSkills.sort(this.compare);
      }
      
      private function compare(param1:SkillInfo, param2:SkillInfo) : int
      {
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc3_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param1.id);
         var _loc4_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(param2.id);
         var _loc5_:Array = this.pmService.getOperationPM(this._petInfo.raceId).pmData.getGQNewSkill_UnchangeableSkill(true);
         if(Boolean(PMSkillTypes.getIsGQZhuanshuSkill(_loc3_.getSkillType())) || _loc5_.indexOf(_loc3_.skillId) != -1 && !PMSkillTypes.isPassiveSkill(_loc3_))
         {
            return -1;
         }
         if(Boolean(PMSkillTypes.getIsGQZhuanshuSkill(_loc4_.getSkillType())) || _loc5_.indexOf(_loc4_.skillId) != -1 && !PMSkillTypes.isPassiveSkill(_loc4_))
         {
            return 1;
         }
         if(PMSkillTypes.isGQCommonSpiritSkill(_loc3_.getSkillType()))
         {
            if(!PMSkillTypes.isGQCommonSpiritSkill(_loc4_.getSkillType()))
            {
               return -1;
            }
            if(_loc3_.costSoulNum > _loc4_.costSoulNum)
            {
               return -1;
            }
            if(_loc3_.costSoulNum == _loc4_.costSoulNum)
            {
               return _loc4_.skillId - _loc3_.skillId;
            }
            return 1;
         }
         if(PMSkillTypes.isPassiveSkill(_loc3_))
         {
            return 1;
         }
         if(PMSkillTypes.GQ_YIREN_COMMON_SKILL == _loc3_.getSkillType())
         {
            if(PMSkillTypes.GQ_YIREN_COMMON_SKILL != _loc4_.getSkillType())
            {
               return -1;
            }
            _loc6_ = int(GQPetType.getYiRenSkillCost(PetAssetsMap.getPetFlaId(this._petInfo.raceId),param1.id));
            _loc7_ = int(GQPetType.getYiRenSkillCost(PetAssetsMap.getPetFlaId(this._petInfo.raceId),param2.id));
            return _loc6_ - _loc7_ > 0 ? -1 : 1;
         }
         if(PMSkillTypes.isGQCommonSpiritSkill(_loc4_.getSkillType()))
         {
            return 1;
         }
         if(PMSkillTypes.isPassiveSkill(_loc4_))
         {
            return -1;
         }
         if(_loc4_.power == _loc3_.power)
         {
            return _loc4_.skillId - _loc3_.skillId;
         }
         return _loc4_.power - _loc3_.power;
      }
      
      private function fightUseCustomSkill(param1:PetFightEvent) : void
      {
         var _loc2_:int = int(param1.params.skillId);
         var _loc3_:PetBriefInfo = this.getOperatingPetInfo();
         var _loc4_:PMSkill = this.pmService.customData.pmSkillMap.getSkill(_loc2_);
         var _loc5_:int = int(_loc4_.getSkillType());
         var _loc6_:int = param1.params.hasOwnProperty("index") ? int(param1.params.index) : -1;
         UseBigSkillHandler.instance.handleUse(_loc3_,_loc2_,_loc5_,_loc6_);
      }
   }
}

