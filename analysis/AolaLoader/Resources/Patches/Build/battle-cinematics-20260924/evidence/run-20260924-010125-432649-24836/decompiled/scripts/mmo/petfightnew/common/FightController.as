package mmo.petfightnew.common
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.display.StageQuality;
   import flash.events.EventDispatcher;
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.media.Sound;
   import flash.utils.Timer;
   import mmo.common.bonus.ShowBonusHelper;
   import mmo.common.event.EnterFrameManager;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.sound.SoundManager;
   import mmo.common.sound.SoundPlayer;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.live.ILiveService;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.GQDengShenChangJieSkillParse;
   import mmo.interfaces.pet.data.GQZhenLiFaDianSkillParse;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.ILevelUp;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.IPetFightConfig;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.fightmusic.IFightMusic;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.LoaderContainer;
   import mmo.petfightnew.DocPetFight;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.event.FightInnerEvent;
   import mmo.petfightnew.common.fightcontroller.AttributeLevelController;
   import mmo.petfightnew.common.fightcontroller.BackGroundStatus;
   import mmo.petfightnew.common.fightcontroller.BattleNextTurn;
   import mmo.petfightnew.common.fightcontroller.BattlePmDying;
   import mmo.petfightnew.common.fightcontroller.BattleSmallTurn;
   import mmo.petfightnew.common.fightcontroller.BossMovieHelper;
   import mmo.petfightnew.common.fightcontroller.CatchPm;
   import mmo.petfightnew.common.fightcontroller.ChangePetView;
   import mmo.petfightnew.common.fightcontroller.ChangeViewStatus;
   import mmo.petfightnew.common.fightcontroller.Escape;
   import mmo.petfightnew.common.fightcontroller.FightTalk;
   import mmo.petfightnew.common.fightcontroller.FinBattle;
   import mmo.petfightnew.common.fightcontroller.FinBattleTimer;
   import mmo.petfightnew.common.fightcontroller.LosePanel;
   import mmo.petfightnew.common.fightcontroller.Status;
   import mmo.petfightnew.common.fightcontroller.SummonPetProcessor;
   import mmo.petfightnew.common.fightcontroller.SwitchPm;
   import mmo.petfightnew.common.fightcontroller.TerritoryRelive;
   import mmo.petfightnew.common.fightcontroller.TrainingTower;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.fightcontroller.UseItem;
   import mmo.petfightnew.common.fightcontroller.UseSkill;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.FIP_Controller;
   import mmo.petfightnew.common.manager.FightBitmapDataCache;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.PreloadListManager;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.panel.SuccessPanel;
   import mmo.petfightnew.common.pet.PetAssetsLoader;
   import mmo.petfightnew.common.util.BSUtil;
   import mmo.petfightnew.common.util.GQHundunJuedouEffectHelper;
   import mmo.petfightnew.common.util.PositionUtil;
   
   public class FightController extends EventDispatcher
   {
      
      private static var _instance:FightController;
      
      private static var _processQueue:Array = [];
      
      private static var _endPanels:Array = [];
      
      public static var isHandlePanel:Boolean = true;
      
      public static var isShowBattleEffectiveness:Boolean = false;
      
      public static var isAutoUseSkill:Boolean = false;
      
      private var timer:Timer;
      
      private var petDataService:IPetDataService;
      
      private var levelUpService:ILevelUp;
      
      private var materialPanelService:IMaterialGetPanel;
      
      private var _canUseAutoTimes:int;
      
      private var _gameOptionSvr:IGameOptionService = ServiceContainer.getService(IGameOptionService);
      
      private var _petFightSvr:IPetFightConfig = ServicePool.instance.getService(IPetFight);
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      public var desc:String;
      
      public var pmmStatuses:Array = [];
      
      public var turnCount:int;
      
      public var fightPanel:FightPanel;
      
      public var canEscape:Boolean = true;
      
      public var canSwitch:Boolean = false;
      
      public var canCatch:Boolean = false;
      
      public var isMatchArena:Boolean = false;
      
      public var whoWon:int = -1;
      
      public var isAuto:Boolean = false;
      
      public var canAuto:Boolean = true;
      
      public var useAiType:int = 0;
      
      public var isCatchablePet:Boolean = true;
      
      public var ipetmusic:IFightMusic;
      
      public var trainingTowerType:int = -1;
      
      public var id:int = -1;
      
      public var isVirtualFight:Boolean = false;
      
      private var fightIsWin:Boolean = true;
      
      private var isHandling:Boolean = false;
      
      private var _isShowDropBn:Boolean = true;
      
      private var _isShowFightInfo:Boolean = true;
      
      private var _isEscapeEvacuate:Boolean = false;
      
      private var gainExp:Boolean = false;
      
      private var haveShowGainExpPanel:Boolean = false;
      
      private var _isReplay:Boolean = false;
      
      public var useSkillCacher:UseSkillCacher = new UseSkillCacher();
      
      private var _replayTurnCount:int = 0;
      
      private var _turnCountBefore:int = 0;
      
      private var _lastTimeUpTurn:int = 0;
      
      private var _isDisposed:Boolean = false;
      
      private var _finishWithNoPanel:Boolean = false;
      
      private var _isLive:Boolean = false;
      
      private var _isPetFightSpaceLive:Boolean = false;
      
      private var _isFirstHandleEnd:Boolean = true;
      
      public function FightController()
      {
         super();
         _processQueue = [];
         _endPanels = [];
         this.resetLastTimeUpTurn();
         SocketClient.instance.addEventListener(PetClient.RSPN_ESCAPE,this.onEscape);
         SocketClient.instance.addEventListener(PetClient.RSPN_FIN_BATTLE,this.onFinishBefore);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_NEXT_TURN,this.onNextTurnBefore);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_STATUS_ON_START,this.onBattleStartStatus);
         SocketClient.instance.addEventListener(PetClient.RSPN_SWITCH_PM,this.onSwitchPmBefore);
         SocketClient.instance.addEventListener(PetClient.RSPN_PET_TALK,this.onPetTalk);
         SocketClient.instance.addEventListener("103_6",this.onGetSpecialBonus);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_SUMMON_PM,this.onBattleSummonPm);
      }
      
      public static function get instance() : FightController
      {
         if(_instance == null)
         {
            _instance = new FightController();
         }
         return _instance;
      }
      
      public function resetLastTimeUpTurn() : void
      {
         this._lastTimeUpTurn = -2;
      }
      
      public function init(param1:FightPanel) : void
      {
         FightItemData.instance.init();
         this.fightPanel = param1;
         this.fightPanel.refreshFaZhenSkill();
         FightMcPool.instance.init(FightData.instance.applicationDomain);
         UseSkill.instance.init(this.fightPanel);
         FinBattle.instance.init(this.fightPanel);
         Escape.instance.init(this.fightPanel);
         BattlePmDying.instance.init(this.fightPanel);
         CatchPm.instance.init(this.fightPanel);
         UseItem.instance.init(this.fightPanel);
         Status.instance.init(this.fightPanel);
         BackGroundStatus.instance.init(this.fightPanel);
         BattleNextTurn.instance.init(this.fightPanel);
         BattleSmallTurn.instance.init(this.fightPanel);
         SwitchPm.instance.init(this.fightPanel);
         TrainingTower.instance.init(this.fightPanel,this.trainingTowerType);
         FightTalk.instance.init(this.fightPanel);
         BossMovieHelper.instance.init(this.fightPanel);
         ChangePetView.instance.init(this.fightPanel);
         ChangeViewStatus.instance.init(this.fightPanel);
         SummonPetProcessor.instance.init(this.fightPanel);
         TerritoryRelive.instance.init(this.fightPanel);
         FIP_Controller.instance.init(this.fightPanel);
         this.petDataService = ServicePool.instance.getService(IPetDataService);
         this.materialPanelService = ServicePool.instance.getService(IMaterialGetPanel);
         this.levelUpService = ServicePool.instance.getService(ILevelUp);
         if(this._gameOptionSvr.isFightSound)
         {
            SoundManager.instance.playFightBgMusic();
         }
         this.turnCount = 0;
         if(!this._isReplay)
         {
            this.turnCount = Math.max(0,this._turnCountBefore - 1);
            this.addBattleListener();
         }
         this.gainExp = false;
         this.haveShowGainExpPanel = false;
         DocPetFight.noteDiagnosticPanel(param1);
      }
      
      private function setStageQuality() : void
      {
         var _loc1_:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
         if(_loc1_.isFightLowQuality)
         {
            LoaderContainer.instance.stage.quality = StageQuality.LOW;
         }
         else
         {
            LoaderContainer.instance.stage.quality = StageQuality.HIGH;
         }
      }
      
      private function addBattleListener() : void
      {
         SocketClient.instance.removeEventListener(PetClient.RSPN_FIN_BATTLE,this.onFinishBefore);
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_NEXT_TURN,this.onNextTurnBefore);
         SocketClient.instance.removeEventListener(PetClient.RSPN_SWITCH_PM,this.onSwitchPmBefore);
         SocketClient.instance.addEventListener(PetClient.RSPN_SWITCH_PM,this.onSwitchPM);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_POWERUP,this.onPowerUp);
         SocketClient.instance.addEventListener(PetClient.RSPN_PM_GAIN_EXP,this.onGainExp);
         SocketClient.instance.addEventListener(PetClient.RSPN_CATCH_PM,this.onCatchPM);
         SocketClient.instance.addEventListener(PetClient.RSPN_USE_SKILL,this.onUseSkill);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_NEXT_TURN,this.onNextTurn);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_NEXT_TURN_SMALL,this.onBattleSmallTurn);
         SocketClient.instance.addEventListener(PetClient.RSPN_STATUS_UPDATE,this.onStatusUpdate);
         SocketClient.instance.addEventListener(PetClient.RSPN_FIN_BATTLE,this.onFinish);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_PM_DYING,this.onNeedSwitch);
         SocketClient.instance.addEventListener(PetClient.RSPN_USE_ITEM,this.onUseItem);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_PM_STATUS,this.onStatus);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_BACKGROUND_STATUS,this.onBackStatus);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_STATUS_UPDATE4,this.onChangeViewStatus);
         SocketClient.instance.addEventListener(PetClient2.cmdPMDropBonus,this.onBonus);
         SocketClient.instance.addEventListener(PetClient.RSPN_READY,this.onReady);
         SocketClient.instance.addEventListener(PetClient.RSPN_USE_SUMMON_SKILL,this.onSummonPet);
         SocketClient.instance.addEventListener(PetClient.RSPN_CHANGE_DEGENERATOR_SKILL,this.onChangeDegeneratorSkill);
         SocketClient.instance.addEventListener(PetClient.RSPN_CHANGE_STATE_AT_PLAY_OPERATE,this.onChangeStateAtOperate);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_RELIVE,this.onBattleRelive);
         this.petDataService.addEventListener(PetDataServiceEvent.RSPN_PM_GAIN_NEW_SKILL,this.onRspn_pm_gain_new_skill);
         this.petDataService.addEventListener(PetDataServiceEvent.RSPN_PM_GAIN_EXP,this.onRspn_pm_gain_exp);
         this.petDataService.addEventListener(PetDataServiceEvent.RSPN_PM_LEVELUP,this.onRspn_pm_levelup);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.SHOW_END_PANEL,this.onGetFightEndPanel);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.CLICK_RESULT_PANEL,this.onClickPanel);
         FightEventDispatcher.instance.addEventListener(FightInnerEvent.ON_MOUSE_OVER_PET,this.onOverPet);
         FightEventDispatcher.instance.addEventListener(FightInnerEvent.ON_MOUSE_OUT_PET,this.onOutPet);
      }
      
      public function addReplayListener() : void
      {
         SocketClient.instance.removeEventListener(PetClient.RSPN_FIN_BATTLE,this.onFinishBefore);
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_NEXT_TURN,this.onNextTurnBefore);
         SocketClient.instance.addEventListener(PetClient.RSPN_SWITCH_PM,this.onSwitchPM);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_POWERUP,this.onPowerUp);
         SocketClient.instance.addEventListener(PetClient.RSPN_PM_GAIN_EXP,this.onGainExp);
         SocketClient.instance.addEventListener(PetClient.RSPN_CATCH_PM,this.onCatchPM);
         SocketClient.instance.addEventListener(PetClient.RSPN_USE_SKILL,this.onUseSkill);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_NEXT_TURN,this.onNextTurn);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_NEXT_TURN_SMALL,this.onBattleSmallTurn);
         SocketClient.instance.addEventListener(PetClient.RSPN_STATUS_UPDATE,this.onStatusUpdate);
         SocketClient.instance.addEventListener(PetClient.RSPN_FIN_BATTLE,this.onFinish);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_PM_DYING,this.onNeedSwitch);
         SocketClient.instance.addEventListener(PetClient.RSPN_USE_ITEM,this.onUseItem);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_PM_STATUS,this.onStatus);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_BACKGROUND_STATUS,this.onBackStatus);
         SocketClient.instance.addEventListener(PetClient.RSPN_BATTLE_STATUS_UPDATE4,this.onChangeViewStatus);
         SocketClient.instance.addEventListener(PetClient.RSPN_USE_SUMMON_SKILL,this.onSummonPet);
         FightEventDispatcher.instance.addEventListener(FightInnerEvent.ON_MOUSE_OVER_PET,this.onOverPet);
         FightEventDispatcher.instance.addEventListener(FightInnerEvent.ON_MOUSE_OUT_PET,this.onOutPet);
      }
      
      private function onOverPet(param1:CommonEvent) : void
      {
         AttributeLevelController.instance.addAttributeLevelPanel(param1.params.locaId);
      }
      
      private function onOutPet(param1:CommonEvent) : void
      {
         AttributeLevelController.instance.removeAttributeLevelPanel(param1.params.locaId);
      }
      
      private function onGetSpecialBonus(param1:SocketClientEvent) : void
      {
         var _loc2_:Array = null;
         var _loc3_:int = 0;
         if(param1.params.v == 2)
         {
            return;
         }
         if(this._petFightSvr.isInTerritoryFight)
         {
            return;
         }
         isHandlePanel = true;
         if(param1.params.bn != null)
         {
            _loc2_ = param1.params.bn;
            _loc3_ = 0;
            while(_loc3_ < _loc2_.length)
            {
               this.addEndPanel("showDrop",_loc2_[_loc3_]);
               _loc3_++;
            }
         }
      }
      
      private function onEscape(param1:SocketClientEvent) : void
      {
         if(param1.params.v == 2)
         {
            return;
         }
         if(this._petFightSvr.isInTerritoryFight)
         {
            return;
         }
         this.add(PetClient.RSPN_ESCAPE,param1.params);
      }
      
      private function onNextTurnBefore(param1:SocketClientEvent) : void
      {
         if(param1.params.v == 2)
         {
            return;
         }
         if(this._petFightSvr.isInTerritoryFight)
         {
            return;
         }
         ++this._turnCountBefore;
      }
      
      private function onFinishBefore(param1:SocketClientEvent) : void
      {
         if(param1.params.v == 2)
         {
            return;
         }
         if(this._petFightSvr.isInTerritoryFight)
         {
            return;
         }
         SocketClient.instance.removeEventListener(PetClient.RSPN_FIN_BATTLE,this.onFinishBefore);
         this.whoWon = param1.params.wl;
         this.add(PetClient.RSPN_FIN_BATTLE,param1.params);
      }
      
      private function onSwitchPmBefore(param1:SocketClientEvent) : void
      {
         if(param1.params.v == 2)
         {
            return;
         }
         if(this._petFightSvr.isInTerritoryFight)
         {
            return;
         }
         if(param1.params.battleView == null)
         {
            return;
         }
         if(this._isReplay)
         {
            return;
         }
         var _loc2_:PlayerBattleInfo = new PlayerBattleInfo();
         _loc2_.parseInfo(param1.params);
         var _loc3_:String = new String(param1.params.bs);
         var _loc4_:Object = param1.params.battleView.oldPM;
         var _loc5_:PetBriefInfo = new PetBriefInfo();
         _loc5_.parseInfo(_loc4_);
         this.add("Before_PetClient_RSPN_SWITCH_PM",{
            "playerInfo":_loc2_,
            "extInfo":{
               "bs":_loc3_,
               "oldPMInfo":_loc5_,
               "desc":param1.params.desc
            }
         });
         this.preLoadPet(_loc2_);
      }
      
      private function onSwitchPM(param1:SocketClientEvent) : void
      {
         if(param1.params.battleView == null)
         {
            return;
         }
         var _loc2_:PlayerBattleInfo = new PlayerBattleInfo();
         _loc2_.parseInfo(param1.params);
         var _loc3_:String = new String(param1.params.bs);
         var _loc4_:Object = param1.params.battleView.oldPM;
         var _loc5_:PetBriefInfo = new PetBriefInfo();
         _loc5_.parseInfo(_loc4_);
         this.add(PetClient.RSPN_SWITCH_PM,{
            "playerInfo":_loc2_,
            "extInfo":{
               "bs":_loc3_,
               "oldPMInfo":_loc5_,
               "pmmList":param1.params.pmmList,
               "desc":param1.params.desc
            }
         });
         this.preLoadPet(_loc2_);
      }
      
      private function preLoadPet(param1:PlayerBattleInfo) : void
      {
         var _loc9_:GQDengShenChangJieSkillParse = null;
         var _loc10_:GQZhenLiFaDianSkillParse = null;
         var _loc2_:int = int((param1.myPets[0] as PetBriefInfo).viewId);
         var _loc3_:int = FightData.instance.getLocaId(param1.slotId);
         var _loc4_:int = FightData.instance.getFaceIdByLocalId(_loc3_);
         var _loc5_:int = int(PetAssetsMap.getPetFlaId(_loc2_));
         var _loc6_:PetAssetsLoader = new PetAssetsLoader(_loc5_,_loc4_);
         var _loc7_:PetBriefInfo = param1.myPets[0] as PetBriefInfo;
         _loc6_.preLoadPetFile();
         var _loc8_:PMData = this._pmSvr.getOperationPM((param1.myPets[0] as PetBriefInfo).raceId).pmData;
         if(GQPetType.isDengShenChangJie(_loc8_.getGQType()))
         {
            _loc9_ = GQDengShenChangJieSkillParse.getDengShenChangJieSkillParse(_loc7_.raceId);
            _loc6_ = new PetAssetsLoader(PetAssetsMap.getPetFlaId(_loc9_.changeViewId),_loc4_);
            _loc6_.preLoadPetFile();
         }
         else if(GQPetType.isZhenLiFaDian(_loc8_.getGQType()))
         {
            _loc10_ = GQZhenLiFaDianSkillParse.getZhenLiFaDianSkillParse(_loc7_.raceId);
            _loc6_ = new PetAssetsLoader(PetAssetsMap.getPetFlaId(_loc10_.changeViewId),_loc4_);
            _loc6_.preLoadPetFile();
         }
      }
      
      private function onGainExp(param1:SocketClientEvent) : void
      {
         if(param1.params.v == 2)
         {
            return;
         }
         this.add(PetClient.RSPN_PM_GAIN_EXP,{
            "costExp":param1.params.costExp,
            "curExp":param1.params.curExp,
            "nextExp":param1.params.nextExp
         });
      }
      
      private function onCatchPM(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_CATCH_PM,param1.params);
      }
      
      private function onUseSkill(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_USE_SKILL,param1.params);
      }
      
      private function onPowerUp(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_BATTLE_POWERUP,param1.params);
      }
      
      private function onNextTurn(param1:SocketClientEvent) : void
      {
         ++this._replayTurnCount;
         this.add(PetClient.RSPN_BATTLE_NEXT_TURN,param1.params);
         if(this.fightPanel != null)
         {
            FightData.instance.myInfo.operatingPlayer.faZhenInfo.parseInfo(param1.params.extraMsg);
            this.fightPanel.refreshFaZhenSkill();
         }
      }
      
      private function onBattleSmallTurn(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_BATTLE_NEXT_TURN_SMALL,param1.params);
      }
      
      private function onStatusUpdate(param1:SocketClientEvent) : void
      {
         var _loc2_:PlayerBattleInfo = new PlayerBattleInfo();
         _loc2_.parseInfo(param1.params);
         this.add(PetClient.RSPN_STATUS_UPDATE,{"info":_loc2_});
      }
      
      private function onFinish(param1:SocketClientEvent) : void
      {
         this.whoWon = param1.params.wl;
         this._finishWithNoPanel = param1.params.nopl;
         this.add(PetClient.RSPN_FIN_BATTLE,param1.params);
         if(!this.isReplay && !FightData.instance.isPVE)
         {
            FinBattleTimer.instance.addTimer();
         }
      }
      
      private function onNeedSwitch(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_BATTLE_PM_DYING,param1.params);
      }
      
      private function checkSwitch(param1:Object) : Boolean
      {
         var _loc2_:Array = null;
         var _loc3_:String = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         if(param1.s != null && param1.s.length > 0)
         {
            return true;
         }
         if(param1.ss != null && param1.ss.length > 0)
         {
            _loc2_ = param1.ss.split("#");
            for each(_loc3_ in _loc2_)
            {
               _loc4_ = parseInt(_loc3_.substr(0,_loc3_.indexOf("-")));
               _loc5_ = FightData.instance.getLocaId(_loc4_);
               if(FightData.instance.playerInfo[_loc5_].PMMasterId > 0)
               {
                  return true;
               }
            }
         }
         return false;
      }
      
      private function onGetFightEndPanel(param1:PetFightEvent) : void
      {
         this.fightIsWin = param1.params.iswin;
      }
      
      private function onUseItem(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_USE_ITEM,param1.params);
      }
      
      private function onStatus(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_BATTLE_PM_STATUS,param1.params);
      }
      
      private function onBattleStartStatus(param1:SocketClientEvent) : void
      {
         if(param1.params.v == 2)
         {
            return;
         }
         if(this._petFightSvr.isInTerritoryFight)
         {
            return;
         }
         this.add(PetClient.RSPN_BATTLE_STATUS_ON_START,param1.params);
      }
      
      private function onBackStatus(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_BATTLE_BACKGROUND_STATUS,param1.params);
      }
      
      private function onChangeViewStatus(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_BATTLE_STATUS_UPDATE4,param1.params);
      }
      
      private function onSummonPet(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_USE_SUMMON_SKILL,param1.params);
      }
      
      private function onChangeStateAtOperate(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_CHANGE_STATE_AT_PLAY_OPERATE,param1.params);
      }
      
      private function onBattleRelive(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_BATTLE_RELIVE,param1.params);
      }
      
      private function onPetTalk(param1:SocketClientEvent) : void
      {
         if(param1.params.v == 2)
         {
            return;
         }
         this.add(PetClient.RSPN_PET_TALK,param1.params);
      }
      
      private function onBattleSummonPm(param1:SocketClientEvent) : void
      {
         if(param1.params.v == 2)
         {
            return;
         }
         this.add(PetClient.RSPN_BATTLE_SUMMON_PM,param1.params);
      }
      
      private function onChangeDegeneratorSkill(param1:SocketClientEvent) : void
      {
         this.add(PetClient.RSPN_CHANGE_DEGENERATOR_SKILL,param1.params);
      }
      
      private function onBonus(param1:SocketClientEvent) : void
      {
         if(!this._isShowDropBn)
         {
            return;
         }
         this.addEndPanel(PetClient2.cmdPMDropBonus,param1.params);
      }
      
      private function onReady(param1:SocketClientEvent) : void
      {
         var _loc3_:int = 0;
         var _loc2_:int = int(param1.params.reqSId);
         if(FightData.instance.playerInfo[_loc2_] == null)
         {
            return;
         }
         if(_loc2_ > 0)
         {
            _loc3_ = int(FightData.instance.playerInfo[_loc2_].locaId);
            this.fightPanel.removeReady(_loc3_);
         }
      }
      
      private function onRspn_pm_gain_new_skill(param1:PetDataServiceEvent) : void
      {
         this.addEndPanel(PetDataServiceEvent.RSPN_PM_GAIN_NEW_SKILL,{});
      }
      
      private function onRspn_pm_gain_exp(param1:PetDataServiceEvent) : void
      {
         if(this.gainExp)
         {
            return;
         }
         this.gainExp = true;
         this.addEndPanel(PetDataServiceEvent.RSPN_PM_GAIN_EXP,{});
      }
      
      private function onRspn_pm_levelup(param1:PetDataServiceEvent) : void
      {
         this.addEndPanel(PetDataServiceEvent.RSPN_PM_LEVELUP,{});
      }
      
      private function addEndPanel(param1:String, param2:Object) : void
      {
         var _loc3_:Object = {
            "cmd":param1,
            "params":param2
         };
         _endPanels.push(_loc3_);
      }
      
      private function onClickPanel(param1:PetFightEvent) : void
      {
         this.handlePanel();
      }
      
      public function handlePanel() : void
      {
         var _loc1_:Object = null;
         var _loc3_:Array = null;
         var _loc4_:String = null;
         var _loc5_:Object = null;
         var _loc6_:Object = null;
         var _loc7_:Object = null;
         SoundManager.instance.stopBackgroundMusic();
         if(this._finishWithNoPanel)
         {
            this.closeFightPanel();
            return;
         }
         if(_endPanels.length <= 0 && this._isFirstHandleEnd && !this.isReplay)
         {
            this._isFirstHandleEnd = false;
            if(this.whoWon == 2)
            {
               this.levelUpService.showPureFightWin(FightData.instance.fightEndPbi);
               return;
            }
            if(this.whoWon == 1)
            {
               new LosePanel(this.handlePanel,this.handlePanel,this.handlePanel).showPanel();
               return;
            }
         }
         if(_endPanels.length <= 0)
         {
            this.closeFightPanel();
            return;
         }
         this._isFirstHandleEnd = false;
         if(!isHandlePanel)
         {
            return;
         }
         _loc1_ = _endPanels.shift();
         var _loc2_:String = _loc1_.cmd;
         switch(_loc2_)
         {
            case PetDataServiceEvent.RSPN_PM_GAIN_NEW_SKILL:
               this.levelUpService.showReplaceSkill();
               break;
            case PetDataServiceEvent.RSPN_PM_GAIN_EXP:
               if(this.haveShowGainExpPanel)
               {
                  this.handlePanel();
                  break;
               }
               this.haveShowGainExpPanel = true;
               this.levelUpService.showExpPanelAfterFight(this.fightIsWin,false,FightData.instance.fightEndPbi);
               break;
            case PetDataServiceEvent.RSPN_PM_LEVELUP:
               if(this.haveShowGainExpPanel)
               {
                  _loc5_ = {
                     "cmd":"PmLevelUp",
                     "params":_loc1_.params
                  };
                  _endPanels.splice(0,0,_loc5_);
                  this.handlePanel();
                  break;
               }
               this.haveShowGainExpPanel = true;
               this.levelUpService.showExpPanelAfterFight(this.fightIsWin,true,FightData.instance.fightEndPbi);
               _loc6_ = {
                  "cmd":"PmLevelUp",
                  "params":_loc1_.params
               };
               _endPanels.splice(0,0,_loc6_);
               break;
            case "PmLevelUp":
               this.levelUpService.showLevelUp();
               break;
            case PetClient2.cmdPMDropBonus:
               _loc3_ = _loc1_.params.bn;
               _loc4_ = "";
               if(_loc3_ != null && _loc3_.length > 0)
               {
                  for each(_loc7_ in _loc3_)
                  {
                     this.addEndPanel("showDrop",_loc7_);
                  }
               }
               this.handlePanel();
               break;
            case "showDrop":
               ShowBonusHelper.showBonus([_loc1_.params],null);
         }
      }
      
      public function add(param1:*, param2:Object) : void
      {
         var _loc3_:Object = {
            "cmd":param1,
            "params":param2
         };
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("Fight_Debug_Event",{
            "cmd":param1,
            "params":param2
         }));
         if(!this.isReplay)
         {
            if(param1 == PetClient.RSPN_ESCAPE)
            {
               if(!(param2 && _loc3_.params.msg && _loc3_.params.msg.length > 0))
               {
                  _processQueue = [];
               }
            }
         }
         _processQueue.push(_loc3_);
         if(!this.isHandling && this.fightPanel != null && !this.fightPanel.canStart)
         {
            this.handle();
         }
      }
      
      public function startHandle() : void
      {
         if(this.timer != null && this.timer.running)
         {
            return;
         }
         if(DocPetFight.skipBattlePresentation)
         {
            this.handle();
            return;
         }
         EnterFrameManager.instance.registerNextFrame(this.onStartHandle);
      }
      
      private function onStartHandle() : void
      {
         this.handle();
      }
      
      public function handle() : void
      {
         var _loc1_:Object = null;
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:IGameOptionService = null;
         var _loc5_:PlayerBattleInfo = null;
         var _loc6_:PlayerBattleInfo = null;
         var _loc7_:PetBriefInfo = null;
         var _loc8_:RegExp = null;
         if(_processQueue == null || _processQueue.length == 0)
         {
            this.isHandling = false;
            return;
         }
         _loc1_ = _processQueue.shift();
         if(_loc1_ == null)
         {
            this.isHandling = false;
            return;
         }
         this.isHandling = true;
         if(FinBattleTimer.instance.checkIsOverTime())
         {
            this.handlePanel();
            return;
         }
         if(FightData.instance.myInfo)
         {
            FightData.instance.myInfo.updateExtensionInfo(_loc1_.params);
         }
         if(Boolean(_loc1_.params) && Boolean(_loc1_.params.bs))
         {
            FightData.instance.curBs = _loc1_.params.bs;
            if(_loc1_.params.bs.indexOf("ext=LYSC26061") >= 0)
            {
               CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("mmo.activity260612.luyisitiaozhan26_xueji_movie",{}));
            }
         }
         switch(_loc1_.cmd)
         {
            case PetClient.RSPN_USE_SKILL:
               this.fightPanel.stopTimer();
               if(FightData.instance.isInSmallTurn)
               {
                  this.closeFightPanelWaitTips();
               }
               UseSkill.instance.useSkill(_loc1_.params,false);
               break;
            case PetClient.RSPN_CHANGE_DEGENERATOR_SKILL:
               _loc2_ = new PlayerBattleInfo();
               _loc2_.parseInfo(_loc1_.params);
               _loc3_ = FightData.instance.playerInfo[_loc2_.slotId];
               if(_loc3_)
               {
                  _loc3_.myPets[0].updateInfo(_loc2_.myPets[0]);
                  CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.CHANGE_DEGENERATOR_SUPER_PO_Skill,{}));
               }
               this.handle();
               break;
            case PetClient.RSPN_USE_SUMMON_SKILL:
               if(!_loc1_.params.hasOwnProperty("passivity"))
               {
                  this.fightPanel.stopTimer();
               }
               UseSkill.instance.useSkill(_loc1_.params,true);
               break;
            case PetClient.RSPN_BATTLE_NEXT_TURN:
               FightData.instance.isInSmallTurn = false;
               _loc4_ = ServicePool.instance.getService(IGameOptionService);
               FightData.instance.isLowQuality = _loc4_.isNoFightSkillEffect;
               ++this.turnCount;
               this.fightPanel.refreshTxt("<font color = \'#b7dcff\'> " + "第" + (this.turnCount + 1) + "回合" + "</font>");
               this.handleHunDouJueDou();
               BattleNextTurn.instance.battleNextTurn(_loc1_.params);
               break;
            case PetClient.RSPN_BATTLE_NEXT_TURN_SMALL:
               FightData.instance.isInSmallTurn = true;
               BattleSmallTurn.instance.battleSmallTurn(_loc1_.params);
               break;
            case PetClient.RSPN_STATUS_UPDATE:
               _loc5_ = _loc1_.params.info;
               FightData.instance.playerInfo[_loc5_.slotId].myPets[0].updateInfo(_loc5_.myPets[0]);
               this.handle();
               break;
            case PetClient.RSPN_FIN_BATTLE:
               if(Boolean(_loc1_.params) && Boolean(_loc1_.params.winPMInfo))
               {
                  _loc7_ = new PetBriefInfo();
                  _loc7_.parseInfo(_loc1_.params.winPMInfo);
                  FightData.instance.fightEndPbi = _loc7_;
               }
               FinBattle.instance.finBattle();
               break;
            case PetClient.RSPN_SWITCH_PM:
               this.closeFightPanelWaitTips();
               this.fightPanel.stopTimer();
               SwitchPm.instance.switchPm(_loc1_.params.playerInfo,_loc1_.params.extInfo);
               if(Boolean(_loc1_.params.extInfo.desc) && this.fightPanel != null)
               {
                  _loc8_ = /\$[0-9]\$/;
                  if(this.isReplay)
                  {
                     this.fightPanel.refreshTxt(_loc1_.params.extInfo.desc + " 。");
                     break;
                  }
                  if(_loc1_.params.extInfo.desc.match(_loc8_))
                  {
                     this.fightPanel.refreshTxt(_loc1_.params.extInfo.desc + " 。");
                  }
               }
               break;
            case "Before_PetClient_RSPN_SWITCH_PM":
               SwitchPm.instance.switchPm(_loc1_.params.playerInfo,_loc1_.params.extInfo);
               break;
            case PetClient.RSPN_BATTLE_POWERUP:
               this.fightPanel.stopTimer();
               this.closeFightPanelWaitTips();
               ChangePetView.instance.changeView(_loc1_.params);
               break;
            case PetClient.RSPN_BATTLE_RELIVE:
               TerritoryRelive.instance.relive(_loc1_.params);
               break;
            case PetClient.RSPN_ESCAPE:
               if(Boolean(_loc1_.params) && Boolean(_loc1_.params.msg) && _loc1_.params.msg.indexOf("战斗还没有开始") != -1)
               {
                  break;
               }
               if(Object(_loc1_.params).hasOwnProperty("isEscape"))
               {
                  Escape.instance.escape(_loc1_.params.reqSId,_loc1_.params.isEscape);
                  break;
               }
               Escape.instance.escape(_loc1_.params.reqSId,true);
               break;
            case PetClient.RSPN_PM_GAIN_EXP:
               this.handle();
               break;
            case PetClient.RSPN_CATCH_PM:
               this.closeFightPanelWaitTips();
               this.fightPanel.stopTimer();
               CatchPm.instance.catchPm(_loc1_.params);
               break;
            case PetClient.RSPN_BATTLE_PM_DYING:
               BattlePmDying.instance.battlePmDying(_loc1_.params);
               break;
            case PetClient.RSPN_USE_ITEM:
               this.fightPanel.stopTimer();
               this.closeFightPanelWaitTips();
               UseItem.instance.useItem(_loc1_.params);
               break;
            case PetClient.RSPN_BATTLE_STATUS_ON_START:
               Status.instance.status(_loc1_.params);
               break;
            case PetClient.RSPN_BATTLE_PM_STATUS:
               Status.instance.status(_loc1_.params);
               this.fightPanel.updateUIPanel();
               break;
            case PetClient.RSPN_BATTLE_BACKGROUND_STATUS:
               BackGroundStatus.instance.status(_loc1_.params);
               break;
            case PetClient.RSPN_BATTLE_STATUS_UPDATE4:
               ChangeViewStatus.instance.changeViewStatus(_loc1_.params);
               break;
            case PetClient.RSPN_CHANGE_STATE_AT_PLAY_OPERATE:
               _loc6_ = new PlayerBattleInfo();
               _loc6_.parseInfo(_loc1_.params);
               FightData.instance.playerInfo[_loc6_.slotId].myPets[0].updateInfo(_loc6_.myPets[0]);
               FightController.instance.fightPanel.switchSkill();
               FightData.instance.setLocaId(_loc6_);
               FightController.instance.fightPanel.refreshHunDunState(_loc6_.locaId,FightData.instance.playerInfo[_loc6_.slotId].myPets[0]);
               if(Boolean(_loc1_.params.desc) && _loc1_.params.desc.length > 0)
               {
                  FightController.instance.desc = _loc1_.params.desc;
                  this.fightPanel.refreshTxt(FightController.instance.desc + " 。");
               }
               CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.CHANGE_STATE_AT_PLAY_OPERATE,{}));
               this.handle();
               break;
            case PetClient.RSPN_PET_TALK:
               FightTalk.instance.onPetTalk(_loc1_.params);
               this.handle();
               break;
            case PetClient.RSPN_BATTLE_SUMMON_PM:
               UseSkill.instance.useSkill(_loc1_.params,true);
         }
      }
      
      public function handleHunDouJueDou() : void
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:int = 0;
         var _loc4_:MCPetContainer = null;
         var _loc5_:Point = null;
         if(BSUtil.getIsInHunDunJueDouState())
         {
            this.fightPanel.layerPetDown.visible = this.fightPanel.layerPetUp.visible = false;
         }
         else
         {
            GQHundunJuedouEffectHelper.removeScreenBitmap();
            this.fightPanel.layerPetDown.visible = this.fightPanel.layerPetUp.visible = true;
         }
         var _loc1_:Array = FightData.instance.playerInfo;
         for each(_loc2_ in _loc1_)
         {
            _loc3_ = int(_loc2_.locaId);
            _loc4_ = this.fightPanel.petMCList[_loc3_];
            _loc5_ = PositionUtil.getDefaultPosition(_loc3_);
            _loc4_.x = _loc5_.x;
            _loc4_.y = _loc5_.y;
         }
      }
      
      private function hasPlayer(param1:PlayerBattleInfo) : Boolean
      {
         var _loc2_:PlayerBattleInfo = null;
         for each(_loc2_ in FightData.instance.playerInfo)
         {
            if(param1.PMMasterId == _loc2_.PMMasterId && _loc2_.slotId == param1.slotId)
            {
               return true;
            }
         }
         return false;
      }
      
      public function showSuccessPanel(param1:String) : void
      {
         var _loc2_:Sprite = new SuccessPanel(param1);
         ModalDialogManager.getInstance().addModalDialog(_loc2_);
      }
      
      public function switchPM(param1:int, param2:int) : void
      {
         PetClient.instance.switchPM(param1,this.turnCount,param2);
         FightData.instance.myInfo.setPetWillSwitchUp(param2,param1);
         if(FightData.instance.myInfo.haveDieForSwitchSlot())
         {
            BattlePmDying.instance.handleManualSwitch();
         }
         else
         {
            this.afterOperatedPlayer();
         }
      }
      
      public function useSkill(param1:int, param2:int, param3:int, param4:Boolean, param5:int = -1) : void
      {
         this.fightPanel.mouseEnabled = false;
         PetClient.instance.useSkill(param1,param2,this.turnCount,false,0,param3,param5);
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent(PetFightEvent.CLICK_SKILL_BAR_USE_SKLL,{}));
         if(param4)
         {
            this.fightPanel.stopTimer();
         }
         else
         {
            this.afterOperatedPlayer(param1);
         }
      }
      
      public function changePMView() : void
      {
         var _loc1_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         PetClient.instance.changePMView(_loc1_.slotId,this.turnCount);
         this.afterOperatedPlayer();
      }
      
      public function useItem(param1:int, param2:int) : void
      {
         var _loc3_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         PetClient.instance.useItem(param1,param2,this.turnCount,0,_loc3_.slotId);
         FightData.instance.myInfo.setWillUseItem(param1);
         this.afterOperatedPlayer(-1,true);
      }
      
      public function escape() : void
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc1_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         PetClient.instance.escape(FightController.instance.turnCount,_loc1_.slotId);
         for each(_loc2_ in FightData.instance.myInfo.getCanControlPlayers())
         {
            FightData.instance.myInfo.setPlayerOperatedState(_loc2_.slotId,true);
         }
         this.afterOperatedPlayer();
      }
      
      private function afterOperatedPlayer(param1:int = -1, param2:Boolean = false) : void
      {
         FightData.instance.myInfo.setCurOperatingPlayerOperated(param1);
         var _loc3_:PlayerBattleInfo = FightData.instance.myInfo.getCanOperatePlayer();
         if(_loc3_)
         {
            this.fightPanel.setPlayerOperating(_loc3_.slotId);
         }
         else
         {
            this.fightPanel.stopTimer();
            if(this._gameOptionSvr.isHideFightUIAfterOperated)
            {
               this.fightPanel.openUIPanel(4);
            }
            else if(param2)
            {
               FightController.instance.fightPanel.setFightClicked();
            }
         }
      }
      
      public function get canUseAutoTimes() : int
      {
         return this._canUseAutoTimes;
      }
      
      public function set canUseAutoTimes(param1:int) : void
      {
         if(param1 < 0)
         {
            return;
         }
         this._canUseAutoTimes = param1;
      }
      
      public function playSound(param1:String, param2:Boolean = false, param3:Number = 3) : void
      {
         var _loc4_:Sound = null;
         if(!this._gameOptionSvr.isFightSound)
         {
            return;
         }
         if(param2)
         {
            _loc4_ = this.ipetmusic.getMusicByName({"skill":param1});
         }
         else
         {
            _loc4_ = this.ipetmusic.getMusicByName({"other":param1});
         }
         if(_loc4_ == null)
         {
            return;
         }
         var _loc5_:SoundPlayer = new SoundPlayer(_loc4_);
         _loc5_.play(false,this._gameOptionSvr.fightVolume / 100);
      }
      
      public function getFightPanelPetMC() : Array
      {
         return this.fightPanel.petMCList;
      }
      
      public function getPointByLocaId(param1:int) : Point
      {
         return PositionUtil.getDefaultPosition(param1);
      }
      
      public function refreshFightPanelTxt() : void
      {
         this.fightPanel.refreshTxt(this.desc);
      }
      
      public function addEffect(param1:MovieClip) : void
      {
         this.fightPanel.layerEffect.addChild(param1);
      }
      
      public function closeFightPanelWaitTips() : void
      {
         this.fightPanel.closeWaitTips();
      }
      
      public function closeFightPanel() : void
      {
         if(this.fightPanel != null)
         {
            this.fightPanel.close();
         }
      }
      
      public function dispose() : void
      {
         if(this._isDisposed)
         {
            return;
         }
         this._isDisposed = true;
         FightItemData.instance.dispose();
         UseSkill.instance.dispose();
         FinBattle.instance.dispose();
         Escape.instance.dispose();
         BattlePmDying.instance.dispose();
         CatchPm.instance.dispose();
         UseItem.instance.dispose();
         Status.instance.dispose();
         BackGroundStatus.instance.dispose();
         BattleNextTurn.instance.dispose();
         TrainingTower.instance.dispose();
         FightTalk.instance.dispose();
         BossMovieHelper.instance.dispose();
         FightMcCache.instance.dispose();
         ChangePetView.instance.dispose();
         ChangeViewStatus.instance.dispose();
         AttributeLevelController.instance.dispose();
         UseBigSkillHandler.instance.dispose();
         FinBattleTimer.dispose();
         SummonPetProcessor.instance.dispose();
         FightMcPool.instance.dispose();
         FightBitmapDataCache.instance.dispose();
         ServicePool.instance.dispose();
         PreloadListManager.instance.dispose();
         FIP_Controller.instance.dispose();
         FightData.instance.dispose();
         this._petFightSvr.isInTerritoryFight = false;
         this.removeListeners();
         _processQueue = null;
         _endPanels = null;
         this.resetLastTimeUpTurn();
         this._petFightSvr.setIsFighting(false);
         this.fightPanel = null;
         this.gainExp = false;
         this.haveShowGainExpPanel = false;
         FightEventDispatcher.instance.dispose();
         _instance = null;
      }
      
      private function removeListeners() : void
      {
         if(this.timer != null)
         {
            this.timer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onStartHandle);
         }
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_NEXT_TURN,this.onNextTurnBefore);
         SocketClient.instance.removeEventListener(PetClient.RSPN_SWITCH_PM,this.onSwitchPmBefore);
         SocketClient.instance.removeEventListener(PetClient.RSPN_ESCAPE,this.onEscape);
         SocketClient.instance.removeEventListener(PetClient.RSPN_USE_SUMMON_SKILL,this.onSummonPet);
         SocketClient.instance.removeEventListener(PetClient.RSPN_CHANGE_DEGENERATOR_SKILL,this.onChangeDegeneratorSkill);
         SocketClient.instance.removeEventListener(PetClient.RSPN_SWITCH_PM,this.onSwitchPM);
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_POWERUP,this.onPowerUp);
         SocketClient.instance.removeEventListener(PetClient.RSPN_PM_GAIN_EXP,this.onGainExp);
         SocketClient.instance.removeEventListener(PetClient.RSPN_CATCH_PM,this.onCatchPM);
         SocketClient.instance.removeEventListener(PetClient.RSPN_ESCAPE,this.onEscape);
         SocketClient.instance.removeEventListener(PetClient.RSPN_USE_SKILL,this.onUseSkill);
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_NEXT_TURN,this.onNextTurn);
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_NEXT_TURN_SMALL,this.onBattleSmallTurn);
         SocketClient.instance.removeEventListener(PetClient.RSPN_STATUS_UPDATE,this.onStatusUpdate);
         SocketClient.instance.removeEventListener(PetClient.RSPN_FIN_BATTLE,this.onFinish);
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_PM_DYING,this.onNeedSwitch);
         SocketClient.instance.removeEventListener(PetClient.RSPN_FIN_BATTLE,this.onFinishBefore);
         SocketClient.instance.removeEventListener(PetClient.RSPN_USE_ITEM,this.onUseItem);
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_PM_STATUS,this.onStatus);
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_BACKGROUND_STATUS,this.onBackStatus);
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_STATUS_UPDATE4,this.onChangeViewStatus);
         SocketClient.instance.removeEventListener(PetClient2.cmdPMDropBonus,this.onBonus);
         SocketClient.instance.removeEventListener(PetClient.RSPN_READY,this.onReady);
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_STATUS_ON_START,this.onBattleStartStatus);
         SocketClient.instance.removeEventListener("103_6",this.onGetSpecialBonus);
         SocketClient.instance.removeEventListener(PetClient.RSPN_CHANGE_STATE_AT_PLAY_OPERATE,this.onChangeStateAtOperate);
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_RELIVE,this.onBattleRelive);
         SocketClient.instance.removeEventListener(PetClient.RSPN_PET_TALK,this.onPetTalk);
         SocketClient.instance.removeEventListener(PetClient.RSPN_BATTLE_SUMMON_PM,this.onBattleSummonPm);
         if(this.petDataService != null)
         {
            this.petDataService.removeEventListener(PetDataServiceEvent.RSPN_PM_GAIN_NEW_SKILL,this.onRspn_pm_gain_new_skill);
            this.petDataService.removeEventListener(PetDataServiceEvent.RSPN_PM_GAIN_EXP,this.onRspn_pm_gain_exp);
            this.petDataService.removeEventListener(PetDataServiceEvent.RSPN_PM_LEVELUP,this.onRspn_pm_levelup);
         }
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.CLICK_RESULT_PANEL,this.onClickPanel);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.SHOW_END_PANEL,this.onGetFightEndPanel);
         FightEventDispatcher.instance.removeEventListener(FightInnerEvent.ON_MOUSE_OVER_PET,this.onOverPet);
         FightEventDispatcher.instance.removeEventListener(FightInnerEvent.ON_MOUSE_OUT_PET,this.onOutPet);
      }
      
      public function get isReplay() : Boolean
      {
         return this._isReplay || this._isLive || this._isPetFightSpaceLive;
      }
      
      public function set isLive(param1:Boolean) : void
      {
         var _loc2_:ILiveService = ServicePool.instance.getService(ILiveService);
         if(param1 && Boolean(_loc2_.isPetFightSpaceLive))
         {
            this._isLive = false;
            this.isPetFightSpaceLive = true;
         }
         else
         {
            this._isLive = param1;
         }
      }
      
      public function get isLive() : Boolean
      {
         return this._isLive;
      }
      
      public function set isPetFightSpaceLive(param1:Boolean) : void
      {
         this._isPetFightSpaceLive = param1;
      }
      
      public function get isPetFightSpaceLive() : Boolean
      {
         return this._isPetFightSpaceLive;
      }
      
      public function set isReplay(param1:Boolean) : void
      {
         this._isReplay = param1;
      }
      
      public function get lastTimeUpTurn() : int
      {
         return this._lastTimeUpTurn;
      }
      
      public function set lastTimeUpTurn(param1:int) : void
      {
         this._lastTimeUpTurn = param1;
      }
      
      public function get replayTurnCount() : int
      {
         return this._replayTurnCount;
      }
      
      public function get finishWithNoPanel() : Boolean
      {
         return this._finishWithNoPanel;
      }
      
      public function set isShowDropBn(param1:Boolean) : void
      {
         this._isShowDropBn = param1;
      }
      
      public function get isShowFightInfo() : Boolean
      {
         return this._isShowFightInfo;
      }
      
      public function set isShowFightInfo(param1:Boolean) : void
      {
         this._isShowFightInfo = param1;
      }
      
      public function get isEscapeEvacuate() : Boolean
      {
         return this._isEscapeEvacuate;
      }
      
      public function set isEscapeEvacuate(param1:Boolean) : void
      {
         this._isEscapeEvacuate = param1;
      }
   }
}

