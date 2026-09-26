package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.data.XHLunhuiShiyueSkillParse;
   import mmo.interfaces.pet.data.XHTongLingSkillParse;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.XinghuiPetHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3201")]
   public class XinghuiExtraSkillPanel extends MovieClip
   {
      
      public var mc:MovieClip;
      
      public var mcContainer:MovieClip;
      
      public var mcext:MovieClip;
      
      public var mcpassiveskill:MovieClip;
      
      public var mcqiyuanpassiveskill:MovieClip;
      
      public var mcshenpassiveskill:MovieClip;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _pbi:PetBriefInfo = null;
      
      private var _passiveSkillList:Array = [];
      
      private var _xinghuiType:int;
      
      private var _zhanYiExtralSkill:XingHuiZhanYiExtralSkill;
      
      private var _checkerBoardSkill:XingHuiCheckerBoardSkill;
      
      public function XinghuiExtraSkillPanel()
      {
         super();
      }
      
      public function setSkill(param1:PetBriefInfo, param2:Array) : void
      {
         this._pbi = param1;
         this._passiveSkillList = param2;
         this._xinghuiType = this._pmSvr.getOperationPM(this._pbi.raceId).pmData.getXinghuiType();
         this.update();
      }
      
      private function update() : void
      {
         var _loc1_:PMSkill = null;
         var _loc2_:MovieClip = null;
         var _loc3_:PMData = null;
         var _loc4_:MovieClip = null;
         var _loc5_:String = null;
         var _loc6_:MovieClip = null;
         var _loc7_:int = 0;
         var _loc8_:MovieClip = null;
         var _loc9_:SkillInfo = null;
         var _loc10_:* = false;
         var _loc11_:MovieClip = null;
         var _loc12_:SkillInfo = null;
         var _loc13_:int = 0;
         var _loc14_:* = undefined;
         var _loc15_:MovieClip = null;
         var _loc16_:SkillInfo = null;
         var _loc17_:MovieClip = null;
         var _loc18_:MovieClip = null;
         var _loc19_:PMSkill = null;
         var _loc20_:MovieClip = null;
         if(XinghuiPetType.isSpPet(this._xinghuiType))
         {
            if(this.currentFrame != this._xinghuiType)
            {
               this.gotoAndStop(this._xinghuiType);
            }
            _loc4_ = this.getChildAt(0) as MovieClip;
            _loc5_ = "";
            if(XinghuiPetType.isWanWuJuYuan(this._xinghuiType))
            {
               _loc7_ = int(XinghuiPetType.getWanWuJuYuanSPIndex(this._pbi.raceId));
               _loc4_.gotoAndStop(_loc7_ + 1);
               _loc5_ = "万物聚元技";
            }
            else if(this._xinghuiType == XinghuiPetType.SP_AND_CHAOWEI)
            {
               _loc5_ = "超维力量";
            }
            else if(this._xinghuiType == XinghuiPetType.SP_SHENYUANHUIXIANG)
            {
               _loc4_ = this.getChildByName("mcContainer") as MovieClip;
            }
            _loc6_ = _loc4_.getChildByName("mcsp") as MovieClip;
            this.refreshXingHuiSp(_loc6_);
            if(this._xinghuiType == XinghuiPetType.SP_SHENYUANHUIXIANG)
            {
               _loc2_ = this.getChildByName("mcpassiveskill") as MovieClip;
               this.huiXiangHandle(_loc2_);
            }
            else if(XinghuiPetType.isDoubleGod(this._xinghuiType))
            {
               this.refreshDoubleGod(_loc4_.getChildByName("mcpassiveskill") as MovieClip,this._passiveSkillList[this._passiveSkillList.length - 1].id);
            }
            else if(XinghuiPetType.getIsWuwangguiweiWangzhePetByRaceid(this._pbi.raceId))
            {
               _loc8_ = this.getChildByName("mc") as MovieClip;
               this.wangzheHandle(_loc8_);
            }
            else
            {
               _loc2_ = _loc4_.getChildByName("mcpassiveskill") as MovieClip;
               if(_loc2_ != null)
               {
                  _loc9_ = this.getSkillInfoByRaceId(this._pbi.raceId,_loc5_);
                  _loc10_ = _loc9_ != null;
                  _loc2_.gotoAndStop(_loc10_ ? 2 : 1);
                  if(_loc10_)
                  {
                     _loc1_ = this._pmSvr.customData.pmSkillMap.getSkill(_loc9_.id);
                     TipsManager.getInstance().replaceComplexTips(_loc2_,this.getSkillTipsTitle(_loc1_),this.getSkillTipsContent(_loc1_),0,9,-50);
                  }
               }
            }
         }
         else if(this._xinghuiType == XinghuiPetType.WANGZHE || this._xinghuiType == XinghuiPetType.ZHENGNI_JIBAN)
         {
            this.gotoAndStop(this._xinghuiType);
            _loc11_ = this.getChildByName("mc") as MovieClip;
            this.wangzheHandle(_loc11_);
         }
         else if(this._xinghuiType == XinghuiPetType.DOUBLEGOD)
         {
            this.gotoAndStop(this._xinghuiType);
            this.refreshDoubleGod(this.getChildByName("mcpassiveskill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(Boolean(XinghuiPetType.isQiYuan(this._xinghuiType)) && this._xinghuiType != XinghuiPetType.JIBANQIYUAN && this._xinghuiType != XinghuiPetType.SHENQI_QIYUAN || this._xinghuiType == XinghuiPetType.CHUAN_SHUO_QI_YUAN || this._xinghuiType == XinghuiPetType.SHENQI || this._xinghuiType == XinghuiPetType.LINGHUN || this._xinghuiType == XinghuiPetType.CHUAN_SHUO_LING_HUN || this._xinghuiType == XinghuiPetType.WAN_WU_JU_YUAN || this._xinghuiType == XinghuiPetType.CHAOWEI || this._xinghuiType == XinghuiPetType.WANGZHE_REAL || this._xinghuiType == XinghuiPetType.CHAOWEI_AND_CHUANSHUO || this._xinghuiType == XinghuiPetType.SHEN_CHAOWEI || this._xinghuiType == XinghuiPetType.SHEN_LINGHUN)
         {
            this.gotoAndStop(this._xinghuiType);
            _loc2_ = this.getChildByName("mcpassiveskill") as MovieClip;
            _loc2_.gotoAndStop(2);
            if(this._xinghuiType == XinghuiPetType.SHENQI)
            {
               if(Boolean(_loc2_.getChildByName("type")) && XinghuiPetType.getShenQiPetIndex(this._pbi.raceId) >= 0)
               {
                  _loc2_["type"].gotoAndStop(XinghuiPetType.getShenQiPetIndex(this._pbi.raceId) + 1);
               }
            }
            _loc1_ = this._pmSvr.customData.pmSkillMap.getSkill(this._passiveSkillList[0].id);
            TipsManager.getInstance().replaceComplexTips(_loc2_,this.getSkillTipsTitle(_loc1_),this.getSkillTipsContent(_loc1_),0,9,-50);
         }
         else if(this._xinghuiType == XinghuiPetType.JIBANQIYUAN)
         {
            this.gotoAndStop(this._xinghuiType);
            _loc12_ = this.checkQiyuanPassiveSkill();
            _loc2_ = this.getChildByName("mcpassiveskill") as MovieClip;
            _loc2_.gotoAndStop(this._passiveSkillList.length + 1);
            _loc13_ = 0;
            while(_loc13_ < this._passiveSkillList.length)
            {
               _loc15_ = _loc2_.getChildByName("mc_" + _loc13_) as MovieClip;
               _loc15_.mouseChildren = false;
               _loc15_.gotoAndStop(2);
               _loc1_ = this._pmSvr.customData.pmSkillMap.getSkill(this._passiveSkillList[_loc13_].id);
               TipsManager.getInstance().replaceComplexTips(_loc15_,this.getSkillTipsTitle(_loc1_),this.getSkillTipsContent(_loc1_),0,9,-50);
               _loc13_++;
            }
            _loc14_ = this.getChildByName("mcqiyuanpassiveskill") as MovieClip;
            _loc14_.gotoAndStop(2);
            _loc1_ = this._pmSvr.customData.pmSkillMap.getSkill(_loc12_.id);
            TipsManager.getInstance().replaceComplexTips(_loc14_,this.getSkillTipsTitle(_loc1_),this.getSkillTipsContent(_loc1_),0,9,-50);
         }
         else if(this._xinghuiType == XinghuiPetType.LIUWEIYITI)
         {
            this.gotoAndStop(this._xinghuiType);
            _loc2_ = this.getChildByName("mcpassiveskill") as MovieClip;
            _loc2_.gotoAndStop(XinghuiPetType.getLiuweiyitiType(this._pbi.raceId) + 1);
            _loc2_.mc.gotoAndStop(XinghuiPetType.getLiuweiyitiDetailType(this._pbi.raceId) + 1);
            _loc1_ = this._pmSvr.customData.pmSkillMap.getSkill(this._passiveSkillList[0].id);
            TipsManager.getInstance().replaceComplexTips(_loc2_,this.getSkillTipsTitle(_loc1_),this.getSkillTipsContent(_loc1_),0,9,-50);
         }
         else if(this._xinghuiType == XinghuiPetType.SHENYUANHUIXIANG)
         {
            this.gotoAndStop(this._xinghuiType);
            _loc2_ = this.getChildByName("mcpassiveskill") as MovieClip;
            this.huiXiangHandle(_loc2_);
         }
         else if(this._xinghuiType == XinghuiPetType.JUEXING)
         {
            this.gotoAndStop(this._xinghuiType);
            _loc16_ = this._passiveSkillList[0];
            _loc17_ = this.getChildByName("mcext") as MovieClip;
            if(!this._pbi.hasBird)
            {
               _loc17_.gotoAndStop(1);
            }
            else
            {
               _loc17_.gotoAndStop(2);
               _loc17_.btnext.addEventListener(MouseEvent.CLICK,this.onUseSkill);
            }
            _loc1_ = this._pmSvr.customData.pmSkillMap.getSkill(_loc16_.id);
            TipsManager.getInstance().replaceComplexTips(_loc17_,this.getSkillTipsTitle(_loc1_),this.getSkillTipsContent(_loc1_),0,9,-50);
         }
         else if(this._xinghuiType == XinghuiPetType.SHENQI_QIYUAN)
         {
            this.gotoAndStop(this._xinghuiType);
            this.refreshQiyuan(this.getChildByName("mcContainer") as MovieClip);
            this.refreshShenqi(this.getChildByName("mcContainer") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(this._xinghuiType == XinghuiPetType.SHEN_LI)
         {
            this.gotoAndStop(this._xinghuiType);
            this.addCommondIcon(this.getChildByName("mcpassiveskill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(this._xinghuiType == XinghuiPetType.ZHAN_YI)
         {
            this.gotoAndStop(this._xinghuiType);
            if(!this._zhanYiExtralSkill)
            {
               this._zhanYiExtralSkill = new XingHuiZhanYiExtralSkill();
            }
            this._zhanYiExtralSkill.setData(this._pbi,this.getChildByName("mcpassiveskill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(this._xinghuiType == XinghuiPetType.DOUBLEGOD_AND_SHEN_LI)
         {
            this.gotoAndStop(this._xinghuiType);
            _loc18_ = this.getChildAt(0) as MovieClip;
            this.refreshDoubleGod(_loc18_.getChildByName("mcpassiveskill") as MovieClip,this._passiveSkillList[this._passiveSkillList.length - 1].id);
            this.addCommondIcon(_loc18_.getChildByName("mcshenlipassiveskill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(XinghuiPetType.isShiflePro(this._xinghuiType))
         {
            this.gotoAndStop(this._xinghuiType);
            this.addCommondIcon(this.getChildByName("mcpassiveskill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(XinghuiPetType.isShenLingPassive(this._xinghuiType))
         {
            this.gotoAndStop(this._xinghuiType);
            this.addCommondIcon(this.getChildByName("mcpassiveskill") as MovieClip,this._passiveSkillList[0].id,XinghuiPetType.getShenLingExtraSkillFrame(this._pbi.raceId));
         }
         else if(XinghuiPetType.isTongLing(this._xinghuiType))
         {
            this.gotoAndStop(this._xinghuiType);
            this.tonglingHandle(this.getChildByName("mcpassiveskill") as MovieClip);
         }
         else if(XinghuiPetType.isANNUAL_FEE_22(this._xinghuiType))
         {
            this.gotoAndStop(this._xinghuiType);
            this.annualFeeHandle(this.getChildByName("mcpassiveskill") as MovieClip);
         }
         else if(XinghuiPetType.isZhanJiType(this._xinghuiType))
         {
            this.gotoAndStop(this._xinghuiType);
            this.addCommondIcon(this.getChildByName("mcpassiveskill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(XinghuiPetType.isFaHuanType(this._xinghuiType))
         {
            this.gotoAndStop(this._xinghuiType);
            this.addCommondIcon(this.getChildByName("mcpassiveskill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(this._xinghuiType == XinghuiPetType.SHEN_WANGZHE_REAL)
         {
            this.gotoAndStop(this._xinghuiType);
            _loc19_ = this._pmSvr.customData.pmSkillMap.getSkill(this._passiveSkillList[0].id);
            if(_loc19_.getSkillType() == PMSkillTypes.SHEN_WANGZHE_REAL_PASSIVE)
            {
               this.addCommondIcon(this.getChildByName("mcpassiveskill") as MovieClip,this._passiveSkillList[1].id,2);
               this.addCommondIcon(this.getChildByName("mcshenpassiveskill") as MovieClip,this._passiveSkillList[0].id);
            }
            else
            {
               this.addCommondIcon(this.getChildByName("mcpassiveskill") as MovieClip,this._passiveSkillList[0].id,2);
               this.addCommondIcon(this.getChildByName("mcshenpassiveskill") as MovieClip,this._passiveSkillList[1].id);
            }
         }
         else if(this._xinghuiType == XinghuiPetType.LUNHUI_SHIYUE)
         {
            this.gotoAndStop(this._xinghuiType);
            _loc20_ = this.getChildByName("mcpassiveskill") as MovieClip;
            _loc20_.gotoAndStop(XinghuiPetType.getLunhuiQIyueByRaceId(this._pbi.raceId).exSkillFrame);
            _loc13_ = 0;
            while(_loc13_ < 4)
            {
               _loc15_ = _loc20_.getChildByName("mc_" + _loc13_) as MovieClip;
               if(_loc13_ < this._passiveSkillList.length)
               {
                  _loc15_.visible = true;
                  _loc15_.gotoAndStop(XHLunhuiShiyueSkillParse.getPassiveSkillTypeById(this._pbi.raceId,this._passiveSkillList[_loc13_].id) + 1);
                  _loc1_ = this._pmSvr.customData.pmSkillMap.getSkill(this._passiveSkillList[_loc13_].id);
                  TipsManager.getInstance().replaceComplexTips(_loc15_,this.getSkillTipsTitle(_loc1_),this.getSkillTipsContent(_loc1_),0,9,-50);
               }
               else
               {
                  _loc15_.visible = false;
                  _loc15_.stop();
               }
               _loc13_++;
            }
         }
      }
      
      private function wangzheHandle(param1:MovieClip) : void
      {
         var _loc3_:PMSkill = null;
         var _loc4_:MovieClip = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc2_:* = param1;
         _loc2_.gotoAndStop(XinghuiPetType.getWangZheSkillFrameInFight(this._pbi.raceId));
         if(XinghuiPetType.getIsSpecialWangzhePetByRaceid(this._pbi.raceId))
         {
            _loc5_ = 0;
            while(_loc5_ < 4)
            {
               _loc4_ = _loc2_.getChildByName("mcpassiveskill_" + _loc5_) as MovieClip;
               _loc4_.mouseChildren = false;
               _loc4_.visible = true;
               if(_loc5_ < this._passiveSkillList.length)
               {
                  _loc4_.gotoAndStop(2);
                  _loc3_ = this._pmSvr.customData.pmSkillMap.getSkill(this._passiveSkillList[_loc5_].id);
                  TipsManager.getInstance().replaceComplexTips(_loc4_,this.getSkillTipsTitle(_loc3_),this.getSkillTipsContent(_loc3_),0,9,-50);
               }
               else
               {
                  _loc4_.gotoAndStop(1);
                  TipsManager.getInstance().replaceTips(_loc4_,"未龙鳞归位");
               }
               _loc5_++;
            }
         }
         else if(XinghuiPetType.getIsWuwangguiweiWangzhePetByRaceid(this._pbi.raceId))
         {
            _loc4_ = _loc2_.getChildByName("mcpassiveskill") as MovieClip;
            if(this._passiveSkillList.length > 0 && this._passiveSkillList[this._passiveSkillList.length - 1] != null)
            {
               _loc4_.visible = true;
               _loc3_ = this._pmSvr.customData.pmSkillMap.getSkill(this._passiveSkillList[this._passiveSkillList.length - 1].id);
               TipsManager.getInstance().replaceComplexTips(param1,this.getSkillTipsTitle(_loc3_),this.getSkillTipsContent(_loc3_),0,9,-50);
            }
            else
            {
               _loc4_.visible = false;
            }
         }
         else if(this._xinghuiType == XinghuiPetType.ZHENGNI_JIBAN)
         {
            this.addCommondIcon(_loc2_.getChildByName("mcpassiveskill") as MovieClip,this._passiveSkillList[0].id);
         }
         else
         {
            _loc4_ = _loc2_.getChildByName("mcpassiveskill") as MovieClip;
            _loc4_.gotoAndStop(this._passiveSkillList.length);
            _loc6_ = 0;
            while(_loc6_ < this._passiveSkillList.length)
            {
               param1 = _loc4_.getChildByName("mc_" + _loc6_) as MovieClip;
               if(param1 != null)
               {
                  param1.mouseChildren = false;
                  param1.gotoAndStop(2);
                  _loc3_ = this._pmSvr.customData.pmSkillMap.getSkill(this._passiveSkillList[_loc6_].id);
                  TipsManager.getInstance().replaceComplexTips(param1,this.getSkillTipsTitle(_loc3_),this.getSkillTipsContent(_loc3_),0,9,-50);
               }
               _loc6_++;
            }
         }
      }
      
      private function huiXiangHandle(param1:MovieClip) : void
      {
         var _loc5_:MovieClip = null;
         var _loc6_:PMSkill = null;
         var _loc2_:Array = XinghuiPetType.getShenYuanHuiXiangComboSkillIds(this._pbi.raceId);
         var _loc3_:int = XinghuiPetType.getShenYuanHuiXiangIndex(this._pbi.raceId) + 1;
         param1.gotoAndStop(_loc3_);
         var _loc4_:int = 0;
         while(_loc4_ < 3)
         {
            _loc5_ = param1.getChildByName("mccombo_" + _loc4_) as MovieClip;
            _loc5_.visible = _loc2_[_loc4_] != null;
            if(_loc5_.visible)
            {
               _loc6_ = this._pmSvr.customData.pmSkillMap.getSkill(_loc2_[_loc4_]);
               TipsManager.getInstance().replaceComplexTips(_loc5_,_loc6_.newCnName,_loc6_.clientDesc + "\n触发方式：" + XinghuiPetType.getShenYuanHuiXiangActiveDecs(_loc6_.skillId));
            }
            _loc4_++;
         }
      }
      
      private function annualFeeHandle(param1:MovieClip) : void
      {
         var _loc4_:MovieClip = null;
         var _loc2_:Object = XinghuiPetType.getAnnualFee22Object(this._pbi.raceId);
         if(!_loc2_)
         {
            param1.gotoAndStop(1);
            param1.visible = false;
            return;
         }
         param1.gotoAndStop(_loc2_.extraSkillFrame);
         param1.visible = true;
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.extraSkillMaxNum)
         {
            _loc4_ = param1.getChildByName("mcSkill_" + _loc3_) as MovieClip;
            if(_loc3_ < this._passiveSkillList.length)
            {
               this.addCommondIcon(_loc4_,this._passiveSkillList[_loc3_].id,2);
            }
            else
            {
               _loc4_.gotoAndStop(1);
               TipsManager.getInstance().addTips(_loc4_,"敬请期待");
            }
            _loc3_++;
         }
      }
      
      private function tonglingHandle(param1:MovieClip) : void
      {
         var _loc5_:MovieClip = null;
         var _loc6_:Boolean = false;
         var _loc7_:int = 0;
         var _loc2_:Object = XinghuiPetType.getTongLingObject(this._pbi.raceId);
         if(!_loc2_)
         {
            param1.gotoAndStop(1);
            param1.visible = false;
            return;
         }
         param1.gotoAndStop(_loc2_.extraSkillFrame);
         param1.visible = true;
         var _loc3_:XHTongLingSkillParse = XHTongLingSkillParse.getTongLingSkillData(this._pbi.raceId);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_.passiveSkillAry.length)
         {
            _loc5_ = param1.getChildByName("mcSkill_" + _loc4_) as MovieClip;
            _loc6_ = false;
            _loc7_ = 0;
            while(_loc7_ < this._passiveSkillList.length)
            {
               if(_loc3_.passiveSkillAry[_loc4_] == this._passiveSkillList[_loc7_].id)
               {
                  _loc6_ = true;
               }
               _loc7_++;
            }
            this.addCommondIcon(_loc5_,_loc3_.passiveSkillAry[_loc4_],_loc6_ ? 2 : 1);
            _loc4_++;
         }
      }
      
      public function espHandle(param1:PetBriefInfo) : void
      {
         this._pbi = param1;
         this._xinghuiType = this._pmSvr.getOperationPM(this._pbi.raceId).pmData.getXinghuiType();
         this.gotoAndStop(this._xinghuiType);
         if(XinghuiPetType.isCheckerBoard(this._xinghuiType))
         {
            if(!this._checkerBoardSkill)
            {
               this._checkerBoardSkill = new XingHuiCheckerBoardSkill();
            }
            this._checkerBoardSkill.setData(param1,this.getChildByName("mcpassiveskill") as MovieClip);
            return;
         }
      }
      
      private function refreshDoubleGod(param1:MovieClip, param2:int) : void
      {
         param1.gotoAndStop(XinghuiPetType.getDoubleGodType(this._pbi.raceId) + 1);
         param1 = param1.getChildByName("mc") as MovieClip;
         param1.gotoAndStop(2);
         var _loc3_:PMSkill = this._pmSvr.customData.pmSkillMap.getSkill(param2);
         TipsManager.getInstance().replaceComplexTips(param1,this.getSkillTipsTitle(_loc3_),this.getSkillTipsContent(_loc3_),0,9,-50);
      }
      
      private function addCommondIcon(param1:MovieClip, param2:int, param3:int = 1) : void
      {
         param1.gotoAndStop(param3);
         var _loc4_:PMSkill = this._pmSvr.customData.pmSkillMap.getSkill(param2);
         TipsManager.getInstance().replaceComplexTips(param1,this.getSkillTipsTitle(_loc4_),this.getSkillTipsContent(_loc4_),0,9,-50);
      }
      
      private function refreshQiyuan(param1:MovieClip) : void
      {
         var _loc2_:PMSkill = null;
         var _loc3_:SkillInfo = this.checkQiyuanPassiveSkill();
         if(!_loc3_)
         {
            return;
         }
         var _loc4_:MovieClip = param1.getChildByName("mcqiyuanpassiveskill") as MovieClip;
         _loc4_.gotoAndStop(2);
         _loc2_ = this._pmSvr.customData.pmSkillMap.getSkill(_loc3_.id);
         TipsManager.getInstance().replaceComplexTips(_loc4_,this.getSkillTipsTitle(_loc2_),this.getSkillTipsContent(_loc2_),0,9,-50);
      }
      
      private function refreshShenqi(param1:MovieClip, param2:int) : void
      {
         var _loc3_:MovieClip = param1.getChildByName("mcshenqipassiveskill") as MovieClip;
         if(Boolean(_loc3_.getChildByName("type")) && XinghuiPetType.getShenQiPetIndex(this._pbi.raceId) >= 0)
         {
            _loc3_["type"].gotoAndStop(XinghuiPetType.getShenQiPetIndex(this._pbi.raceId) + 1);
         }
         var _loc4_:PMSkill = this._pmSvr.customData.pmSkillMap.getSkill(param2);
         TipsManager.getInstance().replaceComplexTips(_loc3_,this.getSkillTipsTitle(_loc4_),this.getSkillTipsContent(_loc4_),0,9,-50);
      }
      
      private function getSkillInfoBySkillIds(param1:Array) : SkillInfo
      {
         var _loc4_:SkillInfo = null;
         var _loc5_:int = 0;
         var _loc2_:SkillInfo = null;
         var _loc3_:int = 0;
         while(_loc3_ < this._passiveSkillList.length)
         {
            _loc4_ = this._passiveSkillList[_loc3_];
            if(_loc4_ != null)
            {
               _loc5_ = 0;
               while(_loc5_ < param1.length)
               {
                  if(_loc4_.id + "" == param1[_loc5_] + "")
                  {
                     _loc2_ = _loc4_;
                     break;
                  }
                  _loc5_++;
               }
               if(_loc2_ != null)
               {
                  break;
               }
            }
            _loc3_++;
         }
         return _loc2_;
      }
      
      protected function refreshXingHuiSp(param1:MovieClip) : void
      {
         var _loc6_:String = null;
         var _loc7_:PMSkill = null;
         if(param1 == null)
         {
            return;
         }
         var _loc2_:PMData = this._pmSvr.customData.pmDataMap.getPM(this._pbi.raceId);
         var _loc3_:String = _loc2_.getXinghuiExtraConfig();
         var _loc4_:String = this.getXingHuiExtraSkillConig(_loc3_,"sp技能");
         var _loc5_:SkillInfo = this.getSkillInfoBySkillIds(XinghuiPetType.getSpExtraSkills(_loc4_));
         if(_loc5_ == null)
         {
            param1.gotoAndStop(1);
            _loc6_ = _loc4_;
            if(XinghuiPetType.isEffUnlock(_loc6_))
            {
               TipsManager.getInstance().replaceTips(param1,"亚比战斗力达到" + XinghuiPetType.getUnlockEff(_loc6_) + "解锁");
            }
            else
            {
               TipsManager.getInstance().replaceTips(param1,"星辉被动达到5级解锁");
            }
         }
         else
         {
            param1.gotoAndStop(2);
            _loc7_ = this._pmSvr.customData.pmSkillMap.getSkill(_loc5_.id);
            TipsManager.getInstance().replaceComplexTips(param1,this.getSkillTipsTitle(_loc7_),this.getSkillTipsContent(_loc7_),0,9,-50);
         }
      }
      
      private function getSkillInfoByRaceId(param1:int, param2:String) : SkillInfo
      {
         var _loc3_:PMData = this._pmSvr.customData.pmDataMap.getPM(this._pbi.raceId);
         var _loc4_:String = _loc3_.getXinghuiExtraConfig();
         var _loc5_:String = this.getXingHuiExtraSkillConig(_loc4_,param2);
         var _loc6_:Array = this.getSkillIdsByExtralConfig(_loc5_,param2);
         return this.getSkillInfoBySkillIds(_loc6_);
      }
      
      private function getSkillIdsByExtralConfig(param1:String, param2:String) : Array
      {
         return XinghuiPetHelper.getSkillIdsByExtralConfig(param1,param2);
      }
      
      private function getXingHuiExtraSkillConig(param1:String, param2:String) : String
      {
         return XinghuiPetHelper.getXingHuiExtraSkillConig(param1,param2);
      }
      
      private function onUseSkill(param1:MouseEvent) : void
      {
         var _loc2_:PMSkill = null;
         if(this._pbi.hasBird)
         {
            this._pbi.setBirdUsed();
            _loc2_ = this._pmSvr.customData.pmSkillMap.getSkill(this._passiveSkillList[0].id);
            UseBigSkillHandler.instance.handleUse(this._pbi,_loc2_.skillId,_loc2_.getSkillType());
         }
      }
      
      private function checkQiyuanPassiveSkill() : SkillInfo
      {
         var _loc2_:int = 0;
         var _loc3_:Array = null;
         var _loc1_:int = 0;
         while(_loc1_ < this._passiveSkillList.length)
         {
            _loc2_ = int(this._pmSvr.customData.pmSkillMap.getSkill(this._passiveSkillList[_loc1_].id).getSkillType());
            if(_loc2_ == PMSkillTypes.XINGHUI_QIYUAN_PASSIVE_SKILL)
            {
               _loc3_ = this._passiveSkillList.splice(_loc1_,1);
               return _loc3_[0];
            }
            _loc1_++;
         }
         return null;
      }
      
      private function getSkillTipsTitle(param1:PMSkill) : String
      {
         return param1.newCnName + " Lv." + param1.getSkillLevel() + "  " + this.getSkillAttackTypeDesc(param1.attackType);
      }
      
      private function getSkillTipsContent(param1:PMSkill) : String
      {
         return "威力:" + param1.power + "\n" + param1.clientDesc;
      }
      
      private function getSkillAttackTypeDesc(param1:int) : String
      {
         switch(param1)
         {
            case 0:
               return "(普通攻击)";
            case 1:
               return "(特殊攻击)";
            case 2:
               return "(属性攻击)";
            default:
               return "";
         }
      }
   }
}

