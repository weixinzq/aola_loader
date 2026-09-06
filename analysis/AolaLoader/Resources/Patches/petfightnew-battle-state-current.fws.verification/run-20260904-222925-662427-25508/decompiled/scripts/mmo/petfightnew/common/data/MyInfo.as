package mmo.petfightnew.common.data
{
   import com.adobe.utils.ArrayUtil;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.debug.Tracer;
   
   public class MyInfo
   {
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService) as IPMService;
      
      public var extraTurn:int = 0;
      
      private var _allows:Object = {};
      
      private var _needOperates:Object = {};
      
      private var _playerInfoList:Array = [];
      
      private var _myAllPetList:Array = null;
      
      private var _operatingPlayer:PlayerBattleInfo = null;
      
      private var _myPMMasterId:int = 0;
      
      private var _isClientPackage:Boolean = false;
      
      private var _catchLevel:int = 0;
      
      private var _isLocalAndSlotSameSide:Boolean = true;
      
      private var _hasOperatedStates:Object = {};
      
      private var _willUseItemIds:Object = {};
      
      private var _dieForSwitchSlots:Array = [];
      
      private var _willSwitchPetsOnTurnOperation:Array = [];
      
      private var _willSwitchPetsOnDying:Array = [];
      
      private var _skillUsedMap:Object = {};
      
      private var _realTimeRoleHp:Object = {};
      
      private var _needOnlySwitchPMs:Object = {};
      
      private var _needOnlyClickPanels:Object = {};
      
      private var _myPetXingHuiTypeArr:Array = [];
      
      private var _myPetGuangQiTypeArr:Array = [];
      
      public function MyInfo()
      {
         super();
      }
      
      public function addDieForSwitchSlot(param1:int) : void
      {
         if(this._dieForSwitchSlots.indexOf(param1) < 0)
         {
            this._dieForSwitchSlots.push(param1);
         }
      }
      
      public function getAllows(param1:int) : Boolean
      {
         if(this._allows.hasOwnProperty(param1 + ""))
         {
            return this._allows[param1 + ""];
         }
         return false;
      }
      
      public function setAllows(param1:int, param2:Boolean) : void
      {
         this._allows[param1 + ""] = param2;
      }
      
      public function getNeedOperates(param1:int) : Boolean
      {
         if(this._needOperates.hasOwnProperty(param1 + ""))
         {
            return this._needOperates[param1 + ""];
         }
         return false;
      }
      
      public function setNeedOperates(param1:int, param2:Boolean) : void
      {
         this._needOperates[param1] = param2;
      }
      
      public function getNeedOnlySwitchPMs(param1:int) : Boolean
      {
         if(this._needOnlySwitchPMs.hasOwnProperty(param1 + ""))
         {
            return this._needOnlySwitchPMs[param1 + ""];
         }
         return false;
      }
      
      public function setCanOnlySwitchPMs(param1:int, param2:Boolean) : void
      {
         this._needOnlySwitchPMs[param1] = param2;
      }
      
      public function getNeedOnlyClickPanels(param1:int) : Boolean
      {
         if(this._needOnlyClickPanels.hasOwnProperty(param1 + ""))
         {
            return this._needOnlyClickPanels[param1 + ""];
         }
         return false;
      }
      
      public function setNeedOnlyClickPanels(param1:int, param2:Boolean) : void
      {
         this._needOnlyClickPanels[param1] = param2;
      }
      
      public function setWillUseItem(param1:int) : void
      {
         if(this._willUseItemIds.hasOwnProperty(param1))
         {
            ++this._willUseItemIds[param1];
         }
         else
         {
            this._willUseItemIds[param1] = 1;
         }
      }
      
      public function getWillUseItemNum(param1:int) : int
      {
         if(this._willUseItemIds.hasOwnProperty(param1))
         {
            return this._willUseItemIds[param1];
         }
         return 0;
      }
      
      public function haveDieForSwitchSlot() : Boolean
      {
         return this._dieForSwitchSlots.length > 0;
      }
      
      public function setPetWillSwitchUp(param1:int, param2:int) : void
      {
         this.removeFromArray(param1,this._dieForSwitchSlots);
         if(this.isSwitchingOnPetDying())
         {
            this.removeFromArray(param2,this._willSwitchPetsOnTurnOperation);
            this.putIntoArray(param2,this._willSwitchPetsOnDying);
         }
         else
         {
            this.putIntoArray(param2,this._willSwitchPetsOnTurnOperation);
         }
      }
      
      private function putIntoArray(param1:int, param2:Array) : void
      {
         var _loc3_:int = int(param2.indexOf(param1));
         if(_loc3_ < 0)
         {
            param2.push(param1);
         }
      }
      
      private function removeFromArray(param1:int, param2:Array) : void
      {
         var _loc3_:int = int(param2.indexOf(param1));
         if(_loc3_ >= 0)
         {
            param2.splice(_loc3_,1);
         }
      }
      
      private function searchFromArray(param1:int, param2:Array) : Boolean
      {
         return param2.indexOf(param1) >= 0;
      }
      
      public function isPetWillSwitchUpOnTurnOperaiton(param1:int) : Boolean
      {
         return this.searchFromArray(param1,this._willSwitchPetsOnTurnOperation);
      }
      
      public function isPetWillSwitchUpOnDying(param1:int) : Boolean
      {
         return this.searchFromArray(param1,this._willSwitchPetsOnDying);
      }
      
      public function isSwitchingOnPetDying() : Boolean
      {
         return this._dieForSwitchSlots.length > 0;
      }
      
      public function isPetWillSwitchUp(param1:int) : Boolean
      {
         return this.isPetWillSwitchUpOnTurnOperaiton(param1) || this.isPetWillSwitchUpOnDying(param1);
      }
      
      public function resetOperateRecord() : void
      {
         this._willUseItemIds = {};
         this._dieForSwitchSlots.length = 0;
         this._willSwitchPetsOnTurnOperation.length = 0;
         this._willSwitchPetsOnDying.length = 0;
      }
      
      public function havePlayerCanOperate() : Boolean
      {
         return this.getCanOperatePlayer() != null;
      }
      
      public function getCanOperateDefaultSlotId() : int
      {
         var _loc1_:PlayerBattleInfo = this.getDefaultCanOperatePlayer();
         if(_loc1_)
         {
            return _loc1_.slotId;
         }
         return -1;
      }
      
      private function getDefaultCanOperatePlayer() : PlayerBattleInfo
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc1_:int = 0;
         while(_loc1_ < this._playerInfoList.length)
         {
            _loc2_ = this._playerInfoList[_loc1_];
            if(this.haveOperateRight(_loc2_))
            {
               if(this.isBattlePetOfPlayerAlive(_loc2_))
               {
                  if(!this.hasOperated(_loc2_.slotId))
                  {
                     return _loc2_;
                  }
               }
            }
            _loc1_++;
         }
         return null;
      }
      
      public function setPlayerOperatedState(param1:int, param2:Boolean) : void
      {
         this._hasOperatedStates[param1] = param2;
      }
      
      public function hasOperated(param1:int) : Boolean
      {
         return this._hasOperatedStates[param1];
      }
      
      public function getCanOperatePlayer() : PlayerBattleInfo
      {
         var _loc1_:PlayerBattleInfo = null;
         for each(_loc1_ in this._playerInfoList)
         {
            if(this.haveOperateRight(_loc1_) && this.isBattlePetOfPlayerAlive(_loc1_) && !this._hasOperatedStates[_loc1_.slotId] && _loc1_.lingshouRealitySlotId == -1)
            {
               return _loc1_;
            }
         }
         return null;
      }
      
      private function isBattlePetOfPlayerAlive(param1:PlayerBattleInfo) : Boolean
      {
         return (param1.myPets[0] as PetBriefInfo).curHp > 0;
      }
      
      public function haveOperateRight(param1:PlayerBattleInfo) : Boolean
      {
         return param1 != null && param1.PMMasterId > 0 && !FightData.instance.isSummonedPlayer(param1);
      }
      
      public function resetOperatedStates() : void
      {
         this._hasOperatedStates = {};
      }
      
      public function setCurOperatingPlayerOperated(param1:int = -1) : void
      {
         var _loc3_:IPMService = null;
         var _loc4_:PMSkill = null;
         var _loc5_:* = undefined;
         var _loc6_:PetBriefInfo = null;
         var _loc2_:int = int(this._operatingPlayer.slotId);
         if(param1 > 0)
         {
            _loc3_ = ServicePool.instance.getService(IPMService);
            _loc4_ = _loc3_.customData.pmSkillMap.getSkill(param1);
            _loc5_ = _loc4_.getSkillType();
            if(_loc5_ == PMSkillTypes.XINGHUI_WANGZHE_REAL_EXTEND_SKILL || _loc5_ == PMSkillTypes.XINGHUI_CHUAN_SHUO_BIAN_SHEN || _loc5_ == PMSkillTypes.XINGHUI_HUAN_XIANG_ZHAO_HUAN || _loc5_ == PMSkillTypes.LING_YU_FA_ZHEN_SKILL || _loc5_ == PMSkillTypes.HUN_DUN_XINGHUI_SKILL || _loc5_ == PMSkillTypes.TONG_LING_ACTIVE || _loc5_ == PMSkillTypes.ANNUAL_FEE_22_EIGHT_SKILL || _loc5_ == PMSkillTypes.ZHAN_JI_SKILL || _loc5_ == PMSkillTypes.FA_HUAN_ACTIVE_SKILL || _loc5_ == PMSkillTypes.XINGHUI_LUNHUI_SHIYUE_SPIRIT_TEJI || _loc5_ == PMSkillTypes.XINGHUI_LUNHUI_SHIYUE_ACTIVE_SKILL || _loc5_ == PMSkillTypes.GQ_GUANG_JIN_SKILL || _loc5_ == PMSkillTypes.GQ_QI_YUAN_SKILL || _loc5_ == PMSkillTypes.GQ_TIANYI_SPIRIT_SKILL || _loc5_ == PMSkillTypes.GQ_QUNXING_ZHIYU_SPIRIT_SKILL || _loc5_ == PMSkillTypes.GQ_YIREN_SPIRIT_SKILL || _loc5_ == PMSkillTypes.GQ_SHENXU_SPIRIT_SKILL || _loc5_ == PMSkillTypes.GQ_DIJIESHI_CHANGE_SKILL || _loc5_ == PMSkillTypes.GQ_XINGZHIYU_SPIRIT_SKILL || _loc5_ == PMSkillTypes.GQ_ETERNITY_ZHANYI_COMMON_SKILL || _loc5_ == PMSkillTypes
            .GQ_ETERNITY_ZHANYI_SPIRIT_SKILL || _loc5_ == PMSkillTypes.GQ_YANHUAZHIYAO_SPIRIT_SKILL || _loc5_ == PMSkillTypes.GQ_PET_FIGHT_SPACE_3_SKILL || _loc5_ == PMSkillTypes.GQ_MINGYUNBOYI_SPIRIT_SKILL || _loc5_ == PMSkillTypes.GQ_HUANLINGSHI_FIRST_SPIRIT_SKILL || _loc5_ == PMSkillTypes.GQ_WANYUZHICHAO_SPIRIT_0_SKILL || _loc5_ == PMSkillTypes.GQ_SHIKONGFANGZHU_SPIRIT_SKILL || _loc5_ == PMSkillTypes.GQ_YUXIANGSHI_FIRST_SKILL)
            {
               _loc6_ = this._operatingPlayer.myPets[0];
               this._skillUsedMap[_loc6_.id + "_" + param1] = true;
               return;
            }
            if(_loc5_ == PMSkillTypes.GQ_XIANJINGJI_SKILL)
            {
               this._skillUsedMap[FightController.instance.turnCount + "_" + param1] = true;
               return;
            }
         }
         this._hasOperatedStates[_loc2_] = true;
      }
      
      public function isSkillUsed(param1:int, param2:int) : Boolean
      {
         var _loc3_:PMSkill = this._pmSvr.customData.pmSkillMap.getSkill(param2);
         var _loc4_:* = _loc3_.getSkillType();
         var _loc5_:String = param1 + "_" + param2;
         if(_loc4_ == PMSkillTypes.GQ_XIANJINGJI_SKILL)
         {
            _loc5_ = FightController.instance.turnCount + "_" + param2;
         }
         if(Boolean(this._skillUsedMap.hasOwnProperty(_loc5_)) && Boolean(this._skillUsedMap[_loc5_]))
         {
            return true;
         }
         return false;
      }
      
      public function isOneSkillUsed(param1:int, param2:Array) : Boolean
      {
         var _loc3_:* = undefined;
         for each(_loc3_ in param2)
         {
            if(this.isSkillUsed(param1,_loc3_))
            {
               return true;
            }
         }
         return false;
      }
      
      public function setPlayerOperating(param1:int) : void
      {
         var _loc2_:PlayerBattleInfo = null;
         for each(_loc2_ in this._playerInfoList)
         {
            if(_loc2_.slotId == param1)
            {
               if(!this.haveOperateRight(_loc2_))
               {
                  this._operatingPlayer = this.getDefaultCanOperatePlayer();
                  break;
               }
               this._operatingPlayer = _loc2_;
            }
         }
      }
      
      public function init(param1:Array, param2:int) : void
      {
         var _loc4_:PlayerBattleInfo = null;
         var _loc5_:PlayerBattleInfo = null;
         var _loc6_:PetBriefInfo = null;
         var _loc7_:PMData = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc3_:IPetDataService = ServicePool.instance.getService(IPetDataService);
         this._myPMMasterId = _loc3_.getMyInfo().PMMasterId;
         for each(_loc4_ in param1)
         {
            if(param2 == -1)
            {
               if(_loc4_.PMMasterId == this._myPMMasterId)
               {
                  this._playerInfoList.push(_loc4_);
               }
            }
            else if(_loc4_.slotId == param2)
            {
               this._playerInfoList.push(_loc4_);
            }
         }
         _loc5_ = this._playerInfoList[0];
         this._myPMMasterId = _loc5_.PMMasterId;
         this._isClientPackage = _loc5_.isClientPackage;
         this._isLocalAndSlotSameSide = _loc5_.slotId <= FightData.MARK_LOCA_ID || _loc5_.slotId == FightData.SHENG_LING_POS_WE;
         this._catchLevel = _loc5_.pmCatchLevel;
         if(this.isClientPackage && !FightController.instance.isReplay)
         {
            this._myAllPetList = _loc3_.getMyPets();
         }
         else
         {
            this._myAllPetList = this.getAllPetList(this._playerInfoList);
         }
         this._operatingPlayer = this._playerInfoList[0];
         this._realTimeRoleHp = {};
         this._myPetXingHuiTypeArr = [];
         this._myPetGuangQiTypeArr = [];
         for each(_loc6_ in this.myAllPetList)
         {
            _loc7_ = this._pmSvr.getOperationPM(_loc6_.raceId).pmData;
            _loc8_ = int(_loc7_.getXinghuiType());
            if(_loc8_ > -1)
            {
               if(XinghuiPetType.MultiSysConfigObj.hasOwnProperty(_loc8_.toString()))
               {
                  this._myPetXingHuiTypeArr = this._myPetXingHuiTypeArr.concat(XinghuiPetType.MultiSysConfigObj[_loc8_.toString()]);
               }
               this._myPetXingHuiTypeArr.push(_loc8_);
            }
            _loc9_ = int(_loc7_.getGQType());
            if(_loc9_ > -1)
            {
               if(GQPetType.MultiSysConfigObj.hasOwnProperty(_loc9_.toString()))
               {
                  this._myPetGuangQiTypeArr = this._myPetGuangQiTypeArr.concat(GQPetType.MultiSysConfigObj[_loc9_.toString()]);
               }
               this._myPetGuangQiTypeArr.push(_loc9_);
            }
         }
      }
      
      private function getAllPetList(param1:Array) : Array
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc2_:Array = [];
         for each(_loc3_ in param1)
         {
            if(_loc3_.myPets.length > _loc2_.length)
            {
               _loc2_ = _loc3_.myPets;
            }
         }
         return _loc2_.concat();
      }
      
      public function get isClientPackage() : Boolean
      {
         return this._isClientPackage;
      }
      
      public function get pmCatchLevel() : int
      {
         return this._catchLevel;
      }
      
      public function get PMMasterId() : int
      {
         return this._myPMMasterId;
      }
      
      public function isLocalIdAndSlotIdSame() : Boolean
      {
         return this._isLocalAndSlotSameSide;
      }
      
      public function get playerInfos() : Array
      {
         return this._playerInfoList;
      }
      
      public function addPlayerInfos(param1:PlayerBattleInfo) : void
      {
         if(param1.PMMasterId == this._myPMMasterId)
         {
            this._playerInfoList.push(param1);
         }
      }
      
      public function delPlayerInfos(param1:PlayerBattleInfo) : void
      {
         var _loc2_:int = 0;
         if(param1.PMMasterId == this._myPMMasterId)
         {
            _loc2_ = 0;
            while(_loc2_ < this._playerInfoList.length)
            {
               if(this._playerInfoList[_loc2_].slotId == param1.slotId)
               {
                  this._playerInfoList.splice(_loc2_,1);
                  break;
               }
               _loc2_++;
            }
         }
      }
      
      public function get operatingPlayer() : PlayerBattleInfo
      {
         return this._operatingPlayer;
      }
      
      public function isMyControlSlotId(param1:int) : Boolean
      {
         var _loc2_:PlayerBattleInfo = null;
         for each(_loc2_ in this._playerInfoList)
         {
            if(_loc2_.slotId == param1)
            {
               return true;
            }
         }
         return false;
      }
      
      public function isMyControlLocalId(param1:int) : Boolean
      {
         var _loc2_:PlayerBattleInfo = null;
         for each(_loc2_ in this._playerInfoList)
         {
            if(_loc2_.locaId == param1)
            {
               return true;
            }
         }
         return false;
      }
      
      public function getMyPlayerInfoByLocalId(param1:int) : PlayerBattleInfo
      {
         var _loc2_:PlayerBattleInfo = null;
         for each(_loc2_ in this._playerInfoList)
         {
            if(_loc2_.locaId == param1)
            {
               return _loc2_;
            }
         }
         return this._playerInfoList[0];
      }
      
      public function getMyPlayerInfoBySlotId(param1:int) : PlayerBattleInfo
      {
         var _loc2_:PlayerBattleInfo = null;
         for each(_loc2_ in this._playerInfoList)
         {
            if(_loc2_.slotId == param1)
            {
               return _loc2_;
            }
         }
         return this._playerInfoList[0];
      }
      
      public function get myAllPetList() : Array
      {
         return this._myAllPetList;
      }
      
      public function getNoOperatingPlayers() : Array
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc1_:Array = [];
         for each(_loc2_ in this._playerInfoList)
         {
            if(this.haveOperateRight(_loc2_) && _loc2_.locaId != this._operatingPlayer.locaId)
            {
               _loc1_.push(_loc2_);
            }
         }
         return _loc1_;
      }
      
      public function getCanControlPlayers() : Array
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc1_:Array = [];
         for each(_loc2_ in this._playerInfoList)
         {
            if(this.haveOperateRight(_loc2_))
            {
               _loc1_.push(_loc2_);
            }
         }
         return _loc1_;
      }
      
      public function isPetInBattleFiled(param1:int) : Boolean
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:PetBriefInfo = null;
         for each(_loc2_ in this._playerInfoList)
         {
            _loc3_ = _loc2_.myPets[0] as PetBriefInfo;
            if(_loc3_.curHp > 0 && _loc3_.id == param1 && !StatusUtil.getIsAsDyingButHasHp(_loc3_))
            {
               return true;
            }
         }
         return false;
      }
      
      public function getInBattleFiledPet(param1:int) : PetBriefInfo
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:PetBriefInfo = null;
         for each(_loc2_ in this._playerInfoList)
         {
            _loc3_ = _loc2_.myPets[0] as PetBriefInfo;
            if(_loc3_.curHp > 0 && _loc3_.id == param1)
            {
               return _loc2_.myPets[0];
            }
         }
         return null;
      }
      
      public function getDieForSwitchSlots() : Array
      {
         return this._dieForSwitchSlots;
      }
      
      public function getCanSwitchUpPetsInDyingSwitch() : Array
      {
         var _loc5_:PetBriefInfo = null;
         var _loc6_:Boolean = false;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:PetBriefInfo = null;
         var _loc10_:int = 0;
         var _loc11_:PetBriefInfo = null;
         var _loc12_:* = false;
         var _loc13_:* = false;
         var _loc14_:* = false;
         var _loc15_:Boolean = false;
         var _loc16_:int = 0;
         var _loc17_:int = 0;
         var _loc18_:PetBriefInfo = null;
         var _loc1_:Array = [];
         var _loc2_:Array = [];
         var _loc3_:* = FightData.instance.myInfo;
         var _loc4_:Array = _loc3_.myAllPetList;
         for each(_loc5_ in _loc4_)
         {
            _loc10_ = int(_loc5_.id);
            _loc11_ = _loc3_.getInBattleFiledPet(_loc10_);
            if(_loc11_)
            {
               _loc14_ = _loc11_.curHp > 0;
               _loc15_ = false;
            }
            else
            {
               _loc14_ = _loc5_.curHp > 0;
               _loc15_ = true;
            }
            _loc12_ = _loc1_.indexOf(_loc10_) == -1;
            _loc13_ = !this.isPetWillSwitchUpOnDying(_loc10_);
            if(_loc14_ && _loc15_ && _loc12_ && _loc13_)
            {
               _loc1_.push(_loc10_);
               _loc2_.push(_loc5_);
            }
         }
         _loc6_ = true;
         _loc7_ = int.MAX_VALUE;
         _loc8_ = -1;
         for each(_loc9_ in _loc2_)
         {
            if(_loc9_.lockRound <= 0)
            {
               _loc6_ = false;
            }
            if(_loc9_.lockRound < _loc7_)
            {
               _loc7_ = int(_loc9_.lockRound);
               _loc8_ = int(_loc2_.indexOf(_loc9_));
            }
         }
         if(_loc6_ && _loc8_ > -1)
         {
            _loc16_ = int((_loc2_[_loc8_] as PetBriefInfo).id);
            return [_loc16_];
         }
         _loc17_ = int(_loc2_.length - 1);
         while(_loc17_ >= 0)
         {
            _loc18_ = _loc2_[_loc17_];
            if(_loc18_.lockRound > 0)
            {
               _loc1_.splice(_loc17_,1);
            }
            _loc17_--;
         }
         return _loc1_;
      }
      
      public function resetDieForSwitchSlots() : void
      {
         this._dieForSwitchSlots.length = 0;
         this._willSwitchPetsOnDying.length = 0;
      }
      
      public function haveCanSwitchUpPetOnDying() : Boolean
      {
         return this.getCanSwitchUpPetsInDyingSwitch().length > 0;
      }
      
      public function updateExtensionInfo(param1:Object) : void
      {
         this.updateRealTimeRoleHp(param1);
         this.tryInitRoundInfo(param1.pmmList);
      }
      
      private function tryInitRoundInfo(param1:Array) : void
      {
         var _loc2_:* = undefined;
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:PetBriefInfo = null;
         var _loc5_:PetBriefInfo = null;
         if(param1 == null || param1.length == 0)
         {
            return;
         }
         for each(_loc2_ in param1)
         {
            _loc3_ = new PlayerBattleInfo();
            _loc3_.parseInfo(_loc2_);
            if(FightData.instance.isMySide(_loc3_.locaId))
            {
               Tracer.doTrace("tryInitRoundInfo检测开始");
               for each(_loc4_ in _loc3_.myPets)
               {
                  Tracer.doTrace("lockRound:" + _loc4_.lockRound + "," + _loc4_.name);
                  if(_loc4_.lockRound > 0)
                  {
                     for each(_loc5_ in this._myAllPetList)
                     {
                        if(_loc5_.id == _loc4_.id)
                        {
                           _loc5_.updateLockRound(_loc4_.lockRound);
                           Tracer.doTrace("update lockRound:" + _loc5_.raceId + "," + _loc5_.name);
                           break;
                        }
                     }
                  }
               }
               Tracer.doTrace("tryInitRoundInfo检测结束");
            }
         }
      }
      
      public function updateLockRoundAndSkillUseInfo() : void
      {
         var _loc1_:PetBriefInfo = null;
         var _loc2_:Object = null;
         var _loc3_:PmInBagData = null;
         for each(_loc1_ in this._myAllPetList)
         {
            if(_loc1_.lockRound > 0)
            {
               _loc1_.updateLockRound(_loc1_.lockRound - 1);
            }
         }
         if(Boolean(this._realTimeRoleHp) && Boolean(this._realTimeRoleHp.hasOwnProperty("uqi")))
         {
            _loc2_ = this._realTimeRoleHp.uqi;
            for each(_loc3_ in _loc2_)
            {
               if(_loc3_.lockRound > 0)
               {
                  --_loc3_.lockRound;
               }
            }
         }
         this._skillUsedMap = {};
      }
      
      public function getLockRound(param1:int) : int
      {
         var _loc2_:PetBriefInfo = this._myAllPetList[param1] as PetBriefInfo;
         return _loc2_.lockRound;
      }
      
      private function updateRealTimeRoleHp(param1:Object) : void
      {
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc4_:Object = null;
         if(Boolean(param1) && Boolean(param1.pmInBagList))
         {
            this.pmInBagListHandle(param1.pmInBagList);
         }
         if(Boolean(param1) && Boolean(param1.pmmList))
         {
            _loc2_ = param1.pmmList;
         }
         else if(param1 && param1.extInfo && Boolean(param1.extInfo.pmmList))
         {
            _loc2_ = param1.extInfo.pmmList;
         }
         if(!_loc2_)
         {
            return;
         }
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.pmInBagList != undefined)
            {
               _loc4_ = _loc3_.pmInBagList;
               if(_loc4_)
               {
                  this.pmInBagListHandle(_loc4_);
               }
            }
         }
      }
      
      private function pmInBagListHandle(param1:Object) : void
      {
         var _loc2_:Object = null;
         var _loc3_:PmInBagData = null;
         var _loc4_:Object = null;
         for each(_loc2_ in param1)
         {
            if(!this._realTimeRoleHp["uqi"])
            {
               this._realTimeRoleHp["uqi"] = new Object();
            }
            _loc4_ = this._realTimeRoleHp["uqi"];
            if(!_loc4_[_loc2_.uqi])
            {
               _loc4_[_loc2_.uqi] = new PmInBagData();
            }
            _loc3_ = _loc4_[_loc2_.uqi];
            _loc3_.setData(_loc2_);
            if(!this._realTimeRoleHp["pid"])
            {
               this._realTimeRoleHp["pid"] = new Object();
            }
            this._realTimeRoleHp["pid"][_loc2_.i] = _loc3_;
         }
      }
      
      public function getRealTimeRoleHpData(param1:int, param2:int = -1) : PmInBagData
      {
         if(param1 > 0 && Boolean(this._realTimeRoleHp["uqi"]))
         {
            return this._realTimeRoleHp["uqi"][param1];
         }
         if(param2 > 0 && Boolean(this._realTimeRoleHp["pid"]))
         {
            return this._realTimeRoleHp["pid"][param2];
         }
         return null;
      }
      
      public function updateRealTimeRoleHpData(param1:int, param2:int, param3:PetBriefInfo) : void
      {
         var _loc4_:PmInBagData = null;
         var _loc5_:Object = null;
         var _loc6_:Object = null;
         if(param1 > 0)
         {
            if(!this._realTimeRoleHp["uqi"])
            {
               this._realTimeRoleHp["uqi"] = new Object();
            }
            _loc5_ = this._realTimeRoleHp["uqi"];
            if(!_loc5_[param1])
            {
               _loc5_[param1] = new PmInBagData();
            }
            _loc4_ = _loc5_[param1];
            _loc4_.setData({
               "s0":param3.maxHp,
               "c0":param3.curHp,
               "st":param3.status,
               "lock":param3.lockRound,
               "r":param3.raceId,
               "f":param3.viewId,
               "nm":param3.name,
               "nick":param3.nickname,
               "t":param3.pmAttribute,
               "t1":param3.pmAttribute2
            });
         }
         if(param2 > 0)
         {
            if(!this._realTimeRoleHp["pid"])
            {
               this._realTimeRoleHp["pid"] = new Object();
            }
            _loc6_ = this._realTimeRoleHp["pid"];
            if(!_loc6_[param2])
            {
               _loc6_[param2] = new PmInBagData();
            }
            _loc4_ = _loc6_[param2];
            _loc4_.setData({
               "s0":param3.maxHp,
               "c0":param3.curHp,
               "st":param3.status,
               "lock":param3.lockRound,
               "r":param3.raceId,
               "f":param3.viewId,
               "nm":param3.name,
               "nick":param3.nickname,
               "t":param3.pmAttribute,
               "t1":param3.pmAttribute2
            });
         }
      }
      
      public function getIsMyPetListContainXinghuiPetType(param1:int) : Boolean
      {
         return ArrayUtil.arrayContainsValue(this._myPetXingHuiTypeArr,param1);
      }
      
      public function getIsMyPetListContainGuangQiPetType(param1:int) : Boolean
      {
         return ArrayUtil.arrayContainsValue(this._myPetGuangQiTypeArr,param1);
      }
   }
}

