package mmo.petfightnew.common.panel.skill.small
{
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.common.bitmapmovie.BitmapMovieClip;
   import mmo.common.bitmapmovie.BitmapMovieClipParser;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.common.utils.tips.TipsType;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.XingHuiPetHelperUtil;
   import mmo.interfaces.pet.data.GQMingYunBoYiSkillParse;
   import mmo.interfaces.pet.data.GQXingZhiYuSkillParse;
   import mmo.interfaces.pet.data.GQYiRenWujinMingtuSkillParse;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.component.CachedClip;
   import mmo.petfightnew.common.component.StaticButton;
   import mmo.petfightnew.common.constant.FightSize;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.event.FightInnerEvent;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.panel.*;
   import mmo.petfightnew.common.panel.skill.EffectIcon;
   import mmo.petfightnew.common.panel.skill.EffectIcon2v2;
   import mmo.petfightnew.common.useskill.SkillRange;
   import mmo.petfightnew.common.util.BSUtil;
   import mmo.petfightnew.common.util.PositionUtil;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.activity.framework.util.CallbackUtil;
   import mmo.play.petfight.common.config.FightResConfig;
   import mmo.play.petfight.common.data.SkillType;
   
   public class SmallSkillMC extends Sprite implements IDispose
   {
      
      private static const ENABLE:int = 0;
      
      private static const DISABLE_REASON_FREEZE_ATT:int = 1;
      
      private static const DISABLE_REASON_FREEZE_SATT:int = 2;
      
      private static const DISABLE_REASON_NO_PP:int = 2;
      
      private static const DISABLE_WITH_NO_REASON:int = 3;
      
      private var _canUseTime:int;
      
      private var _enableState:int = -1;
      
      private var _effectIcon:CachedClip;
      
      private var _mc2v2EffectIcons:Array = [];
      
      private var _skillType:int = 1;
      
      private var _pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
      
      private var _petSkillMesSvr:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
      
      private var _skillInfo:SkillInfo;
      
      private var _pmSkill:PMSkill = null;
      
      private var _petInfo:PetBriefInfo;
      
      private var _refreshGQSoulCall:Function = null;
      
      private var _zhaohuanBigKillPanel:DegeneratorZhaohuanBigKillPanel = null;
      
      private var _gongmingBigKillPanel:XinghuiGongmingBigKillPanel = null;
      
      private var _extraAddedSkill:XinghuiAddedKillPanel = null;
      
      private var _btnSkill:StaticButton;
      
      private var _upState:SkillButtonState_Up;
      
      private var _overState:SkillButtonState_Over;
      
      private var _xingHuiSuperSpiritMovie:BitmapMovieClip;
      
      private var _gqPFSShenHuanExtraSkillPl:GQPFSShenHuanExtraSkillPanel = null;
      
      private var _gqXingZhiYuExtraSkillPl:GQXingZhiYuExtraSkillPanel = null;
      
      private var _gqMingYunBoYiExtraSkillPl:GQMingYunBoYiExtraSkillPanel = null;
      
      private var _targetVSPlayer:PlayerBattleInfo = null;
      
      private var _lastPetId:int;
      
      private var _lastRaceId:int;
      
      private var _lastSkillId:int;
      
      private var _lastSoulNum:int;
      
      public function SmallSkillMC()
      {
         super();
         this.initSkillButton();
         this.initListeners();
      }
      
      private function initSkillButton() : void
      {
         this._btnSkill = new StaticButton();
         this._upState = new SkillButtonState_Up();
         this._overState = new SkillButtonState_Over();
         this.addChild(this._btnSkill);
      }
      
      public function setSkill(param1:SkillInfo, param2:PetBriefInfo, param3:Function = null) : void
      {
         this._skillInfo = param1;
         this._pmSkill = this._pmService.customData.pmSkillMap.getSkill(param1.id);
         this._petInfo = param2;
         this._skillType = SkillType.getSkillType(this._skillInfo.id);
         this._canUseTime = param1.canUseTimes;
         this._refreshGQSoulCall = param3;
         this.checkEnabled();
         this.resetTips();
         this.update();
         this._lastPetId = this._petInfo.id;
         this._lastRaceId = this._petInfo.raceId;
         this._lastSkillId = this.skillId;
      }
      
      private function updateSuperSpiritMovie() : void
      {
         var currentSoulNum:int = 0;
         var cls:Class = null;
         var superSpiritMc:MovieClip = null;
         var mc:MovieClip = null;
         var costSoulNum:int = int(this._pmSkill.costSoulNum);
         if(!(Boolean(SkillType.checkIsSuperSpiriteSkill(this.skillId)) && costSoulNum > 0))
         {
            this.hideXingHuiSuperSpiritMovie();
            return;
         }
         if(Boolean(SkillType.getIsDegeneratorSuperSpiritSkill(this._skillType)) && this._skillType != SkillType.DEGENERATOR_SUPER_SPIRIT_YU_PASSIVE && this._skillType != SkillType.DEGENERATOR_SUPER_SPIRIT_JUE && this._skillType != SkillType.DEGENERATOR_SUPER_SPIRIT_ZHAOHUAN_PASSIVE)
         {
            currentSoulNum = int(this._petInfo.curDegeneratorSoulNum);
            if(this._lastPetId != this._petInfo.id || this._lastRaceId != this._petInfo.raceId || this._lastSkillId != this.skillId)
            {
               this._lastSoulNum = 0;
            }
            if(this._lastSoulNum < costSoulNum && currentSoulNum >= costSoulNum)
            {
               cls = getDefinitionByName("mmo.petfightnew.common.ChangeToSuperSpiritMv") as Class;
               superSpiritMc = new cls() as MovieClip;
               superSpiritMc.mouseEnabled = superSpiritMc.mouseChildren = false;
               superSpiritMc.gotoAndStop(this._skillType - 8);
               superSpiritMc.x = this._btnSkill.x;
               superSpiritMc.y = this._btnSkill.y - 2;
               addChild(superSpiritMc);
               mc = superSpiritMc.mcframe;
               mc.stop();
               FightMovieManager.instance.addMovie(mc);
               mc.addFrameScript(mc.totalFrames - 1,function():*
               {
                  FightMovieManager.instance.removeMovie(mc);
                  DisplayUtil.stopAndRemove(superSpiritMc);
               });
               mc.gotoAndPlay(1);
            }
            this._lastSoulNum = currentSoulNum;
         }
         else if(this._petInfo.curXinghuiSoulNum >= costSoulNum)
         {
            if(this._xingHuiSuperSpiritMovie == null)
            {
               this._xingHuiSuperSpiritMovie = BitmapMovieClipParser.getBitmapMovieClip(FightResConfig.XING_HUI_SPIRIT_SKILL_BUTTON_MOVIE_CLSNAME,FightData.instance.applicationDomain);
               if(this._xingHuiSuperSpiritMovie != null)
               {
                  this._xingHuiSuperSpiritMovie.mouseChildren = this._xingHuiSuperSpiritMovie.mouseEnabled = false;
                  this._xingHuiSuperSpiritMovie.x = this._btnSkill.x;
                  this._xingHuiSuperSpiritMovie.y = this._btnSkill.y;
                  this.addChild(this._xingHuiSuperSpiritMovie);
               }
            }
            else
            {
               this._xingHuiSuperSpiritMovie.visible = true;
            }
            if(this._xingHuiSuperSpiritMovie)
            {
               this._xingHuiSuperSpiritMovie.gotoAndPlay(1);
            }
         }
         else
         {
            this.hideXingHuiSuperSpiritMovie();
         }
      }
      
      private function updateGQSpecialTips() : void
      {
         var _loc1_:Class = getDefinitionByName("mmo.petfightnew.common.GQSpecialTipsMc") as Class;
         var _loc2_:MovieClip = this.getChildByName("GQSpecialTipsMc") as MovieClip;
         if(this._pmSkill.getSkillType() == PMSkillTypes.GQ_CONDITION_SPIRIT_SKILL)
         {
            this.addSpecialTips(_loc1_,_loc2_,1,"我方任意单位受到非反击技的攻击技能时概率无消耗触发反击技回击攻击者");
         }
         else if(this._pmSkill.getSkillType() == PMSkillTypes.GQ_ZHUIJI_SPIRIT_SKILL)
         {
            this.addSpecialTips(_loc1_,_loc2_,2,"我方攻击时概率无消耗触发追击技追击受击者");
         }
         else if(this._pmSkill.attackType == 2 && !PMSkillTypes.isPassiveSkill(this._pmSkill))
         {
            if(this._pmSkill.hitTaget <= 2)
            {
               this.addSpecialTips(_loc1_,_loc2_,3,"技能范围");
            }
            else
            {
               this.addSpecialTips(_loc1_,_loc2_,4,"技能范围");
            }
         }
         else if(Boolean(_loc2_) && Boolean(_loc2_.parent))
         {
            DisplayUtil.stopAndRemove(_loc2_);
            _loc2_ = null;
         }
      }
      
      private function addSpecialTips(param1:Class, param2:MovieClip, param3:int, param4:String) : void
      {
         if(!param2)
         {
            param2 = new param1() as MovieClip;
            param2.name = "GQSpecialTipsMc";
         }
         param2.gotoAndStop(param3);
         param2.x = this._btnSkill.x + 86.3;
         param2.y = this._btnSkill.y - 15;
         TipsManager.getInstance().replaceTips(param2,param4);
         this.addChild(param2);
      }
      
      private function hideXingHuiSuperSpiritMovie() : void
      {
         if(this._xingHuiSuperSpiritMovie)
         {
            this._xingHuiSuperSpiritMovie.stop();
            this._xingHuiSuperSpiritMovie.visible = false;
         }
      }
      
      private function checkEnabled() : void
      {
         var _loc1_:int = int(TipsType.NORMAL);
         var _loc2_:Array = this._pmService.getOperationPM(this._petInfo.raceId).pmData.getGQNewSkill_UnchangeableSkill(true);
         if(_loc2_.indexOf(this.id) != -1 || Boolean(PMSkillTypes.getIsGQZhuanshuSkill(this._pmSkill.getSkillType())))
         {
            _loc1_ = int(TipsType.FIGHTSKILL_ZHUANSHU);
         }
         var _loc3_:GQYiRenWujinMingtuSkillParse = GQYiRenWujinMingtuSkillParse.getYiRenWujinMingtuSkillData(this._petInfo.raceId);
         var _loc4_:int = int(GQPetType.getYiRenSkillCost(this._petInfo.raceId,this.skillId));
         if(this.isPassiveSkill() || Boolean(this._pmSkill.isSkillLock) || this._skillType == SkillType.DEGENERATOR_SUPER_SPIRIT_JUE || this._skillType == SkillType.DEGENERATOR_SUPER_SPIRIT_YU_PASSIVE || _loc1_ == TipsType.FIGHTSKILL_ZHUANSHU && StatusUtil.getIsInYiWangCommonBuff(this._petInfo))
         {
            this._enableState = DISABLE_WITH_NO_REASON;
         }
         else if(!StatusUtil.getCanUseSkillWithToteOrBuff(this._petInfo,this.id))
         {
            this._enableState = DISABLE_WITH_NO_REASON;
         }
         else if(this._skillInfo.cd > 0)
         {
            this._enableState = DISABLE_WITH_NO_REASON;
         }
         else if(_loc3_ && _loc3_.getIsAfterChangeView(this._petInfo) && StatusUtil.getYirenShieldByPbi(this._petInfo)[0] < _loc4_)
         {
            this._enableState = DISABLE_WITH_NO_REASON;
         }
         else if(this._canUseTime <= 0 && (!SkillType.getIsDegeneratorSuperSpiritSkill(this._skillType) && !SkillType.getIsXinghuiSuperSpiritSkill(this._skillType)) && !SkillType.getIsXinghuiHunDunSkill(this._skillType) && !SkillType.getIsZhanYiActiveSkill(this._skillType) && !SkillType.getIsZhanJicOMMONSkill(this._skillType) && !SkillType.checkIsGQCommonSpiritSkill(this.id) && !SkillType.checkIsGQZhanYiActiveSkill(this.id))
         {
            this._enableState = DISABLE_REASON_NO_PP;
         }
         else
         {
            this._enableState = ENABLE;
         }
         var _loc5_:Array = this.getFreezeSkillState();
         var _loc6_:int = int(this._pmSkill.attackType);
         var _loc7_:int = 0;
         while(_loc7_ < _loc5_.length)
         {
            if(_loc5_[_loc7_] == "58" && _loc6_ == 0)
            {
               if(!this.isPassiveSkill() && !this._pmSkill.isSkillLock)
               {
                  this._enableState = DISABLE_REASON_FREEZE_ATT;
                  break;
               }
               this._enableState = DISABLE_WITH_NO_REASON;
               break;
            }
            if(_loc5_[_loc7_] == "59" && _loc6_ == 1)
            {
               if(!this.isPassiveSkill() && !this._pmSkill.isSkillLock)
               {
                  this._enableState = DISABLE_REASON_FREEZE_SATT;
                  break;
               }
               this._enableState = DISABLE_WITH_NO_REASON;
               break;
            }
            _loc7_++;
         }
      }
      
      private function initListeners() : void
      {
         SocketClient.instance.addEventListener(PetClient.RSPN_USE_SKILL + "",this.onUseSkill);
         FightEventDispatcher.instance.addEventListener(FightInnerEvent.ON_MOUSE_OVER_PET,this.onMouseRoleOverPetListener);
         FightEventDispatcher.instance.addEventListener(FightInnerEvent.ON_MOUSE_OUT_PET,this.onMouseRollOutPetListener);
         this.addEventListener(Event.REMOVED_FROM_STAGE,this.onRemovedListener);
         this._btnSkill.addEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      private function onRemovedListener(param1:Event) : void
      {
         this.onRollOutListener(null);
      }
      
      private function haveExtSkillPanel() : Boolean
      {
         var _loc1_:Boolean = false;
         if(XinghuiAddedKillPanel.canShowAddedSkill(this._petInfo,this._skillType))
         {
            _loc1_ = true;
         }
         else if(this._skillType == SkillType.DEGENERATOR_SUPER_SPIRIT_ZHAOHUAN)
         {
            _loc1_ = true;
         }
         return _loc1_;
      }
      
      public function dispose() : void
      {
         var _loc1_:CachedClip = null;
         DisplayUtil.clearFilters(this);
         this._effectIcon && this._effectIcon.dispose();
         DisplayUtil.stopAndRemove(this._effectIcon);
         this._effectIcon = null;
         for each(_loc1_ in this._mc2v2EffectIcons)
         {
            DisplayUtil.stopAndRemove(_loc1_);
            _loc1_.dispose();
         }
         this._mc2v2EffectIcons.length = 0;
         this._xingHuiSuperSpiritMovie && this._xingHuiSuperSpiritMovie.dispose();
         this._btnSkill.removeEventListener(MouseEvent.CLICK,this.onClick);
         this._btnSkill.removeEventListener(MouseEvent.ROLL_OVER,this.onRollOverListener);
         this._btnSkill.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
         this.removeEventListener(Event.REMOVED_FROM_STAGE,this.onRemovedListener);
         SocketClient.instance.removeEventListener(PetClient.RSPN_USE_SKILL + "",this.onUseSkill);
         FightEventDispatcher.instance.removeEventListener(FightInnerEvent.ON_MOUSE_OVER_PET,this.onMouseRoleOverPetListener);
         FightEventDispatcher.instance.removeEventListener(FightInnerEvent.ON_MOUSE_OUT_PET,this.onMouseRollOutPetListener);
         if(this._zhaohuanBigKillPanel != null)
         {
            this._zhaohuanBigKillPanel.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
            DisplayUtil.stopAndRemove(this._zhaohuanBigKillPanel);
            this._zhaohuanBigKillPanel = null;
         }
         else if(this._gongmingBigKillPanel != null)
         {
            this._gongmingBigKillPanel.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
            DisplayUtil.stopAndRemove(this._gongmingBigKillPanel);
            this._gongmingBigKillPanel = null;
         }
         if(this._gqPFSShenHuanExtraSkillPl != null)
         {
            this._gqPFSShenHuanExtraSkillPl.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
            DisplayUtil.stopAndRemove(this._gqPFSShenHuanExtraSkillPl);
            this._gqPFSShenHuanExtraSkillPl = null;
         }
         if(this._gqXingZhiYuExtraSkillPl != null)
         {
            this._gqXingZhiYuExtraSkillPl.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
            DisplayUtil.stopAndRemove(this._gqXingZhiYuExtraSkillPl);
            this._gqXingZhiYuExtraSkillPl = null;
         }
         if(this._gqMingYunBoYiExtraSkillPl != null)
         {
            this._gqMingYunBoYiExtraSkillPl.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
            DisplayUtil.stopAndRemove(this._gqMingYunBoYiExtraSkillPl);
            this._gqMingYunBoYiExtraSkillPl = null;
         }
         if(this._extraAddedSkill != null)
         {
            this._extraAddedSkill.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
            DisplayUtil.stopAndRemove(this._extraAddedSkill);
            this._extraAddedSkill = null;
         }
         this._overState && this._overState.dispose();
         this._upState && this._upState.dispose();
         this._overState = null;
         this._upState = null;
         this._btnSkill && this._btnSkill.dispose();
         this._btnSkill = null;
         this._petInfo = null;
         this._targetVSPlayer = null;
      }
      
      private function onMouseRoleOverPetListener(param1:CommonEvent) : void
      {
         var _loc2_:int = int(param1.params.locaId);
         if(FightData.instance.isMySide(_loc2_))
         {
            return;
         }
         if(FightData.instance.opponents.length <= 1)
         {
            return;
         }
         this._targetVSPlayer = FightData.instance.getPlayerInfoByLocalId(_loc2_);
         this.updateEffectIcon();
      }
      
      private function updateEffectIcon() : void
      {
         var _loc3_:Object = null;
         var _loc6_:PlayerBattleInfo = null;
         var _loc7_:MovieClip = null;
         if(this._targetVSPlayer == null)
         {
            this.removeEffectIcon();
            return;
         }
         var _loc1_:PetBriefInfo = this._targetVSPlayer.myPets[0] as PetBriefInfo;
         if(_loc1_ == null)
         {
            return;
         }
         var _loc2_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         if(this._targetVSPlayer.lingshouRealitySlotId == -1)
         {
            _loc3_ = _loc2_.getPetMes(_loc1_.raceId);
         }
         else
         {
            _loc6_ = FightData.instance.getPlayerInfoBySlotId(this._targetVSPlayer.lingshouRealitySlotId);
            _loc3_ = _loc2_.getPetMes((_loc6_.myPets[0] as PetBriefInfo).raceId);
         }
         var _loc4_:Object = _loc2_.getPetSkillMes(this.id);
         var _loc5_:int = _loc2_.compareAttributeRelation(_loc4_.attribute,_loc3_.attribute,_loc3_.attribute2) + 1;
         if(this._effectIcon == null)
         {
            _loc7_ = new EffectIcon();
            this._effectIcon = new CachedClip(_loc7_);
            this._effectIcon.x = -28;
            this._effectIcon.y = 10;
         }
         this._effectIcon.gotoAndStop(_loc5_);
         this._effectIcon.visible = !this.haveExtSkillPanel();
         this.addChild(this._effectIcon);
      }
      
      private function update2V2EffectIcon() : void
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:PetBriefInfo = null;
         var _loc5_:Object = null;
         var _loc6_:int = 0;
         var _loc7_:Point = null;
         var _loc8_:MovieClip = null;
         var _loc9_:MovieClip = null;
         var _loc10_:CachedClip = null;
         var _loc1_:Array = FightData.instance.opponents;
         var _loc2_:int = 0;
         while(_loc2_ < _loc1_.length)
         {
            _loc3_ = _loc1_[_loc2_];
            if(_loc3_ && _loc3_.myPets.length > 0 && (_loc3_.myPets[0] as PetBriefInfo).curHp > 0)
            {
               _loc4_ = _loc3_.myPets[0];
               _loc5_ = this._petSkillMesSvr.getPetMes(_loc4_.raceId);
               _loc6_ = this._petSkillMesSvr.compareAttributeRelation(this._pmSkill.attributeType,_loc5_.attribute,_loc5_.attribute2) + 1;
               if(this._mc2v2EffectIcons[_loc2_] == null)
               {
                  _loc9_ = new EffectIcon2v2() as MovieClip;
                  _loc10_ = new CachedClip(_loc9_);
                  this._mc2v2EffectIcons[_loc2_] = _loc10_;
               }
               _loc7_ = PositionUtil.getDefaultPosition(_loc3_.locaId);
               this._mc2v2EffectIcons[_loc2_].gotoAndStop(_loc6_);
               FightController.instance.fightPanel.layerPetUp.addChild(this._mc2v2EffectIcons[_loc2_]);
               this._mc2v2EffectIcons[_loc2_].x = _loc7_.x + 100;
               this._mc2v2EffectIcons[_loc2_].y = _loc7_.y;
               _loc8_ = this._mc2v2EffectIcons[_loc2_].getChildByName("mc") as MovieClip;
               (_loc8_) && _loc8_.gotoAndPlay(1);
            }
            _loc2_++;
         }
      }
      
      private function onMouseRollOutPetListener(param1:CommonEvent) : void
      {
         if(this.haveOnlyOneEnemy())
         {
            return;
         }
         this._targetVSPlayer = null;
         this.removeEffectIcon();
      }
      
      private function haveOnlyOneEnemy() : Boolean
      {
         return FightData.instance.opponents.length == 1;
      }
      
      private function removeEffectIcon() : void
      {
         DisplayUtil.stopAndRemove(this._effectIcon);
      }
      
      public function get skillName() : String
      {
         return this._skillInfo.name;
      }
      
      public function get id() : int
      {
         return this._skillInfo.id;
      }
      
      private function resetTips() : void
      {
         var _loc1_:Boolean = Boolean(GQPetType.isXingZhiYu(this._pmService.getOperationPM(this._petInfo.raceId).pmData.getGQType()));
         var _loc2_:int = int(GQXingZhiYuSkillParse.getXingZhiYuSpiritSkillId(this._petInfo));
         var _loc3_:Boolean = Boolean(GQPetType.isMingYunBoYi(this._pmService.getOperationPM(this._petInfo.raceId).pmData.getGQType()));
         var _loc4_:int = int(GQMingYunBoYiSkillParse.getMingYunBoYiSpiritSkillId(this._petInfo));
         if(this.isPetHaveEWaiTeJi(this._skillType) || XinghuiAddedKillPanel.canShowAddedSkill(this._petInfo,this._skillType) || this._skillType == SkillType.DEGENERATOR_SUPER_SPIRIT_ZHAOHUAN || this._skillType == SkillType.XINGHUI_WANGZHE_SPIRIT_TEJI && !XinghuiPetType.isFuBloodPet(this._pmService.getOperationPM(this._petInfo.raceId).pmData.getXinghuiType()) || FightData.instance.isPFSShenHuanFight && !PMSkillTypes.isGQPassiveSkill(this._pmSkill.getSkillType()) || _loc1_ && _loc2_ > 0 && PMSkillTypes.GQ_XINGZHIYU_ZHUANSHU_SKILL == this._pmSkill.getSkillType() || _loc3_ && _loc4_ > 0 && PMSkillTypes.GQ_MINGYUNBOYI_ZHUANSHU_SKILL == this._pmSkill.getSkillType() || FightData.instance.fightSize == FightSize.TWO_VS_TWO)
         {
            this._btnSkill.addEventListener(MouseEvent.ROLL_OVER,this.onRollOverListener);
            if(FightData.instance.isPFSShenHuanFight || FightData.instance.fightSize == FightSize.TWO_VS_TWO)
            {
               this.addEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
               this.addSkillTips(this._btnSkill);
            }
            else if(_loc1_ && _loc2_ > 0 && PMSkillTypes.GQ_XINGZHIYU_ZHUANSHU_SKILL == this._pmSkill.getSkillType() || _loc3_ && _loc4_ > 0 && PMSkillTypes.GQ_MINGYUNBOYI_ZHUANSHU_SKILL == this._pmSkill.getSkillType())
            {
               this.addEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
               this.removeSkillTips(this._btnSkill);
            }
            else
            {
               this.removeSkillTips(this._btnSkill);
            }
         }
         else
         {
            this._btnSkill.removeEventListener(MouseEvent.ROLL_OVER,this.onRollOverListener);
            this.addSkillTips(this._btnSkill);
         }
      }
      
      public function isPetHaveEWaiTeJi(param1:int) : Boolean
      {
         var _loc4_:Array = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc2_:Array = XingHuiPetHelperUtil.getSkiilIdsByRaceIdAndSkillName(this._petInfo.raceId,"额外特技");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            _loc5_ = 0;
            while(_loc5_ < _loc4_.length)
            {
               _loc6_ = parseInt(_loc4_[_loc5_] + "");
               if(param1 == this._pmService.customData.pmSkillMap.getSkill(_loc6_).getSkillType())
               {
                  return true;
               }
               _loc5_++;
            }
            _loc3_++;
         }
         return false;
      }
      
      private function onRollOverListener(param1:MouseEvent) : void
      {
         var _loc6_:Array = null;
         var _loc2_:Boolean = Boolean(GQPetType.isXingZhiYu(this._pmService.getOperationPM(this._petInfo.raceId).pmData.getGQType()));
         var _loc3_:int = int(GQXingZhiYuSkillParse.getXingZhiYuSpiritSkillId(this._petInfo));
         var _loc4_:Boolean = Boolean(GQPetType.isMingYunBoYi(this._pmService.getOperationPM(this._petInfo.raceId).pmData.getGQType()));
         var _loc5_:int = int(GQMingYunBoYiSkillParse.getMingYunBoYiSpiritSkillId(this._petInfo));
         if(FightData.instance.isPFSShenHuanFight && !PMSkillTypes.isGQPassiveSkill(this._pmSkill.getSkillType()))
         {
            if(this._gqPFSShenHuanExtraSkillPl == null)
            {
               this._gqPFSShenHuanExtraSkillPl = new GQPFSShenHuanExtraSkillPanel(this._skillInfo);
            }
            this.addChild(this._gqPFSShenHuanExtraSkillPl);
         }
         else if(_loc2_ && _loc3_ > 0 && PMSkillTypes.GQ_XINGZHIYU_ZHUANSHU_SKILL == this._pmSkill.getSkillType())
         {
            if(this._gqXingZhiYuExtraSkillPl == null)
            {
               this._gqXingZhiYuExtraSkillPl = new GQXingZhiYuExtraSkillPanel(this._skillInfo);
            }
            this.add2Parent(this._gqXingZhiYuExtraSkillPl);
            this._gqXingZhiYuExtraSkillPl.addEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
         }
         else if(_loc4_ && _loc5_ > 0 && PMSkillTypes.GQ_MINGYUNBOYI_ZHUANSHU_SKILL == this._pmSkill.getSkillType())
         {
            if(this._gqMingYunBoYiExtraSkillPl == null)
            {
               this._gqMingYunBoYiExtraSkillPl = new GQMingYunBoYiExtraSkillPanel(this._skillInfo);
            }
            this.add2Parent(this._gqMingYunBoYiExtraSkillPl);
            this._gqMingYunBoYiExtraSkillPl.addEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
         }
         else if(XinghuiAddedKillPanel.canShowAddedSkill(this._petInfo,this._skillType))
         {
            if(this._extraAddedSkill == null)
            {
               _loc6_ = XinghuiAddedKillPanel.getExtAddSkillInfo(this._petInfo,this._skillType);
               this._extraAddedSkill = new XinghuiAddedKillPanel(_loc6_,this._petInfo,this._skillType);
            }
            this.add2Parent(this._extraAddedSkill);
            this._extraAddedSkill.addEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
         }
         else if(this._skillType == SkillType.DEGENERATOR_SUPER_SPIRIT_ZHAOHUAN)
         {
            if(this._zhaohuanBigKillPanel == null)
            {
               this._zhaohuanBigKillPanel = new DegeneratorZhaohuanBigKillPanel(this.skillId);
            }
            this.add2Parent(this._zhaohuanBigKillPanel);
            this._zhaohuanBigKillPanel.addEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
         }
         else if(this._skillType == SkillType.XINGHUI_WANGZHE_SPIRIT_TEJI && !XinghuiPetType.isFuBloodPet(this._pmService.getOperationPM(this._petInfo.raceId).pmData.getXinghuiType()))
         {
            if(this._gongmingBigKillPanel == null)
            {
               this._gongmingBigKillPanel = new XinghuiGongmingBigKillPanel(this.skillId);
            }
            this.add2Parent(this._gongmingBigKillPanel);
            this._gongmingBigKillPanel.addEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
         }
         else if(FightData.instance.fightSize == FightSize.TWO_VS_TWO)
         {
            this.update2V2EffectIcon();
         }
      }
      
      private function add2Parent(param1:Sprite) : void
      {
         if(this.parent != null)
         {
            param1.x = this.x;
            param1.y = this.y;
            this.parent.addChild(param1);
         }
      }
      
      private function onRollOutListener(param1:MouseEvent) : void
      {
         var _loc3_:CachedClip = null;
         if(!param1)
         {
            return;
         }
         var _loc2_:Point = new Point(param1.stageX,param1.stageY);
         if(this._zhaohuanBigKillPanel != null)
         {
            if(!this._zhaohuanBigKillPanel.hitTestPoint(_loc2_.x,_loc2_.y))
            {
               this._zhaohuanBigKillPanel.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
               DisplayUtil.stopAndRemove(this._zhaohuanBigKillPanel);
               this._zhaohuanBigKillPanel = null;
            }
         }
         if(this._gongmingBigKillPanel != null)
         {
            if(!this._gongmingBigKillPanel.hitTestPoint(_loc2_.x,_loc2_.y))
            {
               this._gongmingBigKillPanel.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
               DisplayUtil.stopAndRemove(this._gongmingBigKillPanel);
               this._gongmingBigKillPanel = null;
            }
         }
         if(this._extraAddedSkill != null)
         {
            if(!this._extraAddedSkill.hitTestPoint(_loc2_.x,_loc2_.y))
            {
               this._extraAddedSkill.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
               DisplayUtil.stopAndRemove(this._extraAddedSkill);
               this._extraAddedSkill = null;
            }
         }
         if(this._gqPFSShenHuanExtraSkillPl != null)
         {
            if(!this._gqPFSShenHuanExtraSkillPl.hitTestPoint(_loc2_.x,_loc2_.y))
            {
               this._gqPFSShenHuanExtraSkillPl.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
               DisplayUtil.stopAndRemove(this._gqPFSShenHuanExtraSkillPl);
               this._gqPFSShenHuanExtraSkillPl = null;
            }
         }
         if(this._gqXingZhiYuExtraSkillPl != null)
         {
            if(!this._gqXingZhiYuExtraSkillPl.hitTestPoint(_loc2_.x,_loc2_.y))
            {
               this._gqXingZhiYuExtraSkillPl.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
               DisplayUtil.stopAndRemove(this._gqXingZhiYuExtraSkillPl);
               this._gqXingZhiYuExtraSkillPl = null;
            }
         }
         if(this._gqMingYunBoYiExtraSkillPl != null)
         {
            if(!this._gqMingYunBoYiExtraSkillPl.hitTestPoint(_loc2_.x,_loc2_.y))
            {
               this._gqMingYunBoYiExtraSkillPl.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutListener);
               DisplayUtil.stopAndRemove(this._gqMingYunBoYiExtraSkillPl);
               this._gqMingYunBoYiExtraSkillPl = null;
            }
         }
         for each(_loc3_ in this._mc2v2EffectIcons)
         {
            DisplayUtil.stopAndRemove(_loc3_);
         }
      }
      
      private function removeSkillTips(param1:InteractiveObject) : void
      {
         TipsManager.getInstance().removeTips(param1);
      }
      
      private function addSkillTips(param1:InteractiveObject) : void
      {
         var _loc2_:String = "";
         var _loc3_:String = "";
         var _loc4_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         var _loc5_:Object = _loc4_.getPetSkillMes(this.id);
         var _loc6_:* = "";
         var _loc7_:int = int(TipsType.NORMAL);
         var _loc8_:Array = this._pmService.getOperationPM(this._petInfo.raceId).pmData.getGQNewSkill_UnchangeableSkill(true);
         var _loc9_:Array = this._pmService.getOperationPM(this._petInfo.raceId).pmData.getGQNewSkill_ReplacableSkills(true);
         if(this.isPassiveSkill())
         {
            _loc7_ = int(TipsType.FIGHTSKILL_BEIDONG);
         }
         else if(_loc8_.indexOf(this.id) != -1 || Boolean(PMSkillTypes.getIsGQZhuanshuSkill(this._pmSkill.getSkillType())))
         {
            _loc7_ = int(TipsType.FIGHTSKILL_ZHUANSHU);
         }
         else if(_loc9_.indexOf(this.id) != -1)
         {
            _loc7_ = int(TipsType.FIGHTSKILL_TONGYONG);
         }
         if(this.isPassiveSkill())
         {
            TipsManager.getInstance().replaceComplexTips(param1,_loc5_.pname + _loc2_,_loc5_.descriptor,100,-100,9,_loc7_);
         }
         else if(Boolean(SkillType.getIsDegeneratorSuperSpiritSkill(this._skillType)) || Boolean(SkillType.getIsXinghuiSuperSpiritSkill(this._skillType)))
         {
            TipsManager.getInstance().replaceComplexTips(param1,_loc5_.pname + " 威力：" + this.getSkillPowerDesc(_loc5_.power),_loc5_.descriptor,100,-100,9,_loc7_);
         }
         else if(SkillType.checkIsGQCommonSpiritSkill(this.id))
         {
            if(this._gameOptionSvr.isGQSimpleSkillView)
            {
               _loc6_ = this._pmSkill.oldEffectDesc;
            }
            else
            {
               _loc6_ = this._pmSkill.clientDesc;
            }
            _loc6_ += "\n-------\n当前拥有" + this._petInfo.curGQSoulNum + "光能。";
            if(this._petInfo.curGQSoulNum < this._pmSkill.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(this._petInfo))
            {
               _loc6_ += "\n-------\n光能不足，不能使用该技能！";
            }
            _loc3_ = this._pmSkill.newCnName + _loc2_;
            TipsManager.getInstance().replaceComplexTips(param1,_loc3_,_loc6_,100,-100,9,_loc7_);
         }
         else if(PMSkillTypes.isGQSkill(this._pmSkill.getSkillType()))
         {
            if(this._gameOptionSvr.isGQSimpleSkillView)
            {
               _loc6_ = this._pmSkill.oldEffectDesc;
            }
            else
            {
               _loc6_ = this._pmSkill.clientDesc;
            }
            _loc3_ = this._pmSkill.newCnName + _loc2_;
            TipsManager.getInstance().replaceComplexTips(param1,_loc3_,_loc6_,100,-100,9,_loc7_);
         }
         else if(this._enableState == DISABLE_REASON_NO_PP)
         {
            TipsManager.getInstance().replaceComplexTips(param1,"","快打开“道具”使用“活力豆”回复技能PP吧",100,-100,9);
         }
         else if(this._enableState == DISABLE_REASON_FREEZE_ATT)
         {
            TipsManager.getInstance().replaceComplexTips(param1,"","普通攻击技能暂时不可使用",100,-100,9);
         }
         else if(this._enableState == DISABLE_REASON_FREEZE_SATT)
         {
            TipsManager.getInstance().replaceComplexTips(param1,"","特殊攻击技能暂时不可使用",100,-100,9);
         }
         else
         {
            TipsManager.getInstance().replaceComplexTips(param1,_loc5_.pname + _loc2_,_loc5_.descriptor,100,-100,9,_loc7_);
         }
      }
      
      private function getSkillPowerDesc(param1:int) : String
      {
         if(param1 > 0)
         {
            return param1.toString();
         }
         return "未知";
      }
      
      private function isPassiveSkill() : Boolean
      {
         var _loc1_:int = int(this._pmSkill.getSkillType());
         return this._skillType == SkillType.PASSIVE || (_loc1_ == PMSkillTypes.DEGENERATOR_COMMON_SPIRIT_PO || _loc1_ == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_JUE || _loc1_ == PMSkillTypes.DEGENERATOR_LOCK_SKILL || _loc1_ == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_YU_PASSIVE || _loc1_ == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_BAO_PASSIVE || _loc1_ == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_ZHU_PASSIVE || _loc1_ == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_ZHAOHUAN_PASSIVE) && Boolean(this._pmSkill.getisDegeneratorSpiritPassive()) || _loc1_ == PMSkillTypes.XINGHUI_LOCK_SKILL || _loc1_ == PMSkillTypes.XINGHUI_PASSIVE_SKILL || _loc1_ == PMSkillTypes.HUN_DUN_XINGHUI_SKILL && this._petInfo.isUseHdxht > 0 || Boolean(PMSkillTypes.isGQSmallPassiveSkill(_loc1_));
      }
      
      public function set enabled(param1:Boolean) : void
      {
         if(this.isPassiveSkill() || Boolean(this._pmSkill.isSkillLock) || this._skillType == SkillType.DEGENERATOR_SUPER_SPIRIT_JUE || this._skillType == SkillType.DEGENERATOR_SUPER_SPIRIT_YU_PASSIVE || Boolean(SkillType.getIsXinghuiSuperSpiritSkill(this._skillType)) && this._petInfo.curXinghuiSoulNum < this._pmSkill.costSoulNum || Boolean(SkillType.checkIsGQCommonSpiritSkill(this.id)) && this._petInfo.curGQSoulNum < this._pmSkill.costSoulNum && (!StatusUtil.getIsinTouzhiCommonBuff(this._petInfo) && StatusUtil.getHunDunJueDouHp(this._petInfo) < 0))
         {
            this._btnSkill.enabled = false;
         }
         else
         {
            this._btnSkill.enabled = param1 && this._enableState == ENABLE;
            if(this._zhaohuanBigKillPanel != null)
            {
               this._zhaohuanBigKillPanel.setClickable(param1);
            }
            if(this._gongmingBigKillPanel != null)
            {
               this._gongmingBigKillPanel.setClickable(param1);
            }
            if(this._extraAddedSkill != null)
            {
               this._extraAddedSkill.setClickable(param1);
            }
            if(this._gqPFSShenHuanExtraSkillPl != null)
            {
               this._gqPFSShenHuanExtraSkillPl.setClickable(param1);
            }
            if(this._gqXingZhiYuExtraSkillPl != null)
            {
               this._gqXingZhiYuExtraSkillPl.setClickable(param1);
            }
            if(this._gqMingYunBoYiExtraSkillPl != null)
            {
               this._gqMingYunBoYiExtraSkillPl.setClickable(param1);
            }
         }
      }
      
      private function update() : void
      {
         if(this._enableState == DISABLE_WITH_NO_REASON && !PMSkillTypes.isGQSmallPassiveSkill(this._pmSkill.getSkillType()))
         {
            DisplayUtil.clearFilters(this);
            this._overState.setBGGray();
            this._upState.setBGGray();
         }
         else if(this._enableState != ENABLE && !PMSkillTypes.isGQSmallPassiveSkill(this._pmSkill.getSkillType()))
         {
            DisplayUtil.applyGray(this);
         }
         else
         {
            this._overState.clearBGGray();
            this._upState.clearBGGray();
            DisplayUtil.clearFilters(this);
         }
         this._btnSkill.enabled = this._enableState == ENABLE;
         if(this._skillInfo)
         {
            this._overState.update(this._skillInfo,this._petInfo);
            this._upState.update(this._skillInfo,this._petInfo);
         }
         this._btnSkill.upState = this._btnSkill.downState = this._upState;
         this._btnSkill.overState = this._overState;
         if(this.haveOnlyOneEnemy())
         {
            this._targetVSPlayer = FightData.instance.opponents[0];
         }
         this.updateEffectIcon();
         this.updateSuperSpiritMovie();
         this.updateGQSpecialTips();
         CallbackUtil.apply(this._refreshGQSoulCall);
      }
      
      private function getFreezeSkillState() : Array
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:PetBriefInfo = null;
         var _loc5_:Array = null;
         var _loc6_:int = 0;
         var _loc1_:Array = [];
         if(FightController.instance.pmmStatuses == null)
         {
            return _loc1_;
         }
         var _loc2_:int = 0;
         while(_loc2_ < FightController.instance.pmmStatuses.length)
         {
            _loc3_ = FightController.instance.pmmStatuses[_loc2_] as PlayerBattleInfo;
            if(!(_loc3_ == null || _loc3_.PMMasterId != FightData.instance.myInfo.PMMasterId))
            {
               _loc4_ = _loc3_.myPets[0] as PetBriefInfo;
               if(!(_loc4_ == null || _loc4_.status == null || _loc4_.status == ""))
               {
                  _loc5_ = _loc4_.status.split(",");
                  _loc6_ = 0;
                  while(_loc6_ < _loc1_.length)
                  {
                     if(_loc5_[_loc6_] == "58" || _loc5_[_loc6_] == "59")
                     {
                        _loc1_.push(_loc5_[_loc6_]);
                     }
                     _loc6_++;
                  }
                  break;
               }
            }
            _loc2_++;
         }
         return _loc1_;
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc4_:int = 0;
         var _loc5_:PlayerBattleInfo = null;
         var _loc6_:PetBriefInfo = null;
         if(!this.validate())
         {
            return;
         }
         this.selectNoRound();
         this.setSelect();
         var _loc2_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         var _loc3_:int = int(_loc2_.getPetSkillMes(this.skillId).range);
         FightEventDispatcher.instance.dispatchEvent(new FightInnerEvent(FightInnerEvent.CHANGE_USING_SKILL,{"skillBtn":this}));
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent(PetFightEvent.CLICK_SKILL_BUTTON,{}));
         switch(_loc3_)
         {
            case SkillRange.TEAMMATE:
               if(Boolean(FightData.instance.teammates) && FightData.instance.teammates.length <= 1)
               {
                  FightData.instance.targetSlot = FightData.instance.myInfo.operatingPlayer.slotId;
                  this.startUseSkill();
                  break;
               }
               this.addClickListener(true);
               break;
            case SkillRange.ENEMY_ONE:
               if(Boolean(FightData.instance.opponents) && FightData.instance.opponents.length <= 1)
               {
                  FightData.instance.targetSlot = FightData.instance.vsSlot;
                  this.startUseSkill();
                  break;
               }
               if(Boolean(FightData.instance.opponents) && FightData.instance.getCanBattlePlayerNum(FightData.instance.opponents) <= 1)
               {
                  FightData.instance.targetSlot = FightData.instance.getCanBattleSlot(FightData.instance.opponents);
                  this.startUseSkill();
                  break;
               }
               if(BSUtil.getIsInHunDunJueDouState())
               {
                  FightData.instance.targetSlot = FightData.instance.getCanBattleSlot(FightData.instance.opponents);
                  _loc4_ = 0;
                  while(_loc4_ < FightData.instance.opponents.length)
                  {
                     _loc5_ = FightData.instance.opponents[_loc4_];
                     _loc6_ = _loc5_.myPets[0];
                     if(_loc6_ != null && _loc6_.curHp > 0 && StatusUtil.getIsInHunDunJueDouState(_loc6_))
                     {
                        FightData.instance.targetSlot = _loc5_.slotId;
                     }
                     _loc4_++;
                  }
                  this.startUseSkill();
                  break;
               }
               this.addClickListener(false);
               break;
            default:
               FightData.instance.targetSlot = FightData.instance.myInfo.operatingPlayer.slotId;
               this.startUseSkill();
         }
      }
      
      private function onClickSkill(param1:PetFightEvent) : void
      {
         this.removeClickListener();
         if(param1.params.haveHit)
         {
            this.startUseSkill();
         }
      }
      
      private function removePetListen() : void
      {
         var _loc1_:PlayerBattleInfo = null;
         for each(_loc1_ in FightData.instance.playerInfo)
         {
            if(FightController.instance.fightPanel.petMCList[_loc1_.locaId])
            {
               if(FightController.instance.fightPanel.contains(FightController.instance.fightPanel.petMCList[_loc1_.locaId]))
               {
                  (FightController.instance.fightPanel.petMCList[_loc1_.locaId] as MCPetContainer).removeListen();
               }
            }
         }
      }
      
      public function startUseSkill(param1:Boolean = false) : void
      {
         this.removePetListen();
         var _loc2_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         FightController.instance.useSkill(this.skillId,FightData.instance.targetSlot,_loc2_.slotId,param1);
      }
      
      private function setSelect() : void
      {
         this._btnSkill.fixState(StaticButton.STATE_OVER);
      }
      
      private function removeSelect() : void
      {
         this._btnSkill.cancelFix();
      }
      
      private function selectNoRound() : void
      {
         if(this._pmSkill.getSkillType() == PMSkillTypes.HUN_DUN_XINGHUI_SKILL)
         {
            this._petInfo.setHdxht();
         }
      }
      
      private function addClickListener(param1:Boolean) : void
      {
         var _loc2_:PlayerBattleInfo = null;
         for each(_loc2_ in FightData.instance.playerInfo)
         {
            if(param1 && FightData.instance.isMySide(_loc2_.locaId) || !param1 && !FightData.instance.isMySide(_loc2_.locaId))
            {
               if(FightController.instance.fightPanel.contains(FightController.instance.fightPanel.petMCList[_loc2_.locaId]))
               {
                  FightController.instance.fightPanel.petMCList[_loc2_.locaId].addListen(_loc2_.slotId,param1);
               }
            }
         }
         FightEventDispatcher.instance.addEventListener(FightInnerEvent.CHANGE_USING_SKILL,this.changeUsingSkill);
         FightEventDispatcher.instance.addEventListener(PetFightEvent.CLICK_SKILL,this.onClickSkill);
      }
      
      private function changeUsingSkill(param1:FightInnerEvent) : void
      {
         this.removeClickListener();
         if(param1.params.skillBtn != this)
         {
            this.cancelUse();
         }
      }
      
      public function cancelUse() : void
      {
         this.removeClickListener();
         this.removePetListen();
         this.removeSelect();
      }
      
      private function onUseSkill(param1:SocketClientEvent) : void
      {
         if(FightData.instance.myInfo == null)
         {
            SocketClient.instance.removeEventListener(PetClient.RSPN_USE_SKILL + "",this.onUseSkill);
            return;
         }
         if(param1.params.id == this.skillId && Boolean(SkillType.getIsDegeneratorSuperSpiritSkill(this._skillType)))
         {
            this._petInfo.curDegeneratorSoulNum -= this._pmSkill.costSoulNum;
            this.update();
         }
         else if(param1.params.id == this.skillId && Boolean(SkillType.getIsXinghuiSuperSpiritSkill(this._skillType)))
         {
            this._petInfo.curXinghuiSoulNum -= this._pmSkill.costSoulNum;
            this.update();
         }
         else if(param1.params.id == this.skillId && Boolean(SkillType.checkIsGQCommonSpiritSkill(this.skillId)))
         {
            this.update();
         }
         var _loc2_:Boolean = Boolean(param1.params.dec);
         var _loc3_:* = FightData.instance.myInfo.operatingPlayer.slotId == param1.params.reqSId;
         if(_loc2_ && _loc3_ && param1.params.id == this.skillId)
         {
            --this._canUseTime;
         }
      }
      
      private function removeClickListener() : void
      {
         FightEventDispatcher.instance.removeEventListener(FightInnerEvent.CHANGE_USING_SKILL,this.changeUsingSkill);
         FightEventDispatcher.instance.removeEventListener(PetFightEvent.CLICK_SKILL,this.onClickSkill);
      }
      
      public function useSkill() : Boolean
      {
         if(this.validate())
         {
            FightEventDispatcher.instance.dispatchEvent(new FightInnerEvent(FightInnerEvent.CHANGE_USING_SKILL,{"skillBtn":this}));
            this.removeClickListener();
            this.removePetListen();
            this.setSelect();
            return true;
         }
         return false;
      }
      
      private function validate() : Boolean
      {
         if(this._enableState != ENABLE || this.isPassiveSkill() || Boolean(this._pmSkill.isSkillLock) || !this._btnSkill.enabled || this._skillType == SkillType.DEGENERATOR_SUPER_SPIRIT_ZHAOHUAN || this._skillType == SkillType.XINGHUI_WANGZHE_SPIRIT_TEJI && !XinghuiPetType.isFuBloodPet(this._pmService.getOperationPM(this._petInfo.raceId).pmData.getXinghuiType()) || Boolean(SkillType.getIsXinghuiSuperSpiritSkill(this._skillType)) && this._petInfo.curXinghuiSoulNum < this._pmSkill.costSoulNum || Boolean(SkillType.checkIsGQCommonSpiritSkill(this._pmSkill.skillId)) && (this._petInfo.curGQSoulNum < this._pmSkill.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(this._petInfo)))
         {
            return false;
         }
         return true;
      }
      
      private function get skillId() : int
      {
         return this._pmSkill.skillId;
      }
   }
}

