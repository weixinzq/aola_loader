package mmo.petfightnew.common
{
   import flash.display.DisplayObject;
   import flash.system.ApplicationDomain;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.shareobject.LocalStore;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.FightMode;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.SubDomain;
   import mmo.petfightnew.common.config.ForceCanCatchConfig;
   import mmo.petfightnew.common.constant.FightSize;
   import mmo.petfightnew.common.data.MyInfo;
   import mmo.petfightnew.common.pet.PetFace;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.petfight.common.PetMovieStrategyType;
   import mmo.play.petfight.common.config.FightResConfig;
   
   public class FightData
   {
      
      private static var _instance:FightData;
      
      public static const SHENG_LING_POS_WE:int = 12;
      
      public static const SHENG_LING_POS_ENEMY:int = 13;
      
      public static const SLOT_NUM:int = 12;
      
      public static const MARK_LOCA_ID:int = 5;
      
      public static const MAX_LOCA_ID:int = SLOT_NUM - 1;
      
      public static const MIN_LOCA_ID:int = 0;
      
      public static const HuanLingShiFirstSkillKey:String = "HuanLingShiFirstSkillKey";
      
      public static var fightMode:int = FightMode.NORMAL;
      
      public static var startMovieInfo:Object = {};
      
      public static const ChangZhuVisibleKey:String = "petfightnew_NewStatusIconList_ChangZhuVisible";
      
      private var _playerInfos:Array = [];
      
      private var _teammates:Array = [];
      
      private var _opponents:Array = [];
      
      private var _teamScale:Number = 1;
      
      private var _petScale:Number = 1;
      
      private var _targetSlot:int = 11;
      
      private var _vsSlot:int = 11;
      
      private var _fightNum:int;
      
      public var challengeNpcId:int = -1;
      
      public var npcName:String = "";
      
      public var bs:String = "";
      
      public var curBs:String = "";
      
      public var xueJiSlotId:int = -1;
      
      private var _fightTitle:DisplayObject = null;
      
      private var aiNameIndex:int = 0;
      
      public var myAiNameArr:Array;
      
      public var joinInfoStr:String;
      
      private var _domain:ApplicationDomain;
      
      private var _replayId:int = 0;
      
      private var _isLowQuality:Boolean = false;
      
      private var _qualityBeforeFight:Boolean = false;
      
      private var _fightActId:int = -1;
      
      private var _haveSummonPet:Boolean = false;
      
      private var _haveXinghuiPet:Boolean = false;
      
      private var _haveGQPet:Boolean = false;
      
      private var _fightSize:int = 0;
      
      private var _myInfo:MyInfo = null;
      
      private var _canControlPetNum:int = 1;
      
      private var _battleId:int = 0;
      
      private var _isPVE:Boolean;
      
      private var _fetterEffect:Array = null;
      
      private var _petMovieStrategyType:int;
      
      private var _modeScale:Number;
      
      private var _liHuiArr:Array;
      
      private var _fightSignInArr:Array;
      
      private var _fightEndPbi:PetBriefInfo = null;
      
      private var _isPFSShenHuanFight:Boolean = false;
      
      private var _isPFS2v2:Boolean = false;
      
      private var _isPFS3KuangBao:Boolean = false;
      
      private var _extData:Object = {};
      
      private var _isInSmallTurn:Boolean = false;
      
      private var _animationSpeedPercent:int = 100;
      
      private var _forceAutoCount:int = 0;
      
      private var _fightType:int = 0;
      
      private var _isChangZhuVisible:Boolean = LocalStore.getValue(ChangZhuVisibleKey);
      
      public function FightData()
      {
         super();
         this.initDomain();
      }
      
      public static function get instance() : FightData
      {
         if(_instance == null)
         {
            _instance = new FightData();
         }
         return _instance;
      }
      
      public static function isSameSide(param1:int, param2:int) : Boolean
      {
         return param1 > MARK_LOCA_ID && param2 > MARK_LOCA_ID || param1 <= MARK_LOCA_ID && param2 <= MARK_LOCA_ID || param1 > MARK_LOCA_ID && param2 == SHENG_LING_POS_ENEMY || param2 > MARK_LOCA_ID && param1 == SHENG_LING_POS_ENEMY || param1 <= MARK_LOCA_ID && param2 == SHENG_LING_POS_WE || param2 <= MARK_LOCA_ID && param1 == SHENG_LING_POS_WE;
      }
      
      public function get applicationDomain() : ApplicationDomain
      {
         if(this._domain == null)
         {
            this.initDomain();
         }
         return this._domain;
      }
      
      public function getPetViewDomain() : ResDomain
      {
         return SubDomain.getInstance().getPetViewDomain();
      }
      
      private function initDomain() : void
      {
         this._domain = new ApplicationDomain(ApplicationDomain.currentDomain);
         this._extData = {};
      }
      
      public function isMySide(param1:int) : Boolean
      {
         return param1 <= MARK_LOCA_ID || param1 == SHENG_LING_POS_WE;
      }
      
      public function get isLowQuality() : Boolean
      {
         return this._isLowQuality;
      }
      
      public function getBitmapQuality() : int
      {
         return this._isLowQuality ? 80 : 100;
      }
      
      public function set isLowQuality(param1:Boolean) : void
      {
         this._isLowQuality = param1;
      }
      
      public function getFaceIdByLocalId(param1:int) : int
      {
         if(this.isMySide(param1))
         {
            return PetFace.BACK;
         }
         return PetFace.POSITIVE;
      }
      
      public function getLocaIdByUserId(param1:int) : int
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc2_:int = -1;
         for each(_loc3_ in this._playerInfos)
         {
            if(param1 == _loc3_.PMMasterId)
            {
               _loc2_ = int(_loc3_.locaId);
               break;
            }
         }
         return _loc2_;
      }
      
      public function getUserIdByLocalId(param1:int) : int
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc2_:int = -1;
         for each(_loc3_ in this._playerInfos)
         {
            if(param1 == _loc3_.locaId)
            {
               _loc2_ = int(_loc3_.PMMasterId);
               break;
            }
         }
         return _loc2_;
      }
      
      public function setFightData(param1:Array, param2:int = -1) : void
      {
         var _loc3_:PlayerBattleInfo = null;
         this.initMyInfo(param1,param2);
         this._playerInfos = [];
         for each(_loc3_ in param1)
         {
            this.addPlayer(_loc3_);
         }
         if(!this._myInfo.isLocalIdAndSlotIdSame())
         {
            this._targetSlot = MIN_LOCA_ID;
            this._vsSlot = MIN_LOCA_ID;
         }
         this._fightNum = param1.length;
         this.initFightSize();
         this._petScale = 0.6;
         this._petMovieStrategyType = PetMovieStrategyType.BITMAP;
         if(this._fightSize == FightSize.SIX_VS_SIX)
         {
            this._teamScale = 0.4;
         }
         else if(this._fightSize != FightSize.ONE_VS_ONE && this._fightSize != FightSize.XH_ONE_VS_ONE)
         {
            this._teamScale = 0.4;
         }
         else if(this._fightSize == FightSize.XH_ONE_VS_ONE)
         {
            this._teamScale = 0.65;
         }
         else
         {
            this._teamScale = 0.65;
         }
         this.checkCatchable();
      }
      
      private function initFightSize() : void
      {
         if(this.isFetterEffect)
         {
            this._fightSize = FightSize.SIX_VS_SIX;
         }
         else if(this._fightNum == 2 && (this._haveXinghuiPet || this._haveGQPet) && !this._haveSummonPet)
         {
            this._fightSize = FightSize.XH_ONE_VS_ONE;
         }
         else if(this._fightNum == 2 && !this._haveSummonPet)
         {
            this._fightSize = FightSize.ONE_VS_ONE;
         }
         else if(this._fightNum == 4 && this._teammates.length == 2 && !this._haveSummonPet)
         {
            this._fightSize = FightSize.TWO_VS_TWO;
         }
         else if(this._fightNum == 5)
         {
            this._fightSize = FightSize.TWO_VS_THREE;
         }
         else
         {
            this._fightSize = FightSize.THREE_VS_THREE;
         }
      }
      
      public function addPlayer(param1:PlayerBattleInfo) : void
      {
         param1.locaId = this.getLocaId(param1.slotId);
         this._playerInfos[param1.slotId] = param1;
         if(this.isMySide(param1.locaId))
         {
            this._teammates.push(param1);
         }
         else
         {
            this._opponents.push(param1);
         }
         var _loc2_:int = int((param1.myPets[0] as PetBriefInfo).raceId);
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FightAddPlayer,{
            "raceId":_loc2_,
            "locaId":param1.locaId
         }));
      }
      
      public function getMySidePetList() : Array
      {
         return this.getPetList(this._teammates);
      }
      
      public function getOpponentSidePetList() : Array
      {
         return this.getPetList(this._opponents);
      }
      
      private function getPetList(param1:Array) : Array
      {
         var _loc6_:PlayerBattleInfo = null;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         while(_loc5_ < param1.length)
         {
            _loc6_ = param1[_loc5_];
            if(_loc6_ != null && _loc6_.myPets != null && _loc6_.myPets.length > _loc4_)
            {
               if(_loc6_.myPets.length > _loc3_)
               {
                  _loc2_ = _loc5_;
                  _loc3_ = int(_loc6_.myPets.length);
               }
            }
            _loc5_++;
         }
         return (param1[_loc2_] as PlayerBattleInfo).myPets;
      }
      
      public function getInBattleFiledPetBySide(param1:Boolean) : Array
      {
         var _loc4_:PlayerBattleInfo = null;
         var _loc2_:Array = param1 ? this._teammates : this._opponents;
         var _loc3_:Array = [];
         for each(_loc4_ in _loc2_)
         {
            if(Boolean(_loc4_) && Boolean(_loc4_.myPets))
            {
               _loc3_.push((_loc4_.myPets[0] as PetBriefInfo).Clone());
            }
         }
         return _loc3_;
      }
      
      private function initMyInfo(param1:Array, param2:int) : void
      {
         this._myInfo = new MyInfo();
         this._myInfo.init(param1,param2);
      }
      
      public function checkCatchable() : void
      {
         var _loc1_:PlayerBattleInfo = null;
         FightController.instance.canCatch = FightController.instance.isCatchablePet;
         for each(_loc1_ in this._playerInfos)
         {
            if(this.isMySide(_loc1_.locaId))
            {
               if(!(_loc1_.locaId == 0 || _loc1_.PMMasterId < 0))
               {
                  FightController.instance.canCatch = false;
                  break;
               }
            }
            else
            {
               if(_loc1_.PMMasterId > 0)
               {
                  FightController.instance.canCatch = false;
                  break;
               }
               if(_loc1_.myPets[0].raceId > 5000 && ForceCanCatchConfig.canCatchIdArr.indexOf(_loc1_.myPets[0].raceId) == -1)
               {
                  FightController.instance.canCatch = false;
                  break;
               }
            }
         }
      }
      
      public function setLocaId(param1:PlayerBattleInfo) : PlayerBattleInfo
      {
         if(param1.slotId == SHENG_LING_POS_WE || param1.slotId == SHENG_LING_POS_ENEMY)
         {
            if(this._myInfo.isLocalIdAndSlotIdSame())
            {
               param1.locaId = param1.slotId;
            }
            else
            {
               param1.locaId = param1.slotId == SHENG_LING_POS_WE ? SHENG_LING_POS_ENEMY : SHENG_LING_POS_WE;
            }
         }
         else if(this._myInfo.isLocalIdAndSlotIdSame())
         {
            param1.locaId = param1.slotId;
         }
         else
         {
            param1.locaId = MAX_LOCA_ID - param1.slotId;
         }
         return param1;
      }
      
      public function getSlotId(param1:int) : int
      {
         var _loc2_:int = 0;
         if(param1 == SHENG_LING_POS_WE || param1 == SHENG_LING_POS_ENEMY)
         {
            if(this._myInfo.isLocalIdAndSlotIdSame())
            {
               _loc2_ = param1;
            }
            else
            {
               _loc2_ = param1 == SHENG_LING_POS_WE ? SHENG_LING_POS_ENEMY : SHENG_LING_POS_WE;
            }
         }
         else if(this._myInfo.isLocalIdAndSlotIdSame())
         {
            _loc2_ = param1;
         }
         else
         {
            _loc2_ = MAX_LOCA_ID - param1;
         }
         return _loc2_;
      }
      
      public function getLocaId(param1:int) : int
      {
         var _loc2_:int = 0;
         if(param1 == SHENG_LING_POS_WE || param1 == SHENG_LING_POS_ENEMY)
         {
            if(this._myInfo.isLocalIdAndSlotIdSame())
            {
               _loc2_ = param1;
            }
            else
            {
               _loc2_ = param1 == SHENG_LING_POS_WE ? SHENG_LING_POS_ENEMY : SHENG_LING_POS_WE;
            }
         }
         else if(this._myInfo.isLocalIdAndSlotIdSame())
         {
            _loc2_ = param1;
         }
         else
         {
            _loc2_ = MAX_LOCA_ID - param1;
         }
         return _loc2_;
      }
      
      public function get playerInfo() : Array
      {
         return this._playerInfos;
      }
      
      public function getPlayerInfoBySlotId(param1:int) : PlayerBattleInfo
      {
         return this._playerInfos[param1];
      }
      
      public function getPlayerInfoByLocalId(param1:int) : PlayerBattleInfo
      {
         return this.getPlayerInfoBySlotId(this.getSlotId(param1));
      }
      
      public function get teammates() : Array
      {
         return this._teammates;
      }
      
      public function get opponents() : Array
      {
         return this._opponents;
      }
      
      public function getCanBattlePlayerNum(param1:Array) : int
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:PetBriefInfo = null;
         var _loc2_:int = 0;
         for each(_loc3_ in param1)
         {
            _loc4_ = _loc3_.myPets[0];
            if(_loc4_ != null && _loc4_.curHp > 0)
            {
               _loc2_++;
            }
         }
         return _loc2_;
      }
      
      public function getCanBattleSlot(param1:Array) : int
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:PetBriefInfo = null;
         for each(_loc2_ in param1)
         {
            _loc3_ = _loc2_.myPets[0];
            if(_loc3_ != null && _loc3_.curHp > 0)
            {
               return _loc2_.slotId;
            }
         }
         return -1;
      }
      
      public function get fightNum() : int
      {
         return this._fightNum;
      }
      
      public function get teamScale() : Number
      {
         return this._teamScale;
      }
      
      public function set targetSlot(param1:int) : *
      {
         this._targetSlot = param1;
      }
      
      public function get targetSlot() : int
      {
         return this._targetSlot;
      }
      
      public function get vsSlot() : int
      {
         return this._vsSlot;
      }
      
      public function delPlayer(param1:int, param2:Boolean = true) : void
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc3_:PlayerBattleInfo = this._playerInfos[param1];
         if(this.isMySide(_loc3_.locaId))
         {
            _loc4_ = 0;
            while(_loc4_ < this._teammates.length)
            {
               if(this._teammates[_loc4_].locaId == _loc3_.locaId)
               {
                  this._teammates.splice(_loc4_,1);
               }
               _loc4_++;
            }
         }
         else
         {
            _loc5_ = 0;
            while(_loc5_ < this._opponents.length)
            {
               if(this._opponents[_loc5_].locaId == _loc3_.locaId)
               {
                  this._opponents.splice(_loc5_,1);
               }
               _loc5_++;
            }
         }
         delete this._playerInfos[param1];
         if(param2)
         {
            --this._fightNum;
         }
      }
      
      public function dispose() : void
      {
         this._domain = null;
         _instance = null;
      }
      
      public function saveFightTitleView(param1:DisplayObject) : void
      {
         this._fightTitle = param1;
      }
      
      public function getFightTitleView() : DisplayObject
      {
         return this._fightTitle;
      }
      
      public function popFightTitleView() : DisplayObject
      {
         var _loc1_:DisplayObject = this._fightTitle;
         this._fightTitle = null;
         return _loc1_;
      }
      
      public function getNextAiName() : String
      {
         if(this.myAiNameArr == null)
         {
            return null;
         }
         var _loc1_:String = this.myAiNameArr[this.aiNameIndex] as String;
         ++this.aiNameIndex;
         return _loc1_;
      }
      
      public function get replayId() : int
      {
         return this._replayId;
      }
      
      public function set replayId(param1:int) : void
      {
         this._replayId = param1;
      }
      
      public function get fightActId() : int
      {
         return this._fightActId;
      }
      
      public function set fightActId(param1:int) : void
      {
         this._fightActId = param1;
      }
      
      public function get haveSummonPet() : Boolean
      {
         return this._haveSummonPet;
      }
      
      public function set haveSummonPet(param1:Boolean) : void
      {
         this._haveSummonPet = param1;
      }
      
      public function get haveXinghuiPet() : Boolean
      {
         return this._haveXinghuiPet;
      }
      
      public function set haveXinghuiPet(param1:Boolean) : void
      {
         this._haveXinghuiPet = param1;
      }
      
      public function get haveGQPet() : Boolean
      {
         return this._haveGQPet;
      }
      
      public function set haveGQPet(param1:Boolean) : void
      {
         this._haveGQPet = param1;
      }
      
      public function get fightSize() : int
      {
         return this._fightSize;
      }
      
      public function getPetVisionScale() : Number
      {
         if(this._fightType != 11)
         {
            return this._petScale;
         }
         return 1;
      }
      
      public function getPetScale(param1:int) : Number
      {
         if(FightResConfig.isSpinePetMovie(param1))
         {
            if(FightResConfig.isOldStyleSpinePet(param1))
            {
               return 0.7;
            }
            if(FightResConfig.isNoScalePet(param1))
            {
               return 1;
            }
            return 0.6;
         }
         return this._petScale;
      }
      
      public function getPetHitDistanceScale(param1:int) : Number
      {
         if(FightResConfig.isSpinePetMovie(param1))
         {
            if(FightResConfig.isOldStyleSpinePet(param1))
            {
               return 0.7;
            }
            return 1;
         }
         if(this._fightType != 11)
         {
            return this._petScale;
         }
         return 1;
      }
      
      public function get canControlPetNum() : int
      {
         return this._canControlPetNum;
      }
      
      public function set canControlPetNum(param1:int) : void
      {
         this._canControlPetNum = param1;
      }
      
      public function get myInfo() : MyInfo
      {
         return this._myInfo;
      }
      
      public function isSummonedPetOfLocalPosition(param1:int) : Boolean
      {
         var _loc2_:PlayerBattleInfo = null;
         if(this._fightSize == FightSize.SIX_VS_SIX)
         {
            _loc2_ = this.getPlayerInfoBySlotId(this.getSlotId(param1));
            return _loc2_ != null && Boolean(_loc2_.isSummoned());
         }
         return param1 >= 3 && param1 <= MARK_LOCA_ID || param1 <= 8 && param1 > MARK_LOCA_ID || param1 == SHENG_LING_POS_WE || param1 == SHENG_LING_POS_ENEMY;
      }
      
      public function isSummonedPlayer(param1:PlayerBattleInfo) : Boolean
      {
         var _loc2_:int = 0;
         if(this._fightSize == FightSize.SIX_VS_SIX)
         {
            return param1 != null && Boolean(param1.isSummoned());
         }
         if(StatusUtil.getIsInLiangziXinglianState(param1.myPets[0]) || StatusUtil.getIsInTuichuLiangziXinglianState(param1.myPets[0]))
         {
            return false;
         }
         if(StatusUtil.getIsInHunDunJueDouState(param1.myPets[0]))
         {
            return false;
         }
         _loc2_ = int(param1.locaId);
         return _loc2_ >= 3 && _loc2_ <= MARK_LOCA_ID || _loc2_ <= 8 && _loc2_ > MARK_LOCA_ID || _loc2_ == SHENG_LING_POS_WE || _loc2_ == SHENG_LING_POS_ENEMY;
      }
      
      public function isMySideHaveSummonPetInBattleField() : Boolean
      {
         var _loc1_:PlayerBattleInfo = null;
         for each(_loc1_ in this._teammates)
         {
            if(this.isSummonedPlayer(_loc1_) && _loc1_.myPets[0] != null && _loc1_.myPets[0].curHp > 0)
            {
               return true;
            }
         }
         return false;
      }
      
      public function isMultiControl() : Boolean
      {
         return this._canControlPetNum > 1;
      }
      
      public function get battleId() : int
      {
         return this._battleId;
      }
      
      public function set battleId(param1:int) : void
      {
         this._battleId = param1;
      }
      
      public function get isPVE() : Boolean
      {
         return this._isPVE;
      }
      
      public function set isPVE(param1:Boolean) : void
      {
         this._isPVE = param1;
      }
      
      public function get isFetterEffect() : Boolean
      {
         return this._fetterEffect != null;
      }
      
      public function get fetterEffect() : Array
      {
         return this._fetterEffect;
      }
      
      public function set fetterEffect(param1:Array) : void
      {
         this._fetterEffect = param1;
      }
      
      public function getPetMovieStrategyType(param1:int) : int
      {
         if(FightData.instance.fightType == 11 && (this._petMovieStrategyType == PetMovieStrategyType.VECTORGRAPH || param1 <= FightResConfig.PET_BITMAP_MOVIE_START_RACE_ID && param1 != FightResConfig.DEFAULT_PET_ID))
         {
            return PetMovieStrategyType.VECTORGRAPH;
         }
         return PetMovieStrategyType.BITMAP;
      }
      
      public function getOperatingPet() : PetBriefInfo
      {
         return FightData.instance.myInfo.operatingPlayer.myPets[0];
      }
      
      public function setLiHuiArr(param1:String) : void
      {
         var _loc4_:String = null;
         var _loc5_:Array = null;
         this._liHuiArr = [];
         var _loc2_:Array = param1.split(",");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(_loc4_ != "")
            {
               _loc5_ = _loc4_.split("=");
               if(parseInt(_loc5_[0]) == this._myInfo.PMMasterId)
               {
                  this._liHuiArr.unshift(parseInt(_loc5_[1]));
               }
               else
               {
                  this._liHuiArr.push(parseInt(_loc5_[1]));
               }
            }
            _loc3_++;
         }
         if(this._liHuiArr.length == 0)
         {
            this._liHuiArr = [0,0];
         }
         else if(this._liHuiArr.length == 1)
         {
            this._liHuiArr.push(0);
         }
      }
      
      public function setFightSignInArr(param1:String) : void
      {
         var _loc4_:String = null;
         var _loc5_:Array = null;
         this._fightSignInArr = [];
         var _loc2_:Array = param1.split(",");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(_loc4_ != "")
            {
               _loc5_ = _loc4_.split("=");
               if(parseInt(_loc5_[0]) == this._myInfo.PMMasterId)
               {
                  this._fightSignInArr.unshift(parseInt(_loc5_[1]));
               }
               else
               {
                  this._fightSignInArr.push(parseInt(_loc5_[1]));
               }
            }
            _loc3_++;
         }
         if(this._fightSignInArr.length == 0)
         {
            this._fightSignInArr = [0,0];
         }
         else if(this._fightSignInArr.length == 1)
         {
            this._fightSignInArr.push(0);
         }
      }
      
      public function getLiHui() : Array
      {
         return this._liHuiArr;
      }
      
      public function getFightSignIn() : Array
      {
         return this._fightSignInArr;
      }
      
      public function get fightEndPbi() : PetBriefInfo
      {
         return this._fightEndPbi;
      }
      
      public function set fightEndPbi(param1:PetBriefInfo) : void
      {
         this._fightEndPbi = param1;
      }
      
      public function get isPFSShenHuanFight() : Boolean
      {
         return this._isPFSShenHuanFight;
      }
      
      public function set isPFSShenHuanFight(param1:Boolean) : void
      {
         this._isPFSShenHuanFight = param1;
      }
      
      public function get extData() : Object
      {
         return this._extData;
      }
      
      public function set extData(param1:Object) : void
      {
         this._extData = param1;
      }
      
      public function get isPFS2v2() : Boolean
      {
         return this._isPFS2v2;
      }
      
      public function set isPFS2v2(param1:Boolean) : void
      {
         this._isPFS2v2 = param1;
      }
      
      public function get isPFS3KuangBao() : Boolean
      {
         return this._isPFS3KuangBao;
      }
      
      public function set isPFS3KuangBao(param1:Boolean) : void
      {
         this._isPFS3KuangBao = param1;
      }
      
      public function get animationSpeedPercent() : int
      {
         return this._animationSpeedPercent;
      }
      
      public function set animationSpeedPercent(param1:int) : void
      {
         this._animationSpeedPercent = param1;
      }
      
      public function get isInSmallTurn() : Boolean
      {
         return this._isInSmallTurn;
      }
      
      public function set isInSmallTurn(param1:Boolean) : void
      {
         this._isInSmallTurn = param1;
      }
      
      public function get forceAutoCount() : int
      {
         return this._forceAutoCount;
      }
      
      public function set forceAutoCount(param1:int) : void
      {
         this._forceAutoCount = param1;
      }
      
      public function get isPVPForceAuto() : Boolean
      {
         return !FightData.instance.isPVE && this._forceAutoCount >= 2;
      }
      
      public function get isChangZhuVisible() : Boolean
      {
         return this._isChangZhuVisible;
      }
      
      public function set isChangZhuVisible(param1:Boolean) : void
      {
         this._isChangZhuVisible = param1;
         LocalStore.setValue(ChangZhuVisibleKey,this._isChangZhuVisible);
      }
      
      public function get fightType() : int
      {
         return this._fightType;
      }
      
      public function set fightType(param1:int) : void
      {
         this._fightType = param1;
      }
   }
}

