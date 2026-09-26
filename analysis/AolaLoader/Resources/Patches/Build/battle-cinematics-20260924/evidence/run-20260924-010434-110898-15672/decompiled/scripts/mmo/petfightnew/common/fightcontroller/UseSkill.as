package mmo.petfightnew.common.fightcontroller
{
   import com.adobe.utils.StringUtil;
   import com.greensock.TweenMax;
   import com.greensock.data.TweenLiteVars;
   import flash.display.DisplayObject;
   import flash.display.FrameLabel;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.system.ApplicationDomain;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.user.UserInfo;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.AoYiConfig;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.data.skin.IPetSkinDataService;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.petcommon.SuperPetHelper;
   import mmo.interfaces.pet.pm.data.custom.PMLegendBigSkillTypes;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.DocPetFight;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.helper.SkillEffectHelper;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.petfightnew.common.manager.FightTweenMaxManager;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.skilleffect.GQHuanLingShiEffectHelper;
   import mmo.petfightnew.common.skilleffect.GQLianSuoEffectHelper;
   import mmo.petfightnew.common.skilleffect.SkillEffectLoader;
   import mmo.petfightnew.common.useskill.SkillRange;
   import mmo.petfightnew.common.useskill.SkillResults;
   import mmo.petfightnew.common.util.BSUtil;
   import mmo.petfightnew.common.util.GQBuxiuLvtuEffecthelper;
   import mmo.petfightnew.common.util.GQHundunJuedouEffectHelper;
   import mmo.petfightnew.common.util.GQMenghuanDiyueEffectHelper;
   import mmo.petfightnew.common.util.GQWanyuZhichaoEffectHelper;
   import mmo.petfightnew.common.util.PositionUtil;
   import mmo.petfightnew.common.util.ShenYuanHuiXiangMovieHelper;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.petfightnew.common.util.XingHuiWangzheRealHelper;
   import mmo.play.actthings.helper.ActMovieHelper;
   import mmo.play.petfight.common.config.SkillMap;
   
   public class UseSkill implements IDispose
   {
      
      private static var _instance:UseSkill;
      
      private static const TRY_GC_SIZE:int = 500;
      
      private var _petSkinDataSvr:IPetSkinDataService = ServicePool.instance.getService(IPetSkinDataService);
      
      private var _pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
      
      private var _petDataSvr:IPetDataService = ServicePool.instance.getService(IPetDataService);
      
      private var reqLocaId:int;
      
      private var hittedLocaId:int;
      
      private var skillId:int;
      
      private var pmSkillType:int;
      
      private var skillRange:int;
      
      private var curEffectId:int;
      
      private var effectMC:MovieClip;
      
      private var petSkillMess:IPetSkillMesService;
      
      private var isCriticalHit:Boolean;
      
      private var skillResult:int;
      
      private var isPlayingAttack:Boolean = false;
      
      private var isPlayingEffect:Boolean = false;
      
      private var onPlayReturn:Function;
      
      private var fightPanel:FightPanel;
      
      private var skillBS:String = "";
      
      private var _bus:Array = [];
      
      private var _skillParams:Object = {};
      
      private var _aoyiMoveHelper:AoYiMovieHelper = null;
      
      private var _isMyPetInPMMList:Boolean = false;
      
      private var _isSummonerSkill:Boolean = false;
      
      private var _pmSummonerArr:Array = [];
      
      private var _isMyPetJustGetInLegendField:Boolean = false;
      
      private var _isMyPetJustGetInDegeneratorXian:Boolean = false;
      
      private var _comboStr:String = "";
      
      private var _disposed:Boolean = false;
      
      private var _skillEffectLoader:SkillEffectLoader;
      
      private var _isRaceAppearObj:Object;
      
      private var _isAttackTogether:Boolean = false;
      
      private var _params:Object = null;
      
      public function UseSkill()
      {
         super();
      }
      
      public static function get instance() : UseSkill
      {
         if(_instance == null)
         {
            _instance = new UseSkill();
         }
         return _instance;
      }
      
      private static function playSpecialMovie(param1:int, param2:Function = null) : void
      {
         var movieContainer:Sprite = null;
         var fladId:int = param1;
         var afterMovie:Function = param2;
         movieContainer = FightController.instance.fightPanel.layerEffect;
         var url:String = "fightassets/skineffect/zhuanshuskilleffect_" + fladId;
         var cls:String = "mmo.petfightnew.skineffect.ZhuanShuSkillEffect_" + fladId;
         ResScheduler.getRes(ResParams.createTempByDomain(url,function(param1:MovieClip, param2:ApplicationDomain = null):void
         {
            movieContainer.addChild(param1);
            ActMovieHelper.playMcMv(param1,afterMovie);
         },ResDomain.decorate(FightData.instance.applicationDomain),cls));
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
         this.petSkillMess = ServicePool.instance.getService(IPetSkillMesService);
         this._skillEffectLoader = new SkillEffectLoader();
         this._isRaceAppearObj = {};
      }
      
      public function useSkill(param1:Object, param2:Boolean) : void
      {
         var params:Object = param1;
         var isSummonSkill:Boolean = param2;
         try
         {
            this._isAttackTogether = false;
            this.handleUseSkill(params,isSummonSkill);
         }
         catch(e:Error)
         {
            afterSkillUseEnd();
         }
      }
      
      public function handleUseSkill(param1:Object, param2:Boolean) : void
      {
         var reqSId:int;
         var reqPlayInfo:PlayerBattleInfo;
         var pmSvr:IPMService;
         var pmSkillType:int;
         var petInfo:PetBriefInfo = null;
         var annalFeeEightRaceId:int = 0;
         var isXuYingSkill:Boolean = false;
         var WanyuZhichaoObjectArr:Array = null;
         var i:int = 0;
         var params:Object = param1;
         var isSummonSkill:Boolean = param2;
         this._isMyPetInPMMList = false;
         this._isSummonerSkill = isSummonSkill;
         this._pmSummonerArr = [];
         this._isMyPetJustGetInLegendField = false;
         this._isMyPetJustGetInDegeneratorXian = false;
         this._params = params;
         reqSId = int(params.reqSId);
         this.reqLocaId = FightData.instance.getLocaId(reqSId);
         reqPlayInfo = FightData.instance.playerInfo[reqSId] as PlayerBattleInfo;
         if(reqPlayInfo == null)
         {
            annalFeeEightRaceId = this.getHandleAnnalFeeEightRaceId(params);
            if(annalFeeEightRaceId != -1)
            {
               this.handleAnnalFeeEight(annalFeeEightRaceId,params);
            }
            else
            {
               this.handleDatas(params);
               this.handleMovie(params);
            }
            return;
         }
         petInfo = reqPlayInfo.myPets[0] as PetBriefInfo;
         pmSvr = ServicePool.instance.getService(IPMService);
         pmSkillType = -1;
         if(params.id > 0)
         {
            pmSkillType = int(this._pmService.customData.pmSkillMap.getSkill(params.id).getSkillType());
         }
         if(!pmSvr.getOperationPM(petInfo.raceId).pmData.isDegeneratorPM() && AoYiConfig.getAoYiSkillId(petInfo.raceId) == params.id && params.id != 0)
         {
            if(this.fightPanel == null)
            {
               return;
            }
            if(DocPetFight.skipBattlePresentation)
            {
               this.handleAoYiSkill(petInfo,params);
               return;
            }
            this._aoyiMoveHelper = new AoYiMovieHelper();
            this._aoyiMoveHelper.playAoYiTakeEffectMovie(petInfo.raceId,function():void
            {
               handleAoYiSkill(petInfo,params);
            });
         }
         else
         {
            if(this.fightPanel == null)
            {
               return;
            }
            if(DocPetFight.skipBattlePresentation)
            {
               this.handleDatas(params);
               this.handleMovie(params);
               return;
            }
            if(this.isNeedToHandleWangzheReal(params))
            {
               this.handleWangzheReal(params);
            }
            else if(params.id > 0 && pmSkillType == PMSkillTypes.GQ_MENGHUAN_DIYUE_SKILL)
            {
               this.handleGQMenghuanDiyueEffect(params);
            }
            else
            {
               isXuYingSkill = false;
               WanyuZhichaoObjectArr = GQPetType.WanyuZhichaoObjectArr;
               i = 0;
               while(i < WanyuZhichaoObjectArr.length)
               {
                  if(params.id >= WanyuZhichaoObjectArr[i].xuyingSkillStartId && params.id <= WanyuZhichaoObjectArr[i].xuyingSkillEndId && petInfo.raceId != WanyuZhichaoObjectArr[i].changeViewId)
                  {
                     this.handleGQWanyuZhichaoEffect(params);
                     isXuYingSkill = true;
                     break;
                  }
                  i++;
               }
               if(!isXuYingSkill)
               {
                  this.handleDatas(params);
                  this.handleMovie(params);
               }
            }
         }
      }
      
      private function getHandleAnnalFeeEightRaceId(param1:Object) : int
      {
         var _loc3_:Object = null;
         var _loc4_:PlayerBattleInfo = null;
         var _loc5_:PetBriefInfo = null;
         var _loc2_:Array = param1.pmmList;
         if(!_loc2_ || _loc2_.length == 0)
         {
            return -1;
         }
         for each(_loc3_ in _loc2_)
         {
            _loc4_ = new PlayerBattleInfo();
            _loc4_.parseInfo(_loc3_);
            _loc4_ = FightData.instance.setLocaId(_loc4_);
            if(!_loc4_.myPets)
            {
               return -1;
            }
            if(this._isSummonerSkill && this.isNewSummoned(_loc4_) && FightData.instance.isMySide(_loc4_.locaId))
            {
               _loc5_ = _loc4_.myPets[0] as PetBriefInfo;
               if(_loc5_.getXingHuiAnnualFee22SkillParser().isAnnualSummon)
               {
                  return _loc5_.getXingHuiAnnualFee22SkillParser().summonMasterRaceId;
               }
            }
         }
         return -1;
      }
      
      private function handleAnnalFeeEight(param1:int, param2:Object) : void
      {
         var obj:Object = null;
         var url:String = null;
         var cls:String = null;
         var self:UseSkill = null;
         var raceId:int = param1;
         var params:Object = param2;
         if(DocPetFight.skipBattlePresentation)
         {
            this.handleDatas(param2);
            this.handleMovie(param2);
            return;
         }
         obj = XinghuiPetType.getAnnualFee22Object(raceId);
         if(obj == null)
         {
            this.handleDatas(params);
            this.handleMovie(params);
            return;
         }
         url = "xinghuipet/annualfee22/effect/xinghuiannual22appearmv";
         cls = "mmo.xinghuipet.annualfee22.XingHuiAnnual22AppearMv";
         url += "_" + obj.fightEffect;
         cls += "_" + obj.fightEffect;
         self = this;
         this.playAnimation(url,cls,function():*
         {
            url = "xinghuipet/annualfee22/effect/xinghuiannual22grab";
            cls = "mmo.xinghuipet.annualfee22.XingHuiAnnual22GrabMv";
            url += "_" + obj.fightEffect;
            cls += "_" + obj.fightEffect;
            self.playAnimation(url,cls,function():*
            {
               self.handleDatas(params);
               self.handleMovie(params);
            });
         });
      }
      
      private function isNeedToHandleWangzheReal(param1:Object) : Boolean
      {
         var _loc2_:int = FightData.instance.getSlotId(this.reqLocaId);
         if(FightData.instance.playerInfo[_loc2_] == null)
         {
            return false;
         }
         var _loc3_:int = int(FightData.instance.playerInfo[_loc2_].myPets[0].raceId);
         if(this._pmService.customData.pmDataMap.getPM(_loc3_).getXinghuiType() != XinghuiPetType.WANGZHE_REAL || this._pmService.customData.pmDataMap.getPM(_loc3_).getXinghuiType() != XinghuiPetType.SHEN_WANGZHE_REAL)
         {
            return false;
         }
         var _loc4_:* = param1.id;
         if(this._pmService.customData.pmSkillMap.getSkill(_loc4_).getSkillType() == PMSkillTypes.XINGHUI_WANGZHE_REAL_EXTEND_SKILL)
         {
            return true;
         }
         return false;
      }
      
      private function handleWangzheReal(param1:Object) : void
      {
         var params:Object = param1;
         var slotId:int = FightData.instance.getSlotId(this.reqLocaId);
         var raceId:int = int(FightData.instance.playerInfo[slotId].myPets[0].raceId);
         XingHuiWangzheRealHelper.playAttackMovie(this.fightPanel.layerPetUp,this.reqLocaId,raceId.toString(),function():void
         {
            handleDatas(params);
            handleMovie(params);
         });
      }
      
      private function handleGQMenghuanDiyueEffect(param1:Object) : void
      {
         var params:Object = param1;
         var slotId:int = FightData.instance.getSlotId(this.reqLocaId);
         var raceId:int = int(FightData.instance.playerInfo[slotId].myPets[0].raceId);
         GQMenghuanDiyueEffectHelper.playAttackMovie(this.fightPanel.layerPetUp,this.reqLocaId,raceId,function():void
         {
            handleDatas(params);
            handleMovie(params);
         });
      }
      
      private function handleGQWanyuZhichaoEffect(param1:Object) : void
      {
         var params:Object = param1;
         var slotId:int = FightData.instance.getSlotId(this.reqLocaId);
         var raceId:int = int(FightData.instance.playerInfo[slotId].myPets[0].raceId);
         this.handleDatas(params);
         GQWanyuZhichaoEffectHelper.playAttackMovie(this.fightPanel.layerPetUp,this.reqLocaId,raceId,function():void
         {
            refreshInfos();
            handleSkillEnd();
         });
         this.delayDo(15,function():void
         {
            setDefendView();
         });
      }
      
      private function handleGQBuxiuJixingEffect() : void
      {
         var slotId:int = FightData.instance.getSlotId(this.reqLocaId);
         var pbi:PetBriefInfo = FightData.instance.playerInfo[slotId].myPets[0];
         GQBuxiuLvtuEffecthelper.playAttackMovie(this.fightPanel.layerPetUp,this.fightPanel.layerPetDown,this.reqLocaId,pbi,function():void
         {
         });
      }
      
      private function handleAoYiSkill(param1:PetBriefInfo, param2:Object) : void
      {
         if(this.fightPanel == null)
         {
            return;
         }
         if(AoYiConfig.getAoYiSkillType(AoYiConfig.getAoYiSkillId(param1.raceId)) == 3)
         {
            ChangePetView.instance.changeView(param2);
         }
         else
         {
            this.handleDatas(param2);
            this.handleMovie(param2);
         }
      }
      
      private function handleDatas(param1:Object) : void
      {
         var _loc6_:Object = null;
         var _loc7_:PlayerBattleInfo = null;
         var _loc8_:PetBriefInfo = null;
         var _loc9_:Array = null;
         var _loc10_:String = null;
         var _loc11_:int = 0;
         this.skillBS = BSUtil.parseBS(param1.bs);
         this._bus = BSUtil.parseBackGroundUp(param1.bs);
         this._skillParams = param1;
         var _loc2_:Array = param1.pmmList;
         var _loc3_:int = int(param1.reqSId);
         var _loc4_:PlayerBattleInfo = FightData.instance.playerInfo[_loc3_] as PlayerBattleInfo;
         this.skillId = param1.id;
         var _loc5_:Object = null;
         if(this.skillId != 0)
         {
            this.pmSkillType = this._pmService.customData.pmSkillMap.getSkill(this.skillId).getSkillType();
            if(this.pmSkillType == PMSkillTypes.GQ_HUANLINGSHI_FIRST_SPIRIT_SKILL && FightData.instance.isMySide(FightData.instance.getLocaId(_loc3_)))
            {
               FightData.instance.extData[FightData.HuanLingShiFirstSkillKey] = true;
            }
            _loc5_ = this.petSkillMess.getPetSkillMes(this.skillId);
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.USE_SKILL,{
               "skillId":this.skillId,
               "playerInfo":_loc4_
            }));
            this.skillRange = _loc5_.range;
         }
         FightController.instance.desc = param1.desc;
         FightController.instance.pmmStatuses = [];
         this._isMyPetInPMMList = false;
         for each(_loc6_ in _loc2_)
         {
            _loc7_ = new PlayerBattleInfo();
            _loc7_.parseInfo(_loc6_);
            _loc7_ = FightData.instance.setLocaId(_loc7_);
            if(this._isSummonerSkill && (this.isNewSummoned(_loc7_) || StatusUtil.getIsInLiangziXinglianState(_loc7_.myPets[0]) || StatusUtil.getIsInHunDunJueDouState(_loc7_.myPets[0])))
            {
               this.parseSummonerPMMDatas(_loc7_,_loc6_);
            }
            else
            {
               this.parseNormalPMMDatas(_loc5_,_loc4_,_loc7_,_loc6_);
            }
            if(Boolean(_loc7_.myPets) && Boolean(_loc7_.myPets[0]))
            {
               _loc8_ = _loc7_.myPets[0];
               _loc9_ = _loc8_.status.split(",");
               for each(_loc10_ in _loc9_)
               {
                  if(_loc10_.indexOf("MB230908_") != -1)
                  {
                     this._isAttackTogether = parseInt(_loc10_.split("_")[1]) == 1;
                     break;
                  }
               }
            }
         }
         this.clientAutoDecSkillPP(param1.dec,_loc3_);
         if((_loc2_ == null || _loc2_.length == 0) && Boolean(param1.hasOwnProperty("tarSId")))
         {
            _loc11_ = int(param1.tarSId);
            this.hittedLocaId = FightData.instance.playerInfo[_loc11_].locaId;
         }
         else
         {
            this.setHittedLocaId(_loc2_,param1.tarSId);
         }
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.AFTER_USE_SKILL,{}));
      }
      
      private function isNewSummoned(param1:PlayerBattleInfo) : Boolean
      {
         if(!FightData.instance.isSummonedPlayer(param1))
         {
            return false;
         }
         var _loc2_:PlayerBattleInfo = FightData.instance.playerInfo[param1.slotId];
         if(_loc2_)
         {
            return _loc2_.myPets.length <= 0 || (_loc2_.myPets[0] as PetBriefInfo).curHp <= 0;
         }
         return true;
      }
      
      private function clientAutoDecSkillPP(param1:Boolean, param2:int) : void
      {
         var _loc3_:PetBriefInfo = null;
         var _loc4_:SkillInfo = null;
         if(param1 && FightData.instance.myInfo.isMyControlSlotId(param2) && !this._isMyPetInPMMList)
         {
            _loc3_ = FightData.instance.myInfo.getMyPlayerInfoBySlotId(param2).myPets[0];
            for each(_loc4_ in _loc3_.skills)
            {
               if(_loc4_.id == this.skillId)
               {
                  _loc4_.decPP();
                  break;
               }
            }
         }
      }
      
      private function parseSummonerPMMDatas(param1:PlayerBattleInfo, param2:Object) : void
      {
         var _loc4_:PetBriefInfo = null;
         var _loc5_:int = 0;
         var _loc3_:PlayerBattleInfo = FightData.instance.playerInfo[param1.slotId];
         if(_loc3_ == null)
         {
            FightData.instance.addPlayer(param1);
            _loc3_ = param1;
         }
         else
         {
            _loc3_.updateIdentityInfo(param2);
            (_loc3_.myPets[0] as PetBriefInfo).updateInfo(param1.myPets[0]);
         }
         if(StatusUtil.getIsInLiangziXinglianState(param1.myPets[0]) && FightData.instance.isMySide(param1.locaId))
         {
            FightData.instance.canControlPetNum += 1;
            FightData.instance.myInfo.addPlayerInfos(param1);
         }
         else if(StatusUtil.getIsInHunDunJueDouState(param1.myPets[0]) && FightData.instance.isMySide(param1.locaId))
         {
            if(FightData.instance.isSummonedPetOfLocalPosition(param1.locaId))
            {
               FightData.instance.canControlPetNum += 1;
               FightData.instance.myInfo.addPlayerInfos(param1);
            }
         }
         if(FightData.instance.isMySide(param1.locaId))
         {
            _loc4_ = _loc3_.myPets[0] as PetBriefInfo;
            _loc5_ = int(_loc4_.raceId);
            if(!this._isRaceAppearObj[_loc4_.raceId + "_" + _loc4_.id])
            {
               if(XinghuiPetType.isShenLingGuard(this._pmService.customData.pmDataMap.getPM(_loc5_).getXinghuiType()))
               {
                  this._isRaceAppearObj[_loc4_.raceId + "_" + _loc4_.id] = true;
                  this.showShenLingAppearMovie(_loc4_.raceId);
               }
               else if(XinghuiPetType.isTongLingSummon(this._pmService.customData.pmDataMap.getPM(_loc5_).getXinghuiType()))
               {
                  this._isRaceAppearObj[_loc4_.raceId + "_" + _loc4_.id] = true;
                  this.showTongLingAppearMovie(_loc4_.raceId);
               }
            }
         }
         this._pmSummonerArr.push(_loc3_);
      }
      
      private function parseNormalPMMDatas(param1:Object, param2:PlayerBattleInfo, param3:PlayerBattleInfo, param4:Object) : void
      {
         var _loc6_:int = 0;
         var _loc14_:Boolean = false;
         var _loc15_:Boolean = false;
         var _loc5_:PlayerBattleInfo = FightData.instance.getPlayerInfoBySlotId(param3.slotId);
         if(param3.PMMasterId == FightData.instance.myInfo.PMMasterId)
         {
            this._isMyPetInPMMList = true;
            _loc14_ = StatusUtil.isPetInLegendFieldState(_loc5_.myPets[0]);
            this._isMyPetJustGetInLegendField = this.isLegendFieldSkill() && !_loc14_;
            _loc15_ = StatusUtil.isPetInDegeneratorXianState(_loc5_.myPets[0]);
            this._isMyPetJustGetInDegeneratorXian = this.isDegeneratorXianSkill() && !_loc15_;
         }
         if(_loc5_ == null || _loc5_.myPets[0] == null || _loc5_.myPets[0].curHp <= 0 && _loc5_.myPets[0].raceId != param3.myPets[0].raceId)
         {
            return;
         }
         _loc5_.myPets[0].updateInfo(param3.myPets[0]);
         var _loc7_:int = int(this.petSkillMess.getPetMes(param3.myPets[0].raceId).attribute);
         _loc6_ = int(this.petSkillMess.compareAttributeRelation(param1.attribute,_loc7_));
         var _loc8_:Boolean = Boolean(SuperPetHelper.isSuperPet(PetBriefInfo(param2.myPets[0]).raceId));
         var _loc9_:String = param4.hpIncList || "";
         var _loc10_:String = param4.shp || "";
         var _loc11_:Array = param4.cbl || [];
         var _loc12_:Object = param4.kList || {};
         var _loc13_:Object = {
            "hpInc":param4.hpInc,
            "player":param3,
            "srt":param4.srt,
            "aor":0,
            "cri":param4.cri,
            "isSkill":true,
            "hpIncList":_loc9_.split(","),
            "skillEffect":_loc6_,
            "ifShowStateMovie":true,
            "isSuperEffect":_loc8_,
            "hpType":param4.hpType,
            "shp":_loc10_.split(","),
            "skillWindWordList":_loc11_,
            "killList":_loc12_
         };
         FightController.instance.pmmStatuses.push(_loc13_);
         this.isCriticalHit = param4.cri;
         this.skillResult = param4.srt;
      }
      
      private function isLegendFieldSkill() : Boolean
      {
         var _loc1_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(this.skillId);
         var _loc2_:int = int(_loc1_.getLegendBigSkillType());
         return _loc1_.getLegendBigSkillType() == PMLegendBigSkillTypes.LEGEND_FIELD_BIG;
      }
      
      private function isDegeneratorXianSkill() : Boolean
      {
         var _loc1_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(this.skillId);
         return _loc1_.getSkillType() == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_XIAN;
      }
      
      private function setHittedLocaId(param1:Array, param2:int) : void
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:Object = null;
         var _loc6_:PlayerBattleInfo = null;
         var _loc5_:Boolean = false;
         if(this.isHittedOnEnemy())
         {
            _loc6_ = FightData.instance.opponents[0] as PlayerBattleInfo;
            this.hittedLocaId = _loc6_.locaId;
            for each(_loc4_ in param1)
            {
               _loc3_ = new PlayerBattleInfo();
               _loc3_.parseInfo(_loc4_);
               _loc3_ = FightData.instance.setLocaId(_loc3_);
               if(!FightData.instance.isMySide(_loc3_.locaId))
               {
                  this.hittedLocaId = _loc3_.locaId;
                  if(param2 == _loc3_.slotId)
                  {
                     _loc5_ = true;
                     break;
                  }
               }
            }
            if(!_loc5_)
            {
               this.hittedLocaId = FightData.instance.getPlayerInfoBySlotId(param2).locaId;
            }
         }
         else if(this.isHittedOnMyTeam())
         {
            this.hittedLocaId = FightData.instance.myInfo.operatingPlayer.locaId;
            for each(_loc4_ in param1)
            {
               _loc3_ = new PlayerBattleInfo();
               _loc3_.parseInfo(_loc4_);
               _loc3_ = FightData.instance.setLocaId(_loc3_);
               if(FightData.instance.isMySide(_loc3_.locaId))
               {
                  this.hittedLocaId = _loc3_.locaId;
                  if(param2 == _loc3_.slotId)
                  {
                     _loc5_ = true;
                     break;
                  }
               }
            }
            if(!_loc5_)
            {
               this.hittedLocaId = FightData.instance.getPlayerInfoBySlotId(param2).locaId;
            }
         }
         else
         {
            this.hittedLocaId = FightData.instance.myInfo.operatingPlayer.locaId;
            for each(_loc4_ in param1)
            {
               _loc3_ = new PlayerBattleInfo();
               _loc3_.parseInfo(_loc4_);
               _loc3_ = FightData.instance.setLocaId(_loc3_);
               if(!FightData.instance.isMySide(_loc3_.locaId))
               {
                  this.hittedLocaId = _loc3_.locaId;
                  if(param2 == _loc3_.slotId)
                  {
                     break;
                  }
               }
            }
         }
      }
      
      private function isHittedOnEnemy() : Boolean
      {
         var _loc1_:Array = [SkillRange.ALL,SkillRange.ENEMY_GROUND,SkillRange.ENEMY_ONE,SkillRange.ENEMY_RANDOM,SkillRange.ENEMY_TEAM,SkillRange.ENEMY_TWO,SkillRange.RANDOM_SELF_EXCLUDE];
         var _loc2_:Array = [SkillRange.SELF,SkillRange.SELF_AND_TEAM,SkillRange.TEAMMATE];
         if(_loc1_.indexOf(this.skillRange) != -1 && FightData.instance.isMySide(this.reqLocaId))
         {
            return true;
         }
         if(_loc2_.indexOf(this.skillRange) != -1 && !FightData.instance.isMySide(this.reqLocaId))
         {
            return true;
         }
         return false;
      }
      
      private function isHittedOnMyTeam() : Boolean
      {
         var _loc1_:Array = [SkillRange.ALL,SkillRange.ENEMY_GROUND,SkillRange.ENEMY_ONE,SkillRange.ENEMY_RANDOM,SkillRange.ENEMY_TEAM,SkillRange.ENEMY_TWO,SkillRange.RANDOM_SELF_EXCLUDE];
         var _loc2_:Array = [SkillRange.SELF,SkillRange.SELF_AND_TEAM,SkillRange.TEAMMATE];
         if(_loc1_.indexOf(this.skillRange) != -1 && !FightData.instance.isMySide(this.reqLocaId))
         {
            return true;
         }
         if(_loc2_.indexOf(this.skillRange) != -1 && FightData.instance.isMySide(this.reqLocaId))
         {
            return true;
         }
         return false;
      }
      
      private function handleMovie(param1:Object) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function onGetSkillEffect(param1:MovieClip) : void
      {
         this.effectMC = param1;
         this.playFight();
      }
      
      private function delayDo(param1:int, param2:Function) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function playFight() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function getUseSkillPoint() : Point
      {
         return PositionUtil.getUseSkillPosition(this.reqLocaId,this.hittedLocaId);
      }
      
      private function shenQiSKillPlayFight() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function gqShenQiSKillPlayFight() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function isHunDunXingHuiSkill(param1:int) : Boolean
      {
         var _loc2_:int = int(this._pmService.customData.pmSkillMap.getSkill(param1).getSkillType());
         return PMSkillTypes.isHunDunSkill(_loc2_);
      }
      
      private function isXingHuiSuperSpiritSkill(param1:int) : Boolean
      {
         var _loc2_:int = int(this._pmService.customData.pmSkillMap.getSkill(param1).getSkillType());
         return PMSkillTypes.isXinghuiSuperSpiritSkill(_loc2_);
      }
      
      private function isXingHuiShenqiKillBig(param1:int) : Boolean
      {
         var _loc2_:int = int(this._pmService.customData.pmSkillMap.getSkill(param1).getSkillType());
         return _loc2_ == PMSkillTypes.XINGHUI_SHENQI_KILL_BIG;
      }
      
      private function isShenQiKillBigSkill(param1:int) : Boolean
      {
         var _loc2_:int = int(this._pmService.customData.pmSkillMap.getSkill(param1).getSkillType());
         return _loc2_ == PMSkillTypes.DEGENERATOR_SHENQI_KILL_BIG;
      }
      
      private function isXinghuiShenQiSpiritSkill(param1:int) : Boolean
      {
         var _loc2_:int = int(this._pmService.customData.pmSkillMap.getSkill(param1).getSkillType());
         return _loc2_ == PMSkillTypes.XINGHUI_SHENQI_SPIRIT_TEJI;
      }
      
      private function isGQShenQiSpiritSkill(param1:int) : Boolean
      {
         var _loc2_:int = int(this._pmService.customData.pmSkillMap.getSkill(param1).getSkillType());
         return _loc2_ == PMSkillTypes.GQ_SHENQI_SPIRIT_SKILL;
      }
      
      private function onMove(param1:Function = null) : void
      {
         if(this._disposed)
         {
            return;
         }
         this.onPlayReturn = param1;
         var _loc2_:Array = this.fightPanel.petMCList;
         var _loc3_:MCPetContainer = _loc2_[this.reqLocaId];
         _loc3_.addEventListener(PetFightEvent.START_EFFECT,this.onEffectStart);
         _loc3_.addEventListener(PetFightEvent.START_DEFEND,this.onDefendStart);
         var _loc4_:Point = this.getPointByLocaId(this.hittedLocaId);
         var _loc5_:Point = this.getPointByLocaId(this.reqLocaId);
         _loc3_.attack(this.skillId,new Point(_loc3_.x,_loc3_.y),_loc4_,this.isCriticalHit,this.isCompletedSkill(),this.onAttackEnd,this.setPetVisible);
         var _loc6_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(this.skillId);
         var _loc7_:int = FightData.instance.getSlotId(this.reqLocaId);
         var _loc8_:int = int(FightData.instance.playerInfo[_loc7_].myPets[0].raceId);
         if(_loc6_.getSkillType() == PMSkillTypes.GQ_HUANLINGSHI_SECOND_SPIRIT_SKILL)
         {
            GQHuanLingShiEffectHelper.playAttackMv(_loc8_,!FightData.instance.isMySide(this.reqLocaId),null);
         }
         this.showSkillTips(this.skillId,_loc3_);
         this.isPlayingAttack = true;
         GQLianSuoEffectHelper.getInstance().playMvHandle(_loc3_.getCurPbi(),this.skillId);
         if(this.pmSkillType == PMSkillTypes.GQ_HUNDUNJUEDOU_SPIRIT_SKILL)
         {
            GQHundunJuedouEffectHelper.addScreenBitmap();
         }
      }
      
      private function getPointByLocaId(param1:int) : Point
      {
         return PositionUtil.getDefaultPosition(param1);
      }
      
      private function onAttackEnd() : void
      {
         var _loc3_:Array = null;
         var _loc4_:Object = null;
         var _loc5_:PlayerBattleInfo = null;
         var _loc6_:MCPetContainer = null;
         this.isPlayingAttack = false;
         var _loc1_:Array = this.fightPanel.petMCList;
         var _loc2_:MCPetContainer = _loc1_[this.reqLocaId];
         _loc2_.removeEventListener(PetFightEvent.START_EFFECT,this.onEffectStart);
         _loc2_.removeEventListener(PetFightEvent.START_DEFEND,this.onDefendStart);
         this.playerTryReturn();
         if(!this.isPlayingEffect)
         {
            if(this._params)
            {
               _loc3_ = this._params.pmmList;
               if(_loc3_)
               {
                  for each(_loc4_ in _loc3_)
                  {
                     _loc5_ = new PlayerBattleInfo();
                     _loc5_.parseInfo(_loc4_);
                     _loc5_ = FightData.instance.setLocaId(_loc5_);
                     _loc6_ = this.fightPanel.petMCList[_loc5_.locaId] as MCPetContainer;
                     if(_loc6_)
                     {
                        _loc6_.setPetColorTransform();
                     }
                  }
               }
               this._params = null;
            }
            this.afterSkillUseEnd();
         }
         this.setPetVisible(false,true);
      }
      
      private function setPetVisible(param1:Boolean, param2:Boolean) : void
      {
         var _loc4_:PlayerBattleInfo = null;
         if(this.fightPanel == null || this.fightPanel.parent == null)
         {
            return;
         }
         var _loc3_:int = 0;
         while(_loc3_ < FightData.SLOT_NUM)
         {
            _loc4_ = FightData.instance.getPlayerInfoByLocalId(_loc3_);
            if(!(_loc4_ == null || _loc4_.myPets.length <= 0 || (_loc4_.myPets[0] as PetBriefInfo).curHp <= 0))
            {
               if(param2)
               {
                  this.fightPanel.setPetVisible(_loc3_,true);
                  this.fightPanel.setPetInfoMCVisible(_loc3_,true);
               }
               else
               {
                  this.fightPanel.setPetInfoMCVisible(_loc3_,false);
                  if(_loc3_ != this.reqLocaId && _loc3_ != this.hittedLocaId && _loc4_.maidservantMsterSlotId != this.reqLocaId || param1 && _loc3_ != this.hittedLocaId)
                  {
                     this.fightPanel.setPetVisible(_loc3_,false);
                  }
               }
            }
            _loc3_++;
         }
      }
      
      private function playerTryReturn() : void
      {
         if(this.onPlayReturn != null)
         {
            this.onPlayReturn.apply();
            this.onPlayReturn = null;
         }
      }
      
      private function showSkillTips(param1:int, param2:MCPetContainer) : void
      {
         var _loc3_:String = this.petSkillMess.getPetSkillMes(param1).pname;
         param2.showSkillName(_loc3_ + "!!");
      }
      
      private function onEffectStart(param1:PetFightEvent) : void
      {
         this.showComboMovie();
         if(FightData.instance.isLowQuality || this.effectMC == null)
         {
            if(this.effectMC != null)
            {
               SkillEffectHelper.recycleEffect(this.effectMC,this.curEffectId);
            }
            this.fightPanel.setBS(this.skillBS);
            this.fightPanel.setBackGroundUp(this._bus);
            this.fightPanel.setPetUp(this._skillParams);
            this.onStartAttEff();
            return;
         }
         var _loc2_:Boolean = true;
         var _loc3_:MCPetContainer = this.fightPanel.petMCList[this.reqLocaId];
         _loc3_.removeEventListener(PetFightEvent.START_EFFECT,this.onEffectStart);
         if(FightData.instance.isMySide(this.reqLocaId))
         {
            _loc2_ = false;
         }
         if(!this.isFullScreen(this.skillRange) && !this.isLegendTotenSkill())
         {
            this.effectMC.scaleX = FightData.instance.teamScale;
            this.effectMC.scaleY = FightData.instance.teamScale;
         }
         this.setEffectMovie(this.reqLocaId,this.hittedLocaId,this.effectMC,this.skillRange,_loc2_);
      }
      
      private function showComboMovie() : void
      {
         var _loc6_:* = undefined;
         if(StringUtil.isNullOrEmpty(this._comboStr))
         {
            return;
         }
         var _loc1_:int = FightData.instance.getSlotId(this.reqLocaId);
         if(FightData.instance.playerInfo[_loc1_] == null)
         {
            return;
         }
         var _loc2_:int = int(FightData.instance.playerInfo[_loc1_].myPets[0].raceId);
         var _loc3_:Array = XinghuiPetType.getShenYuanHuiXiangComboSkillIds(_loc2_);
         if(_loc3_ == null || _loc3_.length <= 0)
         {
            return;
         }
         var _loc4_:Array = this._comboStr.split(",");
         var _loc5_:Array = [];
         for each(_loc6_ in _loc4_)
         {
            if(!StringUtil.isNullOrEmpty(_loc6_))
            {
               _loc5_.push(parseInt(_loc6_));
            }
         }
         if(_loc5_.length <= 0)
         {
            return;
         }
         ShenYuanHuiXiangMovieHelper.showEff(_loc5_,_loc3_,this.fightPanel.layerTop);
      }
      
      private function isLegendTotenSkill() : Boolean
      {
         return SkillMap.instance.checkIsTotenSkill(this.skillId);
      }
      
      private function onDefendStart(param1:PetFightEvent) : void
      {
         this.setDefendView(false);
      }
      
      private function isFullScreen(param1:int) : Boolean
      {
         return param1 == SkillRange.SELF_AND_TEAM || param1 == SkillRange.ENEMY_TEAM || param1 == SkillRange.SELF_EXCLUDE || param1 == SkillRange.ALL;
      }
      
      private function isCompletedSkill() : Boolean
      {
         return SkillMap.instance.checkIsCompletedSkill(this.skillId);
      }
      
      private function setEffectMovie(param1:int, param2:int, param3:MovieClip, param4:int, param5:Boolean) : void
      {
         var labels:Array;
         var hitedPoint:Point;
         var reqPoint:Point;
         var hasAttLabel:Boolean;
         var frameLabel:FrameLabel = null;
         var point:Point = null;
         var p1:int = 0;
         var p2:int = 0;
         var reqLocaId:int = param1;
         var hitedLocaId:int = param2;
         var effect:MovieClip = param3;
         var range:int = param4;
         var isFace:Boolean = param5;
         this.fightPanel.layerEffect.addChild(effect);
         labels = effect.currentLabels;
         hitedPoint = this.getPointByLocaId(hitedLocaId);
         reqPoint = this.getPointByLocaId(reqLocaId);
         if(!this.isLegendTotenSkill() && (range == SkillRange.SELF || range == SkillRange.SELF_AND_TEAM || this.isMove(effect)))
         {
            if(SkillMap.instance.getAttFrame(this.skillId) == 5)
            {
               point = reqPoint;
            }
            else
            {
               point = this.getUseSkillPoint();
            }
            effect.x = point.x;
            effect.y = point.y;
            if(this.isMove(effect))
            {
               p1 = this.getLabelFrame("p1",labels);
               p2 = this.getLabelFrame("p2",labels);
               FightMovieManager.instance.addMovie(effect);
               effect.addFrameScript(p1 - 1,function():*
               {
                  setMove(effect,p2 - p1,isFace,hitedLocaId);
               });
            }
         }
         else if(this.isAll_NotFlip(effect))
         {
            effect.scaleX = 1;
            effect.scaleY = 1;
            effect.x = 0;
            effect.y = 0;
         }
         else if(this.isAll(effect))
         {
            effect.scaleX = 1;
            effect.scaleY = 1;
            if(isFace)
            {
               effect.x = 0;
               effect.y = 0;
            }
            else
            {
               this.flipH(effect);
               effect.x = 960;
               effect.y = 0;
            }
         }
         else
         {
            effect.x = hitedPoint.x;
            effect.y = hitedPoint.y;
         }
         hasAttLabel = false;
         for each(frameLabel in labels)
         {
            if(frameLabel.name == "att" && !hasAttLabel)
            {
               hasAttLabel = true;
               FightMovieManager.instance.addMovie(effect);
               effect.addFrameScript(frameLabel.frame - 1,this.onStartAttEff);
            }
         }
         if(!hasAttLabel)
         {
            FightMovieManager.instance.addMovie(effect);
            effect.addFrameScript(1,this.onStartAttEff);
         }
         FightMovieManager.instance.addMovie(effect);
         effect.addFrameScript(effect.totalFrames - 1,function():*
         {
            onEffectEnd(effect);
         });
         effect.gotoAndPlay(1);
         this.isPlayingEffect = true;
      }
      
      private function onStartAttEff() : void
      {
         if(this.skillRange != SkillRange.SELF)
         {
            this.setDefendView();
         }
         this.refreshInfos();
      }
      
      private function isMove(param1:MovieClip) : Boolean
      {
         var _loc3_:FrameLabel = null;
         var _loc2_:Array = param1.currentLabels;
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.name == "move")
            {
               return true;
            }
         }
         return false;
      }
      
      private function getLabelFrame(param1:String, param2:Array) : int
      {
         var _loc3_:FrameLabel = null;
         for each(_loc3_ in param2)
         {
            if(_loc3_.name == param1)
            {
               return _loc3_.frame;
            }
         }
         return 0;
      }
      
      private function setMove(param1:MovieClip, param2:int, param3:Boolean, param4:int) : void
      {
         var tweenMax:TweenMax = null;
         var mc:MovieClip = param1;
         var durationFrame:int = param2;
         var isFace:Boolean = param3;
         var tarLocaId:int = param4;
         var myTweenLiteVars:TweenLiteVars = new TweenLiteVars();
         var point:Point = this.getUseSkillPoint();
         myTweenLiteVars.prop("x",point.x);
         myTweenLiteVars.prop("y",point.y);
         myTweenLiteVars.useFrames(true);
         myTweenLiteVars.onComplete(function():void
         {
            FightTweenMaxManager.instance.removeTweenMax(tweenMax);
         });
         tweenMax = new TweenMax(mc,durationFrame,myTweenLiteVars);
         FightTweenMaxManager.instance.addTweenMax(tweenMax);
      }
      
      private function isAll(param1:MovieClip) : Boolean
      {
         var _loc3_:FrameLabel = null;
         var _loc2_:Array = param1.currentLabels;
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.name == "all")
            {
               return true;
            }
         }
         return false;
      }
      
      private function isAll_NotFlip(param1:MovieClip) : Boolean
      {
         var _loc3_:FrameLabel = null;
         var _loc2_:Array = param1.currentLabels;
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.name == "all_notflip")
            {
               return true;
            }
         }
         return false;
      }
      
      private function onEffectEnd(param1:MovieClip) : void
      {
         param1.stop();
         FightMovieManager.instance.removeMovie(param1);
         SkillEffectHelper.recycleEffect(param1,this.curEffectId);
         this.isPlayingEffect = false;
         this.fightPanel.showSkillEffectMovie(FightController.instance.pmmStatuses);
         this.fightPanel.setBS(this.skillBS);
         this.fightPanel.setBackGroundUp(this._bus);
         this.fightPanel.setPetUp(this._skillParams);
         this.handleSkillEnd();
      }
      
      private function flipH(param1:DisplayObject) : void
      {
         var _loc2_:Matrix = param1.transform.matrix.clone();
         _loc2_.a = -1;
         param1.transform.matrix = _loc2_;
      }
      
      private function setDefendView(param1:Boolean = true) : void
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:int = 0;
         var _loc4_:MCPetContainer = null;
         var _loc7_:Boolean = false;
         var _loc5_:* = this.skillResult != SkillResults.HIT;
         if(this.isOneDefend())
         {
            _loc4_ = this.fightPanel.petMCList[this.hittedLocaId] as MCPetContainer;
            if(_loc4_ != null)
            {
               _loc4_.setHurt(_loc5_,this.isCriticalHit,param1);
            }
            return;
         }
         if(this.skillRange == SkillRange.ENEMY_TEAM)
         {
            _loc7_ = FightData.instance.isMySide(this.hittedLocaId);
            this.setOneSideDefend(_loc7_,param1);
            return;
         }
         var _loc6_:Array = [];
         if(this.skillRange == SkillRange.SELF_EXCLUDE)
         {
            for each(_loc2_ in FightData.instance.playerInfo)
            {
               _loc3_ = int(_loc2_.locaId);
               if(_loc3_ != this.reqLocaId)
               {
                  _loc6_.push(_loc2_);
               }
            }
         }
         else if(this.skillRange == SkillRange.ALL)
         {
            _loc6_ = FightData.instance.playerInfo;
         }
         for each(_loc2_ in _loc6_)
         {
            _loc4_ = this.fightPanel.petMCList[_loc2_.locaId] as MCPetContainer;
            if(_loc2_.locaId != this.reqLocaId)
            {
               _loc4_.setHurt(_loc5_,this.isCriticalHit,param1);
            }
         }
      }
      
      private function isOneDefend() : Boolean
      {
         var _loc1_:Array = [SkillRange.ENEMY_ONE,SkillRange.ENEMY_RANDOM,SkillRange.RANDOM,SkillRange.RANDOM_SELF_EXCLUDE];
         if(_loc1_.indexOf(this.skillRange) == -1)
         {
            return false;
         }
         return true;
      }
      
      private function setOneSideDefend(param1:Boolean, param2:Boolean) : void
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:int = 0;
         var _loc5_:MCPetContainer = null;
         var _loc6_:Array = null;
         if(param1)
         {
            _loc6_ = FightData.instance.teammates;
         }
         else
         {
            _loc6_ = FightData.instance.opponents;
         }
         var _loc7_:* = this.skillResult != SkillResults.HIT;
         for each(_loc3_ in _loc6_)
         {
            _loc4_ = int(_loc3_.locaId);
            _loc5_ = this.fightPanel.petMCList[_loc4_] as MCPetContainer;
            _loc5_.setHurt(_loc7_,this.isCriticalHit,param2);
         }
      }
      
      private function refreshInfos() : void
      {
         this.fightPanel.refreshInfosAfterSkill(FightController.instance.pmmStatuses);
         this.fightPanel.refreshTxt(FightController.instance.desc);
      }
      
      private function handleSkillEnd() : void
      {
         var player:PlayerBattleInfo = null;
         var locaId:int = 0;
         var thePet:MCPetContainer = null;
         var pmmList:Array = null;
         var obj:Object = null;
         var playerInfo:PlayerBattleInfo = null;
         var delayFrame:int = 0;
         for each(player in FightData.instance.playerInfo)
         {
            locaId = int(player.locaId);
            thePet = this.fightPanel.petMCList[locaId] as MCPetContainer;
            if(Boolean(thePet) && thePet.isDefending)
            {
               thePet.setNormal();
            }
         }
         if(this._params)
         {
            pmmList = this._params.pmmList;
            for each(obj in pmmList)
            {
               playerInfo = new PlayerBattleInfo();
               playerInfo.parseInfo(obj);
               playerInfo = FightData.instance.setLocaId(playerInfo);
               thePet = this.fightPanel.petMCList[playerInfo.locaId] as MCPetContainer;
               if(thePet)
               {
                  thePet.setPetColorTransform();
               }
            }
            this._params = null;
         }
         if(this.checkIsMultipleHit(FightController.instance.pmmStatuses))
         {
            delayFrame = this.getMuiltHitDecHpDelayFrame(this.getMultipleHitTimes(FightController.instance.pmmStatuses));
            this.delayDo(delayFrame,function():void
            {
               isPlayingEffect = false;
               if(!isPlayingAttack)
               {
                  afterSkillUseEnd();
               }
            });
            this.isPlayingEffect = true;
         }
         else if(!this.isPlayingAttack)
         {
            this.afterSkillUseEnd();
         }
      }
      
      private function afterSkillUseEnd() : void
      {
         if(this._pmSummonerArr.length != 0)
         {
            SummonPetProcessor.instance.summonPet(this._pmSummonerArr);
            this._pmSummonerArr = [];
         }
         else
         {
            if(this._isMyPetJustGetInLegendField || this._isMyPetJustGetInDegeneratorXian)
            {
               this.fightPanel.setFightClicked(true);
               this.fightPanel.disableClick();
            }
            FightController.instance.handleHunDouJueDou();
            FightController.instance.startHandle();
         }
      }
      
      private function getMuiltHitDecHpDelayFrame(param1:int) : int
      {
         if(DocPetFight.skipBattlePresentation)
         {
            return 1;
         }
         var _loc2_:int = 2 * 25;
         var _loc3_:int = 8;
         if(param1 > 8)
         {
            _loc3_ = Math.ceil(_loc2_ / param1);
         }
         return _loc3_ * param1;
      }
      
      private function checkIsMultipleHit(param1:Array) : Boolean
      {
         return this.getMultipleHitTimes(param1) > 0;
      }
      
      private function getMultipleHitTimes(param1:Array) : int
      {
         var _loc2_:Object = null;
         var _loc3_:Array = null;
         for each(_loc2_ in param1)
         {
            _loc3_ = _loc2_.hpIncList;
            if(_loc3_)
            {
               return _loc3_.length;
            }
         }
         return 0;
      }
      
      private function isDoNothingDuringMultiRounds(param1:Boolean) : Boolean
      {
         if(this.skillId == 0)
         {
            return true;
         }
         var _loc2_:Object = this.isMultiRoundsSkill(this.skillId);
         if(_loc2_ == null)
         {
            return false;
         }
         if(param1)
         {
            if(_loc2_.s1 == -1)
            {
               return true;
            }
            this.skillRange = _loc2_.s1;
         }
         else
         {
            if(_loc2_.s2 == -1)
            {
               return true;
            }
            this.skillRange = _loc2_.s2;
         }
         return false;
      }
      
      private function isMultiRoundsSkill(param1:int) : Object
      {
         var _loc2_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         var _loc3_:int = -2;
         var _loc4_:int = -2;
         if(_loc2_.getPetSkillMes(param1).skill1 != null && _loc2_.getPetSkillMes(param1).skill1 != undefined)
         {
            _loc3_ = int(_loc2_.getPetSkillMes(param1).skill1);
         }
         if(_loc2_.getPetSkillMes(param1).skill2 != null && _loc2_.getPetSkillMes(param1).skill2 != undefined)
         {
            _loc4_ = int(_loc2_.getPetSkillMes(param1).skill2);
         }
         if(_loc3_ != -2 && _loc4_ != -2)
         {
            return {
               "s1":_loc3_,
               "s2":_loc4_
            };
         }
         return null;
      }
      
      private function showShenLingAppearMovie(param1:int) : void
      {
         var _loc2_:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
         if(LocalStore.getValue(XinghuiPetType.isCloseShenLingMvkey,UserInfo.userName))
         {
            return;
         }
         var _loc3_:String = "xinghuipet/shenling/effect/xinghuishenlingappearmv";
         var _loc4_:String = "mmo.xinghuipet.shenling.XingHuiShenLingAppearMv";
         var _loc5_:Object = XinghuiPetType.getShenLingGuard_Object(param1);
         if((Boolean(_loc5_)) && _loc5_.summonEffect > 1)
         {
            _loc3_ += "_" + _loc5_.summonEffect;
            _loc4_ += "_" + _loc5_.summonEffect;
         }
         this.playAnimation(_loc3_,_loc4_);
      }
      
      private function showTongLingAppearMovie(param1:int) : void
      {
         var _loc2_:String = "xinghuipet/tongling/effect/xinghuitonglingappearmv";
         var _loc3_:String = "mmo.xinghuipet.tongling.XingHuiTongLingAppearMv";
         var _loc4_:int = 1;
         var _loc5_:Object = XinghuiPetType.getTongLingSummon_Object(param1);
         if(_loc5_)
         {
            _loc4_ = int(_loc5_.fightEffect);
         }
         _loc2_ += "_" + _loc4_;
         _loc3_ += "_" + _loc4_;
         this.playAnimation(_loc2_,_loc3_);
      }
      
      private function playAnimation(param1:String, param2:String, param3:Function = null) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      public function dispose() : void
      {
         this._disposed = true;
         if(this._skillEffectLoader != null)
         {
            this._skillEffectLoader.dispose();
         }
         if(this._aoyiMoveHelper != null)
         {
            this._aoyiMoveHelper.dispose();
         }
         this.effectMC = null;
         this.fightPanel = null;
         this._pmSummonerArr = [];
         this._skillEffectLoader = null;
         this.onPlayReturn = null;
         this._params = null;
         _instance = null;
      }
   }
}

