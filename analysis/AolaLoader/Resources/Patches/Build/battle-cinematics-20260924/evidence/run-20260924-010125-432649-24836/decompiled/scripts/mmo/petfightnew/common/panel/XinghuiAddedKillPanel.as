package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.XingHuiPetHelperUtil;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.play.petfight.common.data.SkillType;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol34")]
   public class XinghuiAddedKillPanel extends MovieClip
   {
      
      public var mcskill_0:MovieClip;
      
      public var mcskill_1:MovieClip;
      
      public var mcskill_2:MovieClip;
      
      public var mcskill_3:MovieClip;
      
      public var mcskill_4:MovieClip;
      
      public var mcskill_5:MovieClip;
      
      private var _changeViewBtnEnabled:Boolean;
      
      private var _infos:Array;
      
      private var _pbi:PetBriefInfo;
      
      private var _type:int;
      
      public function XinghuiAddedKillPanel(param1:Array, param2:PetBriefInfo, param3:int)
      {
         var _loc8_:MovieClip = null;
         var _loc9_:Object = null;
         var _loc10_:int = 0;
         var _loc11_:PMSkill = null;
         var _loc12_:String = null;
         super();
         this._infos = param1;
         this._pbi = param2;
         this._type = param3;
         this.gotoAndStop(param1.length);
         var _loc4_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc5_:PMData = _loc4_.customData.pmDataMap.getPM(param2.raceId);
         var _loc6_:String = _loc5_.getXinghuiExtraConfig();
         var _loc7_:int = 0;
         while(_loc7_ < param1.length)
         {
            _loc8_ = this.getChildByName("mcskill_" + _loc7_) as MovieClip;
            _loc9_ = param1[_loc7_];
            _loc10_ = int(_loc9_["id"]);
            _loc8_.addEventListener(MouseEvent.CLICK,this.onClick);
            _loc11_ = _loc4_.customData.pmSkillMap.getSkill(_loc10_);
            if(!_loc9_.open)
            {
               _loc8_.gotoAndStop(3);
               if(XinghuiPetType.isEffUnlock(_loc6_))
               {
                  TipsManager.getInstance().addTips(_loc8_,"亚比战斗力达到" + XinghuiPetType.getUnlockEff(_loc6_) + "解锁");
               }
               else
               {
                  TipsManager.getInstance().addTips(_loc8_,"星辉被动达到5级解锁");
               }
            }
            else
            {
               if(this._pbi.curXinghuiSoulNum < _loc11_.costSoulNum)
               {
                  _loc8_.gotoAndStop(2);
               }
               else
               {
                  this._changeViewBtnEnabled = true;
                  _loc8_.gotoAndStop(1);
               }
               _loc12_ = _loc11_.newCnName + " 威力：" + this.getSkillPowerDesc(_loc11_.power);
               TipsManager.getInstance().replaceComplexTips(_loc8_,_loc12_,_loc11_.clientDesc,100,-100,9);
            }
            _loc8_["txtName"].text = _loc4_.customData.pmSkillMap.getSkill(_loc10_).newCnName;
            this.addEffectIcon(11,_loc10_,_loc8_);
            _loc7_++;
         }
      }
      
      public static function canShowAddedSkill(param1:PetBriefInfo, param2:int) : Boolean
      {
         var _loc3_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc4_:Boolean = param2 == SkillType.XINGHUI_KILL_BIG || param2 == SkillType.XINGHUI_SUPER_SPIRIT_TEJI;
         if(!_loc4_)
         {
            return false;
         }
         if(isPetHaveEWaiTeJi(param1,param2))
         {
            return true;
         }
         if(!XinghuiPetType.isSpPet(_loc3_.customData.pmDataMap.getPM(param1.raceId).getXinghuiType()))
         {
            return false;
         }
         return _loc4_;
      }
      
      public static function isPetHaveEWaiTeJi(param1:PetBriefInfo, param2:int) : Boolean
      {
         var _loc6_:Array = null;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc3_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc4_:Array = XingHuiPetHelperUtil.getSkiilIdsByRaceIdAndSkillName(param1.raceId,"额外特技");
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_.length)
         {
            _loc6_ = _loc4_[_loc5_];
            _loc7_ = 0;
            while(_loc7_ < _loc6_.length)
            {
               _loc8_ = parseInt(_loc6_[_loc7_] + "");
               if(param2 == _loc3_.customData.pmSkillMap.getSkill(_loc8_).getSkillType())
               {
                  return true;
               }
               _loc7_++;
            }
            _loc5_++;
         }
         return false;
      }
      
      public static function getExtAddSkillInfo(param1:PetBriefInfo, param2:int) : Array
      {
         var _loc3_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc4_:PMData = _loc3_.customData.pmDataMap.getPM(param1.raceId);
         if(XinghuiPetType.isSpPet(_loc4_.getXinghuiType()))
         {
            return XinghuiAddedKillPanel.getXingHuiSpExtAddSkillInfo(param1,param2);
         }
         if(XinghuiPetType.isChuanShuo(_loc4_.getXinghuiType()))
         {
            return XinghuiAddedKillPanel.getXingHuiChuanShuoExtAddSkillInfo(param1,param2);
         }
         if(isPetHaveEWaiTeJi(param1,param2))
         {
            return XinghuiAddedKillPanel.getEWaiTeJiExtAddSkillInfo(param1,param2);
         }
         return null;
      }
      
      private static function getXingHuiSpExtAddSkillInfo(param1:PetBriefInfo, param2:int) : Array
      {
         var _loc8_:* = undefined;
         var _loc9_:Array = null;
         var _loc10_:int = 0;
         var _loc11_:* = false;
         var _loc3_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc4_:PMData = _loc3_.customData.pmDataMap.getPM(param1.raceId);
         if(!XinghuiPetType.isSpPet(_loc4_.getXinghuiType()))
         {
            return null;
         }
         if(param2 != SkillType.XINGHUI_KILL_BIG && param2 != SkillType.XINGHUI_SUPER_SPIRIT_TEJI)
         {
            return null;
         }
         var _loc5_:Array = getSkillIds(param1.skills);
         var _loc6_:Array = _loc5_.concat();
         var _loc7_:Array = XinghuiPetType.getSpExtraSkills(_loc4_.getXinghuiExtraConfig());
         for each(_loc8_ in _loc7_)
         {
            if(_loc5_.indexOf(parseInt(_loc8_)) < 0)
            {
               _loc5_.push(parseInt(_loc8_));
            }
         }
         _loc9_ = [];
         _loc10_ = 0;
         while(_loc10_ < _loc5_.length)
         {
            if(_loc3_.customData.pmSkillMap.getSkill(_loc5_[_loc10_]).getSkillType() == param2)
            {
               _loc11_ = _loc6_.indexOf(_loc5_[_loc10_]) >= 0;
               _loc9_.push({
                  "id":_loc5_[_loc10_],
                  "open":_loc11_
               });
            }
            _loc10_++;
         }
         return _loc9_;
      }
      
      private static function getXingHuiChuanShuoExtAddSkillInfo(param1:PetBriefInfo, param2:int) : Array
      {
         var _loc9_:* = false;
         var _loc3_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc4_:PMData = _loc3_.customData.pmDataMap.getPM(param1.raceId);
         if(!XinghuiPetType.isChuanShuo(_loc4_.getXinghuiType()))
         {
            return null;
         }
         if(param2 != SkillType.XINGHUI_KILL_BIG && param2 != SkillType.XINGHUI_SUPER_SPIRIT_TEJI)
         {
            return null;
         }
         var _loc5_:Array = getSkillIds(param1.skills);
         var _loc6_:Array = _loc5_.concat();
         var _loc7_:Array = [];
         var _loc8_:int = 0;
         while(_loc8_ < _loc5_.length)
         {
            if(_loc3_.customData.pmSkillMap.getSkill(_loc5_[_loc8_]).getSkillType() == param2)
            {
               _loc9_ = _loc6_.indexOf(_loc5_[_loc8_]) >= 0;
               _loc7_.push({
                  "id":_loc5_[_loc8_],
                  "open":true
               });
            }
            _loc8_++;
         }
         return _loc7_;
      }
      
      private static function getEWaiTeJiExtAddSkillInfo(param1:PetBriefInfo, param2:int) : Array
      {
         var _loc8_:int = 0;
         var _loc3_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc4_:Array = [];
         var _loc5_:Array = getSkillIds(param1.skills);
         var _loc6_:Array = _loc5_.concat();
         var _loc7_:int = 0;
         while(_loc7_ < _loc6_.length)
         {
            _loc8_ = int(_loc6_[_loc7_]);
            if(param2 == _loc3_.customData.pmSkillMap.getSkill(_loc8_).getSkillType())
            {
               _loc4_.push({
                  "id":_loc8_,
                  "open":true
               });
            }
            _loc7_++;
         }
         return _loc4_;
      }
      
      private static function isInArray2d(param1:int, param2:Array) : Boolean
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
      
      private static function getSkillIds(param1:Array) : Array
      {
         var _loc4_:SkillInfo = null;
         var _loc2_:Array = [];
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc4_ = param1[_loc3_];
            _loc2_.push(_loc4_.id);
            _loc3_++;
         }
         return _loc2_;
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
      
      public function setClickable(param1:Boolean) : void
      {
         this._changeViewBtnEnabled = param1;
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
         var _loc2_:IPMService = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:PMSkill = null;
         var _loc6_:int = 0;
         param1.stopImmediatePropagation();
         if(!this._changeViewBtnEnabled)
         {
            return;
         }
         if(param1.target.name == "btnskill")
         {
            _loc2_ = ServicePool.instance.getService(IPMService);
            _loc3_ = parseInt(param1.target.parent.name.split("_")[1]);
            _loc4_ = int(this._infos[_loc3_].id);
            _loc5_ = _loc2_.customData.pmSkillMap.getSkill(_loc4_);
            _loc6_ = int(_loc5_.getSkillType());
            if(UseBigSkillHandler.instance.isHandling() && !UseBigSkillHandler.instance.isUsingSkill(_loc6_,_loc4_))
            {
               UseBigSkillHandler.instance.cancelUse();
            }
            UseBigSkillHandler.instance.handleUse(this._pbi,_loc4_,_loc6_);
         }
      }
   }
}

