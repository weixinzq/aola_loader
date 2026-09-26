package mmo.petfightnew.common.useskill
{
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.GQYanhuaZhiyaoGongmingZhongduanSkillParse;
   import mmo.interfaces.pet.data.GQYiRenWujinMingtuSkillParse;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMLegendBigSkillTypes;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.restraint.RestraintEffect;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.DegeneratorPetHelper;
   import mmo.petfightnew.common.util.GQPetHelper;
   import mmo.petfightnew.common.util.LegendPetHelper;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.petfightnew.common.util.XinghuiPetHelper;
   
   public class NewOrderlySkillStrategy implements IUseSkillStrategy
   {
      
      private static var count:int;
      
      private var pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      public function NewOrderlySkillStrategy()
      {
         super();
         reset();
      }
      
      public static function reset() : void
      {
         count = 0;
      }
      
      public function useSkill(param1:PetBriefInfo) : int
      {
         var _loc10_:PMSkill = null;
         var _loc11_:Array = null;
         var _loc12_:PMSkill = null;
         var _loc13_:PMSkill = null;
         var _loc14_:Array = null;
         var _loc15_:PMSkill = null;
         var _loc16_:PMSkill = null;
         var _loc17_:PMSkill = null;
         var _loc18_:Array = null;
         var _loc19_:GQYiRenWujinMingtuSkillParse = null;
         var _loc20_:Object = null;
         var _loc21_:int = 0;
         var _loc22_:int = 0;
         var _loc23_:Array = null;
         var _loc24_:int = 0;
         var _loc25_:SkillInfo = null;
         var _loc26_:int = 0;
         var _loc2_:PetBriefInfo = FightData.instance.opponents[0].myPets[0];
         var _loc3_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         var _loc4_:Array = param1.skills.concat();
         var _loc5_:Boolean = this.checkIsLegend(param1.raceId);
         var _loc6_:Boolean = this.checkIsDegenerator(param1.raceId);
         var _loc7_:Boolean = this.checkIsXinghui(param1.raceId);
         var _loc8_:Boolean = this.checkIsGQ(param1.raceId);
         var _loc9_:int = int(this.pmService.getOperationPM(param1.raceId).pmData.getGQType());
         if(_loc5_)
         {
            this.filterPassiveSkill(_loc4_);
            _loc10_ = LegendPetHelper.getLegendPetBigSkill(param1);
            if(_loc10_ != null)
            {
               if(this.canUseLegendBig(param1,_loc10_))
               {
                  return _loc10_.skillId;
               }
            }
         }
         else if(_loc6_)
         {
            this.filterPassiveSkill(_loc4_);
            _loc11_ = [];
            _loc12_ = DegeneratorPetHelper.getDegeneratorPetBigSkill(param1);
            _loc13_ = DegeneratorPetHelper.getDegeneratorPetSuperSkill(param1);
            if(_loc12_ != null)
            {
               if(this.canUseDegeneratorBig(param1,_loc12_))
               {
                  _loc11_.push(_loc12_.skillId);
               }
            }
            if(_loc13_ != null && _loc13_.getSkillType() != PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_JUE && _loc13_.getSkillType() != PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_YU_PASSIVE && _loc13_.getSkillType() != PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_ZHAOHUAN)
            {
               if(this.canUseDegeneratorBig(param1,_loc13_))
               {
                  _loc11_.push(_loc13_.skillId);
               }
            }
            if(_loc11_.length > 0)
            {
               return _loc11_[int(Math.random() * _loc11_.length)];
            }
         }
         else if(_loc7_)
         {
            this.filterPassiveSkill(_loc4_);
            _loc14_ = [];
            _loc15_ = XinghuiPetHelper.getXinghuiPetBigSkill(param1);
            _loc16_ = XinghuiPetHelper.getXinghuiPetSuperSpiritSkill(param1);
            if(_loc16_ != null && param1.curXinghuiSoulNum >= 3)
            {
               if(this.canUseXinghuiBig(param1,_loc16_))
               {
                  if(Math.random() < 0.25)
                  {
                     return _loc16_.skillId;
                  }
               }
            }
            if(_loc15_ != null && param1.curXinghuiSoulNum >= 5)
            {
               if(this.canUseXinghuiBig(param1,_loc15_))
               {
                  return _loc15_.skillId;
               }
            }
         }
         else if(_loc8_)
         {
            this.filterPassiveSkill(_loc4_);
            _loc17_ = GQPetHelper.getGQPetBigSkill(param1);
            _loc18_ = GQPetHelper.getGQCommonSpiritSkills(param1);
            _loc19_ = GQYiRenWujinMingtuSkillParse.getYiRenWujinMingtuSkillData(param1.raceId);
            if((Boolean(_loc19_)) && Boolean(_loc19_.getIsAfterChangeView(param1)))
            {
               _loc20_ = GQPetType.getYiRenObject(PetAssetsMap.getPetFlaId(param1.raceId));
               return _loc20_.skillCost[0]["skillId"];
            }
            if(GQPetType.isYanhuaZhiyao(_loc9_))
            {
               if(!StatusUtil.getIsYanhuaZhiyaoUsed(param1))
               {
                  _loc21_ = int(GQYanhuaZhiyaoGongmingZhongduanSkillParse.getYanhuaZhiyaoSpiritSkillId(param1));
                  if(_loc21_ > 0)
                  {
                     return _loc21_;
                  }
               }
               else
               {
                  this.filterYanhuaZhiyaoSkill(_loc4_);
               }
            }
            if(param1.curGQSoulNum >= 3)
            {
               _loc22_ = 0;
               while(_loc22_ < _loc18_.length)
               {
                  if(this.canUsGQBig(param1,_loc18_[_loc22_]))
                  {
                     if(Math.random() < 0.25)
                     {
                        return _loc18_[_loc22_].skillId;
                     }
                  }
                  _loc22_++;
               }
            }
            if(_loc17_ != null && param1.curGQSoulNum >= 4)
            {
               if(this.canUsGQBig(param1,_loc17_))
               {
                  return _loc17_.skillId;
               }
            }
         }
         this.filterLegendBigSkill(_loc4_);
         this.filterDegeneratorBigSkill(_loc4_);
         this.filterXinghuiBigSkill(_loc4_);
         this.filterGQBigSkill(_loc4_);
         if(this.isAllCannotUse(_loc4_))
         {
            return this.getValideSkillId(_loc4_,_loc18_);
         }
         if(_loc7_)
         {
            _loc23_ = [];
            _loc23_ = this.getCanUseSkills(_loc4_);
            if(_loc4_.length > 0)
            {
               _loc24_ = int(this.pmService.getOperationPM(_loc2_.raceId).pmData.pmAttribute);
               for each(_loc25_ in _loc4_)
               {
                  _loc26_ = int(this.pmService.customData.pmSkillMap.getSkill(_loc25_.id).attributeType);
                  if(RestraintEffect.isVeryEffect(_loc3_.compareAttributeRelation(_loc26_,_loc24_)))
                  {
                     return _loc25_.id;
                  }
               }
            }
            else
            {
               _loc4_ = _loc23_;
            }
         }
         _loc4_.sort(this.compare);
         return this.selectSkill(_loc4_);
      }
      
      private function getCanUseSkills(param1:Array) : Array
      {
         var _loc5_:SkillInfo = null;
         var _loc6_:PMSkill = null;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:Array = [];
         var _loc4_:int = int(param1.length - 1);
         while(_loc4_ >= 0)
         {
            _loc5_ = param1[_loc4_];
            _loc6_ = _loc2_.customData.pmSkillMap.getSkill(_loc5_.id);
            if(_loc5_.canUseTimes <= 0)
            {
               param1.splice(_loc4_,1);
            }
            else if(_loc6_.attackType == 2)
            {
               param1.splice(_loc4_,1);
               _loc3_.push(_loc5_);
            }
            _loc4_--;
         }
         return _loc3_;
      }
      
      private function canUseXinghuiBig(param1:PetBriefInfo, param2:PMSkill) : Boolean
      {
         if(param1.curXinghuiSoulNum < param2.costSoulNum)
         {
            return false;
         }
         return true;
      }
      
      private function canUsGQBig(param1:PetBriefInfo, param2:PMSkill) : Boolean
      {
         if(param1.curGQSoulNum < param2.costSoulNum)
         {
            return false;
         }
         return true;
      }
      
      private function canUseDegeneratorBig(param1:PetBriefInfo, param2:PMSkill) : Boolean
      {
         if(param1.curDegeneratorSoulNum < param2.costSoulNum)
         {
            return false;
         }
         return true;
      }
      
      private function canUseLegendBig(param1:PetBriefInfo, param2:PMSkill) : Boolean
      {
         if(param1.curSoulNum < param2.costSoulNum)
         {
            return false;
         }
         if(param2.getLegendBigSkillType() == PMLegendBigSkillTypes.LEGEND_TOTEM_BIG)
         {
            if(FightData.instance.isMySideHaveSummonPetInBattleField())
            {
               return false;
            }
         }
         return true;
      }
      
      private function filterLegendBigSkill(param1:Array) : void
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:SkillInfo = null;
         var _loc4_:int = int(param1.length - 1);
         while(_loc4_ >= 0)
         {
            _loc3_ = param1[_loc4_];
            if(_loc2_.customData.pmSkillMap.getSkill(_loc3_.id).isLegendBigSkill())
            {
               param1.splice(_loc4_,1);
            }
            _loc4_--;
         }
      }
      
      private function filterDegeneratorBigSkill(param1:Array) : void
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:SkillInfo = null;
         var _loc4_:int = int(param1.length - 1);
         while(_loc4_ >= 0)
         {
            _loc3_ = param1[_loc4_];
            if(DegeneratorPetHelper.checkIsDegeneratorBig(_loc3_.id) || DegeneratorPetHelper.checkIsDegeneratorSuperPo(_loc3_.id))
            {
               param1.splice(_loc4_,1);
            }
            _loc4_--;
         }
      }
      
      private function filterXinghuiBigSkill(param1:Array) : void
      {
         var _loc4_:PMSkill = null;
         var _loc2_:SkillInfo = null;
         var _loc3_:int = int(param1.length - 1);
         while(_loc3_ >= 0)
         {
            _loc2_ = param1[_loc3_];
            _loc4_ = this.pmService.customData.pmSkillMap.getSkill(_loc2_.id);
            if(Boolean(PMSkillTypes.isXinghuiKillBig(_loc4_.getSkillType())) || Boolean(PMSkillTypes.isXinghuiSuperSpiritSkill(_loc4_.getSkillType())))
            {
               param1.splice(_loc3_,1);
            }
            _loc3_--;
         }
      }
      
      private function filterGQBigSkill(param1:Array) : void
      {
         var _loc4_:PMSkill = null;
         var _loc2_:SkillInfo = null;
         var _loc3_:int = int(param1.length - 1);
         while(_loc3_ >= 0)
         {
            _loc2_ = param1[_loc3_];
            _loc4_ = this.pmService.customData.pmSkillMap.getSkill(_loc2_.id);
            if(Boolean(PMSkillTypes.isGQKillBig(_loc4_.getSkillType())) || Boolean(PMSkillTypes.isGQCommonSpiritSkill(_loc4_.getSkillType())))
            {
               param1.splice(_loc3_,1);
            }
            _loc3_--;
         }
      }
      
      private function filterYanhuaZhiyaoSkill(param1:Array) : void
      {
         var _loc4_:PMSkill = null;
         var _loc2_:SkillInfo = null;
         var _loc3_:int = int(param1.length - 1);
         while(_loc3_ >= 0)
         {
            _loc2_ = param1[_loc3_];
            _loc4_ = this.pmService.customData.pmSkillMap.getSkill(_loc2_.id);
            if(PMSkillTypes.GQ_YANHUAZHIYAO_SPIRIT_SKILL == _loc4_.getSkillType())
            {
               param1.splice(_loc3_,1);
            }
            _loc3_--;
         }
      }
      
      private function getValideSkillId(param1:Array, param2:Array) : int
      {
         if(param1.length <= 0)
         {
            return param2[0].skillId;
         }
         return param1[0].id;
      }
      
      private function filterPassiveSkill(param1:Array) : Array
      {
         var _loc5_:PMSkill = null;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:SkillInfo = null;
         var _loc4_:int = int(param1.length - 1);
         while(_loc4_ >= 0)
         {
            _loc3_ = param1[_loc4_];
            _loc5_ = _loc2_.customData.pmSkillMap.getSkill(_loc3_.id);
            if(Boolean(_loc5_.isPassiveSkill) || _loc5_.getSkillType() == PMSkillTypes.DEGENERATOR_PASSIVE_SKILL || _loc5_.getSkillType() == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_JUE || _loc5_.getSkillType() == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_YU_PASSIVE || _loc5_.getSkillType() == PMSkillTypes.XINGHUI_PASSIVE_SKILL || Boolean(PMSkillTypes.isGQPassiveSkill(_loc5_.getSkillType())))
            {
               param1.splice(_loc4_,1);
            }
            _loc4_--;
         }
         return param1;
      }
      
      private function checkIsLegend(param1:int) : Boolean
      {
         return LegendPetHelper.checkIsLegendPet(param1);
      }
      
      private function checkIsDegenerator(param1:int) : Boolean
      {
         return DegeneratorPetHelper.checkIsDegeneratorPet(param1);
      }
      
      private function checkIsXinghui(param1:int) : Boolean
      {
         return XinghuiPetHelper.checkIsXinghuiPet(param1);
      }
      
      private function checkIsGQ(param1:int) : Boolean
      {
         return GQPetHelper.checkIsGQPet(param1);
      }
      
      private function isAllCannotUse(param1:Array) : Boolean
      {
         var _loc3_:SkillInfo = null;
         var _loc2_:Boolean = true;
         for each(_loc3_ in param1)
         {
            if(_loc3_.canUseTimes > 0)
            {
               _loc2_ = false;
               break;
            }
         }
         return _loc2_;
      }
      
      private function selectSkill(param1:Array) : int
      {
         var _loc2_:int = count % param1.length;
         ++count;
         var _loc3_:SkillInfo = param1[_loc2_] as SkillInfo;
         if(_loc3_.canUseTimes > 0)
         {
            return _loc3_.id;
         }
         return this.selectSkill(param1);
      }
      
      private function compare(param1:SkillInfo, param2:SkillInfo) : int
      {
         var _loc3_:IPMService = ServicePool.instance.getService(IPMService);
         return _loc3_.customData.pmSkillMap.getSkill(param2.id).power - _loc3_.customData.pmSkillMap.getSkill(param1.id).power;
      }
   }
}

