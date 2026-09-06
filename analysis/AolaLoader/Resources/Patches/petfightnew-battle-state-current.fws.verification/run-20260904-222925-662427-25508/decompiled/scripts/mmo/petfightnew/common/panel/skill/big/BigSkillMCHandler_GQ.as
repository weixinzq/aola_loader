package mmo.petfightnew.common.panel.skill.big
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.common.utils.tips.TipsType;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.option.IGameOptionService;
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
   import mmo.interfaces.pet.data.GQOutburstCopySkillParse;
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
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.component.CachedClip;
   import mmo.petfightnew.common.constant.FightSize;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.event.FightInnerEvent;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.handler.attributeicon.FightAttributeIconCacheKey;
   import mmo.petfightnew.common.handler.attributeicon.FightAttributeIconHandler;
   import mmo.petfightnew.common.helper.SkillHelper;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.panel.GQEternityContractPlHandler;
   import mmo.petfightnew.common.panel.GQMingYunBoYiExtraSkillPanel;
   import mmo.petfightnew.common.panel.GQPFSShenHuanExtraSkillPanel;
   import mmo.petfightnew.common.panel.GQXingZhiYuExtraSkillPanel;
   import mmo.petfightnew.common.panel.skill.EffectIcon;
   import mmo.petfightnew.common.panel.skill.EffectIcon2v2;
   import mmo.petfightnew.common.util.GQPetHelper;
   import mmo.petfightnew.common.util.PositionUtil;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActMovieHelper;
   import mmo.play.petfight.common.config.FightResConfig;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   public class BigSkillMCHandler_GQ extends BigSkillMCHandler
   {
      
      private var _petSkillMesSvr:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
      
      private var _gameOptionSvr:IGameOptionService;
      
      private var _originPoint:Point;
      
      private var _eternityContractPanelHandler:GQEternityContractPlHandler;
      
      private var _lianSuoAttributeIcon:FightAttributeIconHandler;
      
      private var _gqPFSShenHuanExtraSkillPl:GQPFSShenHuanExtraSkillPanel = null;
      
      private var _petInfo:PetBriefInfo;
      
      private var _gqTianyiSpiritSkillIds:Array = [];
      
      private var _gqXingZhiYuExtraSkillPl:GQXingZhiYuExtraSkillPanel = null;
      
      private var _gqMingYunBoYiExtraSkillPl:GQMingYunBoYiExtraSkillPanel = null;
      
      private var _isRollOverEternityZhanyi:Boolean = false;
      
      private var _effectIcon:CachedClip;
      
      private var _mc2v2EffectIcons:Array = [];
      
      private var _targetVSPlayer:PlayerBattleInfo = null;
      
      public function BigSkillMCHandler_GQ()
      {
         super();
         this._gameOptionSvr = ServicePool.instance.getService(IGameOptionService);
      }
      
      override public function initView(param1:CachedClip) : void
      {
         super.initView(param1);
         this._originPoint = new Point(this._mcChangeView.x,this._mcChangeView.y);
         FightEventDispatcher.instance.addEventListener(FightInnerEvent.ON_MOUSE_OVER_PET,this.onMouseRoleOverPetListener);
         FightEventDispatcher.instance.addEventListener(FightInnerEvent.ON_MOUSE_OUT_PET,this.onMouseRollOutPetListener);
      }
      
      override public function update() : void
      {
         var _loc6_:* = null;
         var _loc7_:MovieClip = null;
         var _loc8_:MovieClip = null;
         var _loc9_:Sprite = null;
         var _loc10_:GQYiRenWujinMingtuSkillParse = null;
         var _loc11_:GQDengShenChangJieSkillParse = null;
         var _loc12_:GQJiangShenSkillParse = null;
         var _loc13_:int = 0;
         var _loc14_:MovieClip = null;
         var _loc15_:Boolean = false;
         var _loc16_:int = 0;
         var _loc17_:GQOutburstCopySkillParse = null;
         var _loc18_:int = 0;
         var _loc19_:int = 0;
         var _loc20_:String = null;
         super.update();
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         this._petInfo = _loc1_;
         if(this.haveOnlyOneEnemy())
         {
            this._targetVSPlayer = FightData.instance.opponents[0];
         }
         this.updateEffectIcon();
         if(this._pmService.getOperationPM(_loc1_.raceId) == null || this._pmService.getOperationPM(_loc1_.raceId).pmData == null)
         {
            throw new Error("PM数据有问题，应该是没有" + _loc1_.raceId + "的" + _loc1_.name + "这只亚比！");
         }
         var _loc2_:PMData = this._pmService.getOperationPM(_loc1_.raceId).pmData;
         var _loc3_:int = int(_loc1_.curGQSoulNum);
         var _loc4_:PMSkill = GQPetHelper.getGQPetBigSkill(_loc1_);
         if(_loc4_ == null && _loc1_.usingGQSkillType == 0)
         {
            this._mcChangeView.gotoAndStop(19);
            return;
         }
         if(_loc4_ == null)
         {
            this._mcChangeView.gotoAndStop(18);
         }
         else
         {
            if(this._gameOptionSvr.isGQSimpleSkillView)
            {
               _loc6_ = _loc4_.oldEffectDesc;
            }
            else
            {
               _loc6_ = _loc4_.clientDesc;
            }
            this._mcChangeView.gotoAndStop(17);
            _loc7_ = this._mcChangeView.getChildByName("mcSoulNum0") as MovieClip;
            _loc8_ = this._mcChangeView.getChildByName("mcSoulNum1") as MovieClip;
            if(PMSkillTypes.GQ_YIREN_KILL_BIG == _loc4_.getSkillType())
            {
               _loc7_.visible = false;
               _loc8_.visible = false;
            }
            else
            {
               _loc7_.visible = true;
               _loc8_.visible = true;
               ArtNumberManager.setNumber([_loc7_,_loc8_],_loc4_.costSoulNum,false);
            }
            _loc9_ = this._mcChangeView.getChildByName("mctipslayer") as Sprite;
            if(_loc9_ == null)
            {
               _loc9_ = this._mcChangeView.curClip as Sprite;
            }
            _loc10_ = GQYiRenWujinMingtuSkillParse.getYiRenWujinMingtuSkillData(this._petInfo.raceId);
            _loc11_ = GQDengShenChangJieSkillParse.getDengShenChangJieSkillParse(this._petInfo.raceId);
            _loc12_ = GQJiangShenSkillParse.getGQJiangShenSkillParse(this._petInfo.raceId);
            _loc13_ = int(GQPetType.getYiRenSkillCost(this._petInfo.raceId,_loc4_.skillId));
            _loc14_ = this._mcChangeView.getChildByName("mvSoul") as MovieClip;
            _loc14_.mouseEnabled = _loc14_.mouseChildren = false;
            _loc6_ += "\n-------\n当前拥有" + _loc3_ + "光能。";
            if(StatusUtil.getHunDunJueDouHp(this._petInfo) >= 0)
            {
               _loc9_.buttonMode = true;
               _loc14_.play();
               _loc14_.visible = true;
            }
            else if(_loc3_ < _loc4_.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(_loc1_))
            {
               _loc6_ += "\n-------\n光能不足，不能使用该技能！";
               _loc9_.buttonMode = false;
               _loc14_.stop();
               _loc14_.visible = false;
            }
            else if(_loc10_ && _loc10_.getIsAfterChangeView(this._petInfo) && StatusUtil.getYirenShieldByPbi(this._petInfo)[0] < _loc13_)
            {
               _loc9_.buttonMode = false;
               _loc14_.stop();
               _loc14_.visible = false;
            }
            else
            {
               _loc9_.buttonMode = true;
               if(GQDiJieShiSkillParse.getIsChangeView(this._petInfo))
               {
                  _loc14_.stop();
                  _loc14_.visible = false;
                  if(StatusUtil.getIsDijieshiBigSkillUsed(this._petInfo))
                  {
                     _loc9_.buttonMode = false;
                     _loc6_ += "\n-------\n已使用过！";
                  }
               }
               else
               {
                  _loc14_.play();
                  _loc14_.visible = true;
               }
            }
            if(GQPetType.isOutburstCopy(_loc2_.getGQType()))
            {
               ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",1);
               _loc17_ = GQOutburstCopySkillParse.getOutburstCopySkillParse(_loc1_.raceId);
               _loc18_ = int(_loc17_.getKillBigSkillId(_loc1_.skills));
               _loc19_ = int(_pmService.customData.pmSkillMap.getSkill(_loc18_).getSkillType());
               if(_loc19_ != PMSkillTypes.GQ_KILL_BIG)
               {
                  ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",_loc19_ - 55);
               }
            }
            else if(Boolean(GQPetType.isArmorBurst(_loc2_.getGQType())) && Boolean(GQArmorBurstSkillParse.getIsAfterChangeView(_loc1_)))
            {
               ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",2);
            }
            else if(GQPetType.isYiRen(_loc2_.getGQType()) && _loc10_ && Boolean(_loc10_.getIsAfterChangeView(_loc1_)))
            {
               ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",6);
            }
            else if(Boolean(GQPetType.isDiJieShi(_loc2_.getGQType())) && PMSkillTypes.GQ_DIJIESHI_KILL_BIG == _loc4_.getSkillType())
            {
               ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",7);
            }
            else if(GQPetType.isXingZhiYu(_loc2_.getGQType()))
            {
               ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",8);
            }
            else if(GQPetType.isJuexing(_loc2_.getGQType()))
            {
               if(PMSkillTypes.GQ_JUEXING_YUANMAO_KILL_BIG == _loc4_.getSkillType())
               {
                  ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",9);
               }
               else if(PMSkillTypes.GQ_JUEXING_ZHENSHEN_KILL_BIG == _loc4_.getSkillType())
               {
                  ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",10);
               }
               else
               {
                  ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",1);
               }
            }
            else if(GQPetType.isMingYunBoYi(_loc2_.getGQType()))
            {
               ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",11);
            }
            else if(Boolean(GQPetType.isDengShenChangJie(_loc2_.getGQType())) && Boolean(_loc11_.getIsAfterChangeView(_loc1_)))
            {
               ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",12);
            }
            else if(Boolean(GQPetType.isBuxiuLvtu(_loc2_.getGQType())) && StatusUtil.getIsBuxiuJixingState(_loc1_))
            {
               ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",12 + _loc4_.level);
            }
            else if(Boolean(GQPetType.isJiangShen(_loc2_.getGQType())) && Boolean(_loc12_.getIsAfterChangeView(_loc1_)))
            {
               ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",18);
            }
            else
            {
               ActComHelper.setMcFrame(_mcChangeView,"mcBackGround",1);
            }
            _loc15_ = Boolean(GQPetType.isXingZhiYu(this._pmService.getOperationPM(_loc1_.raceId).pmData.getGQType()));
            _loc16_ = int(GQXingZhiYuSkillParse.getXingZhiYuSpiritSkillId(_loc1_));
            if(!_loc15_ || _loc16_ <= 0)
            {
               _loc20_ = _loc4_.newCnName + "\n威力：" + this.getSkillPowerDesc(_loc4_.power);
               TipsManager.getInstance().replaceComplexTips(_loc9_,_loc20_,_loc6_,100,-100,9,TipsType.FIGHTSKILL_BAOFA);
            }
         }
         if(FightData.instance.fightSize == FightSize.TWO_VS_TWO)
         {
            this._mcChangeView.addEventListener(MouseEvent.ROLL_OVER,this.onRollOverChangeViewListener);
            this._mcChangeView.addEventListener(MouseEvent.ROLL_OUT,this.onRollOutChangeViewListener);
         }
         var _loc5_:MovieClip = this._mcChangeView.getChildByName("mcGQExtSkill") as MovieClip;
         if(_loc5_)
         {
            this.setLianSuoIsUseBig(_loc1_);
            if(_loc1_.usingGQSkillType == 1 && !GQPetType.isAdaptSystem(_loc2_.getGQType(),_loc1_))
            {
               _loc5_.visible = false;
               return;
            }
            _loc5_.visible = true;
            DisplayUtil.clearChildren(_loc5_);
            this.updateExtraSkill(_loc5_,_loc1_);
         }
      }
      
      private function updateExtraSkill(param1:MovieClip, param2:PetBriefInfo) : void
      {
         var gqExtSkillMc:MovieClip = null;
         var mcSubGQExtSkill:MovieClip = null;
         var mcGQExtSkill:MovieClip = param1;
         var petInfo:PetBriefInfo = param2;
         var gqExtSkillCls:Class = FightData.instance.applicationDomain.getDefinition(FightResConfig.GQ_ExtBigSkillMc_ClsName) as Class;
         if(gqExtSkillCls)
         {
            gqExtSkillMc = new gqExtSkillCls() as MovieClip;
            gqExtSkillMc.name = "mcGQSubExtSkill";
            mcGQExtSkill.addChild(gqExtSkillMc);
            mcSubGQExtSkill = gqExtSkillMc;
            mcSubGQExtSkill.visible = true;
            this.updateEternityContractSkill(petInfo,mcSubGQExtSkill.mcEternityContract);
            this.updateArmorBurstSkill(petInfo,mcSubGQExtSkill.mcArmorBurst);
            this.updateLianSuoSkill(petInfo,mcSubGQExtSkill.mcLianSuo);
            this.updateGuangjinSkill(petInfo,mcSubGQExtSkill.mcGuangJin);
            this.updateQiYuanSkill(petInfo,mcSubGQExtSkill.mcQiYuan);
            this.updateTianYiSkill(petInfo,mcSubGQExtSkill.mcTianYi);
            this.updateQunxingZhiyu(petInfo,mcSubGQExtSkill.mcQunxingZhiyu);
            this.updateYiRenSkill(petInfo,mcSubGQExtSkill.mcYiRen);
            this.updateShenXuSkill(petInfo,mcSubGQExtSkill.mcShenXu);
            this.updateXingZhiYuSkill(petInfo,mcSubGQExtSkill.mcXingZhiYu);
            this.updateJueXingSkill(petInfo,mcSubGQExtSkill.mcJuexing);
            this.updateYingHunSkill(petInfo,mcSubGQExtSkill.mcYingHun);
            this.updateWumangXingji(petInfo,mcSubGQExtSkill.mcWumangXingji);
            this.updateEternityZhanyiSkill(petInfo,mcSubGQExtSkill.mcEternityZhanyi);
            this.updateShenqiSkill(petInfo,mcSubGQExtSkill.mcShenqi);
            this.updateYanhuaZhiyao(petInfo,mcSubGQExtSkill.mcYanhuaZhiyao);
            this.updateZhigaoRongyao(petInfo,mcSubGQExtSkill.mcZhigaoRongyao);
            this.updateMiBao(petInfo,mcSubGQExtSkill.mcMiBao);
            this.updateMingYunBoYi(petInfo,mcSubGQExtSkill.mcMingYunBoYi);
            this.updateJiuRiChongXian(petInfo,mcSubGQExtSkill.mcJiuRiChongXian);
            this.updateHuanLingShi(petInfo,mcSubGQExtSkill.mcHuanLingShi);
            this.updatXingHuanShi(petInfo,mcSubGQExtSkill.mcXingHuanShi);
            this.updateDengShenChangJie(petInfo,mcSubGQExtSkill.mcDengShenChangJie);
            this.updateBuxiuLvtu(petInfo,mcSubGQExtSkill.mcBuxuLvtu);
            this.updateWanyuZhichao(petInfo,mcSubGQExtSkill.mcWanyuZhichao);
            this.updateHundunJuedou(petInfo,mcSubGQExtSkill.mcHundunJuedou);
            this.updateShiKongFangZhu(petInfo,mcSubGQExtSkill.mcShiKongFangZhu);
            this.updateJiangShen(petInfo,mcSubGQExtSkill.mcJiangShen);
            this.updateShenYuTianGang(petInfo,mcSubGQExtSkill.mcShenYuTianGang);
            this.updateZhenLiFaDian(petInfo,mcSubGQExtSkill.mcZhenLiFaDian);
            this.updateLiejieZhixi(petInfo,mcSubGQExtSkill.mcLiejieZhixi);
            return;
         }
         ResScheduler.getRes(ResParams.createTemp("pet/petfightnew_gqresource",function(param1:*, param2:ApplicationDomain):*
         {
            updateExtraSkill(mcGQExtSkill,petInfo);
         },FightResConfig.GQ_ExtBigSkillMc_ClsName));
      }
      
      private function onRollOverChangeViewListener(param1:MouseEvent) : void
      {
         this.update2V2EffectIcon();
      }
      
      private function onRollOutChangeViewListener(param1:MouseEvent) : void
      {
         var _loc2_:CachedClip = null;
         for each(_loc2_ in this._mc2v2EffectIcons)
         {
            DisplayUtil.stopAndRemove(_loc2_);
         }
      }
      
      private function update2V2EffectIcon() : void
      {
         var _loc2_:Array = null;
         var _loc3_:int = 0;
         var _loc4_:PlayerBattleInfo = null;
         var _loc5_:PetBriefInfo = null;
         var _loc6_:Object = null;
         var _loc7_:int = 0;
         var _loc8_:Point = null;
         var _loc9_:MovieClip = null;
         var _loc10_:MovieClip = null;
         var _loc11_:CachedClip = null;
         var _loc1_:PMSkill = GQPetHelper.getGQPetBigSkill(this._petInfo);
         if(_loc1_ != null)
         {
            _loc2_ = FightData.instance.opponents;
            _loc3_ = 0;
            while(_loc3_ < _loc2_.length)
            {
               _loc4_ = _loc2_[_loc3_];
               if((_loc4_) && _loc4_.myPets.length > 0 && (_loc4_.myPets[0] as PetBriefInfo).curHp > 0)
               {
                  _loc5_ = _loc4_.myPets[0];
                  _loc6_ = this._petSkillMesSvr.getPetMes(_loc5_.raceId);
                  _loc7_ = this._petSkillMesSvr.compareAttributeRelation(_loc1_.attributeType,_loc6_.attribute,_loc6_.attribute2) + 1;
                  if(this._mc2v2EffectIcons[_loc3_] == null)
                  {
                     _loc10_ = new EffectIcon2v2() as MovieClip;
                     _loc11_ = new CachedClip(_loc10_);
                     this._mc2v2EffectIcons[_loc3_] = _loc11_;
                  }
                  FightController.instance.fightPanel.layerPetUp.addChild(this._mc2v2EffectIcons[_loc3_]);
                  this._mc2v2EffectIcons[_loc3_].gotoAndStop(_loc7_);
                  _loc8_ = PositionUtil.getDefaultPosition(_loc4_.locaId);
                  this._mc2v2EffectIcons[_loc3_].x = _loc8_.x + 100;
                  this._mc2v2EffectIcons[_loc3_].y = _loc8_.y;
                  _loc9_ = this._mc2v2EffectIcons[_loc3_].getChildByName("mc") as MovieClip;
                  (_loc9_) && _loc9_.gotoAndPlay(1);
               }
               _loc3_++;
            }
         }
      }
      
      protected function updateEternityContractSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         if(!this._eternityContractPanelHandler)
         {
            this._eternityContractPanelHandler = new GQEternityContractPlHandler();
         }
         this._eternityContractPanelHandler.refresh(param1,param2);
      }
      
      private function updateArmorBurstSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc7_:int = 0;
         var _loc8_:* = false;
         var _loc9_:SimpleButton = null;
         var _loc10_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isArmorBurst(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         TipsManager.getInstance().removeTips(param2);
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:GQArmorBurstSkillParse = GQArmorBurstSkillParse.getArmorBurstSkillData(param1.raceId);
         var _loc5_:int = int(_loc4_.armorBurstSkillId);
         var _loc6_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
         if(GQArmorBurstSkillParse.getIsAfterChangeView(param1))
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
         else
         {
            param2.visible = true;
            _loc7_ = int(GQArmorBurstSkillParse.getSkillCd(param1));
            _loc8_ = _loc7_ > 0;
            if(_loc7_ > 0)
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,_loc7_ + "回合后方可使用");
            }
            else if(_loc6_.costSoulNum > param1.curGQSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(param1))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"光能不足，不能使用该技能！");
            }
            else if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc5_))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用！");
            }
            else
            {
               param2.gotoAndStop(1);
               _loc9_ = param2.getChildByName("btnArmorBurst") as SimpleButton;
               _loc9_.enabled = !_loc8_ && (_loc6_.costSoulNum <= param1.curGQSoulNum || StatusUtil.getIsinTouzhiCommonBuff(param1));
               _loc9_.mouseEnabled = !_loc8_ && (_loc6_.costSoulNum <= param1.curGQSoulNum || StatusUtil.getIsinTouzhiCommonBuff(param1));
               _loc10_ = _loc6_.newCnName + "\n威力：" + getSkillPowerDesc(_loc6_.power);
               TipsManager.getInstance().replaceComplexTips(param2,_loc10_,_loc6_.clientDesc,100,-100,9);
            }
         }
         ActComHelper.setMcFrame(param2,"mcNum",_loc6_.costSoulNum);
      }
      
      private function updateLianSuoSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc3_:Boolean = Boolean(GQPetType.isLianSuo(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         param2.gotoAndStop(1);
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:GQLianSuoSkillParse = GQLianSuoSkillParse.getLianSuoSkillData(param1.raceId);
         var _loc5_:int = int(_loc4_.getLianSuoSkillId(param1.skills.concat()));
         if(_loc5_ == -1)
         {
            param2.visible = false;
            return;
         }
         param2.visible = true;
         var _loc6_:int = int(_loc4_.getCurLianSuoSkillIndex(_loc5_));
         var _loc7_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
         param2.gotoAndStop(_loc6_ + 1);
         var _loc8_:int = int(param1.curGQSoulNum);
         var _loc9_:SimpleButton = param2.getChildByName("btnLianSuoSkill") as SimpleButton;
         if(_loc8_ < _loc7_.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(param1))
         {
            _loc9_.enabled = false;
         }
         else if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc5_))
         {
            _loc9_.enabled = false;
         }
         else
         {
            _loc9_.enabled = true;
         }
         var _loc10_:String = _loc7_.newCnName + "\n威力：" + getSkillPowerDesc(_loc7_.power);
         TipsManager.getInstance().replaceComplexTips(param2,_loc10_,_loc7_.clientDesc,100,-100,9);
         ActComHelper.setMcFrame(param2,"mcSoulNum",_loc7_.costSoulNum);
         var _loc11_:MovieClip = param2.getChildByName("mcAttHolder") as MovieClip;
         if(_loc11_)
         {
            if(this._lianSuoAttributeIcon)
            {
               this._lianSuoAttributeIcon.dispose();
               this._lianSuoAttributeIcon = null;
            }
            this._lianSuoAttributeIcon = new FightAttributeIconHandler(_loc11_,FightAttributeIconCacheKey.MIDDLE);
            this._lianSuoAttributeIcon.setIcon(_loc7_.attributeType);
         }
      }
      
      private function setLianSuoIsUseBig(param1:PetBriefInfo) : void
      {
         var _loc2_:PMSkill = GQPetHelper.getGQPetBigSkill(param1);
         var _loc3_:MovieClip = this._mcChangeView.getChildByName("mcLianSuoIsUse") as MovieClip;
         if(!_loc3_)
         {
            return;
         }
         var _loc4_:int = int(this._pmService.getOperationPM(param1.raceId).pmData.getGQType());
         var _loc5_:Boolean = Boolean(GQPetType.isLianSuo(_loc4_));
         if(!_loc5_ || param1.usingGQSkillType == 1 && !GQPetType.isAdaptSystem(_loc4_,param1) || !_loc2_)
         {
            _loc3_.visible = false;
            _loc3_.gotoAndStop(1);
            return;
         }
         var _loc6_:GQLianSuoSkillParse = GQLianSuoSkillParse.getLianSuoSkillData(param1.raceId);
         _loc3_.visible = true;
         _loc3_.gotoAndStop(_loc6_.getIsUseSmallSkill(param1,_loc2_.skillId) ? 2 : 1);
      }
      
      private function updateGuangjinSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc7_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isGuangJin(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.stop();
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:GQGuangJinSkillParse = GQGuangJinSkillParse.getGuangJinSkillData(param1.raceId);
         var _loc5_:int = int(_loc4_.getGuangJinSkillId(param1.skills));
         if(_loc5_ == -1)
         {
            param2.visible = false;
            return;
         }
         var _loc6_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
         if(FightData.instance.myInfo.isSkillUsed(param1.id,_loc5_))
         {
            param2.gotoAndStop(2);
            TipsManager.getInstance().replaceTips(param2,"本回合已用");
         }
         else if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc5_))
         {
            param2.gotoAndStop(2);
            TipsManager.getInstance().replaceTips(param2,"不可使用");
         }
         else if(_loc4_.getCanUseSkill(param1))
         {
            param2.gotoAndStop(1);
            _loc7_ = _loc6_.newCnName + "\n威力：" + getSkillPowerDesc(_loc6_.power);
            TipsManager.getInstance().replaceComplexTips(param2,_loc7_,_loc6_.clientDesc,100,-100,9);
         }
         else
         {
            param2.gotoAndStop(2);
            TipsManager.getInstance().replaceTips(param2,"本场战斗次数用光");
         }
      }
      
      private function updateQiYuanSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc6_:PMSkill = null;
         var _loc7_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isQiYuan(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:GQQiYuanSkillParse = GQQiYuanSkillParse.getGQQiYuanSkillParse(param1.raceId);
         var _loc5_:int = int(_loc4_.getQiYuanSkillId(param1.skills));
         if(_loc5_ > 0)
         {
            _loc6_ = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
            if(_loc4_.getIsSkillBeLocked(param1))
            {
               param2.gotoAndStop(1);
               TipsManager.getInstance().replaceTips(param2,"未解锁");
            }
            else if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc5_))
            {
               param2.gotoAndStop(3);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else if(_loc4_.getCanUseSkill(param1))
            {
               param2.gotoAndStop(2);
               _loc7_ = _loc6_.newCnName + "\n威力：" + getSkillPowerDesc(_loc6_.power);
               TipsManager.getInstance().replaceComplexTips(param2,_loc7_,_loc6_.clientDesc,100,-100,9);
            }
            else
            {
               param2.gotoAndStop(3);
               TipsManager.getInstance().replaceTips(param2,"已使用");
            }
         }
         else
         {
            param2.gotoAndStop(1);
            TipsManager.getInstance().replaceTips(param2,"未解锁");
         }
      }
      
      private function updateTianYiSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _tianYiSkillParse:GQTianYiSkillParse;
         var raceSkillIds:Array;
         var pbiSkillIds:Array;
         var isUsedTianyiSkill:Boolean;
         var k:int;
         var i:int;
         var subTianyiMc:MovieClip = null;
         var onRollOverTianyi:Function = null;
         var onRollOutTianyi:Function = null;
         var skill:PMSkill = null;
         var j:int = 0;
         var useSkill:PMSkill = null;
         var tips:String = null;
         var petInfo:PetBriefInfo = param1;
         var mcTianYi:MovieClip = param2;
         onRollOverTianyi = function(param1:MouseEvent):void
         {
            subTianyiMc.visible = true;
         };
         onRollOutTianyi = function(param1:MouseEvent):void
         {
            subTianyiMc.visible = false;
         };
         var isTianYi:Boolean = Boolean(GQPetType.isTianYi(this._pmService.getOperationPM(petInfo.raceId).pmData.getGQType()));
         mcTianYi.visible = isTianYi;
         if(!isTianYi)
         {
            DisplayUtil.stopAndRemove(mcTianYi);
            return;
         }
         subTianyiMc = mcTianYi.getChildByName("mcSubTianyi") as MovieClip;
         mcTianYi.addEventListener(MouseEvent.ROLL_OVER,onRollOverTianyi);
         mcTianYi.addEventListener(MouseEvent.ROLL_OUT,onRollOutTianyi);
         subTianyiMc.visible = false;
         _tianYiSkillParse = GQTianYiSkillParse.getGQTianYiSkillParse(petInfo.raceId);
         raceSkillIds = _tianYiSkillParse.spiritSkillIds;
         pbiSkillIds = _tianYiSkillParse.getTianyiSpiritSkillIds(petInfo);
         this._gqTianyiSpiritSkillIds = [];
         isUsedTianyiSkill = false;
         k = 0;
         while(k < pbiSkillIds.length)
         {
            if(FightData.instance.myInfo.isSkillUsed(petInfo.id,pbiSkillIds[k]))
            {
               isUsedTianyiSkill = true;
            }
            k++;
         }
         i = 0;
         while(i < raceSkillIds.length)
         {
            skill = this._pmService.customData.pmSkillMap.getSkill(raceSkillIds[i]);
            j = 0;
            while(j < pbiSkillIds.length)
            {
               if(skill.skillSerials.indexOf(pbiSkillIds[j]) != -1)
               {
                  useSkill = this._pmService.customData.pmSkillMap.getSkill(pbiSkillIds[j]);
                  if(isUsedTianyiSkill)
                  {
                     ActComHelper.refreshObj(subTianyiMc,"mcChess" + i,true,"已使用","",i + 1);
                  }
                  else if(!StatusUtil.getCanUseSkillWithToteOrBuff(petInfo,useSkill.skillId))
                  {
                     ActComHelper.refreshObj(subTianyiMc,"mcChess" + i,true,"不可使用","",i + 1);
                  }
                  else
                  {
                     ActComHelper.refreshObj(subTianyiMc,"mcChess" + i,false,"","",i + 1);
                     tips = useSkill.newCnName + "\n威力：" + getSkillPowerDesc(useSkill.power);
                     TipsManager.getInstance().replaceComplexTips(ActComHelper.getChildNode(subTianyiMc,"mcChess" + i) as MovieClip,tips,useSkill.clientDesc);
                  }
                  this._gqTianyiSpiritSkillIds[i] = pbiSkillIds[j];
                  break;
               }
               j++;
            }
            if(j >= pbiSkillIds.length)
            {
               ActComHelper.refreshObj(subTianyiMc,"mcChess" + i,true,"未解锁","",i + 1);
               this._gqTianyiSpiritSkillIds[i] = 0;
            }
            i++;
         }
      }
      
      private function updateQunxingZhiyu(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc9_:int = 0;
         var _loc10_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isQunxingZhiyu(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.stop();
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:GQQunxingZhiyuSkillParse = GQQunxingZhiyuSkillParse.getQunxingZhiyuSkillData(param1.raceId);
         var _loc5_:int = int(_loc4_.getQunxingZhiyuSkillId(param1.skills));
         if(_loc5_ == -1)
         {
            param2.visible = false;
            return;
         }
         var _loc6_:int = int(GQPetType.getQunXingZhiYuIconFrame(param1.raceId % 10000));
         param2.gotoAndStop(_loc6_);
         var _loc7_:MovieClip = param2.getChildByName("mcSub") as MovieClip;
         if(_loc6_ == 1)
         {
            _loc9_ = 0;
            while(_loc9_ < 8)
            {
               ActComHelper.setMcFrame(_loc7_,"mc" + _loc9_,_loc4_.getQunxingZhiyuBuffLv(param1) > _loc9_ ? 1 : 2);
               ActComHelper.setMcEnable(_loc7_,"mc" + _loc9_,false);
               _loc9_++;
            }
         }
         var _loc8_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
         if(FightData.instance.myInfo.isSkillUsed(param1.id,_loc5_))
         {
            ActComHelper.refreshObj(_loc7_,"btnQunxingZhiyu",true,"本回合已用");
         }
         else if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc5_))
         {
            ActComHelper.refreshObj(_loc7_,"btnQunxingZhiyu",true,"不可使用");
         }
         else if(_loc4_.getCanUseSkill(param1))
         {
            ActComHelper.refreshObj(_loc7_,"btnQunxingZhiyu",false);
            _loc10_ = _loc8_.newCnName + "\n威力：" + getSkillPowerDesc(_loc8_.power);
            TipsManager.getInstance().replaceComplexTips(_loc7_,_loc10_,_loc8_.clientDesc,100,-100,9);
         }
         else
         {
            ActComHelper.refreshObj(_loc7_,"btnQunxingZhiyu",true,"本场战斗次数用光");
         }
      }
      
      private function updateYiRenSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc8_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isYiRen(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         TipsManager.getInstance().removeTips(param2);
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:GQYiRenWujinMingtuSkillParse = GQYiRenWujinMingtuSkillParse.getYiRenWujinMingtuSkillData(param1.raceId);
         var _loc5_:int = int(_loc4_.yirenSkillId);
         var _loc6_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
         var _loc7_:Object = GQPetType.getYiRenObject(param1.raceId);
         if(_loc4_ && _loc4_.getIsAfterChangeView(param1) || !_loc4_.getIsYirenUnlockByPbi(param1))
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
         else
         {
            param2.visible = true;
            if(FightData.instance.myInfo.isSkillUsed(param1.id,_loc6_.skillId))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"当前回合不能使用该技能！");
            }
            else if(Boolean(_loc7_) && _loc7_.changeViewCostHp > StatusUtil.getYirenShieldByPbi(param1)[0])
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不朽者体力不足以释放技能！");
            }
            else if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc6_.skillId))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用！");
            }
            else
            {
               param2.gotoAndStop(1);
               _loc8_ = _loc6_.newCnName + "\n威力：" + getSkillPowerDesc(_loc6_.power);
               TipsManager.getInstance().replaceComplexTips(param2,_loc8_,_loc6_.clientDesc,100,-100,9);
            }
         }
      }
      
      private function updateShenXuSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc8_:int = 0;
         var _loc9_:* = null;
         var _loc10_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isShenXu(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         TipsManager.getInstance().removeTips(param2);
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:GQShenXuSkillParse = GQShenXuSkillParse.getGQShenXuSkillParse(param1.raceId);
         var _loc5_:int = int(_loc4_.getShenxuSpiritSkillId(param1.skills));
         var _loc6_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
         var _loc7_:int = int(_loc4_.getInStrengthSkillLv(param1.skills));
         if(_loc5_ > 0)
         {
            _loc8_ = int(param1.curGQSoulNum);
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc5_))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else
            {
               if(this._gameOptionSvr.isGQSimpleSkillView)
               {
                  _loc9_ = _loc6_.oldEffectDesc;
               }
               else
               {
                  _loc9_ = _loc6_.clientDesc;
               }
               if(_loc8_ < _loc6_.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(param1))
               {
                  param2.gotoAndStop(2);
                  _loc9_ += "\n-------\n光能不足，不能使用该技能！";
               }
               else if(_loc7_ >= param1.gqShenxuLv)
               {
                  param2.gotoAndStop(2);
                  _loc9_ += "\n-------\n已是最高等级，不能使用该技能！";
               }
               else
               {
                  param2.gotoAndStop(1);
               }
               _loc10_ = _loc6_.newCnName + "\n威力：" + getSkillPowerDesc(_loc6_.power);
               TipsManager.getInstance().replaceComplexTips(param2,_loc10_,_loc9_);
            }
         }
         else
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
      }
      
      private function updateXingZhiYuSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var skillId:int;
         var i:int;
         var subXingZhiYuMc:MovieClip = null;
         var onRollOverXingZhiYu:Function = null;
         var onRollOutXingZhiYu:Function = null;
         var cd:int = 0;
         var petInfo:PetBriefInfo = param1;
         var mcXingZhiYu:MovieClip = param2;
         onRollOverXingZhiYu = function(param1:MouseEvent):void
         {
            subXingZhiYuMc.visible = true;
         };
         onRollOutXingZhiYu = function(param1:MouseEvent):void
         {
            subXingZhiYuMc.visible = false;
         };
         var isXingZhiYu:Boolean = Boolean(GQPetType.isXingZhiYu(this._pmService.getOperationPM(petInfo.raceId).pmData.getGQType()));
         mcXingZhiYu.visible = isXingZhiYu;
         if(!isXingZhiYu)
         {
            DisplayUtil.stopAndRemove(mcXingZhiYu);
            return;
         }
         skillId = int(GQXingZhiYuSkillParse.getXingZhiYuSpiritSkillId(petInfo));
         if(skillId == -1)
         {
            mcXingZhiYu.visible = false;
            return;
         }
         subXingZhiYuMc = mcXingZhiYu.getChildByName("mcSubXingZhiYu") as MovieClip;
         mcXingZhiYu.addEventListener(MouseEvent.ROLL_OVER,onRollOverXingZhiYu);
         mcXingZhiYu.addEventListener(MouseEvent.ROLL_OUT,onRollOutXingZhiYu);
         subXingZhiYuMc.visible = false;
         i = 0;
         while(i < 4)
         {
            if(FightData.instance.myInfo.isSkillUsed(petInfo.id,skillId))
            {
               ActComHelper.refreshObj(subXingZhiYuMc,"btnXingZhiYu" + i,true,"本回合已用");
            }
            else if(!StatusUtil.getCanUseSkillWithToteOrBuff(petInfo,skillId))
            {
               ActComHelper.refreshObj(subXingZhiYuMc,"btnXingZhiYu" + i,true,"不可使用");
            }
            else
            {
               cd = int(GQXingZhiYuSkillParse.getSkillCd(petInfo));
               if(cd > 0)
               {
                  ActComHelper.refreshObj(subXingZhiYuMc,"btnXingZhiYu" + i,true,cd + "回合后方可使用");
               }
               else
               {
                  ActComHelper.refreshObj(subXingZhiYuMc,"btnXingZhiYu" + i,false);
               }
            }
            i++;
         }
      }
      
      private function updateJueXingSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var juexingSkillParse:GQJueXingSkillParse;
         var onRollOverJuexing:Function;
         var onRollOutJuexing:Function;
         var subJuexingMc:MovieClip = null;
         var i:int = 0;
         var skillId:int = 0;
         var pmSkill:PMSkill = null;
         var cd:int = 0;
         var curSoulNum:int = 0;
         var tips:String = null;
         var petInfo:PetBriefInfo = param1;
         var mcJuexing:MovieClip = param2;
         var isJuexing:Boolean = Boolean(GQPetType.isJuexing(this._pmService.getOperationPM(petInfo.raceId).pmData.getGQType()));
         DisplayUtil.stop(mcJuexing);
         mcJuexing.visible = isJuexing;
         if(!isJuexing)
         {
            DisplayUtil.stopAndRemove(mcJuexing);
            return;
         }
         juexingSkillParse = GQJueXingSkillParse.getJueXingSkillParse(petInfo.raceId);
         if(juexingSkillParse.getChangeState(petInfo) == -1)
         {
            mcJuexing.gotoAndStop(1);
            subJuexingMc = mcJuexing.getChildByName("mcSubJuexing") as MovieClip;
            subJuexingMc.visible = false;
            if(juexingSkillParse.getIsUnlock(petInfo))
            {
               onRollOverJuexing = function(param1:MouseEvent):void
               {
                  var mcMv:MovieClip;
                  var evt:MouseEvent = param1;
                  ActComHelper.setMcFrame(mcJuexing,"mc",2);
                  mcMv = ActComHelper.getChildNode(mcJuexing,"mc.mcMv") as MovieClip;
                  if(Boolean(mcMv) && Boolean(mcMv.parent))
                  {
                     ActMovieHelper.playMcMv(mcMv,function():void
                     {
                        if(Boolean(mcJuexing) && Boolean(mcJuexing.parent))
                        {
                           ActComHelper.setMcFrame(mcJuexing,"mc",3);
                           subJuexingMc.visible = true;
                        }
                     });
                  }
               };
               onRollOutJuexing = function(param1:MouseEvent):void
               {
                  subJuexingMc.visible = false;
                  ActComHelper.setMcFrame(mcJuexing,"mc",1);
               };
               ActComHelper.setMcFrame(mcJuexing,"mc",1);
               mcJuexing.addEventListener(MouseEvent.ROLL_OVER,onRollOverJuexing);
               mcJuexing.addEventListener(MouseEvent.ROLL_OUT,onRollOutJuexing);
               i = 0;
               while(i < juexingSkillParse.changeSkillIds.length)
               {
                  skillId = int(juexingSkillParse.changeSkillIds[i]);
                  pmSkill = _pmService.customData.pmSkillMap.getSkill(skillId);
                  if(!StatusUtil.getCanUseSkillWithToteOrBuff(petInfo,skillId))
                  {
                     ActComHelper.refreshObj(subJuexingMc,"btnJuexing" + i,true,"不可使用");
                  }
                  else
                  {
                     cd = int(GQJueXingSkillParse.getSkillCd(petInfo));
                     curSoulNum = int(petInfo.curGQSoulNum);
                     if(cd > 0)
                     {
                        ActComHelper.refreshObj(subJuexingMc,"btnJuexing" + i,true,cd + "回合后方可使用");
                     }
                     else if(curSoulNum < pmSkill.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(petInfo))
                     {
                        ActComHelper.refreshObj(subJuexingMc,"btnJuexing" + i,true,"光能不足，不能使用该技能！");
                     }
                     else
                     {
                        ActComHelper.refreshObj(subJuexingMc,"btnJuexing" + i,false);
                        tips = pmSkill.newCnName + "\n威力：" + getSkillPowerDesc(pmSkill.power);
                        TipsManager.getInstance().replaceComplexTips(ActComHelper.getChildNode(subJuexingMc,"btnJuexing" + i) as SimpleButton,tips,pmSkill.clientDesc);
                     }
                  }
                  i++;
               }
            }
            else
            {
               ActComHelper.refreshObj(mcJuexing,"mc",false,"未解锁","",1);
            }
         }
         else
         {
            mcJuexing.gotoAndStop(2);
            pmSkill = _pmService.customData.pmSkillMap.getSkill(juexingSkillParse.changeBackSkillId);
            tips = pmSkill.newCnName + "\n威力：" + getSkillPowerDesc(pmSkill.power);
            TipsManager.getInstance().replaceComplexTips(ActComHelper.getChildNode(mcJuexing,"btnExitJuexingChangeView") as SimpleButton,tips,pmSkill.clientDesc);
         }
      }
      
      private function updateYingHunSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc6_:int = 0;
         var _loc7_:PMSkill = null;
         var _loc8_:String = null;
         var _loc9_:String = null;
         var _loc10_:int = 0;
         var _loc3_:int = int(this._pmService.getOperationPM(param1.raceId).pmData.getGQType());
         var _loc4_:Boolean = Boolean(GQPetType.isYingHun(_loc3_));
         DisplayUtil.stop(param2);
         param2.visible = _loc4_;
         if(!_loc4_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         if(_loc3_ == GQPetType.YINGHUN_SHENQI)
         {
            param2.y = 85;
         }
         var _loc5_:GQYinghunYingjiemengyueSkillParse = GQYinghunYingjiemengyueSkillParse.getYinghunYingjiemengyueSkillParse(param1.raceId);
         if(_loc5_.getIsUnlock(param1))
         {
            _loc6_ = int(_loc5_.yinghunSkillId);
            _loc7_ = _pmService.customData.pmSkillMap.getSkill(_loc6_);
            _loc8_ = _loc7_.newCnName + "\n威力：" + this.getSkillPowerDesc(_loc7_.power);
            _loc10_ = int(_loc5_.getYinghunEnergy(param1));
            if(this._gameOptionSvr.isGQSimpleSkillView)
            {
               _loc9_ = _loc7_.oldEffectDesc;
            }
            else
            {
               _loc9_ = _loc7_.clientDesc;
            }
            _loc9_ += "\n-------\n当前能量值：" + _loc10_;
            TipsManager.getInstance().replaceComplexTips(param2,_loc8_,_loc9_);
            param2.gotoAndStop(int(_loc10_ / 25) + 1);
         }
         else
         {
            ActComHelper.refreshObj(param2,"",true,"未解锁","",1);
         }
      }
      
      private function updateWumangXingji(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc8_:int = 0;
         var _loc9_:PMSkill = null;
         var _loc10_:String = null;
         var _loc11_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isWumangXingJi(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:Array = GQWumangXingjiSkillParse.getWumangXingjiSkillIds(param1);
         if(!_loc4_ || _loc4_.length <= 0)
         {
            param2.visible = false;
            return;
         }
         var _loc5_:Object = GQPetType.getWuMangXingJiObject(param1.raceId % 10000);
         param2.gotoAndStop(_loc5_.extraSkillFrame);
         var _loc6_:MovieClip = param2.getChildByName("subWumangXingjiMc") as MovieClip;
         var _loc7_:int = 0;
         while(_loc7_ < _loc5_.lv)
         {
            if(_loc7_ >= _loc4_.length)
            {
               ActComHelper.refreshObj(_loc6_,"mcWumangXingji" + _loc7_,true,"不可使用","",1);
            }
            else
            {
               _loc8_ = int(GQWumangXingjiSkillParse.getSkillCd(param1));
               if(_loc8_ > 0)
               {
                  ActComHelper.refreshObj(_loc6_,"mcWumangXingji" + _loc7_,true,_loc8_ + "回合后方可使用","",1);
               }
               else
               {
                  ActComHelper.refreshObj(_loc6_,"mcWumangXingji" + _loc7_,false,"","",2);
                  _loc9_ = _pmService.customData.pmSkillMap.getSkill(_loc4_[_loc7_]);
                  _loc10_ = SkillHelper.getSkillTipsTitle(_loc9_);
                  _loc11_ = SkillHelper.getSKillTipsContent(_loc9_);
                  TipsManager.getInstance().replaceComplexTips(ActComHelper.getChildNode(_loc6_,"mcWumangXingji" + _loc7_) as MovieClip,_loc10_,_loc11_);
               }
            }
            _loc7_++;
         }
      }
      
      private function updateEternityZhanyiSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var cd:int;
         var eternityZhanyiSkillParse:GQEternityZhanyiSkillParse = null;
         var eternityZhanyiSpiritSkillMc:MovieClip = null;
         var stone:int = 0;
         var pmSkill:PMSkill = null;
         var onMouseOverOverEternityZhanyiMc:Function = null;
         var onMouseOutEternityZhanyiMc:Function = null;
         var tipsTitle:String = null;
         var tipsContent:String = null;
         var petInfo:PetBriefInfo = param1;
         var mcEternityZhanyi:MovieClip = param2;
         onMouseOverOverEternityZhanyiMc = function(param1:MouseEvent):void
         {
            var mcMv:MovieClip = null;
            var evt:MouseEvent = param1;
            _isRollOverEternityZhanyi = true;
            eternityZhanyiSpiritSkillMc.gotoAndStop(2);
            mcMv = eternityZhanyiSpiritSkillMc.getChildByName("mcMv") as MovieClip;
            mcMv.mouseEnabled = mcMv.mouseChildren = false;
            mcMv.addFrameScript(mcMv.totalFrames - 1,function():void
            {
               var _loc1_:int = 0;
               if(Boolean(mcMv) && Boolean(mcMv.parent))
               {
                  mcMv.stop();
                  mcMv.mouseEnabled = mcMv.mouseChildren = true;
                  _loc1_ = 0;
                  while(_loc1_ < eternityZhanyiSkillParse.enternityCommonSkillIds.length)
                  {
                     if(FightData.instance.myInfo.isOneSkillUsed(petInfo.id,eternityZhanyiSkillParse.enternityCommonSkillIds))
                     {
                        ActComHelper.refreshObj(mcMv,"btnEternityZhanyiCommonSkill" + _loc1_,true,"本回合已用");
                     }
                     else if(stone < _loc1_ + 1)
                     {
                        ActComHelper.refreshObj(mcMv,"btnEternityZhanyiCommonSkill" + _loc1_,true,"源晶不足");
                     }
                     else
                     {
                        ActComHelper.refreshObj(mcMv,"btnEternityZhanyiCommonSkill" + _loc1_,false);
                        pmSkill = _pmService.customData.pmSkillMap.getSkill(eternityZhanyiSkillParse.enternityCommonSkillIds[_loc1_]);
                        tipsTitle = SkillHelper.getSkillTipsTitle(pmSkill);
                        tipsContent = SkillHelper.getSKillTipsContent(pmSkill);
                        TipsManager.getInstance().replaceComplexTips(ActComHelper.getChildNode(mcMv,"btnEternityZhanyiCommonSkill" + _loc1_) as SimpleButton,tipsTitle,tipsContent);
                     }
                     _loc1_++;
                  }
               }
            });
            mcMv.gotoAndPlay(1);
         };
         onMouseOutEternityZhanyiMc = function(param1:MouseEvent):void
         {
            _isRollOverEternityZhanyi = false;
            eternityZhanyiSpiritSkillMc.gotoAndStop(1);
         };
         var isEternityZhanyi:Boolean = Boolean(GQPetType.isEternityZhanyi(this._pmService.getOperationPM(petInfo.raceId).pmData.getGQType()));
         mcEternityZhanyi.visible = isEternityZhanyi;
         if(!isEternityZhanyi)
         {
            DisplayUtil.stopAndRemove(mcEternityZhanyi);
            return;
         }
         if(!GQEternityZhanyiSkillParse.getIsUnlock(petInfo))
         {
            mcEternityZhanyi.visible = false;
            return;
         }
         eternityZhanyiSkillParse = GQEternityZhanyiSkillParse.getEternityZhanyiSkillParse(petInfo.raceId);
         eternityZhanyiSpiritSkillMc = mcEternityZhanyi.getChildByName("mcEternityZhanyiSpiritSkill") as MovieClip;
         eternityZhanyiSpiritSkillMc.addEventListener(MouseEvent.ROLL_OVER,onMouseOverOverEternityZhanyiMc);
         eternityZhanyiSpiritSkillMc.addEventListener(MouseEvent.ROLL_OUT,onMouseOutEternityZhanyiMc);
         if(!this._isRollOverEternityZhanyi)
         {
            eternityZhanyiSpiritSkillMc.gotoAndStop(1);
         }
         else
         {
            onMouseOverOverEternityZhanyiMc(null);
         }
         cd = int(GQEternityZhanyiSkillParse.getSkillCd(petInfo));
         stone = int(GQEternityZhanyiSkillParse.getYuanjingNum(petInfo));
         pmSkill = _pmService.customData.pmSkillMap.getSkill(eternityZhanyiSkillParse.enternitySpiritSkillId);
         if(FightData.instance.myInfo.isSkillUsed(petInfo.id,pmSkill.skillId))
         {
            ActComHelper.refreshObj(eternityZhanyiSpiritSkillMc,"btnEternityZhanyiSpiritSkill",true,"本回合已用");
         }
         else if(cd > 0)
         {
            ActComHelper.refreshObj(eternityZhanyiSpiritSkillMc,"btnEternityZhanyiSpiritSkill",true,cd + "回合后方可使用","");
         }
         else
         {
            ActComHelper.refreshObj(eternityZhanyiSpiritSkillMc,"btnEternityZhanyiSpiritSkill",false);
            tipsTitle = SkillHelper.getSkillTipsTitle(pmSkill);
            tipsContent = SkillHelper.getSKillTipsContent(pmSkill);
            TipsManager.getInstance().replaceComplexTips(ActComHelper.getChildNode(eternityZhanyiSpiritSkillMc,"btnEternityZhanyiSpiritSkill") as SimpleButton,tipsTitle,tipsContent);
         }
      }
      
      private function updateShenqiSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc6_:int = 0;
         var _loc7_:* = null;
         var _loc8_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isShenQi(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:int = int(GQShenQiSkillParse.getShenqiSpiritSkillId(param1));
         var _loc5_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
         if(_loc4_ > 0)
         {
            _loc6_ = int(param1.curGQSoulNum);
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc4_))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else
            {
               if(this._gameOptionSvr.isGQSimpleSkillView)
               {
                  _loc7_ = _loc5_.oldEffectDesc;
               }
               else
               {
                  _loc7_ = _loc5_.clientDesc;
               }
               if(_loc6_ < _loc5_.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(param1))
               {
                  param2.gotoAndStop(2);
                  _loc7_ += "\n-------\n光能不足，不能使用该技能！";
               }
               else
               {
                  param2.gotoAndStop(1);
               }
               _loc8_ = _loc5_.newCnName + "\n威力：" + getSkillPowerDesc(_loc5_.power);
               TipsManager.getInstance().replaceComplexTips(param2,_loc8_,_loc7_);
            }
         }
         else
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
      }
      
      private function updateYanhuaZhiyao(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc5_:GQYanhuaZhiyaoGongmingZhongduanSkillParse = null;
         var _loc6_:PMSkill = null;
         var _loc7_:int = 0;
         var _loc8_:MovieClip = null;
         var _loc9_:String = null;
         var _loc10_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isYanhuaZhiyao(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:int = int(GQYanhuaZhiyaoGongmingZhongduanSkillParse.getYanhuaZhiyaoSpiritSkillId(param1));
         if(_loc4_ > 0)
         {
            _loc5_ = GQYanhuaZhiyaoGongmingZhongduanSkillParse.getYanhuaZhiyaoGongmingZhongduanSkillParse(param1.raceId);
            _loc6_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            _loc7_ = int(_loc5_.yanhuaZhiyaoSpiritSkillIds.indexOf(_loc4_));
            param2.gotoAndStop(_loc7_ + 1);
            _loc8_ = param2.getChildByName("mcSubYanhuaZhiyao") as MovieClip;
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc4_))
            {
               _loc8_.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(_loc8_,"不可使用");
            }
            else if(StatusUtil.getIsYanhuaZhiyaoUsed(this._petInfo))
            {
               _loc8_.gotoAndStop(2);
               _loc8_.visible = false;
            }
            else if(FightData.instance.myInfo.isSkillUsed(param1.id,_loc6_.skillId))
            {
               _loc8_.gotoAndStop(2);
               _loc8_.visible = false;
            }
            else
            {
               if(this._gameOptionSvr.isGQSimpleSkillView)
               {
                  _loc9_ = _loc6_.oldEffectDesc;
               }
               else
               {
                  _loc9_ = _loc6_.clientDesc;
               }
               _loc8_.gotoAndStop(1);
               _loc10_ = _loc6_.newCnName + "\n威力：" + getSkillPowerDesc(_loc6_.power);
               TipsManager.getInstance().replaceComplexTips(param2,_loc10_,_loc9_);
            }
         }
         else
         {
            param2.visible = false;
         }
      }
      
      private function updateZhigaoRongyao(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc6_:PMSkill = null;
         var _loc7_:int = 0;
         var _loc8_:String = null;
         var _loc9_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isZhigaoRongyao(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:GQZhigaoRongyaoSkillParse = GQZhigaoRongyaoSkillParse.getZhigaoRongyaoSkillData(param1.raceId);
         var _loc5_:int = int(GQZhigaoRongyaoSkillParse.getZhigaoRongyaoSkillId(param1));
         if(_loc5_ > 0)
         {
            _loc6_ = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc5_))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else if(StatusUtil.getIsZhigaoRongyaoBigSkillUsed(param1))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"本场战斗次数用光");
            }
            else
            {
               param2.gotoAndStop(1);
               if(this._gameOptionSvr.isGQSimpleSkillView)
               {
                  _loc8_ = _loc6_.oldEffectDesc;
               }
               else
               {
                  _loc8_ = _loc6_.clientDesc;
               }
               _loc9_ = _loc6_.newCnName + "\n威力：" + getSkillPowerDesc(_loc6_.power);
               TipsManager.getInstance().replaceComplexTips(param2,_loc9_,_loc8_);
            }
            _loc7_ = 0;
            while(_loc7_ < _loc4_.qiyueRaceIds.length)
            {
               ActComHelper.setMcFrame(param2,"mcZhigaoRongyaoQiyue" + _loc7_,StatusUtil.getZhigaoRongyaoContractArr(this._petInfo)[_loc7_] + 1);
               _loc7_++;
            }
         }
         else
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
      }
      
      private function updateMiBao(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc10_:PMSkill = null;
         var _loc11_:int = 0;
         var _loc12_:int = 0;
         var _loc13_:String = null;
         var _loc14_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isMiBao(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:Object = GQPetType.getMiBaoObject(param1.raceId);
         var _loc5_:int = _loc4_ == null ? 1 : int(_loc4_["iconFrame"]);
         param2.gotoAndStop(_loc5_);
         var _loc6_:MovieClip = param2.getChildByName("mcBox") as MovieClip;
         var _loc7_:GQMiBaoSkillParse = GQMiBaoSkillParse.getMiBaoSkillData(param1.raceId);
         var _loc8_:int = int(GQMiBaoSkillParse.getMiBaoSkillId(param1));
         var _loc9_:int = StatusUtil.getMiBaoGainSoulNum(param1);
         if(_loc8_ > 0)
         {
            _loc10_ = this._pmService.customData.pmSkillMap.getSkill(_loc8_);
            _loc11_ = StatusUtil.getMiBaoSkillState(param1);
            if(_loc11_ == 0)
            {
               _loc6_.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(_loc6_,"累计获得" + _loc9_ + "/4光能");
            }
            else if(_loc11_ == 2)
            {
               _loc6_.gotoAndStop(2);
               _loc12_ = StatusUtil.getMiBaoSkillCd(param1);
               TipsManager.getInstance().replaceTips(_loc6_,_loc12_ + "回合后方可使用");
            }
            else if(param1.curGQSoulNum < _loc10_.costSoulNum)
            {
               _loc6_.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(_loc6_,"光能不足");
            }
            else
            {
               _loc6_.gotoAndStop(1);
               if(this._gameOptionSvr.isGQSimpleSkillView)
               {
                  _loc13_ = _loc10_.oldEffectDesc;
               }
               else
               {
                  _loc13_ = _loc10_.clientDesc;
               }
               _loc14_ = _loc10_.newCnName + "\n威力：" + getSkillPowerDesc(_loc10_.power);
               TipsManager.getInstance().replaceComplexTips(_loc6_,_loc14_,_loc13_);
            }
         }
         else
         {
            _loc6_.gotoAndStop(2);
            TipsManager.getInstance().replaceTips(_loc6_,"累计获得" + _loc9_ + "/4光能");
         }
      }
      
      private function updateMingYunBoYi(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var skillId:int;
         var i:int;
         var subMingYunBoYiMc:MovieClip = null;
         var onRollOverMingYunBoYi:Function = null;
         var onRollOutMingYunBoYi:Function = null;
         var petInfo:PetBriefInfo = param1;
         var mcMingYunBoYi:MovieClip = param2;
         onRollOverMingYunBoYi = function(param1:MouseEvent):void
         {
            subMingYunBoYiMc.visible = true;
         };
         onRollOutMingYunBoYi = function(param1:MouseEvent):void
         {
            subMingYunBoYiMc.visible = false;
         };
         var isMingYunBoYi:Boolean = Boolean(GQPetType.isMingYunBoYi(this._pmService.getOperationPM(petInfo.raceId).pmData.getGQType()));
         mcMingYunBoYi.visible = isMingYunBoYi;
         if(!isMingYunBoYi)
         {
            DisplayUtil.stopAndRemove(mcMingYunBoYi);
            return;
         }
         skillId = int(GQMingYunBoYiSkillParse.getMingYunBoYiSpiritSkillId(petInfo));
         if(skillId == -1)
         {
            mcMingYunBoYi.visible = false;
            return;
         }
         subMingYunBoYiMc = mcMingYunBoYi.getChildByName("mcSubMingYunBoYi") as MovieClip;
         mcMingYunBoYi.addEventListener(MouseEvent.ROLL_OVER,onRollOverMingYunBoYi);
         mcMingYunBoYi.addEventListener(MouseEvent.ROLL_OUT,onRollOutMingYunBoYi);
         subMingYunBoYiMc.visible = false;
         i = 0;
         while(i < 4)
         {
            if(FightData.instance.myInfo.isSkillUsed(petInfo.id,skillId) || StatusUtil.getMingYunBoYiUsed(petInfo))
            {
               ActComHelper.refreshObj(subMingYunBoYiMc,"btnMingYunBoYi" + i,true,"本回合已用");
            }
            else if(!StatusUtil.getCanUseSkillWithToteOrBuff(petInfo,skillId))
            {
               ActComHelper.refreshObj(subMingYunBoYiMc,"btnMingYunBoYi" + i,true,"不可使用");
            }
            else
            {
               ActComHelper.refreshObj(subMingYunBoYiMc,"btnMingYunBoYi" + i,false,"","");
            }
            i++;
         }
      }
      
      private function updateJiuRiChongXian(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc5_:int = 0;
         var _loc6_:PMSkill = null;
         var _loc7_:String = null;
         var _loc8_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isJiuRiChongXian(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:int = int(GQJiuRiChongXianSkillParse.getJiuRiChongXianSpiritSkillId(param1));
         if(_loc4_ > 0)
         {
            _loc5_ = int(GQPetType.getJiuRiChongXianObject(param1.raceId % 10000).iconFrame);
            _loc6_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc4_))
            {
               param2.gotoAndStop(_loc5_ * 2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else if(StatusUtil.getIsJiuRiChongXianBigSkillUsed(param1))
            {
               param2.gotoAndStop(_loc5_ * 2);
               TipsManager.getInstance().replaceTips(param2,"本场战斗次数用光");
            }
            else
            {
               param2.gotoAndStop(_loc5_ * 2 - 1);
               _loc7_ = this._gameOptionSvr.isGQSimpleSkillView ? _loc6_.oldEffectDesc : _loc6_.clientDesc;
               _loc8_ = _loc6_.newCnName + "\n威力：" + getSkillPowerDesc(_loc6_.power);
               TipsManager.getInstance().replaceComplexTips(param2,_loc8_,_loc7_);
            }
         }
         else
         {
            param2.stop();
            param2.visible = false;
         }
      }
      
      private function updateHuanLingShi(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc5_:PMSkill = null;
         var _loc6_:MovieClip = null;
         var _loc7_:String = null;
         var _loc8_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isHuanLingShi(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:int = int(GQHuanLingShiSkillParse.getHuanLingShiSpiritSkillId(param1));
         if(_loc4_ > 0)
         {
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            param2.gotoAndStop(_loc5_.getSkillType() - 103);
            _loc6_ = param2.mcSkill;
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc4_))
            {
               _loc6_.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(_loc6_,"不可使用");
            }
            else if(Boolean(FightData.instance.extData[FightData.HuanLingShiFirstSkillKey]) && _loc5_.getSkillType() == PMSkillTypes.GQ_HUANLINGSHI_FIRST_SPIRIT_SKILL)
            {
               _loc6_.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(_loc6_,"不可使用");
            }
            else if(FightData.instance.myInfo.isSkillUsed(param1.id,_loc4_))
            {
               _loc6_.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(_loc6_,"本回合已用");
            }
            else if(_loc5_.getSkillType() == PMSkillTypes.GQ_HUANLINGSHI_SECOND_SPIRIT_SKILL && !StatusUtil.getIsHuanLingShiCanUseSkill(param1))
            {
               if(StatusUtil.getHuanLingShiEnergy(param1) < 20)
               {
                  _loc6_.gotoAndStop(1);
               }
               else
               {
                  _loc6_.gotoAndStop(Math.floor(StatusUtil.getHuanLingShiEnergy(param1) / 20));
               }
               TipsManager.getInstance().replaceTips(_loc6_,"当前能量值：" + StatusUtil.getHuanLingShiEnergy(param1) + "/100");
            }
            else
            {
               _loc6_.gotoAndStop(_loc5_.getSkillType() == PMSkillTypes.GQ_HUANLINGSHI_SECOND_SPIRIT_SKILL ? 5 : 1);
               _loc7_ = this._gameOptionSvr.isGQSimpleSkillView ? _loc5_.oldEffectDesc : _loc5_.clientDesc;
               _loc8_ = _loc5_.newCnName + "\n威力：" + getSkillPowerDesc(_loc5_.power);
               TipsManager.getInstance().replaceComplexTips(_loc6_,_loc8_,_loc7_);
            }
         }
         else
         {
            DisplayUtil.stop(param2);
            param2.visible = false;
         }
      }
      
      private function updatXingHuanShi(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc5_:PMSkill = null;
         var _loc6_:String = null;
         var _loc7_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isXingHuanShi(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:int = int(GQXingHuanShiSkillParse.getXingHuanShiSpiritSkillId(param1));
         if(_loc4_ > 0)
         {
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc4_))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else if(StatusUtil.getIsXingHuanShiBigSkillUsed(param1))
            {
               param2.gotoAndStop(2);
               param2.visible = false;
            }
            else
            {
               param2.gotoAndStop(1);
               _loc6_ = this._gameOptionSvr.isGQSimpleSkillView ? _loc5_.oldEffectDesc : _loc5_.clientDesc;
               _loc7_ = _loc5_.newCnName + "\n威力：" + getSkillPowerDesc(_loc5_.power);
               TipsManager.getInstance().replaceComplexTips(param2,_loc7_,_loc6_);
            }
         }
         else
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
      }
      
      private function updateDengShenChangJie(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc5_:PMSkill = null;
         var _loc6_:String = null;
         var _loc7_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isDengShenChangJie(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:int = int(GQDengShenChangJieSkillParse.getSpiritSkillId(param1));
         if(_loc4_ > 0)
         {
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc4_))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else
            {
               param2.gotoAndStop(1);
               _loc6_ = this._gameOptionSvr.isGQSimpleSkillView ? _loc5_.oldEffectDesc : _loc5_.clientDesc;
               _loc7_ = _loc5_.newCnName + "\n威力：" + getSkillPowerDesc(_loc5_.power);
               TipsManager.getInstance().replaceComplexTips(param2,_loc7_,_loc6_);
            }
         }
         else
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
      }
      
      private function updateBuxiuLvtu(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc5_:PMSkill = null;
         var _loc6_:* = null;
         var _loc7_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isBuxiuLvtu(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         if(StatusUtil.getIsBuxiuJixingState(param1))
         {
            param2.visible = false;
            return;
         }
         var _loc4_:int = int(GQBuxiuLvtuSkillParse.getSpiritSkillId(param1));
         if(_loc4_ > 0)
         {
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            param2.visible = true;
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc4_))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else if(StatusUtil.getIsBuxiuJixingSpiritSkillUsed(param1))
            {
               param2.gotoAndStop(2);
               param2.visible = false;
            }
            else
            {
               _loc6_ = this._gameOptionSvr.isGQSimpleSkillView ? _loc5_.oldEffectDesc : _loc5_.clientDesc;
               _loc7_ = _loc5_.newCnName + "\n威力：" + getSkillPowerDesc(_loc5_.power);
               if(param1.curGQSoulNum < _loc5_.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(param1))
               {
                  param2.gotoAndStop(2);
                  _loc6_ += "\n-------\n当前拥有" + param1.curGQSoulNum + "光能。";
                  if(param1.curGQSoulNum < _loc5_.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(param1))
                  {
                     _loc6_ += "\n-------\n光能不足，不能使用该技能！";
                  }
               }
               else
               {
                  param2.gotoAndStop(1);
               }
               TipsManager.getInstance().replaceComplexTips(param2,_loc7_,_loc6_);
            }
         }
         else
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
      }
      
      private function updateWanyuZhichao(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc8_:PMSkill = null;
         var _loc9_:String = null;
         var _loc10_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isWanYuZhiChao(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         if(StatusUtil.getWanyuZhichaoSpiritSkillUsed(param1))
         {
            param2.visible = false;
            return;
         }
         var _loc4_:GQWanyuZhichaoSkillParse = GQWanyuZhichaoSkillParse.getGQWanyuZhichaoSkillParse(param1.raceId);
         var _loc5_:int = int(GQWanyuZhichaoSkillParse.getWanyuZhichaoSpiritSkillId(param1));
         var _loc6_:Array = _loc4_.wanyuZhichaoSkillIds.sort(Array.NUMERIC);
         var _loc7_:int = int(_loc6_.indexOf(_loc5_));
         if(_loc5_ > 0)
         {
            _loc8_ = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
            param2.visible = true;
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc5_))
            {
               param2.gotoAndStop(_loc7_ * 2 + 2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else if(FightData.instance.myInfo.isSkillUsed(param1.id,_loc5_))
            {
               param2.stop();
               param2.visible = false;
            }
            else
            {
               _loc9_ = this._gameOptionSvr.isGQSimpleSkillView ? _loc8_.oldEffectDesc : _loc8_.clientDesc;
               _loc10_ = _loc8_.newCnName + "\n威力：" + getSkillPowerDesc(_loc8_.power);
               param2.gotoAndStop(_loc7_ * 2 + 1);
               TipsManager.getInstance().replaceComplexTips(param2,_loc10_,_loc9_);
            }
         }
         else
         {
            param2.stop();
            param2.visible = false;
         }
      }
      
      private function updateHundunJuedou(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc5_:PMSkill = null;
         var _loc6_:String = null;
         var _loc7_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isHunDunJueDou(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         if(StatusUtil.getIsHunDunJueDouSpiritSkillUsed(param1))
         {
            param2.visible = false;
            return;
         }
         var _loc4_:int = int(GQHunDunJueDouSkillParse.getHunDunJueDouSkillId(param1));
         if(_loc4_ > 0)
         {
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            param2.visible = true;
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc4_))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else if(StatusUtil.getIsHunDunJueDouSpiritSkillUsed(param1))
            {
               param2.stop();
               param2.visible = false;
            }
            else
            {
               _loc6_ = this._gameOptionSvr.isGQSimpleSkillView ? _loc5_.oldEffectDesc : _loc5_.clientDesc;
               _loc7_ = _loc5_.newCnName + "\n威力：" + getSkillPowerDesc(_loc5_.power);
               param2.gotoAndStop(1);
               TipsManager.getInstance().replaceComplexTips(param2,_loc7_,_loc6_);
            }
         }
         else
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
      }
      
      private function updateShiKongFangZhu(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc5_:PMSkill = null;
         var _loc6_:String = null;
         var _loc7_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isShiKongFangZhu(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         if(StatusUtil.getIsShiKongFangZhuSpiritSkillUsed(param1))
         {
            param2.visible = false;
            return;
         }
         var _loc4_:int = int(GQShiKongFangZhuSkillParse.getShiKongFangZhuSkillId(param1));
         if(_loc4_ > 0)
         {
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            param2.visible = true;
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc4_))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else if(StatusUtil.getIsShiKongFangZhuSpiritSkillUsed(param1) || FightData.instance.myInfo.isSkillUsed(param1.id,_loc4_))
            {
               param2.stop();
               param2.visible = false;
            }
            else
            {
               _loc6_ = this._gameOptionSvr.isGQSimpleSkillView ? _loc5_.oldEffectDesc : _loc5_.clientDesc;
               _loc7_ = _loc5_.newCnName + "\n威力：" + getSkillPowerDesc(_loc5_.power);
               param2.gotoAndStop(1);
               TipsManager.getInstance().replaceComplexTips(param2,_loc7_,_loc6_);
            }
         }
         else
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
      }
      
      private function updateJiangShen(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc5_:PMSkill = null;
         var _loc6_:String = null;
         var _loc7_:String = null;
         var _loc3_:Boolean = Boolean(GQPetType.isJiangShen(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         if(!StatusUtil.getIsInJiangShenState(param1))
         {
            param2.visible = false;
            return;
         }
         var _loc4_:int = int(GQJiangShenSkillParse.getJiangShenSkillId(param1));
         if(_loc4_ > 0)
         {
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            param2.visible = true;
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc4_))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else if(StatusUtil.getIsJiangShenSpiritSkillUsed(param1) || FightData.instance.myInfo.isSkillUsed(param1.id,_loc4_))
            {
               param2.stop();
               param2.visible = false;
            }
            else if(!StatusUtil.getIsJiangShenCanUseSpiritSkill(param1))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"当前能量值：" + StatusUtil.getJiangShenSpiritEnergy(param1) + "/100");
            }
            else
            {
               _loc6_ = this._gameOptionSvr.isGQSimpleSkillView ? _loc5_.oldEffectDesc : _loc5_.clientDesc;
               _loc7_ = _loc5_.newCnName + "\n威力：" + getSkillPowerDesc(_loc5_.power);
               param2.gotoAndStop(1);
               TipsManager.getInstance().replaceComplexTips(param2,_loc7_,_loc6_);
            }
         }
         else
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
      }
      
      private function updateShenYuTianGang(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var skillIds:Array;
         var onRollOverJuexing:Function;
         var onRollOutJuexing:Function;
         var subShenYuTianGangMc:MovieClip = null;
         var i:int = 0;
         var pmSkill:PMSkill = null;
         var cd:int = 0;
         var tips:String = null;
         var petInfo:PetBriefInfo = param1;
         var mcShenYuTianGang:MovieClip = param2;
         var isShenYuTianGang:Boolean = Boolean(GQPetType.isShenYuTianGang(this._pmService.getOperationPM(petInfo.raceId).pmData.getGQType()));
         DisplayUtil.stop(mcShenYuTianGang);
         mcShenYuTianGang.visible = isShenYuTianGang;
         if(!isShenYuTianGang)
         {
            DisplayUtil.stopAndRemove(mcShenYuTianGang);
            return;
         }
         skillIds = GQShenYuTianGangSkillParse.getSpiritSkillIdArr(petInfo);
         if(skillIds.length > 0)
         {
            onRollOverJuexing = function(param1:MouseEvent):void
            {
               ActComHelper.setMcFrame(mcShenYuTianGang,"mc",3);
               subShenYuTianGangMc.visible = true;
            };
            onRollOutJuexing = function(param1:MouseEvent):void
            {
               subShenYuTianGangMc.visible = false;
               ActComHelper.setMcFrame(mcShenYuTianGang,"mc",1);
            };
            mcShenYuTianGang.gotoAndStop(1);
            subShenYuTianGangMc = mcShenYuTianGang.getChildByName("mcSubShenYuTianGang") as MovieClip;
            subShenYuTianGangMc.visible = false;
            ActComHelper.setMcFrame(mcShenYuTianGang,"mc",1);
            mcShenYuTianGang.addEventListener(MouseEvent.ROLL_OVER,onRollOverJuexing);
            mcShenYuTianGang.addEventListener(MouseEvent.ROLL_OUT,onRollOutJuexing);
            i = 0;
            while(i < skillIds.length)
            {
               pmSkill = _pmService.customData.pmSkillMap.getSkill(skillIds[i]);
               if(!StatusUtil.getCanUseSkillWithToteOrBuff(petInfo,skillIds[i]))
               {
                  ActComHelper.refreshObj(mcShenYuTianGang,"",true,"不可使用");
               }
               else
               {
                  cd = StatusUtil.getShenYuTianGangSpiritSkillCd(petInfo);
                  if(cd > 0)
                  {
                     ActComHelper.refreshObj(mcShenYuTianGang,"",true,cd + "回合后方可使用");
                  }
                  else
                  {
                     ActComHelper.refreshObj(mcShenYuTianGang,"",false);
                     tips = pmSkill.newCnName + "\n威力：" + getSkillPowerDesc(pmSkill.power);
                     TipsManager.getInstance().replaceComplexTips(ActComHelper.getChildNode(subShenYuTianGangMc,"btnShenYuTianGang" + i) as SimpleButton,tips,pmSkill.clientDesc);
                  }
               }
               i++;
            }
         }
         else
         {
            mcShenYuTianGang.gotoAndStop(2);
            mcShenYuTianGang.visible = false;
         }
      }
      
      private function updateZhenLiFaDian(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc5_:PMSkill = null;
         var _loc3_:Boolean = Boolean(GQPetType.isZhenLiFaDian(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:int = int(GQZhenLiFaDianSkillParse.getSpiritSkillId(param1));
         if(_loc4_ > 0)
         {
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc4_))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else if(StatusUtil.getIsZhenLiFaDianSpiritSkillUsed(param1))
            {
               param2.stop();
               param2.visible = false;
            }
            else
            {
               param2.gotoAndStop(1);
               this.addSkillTips(param2,_loc5_);
            }
         }
         else
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
      }
      
      private function updateLiejieZhixi(param1:PetBriefInfo, param2:MovieClip) : void
      {
         var _loc5_:PMSkill = null;
         var _loc3_:Boolean = Boolean(GQPetType.isLieJieXZhiXi(this._pmService.getOperationPM(param1.raceId).pmData.getGQType()));
         param2.visible = _loc3_;
         if(!_loc3_)
         {
            DisplayUtil.stopAndRemove(param2);
            return;
         }
         var _loc4_:int = int(GQLieJieZhiXiSkillParse.getSpiritSkillId(param1));
         if(_loc4_ > 0)
         {
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            if(!StatusUtil.getCanUseSkillWithToteOrBuff(param1,_loc4_))
            {
               param2.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param2,"不可使用");
            }
            else if(StatusUtil.getIsLIEJIEZHIXISkillUsed(param1))
            {
               param2.stop();
               param2.visible = false;
            }
            else
            {
               param2.gotoAndStop(1);
               this.addSkillTips(param2,_loc5_);
            }
         }
         else
         {
            param2.gotoAndStop(2);
            param2.visible = false;
         }
      }
      
      private function addSkillTips(param1:InteractiveObject, param2:PMSkill) : void
      {
         var _loc3_:String = this._gameOptionSvr.isGQSimpleSkillView ? param2.oldEffectDesc : param2.clientDesc;
         var _loc4_:String = param2.newCnName + "\n威力：" + getSkillPowerDesc(param2.power);
         TipsManager.getInstance().replaceComplexTips(param1,_loc4_,_loc3_);
      }
      
      override public function onMouseRollOver(param1:MouseEvent) : void
      {
         var _loc3_:Boolean = false;
         var _loc4_:int = 0;
         var _loc5_:Boolean = false;
         var _loc6_:int = 0;
         var _loc7_:PMSkill = null;
         var _loc8_:SkillInfo = null;
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "mctipslayer")
         {
            if(this.isEnable())
            {
               --this._mcChangeView.x;
               ++this._mcChangeView.y;
            }
         }
         if(param1.localX > -48)
         {
            if(FightData.instance.isPFSShenHuanFight)
            {
               if(this._gqPFSShenHuanExtraSkillPl == null)
               {
                  _loc7_ = GQPetHelper.getGQPetBigSkill(this._petInfo);
                  for each(_loc8_ in this._petInfo.skills)
                  {
                     if(_loc8_.id == _loc7_.skillId)
                     {
                        this._gqPFSShenHuanExtraSkillPl = new GQPFSShenHuanExtraSkillPanel(_loc8_);
                        break;
                     }
                  }
               }
               this._mcChangeView.addChild(this._gqPFSShenHuanExtraSkillPl);
            }
            _loc3_ = Boolean(GQPetType.isXingZhiYu(this._pmService.getOperationPM(this._petInfo.raceId).pmData.getGQType()));
            _loc4_ = int(GQXingZhiYuSkillParse.getXingZhiYuSpiritSkillId(this._petInfo));
            if(_loc3_ && _loc4_ > 0)
            {
               if(this._gqXingZhiYuExtraSkillPl == null)
               {
                  _loc7_ = GQPetHelper.getGQPetBigSkill(this._petInfo);
                  for each(_loc8_ in this._petInfo.skills)
                  {
                     if(_loc8_.id == _loc7_.skillId)
                     {
                        this._gqXingZhiYuExtraSkillPl = new GQXingZhiYuExtraSkillPanel(_loc8_);
                        break;
                     }
                  }
               }
               this._mcChangeView.addChild(this._gqXingZhiYuExtraSkillPl);
            }
            _loc5_ = Boolean(GQPetType.isMingYunBoYi(this._pmService.getOperationPM(this._petInfo.raceId).pmData.getGQType()));
            _loc6_ = int(GQMingYunBoYiSkillParse.getMingYunBoYiSpiritSkillId(this._petInfo));
            if(_loc5_ && _loc6_ > 0)
            {
               if(this._gqMingYunBoYiExtraSkillPl == null)
               {
                  _loc7_ = GQPetHelper.getGQPetBigSkill(this._petInfo);
                  for each(_loc8_ in this._petInfo.skills)
                  {
                     if(_loc8_.id == _loc7_.skillId)
                     {
                        this._gqMingYunBoYiExtraSkillPl = new GQMingYunBoYiExtraSkillPanel(_loc8_);
                        break;
                     }
                  }
               }
               this._mcChangeView.addChild(this._gqMingYunBoYiExtraSkillPl);
            }
         }
      }
      
      override public function onMouseRollOut() : void
      {
         this._mcChangeView.x = this._originPoint.x;
         this._mcChangeView.y = this._originPoint.y;
         this.onRollOutListener(null);
      }
      
      private function onRollOutListener(param1:MouseEvent) : void
      {
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
      }
      
      private function isEnable() : Boolean
      {
         var _loc7_:SkillInfo = null;
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         var _loc2_:int = int(_loc1_.curGQSoulNum);
         var _loc3_:PMSkill = GQPetHelper.getGQPetBigSkill(_loc1_);
         var _loc4_:int = 0;
         var _loc5_:GQYiRenWujinMingtuSkillParse = GQYiRenWujinMingtuSkillParse.getYiRenWujinMingtuSkillData(_loc1_.raceId);
         var _loc6_:int = int(GQPetType.getYiRenSkillCost(_loc1_.raceId,_loc3_.skillId));
         for each(_loc7_ in _loc1_.skills)
         {
            if(_loc3_.skillId == _loc7_.id)
            {
               _loc4_ = int(_loc7_.cd);
               break;
            }
         }
         if(Boolean(_loc3_) && StatusUtil.getHunDunJueDouHp(_loc1_) >= 0)
         {
            return true;
         }
         if(Boolean(_loc3_) && _loc3_.getSkillType() == PMSkillTypes.GQ_DIJIESHI_KILL_BIG)
         {
            if(StatusUtil.getIsDijieshiBigSkillUsed(_loc1_))
            {
               return false;
            }
         }
         if(Boolean(_loc3_) && StatusUtil.getCanUseSkillWithToteOrBuff(_loc1_,_loc3_.skillId))
         {
            if(!_loc5_ || !_loc5_.getIsAfterChangeView(_loc1_))
            {
               return _loc2_ >= _loc3_.costSoulNum || StatusUtil.getIsinTouzhiCommonBuff(_loc1_);
            }
            return _loc6_ <= StatusUtil.getYirenShieldByPbi(_loc1_)[0];
         }
         return false;
      }
      
      override public function onClicked(param1:MouseEvent) : void
      {
         var _loc4_:GQLianSuoSkillParse = null;
         var _loc5_:int = 0;
         var _loc6_:PMSkill = null;
         var _loc7_:int = 0;
         var _loc8_:GQArmorBurstSkillParse = null;
         var _loc9_:int = 0;
         var _loc10_:PMSkill = null;
         var _loc11_:GQGuangJinSkillParse = null;
         var _loc12_:int = 0;
         var _loc13_:PMSkill = null;
         var _loc14_:GQQiYuanSkillParse = null;
         var _loc15_:int = 0;
         var _loc16_:PMSkill = null;
         var _loc17_:int = 0;
         var _loc18_:PMSkill = null;
         var _loc19_:GQQunxingZhiyuSkillParse = null;
         var _loc20_:int = 0;
         var _loc21_:PMSkill = null;
         var _loc22_:GQYiRenWujinMingtuSkillParse = null;
         var _loc23_:int = 0;
         var _loc24_:PMSkill = null;
         var _loc25_:GQShenXuSkillParse = null;
         var _loc26_:int = 0;
         var _loc27_:PMSkill = null;
         var _loc28_:GQXingZhiYuSkillParse = null;
         var _loc29_:int = 0;
         var _loc30_:PMSkill = null;
         var _loc31_:int = 0;
         var _loc32_:GQJueXingSkillParse = null;
         var _loc33_:int = 0;
         var _loc34_:PMSkill = null;
         var _loc35_:int = 0;
         var _loc36_:PMSkill = null;
         var _loc37_:GQWumangXingjiSkillParse = null;
         var _loc38_:int = 0;
         var _loc39_:PMSkill = null;
         var _loc40_:GQEternityZhanyiSkillParse = null;
         var _loc41_:int = 0;
         var _loc42_:PMSkill = null;
         var _loc43_:int = 0;
         var _loc44_:PMSkill = null;
         var _loc45_:int = 0;
         var _loc46_:PMSkill = null;
         var _loc47_:int = 0;
         var _loc48_:PMSkill = null;
         var _loc49_:int = 0;
         var _loc50_:PMSkill = null;
         var _loc51_:PMSkill = null;
         var _loc52_:int = 0;
         var _loc53_:PMSkill = null;
         var _loc54_:GQMingYunBoYiSkillParse = null;
         var _loc55_:int = 0;
         var _loc56_:PMSkill = null;
         var _loc57_:int = 0;
         var _loc58_:PMSkill = null;
         var _loc59_:int = 0;
         var _loc60_:PMSkill = null;
         var _loc61_:int = 0;
         var _loc62_:PMSkill = null;
         var _loc63_:int = 0;
         var _loc64_:PMSkill = null;
         var _loc65_:int = 0;
         var _loc66_:PMSkill = null;
         var _loc67_:int = 0;
         var _loc68_:PMSkill = null;
         var _loc69_:int = 0;
         var _loc70_:PMSkill = null;
         var _loc71_:int = 0;
         var _loc72_:PMSkill = null;
         var _loc73_:int = 0;
         var _loc74_:PMSkill = null;
         var _loc75_:int = 0;
         var _loc76_:PMSkill = null;
         var _loc77_:int = 0;
         var _loc78_:PMSkill = null;
         var _loc79_:int = 0;
         var _loc80_:PMSkill = null;
         var _loc2_:String = param1.target.name;
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent(PetFightEvent.CLICK_SKILL_BUTTON,{}));
         var _loc3_:PetBriefInfo = this.getOperatingPetInfo();
         if(_loc2_ == "btnNoResponeSkill")
         {
            return;
         }
         if(_loc2_ == "btnLianSuoSkill")
         {
            _loc4_ = GQLianSuoSkillParse.getLianSuoSkillData(_loc3_.raceId);
            _loc5_ = int(_loc4_.getLianSuoSkillId(_loc3_.skills.concat()));
            if(_loc5_ > 0)
            {
               _loc6_ = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
               _loc7_ = int(_loc3_.curGQSoulNum);
               if(_loc7_ < _loc6_.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(_loc3_))
               {
                  return;
               }
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc6_.skillId,_loc6_.getSkillType());
            }
         }
         else if(_loc2_ == "btnArmorBurst")
         {
            _loc8_ = GQArmorBurstSkillParse.getArmorBurstSkillData(_loc3_.raceId);
            _loc9_ = int(_loc8_.armorBurstSkillId);
            if(_loc9_ > 0)
            {
               _loc10_ = this._pmService.customData.pmSkillMap.getSkill(_loc9_);
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc10_.skillId,_loc10_.getSkillType());
            }
         }
         else if(_loc2_ == "btnGuangJin")
         {
            _loc11_ = GQGuangJinSkillParse.getGuangJinSkillData(_loc3_.raceId);
            _loc12_ = int(_loc11_.getGuangJinSkillId(_loc3_.skills));
            if(_loc12_ > 0)
            {
               _loc13_ = this._pmService.customData.pmSkillMap.getSkill(_loc12_);
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc13_.skillId,_loc13_.getSkillType());
            }
         }
         else if(_loc2_ == "btnQiYuan")
         {
            _loc14_ = GQQiYuanSkillParse.getGQQiYuanSkillParse(_loc3_.raceId);
            _loc15_ = int(_loc14_.getQiYuanSkillId(_loc3_.skills));
            if(_loc15_ > 0)
            {
               _loc16_ = this._pmService.customData.pmSkillMap.getSkill(_loc15_);
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc16_.skillId,_loc16_.getSkillType());
            }
         }
         else if(_loc2_ == "btnTianyi")
         {
            _loc17_ = int(Panel_Helper.intelligentlyGetIndex(param1.target as DisplayObject));
            if(this._gqTianyiSpiritSkillIds[_loc17_] > 0)
            {
               _loc18_ = this._pmService.customData.pmSkillMap.getSkill(this._gqTianyiSpiritSkillIds[_loc17_]);
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc18_.skillId,_loc18_.getSkillType());
            }
         }
         else if(_loc2_ == "btnQunxingZhiyu")
         {
            _loc19_ = GQQunxingZhiyuSkillParse.getQunxingZhiyuSkillData(_loc3_.raceId);
            _loc20_ = int(_loc19_.getQunxingZhiyuSkillId(_loc3_.skills));
            if(_loc20_ > 0)
            {
               _loc21_ = this._pmService.customData.pmSkillMap.getSkill(_loc20_);
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc21_.skillId,_loc21_.getSkillType());
            }
         }
         else if(_loc2_ == "btnYiRen")
         {
            _loc22_ = GQYiRenWujinMingtuSkillParse.getYiRenWujinMingtuSkillData(_loc3_.raceId);
            _loc23_ = int(_loc22_.yirenSkillId);
            if(_loc23_ > 0)
            {
               _loc24_ = this._pmService.customData.pmSkillMap.getSkill(_loc23_);
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc23_,_loc24_.getSkillType());
            }
         }
         else if(_loc2_ == "btnShenXu")
         {
            _loc25_ = GQShenXuSkillParse.getGQShenXuSkillParse(_loc3_.raceId);
            _loc26_ = int(_loc25_.getShenxuSpiritSkillId(_loc3_.skills));
            _loc27_ = this._pmService.customData.pmSkillMap.getSkill(_loc26_);
            if(_loc26_ > 0)
            {
               _loc7_ = int(_loc3_.curGQSoulNum);
               if(_loc7_ < _loc27_.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(_loc3_))
               {
                  return;
               }
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc27_.skillId,_loc27_.getSkillType());
            }
         }
         else if(_loc2_.indexOf("btnXingZhiYu") != -1)
         {
            _loc28_ = GQXingZhiYuSkillParse.getGQXingZhiYuSkillParse(_loc3_.raceId);
            _loc29_ = int(_loc28_.spiritSkillId);
            _loc30_ = this._pmService.customData.pmSkillMap.getSkill(_loc29_);
            if(_loc29_ > 0)
            {
               _loc17_ = int(Panel_Helper.intelligentlyGetIndex(param1.target as DisplayObject));
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc30_.skillId,_loc30_.getSkillType(),_loc17_);
            }
         }
         else if(_loc2_.indexOf("btnJuexing") != -1)
         {
            _loc31_ = int(GQJueXingSkillParse.getSkillCd(_loc3_));
            _loc32_ = GQJueXingSkillParse.getJueXingSkillParse(_loc3_.raceId);
            _loc17_ = int(Panel_Helper.intelligentlyGetIndex(param1.target as DisplayObject));
            _loc33_ = int(_loc32_.changeSkillIds[_loc17_]);
            _loc34_ = this._pmService.customData.pmSkillMap.getSkill(_loc33_);
            if(_loc33_ < 0 || _loc31_ > 0 || _loc3_.curGQSoulNum < _loc34_.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(_loc3_))
            {
               return;
            }
            UseBigSkillHandler.instance.handleUse(_loc3_,_loc34_.skillId,_loc34_.getSkillType(),_loc17_);
         }
         else if(_loc2_ == "btnExitJuexingChangeView")
         {
            _loc32_ = GQJueXingSkillParse.getJueXingSkillParse(_loc3_.raceId);
            _loc35_ = int(_loc32_.changeBackSkillId);
            _loc36_ = this._pmService.customData.pmSkillMap.getSkill(_loc35_);
            if(_loc35_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc36_.skillId,_loc36_.getSkillType());
            }
         }
         else if(_loc2_ == "btnWumangXingji")
         {
            _loc31_ = int(GQWumangXingjiSkillParse.getSkillCd(_loc3_));
            _loc37_ = GQWumangXingjiSkillParse.getWumangXingjiSkillData(_loc3_.raceId);
            _loc17_ = int(Panel_Helper.intelligentlyGetIndex(param1.target as DisplayObject));
            _loc38_ = int(_loc37_.wumangxingjiSkillId);
            _loc39_ = this._pmService.customData.pmSkillMap.getSkill(_loc38_);
            if(_loc38_ < 0 || _loc31_ > 0)
            {
               return;
            }
            UseBigSkillHandler.instance.handleUse(_loc3_,GQWumangXingjiSkillParse.getWumangXingjiSkillIds(_loc3_)[_loc17_],_loc39_.getSkillType(),_loc17_);
         }
         else if(_loc2_ == "btnEternityZhanyiSpiritSkill")
         {
            _loc40_ = GQEternityZhanyiSkillParse.getEternityZhanyiSkillParse(_loc3_.raceId);
            _loc41_ = int(_loc40_.enternitySpiritSkillId);
            _loc42_ = this._pmService.customData.pmSkillMap.getSkill(_loc41_);
            UseBigSkillHandler.instance.handleUse(_loc3_,_loc42_.skillId,_loc42_.getSkillType());
         }
         else if(_loc2_.indexOf("btnEternityZhanyiCommonSkill") != -1)
         {
            _loc40_ = GQEternityZhanyiSkillParse.getEternityZhanyiSkillParse(_loc3_.raceId);
            _loc17_ = int(Panel_Helper.intelligentlyGetIndex(param1.target as DisplayObject));
            _loc43_ = int(_loc40_.enternityCommonSkillIds[_loc17_]);
            _loc44_ = this._pmService.customData.pmSkillMap.getSkill(_loc43_);
            UseBigSkillHandler.instance.handleUse(_loc3_,_loc44_.skillId,_loc44_.getSkillType(),_loc17_);
         }
         else if(_loc2_ == "btnShenqi")
         {
            _loc45_ = int(GQShenQiSkillParse.getShenqiSpiritSkillId(_loc3_));
            _loc46_ = this._pmService.customData.pmSkillMap.getSkill(_loc45_);
            if(_loc45_ > 0)
            {
               _loc7_ = int(_loc3_.curGQSoulNum);
               if(_loc7_ < _loc46_.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(_loc3_))
               {
                  return;
               }
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc46_.skillId,_loc46_.getSkillType());
            }
         }
         else if(_loc2_ == "btnYanhuaZhiyao")
         {
            _loc47_ = int(GQYanhuaZhiyaoGongmingZhongduanSkillParse.getYanhuaZhiyaoSpiritSkillId(_loc3_));
            _loc48_ = this._pmService.customData.pmSkillMap.getSkill(_loc47_);
            if(_loc47_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc48_.skillId,_loc48_.getSkillType());
            }
         }
         else if(_loc2_ == "btnZhigaoRongyao")
         {
            _loc49_ = int(GQZhigaoRongyaoSkillParse.getZhigaoRongyaoSkillId(_loc3_));
            _loc50_ = this._pmService.customData.pmSkillMap.getSkill(_loc49_);
            if(_loc49_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc50_.skillId,_loc50_.getSkillType());
            }
         }
         else if(_loc2_ == "mctipslayer" || _loc2_ == "mcBackGround")
         {
            _loc51_ = GQPetHelper.getGQPetBigSkill(_loc3_);
            if(this.isEnable())
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc51_.skillId,_loc51_.getSkillType());
            }
         }
         else if(_loc2_ == "btnMiBao")
         {
            _loc52_ = int(GQMiBaoSkillParse.getMiBaoSkillId(_loc3_));
            _loc53_ = this._pmService.customData.pmSkillMap.getSkill(_loc52_);
            if(_loc52_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc53_.skillId,_loc53_.getSkillType());
            }
         }
         else if(_loc2_.indexOf("btnMingYunBoYi") != -1)
         {
            _loc54_ = GQMingYunBoYiSkillParse.getGQMingYunBoYiSkillParse(_loc3_.raceId);
            _loc55_ = int(_loc54_.spiritSkillId);
            _loc56_ = this._pmService.customData.pmSkillMap.getSkill(_loc55_);
            if(_loc55_ > 0)
            {
               _loc17_ = int(Panel_Helper.intelligentlyGetIndex(param1.target as DisplayObject));
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc56_.skillId,_loc56_.getSkillType(),_loc17_);
            }
         }
         else if(_loc2_ == "btnJiuRiChongXian")
         {
            _loc57_ = int(GQJiuRiChongXianSkillParse.getJiuRiChongXianSpiritSkillId(_loc3_));
            _loc58_ = this._pmService.customData.pmSkillMap.getSkill(_loc57_);
            if(_loc57_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc57_,_loc58_.getSkillType());
            }
         }
         else if(_loc2_ == "btnHuanLingShi")
         {
            _loc59_ = int(GQHuanLingShiSkillParse.getHuanLingShiSpiritSkillId(_loc3_));
            _loc60_ = this._pmService.customData.pmSkillMap.getSkill(_loc59_);
            if(_loc59_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc59_,_loc60_.getSkillType());
            }
         }
         else if(_loc2_ == "btnXingHuanShi")
         {
            _loc61_ = int(GQXingHuanShiSkillParse.getXingHuanShiSpiritSkillId(_loc3_));
            _loc62_ = this._pmService.customData.pmSkillMap.getSkill(_loc61_);
            if(_loc61_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc61_,_loc62_.getSkillType());
            }
         }
         else if(_loc2_ == "btnDengShenChangJie")
         {
            _loc63_ = int(GQDengShenChangJieSkillParse.getSpiritSkillId(_loc3_));
            _loc64_ = this._pmService.customData.pmSkillMap.getSkill(_loc63_);
            if(_loc63_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc63_,_loc64_.getSkillType());
            }
         }
         else if(_loc2_ == "btnBuxiuLvtu")
         {
            _loc65_ = int(GQBuxiuLvtuSkillParse.getSpiritSkillId(_loc3_));
            _loc66_ = this._pmService.customData.pmSkillMap.getSkill(_loc65_);
            if(_loc65_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc65_,_loc66_.getSkillType());
            }
         }
         else if(_loc2_ == "btnWanyuZhichao")
         {
            _loc67_ = int(GQWanyuZhichaoSkillParse.getWanyuZhichaoSpiritSkillId(_loc3_));
            _loc68_ = this._pmService.customData.pmSkillMap.getSkill(_loc67_);
            if(_loc67_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc67_,_loc68_.getSkillType());
            }
         }
         else if(_loc2_ == "btnHundunJuedou")
         {
            _loc69_ = int(GQHunDunJueDouSkillParse.getHunDunJueDouSkillId(_loc3_));
            _loc70_ = this._pmService.customData.pmSkillMap.getSkill(_loc69_);
            if(_loc69_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc69_,_loc70_.getSkillType());
            }
         }
         else if(_loc2_ == "btnShiKongFangZhu")
         {
            _loc71_ = int(GQShiKongFangZhuSkillParse.getShiKongFangZhuSkillId(_loc3_));
            _loc72_ = this._pmService.customData.pmSkillMap.getSkill(_loc71_);
            if(_loc71_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc71_,_loc72_.getSkillType());
            }
         }
         else if(_loc2_ == "btnJiangShen")
         {
            _loc73_ = int(GQJiangShenSkillParse.getJiangShenSkillId(_loc3_));
            _loc74_ = this._pmService.customData.pmSkillMap.getSkill(_loc73_);
            if(_loc73_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc73_,_loc74_.getSkillType());
            }
         }
         else if(_loc2_.indexOf("btnShenYuTianGang") != -1)
         {
            _loc31_ = StatusUtil.getShenYuTianGangSpiritSkillCd(_loc3_);
            _loc17_ = int(Panel_Helper.intelligentlyGetIndex(param1.target as DisplayObject));
            _loc75_ = int(GQShenYuTianGangSkillParse.getSpiritSkillIdArr(_loc3_)[_loc17_]);
            _loc76_ = this._pmService.customData.pmSkillMap.getSkill(_loc75_);
            if(_loc75_ < 0 || _loc31_ > 0)
            {
               return;
            }
            UseBigSkillHandler.instance.handleUse(_loc3_,_loc76_.skillId,_loc76_.getSkillType(),_loc17_);
         }
         else if(_loc2_ == "btnZhenLiFaDian")
         {
            _loc77_ = int(GQZhenLiFaDianSkillParse.getSpiritSkillId(_loc3_));
            _loc78_ = this._pmService.customData.pmSkillMap.getSkill(_loc77_);
            if(_loc77_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc77_,_loc78_.getSkillType());
            }
         }
         else if(_loc2_ == "btnLiejieZhixi")
         {
            _loc79_ = int(GQLieJieZhiXiSkillParse.getSpiritSkillId(_loc3_));
            _loc80_ = this._pmService.customData.pmSkillMap.getSkill(_loc79_);
            if(_loc79_ > 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc79_,_loc80_.getSkillType());
            }
         }
      }
      
      override public function dispose() : void
      {
         var _loc1_:CachedClip = null;
         var _loc2_:MovieClip = null;
         var _loc3_:MovieClip = null;
         super.dispose();
         if(this._eternityContractPanelHandler)
         {
            this._eternityContractPanelHandler.dispose();
            this._eternityContractPanelHandler = null;
         }
         FightEventDispatcher.instance.removeEventListener(FightInnerEvent.ON_MOUSE_OVER_PET,this.onMouseRoleOverPetListener);
         FightEventDispatcher.instance.removeEventListener(FightInnerEvent.ON_MOUSE_OUT_PET,this.onMouseRollOutPetListener);
         this._mcChangeView.removeEventListener(MouseEvent.ROLL_OVER,this.onRollOverChangeViewListener);
         this._mcChangeView.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutChangeViewListener);
         this._effectIcon && this._effectIcon.dispose();
         DisplayUtil.stopAndRemove(this._effectIcon);
         this._effectIcon = null;
         for each(_loc1_ in this._mc2v2EffectIcons)
         {
            DisplayUtil.stopAndRemove(_loc1_);
            _loc1_.dispose();
         }
         this._mc2v2EffectIcons.length = 0;
         _loc2_ = this._mcChangeView.getChildByName("mcGQExtSkill") as MovieClip;
         if(_loc2_)
         {
            _loc3_ = _loc2_.getChildByName("mcGQSubExtSkill") as MovieClip;
            if(Boolean(_loc3_) && Boolean(_loc3_.mcArmorBurst))
            {
               TipsManager.getInstance().removeTips(_loc3_.mcArmorBurst);
            }
         }
         if(this._lianSuoAttributeIcon)
         {
            this._lianSuoAttributeIcon.dispose();
            this._lianSuoAttributeIcon = null;
         }
         this.onRollOutListener(null);
      }
      
      override protected function care() : Boolean
      {
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         return GQPetHelper.checkIsGQPet(_loc1_.raceId);
      }
      
      private function haveOnlyOneEnemy() : Boolean
      {
         return FightData.instance.opponents.length == 1;
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
      
      private function onMouseRollOutPetListener(param1:CommonEvent) : void
      {
         if(this.haveOnlyOneEnemy())
         {
            return;
         }
         this._targetVSPlayer = null;
         this.removeEffectIcon();
      }
      
      private function updateEffectIcon() : void
      {
         var _loc4_:Object = null;
         var _loc7_:PlayerBattleInfo = null;
         var _loc8_:MovieClip = null;
         if(this._targetVSPlayer == null)
         {
            this.removeEffectIcon();
            return;
         }
         var _loc1_:PetBriefInfo = this._targetVSPlayer.myPets[0] as PetBriefInfo;
         if(_loc1_ == null)
         {
            this.removeEffectIcon();
            return;
         }
         if(!this._petInfo)
         {
            return;
         }
         if(!_pmService.getOperationPM(this._petInfo.raceId).pmData.isGQPM())
         {
            return;
         }
         var _loc2_:PMSkill = GQPetHelper.getGQPetBigSkill(this._petInfo);
         if(_loc2_ == null)
         {
            this.removeEffectIcon();
            return;
         }
         var _loc3_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         if(this._targetVSPlayer.lingshouRealitySlotId == -1)
         {
            _loc4_ = _loc3_.getPetMes(_loc1_.raceId);
         }
         else
         {
            _loc7_ = FightData.instance.getPlayerInfoBySlotId(this._targetVSPlayer.lingshouRealitySlotId);
            _loc4_ = _loc3_.getPetMes((_loc7_.myPets[0] as PetBriefInfo).raceId);
         }
         var _loc5_:Object = _loc3_.getPetSkillMes(_loc2_.skillId);
         var _loc6_:int = _loc3_.compareAttributeRelation(_loc5_.attribute,_loc4_.attribute,_loc4_.attribute2) + 1;
         if(this._effectIcon == null)
         {
            _loc8_ = new EffectIcon();
            this._effectIcon = new CachedClip(_loc8_);
            this._effectIcon.x = -58;
            this._effectIcon.y = -20;
         }
         this._effectIcon.gotoAndStop(_loc6_);
         this._effectIcon.visible = true;
         this._mcChangeView.addChild(this._effectIcon);
      }
      
      private function removeEffectIcon() : void
      {
         DisplayUtil.stopAndRemove(this._effectIcon);
      }
   }
}

