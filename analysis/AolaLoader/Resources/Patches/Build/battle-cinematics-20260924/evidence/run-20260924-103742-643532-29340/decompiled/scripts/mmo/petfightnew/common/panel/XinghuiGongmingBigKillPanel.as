package mmo.petfightnew.common.panel
{
   import com.adobe.utils.ArrayUtil;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.manager.ServicePool;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol33")]
   public class XinghuiGongmingBigKillPanel extends MovieClip
   {
      
      public var mcskill_0:MovieClip;
      
      public var mcskill_1:MovieClip;
      
      public var mcskill_2:MovieClip;
      
      public var mcskill_3:MovieClip;
      
      public var mcskill_4:MovieClip;
      
      public var mcskill_5:MovieClip;
      
      public var mcskill_6:MovieClip;
      
      public var mcskill_7:MovieClip;
      
      public var mcskill_8:MovieClip;
      
      private var _pbi:PetBriefInfo = null;
      
      private var _xinghuiBigSkill:PMSkill = null;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _pmData:PMData;
      
      private var _pskSvr:IPetSkillMesService = null;
      
      private var _skillList:Array = [];
      
      private var _gongmingLvArr:Array = [];
      
      private var _changeViewBtnEnabled:Boolean = true;
      
      public function XinghuiGongmingBigKillPanel(param1:int)
      {
         super();
         this._xinghuiBigSkill = this._pmSvr.customData.pmSkillMap.getSkill(param1);
         this.init();
      }
      
      private function init() : void
      {
         this._pbi = FightData.instance.myInfo.operatingPlayer.myPets[0];
         this._pmData = this._pmSvr.getOperationPM(this._pbi.raceId).pmData;
         this._pskSvr = ServicePool.instance.getService(IPetSkillMesService);
         this.initSkillList();
         this.gotoAndStop(this._skillList.length);
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         this.refresh();
      }
      
      public function setClickable(param1:Boolean) : void
      {
         this._changeViewBtnEnabled = param1;
      }
      
      private function initSkillList() : void
      {
         var _loc3_:int = 0;
         var _loc4_:Object = null;
         var _loc5_:Array = null;
         var _loc6_:* = undefined;
         var _loc7_:int = 0;
         this._gongmingLvArr = this._pbi.getGongmingArr();
         this._skillList = [this._xinghuiBigSkill.skillId];
         var _loc1_:int = 0;
         while(_loc1_ < this._pmData.beGongmingObjetArr.length)
         {
            _loc3_ = -1;
            _loc4_ = this._pmData.beGongmingObjetArr[_loc1_];
            if(_loc4_["skillId"][0] != -1 && this._gongmingLvArr.length > 0 && this._gongmingLvArr[_loc1_] > -1)
            {
               _loc3_ = int(this._pmSvr.customData.pmSkillMap.getSkill(_loc4_["skillId"][0]).skillSerials[this._gongmingLvArr[_loc1_]]);
            }
            else
            {
               _loc3_ = int(_loc4_["skillId"][0]);
            }
            if(!ArrayUtil.arrayContainsValue(this._skillList,_loc3_))
            {
               this._skillList.push(_loc3_);
            }
            _loc1_++;
         }
         var _loc2_:Array = [];
         if(this._pmData.getXinghuiType() == XinghuiPetType.SP_WANGZHE)
         {
            _loc5_ = XinghuiPetType.getSpExtraSkills(this._pmData.getXinghuiExtraConfig());
            for each(_loc6_ in _loc5_)
            {
               if(_loc2_.indexOf(parseInt(_loc6_)) < 0)
               {
                  _loc2_.push(parseInt(_loc6_));
               }
            }
            _loc7_ = 0;
            while(_loc7_ < _loc2_.length)
            {
               if(this._pmSvr.customData.pmSkillMap.getSkill(_loc2_[_loc7_]).getSkillType() == PMSkillTypes.XINGHUI_SUPER_SPIRIT_TEJI)
               {
                  this._skillList.push(_loc2_[_loc7_]);
               }
               _loc7_++;
            }
         }
      }
      
      public function refresh() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:PMSkill = null;
         var _loc4_:String = null;
         this._pbi = FightData.instance.myInfo.operatingPlayer.myPets[0];
         var _loc1_:int = 0;
         for(; _loc1_ < this._skillList.length; _loc1_++)
         {
            _loc2_ = this.getChildByName("mcskill_" + _loc1_) as MovieClip;
            if(_loc2_ != null)
            {
               _loc2_.visible = true;
               if(this._skillList[_loc1_] != -1)
               {
                  _loc3_ = this._pmSvr.customData.pmSkillMap.getSkill(this._skillList[_loc1_]);
                  if(_loc3_ == null)
                  {
                     _loc2_.gotoAndStop(3);
                     _loc2_.visible = false;
                     continue;
                  }
                  if((this._pbi.getGongmingArr().length == 0 || this._pbi.getGongmingArr()[_loc1_ - 1] == -1) && _loc1_ != 0)
                  {
                     _loc2_.gotoAndStop(3);
                  }
                  else if(this._pbi.curXinghuiSoulNum < _loc3_.costSoulNum)
                  {
                     _loc2_.gotoAndStop(2);
                  }
                  else
                  {
                     _loc2_.gotoAndStop(1);
                  }
                  (_loc2_.txtName as TextField).text = _loc3_.newCnName;
                  _loc4_ = _loc3_.newCnName + " 威力：" + this.getSkillPowerDesc(_loc3_.power);
                  TipsManager.getInstance().replaceComplexTips(_loc2_,_loc4_,_loc3_.clientDesc,100,-100,9);
               }
               else
               {
                  _loc2_.gotoAndStop(3);
               }
               this.addEffectIcon(11,this._skillList[_loc1_],_loc2_);
            }
         }
      }
      
      private function addEffectIcon(param1:int, param2:int, param3:MovieClip) : void
      {
         var _loc8_:Object = null;
         var _loc14_:PlayerBattleInfo = null;
         var _loc15_:Sprite = null;
         if(param3["mcEffectIcon"] == null)
         {
            return;
         }
         var _loc4_:int = FightData.instance.getSlotId(param1);
         var _loc5_:PlayerBattleInfo = FightData.instance.playerInfo[_loc4_] as PlayerBattleInfo;
         if(_loc5_ == null)
         {
            return;
         }
         var _loc6_:PetBriefInfo = _loc5_.myPets[0] as PetBriefInfo;
         if(_loc6_ == null)
         {
            return;
         }
         var _loc7_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         if(_loc5_.lingshouRealitySlotId == -1)
         {
            _loc8_ = _loc7_.getPetMes(_loc6_.raceId);
         }
         else
         {
            _loc14_ = FightData.instance.getPlayerInfoBySlotId(_loc5_.lingshouRealitySlotId);
            _loc8_ = _loc7_.getPetMes((_loc14_.myPets[0] as PetBriefInfo).raceId);
         }
         var _loc9_:Object = _loc7_.getPetSkillMes(param2);
         var _loc10_:int = _loc7_.compareAttributeRelation(_loc9_.attribute,_loc8_.attribute,_loc8_.attribute2) + 1;
         var _loc11_:* = param3["mcEffectIcon"];
         _loc11_.gotoAndStop(_loc10_);
         var _loc12_:int = int(_loc9_.attribute);
         var _loc13_:MovieClip = param3["mcSkillAtt"];
         if(_loc13_ != null)
         {
            _loc15_ = _loc7_.getSkillAttributeIcon(_loc12_);
            _loc13_.addChild(_loc15_);
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
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:PMSkill = null;
         var _loc5_:int = 0;
         if(!this._changeViewBtnEnabled)
         {
            return;
         }
         if(param1.target.name == "btnskill")
         {
            _loc2_ = parseInt(param1.target.parent.name.split("_")[1]);
            _loc3_ = int(this._skillList[_loc2_]);
            _loc4_ = this._pmSvr.customData.pmSkillMap.getSkill(_loc3_);
            _loc5_ = int(_loc4_.getSkillType());
            if(UseBigSkillHandler.instance.isHandling() && !UseBigSkillHandler.instance.isUsingSkill(_loc5_,_loc3_))
            {
               UseBigSkillHandler.instance.cancelUse();
            }
            UseBigSkillHandler.instance.handleUse(this._pbi,_loc3_,_loc5_);
         }
      }
   }
}

