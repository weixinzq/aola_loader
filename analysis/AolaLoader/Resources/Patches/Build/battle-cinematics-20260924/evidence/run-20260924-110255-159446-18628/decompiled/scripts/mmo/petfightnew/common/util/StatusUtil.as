package mmo.petfightnew.common.util
{
   import com.adobe.utils.ArrayUtil;
   import com.adobe.utils.StringUtil;
   import mmo.common.utils.bit.BitUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.degenerator.DegeneratorPetType;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.gq.shenbing.GQShenBingObjHelper;
   import mmo.interfaces.legend.LegendPetType;
   import mmo.interfaces.material.crystalkey.ICrystalKeyService;
   import mmo.interfaces.material.godcard.GodCardTipsHelper;
   import mmo.interfaces.material.tote.IToteService;
   import mmo.interfaces.material.tote.ToteConfig;
   import mmo.interfaces.material.tote.ToteData;
   import mmo.interfaces.material.tote.ToteEntryData;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.GQJiangShenSkillParse;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.fight.IPetFightConfig;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.play.actthings.helper.ActStrHelper;
   import mmo.play.actthings.obj.ActArrHelper;
   import mmo.play.petfight.common.config.PetCardSuitConfig;
   import mmo.play.petfight.common.config.StampConfig;
   import mmo.play.petfight.commonbuff.CommonBuffHelper;
   
   public class StatusUtil
   {
      
      private static const SHEN_BEN_STATUS_PRE:String = "godArm";
      
      private static const CHANGE_VIEW_STATUS_PRE:String = "skc";
      
      private static const DEGENERATOR_CHANGE_VIEW_STATUS_PRE:String = "sdm";
      
      private static const GQ_TUJIAN:String = "gqzs";
      
      private static const GQ_SHENBING:String = "gqga";
      
      private static const ZHAO_HUAN_SHI_PRE:String = "summonerBuffId_";
      
      private static const GQ_SHENGBIG_FRAMES:Array = [184,185];
      
      private static var iPetfightConfig:IPetFightConfig = ServicePool.instance.getService("PetFightService") as IPetFightConfig;
      
      private static var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService) as IGameOptionService;
      
      private static var _pmSvr:IPMService = ServicePool.instance.getService(IPMService) as IPMService;
      
      private static var frames:Array = [];
      
      private static var tipsArr:Array = [];
      
      private static var detailTipsArr:Array = [];
      
      private static const ZHANYI_BUFF1:String = "warthP0";
      
      private static const ZHANYI_BUFF2:String = "warthP1";
      
      private static const ZHANYI_BUFF3:String = "warthP2";
      
      public static const ZHANYI_BUFF_ADDNUMARY:Array = [[600,600,600,600,600,200,200,200,200,200],[300,300,300,300,300,100,100,100,100,100],[3000,3000,3000,3000,3000,1000,1000,1000,1000,1000]];
      
      public static const SKILL_ROUND_BUFF:Array = ["yxww","sswz","wlkq","lmfz","fyyj","hpzf1","hpzf2","mxf1","jlb","mhyj"];
      
      private static const ToteKey:String = "xdwct";
      
      private static const ToteFrame:int = 265;
      
      private static const CRYSTAL_KEY_KEY:String = "ctkbuff";
      
      private static const CRYSTAL_KEY_FRAME:int = 266;
      
      public static const SpecialStatusArr:Array = [{
         "preStr":"cbf_1494",
         "startFrame":130
      },{
         "preStr":"xl250829",
         "frame":134,
         "scale":1
      },{
         "preStr":"dcc250905",
         "frame":135,
         "scale":1
      },{
         "preStr":"cbf_1517",
         "frame":136,
         "scale":1
      },{
         "preStr":"cbf_1518",
         "frame":137,
         "scale":1
      },{
         "preStr":"cbf_1522",
         "frame":138,
         "scale":1
      },{
         "preStr":"cbf_1526",
         "frame":139,
         "scale":1
      },{
         "preStr":"cbf_1527",
         "frame":140,
         "scale":1
      },{
         "preStr":"cbf_1528",
         "frame":141,
         "scale":1
      },{
         "preStr":"cbf_1533",
         "frame":142,
         "scale":1
      },{
         "preStr":"cbf_1534",
         "frame":143,
         "scale":1
      },{
         "preStr":"cbf_1535",
         "frame":144,
         "scale":1
      },{
         "preStr":"cbf_1536",
         "frame":145,
         "scale":1
      },{
         "preStr":"cbf_1540",
         "frame":146,
         "scale":1
      },{
         "preStr":"cbf_1541",
         "frame":147,
         "scale":1
      },{
         "preStr":"cbf_1542",
         "frame":148,
         "scale":1
      },{
         "preStr":"cbf_1543",
         "frame":149,
         "scale":1
      },{
         "preStr":"cbf_1544",
         "frame":150,
         "scale":1
      },{
         "preStr":"cbf_1563",
         "frame":151,
         "scale":1
      },{
         "preStr":"cbf_1564",
         "frame":152,
         "scale":1
      },{
         "preStr":"cbf_1565",
         "frame":153,
         "scale":1
      },{
         "preStr":"cbf_1566",
         "frame":154,
         "scale":1
      },{
         "preStr":"cbf_1567",
         "frame":155,
         "scale":1
      }];
      
      public static const SpecialStatusFrameArr:Array = [12,13,14,15,17,26,27,28,29,30,31,32,33,40,45,46,47];
      
      public static const SkillWindWordArr:Array = [{
         "effectId":100,
         "frame":1
      },{
         "effectId":101,
         "frame":2
      },{
         "effectId":102,
         "frame":3
      },{
         "effectId":103,
         "frame":4
      },{
         "effectId":104,
         "frame":5
      },{
         "effectId":105,
         "frame":6
      },{
         "effectId":106,
         "frame":7
      },{
         "effectId":1001,
         "frame":8
      },{
         "effectId":1002,
         "frame":9
      },{
         "effectId":1003,
         "frame":10
      },{
         "effectId":1004,
         "frame":11
      },{
         "effectId":1005,
         "frame":12
      },{
         "effectId":1006,
         "frame":13
      },{
         "effectId":1007,
         "frame":14
      },{
         "effectId":1008,
         "frame":15
      },{
         "effectId":1009,
         "frame":16
      },{
         "effectId":1010,
         "frame":17
      },{
         "effectId":1011,
         "frame":18
      },{
         "effectId":1012,
         "frame":19
      },{
         "effectId":1013,
         "frame":20
      },{
         "effectId":1014,
         "frame":21
      },{
         "effectId":1015,
         "frame":22
      },{
         "effectId":1016,
         "frame":23
      },{
         "effectId":1017,
         "frame":24
      },{
         "effectId":1018,
         "frame":25
      },{
         "effectId":1019,
         "frame":26
      },{
         "effectId":1020,
         "frame":27
      },{
         "effectId":1021,
         "frame":28
      },{
         "effectId":1022,
         "frame":29
      },{
         "effectId":1023,
         "frame":30
      },{
         "effectId":1024,
         "frame":31
      },{
         "effectId":1025,
         "frame":32
      },{
         "effectId":1026,
         "frame":33
      },{
         "effectId":1027,
         "frame":34
      },{
         "effectId":1028,
         "frame":35
      },{
         "effectId":1029,
         "frame":36
      },{
         "effectId":1030,
         "frame":37
      },{
         "effectId":1031,
         "frame":38
      },{
         "effectId":1032,
         "frame":39
      },{
         "effectId":1033,
         "frame":40
      },{
         "effectId":1034,
         "frame":41
      },{
         "effectId":1035,
         "frame":42
      },{
         "effectId":1036,
         "frame":43
      },{
         "effectId":1037,
         "frame":44
      },{
         "effectId":1038,
         "frame":45
      },{
         "effectId":1039,
         "frame":46
      },{
         "effectId":1040,
         "frame":47
      },{
         "effectId":1041,
         "frame":48
      },{
         "effectId":1042,
         "frame":49
      },{
         "effectId":1049,
         "frame":50
      },{
         "effectId":1050,
         "frame":51
      },{
         "effectId":1051,
         "frame":52
      },{
         "effectId":1052,
         "frame":53
      },{
         "effectId":1053,
         "frame":54
      }];
      
      public function StatusUtil()
      {
         super();
      }
      
      public static function getCommonBuffSpcialStatusFrame(param1:String, param2:int) : int
      {
         var _loc3_:int = parseInt(param1.split("_")[3]);
         if(_loc3_ == 100)
         {
            return param2 + 3;
         }
         if(_loc3_ == 0)
         {
            return 0;
         }
         return int(_loc3_ / 25) + param2;
      }
      
      public static function get noMovieStatusArr() : Array
      {
         return iPetfightConfig.statusUtilNoMovieStatusArr;
      }
      
      public static function isUpView(param1:String) : Boolean
      {
         return iPetfightConfig.statusUtilUpViewStateArr.indexOf(param1) != -1;
      }
      
      public static function getFrame(param1:String) : int
      {
         frames = iPetfightConfig.statusUtilFrames;
         var _loc2_:int = 0;
         if(StampConfig.checkIsStampStatus(param1))
         {
            _loc2_ = int(StampConfig.getStampStatusFrame(param1));
         }
         else if(frames.hasOwnProperty(param1))
         {
            _loc2_ = int(frames[param1]);
         }
         else if(isShenBenStatus(param1))
         {
            _loc2_ = int(frames[SHEN_BEN_STATUS_PRE]);
         }
         else if(isZhanYiStatus(param1))
         {
            _loc2_ = int(frames[param1.split("_")[0]]);
         }
         else if(isSkillRoundBuffStatus(param1))
         {
            _loc2_ = int(frames[param1.split("_")[0]]);
         }
         else if(isGQSkillWindWord(param1))
         {
            _loc2_ = parseInt(param1.split("_")[1]);
         }
         else if(isGQTujian(param1))
         {
            _loc2_ = int(frames[param1.split("_")[0]]);
         }
         else if(isGQShenBingStatus(param1))
         {
            _loc2_ = int(GQ_SHENGBIG_FRAMES[GQShenBingObjHelper.getTypeByRaceId(parseInt(param1.split("_")[1])) - 1]);
         }
         else if(isToteStatus(param1))
         {
            _loc2_ = ToteFrame;
         }
         else if(isCrystalKeyStatus(param1))
         {
            _loc2_ = CRYSTAL_KEY_FRAME;
         }
         else if(PetCardSuitConfig.checkIsPetcardSuitStatus(param1))
         {
            _loc2_ = int(PetCardSuitConfig.getPetcardSuitStatusFrame(param1));
         }
         return _loc2_;
      }
      
      public static function getTips(param1:String) : String
      {
         if(isLegendFieldStatus(param1))
         {
            return "";
         }
         if(StampConfig.checkIsStampStatus(param1))
         {
            return StampConfig.getTipsTitle(param1);
         }
         tipsArr = iPetfightConfig.statusUtilTipsArr;
         if(isShenBenStatus(param1))
         {
            return tipsArr[SHEN_BEN_STATUS_PRE];
         }
         if(isZhanYiStatus(param1))
         {
            return tipsArr[param1.split("_")[0]];
         }
         if(isToteStatus(param1))
         {
            return getToteTitle(param1);
         }
         if(isCrystalKeyStatus(param1))
         {
            return getCrystalKeyTitle(param1);
         }
         if(isSkillRoundBuffStatus(param1))
         {
            return tipsArr[param1.split("_")[0]];
         }
         if(isGQSkillWindWord(param1))
         {
            return CommonBuffHelper.getTipsById(parseInt(param1.split("_")[1]));
         }
         if(isGQTujian(param1))
         {
            return tipsArr[param1.split("_")[0]];
         }
         if(isGQShenBingStatus(param1))
         {
            return "神兵之力";
         }
         if(tipsArr.hasOwnProperty(param1))
         {
            return tipsArr[param1];
         }
         return PetCardSuitConfig.getTipsTitle(param1);
      }
      
      public static function isPetInLegendFieldState(param1:PetBriefInfo) : Boolean
      {
         return getPetLeftLegendFieldRound(param1) > 0;
      }
      
      public static function getPetLeftLegendFieldRound(param1:PetBriefInfo) : int
      {
         var _loc4_:Array = null;
         var _loc5_:String = null;
         var _loc6_:int = 0;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:PMData = _loc2_.getOperationPM(param1.raceId).pmData;
         if(Boolean(_loc3_.isLegendPM()) && _loc3_.getLegendType() == LegendPetType.FIELD)
         {
            _loc4_ = param1.status.split(",");
            for each(_loc5_ in _loc4_)
            {
               if(isLegendFieldStatus(_loc5_))
               {
                  return getLegendFieldLeftRound(_loc5_);
               }
            }
         }
         return 0;
      }
      
      public static function isZhanYiStatus(param1:String) : Boolean
      {
         return param1.indexOf(ZHANYI_BUFF1) == 0 || param1.indexOf(ZHANYI_BUFF2) == 0 || param1.indexOf(ZHANYI_BUFF3) == 0;
      }
      
      public static function isToteStatus(param1:String) : Boolean
      {
         return param1.indexOf(ToteKey) == 0;
      }
      
      public static function getToteTips(param1:String) : String
      {
         var _loc2_:int = int(param1.split("_")[1]);
         var _loc3_:IToteService = ServiceContainer.getService(IToteService) as IToteService;
         var _loc4_:ToteEntryData = _loc3_.getEntryDataById(_loc2_);
         if(_loc4_)
         {
            return _loc4_.effectStr;
         }
         return "";
      }
      
      public static function getToteTitle(param1:String) : String
      {
         var _loc4_:ToteData = null;
         var _loc2_:int = int(param1.split("_")[1]);
         var _loc3_:IToteService = ServiceContainer.getService(IToteService) as IToteService;
         for each(_loc4_ in _loc3_.getConfigDataArrByType(ToteConfig.Type_All))
         {
            if(_loc4_.effectId == _loc2_)
            {
               return _loc4_.name;
            }
         }
         return "";
      }
      
      public static function isCrystalKeyStatus(param1:String) : Boolean
      {
         return param1.indexOf(CRYSTAL_KEY_KEY) == 0;
      }
      
      public static function getCrystalKeyTips(param1:String) : String
      {
         var _loc2_:int = int(param1.split("_")[1]);
         var _loc3_:ICrystalKeyService = ServiceContainer.getService(ICrystalKeyService) as ICrystalKeyService;
         return _loc3_.getCrystalKeyById(_loc2_).effect;
      }
      
      public static function getCrystalKeyTitle(param1:String) : String
      {
         var _loc2_:int = int(param1.split("_")[1]);
         var _loc3_:ICrystalKeyService = ServiceContainer.getService(ICrystalKeyService) as ICrystalKeyService;
         return _loc3_.getCrystalKeyById(_loc2_).name;
      }
      
      public static function getZhanYiBuffDes(param1:String) : String
      {
         var _loc2_:String = param1.split("_")[0];
         var _loc3_:int = int(param1.split("_")[1]);
         if(_loc2_ == ZHANYI_BUFF1)
         {
            return detailTipsArr[_loc2_] + getZhanYiNum(0,_loc3_);
         }
         if(_loc2_ == ZHANYI_BUFF2)
         {
            return detailTipsArr[_loc2_] + getZhanYiNum(1,_loc3_);
         }
         return detailTipsArr[_loc2_] + getZhanYiNum(2,_loc3_);
      }
      
      public static function isSkillRoundBuffStatus(param1:String) : Boolean
      {
         var _loc2_:int = 0;
         while(_loc2_ < SKILL_ROUND_BUFF.length)
         {
            if(param1.indexOf(SKILL_ROUND_BUFF[_loc2_]) == 0)
            {
               return true;
            }
            _loc2_++;
         }
         return false;
      }
      
      public static function isGQSkillWindWord(param1:String) : Boolean
      {
         return CommonBuffHelper.getIsCommonBuff(param1);
      }
      
      public static function getSkillRoundBuffDes(param1:String) : String
      {
         var _loc4_:int = 0;
         var _loc2_:String = param1.split("_")[0];
         var _loc3_:int = int(param1.split("_")[1]);
         if(_loc2_ == SKILL_ROUND_BUFF[0])
         {
            if(_loc3_ < 0)
            {
               _loc3_ = 0;
            }
            return detailTipsArr[_loc2_] + "\n剩余化解次数：" + _loc3_;
         }
         if(_loc2_ == SKILL_ROUND_BUFF[1] || _loc2_ == SKILL_ROUND_BUFF[2] || _loc2_ == SKILL_ROUND_BUFF[3] || _loc2_ == "hpzf1" || _loc2_ == "hpzf2" || _loc2_ == "mxf1" || _loc2_ == "jlb")
         {
            if(_loc3_ < 0)
            {
               _loc3_ = 0;
            }
            return detailTipsArr[_loc2_] + "\n剩余回合：" + _loc3_;
         }
         if(_loc2_ == SKILL_ROUND_BUFF[4])
         {
            _loc4_ = int(param1.split("_")[2]);
            if(_loc3_ < 0)
            {
               _loc3_ = 0;
            }
            if(_loc4_ < 0)
            {
               _loc4_ = 0;
            }
            return detailTipsArr[_loc2_] + "当前印记：" + _loc4_ + "\n剩余回合：" + _loc3_;
         }
         if(_loc2_ == "mhyj")
         {
            if(_loc3_ < 0)
            {
               _loc3_ = 0;
            }
            return detailTipsArr[_loc2_] + "\n受到的攻击次数：" + _loc3_;
         }
         return "";
      }
      
      public static function getGQSkillWindWordBuffDes(param1:String) : String
      {
         var _loc6_:int = 0;
         var _loc7_:Array = null;
         var _loc8_:int = 0;
         var _loc9_:String = null;
         var _loc2_:String = "";
         var _loc3_:Array = param1.split("_");
         var _loc4_:String = CommonBuffHelper.getDetailTipsById(parseInt(_loc3_[1])).concat();
         var _loc5_:Array = ["r","x","y","z","a","b","c"];
         if(_loc3_.length < 3)
         {
            _loc2_ = _loc4_;
         }
         else
         {
            _loc6_ = 0;
            while(_loc6_ < _loc4_.length)
            {
               _loc8_ = 0;
               while(_loc8_ < _loc5_.length)
               {
                  if(_loc4_.charAt(_loc6_) == _loc5_[_loc8_])
                  {
                     if(_loc8_ != 0)
                     {
                        _loc4_ = _loc4_.replace(_loc5_[_loc8_],"%s");
                        _loc6_++;
                        break;
                     }
                     _loc9_ = _loc4_.substr(_loc6_,5);
                     if(_loc9_ == "round")
                     {
                        _loc4_ = _loc4_.replace(_loc9_,"%s");
                        _loc6_++;
                        break;
                     }
                  }
                  _loc8_++;
               }
               _loc6_++;
            }
            _loc7_ = _loc3_.splice(2);
            _loc2_ = StringUtil.javaFormatForList(_loc4_,_loc7_);
         }
         return _loc2_;
      }
      
      public static function isShenBenStatus(param1:String) : Boolean
      {
         return param1.indexOf(SHEN_BEN_STATUS_PRE) == 0;
      }
      
      public static function isLegendFieldStatus(param1:String) : Boolean
      {
         return param1.indexOf(CHANGE_VIEW_STATUS_PRE) == 0;
      }
      
      public static function getLegendFieldLeftRound(param1:String) : int
      {
         var _loc2_:Array = param1.split("_");
         return parseInt(_loc2_[1]);
      }
      
      public static function isPetInDegeneratorXianState(param1:PetBriefInfo) : Boolean
      {
         return getPetLeftDegeneratorXianRound(param1) > 0;
      }
      
      public static function isGQShenBingStatus(param1:String) : Boolean
      {
         return param1.indexOf(GQ_SHENBING) == 0;
      }
      
      public static function isZhaoHuanShiStatus(param1:String) : Boolean
      {
         return param1.indexOf(ZHAO_HUAN_SHI_PRE) == 0;
      }
      
      public static function getPetLeftDegeneratorXianRound(param1:PetBriefInfo) : int
      {
         var _loc4_:Array = null;
         var _loc5_:String = null;
         var _loc6_:int = 0;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:PMData = _loc2_.getOperationPM(param1.raceId).pmData;
         if(Boolean(_loc3_.isDegeneratorPM()) && _loc3_.getDegeneratorType() == DegeneratorPetType.XIAN)
         {
            _loc4_ = param1.status.split(",");
            for each(_loc5_ in _loc4_)
            {
               if(isDegeneratorXianStatus(_loc5_))
               {
                  return getDegeneratorXianLeftRound(_loc5_);
               }
            }
         }
         return 0;
      }
      
      public static function isGQTujian(param1:String) : Boolean
      {
         return param1.indexOf(GQ_TUJIAN) == 0;
      }
      
      public static function isDegeneratorXianStatus(param1:String) : Boolean
      {
         return param1.indexOf(DEGENERATOR_CHANGE_VIEW_STATUS_PRE) == 0;
      }
      
      public static function getDegeneratorXianLeftRound(param1:String) : int
      {
         var _loc2_:Array = param1.split("_");
         return parseInt(_loc2_[1]);
      }
      
      public static function getDegeneratorXianLevel(param1:String) : int
      {
         var _loc2_:Array = param1.split("_");
         return parseInt(_loc2_[2]);
      }
      
      public static function getDetailTips(param1:String) : String
      {
         var _loc2_:int = 0;
         var _loc3_:Array = null;
         if(isLegendFieldStatus(param1))
         {
            return "";
         }
         if(StampConfig.checkIsStampStatus(param1))
         {
            return StampConfig.getTipsDetail(param1);
         }
         if(isShenBenStatus(param1))
         {
            _loc2_ = int(param1.split("_")[1]);
            return GodCardTipsHelper.getSuitDecByCardId(_loc2_);
         }
         if(isZhanYiStatus(param1))
         {
            return getZhanYiBuffDes(param1);
         }
         if(isToteStatus(param1))
         {
            return getToteTips(param1);
         }
         if(isCrystalKeyStatus(param1))
         {
            return getCrystalKeyTips(param1);
         }
         if(isSkillRoundBuffStatus(param1))
         {
            return getSkillRoundBuffDes(param1);
         }
         if(isGQSkillWindWord(param1))
         {
            return getGQSkillWindWordBuffDes(param1);
         }
         if(isGQTujian(param1))
         {
            _loc3_ = param1.split("_");
            return "所有光启亚比\n体力+" + _loc3_[1] + "%\n伤害+" + _loc3_[2] + "%";
         }
         if(isGQShenBingStatus(param1))
         {
            _loc3_ = param1.split("_");
            if(_gameOptionSvr.isGQSimpleSkillView)
            {
               return GQShenBingObjHelper.getSimpleTipsByRaceIdAndLv(parseInt(_loc3_[1]),parseInt(_loc3_[2]),parseInt(_loc3_[3]) == 1);
            }
            return GQShenBingObjHelper.getDetailTipsByRaceIdAndLv(parseInt(_loc3_[1]),parseInt(_loc3_[2]),parseInt(_loc3_[3]) == 1);
         }
         detailTipsArr = iPetfightConfig.statusUtilDetailTipsArr;
         if(detailTipsArr.hasOwnProperty(param1))
         {
            return detailTipsArr[param1];
         }
         return PetCardSuitConfig.getTipsDetail(param1);
      }
      
      public static function parseStatusStr(param1:String) : Array
      {
         var _loc2_:Array = null;
         var _loc3_:Array = null;
         var _loc4_:Array = null;
         var _loc5_:Array = null;
         var _loc6_:Array = null;
         var _loc7_:Array = null;
         var _loc8_:int = 0;
         var _loc9_:String = null;
         if(StringUtil.isNullOrEmpty(param1))
         {
            return [];
         }
         _loc2_ = param1.split(",");
         _loc3_ = [];
         _loc4_ = [];
         _loc5_ = [];
         _loc6_ = [];
         _loc7_ = [];
         _loc8_ = int(_loc2_.length - 1);
         while(_loc8_ >= 0)
         {
            _loc9_ = _loc2_[_loc8_];
            if(StampConfig.checkIsStampStatus(_loc9_))
            {
               _loc3_.push(_loc9_);
               _loc2_.splice(_loc8_,1);
            }
            else if(_loc9_.indexOf("slpc_") != -1)
            {
               _loc4_.push(_loc9_);
               _loc2_.splice(_loc8_,1);
            }
            else if(_loc9_.indexOf("slt_") != -1 || _loc9_.indexOf("sltex_") != -1)
            {
               _loc5_.push(_loc9_);
               _loc2_.splice(_loc8_,1);
            }
            else if(_loc9_.indexOf("suit_") != -1)
            {
               _loc6_.push(_loc9_);
               _loc2_.splice(_loc8_,1);
            }
            else if(isShenBenStatus(_loc9_))
            {
               _loc7_.push(_loc9_);
               _loc2_.splice(_loc8_,1);
            }
            _loc8_--;
         }
         return _loc3_.concat(_loc4_).concat(_loc5_).concat(_loc6_).concat(_loc7_).concat(_loc2_);
      }
      
      public static function getZhanYiNum(param1:int, param2:int) : int
      {
         var _loc3_:int = 0;
         var _loc4_:Array = ZHANYI_BUFF_ADDNUMARY[param1];
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_.length)
         {
            if(_loc5_ < param2)
            {
               _loc3_ += _loc4_[_loc5_];
            }
            _loc5_++;
         }
         return _loc3_;
      }
      
      public static function getIsinTouzhiCommonBuff(param1:PetBriefInfo) : Boolean
      {
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:Boolean = false;
         var _loc4_:Boolean = false;
         var _loc5_:int = 0;
         while(_loc5_ < _loc2_.length)
         {
            if(_loc2_[_loc5_].indexOf("cbf_1307") != -1)
            {
               _loc3_ = true;
            }
            if(_loc2_[_loc5_].indexOf("cbf_1301") != -1)
            {
               _loc4_ = true;
            }
            if(_loc2_[_loc5_].indexOf("cbf_1476") != -1)
            {
               _loc3_ = true;
            }
            _loc5_++;
         }
         return _loc3_ && !_loc4_;
      }
      
      public static function getInOnlyUseOneSkillToteSkillId(param1:PetBriefInfo) : int
      {
         var _loc2_:int = -1;
         var _loc3_:Array = param1.status.split(",");
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_.length)
         {
            if(_loc3_[_loc4_].indexOf("zybz_") != -1)
            {
               _loc2_ = parseInt(_loc3_[_loc4_].split("_")[1]);
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public static function getInOnlyUseSomeSkillIdBuff(param1:PetBriefInfo) : Array
      {
         var _loc2_:Array = [];
         var _loc3_:Array = param1.status.split(",");
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_.length)
         {
            if(_loc3_[_loc4_].indexOf("zyyh_") != -1)
            {
               _loc2_ = ActArrHelper.splitStr(_loc3_[_loc4_].split("_")[1],"#",0);
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public static function getCanUseSkillWithToteOrBuff(param1:PetBriefInfo, param2:int) : Boolean
      {
         var _loc3_:int = StatusUtil.getInOnlyUseOneSkillToteSkillId(param1);
         var _loc4_:Array = StatusUtil.getInOnlyUseSomeSkillIdBuff(param1);
         return (_loc3_ == -1 || param2 == _loc3_) && (_loc4_.length <= 0 || Boolean(ArrayUtil.arrayContainsValue(_loc4_,param2)));
      }
      
      public static function getCurrHp(param1:PetBriefInfo) : int
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("mtsk_0") != -1)
            {
               return 0;
            }
         }
         return param1.curHp;
      }
      
      public static function getYirenShieldByPbi(param1:PetBriefInfo) : Array
      {
         var _loc3_:String = null;
         var _loc4_:int = 0;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("mtsk") != -1)
            {
               _loc4_ = parseInt(_loc3_.split("_")[2]);
               _loc4_ = _loc4_ >= 0 ? _loc4_ : 0;
               return [_loc4_,parseInt(_loc3_.split("_")[3])];
            }
         }
         return [0,0];
      }
      
      public static function getIsDijieshiBigSkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("djsbky") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getTouzhiHpByPbi(param1:PetBriefInfo) : int
      {
         var _loc3_:String = null;
         var _loc4_:int = 0;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("cbf_1404_") != -1)
            {
               _loc4_ = parseInt(_loc3_.split("_")[3]);
               return _loc4_ >= 0 ? _loc4_ : 0;
            }
         }
         return -1;
      }
      
      public static function getIsTouzhiHpByPbi(param1:PetBriefInfo) : Boolean
      {
         return getTouzhiHpByPbi(param1) > 0;
      }
      
      public static function getIsInBuxiugonglingState(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("yjlm_1") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getDeadZoneExploreMomentumsByPbi(param1:PetBriefInfo) : Array
      {
         var _loc4_:String = null;
         var _loc2_:Array = [];
         var _loc3_:Array = param1.status.split(",");
         for each(_loc4_ in _loc3_)
         {
            if(_loc4_.indexOf("actQST=") != -1)
            {
               _loc2_ = ActArrHelper.splitStr(_loc4_.split("=")[1],"_",0);
               break;
            }
         }
         return _loc2_;
      }
      
      public static function getDeadZoneExploreSkillIdByPbi(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc2_:int = 0;
         var _loc3_:Array = param1.status.split(",");
         for each(_loc4_ in _loc3_)
         {
            if(_loc4_.indexOf("actESId=") != -1)
            {
               _loc2_ = parseInt(_loc4_.split("=")[1].split("_")[0]);
               break;
            }
         }
         return _loc2_;
      }
      
      public static function getDeadZoneExploreSkillCdByPbi(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc2_:int = 0;
         var _loc3_:Array = param1.status.split(",");
         for each(_loc4_ in _loc3_)
         {
            if(_loc4_.indexOf("actESId=") != -1)
            {
               _loc2_ = parseInt(_loc4_.split("=")[1].split("_")[1]);
               break;
            }
         }
         return _loc2_;
      }
      
      public static function getIsDeadZoneExploreByPbi(param1:PetBriefInfo) : Boolean
      {
         return getDeadZoneExploreMomentumsByPbi(param1).length > 0;
      }
      
      public static function getIsInWumangXingjiState(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("hemscd_") != -1)
            {
               return parseInt(_loc3_.split("_")[2]) > 0;
            }
         }
         return false;
      }
      
      public static function getWumangXingjiStateSkillId(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = -1;
         for each(_loc4_ in _loc2_)
         {
            if(_loc4_.indexOf("hemscd_") != -1)
            {
               _loc3_ = parseInt(_loc4_.split("_")[2]);
            }
         }
         return _loc3_;
      }
      
      public static function getGQShenqiSlotId(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = -1;
         for each(_loc4_ in _loc2_)
         {
            if(_loc4_.indexOf("sqtjpm_") != -1)
            {
               _loc3_ = parseInt(_loc4_.split("_")[1].split(":")[0]);
            }
         }
         return _loc3_;
      }
      
      public static function getGQShenqiQiyuePmId(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = -1;
         for each(_loc4_ in _loc2_)
         {
            if(_loc4_.indexOf("sqtjpm_") != -1)
            {
               _loc3_ = parseInt(_loc4_.split("_")[1].split(":")[1]);
            }
         }
         return _loc3_;
      }
      
      public static function clearGQShenqiState(param1:PetBriefInfo) : void
      {
         var _loc4_:String = null;
         var _loc2_:String = param1.status;
         var _loc3_:Array = _loc2_.split(",");
         for each(_loc4_ in _loc3_)
         {
            if(_loc4_.indexOf("sqtjpm_") != -1)
            {
               param1.status = StringUtil.remove(_loc2_,_loc4_ + ",");
            }
         }
      }
      
      public static function getIsInLockByJueduiWeiduState(param1:PetBriefInfo) : Boolean
      {
         var _loc2_:String = null;
         var _loc3_:Array = null;
         var _loc4_:String = null;
         if(param1)
         {
            _loc2_ = param1.status;
            _loc3_ = _loc2_.split(",");
            for each(_loc4_ in _loc3_)
            {
               if(_loc4_.indexOf("yhzyfs") != -1)
               {
                  return true;
               }
            }
         }
         return false;
      }
      
      public static function getIsInLiangziXinglianState(param1:PetBriefInfo) : Boolean
      {
         var _loc2_:String = null;
         var _loc3_:Array = null;
         var _loc4_:String = null;
         if(param1)
         {
            _loc2_ = param1.status;
            _loc3_ = _loc2_.split(",");
            for each(_loc4_ in _loc3_)
            {
               if(_loc4_ == "yhzyzh")
               {
                  return true;
               }
            }
         }
         return false;
      }
      
      public static function getIsInTuichuLiangziXinglianState(param1:PetBriefInfo) : Boolean
      {
         var _loc2_:String = null;
         var _loc3_:Array = null;
         var _loc4_:String = null;
         if(param1)
         {
            _loc2_ = param1.status;
            _loc3_ = _loc2_.split(",");
            for each(_loc4_ in _loc3_)
            {
               if(_loc4_ == "yhzyzh1")
               {
                  return true;
               }
            }
         }
         return false;
      }
      
      public static function getIsYanhuaZhiyaoUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc2_:String = null;
         var _loc3_:Array = null;
         var _loc4_:String = null;
         if(param1)
         {
            _loc2_ = param1.status;
            _loc3_ = _loc2_.split(",");
            for each(_loc4_ in _loc3_)
            {
               if(_loc4_.indexOf("yhzycs_") != -1)
               {
                  return parseInt(_loc4_.split("_")[1]) > 0;
               }
            }
         }
         return false;
      }
      
      public static function getIsZhigaoRongyaoBigSkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("zgry") != -1)
            {
               return parseInt(_loc3_.split("_")[2]) > 0;
            }
         }
         return false;
      }
      
      public static function getZhigaoRongyaoContractArr(param1:PetBriefInfo) : Array
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("zgry") != -1)
            {
               return BitUtil.splitIntoIntArray(parseInt(_loc3_.split("_")[1]),4);
            }
         }
         return [0,0,0,0];
      }
      
      public static function getPetFightSpace3SkillIdByPbi(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc2_:int = 0;
         var _loc3_:Array = param1.status.split(",");
         for each(_loc4_ in _loc3_)
         {
            if(_loc4_.indexOf("sa231229wm=") != -1)
            {
               _loc2_ = parseInt(_loc4_.split("=")[1].split("_")[0]);
               break;
            }
         }
         return _loc2_;
      }
      
      public static function getPetFightSpace3CanUseSkillByPbi(param1:PetBriefInfo) : Boolean
      {
         var _loc5_:String = null;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         for each(_loc5_ in _loc2_)
         {
            if(_loc5_.indexOf("sa231229wm=") != -1)
            {
               _loc3_ = parseInt(_loc5_.split("=")[1].split("_")[1]);
               _loc4_ = parseInt(_loc5_.split("=")[1].split("_")[2]);
               break;
            }
         }
         return _loc4_ - _loc3_ > 0;
      }
      
      public static function getIsInPetFightSpace3ByPbi(param1:PetBriefInfo) : Boolean
      {
         return getPetFightSpace3SkillIdByPbi(param1) > 0;
      }
      
      public static function getMiBaoSkillState(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc5_:Array = null;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(_loc4_.indexOf("wjmx_") != -1)
            {
               _loc5_ = _loc4_.split("_");
               if(parseInt(_loc5_[3]) > 0)
               {
                  return 2;
               }
               if(parseInt(_loc5_[2]) >= 4)
               {
                  return 1;
               }
            }
            _loc3_++;
         }
         return 0;
      }
      
      public static function getMiBaoGainSoulNum(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc5_:Array = null;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(_loc4_.indexOf("wjmx_") != -1)
            {
               _loc5_ = _loc4_.split("_");
               return parseInt(_loc5_[2]);
            }
            _loc3_++;
         }
         return 0;
      }
      
      public static function getIsAtMiBaoStrollState(param1:PetBriefInfo) : Boolean
      {
         var _loc4_:String = null;
         var _loc5_:Array = null;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(_loc4_.indexOf("wjmx_") != -1)
            {
               _loc5_ = _loc4_.split("_");
               return parseInt(_loc5_[1]) > 0;
            }
            _loc3_++;
         }
         return false;
      }
      
      public static function getMiBaoSkillCd(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc5_:Array = null;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(_loc4_.indexOf("wjmx_") != -1)
            {
               _loc5_ = _loc4_.split("_");
               return parseInt(_loc5_[3]);
            }
            _loc3_++;
         }
         return 0;
      }
      
      public static function getIsHasXingYunBuff(param1:PetBriefInfo) : Boolean
      {
         var _loc4_:String = null;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(_loc4_.indexOf("cbf_1459") != -1)
            {
               return true;
            }
            _loc3_++;
         }
         return false;
      }
      
      public static function getMingYunBoYiUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc4_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("myby_") != -1)
            {
               _loc4_ = _loc3_.split("_")[1];
               return parseInt(_loc4_) == 1;
            }
         }
         return false;
      }
      
      public static function getMingYunBoYiOrders(param1:PetBriefInfo) : Array
      {
         var _loc4_:String = null;
         var _loc5_:Array = null;
         var _loc6_:String = null;
         var _loc7_:Array = null;
         var _loc2_:Array = [];
         var _loc3_:Array = param1.status.split(",");
         for each(_loc4_ in _loc3_)
         {
            if(_loc4_.indexOf("myby_") != -1)
            {
               _loc5_ = _loc4_.split("_")[2].split(":");
               for each(_loc6_ in _loc5_)
               {
                  if(_loc6_.indexOf("-1") != 0)
                  {
                     _loc7_ = _loc6_.split("-");
                     _loc2_.push({
                        "order":parseInt(_loc7_[0]),
                        "guess":parseInt(_loc7_[1])
                     });
                  }
               }
               break;
            }
         }
         return _loc2_;
      }
      
      public static function getMingYunBoYiOrderOpenNum(param1:PetBriefInfo) : int
      {
         var _loc2_:Array = getMingYunBoYiOrders(param1);
         return _loc2_.length;
      }
      
      public static function getIsJiuRiChongXianBigSkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("zysy") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getHuanLingShiEnergy(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = 0;
         for each(_loc4_ in _loc2_)
         {
            if(_loc4_.indexOf("hlsnl_") != -1)
            {
               _loc3_ = parseInt(_loc4_.split("_")[1]);
               break;
            }
         }
         return _loc3_;
      }
      
      public static function getIsHuanLingShiState(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("hlsnl_") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getIsHuanLingShiCanUseSkill(param1:PetBriefInfo) : Boolean
      {
         return getHuanLingShiEnergy(param1) >= 100;
      }
      
      public static function getIsInYiWangCommonBuff(param1:PetBriefInfo) : Boolean
      {
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:* = false;
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            if(_loc2_[_loc4_].indexOf("cbf_1487") != -1)
            {
               _loc3_ = true;
            }
            _loc4_++;
         }
         return _loc3_;
      }
      
      public static function getIsXingHuanShiBigSkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("xhs") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getIsDengShenChangJieSpiritSkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("xslz") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getIsXianJingJiPet(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("clzh") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getIsBuxiuJixingState(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("bxjx_") != -1)
            {
               return parseInt(_loc3_.split("_")[1]) == 1;
            }
         }
         return false;
      }
      
      public static function getBuxiuJixingLevel(param1:PetBriefInfo) : int
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("bxjx_") != -1)
            {
               return parseInt(_loc3_.split("_")[2]) + 1;
            }
         }
         return 0;
      }
      
      public static function getIsBuxiuJixingSpiritSkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("bxjx1") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getWanyuZhichaoSpiritSkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("wyzccs_") != -1)
            {
               return parseInt(_loc3_.split("_")[1]) > 0;
            }
         }
         return false;
      }
      
      public static function getIsWanyuZhichaoHasXuying(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("wyzcxy") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getIsHunDunJueDouSpiritSkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("hdjdcs_") != -1)
            {
               return parseInt(_loc3_.split("_")[1]) > 0;
            }
         }
         return false;
      }
      
      public static function getHunDunJueDouHp(param1:PetBriefInfo) : int
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("hdjdhd_") != -1)
            {
               return parseInt(_loc3_.split("_")[1]);
            }
         }
         return -1;
      }
      
      public static function getIsInHunDunJueDouState(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("hdjdzh") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getIsShiKongFangZhuSpiritSkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("skfzcs_") != -1)
            {
               return parseInt(_loc3_.split("_")[1]) > 0;
            }
         }
         return false;
      }
      
      public static function getIsInShiKongFangZhuState(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("skfzzt") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getIsInJiangShenState(param1:PetBriefInfo) : Boolean
      {
         var _loc4_:GQJiangShenSkillParse = null;
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:PMData = _loc2_.getOperationPM(param1.raceId).pmData;
         if(GQPetType.isJiangShen(_loc3_.getGQType()))
         {
            _loc4_ = GQJiangShenSkillParse.getGQJiangShenSkillParse(param1.raceId);
            if(_loc4_.getIsAfterChangeView(param1))
            {
               return true;
            }
            return false;
         }
         return false;
      }
      
      public static function getIsJiangShenSpiritSkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("jsxt") != -1)
            {
               return parseInt(_loc3_.split("_")[1]) > 0;
            }
         }
         return false;
      }
      
      public static function getJiangShenSpiritEnergy(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = 0;
         for each(_loc4_ in _loc2_)
         {
            if(_loc4_.indexOf("jsnl_") != -1)
            {
               _loc3_ = parseInt(_loc4_.split("_")[1]);
               break;
            }
         }
         return _loc3_;
      }
      
      public static function getIsJiangShenCanUseSpiritSkill(param1:PetBriefInfo) : Boolean
      {
         return getJiangShenSpiritEnergy(param1) >= 100;
      }
      
      public static function getShenYuTianGangSpiritSkillCd(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc5_:int = 0;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(_loc4_.indexOf("sytg_") != -1)
            {
               return int(parseInt(_loc4_.split("_")[1]));
            }
            _loc3_++;
         }
         return 0;
      }
      
      public static function getShenYuTianGangExtraSkillIds(param1:PetBriefInfo) : Array
      {
         var _loc4_:String = null;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(_loc4_.indexOf("sytg_") != -1)
            {
               return ActStrHelper.splitToIntArr1(_loc4_.split("_")[2],"#");
            }
            _loc3_++;
         }
         return [];
      }
      
      public static function getIsZhenLiFaDianSpiritSkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("dzkd") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getIsAsDyingButHasHp(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("tytc") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getAsDyingHpNum(param1:PetBriefInfo) : int
      {
         var _loc3_:String = null;
         var _loc4_:int = 0;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("tytc") != -1)
            {
               return int(parseInt(_loc3_.split("_")[1]));
            }
         }
         return 0;
      }
      
      public static function getIsLIEJIEZHIXISkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("ljzxcs") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getIsInYuXiangState(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("yxszt") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getYuXiangShiIsCanUseFirstSkill(param1:PetBriefInfo) : Boolean
      {
         var _loc4_:String = null;
         var _loc5_:int = 0;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(_loc4_.indexOf("yxscs_") != -1)
            {
               _loc5_ = parseInt(_loc4_.split("_")[1]);
               return _loc5_ < 2;
            }
            _loc3_++;
         }
         return false;
      }
      
      public static function getYuXiangShiSecondSkillCd(param1:PetBriefInfo) : int
      {
         var _loc4_:String = null;
         var _loc5_:int = 0;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(_loc4_.indexOf("yxszt_") != -1)
            {
               return int(parseInt(_loc4_.split("_")[1]));
            }
            _loc3_++;
         }
         return 0;
      }
      
      public static function getYuXiangShiCanChangObjArr(param1:PetBriefInfo) : Array
      {
         var _loc5_:String = null;
         var _loc6_:String = null;
         var _loc7_:Array = null;
         var _loc8_:int = 0;
         var _loc9_:String = null;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:Array = [];
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc5_ = _loc2_[_loc4_];
            if(_loc5_.indexOf("yxszt_") != -1)
            {
               _loc6_ = _loc5_.split("_")[2];
               if(_loc6_.length > 0)
               {
                  _loc7_ = _loc5_.split("_")[2].split("#");
                  _loc8_ = 0;
                  while(_loc8_ < _loc7_.length)
                  {
                     _loc9_ = _loc7_[_loc8_];
                     _loc10_ = parseInt(_loc9_.split(":")[0]);
                     _loc11_ = parseInt(_loc9_.split(":")[1]);
                     _loc3_.push({
                        "raceId":_loc10_,
                        "uniqueId":_loc11_
                     });
                     _loc8_++;
                  }
               }
            }
            _loc4_++;
         }
         return _loc3_;
      }
      
      public static function getIsInXiYaFightState(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("ewyb_") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getXiYaFightCanChangObjArr(param1:PetBriefInfo) : Array
      {
         var _loc5_:String = null;
         var _loc6_:String = null;
         var _loc7_:Array = null;
         var _loc8_:int = 0;
         var _loc9_:String = null;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         var _loc2_:Array = param1.status.split(",");
         var _loc3_:Array = [];
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc5_ = _loc2_[_loc4_];
            if(_loc5_.indexOf("ewyb_") != -1)
            {
               _loc6_ = _loc5_.split("_")[1];
               if(_loc6_.length > 0)
               {
                  _loc7_ = _loc6_.split("#");
                  _loc8_ = 0;
                  while(_loc8_ < _loc7_.length)
                  {
                     _loc9_ = _loc7_[_loc8_];
                     _loc10_ = parseInt(_loc9_.split(":")[0]);
                     _loc11_ = parseInt(_loc9_.split(":")[1]);
                     _loc3_.push({
                        "raceId":_loc10_,
                        "uniqueId":_loc11_
                     });
                     _loc8_++;
                  }
               }
            }
            _loc4_++;
         }
         return _loc3_;
      }
      
      public static function getIsGuiLingXieYiSkillUsed(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("gl260930cs_") != -1)
            {
               return parseInt(_loc3_.split("_")[1]) > 0;
            }
         }
         return false;
      }
      
      public static function getIsInGuiLingXieYiProgState(param1:PetBriefInfo) : Boolean
      {
         var _loc2_:Array = StatusUtil.getGuiLingXieYiHpArr(param1);
         return _loc2_[1] > 0;
      }
      
      public static function getGuiLingXieYiHpArr(param1:PetBriefInfo) : Array
      {
         var _loc3_:String = null;
         var _loc4_:Array = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("gl260930jd_") != -1)
            {
               _loc4_ = _loc3_.split("_");
               return [parseInt(_loc4_[1]),parseInt(_loc4_[2])];
            }
         }
         return [0,0];
      }
      
      public static function getIsGuiLingXieYiDataBody(param1:PetBriefInfo) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = param1.status.split(",");
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.indexOf("gl260930sjt") != -1)
            {
               return true;
            }
         }
         return false;
      }
   }
}

