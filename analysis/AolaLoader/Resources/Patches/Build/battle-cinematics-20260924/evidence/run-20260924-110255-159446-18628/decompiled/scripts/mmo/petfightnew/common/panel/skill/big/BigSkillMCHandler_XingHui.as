package mmo.petfightnew.common.panel.skill.big
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.XingHuiPetHelperUtil;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.XHCheckerBoardSkillParse;
   import mmo.interfaces.pet.data.XHFaHuanSkillParse;
   import mmo.interfaces.pet.data.XHLunhuiShiyueSkillParse;
   import mmo.interfaces.pet.data.XHZhanJiSkillParse;
   import mmo.interfaces.pet.data.XingHuiAnnualFee22SkillParser;
   import mmo.interfaces.pet.data.XingHuiChuanShuoSkillParser;
   import mmo.interfaces.pet.data.XingHuiHuanXiangSkillParser;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.panel.XinghuiAddedKillPanel;
   import mmo.petfightnew.common.panel.XinghuiTongLingSummonPanelHandle;
   import mmo.petfightnew.common.util.XinghuiPetHelper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.petfight.common.config.FightResConfig;
   import mmo.play.petfight.common.data.SkillType;
   
   public class BigSkillMCHandler_XingHui extends BigSkillMCHandler
   {
      
      private var _xinghuiAddedSkillPanel:XinghuiAddedKillPanel = null;
      
      private var _summonPanelHandle:XinghuiTongLingSummonPanelHandle;
      
      public function BigSkillMCHandler_XingHui()
      {
         super();
      }
      
      override public function update() : void
      {
         var _loc6_:MovieClip = null;
         var _loc7_:MovieClip = null;
         var _loc14_:int = 0;
         super.update();
         var _loc1_:PetBriefInfo = this.getOperatingPetInfo();
         if(this._pmService.getOperationPM(_loc1_.raceId) == null || this._pmService.getOperationPM(_loc1_.raceId).pmData == null)
         {
            throw new Error("PM数据有问题，应该是没有" + _loc1_.raceId + "的" + _loc1_.name + "这只亚比！");
         }
         var _loc2_:PMData = this._pmService.getOperationPM(_loc1_.raceId).pmData;
         var _loc3_:int = int(_loc2_.maxXinghuiSoulNum);
         var _loc4_:int = int(_loc1_.curXinghuiSoulNum);
         var _loc5_:PMSkill = XinghuiPetHelper.getXinghuiPetBigSkill(_loc1_);
         this._mcChangeView.gotoAndStop(16);
         var _loc8_:* = _loc5_.clientDesc;
         _loc6_ = this._mcChangeView.getChildByName("mcbig") as MovieClip;
         _loc6_.gotoAndStop(_loc3_ - 4);
         _loc7_ = _loc6_.mc.mcsouls;
         _loc7_.mouseChildren = _loc7_.mouseEnabled = false;
         _loc7_.gotoAndStop(_loc4_ + 1);
         var _loc9_:Sprite = this._mcChangeView.getChildByName("mctipslayer") as Sprite;
         if(_loc9_ == null)
         {
            _loc9_ = this._mcChangeView.curClip as Sprite;
         }
         var _loc10_:MovieClip = this._mcChangeView.getChildByName("mvSoul") as MovieClip;
         _loc10_.mouseEnabled = _loc10_.mouseChildren = false;
         _loc8_ += "\n-------\n当前拥有" + _loc4_ + "星。";
         if(_loc4_ < _loc5_.costSoulNum)
         {
            _loc8_ += "\n-------\n星不足，不能使用超星辉必杀！";
            _loc9_.buttonMode = false;
            _loc10_.stop();
            _loc10_.visible = false;
         }
         else
         {
            _loc9_.buttonMode = true;
            _loc10_.play();
            _loc10_.visible = true;
         }
         var _loc11_:MovieClip = this._mcChangeView.getChildByName("mcXingHuiExtSkill") as MovieClip;
         DisplayUtil.clearChildren(_loc11_);
         this.updateExtraSkill(_loc11_,_loc2_,_loc1_);
         ActComHelper.setMcFrame(this._mcChangeView,"mcXingHuiBiShaName",1);
         var _loc12_:MovieClip = this._mcChangeView.getChildByName("mcbackground") as MovieClip;
         if(XinghuiPetType.isCheckerBoard(_loc2_.getXinghuiType()))
         {
            _loc14_ = int(XHCheckerBoardSkillParse.getPetHasBigType(_loc1_));
            _loc12_.gotoAndStop(_loc14_ == -1 ? 4 : 3 + _loc14_);
            ActComHelper.setMcFrame(this._mcChangeView,"mcXingHuiBiShaName",_loc14_ == 2 ? 2 : 1);
         }
         else if(_loc1_.isShielded())
         {
            _loc12_.gotoAndStop(2);
         }
         else if(_loc2_.getXinghuiType() == XinghuiPetType.JUEXING && this.getIsAfterJuexing(_loc2_,_loc1_))
         {
            _loc12_.gotoAndStop(2);
         }
         else
         {
            _loc12_.gotoAndStop(1);
         }
         var _loc13_:String = _loc5_.newCnName + " 威力：" + getSkillPowerDesc(_loc5_.power);
         TipsManager.getInstance().replaceComplexTips(_loc9_,_loc13_,_loc8_,100,-100,9);
      }
      
      private function updateExtraSkill(param1:MovieClip, param2:PMData, param3:PetBriefInfo) : void
      {
         var xhExtSkillMc:MovieClip = null;
         var mcXingHuiExtSkill:MovieClip = param1;
         var pmData:PMData = param2;
         var petInfo:PetBriefInfo = param3;
         var xhExtSkillCls:Class = FightData.instance.applicationDomain.getDefinition(FightResConfig.XH_ExtBigSkillMc_ClsName) as Class;
         if(xhExtSkillCls)
         {
            xhExtSkillMc = new xhExtSkillCls() as MovieClip;
            xhExtSkillMc.name = "mcXHSubExtSkill";
            mcXingHuiExtSkill.addChild(xhExtSkillMc);
            mcXingHuiExtSkill = xhExtSkillMc;
            this.updateXingHuiWangZheSkill(mcXingHuiExtSkill.mcwangzhe,pmData,petInfo,XinghuiPetType.WANGZHE_REAL);
            this.updateXingHuiWangZheSkill(mcXingHuiExtSkill.mcshenwangzhe,pmData,petInfo,XinghuiPetType.SHEN_WANGZHE_REAL);
            this.updateXingHuiChuanShuoSkill(mcXingHuiExtSkill.mcChuanShuo,pmData,petInfo);
            this.updateXingHuiHuanXiangSkill(mcXingHuiExtSkill.mcHuanXiang,pmData,petInfo);
            this.updateXingHuiCheckerBoardSkill(mcXingHuiExtSkill.mcQiPan,pmData,petInfo);
            this.updateXingHuiTongLingSkill(petInfo,mcXingHuiExtSkill.mcTongLing);
            this.updateXingHuiAnnualFee22Skill(mcXingHuiExtSkill.mcAnnualFee22,pmData,petInfo);
            this.updateXingHuiZhanJiSkill(mcXingHuiExtSkill.mcZhanJi,pmData,petInfo);
            this.updateXingHuiFaHuanSkill(mcXingHuiExtSkill.mcFaHuan,pmData,petInfo);
            this.updateLunhuiShiyueSkill(mcXingHuiExtSkill.mcLunhuiShiyue,pmData,petInfo);
            return;
         }
         ResScheduler.getRes(ResParams.createTemp("pet/petfightnew_xhresource",function(param1:*, param2:ApplicationDomain):*
         {
            updateExtraSkill(mcXingHuiExtSkill,pmData,petInfo);
         },FightResConfig.XH_ExtBigSkillMc_ClsName));
      }
      
      protected function updateXingHuiWangZheSkill(param1:MovieClip, param2:PMData, param3:PetBriefInfo, param4:int) : void
      {
         var _loc7_:String = null;
         if(param1 == null)
         {
            return;
         }
         if(param4 == XinghuiPetType.WANGZHE_REAL)
         {
            param1.visible = param2.getXinghuiType() == XinghuiPetType.WANGZHE_REAL;
         }
         else if(param4 == XinghuiPetType.SHEN_WANGZHE_REAL)
         {
            param1.visible = param2.getXinghuiType() == XinghuiPetType.SHEN_WANGZHE_REAL;
         }
         if(!param1.visible)
         {
            DisplayUtil.stopAndRemove(param1);
         }
         var _loc5_:PMSkill = XinghuiPetHelper.getWangzheRealExtentionSkill(param3);
         var _loc6_:PMSkill = null;
         param1.gotoAndStop(1);
         if(param1.visible)
         {
            if(_loc5_ != null)
            {
               if(!param3.hasBird)
               {
                  param1.gotoAndStop(1);
               }
               else
               {
                  param1.gotoAndStop(2);
               }
               _loc6_ = _loc5_;
            }
            else
            {
               _loc6_ = XinghuiPetHelper.getWangzheRealExtensionPassiveSkill(param3);
            }
         }
         if(param1 != null && param1.visible)
         {
            _loc7_ = _loc6_.newCnName + " 威力：" + getSkillPowerDesc(_loc6_.power);
            TipsManager.getInstance().replaceComplexTips(param1,_loc7_,_loc6_.clientDesc,100,-100,9);
         }
      }
      
      protected function updateXingHuiChuanShuoSkill(param1:MovieClip, param2:PMData, param3:PetBriefInfo) : void
      {
         var _loc12_:PMSkill = null;
         var _loc13_:String = null;
         var _loc14_:Boolean = false;
         if(param1 == null)
         {
            return;
         }
         param3 = getOperatingPetInfo() as PetBriefInfo;
         var _loc4_:Boolean = param2.raceId == 4209 || Boolean(XinghuiPetType.isChuanShuo(param2.getXinghuiType()));
         param1.visible = _loc4_;
         if(!_loc4_)
         {
            DisplayUtil.stopAndRemove(param1);
            return;
         }
         var _loc5_:XingHuiChuanShuoSkillParser = param3.getXingHuiChuangShuoParser();
         var _loc6_:Boolean = Boolean(_loc5_.isBianShening());
         var _loc7_:Boolean = Boolean(_loc5_.isUsedBianShen());
         var _loc8_:int = _loc7_ ? 3 : (_loc6_ ? 2 : 1);
         param1.gotoAndStop(_loc8_);
         this.updateChuanShuoBtnByUseSkillState();
         var _loc9_:Array = XinghuiPetHelper.getSkiilIdsByRaceIdAndSkillName(param3.raceId,"传说技能");
         var _loc10_:int = int(_loc9_[_loc8_ - 1]);
         if(_loc10_ > 0)
         {
            _loc12_ = this._pmService.customData.pmSkillMap.getSkill(_loc10_);
            _loc13_ = _loc12_.newCnName + " 威力：" + getSkillPowerDesc(_loc12_.power);
            TipsManager.getInstance().replaceComplexTips(param1,_loc13_,_loc12_.clientDesc,100,-100,9);
         }
         else
         {
            TipsManager.getInstance().replaceTips(param1,"已经使用过星辉传说技能");
         }
         var _loc11_:SimpleButton = param1.btnXingHuiChuangShuo;
         if(_loc11_ != null)
         {
            _loc14_ = Boolean(this.getOperatingPetInfo().getXingHuiChuangShuoParser().isUseSkillThisTurn);
            _loc11_.enabled = !_loc14_;
            _loc11_.mouseEnabled = !_loc14_;
         }
      }
      
      private function updateChuanShuoBtnByUseSkillState() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:MovieClip = null;
         var _loc4_:SimpleButton = null;
         var _loc5_:Boolean = false;
         var _loc1_:MovieClip = this._mcChangeView.getChildByName("mcXingHuiExtSkill") as MovieClip;
         if(_loc1_)
         {
            _loc2_ = _loc1_.getChildByName("mcXHSubExtSkill") as MovieClip;
            _loc3_ = _loc2_ == null ? null : _loc2_.mcChuanShuo;
            if(_loc3_ != null)
            {
               _loc4_ = _loc3_.btnXingHuiChuangShuo;
               if(_loc4_ != null)
               {
                  _loc5_ = Boolean(this.getOperatingPetInfo().getXingHuiChuangShuoParser().isUseSkillThisTurn);
                  _loc4_.enabled = !_loc5_;
                  _loc4_.mouseEnabled = !_loc5_;
               }
            }
         }
      }
      
      protected function updateXingHuiZhanJiSkill(param1:MovieClip, param2:PMData, param3:PetBriefInfo) : void
      {
         var _loc7_:int = 0;
         var _loc8_:PMSkill = null;
         var _loc9_:String = null;
         if(param1 == null)
         {
            return;
         }
         param3 = getOperatingPetInfo() as PetBriefInfo;
         var _loc4_:Boolean = Boolean(XinghuiPetType.isZhanJiType(param2.getXinghuiType()));
         param1.visible = _loc4_;
         if(!_loc4_)
         {
            DisplayUtil.stopAndRemove(param1);
            return;
         }
         var _loc5_:XHZhanJiSkillParse = XHZhanJiSkillParse.getSkillData(param3.raceId);
         var _loc6_:int = int(_loc5_.espSkillId);
         param1.gotoAndStop(XHZhanJiSkillParse.isAtStrongState(param3) ? 2 : 1);
         this.updateZhanJiBtnByUseSkillState();
         if(_loc6_ > 0)
         {
            _loc7_ = int(XHZhanJiSkillParse.getSkillCd(param3));
            if(_loc7_ == 0)
            {
               _loc8_ = this._pmService.customData.pmSkillMap.getSkill(_loc6_);
               _loc9_ = _loc8_.newCnName + " 威力：" + getSkillPowerDesc(_loc8_.power);
               TipsManager.getInstance().replaceComplexTips(param1,_loc9_,_loc8_.clientDesc,100,-100,9);
            }
            else
            {
               TipsManager.getInstance().replaceTips(param1,_loc7_ + "回合后方可使用");
            }
         }
         else
         {
            TipsManager.getInstance().replaceTips(param1,"已经使用过战技技能");
         }
      }
      
      protected function updateXingHuiFaHuanSkill(param1:MovieClip, param2:PMData, param3:PetBriefInfo) : void
      {
         var _loc7_:int = 0;
         var _loc8_:PMSkill = null;
         var _loc9_:String = null;
         if(param1 == null)
         {
            return;
         }
         param3 = getOperatingPetInfo() as PetBriefInfo;
         var _loc4_:Boolean = Boolean(XinghuiPetType.isFaHuanType(param2.getXinghuiType()));
         param1.visible = _loc4_;
         if(!_loc4_)
         {
            DisplayUtil.stopAndRemove(param1);
            return;
         }
         var _loc5_:XHFaHuanSkillParse = XHFaHuanSkillParse.getSkillData(param3.raceId);
         var _loc6_:int = int(_loc5_.activeSkillId);
         this.updateFaHuanBtnByUseSkillState();
         if(_loc6_ > 0)
         {
            _loc7_ = int(XHFaHuanSkillParse.getSkillCd(param3));
            if(_loc7_ == 0)
            {
               param1.gotoAndStop(1);
               _loc8_ = this._pmService.customData.pmSkillMap.getSkill(_loc6_);
               _loc9_ = _loc8_.newCnName + " 威力：" + getSkillPowerDesc(_loc8_.power);
               TipsManager.getInstance().replaceComplexTips(param1,_loc9_,_loc8_.clientDesc,100,-100,9);
            }
            else
            {
               param1.gotoAndStop(2);
               TipsManager.getInstance().replaceTips(param1,_loc7_ + "回合后方可使用");
            }
         }
         else
         {
            TipsManager.getInstance().replaceTips(param1,"已经使用过战技技能");
         }
      }
      
      protected function updateLunhuiShiyueSkill(param1:MovieClip, param2:PMData, param3:PetBriefInfo) : void
      {
         var _loc6_:MovieClip = null;
         var _loc7_:int = 0;
         var _loc8_:SimpleButton = null;
         var _loc9_:SimpleButton = null;
         var _loc10_:int = 0;
         var _loc11_:PMSkill = null;
         var _loc12_:String = null;
         var _loc13_:SimpleButton = null;
         if(param1 == null)
         {
            return;
         }
         param3 = getOperatingPetInfo() as PetBriefInfo;
         var _loc4_:Boolean = Boolean(XinghuiPetType.isLunhuiShiyueType(param2.getXinghuiType()));
         param1.visible = _loc4_;
         if(!_loc4_)
         {
            param1.stop();
            DisplayUtil.stopAndRemove(param1);
            return;
         }
         param1.gotoAndStop(XinghuiPetType.getLunhuiQIyueByRaceId(param3.raceId).exSkillFrame);
         var _loc5_:int = int(XHLunhuiShiyueSkillParse.getTejiOrActivateSkillIdByPbf(param3));
         if(_loc5_ > 0)
         {
            _loc6_ = param1.getChildByName("mc") as MovieClip;
            if(XHLunhuiShiyueSkillParse.getIsUsedTeji(param3))
            {
               _loc6_.gotoAndStop(2);
               _loc7_ = 0;
               while(_loc7_ < XHLunhuiShiyueSkillParse.getDataStrAryByRaceId(this.getOperatingPetInfo().raceId).length)
               {
                  _loc9_ = _loc6_.getChildByName("btnLunhuiShiyueActivate" + _loc7_) as SimpleButton;
                  _loc9_.visible = XHLunhuiShiyueSkillParse.getRongHunIndexByPbf(param3) == _loc7_;
                  _loc7_++;
               }
               _loc8_ = _loc6_.getChildByName("btnLunhuiShiyueActivate" + XHLunhuiShiyueSkillParse.getRongHunIndexByPbf(param3)) as SimpleButton;
               if(_loc8_ != null)
               {
                  _loc10_ = int(XHLunhuiShiyueSkillParse.getSkillCd(param3));
                  if(_loc10_ == 0)
                  {
                     _loc8_.mouseEnabled = true;
                     DisplayUtil.clearFilters(_loc8_);
                     _loc11_ = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
                     _loc12_ = _loc11_.newCnName + " 威力：" + getSkillPowerDesc(_loc11_.power);
                     TipsManager.getInstance().replaceComplexTips(param1,_loc12_,_loc11_.clientDesc);
                  }
                  else
                  {
                     _loc8_.mouseEnabled = false;
                     DisplayUtil.applyGray(_loc8_);
                     TipsManager.getInstance().replaceTips(param1,_loc10_ + "回合后方可使用");
                  }
               }
            }
            else
            {
               _loc6_.gotoAndStop(1);
               _loc7_ = 0;
               while(_loc7_ < XHLunhuiShiyueSkillParse.getDataStrAryByRaceId(this.getOperatingPetInfo().raceId).length)
               {
                  _loc13_ = _loc6_.getChildByName("btnLunhuiShiyueTeji" + _loc7_) as SimpleButton;
                  _loc13_.visible = XHLunhuiShiyueSkillParse.getRongHunIndexByPbf(param3) == _loc7_;
                  _loc7_++;
               }
               _loc8_ = _loc6_.getChildByName("btnLunhuiShiyueTeji" + XHLunhuiShiyueSkillParse.getRongHunIndexByPbf(param3)) as SimpleButton;
               if(_loc8_ != null)
               {
                  _loc8_.mouseEnabled = true;
                  DisplayUtil.clearFilters(_loc8_);
                  _loc11_ = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
                  _loc12_ = _loc11_.newCnName + " 威力：" + getSkillPowerDesc(_loc11_.power);
                  TipsManager.getInstance().replaceComplexTips(param1,_loc12_,_loc11_.clientDesc);
               }
            }
         }
         else
         {
            param1.visible = false;
         }
      }
      
      protected function updateXingHuiHuanXiangSkill(param1:MovieClip, param2:PMData, param3:PetBriefInfo) : void
      {
         var _loc9_:PMSkill = null;
         var _loc10_:String = null;
         if(param1 == null)
         {
            return;
         }
         param3 = getOperatingPetInfo() as PetBriefInfo;
         var _loc4_:Boolean = Boolean(XinghuiPetType.isHuanXiang(param2.getXinghuiType()));
         param1.visible = _loc4_;
         if(!_loc4_)
         {
            DisplayUtil.stopAndRemove(param1);
            return;
         }
         var _loc5_:XingHuiHuanXiangSkillParser = param3.getXingHuiHuanXiangSkillParaser();
         var _loc6_:Array = XingHuiPetHelperUtil.getSkiilIdsByRaceIdAndSkillName(param3.raceId,"幻象系统");
         var _loc7_:int = int(_loc6_[_loc5_.isUseHuanXiang ? 1 : 2]);
         var _loc8_:int = _loc5_.isUseHuanXiang ? 2 : 1;
         param1.gotoAndStop(_loc8_);
         this.updateHuanXiangBtnByUseSkillState();
         if(_loc7_ > 0)
         {
            _loc9_ = this._pmService.customData.pmSkillMap.getSkill(_loc7_);
            _loc10_ = _loc9_.newCnName + " 威力：" + getSkillPowerDesc(_loc9_.power);
            TipsManager.getInstance().replaceComplexTips(param1,_loc10_,_loc9_.clientDesc,100,-100,9);
         }
         else
         {
            TipsManager.getInstance().replaceTips(param1,"已经使用过星辉幻象技能");
         }
      }
      
      private function updateHuanXiangBtnByUseSkillState() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:MovieClip = null;
         var _loc4_:SimpleButton = null;
         var _loc5_:Boolean = false;
         var _loc1_:MovieClip = this._mcChangeView.getChildByName("mcXingHuiExtSkill") as MovieClip;
         if(_loc1_)
         {
            _loc2_ = _loc1_.getChildByName("mcXHSubExtSkill") as MovieClip;
            _loc3_ = _loc2_ == null ? null : _loc2_["mcHuanXiang"];
            if(_loc3_ != null)
            {
               _loc4_ = _loc3_["btnXingHuiHuanXiang"];
               if(_loc4_ != null)
               {
                  _loc5_ = Boolean(this.getOperatingPetInfo().getXingHuiHuanXiangSkillParaser().isUseHuanXiang);
                  _loc4_.enabled = !_loc5_;
                  _loc4_.mouseEnabled = !_loc5_;
               }
            }
         }
      }
      
      private function updateZhanJiBtnByUseSkillState() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:MovieClip = null;
         var _loc4_:SimpleButton = null;
         var _loc5_:int = 0;
         var _loc6_:* = false;
         var _loc1_:MovieClip = this._mcChangeView.getChildByName("mcXingHuiExtSkill") as MovieClip;
         if(_loc1_)
         {
            _loc2_ = _loc1_.getChildByName("mcXHSubExtSkill") as MovieClip;
            _loc3_ = _loc2_ == null ? null : _loc2_["mcZhanJi"];
            if(_loc3_ != null)
            {
               _loc4_ = _loc3_["btnXingHuiZhanJi"];
               if(_loc4_ != null)
               {
                  _loc5_ = int(XHZhanJiSkillParse.getSkillCd(this.getOperatingPetInfo()));
                  _loc6_ = _loc5_ != 0;
                  _loc4_.enabled = !_loc6_;
                  _loc4_.mouseEnabled = !_loc6_;
               }
            }
         }
      }
      
      private function updateLunhuiShiyueBtnByUseSkill() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:MovieClip = null;
         var _loc4_:int = 0;
         var _loc5_:SimpleButton = null;
         var _loc1_:MovieClip = this._mcChangeView.getChildByName("mcXingHuiExtSkill") as MovieClip;
         if(_loc1_)
         {
            _loc2_ = _loc1_.getChildByName("mcXHSubExtSkill") as MovieClip;
            _loc3_ = _loc2_ == null ? null : _loc2_.mcLunhuiShiyue.mc;
            if(_loc3_ != null)
            {
               _loc4_ = 0;
               while(_loc4_ < XHLunhuiShiyueSkillParse.getDataStrAryByRaceId(this.getOperatingPetInfo().raceId).length)
               {
                  _loc5_ = _loc3_.getChildByName("btnLunhuiShiyueTeji" + _loc4_) as SimpleButton;
                  if(_loc5_ != null)
                  {
                     _loc5_.mouseEnabled = false;
                  }
                  _loc5_ = _loc3_.getChildByName("btnLunhuiShiyueActivate" + _loc4_) as SimpleButton;
                  if(_loc5_ != null)
                  {
                     _loc5_.mouseEnabled = false;
                  }
                  _loc4_++;
               }
            }
         }
      }
      
      private function updateFaHuanBtnByUseSkillState(param1:Boolean = false) : void
      {
         var _loc3_:MovieClip = null;
         var _loc4_:MovieClip = null;
         var _loc5_:SimpleButton = null;
         var _loc6_:int = 0;
         var _loc7_:* = false;
         var _loc2_:MovieClip = this._mcChangeView.getChildByName("mcXingHuiExtSkill") as MovieClip;
         if(_loc2_)
         {
            _loc3_ = _loc2_.getChildByName("mcXHSubExtSkill") as MovieClip;
            _loc4_ = _loc3_ == null ? null : _loc3_["mcFaHuan"];
            if(_loc4_ != null)
            {
               if(param1)
               {
                  _loc4_.gotoAndStop(2);
               }
               _loc5_ = _loc4_["btnXingHuiFaHuan"];
               if(_loc5_ != null)
               {
                  _loc6_ = int(XHFaHuanSkillParse.getSkillCd(this.getOperatingPetInfo()));
                  _loc7_ = _loc6_ != 0;
                  _loc5_.enabled = !_loc7_;
                  _loc5_.mouseEnabled = !_loc7_;
               }
            }
         }
      }
      
      private function getIsAfterJuexing(param1:PMData, param2:PetBriefInfo) : Boolean
      {
         var _loc3_:Array = param1.getXinghuiExtraConfig().split("=")[1].split("#");
         if(parseInt(_loc3_[1]) == param2.raceId)
         {
            return true;
         }
         return false;
      }
      
      override public function onMouseRollOver(param1:MouseEvent) : void
      {
         var _loc3_:Array = null;
         var _loc2_:PetBriefInfo = this.getOperatingPetInfo();
         if(!XinghuiAddedKillPanel.canShowAddedSkill(_loc2_,SkillType.XINGHUI_KILL_BIG))
         {
            return;
         }
         if(XinghuiAddedKillPanel.canShowAddedSkill(_loc2_,SkillType.XINGHUI_KILL_BIG))
         {
            if(this._xinghuiAddedSkillPanel == null)
            {
               _loc3_ = XinghuiAddedKillPanel.getExtAddSkillInfo(_loc2_,SkillType.XINGHUI_KILL_BIG);
               this._xinghuiAddedSkillPanel = new XinghuiAddedKillPanel(_loc3_,_loc2_,SkillType.XINGHUI_KILL_BIG);
               this._xinghuiAddedSkillPanel.x = -25 + this._mcChangeView.x;
               this._xinghuiAddedSkillPanel.y = 3 + this._mcChangeView.y;
            }
            this._mcChangeView.addChild(this._xinghuiAddedSkillPanel);
         }
      }
      
      override public function onMouseRollOut() : void
      {
         if(this._xinghuiAddedSkillPanel != null)
         {
            DisplayUtil.stopAndRemove(this._xinghuiAddedSkillPanel);
            this._xinghuiAddedSkillPanel = null;
         }
      }
      
      override public function onClicked(param1:MouseEvent) : void
      {
         var _loc4_:int = 0;
         var _loc5_:PMSkill = null;
         var _loc6_:XHFaHuanSkillParse = null;
         var _loc7_:int = 0;
         var _loc8_:PMSkill = null;
         var _loc9_:XHZhanJiSkillParse = null;
         var _loc10_:int = 0;
         var _loc11_:PMSkill = null;
         var _loc12_:Array = null;
         var _loc13_:int = 0;
         var _loc14_:PMSkill = null;
         var _loc15_:Array = null;
         var _loc16_:int = 0;
         var _loc17_:PMSkill = null;
         var _loc18_:PMSkill = null;
         var _loc19_:Array = null;
         var _loc20_:XingHuiChuanShuoSkillParser = null;
         var _loc21_:Boolean = false;
         var _loc22_:int = 0;
         var _loc23_:PMSkill = null;
         var _loc24_:int = 0;
         var _loc25_:PMSkill = null;
         var _loc26_:int = 0;
         var _loc27_:PMSkill = null;
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnNoResponeSkill")
         {
            return;
         }
         var _loc3_:PetBriefInfo = getOperatingPetInfo();
         if(_loc2_.indexOf("btnLunhuiShiyueTeji") != -1 || _loc2_.indexOf("btnLunhuiShiyueActivate") != -1)
         {
            _loc4_ = int(XHLunhuiShiyueSkillParse.getTejiOrActivateSkillIdByPbf(_loc3_));
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc4_);
            if(!XHLunhuiShiyueSkillParse.getIsUsedTeji(_loc3_))
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc4_,_loc5_.getSkillType());
               this.updateLunhuiShiyueBtnByUseSkill();
            }
            else if(XHLunhuiShiyueSkillParse.getSkillCd(_loc3_) <= 0)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc4_,_loc5_.getSkillType());
               this.updateLunhuiShiyueBtnByUseSkill();
            }
         }
         else if(param1.target.name == "btnXingHuiFaHuan")
         {
            _loc6_ = XHFaHuanSkillParse.getSkillData(_loc3_.raceId);
            _loc7_ = int(_loc6_.activeSkillId);
            if(_loc7_ > 0)
            {
               _loc8_ = this._pmService.customData.pmSkillMap.getSkill(_loc7_);
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc8_.skillId,_loc8_.getSkillType());
               this.updateFaHuanBtnByUseSkillState(true);
            }
         }
         else if(param1.target.name == "btnXingHuiZhanJi")
         {
            _loc9_ = XHZhanJiSkillParse.getSkillData(_loc3_.raceId);
            _loc10_ = int(_loc9_.espSkillId);
            if(_loc10_ > 0)
            {
               _loc11_ = this._pmService.customData.pmSkillMap.getSkill(_loc10_);
               this.updateZhanJiBtnByUseSkillState();
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc11_.skillId,_loc11_.getSkillType());
            }
         }
         else if(param1.target.name == "btnAnnualFee22")
         {
            _loc12_ = XingHuiPetHelperUtil.getSkiilIdsByRaceIdAndSkillName(_loc3_.raceId,"第八识技能");
            _loc13_ = int(_loc12_[0]);
            _loc14_ = this._pmService.customData.pmSkillMap.getSkill(_loc13_);
            _loc3_.getXingHuiAnnualFee22SkillParser().isUseAnnualFee22 = true;
            this.updateAnnualFee22BtnByUseSkillState();
            UseBigSkillHandler.instance.handleUse(_loc3_,_loc14_.skillId,_loc14_.getSkillType());
         }
         else if(param1.target.name == "btnXingHuiHuanXiang")
         {
            _loc15_ = XingHuiPetHelperUtil.getSkiilIdsByRaceIdAndSkillName(_loc3_.raceId,"幻象系统");
            _loc16_ = int(_loc15_[2]);
            _loc17_ = this._pmService.customData.pmSkillMap.getSkill(_loc16_);
            _loc3_.getXingHuiHuanXiangSkillParaser().isUseHuanXiang = true;
            this.updateHuanXiangBtnByUseSkillState();
            UseBigSkillHandler.instance.handleUse(_loc3_,_loc17_.skillId,_loc17_.getSkillType());
         }
         else if(param1.target.name == "btnwangzhe")
         {
            _loc18_ = XinghuiPetHelper.getWangzheRealExtentionSkill(_loc3_);
            (param1.target.parent as MovieClip).gotoAndStop(1);
            _loc3_.setBirdUsed();
            UseBigSkillHandler.instance.handleUse(_loc3_,_loc18_.skillId,_loc18_.getSkillType());
         }
         else if(param1.target.name == "btnXingHuiChuangShuo")
         {
            _loc19_ = XinghuiPetHelper.getSkiilIdsByRaceIdAndSkillName(_loc3_.raceId,"传说技能");
            _loc20_ = _loc3_.getXingHuiChuangShuoParser();
            if(Boolean(_loc20_.isUsedBianShen()) || Boolean(_loc20_.isUseSkillThisTurn))
            {
               return;
            }
            if(!_loc20_.isUseSkillThisTurn)
            {
               _loc20_.isUseSkillThisTurn = true;
               this.updateChuanShuoBtnByUseSkillState();
            }
            _loc21_ = Boolean(_loc20_.isBianShening());
            _loc22_ = int(_loc19_[_loc21_ ? 1 : 0]);
            _loc23_ = this._pmService.customData.pmSkillMap.getSkill(_loc22_);
            UseBigSkillHandler.instance.handleUse(_loc3_,_loc22_,_loc23_.getSkillType());
         }
         else if(param1.target.name == "btnXingHuiQiPan")
         {
            _loc24_ = int(XHCheckerBoardSkillParse.getCheckerBoardBigSkillId(_loc3_));
            if(_loc24_ == -1)
            {
               return;
            }
            _loc25_ = this._pmService.customData.pmSkillMap.getSkill(_loc24_);
            UseBigSkillHandler.instance.handleUse(_loc3_,_loc24_,_loc25_.getSkillType());
         }
         else if(param1.target.name == "mctipslayer")
         {
            _loc26_ = int(_loc3_.curXinghuiSoulNum);
            _loc27_ = XinghuiPetHelper.getXinghuiPetBigSkill(_loc3_);
            if((Boolean(_loc27_)) && _loc26_ >= _loc27_.costSoulNum)
            {
               UseBigSkillHandler.instance.handleUse(_loc3_,_loc27_.skillId,_loc27_.getSkillType());
            }
         }
      }
      
      override protected function care() : Boolean
      {
         var _loc1_:PetBriefInfo = getOperatingPetInfo() as PetBriefInfo;
         return _pmService.getOperationPM(_loc1_.raceId).pmData.isXinghuiPM();
      }
      
      protected function updateXingHuiTongLingSkill(param1:PetBriefInfo, param2:MovieClip) : void
      {
         if(!this._summonPanelHandle)
         {
            this._summonPanelHandle = new XinghuiTongLingSummonPanelHandle();
         }
         this._summonPanelHandle.refresh(param1,param2);
      }
      
      private function updateAnnualFee22BtnByUseSkillState() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:MovieClip = null;
         var _loc4_:SimpleButton = null;
         var _loc5_:Boolean = false;
         var _loc1_:MovieClip = this._mcChangeView.getChildByName("mcXingHuiExtSkill") as MovieClip;
         if(_loc1_)
         {
            _loc2_ = _loc1_.getChildByName("mcXHSubExtSkill") as MovieClip;
            _loc3_ = _loc2_ == null ? null : _loc2_["mcAnnualFee22"];
            if(_loc3_ != null)
            {
               _loc4_ = _loc3_["btnAnnualFee22"];
               if(_loc4_ != null)
               {
                  _loc5_ = Boolean(this.getOperatingPetInfo().getXingHuiAnnualFee22SkillParser().isUseAnnualFee22);
                  _loc4_.enabled = !_loc5_;
                  _loc4_.mouseEnabled = !_loc5_;
               }
            }
         }
      }
      
      protected function updateXingHuiAnnualFee22Skill(param1:MovieClip, param2:PMData, param3:PetBriefInfo) : void
      {
         var _loc9_:PMSkill = null;
         var _loc10_:String = null;
         if(param1 == null)
         {
            return;
         }
         param3 = getOperatingPetInfo() as PetBriefInfo;
         var _loc4_:Boolean = Boolean(XinghuiPetType.isANNUAL_FEE_22(param2.getXinghuiType()));
         param1.visible = _loc4_;
         if(!_loc4_)
         {
            DisplayUtil.stopAndRemove(param1);
            return;
         }
         var _loc5_:XingHuiAnnualFee22SkillParser = param3.getXingHuiAnnualFee22SkillParser();
         var _loc6_:Array = XingHuiPetHelperUtil.getSkiilIdsByRaceIdAndSkillName(param3.raceId,"第八识技能");
         var _loc7_:int = int(_loc6_[0]);
         var _loc8_:int = _loc5_.isUseAnnualFee22 ? 2 : 1;
         param1.gotoAndStop(_loc8_);
         this.updateAnnualFee22BtnByUseSkillState();
         if(_loc7_ > 0)
         {
            _loc9_ = this._pmService.customData.pmSkillMap.getSkill(_loc7_);
            _loc10_ = _loc9_.newCnName + " 威力：" + getSkillPowerDesc(_loc9_.power);
            TipsManager.getInstance().replaceComplexTips(param1,_loc10_,_loc9_.clientDesc,100,-100,9);
         }
         else
         {
            TipsManager.getInstance().replaceTips(param1,"已经使用过第八识技能");
         }
      }
      
      protected function updateXingHuiCheckerBoardSkill(param1:MovieClip, param2:PMData, param3:PetBriefInfo) : void
      {
         var _loc14_:Array = null;
         var _loc15_:int = 0;
         var _loc16_:String = null;
         var _loc17_:String = null;
         if(param1 == null)
         {
            return;
         }
         param1.visible = false;
         param3 = getOperatingPetInfo() as PetBriefInfo;
         var _loc4_:Boolean = Boolean(XinghuiPetType.isCheckerBoard(param2.getXinghuiType()));
         if(!_loc4_)
         {
            DisplayUtil.stopAndRemove(param1);
            return;
         }
         var _loc5_:int = int(XHCheckerBoardSkillParse.getCheckerBoardBigSkillId(param3));
         if(_loc5_ == -1)
         {
            param1.visible = false;
            return;
         }
         var _loc6_:Object = XinghuiPetType.getCheckerBoardByRaceId(param3.raceId);
         var _loc7_:int = _loc6_ ? int(_loc6_.exSkillFrame) : 1;
         param1.visible = true;
         param1.gotoAndStop(_loc7_);
         var _loc8_:MovieClip = param1.getChildByName("mcQiPanBox") as MovieClip;
         _loc8_.gotoAndStop(XHCheckerBoardSkillParse.getCheckerBoardSkillData(param3.raceId).findBigSkillPos(_loc5_) + 1);
         var _loc9_:SimpleButton = _loc8_.btnXingHuiQiPan;
         var _loc10_:* = false;
         var _loc11_:int = -1;
         if(_loc9_ != null)
         {
            _loc14_ = param3.status.split(",");
            _loc15_ = 0;
            while(_loc15_ < _loc14_.length)
            {
               _loc16_ = _loc14_[_loc15_];
               _loc17_ = _loc16_.split("_")[0];
               if(_loc17_ == "chessCD")
               {
                  _loc11_ = int(_loc16_.split("_")[1]);
               }
               _loc15_++;
            }
            _loc10_ = _loc11_ <= 0;
            _loc9_.enabled = _loc10_;
            _loc9_.mouseEnabled = _loc10_;
         }
         var _loc12_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(_loc5_);
         var _loc13_:String = _loc12_.newCnName + " 威力：" + getSkillPowerDesc(_loc12_.power);
         if(_loc10_)
         {
            TipsManager.getInstance().replaceComplexTips(_loc8_,_loc13_,_loc12_.clientDesc,100,-100,9);
         }
         else
         {
            TipsManager.getInstance().replaceTips(_loc8_,_loc11_ + "回合后方可使用");
         }
      }
   }
}

