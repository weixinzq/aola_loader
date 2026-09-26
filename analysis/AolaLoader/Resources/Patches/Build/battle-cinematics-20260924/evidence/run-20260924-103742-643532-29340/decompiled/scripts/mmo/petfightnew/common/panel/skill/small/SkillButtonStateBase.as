package mmo.petfightnew.common.panel.skill.small
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.GQArmorBurstSkillParse;
   import mmo.interfaces.pet.data.GQDengShenChangJieSkillParse;
   import mmo.interfaces.pet.data.GQJiangShenSkillParse;
   import mmo.interfaces.pet.data.GQLianSuoSkillParse;
   import mmo.interfaces.pet.data.GQShenXuSkillParse;
   import mmo.interfaces.pet.data.GQYiRenWujinMingtuSkillParse;
   import mmo.interfaces.pet.data.GQZhanYiSkillParse;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.data.XHCheckerBoardSkillParse;
   import mmo.interfaces.pet.data.XHZhanJiSkillParse;
   import mmo.interfaces.pet.data.XingHuiZhanYiSkillParser;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petfightnew.common.data.PetState;
   import mmo.petfightnew.common.data.PetType;
   import mmo.petfightnew.common.handler.attributeicon.FightAttributeIconCacheKey;
   import mmo.petfightnew.common.handler.attributeicon.FightAttributeIconHandler;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.petfight.common.data.SkillType;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   public class SkillButtonStateBase extends Sprite implements IDispose
   {
      
      private var _pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _mcBack:MovieClip;
      
      private var _mcDes:MovieClip;
      
      private var _mcAttribute:Sprite;
      
      private var _attributeIcon:FightAttributeIconHandler = null;
      
      private var _petInfo:PetBriefInfo;
      
      private var _skillInfo:SkillInfo;
      
      private var _yirenWujinMingtuSkillParser:GQYiRenWujinMingtuSkillParse = null;
      
      private var _shenxuSkillParse:GQShenXuSkillParse = null;
      
      private var _dengShenChangJieSkillParse:GQDengShenChangJieSkillParse;
      
      private var _jiangShenSkillParser:GQJiangShenSkillParse = null;
      
      public function SkillButtonStateBase()
      {
         super();
         this.mouseChildren = this.mouseEnabled = false;
         this.tabChildren = this.tabEnabled = false;
         this.init();
      }
      
      public function dispose() : void
      {
         DisplayUtil.clearFilters(this._mcBack);
         this._attributeIcon && this._attributeIcon.dispose();
         this._attributeIcon = null;
         this._pmService = null;
         this._mcBack = null;
         this._mcDes = null;
         this._mcAttribute = null;
         this._petInfo = null;
         this._skillInfo = null;
      }
      
      protected function init() : void
      {
         this._mcBack = this.getChildByName("back") as MovieClip;
         this._mcDes = this.getChildByName("mcDes") as MovieClip;
         this._mcAttribute = this.getChildByName("mcAtt") as MovieClip;
         this._mcAttribute.mouseChildren = false;
         this._attributeIcon = new FightAttributeIconHandler(this._mcAttribute,FightAttributeIconCacheKey.SMALL);
      }
      
      public function update(param1:SkillInfo, param2:PetBriefInfo) : void
      {
         this._skillInfo = param1;
         this._petInfo = param2;
         this.setButtonState(param1,param2);
      }
      
      private function setButtonState(param1:SkillInfo, param2:PetBriefInfo) : void
      {
         var _loc15_:int = 0;
         var _loc16_:XHZhanJiSkillParse = null;
         var _loc17_:Object = null;
         var _loc18_:int = 0;
         var _loc19_:int = 0;
         var _loc20_:MovieClip = null;
         var _loc21_:int = 0;
         var _loc3_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(param1.id);
         var _loc4_:PMData = this._pmService.getOperationPM(param2.raceId).pmData;
         var _loc5_:int = int(SkillType.getSkillType(param1.id));
         var _loc6_:int = int(_loc3_.getSkillType());
         var _loc7_:int = PetType.getPetType(param2);
         var _loc8_:int = PetState.getPetState(param2);
         this._yirenWujinMingtuSkillParser = GQYiRenWujinMingtuSkillParse.getYiRenWujinMingtuSkillData(param2.raceId);
         this._shenxuSkillParse = GQShenXuSkillParse.getGQShenXuSkillParse(param2.raceId);
         this._dengShenChangJieSkillParse = GQDengShenChangJieSkillParse.getDengShenChangJieSkillParse(param2.raceId);
         this._jiangShenSkillParser = GQJiangShenSkillParse.getGQJiangShenSkillParse(param2.raceId);
         var _loc9_:int = int(PetAssetsMap.getPetFlaId(param2.raceId));
         var _loc10_:Boolean = false;
         var _loc11_:Array = this._pmService.getOperationPM(this._petInfo.raceId).pmData.getGQNewSkill_UnchangeableSkill(true);
         if(_loc11_.indexOf(param1.id) != -1 || Boolean(PMSkillTypes.getIsGQZhuanshuSkill(_loc3_.getSkillType())))
         {
            _loc10_ = true;
         }
         var _loc12_:int = 1;
         var _loc13_:int = 1;
         if(_loc5_ == SkillType.COMPLETED)
         {
            _loc12_ = 5;
            _loc13_ = 1;
         }
         else if(PetType.isLegendPet(_loc7_))
         {
            if(_loc5_ == SkillType.PASSIVE)
            {
               _loc12_ = 6;
               _loc13_ = 4;
            }
            else if(_loc8_ == PetState.CHANGING_VIEW)
            {
               _loc12_ = 8;
               _loc13_ = 1;
            }
            else
            {
               _loc12_ = 7;
               _loc13_ = 3;
            }
         }
         else if(PetType.isDegeneratorPet(_loc7_))
         {
            _loc13_ = 1;
            if(_loc5_ == SkillType.PASSIVE)
            {
               _loc12_ = 10;
            }
            else if(SkillType.getIsDegeneratorSuperSpiritSkill(_loc5_))
            {
               _loc12_ = _loc5_ + 2;
               _loc13_ = 5;
            }
            else if(_loc5_ == SkillType.DEGENERATOR_YU_NOT_BIG_SKILL)
            {
               _loc12_ = 19;
            }
            else
            {
               _loc12_ = 9;
            }
         }
         else if(PetType.isXinghuiPet(_loc7_))
         {
            _loc13_ = 4;
            if(_loc4_.getXinghuiType() == XinghuiPetType.CHECKER_BOARD)
            {
               _loc15_ = int(XHCheckerBoardSkillParse.getPetHasBigType(param2));
               _loc12_ = _loc15_ == -1 ? 34 : 33 + _loc15_;
               _loc13_ = _loc15_ == -1 ? 8 : 7 + _loc15_;
               if(_loc5_ == SkillType.XINGHUI_SUPER_SPIRIT_TEJI)
               {
                  _loc12_ += 3;
                  _loc13_ = 5;
               }
            }
            else if(_loc5_ == SkillType.ZHANYI_ACTIVE)
            {
               _loc12_ = 32;
               _loc13_ = 6;
            }
            else if(_loc5_ == SkillType.XINGHUI_HUNDUN_TEJI)
            {
               _loc12_ = 31;
               _loc13_ = 5;
            }
            else if(_loc5_ == SkillType.PASSIVE)
            {
               _loc12_ = 25;
            }
            else if(SkillType.getIsXinghuiSuperSpiritSkill(_loc5_))
            {
               _loc12_ = _loc5_ + 3;
               _loc13_ = 5;
            }
            else
            {
               _loc12_ = 24;
            }
            if(XinghuiPetType.isZhanJiType(_loc4_.getXinghuiType()))
            {
               _loc16_ = XHZhanJiSkillParse.getSkillData(param2.raceId);
               if(_loc16_.getSkillType(param1.id) == XHZhanJiSkillParse.TYPE_SKILL_Streng)
               {
                  _loc12_ = _loc5_ == SkillType.XINGHUI_SUPER_SPIRIT_TEJI ? 40 : 39;
                  _loc13_ = _loc5_ == SkillType.XINGHUI_SUPER_SPIRIT_TEJI ? _loc13_ : 10;
               }
            }
         }
         else if(PetType.isGQPet(_loc7_))
         {
            if(_loc5_ == SkillType.GQ_ZHANYI_COMMON_SKILL)
            {
               _loc12_ = 44;
               _loc13_ = 14;
            }
            else if(GQPetType.isJiangShen(_loc4_.getGQType()) && this._jiangShenSkillParser && Boolean(this._jiangShenSkillParser.getIsAfterChangeView(param2)))
            {
               if(_loc5_ == SkillType.PASSIVE)
               {
                  _loc12_ = 67;
                  _loc13_ = 5;
               }
               else
               {
                  _loc12_ = 66;
                  if(_loc3_.costSoulNum > 0)
                  {
                     _loc13_ = 13;
                  }
                  else
                  {
                     _loc13_ = 12;
                  }
               }
            }
            else if(SkillType.checkIsGQCommonSpiritSkill(_loc3_.skillId))
            {
               if(Boolean(GQPetType.isArmorBurst(_loc4_.getGQType())) && Boolean(GQArmorBurstSkillParse.getIsAfterChangeView(param2)))
               {
                  _loc12_ = 43;
               }
               else if(_loc5_ == SkillType.GQ_DIJIESHI_SPIRIT_SKILL)
               {
                  _loc12_ = 49;
               }
               else if(_loc10_)
               {
                  _loc12_ = 58;
               }
               else
               {
                  _loc12_ = 42;
               }
               _loc13_ = 13;
            }
            else if(GQPetType.isYiRen(_loc4_.getGQType()) && this._yirenWujinMingtuSkillParser && Boolean(this._yirenWujinMingtuSkillParser.getIsAfterChangeView(param2)))
            {
               if(_loc5_ == SkillType.PASSIVE)
               {
                  _loc12_ = 41;
                  _loc13_ = 11;
               }
               else
               {
                  _loc12_ = 45;
                  _loc13_ = 15;
               }
            }
            else if(Boolean(GQPetType.isShenXu(_loc4_.getGQType())) && Boolean(SkillType.checkIsGQShenXuCommonSkill(param1.id)))
            {
               _loc12_ = 45 + this._shenxuSkillParse.shenxuCommonSkillIds.indexOf(param1.id);
               _loc13_ = 12;
            }
            else if(Boolean(GQPetType.isDengShenChangJie(_loc4_.getGQType())) && Boolean(this._dengShenChangJieSkillParse.getIsAfterChangeView(param2)) && _loc10_)
            {
               if(_loc5_ == SkillType.PASSIVE)
               {
                  _loc12_ = 60;
                  _loc13_ = 5;
               }
               else
               {
                  _loc12_ = 59;
                  if(_loc3_.costSoulNum > 0)
                  {
                     _loc13_ = 13;
                  }
                  else
                  {
                     _loc13_ = 12;
                  }
               }
            }
            else if(_loc5_ == SkillType.GQ_DIJIESHI_COMMON_SKILL)
            {
               _loc12_ = 49;
               _loc13_ = 12;
            }
            else if(_loc5_ == SkillType.GQ_DIJIESHI_PASSIVE)
            {
               _loc12_ = 50;
               _loc13_ = 5;
            }
            else if(_loc5_ == SkillType.GQ_XINGZHIYU_ZHUANSHU_SKILL)
            {
               _loc12_ = 51;
               if(_loc3_.costSoulNum > 0)
               {
                  _loc13_ = 13;
               }
               else
               {
                  _loc13_ = 12;
               }
            }
            else if(_loc6_ == PMSkillTypes.GQ_JUEXING_YUANMAO_PASSIVE)
            {
               _loc12_ = 52;
               _loc13_ = 5;
            }
            else if(_loc6_ == PMSkillTypes.GQ_JUEXING_YUANMAO_ZHUANSHU_KILL)
            {
               _loc12_ = 53;
               _loc13_ = 12;
            }
            else if(_loc6_ == PMSkillTypes.GQ_JUEXING_ZHENSHEN_PASSIVE)
            {
               _loc12_ = 54;
               _loc13_ = 5;
            }
            else if(_loc6_ == PMSkillTypes.GQ_JUEXING_ZHENSHEN_ZHUANSHU_KILL)
            {
               _loc12_ = 55;
               _loc13_ = 12;
            }
            else if(_loc6_ == PMSkillTypes.GQ_MINGYUNBOYI_ZHUANSHU_SKILL)
            {
               _loc12_ = 57;
               if(_loc3_.costSoulNum > 0)
               {
                  _loc13_ = 13;
               }
               else
               {
                  _loc13_ = 12;
               }
            }
            else if(_loc5_ == SkillType.PASSIVE)
            {
               _loc12_ = 41;
               _loc13_ = 11;
            }
            else if(_loc6_ == PMSkillTypes.GQ_BUXIULVTU_COMMON_SKILL)
            {
               _loc12_ = 60 + _loc3_.level;
               _loc13_ = 12;
            }
            else
            {
               if(Boolean(GQPetType.isArmorBurst(_loc4_.getGQType())) && Boolean(GQArmorBurstSkillParse.getIsAfterChangeView(param2)))
               {
                  _loc12_ = 43;
               }
               else if(_loc10_)
               {
                  _loc12_ = 58;
               }
               else
               {
                  _loc12_ = 42;
               }
               _loc13_ = 12;
            }
         }
         else if(_loc8_ == PetState.CHANGING_VIEW)
         {
            _loc12_ = 2;
            _loc13_ = 1;
         }
         else if(_loc7_ == PetType.GOT_SKILL_AOYI)
         {
            _loc12_ = 3;
            _loc13_ = 2;
         }
         else if(_loc7_ == PetType.MIRACLE)
         {
            _loc12_ = 4;
            _loc13_ = 1;
         }
         else
         {
            _loc12_ = 1;
            _loc13_ = 1;
         }
         this._mcBack.gotoAndStop(_loc12_);
         this._mcDes.gotoAndStop(_loc13_);
         if(PetType.isXinghuiPet(_loc7_) && _loc4_.getXinghuiType() == XinghuiPetType.CHECKER_BOARD)
         {
            _loc17_ = XinghuiPetType.getCheckerBoardByRaceId(param2.raceId);
            _loc18_ = _loc17_ ? int(_loc17_.exSkillFrame) : 1;
            ActComHelper.setMcFrame(this._mcBack,"mcBox",_loc18_);
         }
         this.setSkillDesc(_loc3_,param1);
         if(SkillType.getIsDegeneratorSuperSpiritSkill(_loc5_))
         {
            _loc19_ = int(this._pmService.getOperationPM(param2.raceId).pmData.maxDegeneratorSoulNum);
            _loc20_ = this._mcBack.getChildByName("mc") as MovieClip;
            if(_loc20_ != null)
            {
               _loc20_.gotoAndStop(_loc19_ - 4);
               _loc21_ = int(param2.curDegeneratorSoulNum);
               (_loc20_.mcsoul as MovieClip).gotoAndStop(_loc21_ + 1);
            }
         }
         else if(SkillType.getIsXinghuiSuperSpiritSkill(_loc5_))
         {
            _loc19_ = int(this._pmService.getOperationPM(param2.raceId).pmData.maxXinghuiSoulNum);
            _loc20_ = this._mcBack.getChildByName("mc") as MovieClip;
            if(_loc20_ != null)
            {
               _loc20_.gotoAndStop(_loc19_ - 4);
               _loc21_ = int(param2.curXinghuiSoulNum);
               (_loc20_.mcsoul as MovieClip).gotoAndStop(_loc21_ + 1);
            }
         }
         var _loc14_:MovieClip = this._mcBack.getChildByName("mcxinghuibg") as MovieClip;
         if(_loc14_ != null)
         {
            if(Boolean(param2.isShielded()) || _loc4_.getXinghuiType() == XinghuiPetType.JUEXING && this.getIsAfterJuexing(_loc4_))
            {
               _loc14_.gotoAndStop(2);
            }
            else
            {
               _loc14_.gotoAndStop(1);
            }
         }
         this.lianSuoEspHandle(_loc7_,param1,_loc4_);
      }
      
      private function lianSuoEspHandle(param1:int, param2:SkillInfo, param3:PMData) : void
      {
         var _loc4_:MovieClip = null;
         var _loc5_:int = 0;
         var _loc6_:GQLianSuoSkillParse = null;
         if(PetType.isGQPet(param1))
         {
            _loc4_ = this._mcDes.getChildByName("mcLianSuoIsUse") as MovieClip;
            if(!_loc4_)
            {
               return;
            }
            _loc5_ = int(this._pmService.getOperationPM(this._petInfo.raceId).pmData.getGQType());
            if(!GQPetType.isLianSuo(param3.getGQType()) || this._petInfo.usingGQSkillType == 1 && !GQPetType.isAdaptSystem(_loc5_,this._petInfo))
            {
               _loc4_.visible = false;
               _loc4_.gotoAndStop(1);
            }
            else
            {
               _loc4_.visible = true;
               _loc6_ = GQLianSuoSkillParse.getLianSuoSkillData(param3.raceId);
               _loc4_.gotoAndStop(_loc6_.getIsUseSmallSkill(this._petInfo,param2.id) ? 2 : 1);
            }
         }
      }
      
      private function getIsAfterJuexing(param1:PMData) : Boolean
      {
         var _loc2_:Array = param1.getXinghuiExtraConfig().split("=")[1].split("#");
         if(parseInt(_loc2_[1]) == this._petInfo.raceId)
         {
            return true;
         }
         return false;
      }
      
      private function setSkillDesc(param1:PMSkill, param2:SkillInfo) : void
      {
         var _loc3_:String = null;
         var _loc4_:String = null;
         var _loc5_:String = null;
         var _loc9_:MovieClip = null;
         var _loc10_:int = 0;
         if(this._mcDes.numChildren <= 0)
         {
            this.removeAttributeIcon();
            return;
         }
         this.updateAttributeIcon(param2,param1);
         var _loc6_:int = int(param1.power);
         var _loc7_:* = param2.maxUseTimes;
         var _loc8_:* = param2.canUseTimes;
         _loc3_ = param1.newCnName;
         if(_loc6_ > 0)
         {
            _loc4_ = _loc6_.toString();
         }
         else
         {
            _loc4_ = "-";
         }
         if(SkillType.checkIsGQCommonSpiritSkill(param1.skillId))
         {
            _loc5_ = param1.costSoulNum.toString();
            _loc9_ = this._mcDes.getChildByName("mcGQSoulNum") as MovieClip;
            if(_loc9_)
            {
               ArtNumberManager.setNumber([_loc9_],param1.costSoulNum);
            }
         }
         else if(_loc7_ > 0)
         {
            _loc5_ = _loc8_.toString() + "/" + _loc7_.toString();
         }
         else
         {
            _loc5_ = "-/-";
         }
         ActComHelper.setMcFrame(this._mcDes,"mcCurPP",_loc8_ + 1);
         ActComHelper.setMcFrame(this._mcDes,"mcSumPP",_loc7_ + 1);
         this.setText("txtName",_loc3_);
         this.setText("txtPower",_loc4_);
         this.setText("txtPP",_loc5_);
         if(Boolean(this._yirenWujinMingtuSkillParser) && Boolean(this._yirenWujinMingtuSkillParser.getIsAfterChangeView(this._petInfo)))
         {
            _loc10_ = int(GQPetType.getYiRenSkillCost(this._petInfo.raceId,param2.id));
            this.setText("txtHP",StatusUtil.getYirenShieldByPbi(this._petInfo)[0] + "/" + _loc10_);
         }
         this.zhanYiProHandle();
         this.gqZhanYiProHandle();
      }
      
      private function zhanYiProHandle() : void
      {
         var _loc1_:int = int(SkillType.getSkillType(this._skillInfo.id));
         if(_loc1_ != SkillType.ZHANYI_ACTIVE)
         {
            return;
         }
         var _loc2_:XingHuiZhanYiSkillParser = this._petInfo.getXingHuiZhanYiSkillParser();
         var _loc3_:MovieClip = this._mcDes.getChildByName("mcPro") as MovieClip;
         if(_loc3_ == null)
         {
            return;
         }
         _loc3_.gotoAndStop(_loc2_.curRound() * 4 + 1);
      }
      
      private function gqZhanYiProHandle() : void
      {
         var _loc1_:MovieClip = this._mcDes.getChildByName("mcPro") as MovieClip;
         if(_loc1_ == null)
         {
            return;
         }
         _loc1_.stop();
         _loc1_.visible = false;
         var _loc2_:PMData = this._pmService.getOperationPM(this._petInfo.raceId).pmData;
         var _loc3_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(this._skillInfo.id);
         if(!GQPetType.isZhanYi(_loc2_.getGQType()) || _loc3_.newSkillType == 1)
         {
            return;
         }
         _loc1_.visible = true;
         var _loc4_:GQZhanYiSkillParse = this._petInfo.getGQZhanYiSkillParse();
         var _loc5_:int = int(_loc3_.getSkillType());
         if(_loc5_ != PMSkillTypes.GQ_ZHANYI_COMMON_SKILL && _loc5_ != PMSkillTypes.GQ_ZHANYI_NEW_COMMON_SKILL)
         {
            _loc1_.gotoAndStop(int(_loc4_.energy() / 12.5) + 1);
         }
         else
         {
            _loc1_.gotoAndStop(9);
         }
      }
      
      private function setText(param1:String, param2:String) : void
      {
         var _loc3_:TextField = this._mcDes.getChildByName(param1) as TextField;
         if(_loc3_ == null)
         {
            return;
         }
         _loc3_.mouseEnabled = false;
         _loc3_.text = param2;
      }
      
      private function removeAttributeIcon() : void
      {
         if(this._attributeIcon)
         {
            this._attributeIcon.setEmpty();
            this._attributeIcon = null;
         }
      }
      
      private function updateAttributeIcon(param1:SkillInfo, param2:PMSkill) : void
      {
         var _loc3_:MovieClip = this._mcDes.getChildByName("mcAttHolder") as MovieClip;
         if(_loc3_ == null)
         {
            return;
         }
         if(PMSkillTypes.isGQSkill(param2.getSkillType()))
         {
            if(this._attributeIcon)
            {
               if(this._attributeIcon.cacheKey.indexOf(FightAttributeIconCacheKey.SMALL) != -1 || !this._attributeIcon.container.parent)
               {
                  this.removeAttributeIcon();
               }
            }
            if(!PMSkillTypes.isGQSmallPassiveSkill(param2.getSkillType()) || param2.getSkillType() == PMSkillTypes.GQ_MENGHUAN_DIYUE_PASSIVE)
            {
               if(!this._attributeIcon)
               {
                  this._attributeIcon = new FightAttributeIconHandler(_loc3_,FightAttributeIconCacheKey.MIDDLE);
               }
               this._mcAttribute.x = _loc3_.x;
               this._mcAttribute.y = _loc3_.y;
               this._attributeIcon.setIcon(param2.attributeType);
            }
         }
         else
         {
            if(Boolean(this._attributeIcon) && this._attributeIcon.cacheKey.indexOf(FightAttributeIconCacheKey.MIDDLE) != -1)
            {
               this.removeAttributeIcon();
            }
            if(!this._attributeIcon)
            {
               this._attributeIcon = new FightAttributeIconHandler(this._mcAttribute,FightAttributeIconCacheKey.SMALL);
            }
            this._mcAttribute.scaleX = _loc3_.scaleX;
            this._mcAttribute.scaleY = _loc3_.scaleY;
            this._mcAttribute.x = _loc3_.x + this._mcDes.x;
            this._mcAttribute.y = _loc3_.y + this._mcDes.y;
            this._attributeIcon.setIcon(param2.attributeType);
         }
      }
      
      public function setBGGray() : void
      {
         DisplayUtil.applyGray(this._mcBack);
      }
      
      public function clearBGGray() : void
      {
         DisplayUtil.clearFilters(this._mcBack);
      }
   }
}

