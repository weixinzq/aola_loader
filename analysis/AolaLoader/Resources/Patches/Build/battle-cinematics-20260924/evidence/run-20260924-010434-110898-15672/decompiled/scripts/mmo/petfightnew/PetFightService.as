package mmo.petfightnew
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.media.Sound;
   import flash.system.ApplicationDomain;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.sound.SoundPlayer;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.bit.BitUtil;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.config.ConfigReader;
   import mmo.framework.comm.GatherClient;
   import mmo.framework.comm.MazeCommonClient;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.PetFightClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.SpacetimeClient;
   import mmo.framework.comm.SpacetimeTClient;
   import mmo.framework.comm.VirtualFightClient;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceContainerEvent;
   import mmo.interfaces.antiaddiction.IAntiAddiction;
   import mmo.interfaces.anticheat.IAntiCheatService;
   import mmo.interfaces.dailytask.IDailyTask;
   import mmo.interfaces.fightnew.IFightController;
   import mmo.interfaces.follow.IFollowService;
   import mmo.interfaces.hotspring.HotSpringServiceInfo;
   import mmo.interfaces.material.pettitle.IPetTitleService;
   import mmo.interfaces.music.IMusic;
   import mmo.interfaces.notify.INotifyService;
   import mmo.interfaces.notify.MessageType;
   import mmo.interfaces.notify.NotifyServiceEvent;
   import mmo.interfaces.option.GameOptionConfig;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.FunctionPermitConst;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PermitInfo;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.skin.IPetSkinDataService;
   import mmo.interfaces.pet.data.skin.PetSkinInfo;
   import mmo.interfaces.pet.fight.FightMode;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.IPetFightConfig;
   import mmo.interfaces.pet.fight.IPetRingFunctionPermit;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.fight.PetFightTypes;
   import mmo.interfaces.pet.fight.TrainingFightTypes;
   import mmo.interfaces.pet.fightmusic.FightMusicEvent;
   import mmo.interfaces.pet.fightmusic.IFightMusic;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.zhiduoxing.IZhiDuoXingService;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.fightcontroller.ReplayCmdExtractor_Queue;
   import mmo.petfightnew.common.fightcontroller.TrainingTower;
   import mmo.petfightnew.common.manager.GQKillBigMovieLoader;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.manager.XingHuiKillBigMovieLoader;
   import mmo.petfightnew.common.panel.ChallengeChoosePanel;
   import mmo.petfightnew.common.panel.GotChallengePanel;
   import mmo.petfightnew.common.startmovie.StartMovie;
   import mmo.petfightnew.common.startmovie.StartMovie3v3;
   import mmo.petfightnew.common.useskill.NewOrderlySkillStrategy;
   import mmo.petfightnew.common.util.BSUtil;
   import mmo.petfightnew.common.util.FetterUtil;
   import mmo.petfightnew.common.util.GetBackgroundUtil;
   import mmo.play.player.PlayerManager;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.socketserver.data.User;
   
   public class PetFightService extends Sprite implements IPetFight
   {
      
      private static var _canFight:Boolean = true;
      
      private static const fightInCopyLogMap:Object = {
         "fbsiwude1":755,
         "fbsiwude2":756,
         "fbsiwude3":757,
         "fbsiwude4":758,
         "fbsiwude5":759,
         "fbsiwude6":760,
         "fbsiwude9":761,
         "fbsiwude10":762,
         "fbsiwude11":763
      };
      
      private var notifyService:INotifyService;
      
      private var petDataService:IPetDataService;
      
      private var petFightConfig:IPetFightConfig;
      
      private var raceId:int;
      
      private var playerInfos:Array = [];
      
      private var joinInfoArr:Array = [];
      
      private var level:int;
      
      private var id:int;
      
      private var canSwitch:Boolean;
      
      private var teamService:ITeamService;
      
      private var functionPermitService:IPetRingFunctionPermit;
      
      private var setSlotArr:Array = [];
      
      private var _autoFightItemId:int;
      
      private var fightCmdCacher:FightCmdCacher = new FightCmdCacher();
      
      private var _replayCmdExtractor:ReplayCmdExtractor_Queue = null;
      
      public function PetFightService()
      {
         super();
      }
      
      public function init() : void
      {
         this.petDataService = ServiceContainer.getService(IPetDataService);
         this.teamService = ServiceContainer.getService(ITeamService);
         this.petFightConfig = ServiceContainer.getService(IPetFight);
         ServiceContainer.instance.tryGetService(INotifyService,function(param1:INotifyService, param2:Object):*
         {
            notifyService = param1;
         });
         DocPetFight.ensureAolaBattleBridge();
      }
      
      public function startFight(param1:int, param2:Boolean = false, param3:Object = null) : void
      {
         var type:int = param1;
         var canCatch:Boolean = param2;
         var params:Object = param3;
         if(params != null && Boolean(params["isHurtFight"]))
         {
            params["isHurtFight"] = false;
            this.hurtFight(false,function():void
            {
               startFight(type,false,params);
            });
            return;
         }
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         ProgressFullSprite.show();
         FightController.instance.isCatchablePet = canCatch;
         if(PlayerManager.getInstance().myPlayer != null)
         {
            PlayerManager.getInstance().myPlayer.stop();
         }
         if(null != params && Boolean(params.hasOwnProperty("commonTitleView")))
         {
            FightData.instance.saveFightTitleView(params["commonTitleView"] as DisplayObject);
            delete params["commonTitleView"];
         }
         if(params != null && Boolean(params.hasOwnProperty("myAiNameArr")))
         {
            FightData.instance.myAiNameArr = params.myAiNameArr;
         }
         if(params != null && Boolean(params.hasOwnProperty("canAuto")))
         {
            FightController.instance.canAuto = params.canAuto;
         }
         if(params != null && Boolean(params.hasOwnProperty("isShowDropBn")))
         {
            FightController.instance.isShowDropBn = params.isShowDropBn;
         }
         if(params != null && Boolean(params.hasOwnProperty("isShowFightInfo")))
         {
            FightController.instance.isShowFightInfo = params.isShowFightInfo;
         }
         if(params != null && Boolean(params.hasOwnProperty("isEscapeEvacuate")))
         {
            FightController.instance.isEscapeEvacuate = params.isEscapeEvacuate;
         }
         switch(type)
         {
            case PetFightTypes.FIGHT_IN_NPCCHALLENGE:
               FightData.instance.challengeNpcId = params.npcId;
               FightData.instance.npcName = params.name;
               break;
            case PetFightTypes.FIGHT_WITH_RARE__PET:
               this.fightWithRarePet(params);
               return;
            case PetFightTypes.VIRTUAL_FIGHT:
               FightController.instance.isVirtualFight = true;
               VirtualFightClient.instance.startPk();
               return;
         }
         PetClient2.instance.startFight(type,params);
      }
      
      private function fightWithRarePet(param1:Object) : void
      {
         var _loc2_:int = int(param1.raceId);
         var _loc3_:int = int(param1.level);
         var _loc4_:int = param1.id == undefined ? -1 : int(param1.id);
         ProgressFullSprite.show();
         PetClient2.instance.startPKWithRobot(_loc2_,_loc3_,true,_loc4_);
      }
      
      public function showGotChallengePanel(param1:String, param2:Boolean, param3:int, param4:Object) : void
      {
         ModalDialogManager.getInstance().addModalDialog(new GotChallengePanel(param1,param2,param3,param4));
      }
      
      public function get canFight() : Boolean
      {
         return _canFight;
      }
      
      public function set canFight(param1:Boolean) : void
      {
         _canFight = param1;
      }
      
      public function fightWithTaskPet(param1:int, param2:int = -1, param3:Boolean = true, param4:Boolean = false, param5:int = -1) : void
      {
         if(this.teamService.getMyTeam() != null && param1 != 10201)
         {
            NewDialog.showFailMessage("组队状态不能进行任务对战！");
            return;
         }
         this.fightWithPetByRaceId(param1,param2,param3,param4,param5);
      }
      
      public function fightWithPetByRaceId(param1:int, param2:int = -1, param3:Boolean = true, param4:Boolean = false, param5:int = -1) : void
      {
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         this.raceId = param1;
         this.level = param2;
         this.canSwitch = param3;
         FightController.instance.isCatchablePet = param4;
         this.id = param5;
         if(PlayerManager.getInstance().myPlayer != null)
         {
            PlayerManager.getInstance().myPlayer.stop();
         }
         ProgressFullSprite.show();
         ServiceContainer.instance.addEventListener(ServiceContainerEvent.onGetService,this.onFightWithTaskPet);
         ServiceContainer.instance.tryGetService("AntiCheatService");
      }
      
      private function onFightWithTaskPet(param1:ServiceContainerEvent) : void
      {
         if(param1.serviceName != "AntiCheatService")
         {
            return;
         }
         ProgressFullSprite.close();
         ServiceContainer.instance.removeEventListener(ServiceContainerEvent.onGetService,this.onFightWithTaskPet);
         var _loc2_:IAntiCheatService = param1.service as IAntiCheatService;
         _loc2_.addEventListener("BeginToFight",this.beginToFight);
         _loc2_.showAntiCheatPanel();
      }
      
      private function beginToFight(param1:Event) : void
      {
         param1.currentTarget.removeEventListener("BeginToFight",this.beginToFight);
         ProgressFullSprite.show();
         FightController.instance.id = this.id;
         PetClient2.instance.startPKWithRobot(this.raceId,this.level,this.canSwitch,this.id);
      }
      
      public function fightInTrainingTower(param1:int, param2:int = 1, param3:Array = null) : void
      {
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         TrainingTower.instance.maxRounds = param1;
         TrainingTower.instance.status = param3;
         FightController.instance.trainingTowerType = param2;
         FightController.instance.isCatchablePet = false;
         if(PlayerManager.getInstance().myPlayer != null)
         {
            PlayerManager.getInstance().myPlayer.stop();
         }
         ProgressFullSprite.show();
         SocketClient.instance.sendXtMessage("PTowerExtension","79_5",{});
      }
      
      public function insistFight(param1:int, param2:int, param3:Boolean = false) : void
      {
         if(this.teamService.getMyTeam() != null)
         {
            NewDialog.showFailMessage("组队状态不能对战！");
            return;
         }
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         TrainingTower.instance.game = param1;
         TrainingTower.instance.turns = param2;
         FightController.instance.trainingTowerType = TrainingFightTypes.ROUND_TYPE;
         FightController.instance.isCatchablePet = false;
         if(PlayerManager.getInstance().myPlayer != null)
         {
            PlayerManager.getInstance().myPlayer.stop();
         }
         this.startFight(85,false,{
            "sw":false,
            "lv":param1,
            "buff":param3
         });
      }
      
      public function timerFight(param1:Object) : void
      {
         if(this.teamService.getMyTeam() != null)
         {
            NewDialog.showFailMessage("组队状态不能对战！");
            return;
         }
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         TrainingTower.instance.timerInfo = param1;
         FightController.instance.trainingTowerType = TrainingFightTypes.TIMER_TYPE;
         FightController.instance.isCatchablePet = false;
         if(PlayerManager.getInstance().myPlayer != null)
         {
            PlayerManager.getInstance().myPlayer.stop();
         }
         this.startFight(83);
      }
      
      public function hurtFight(param1:Boolean = false, param2:Function = null) : void
      {
         if(this.teamService.getMyTeam() != null)
         {
            NewDialog.showFailMessage("组队状态不能对战！");
            return;
         }
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         FightController.instance.trainingTowerType = TrainingFightTypes.HURT_TYPE;
         FightController.instance.isCatchablePet = false;
         if(PlayerManager.getInstance().myPlayer != null)
         {
            PlayerManager.getInstance().myPlayer.stop();
         }
         var _loc3_:int = param1 ? 0 : 1;
         if(param2 != null)
         {
            param2.apply();
         }
         else
         {
            this.startFight(86,false,{
               "sw":false,
               "id":0,
               "buff":_loc3_
            });
         }
      }
      
      public function fightWithDailyTaskPet() : void
      {
         if(this.teamService.getMyTeam() != null)
         {
            NewDialog.showFailMessage("组队状态不能与任务怪对战！");
            return;
         }
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         FightController.instance.isCatchablePet = false;
         if(PlayerManager.getInstance().myPlayer != null)
         {
            PlayerManager.getInstance().myPlayer.stop();
         }
         ProgressFullSprite.show();
         var _loc1_:IDailyTask = ServicePool.instance.getService(IDailyTask);
         _loc1_.startFight();
      }
      
      public function fightWithBoss(param1:String, param2:int) : void
      {
         if(this.teamService.getMyTeam() != null)
         {
            NewDialog.showFailMessage("组队状态不能与boss对战！");
            return;
         }
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         FightController.instance.isCatchablePet = false;
         if(PlayerManager.getInstance().myPlayer != null)
         {
            PlayerManager.getInstance().myPlayer.stop();
         }
         ProgressFullSprite.show();
         PetClient2.instance.fightWithBoss(param1,param2);
      }
      
      public function fightWithTeamBoss(param1:String, param2:int) : void
      {
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         FightController.instance.isCatchablePet = false;
         if(PlayerManager.getInstance().myPlayer != null)
         {
            PlayerManager.getInstance().myPlayer.stop();
         }
         ProgressFullSprite.show();
         PetClient2.instance.fightWithBoss(param1,param2);
      }
      
      public function fightWithTowerPet(param1:int) : void
      {
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         FightController.instance.isCatchablePet = false;
         if(PlayerManager.getInstance().myPlayer != null)
         {
            PlayerManager.getInstance().myPlayer.stop();
         }
         ProgressFullSprite.show();
         if(this.teamService.getMyTeam() == null)
         {
            SpacetimeClient.instence.startPK(param1);
         }
         else
         {
            SpacetimeTClient.instence.startPK(param1);
         }
      }
      
      public function fightInMagicCubic(param1:int, param2:int, param3:Boolean) : void
      {
         if(this.teamService.getMyTeam() != null)
         {
            NewDialog.showFailMessage("组队状态不能进行魔方迷宫探索！");
            return;
         }
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         FightController.instance.isCatchablePet = param3;
         if(PlayerManager.getInstance().myPlayer != null)
         {
            PlayerManager.getInstance().myPlayer.stop();
         }
         ProgressFullSprite.show();
         MazeCommonClient.instence.fightInMazeCube(param1,param2);
      }
      
      public function fightInCopy(param1:int) : void
      {
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         FightController.instance.isCatchablePet = false;
         FightController.instance.id = param1;
         if(PlayerManager.getInstance().myPlayer != null)
         {
            PlayerManager.getInstance().myPlayer.stop();
         }
         ProgressFullSprite.show();
         PetClient2.instance.fightInCopy(param1);
         var _loc2_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         if(fightInCopyLogMap.hasOwnProperty(_loc2_))
         {
            SundriesClient.logButton(fightInCopyLogMap[_loc2_]);
         }
      }
      
      public function fightWithOther(param1:String) : void
      {
         if(this.teamService.getMyTeam() != null || this.teamService.getUserTeam(param1) != null)
         {
            NewDialog.showFailMessage("组队状态不能与玩家对战！");
            return;
         }
         if(!_canFight)
         {
            NewDialog.showFailMessage("你现在不能进行对战！");
            return;
         }
         if(!this.ifSatisfyFightCondition())
         {
            return;
         }
         ModalDialogManager.getInstance().addModalDialog(new ChallengeChoosePanel(param1));
      }
      
      private function hasAvailablePet() : Boolean
      {
         var _loc1_:PetBriefInfo = null;
         if(this.petDataService.getMyPets() == null || this.petDataService.getMyPets().length == 0)
         {
            NewDialog.showFailMessage("你没有带上可以作战的亚比哦！快去亚比仓库带上你的亚比一起作战吧！");
         }
         else
         {
            for each(_loc1_ in this.petDataService.getMyPets())
            {
               if(_loc1_.curHp > 0)
               {
                  return true;
               }
            }
            this.showNoBloodPanel();
         }
         ProgressFullSprite.close();
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.ENTER_FIGHT_FAIL));
         return false;
      }
      
      private function showNoBloodPanel() : void
      {
         ProgressFullSprite.show();
         ResScheduler.getResource("pet/petnoblood",function(param1:IShowPanel):void
         {
            ProgressFullSprite.close();
            param1.showPanel();
         },"mmo.petfightnew.common.panel.NoBloodPanel");
      }
      
      public function matchArena(param1:Boolean = false) : Boolean
      {
         if(this.hasAvailableTime())
         {
            FightController.instance.isMatchArena = true;
            return true;
         }
         return false;
      }
      
      public function leaveArena() : void
      {
         FightController.instance.isMatchArena = false;
      }
      
      public function onLookReplayFail(param1:SocketClientEvent) : void
      {
         if(param1.params.res == -1)
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.LOOK_REPLAY_FAIL,{}));
         }
      }
      
      public function onIdUpdate(param1:SocketClientEvent) : void
      {
         var _loc2_:int = int(param1.params.id);
         FightController.instance.id = _loc2_;
      }
      
      public function onDropBattle(param1:SocketClientEvent) : void
      {
         if(!this.petFightConfig.getIsFighting())
         {
            this.battleFail(false);
         }
      }
      
      public function onFinishBattle(param1:SocketClientEvent) : void
      {
         if(this.petFightConfig.getIsFighting())
         {
            this.fightCmdCacher.cacheCmd(PetClient.RSPN_FIN_BATTLE,param1,false);
         }
      }
      
      public function onEscape(param1:SocketClientEvent) : void
      {
         if(this.petFightConfig.getIsFighting())
         {
            this.fightCmdCacher.cacheCmd(PetClient.RSPN_ESCAPE,param1,false);
         }
      }
      
      public function onEndAutoFight(param1:PetFightEvent) : void
      {
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.SCENE_INITED,this.onSceneInited);
      }
      
      public function onStartAutoFight(param1:PetFightEvent) : void
      {
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED,this.onSceneInited);
         this.autoFight();
      }
      
      public function onUseItem(param1:SocketClientEvent) : void
      {
         if(param1.params.res == 1 && (param1.params.ii == 44 || param1.params.ii == 1037))
         {
            SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED,this.onSceneInited);
            this.autoFight();
         }
      }
      
      private function onSceneInited(param1:SceneManagerEvent) : void
      {
         this.autoFight();
      }
      
      public function onGetChallenge(param1:SocketClientEvent) : void
      {
         var e:SocketClientEvent = param1;
         ServiceContainer.instance.tryGetService(IZhiDuoXingService,function(param1:IZhiDuoXingService, param2:Object):*
         {
            var _loc3_:IMusic = null;
            var _loc4_:Sound = null;
            var _loc5_:SoundPlayer = null;
            if(Boolean(param1.isInZhiLeGuan()) || !_canFight)
            {
               PetFightClient.instance.refuse(e.params.name);
               return;
            }
            if(notifyService != null)
            {
               _loc3_ = ServicePool.instance.getService(IMusic);
               _loc4_ = _loc3_.getMusicByName("x1004_4") as Sound;
               _loc5_ = new SoundPlayer(_loc4_);
               _loc5_.play(false,2);
               notifyService.addEventListener(NotifyServiceEvent.onNotifyClick,onClickNotify);
               notifyService.addFightMessage(e.params,MessageType.PET_FIGHT_CHALLENGE);
            }
         });
      }
      
      private function onClickNotify(param1:NotifyServiceEvent) : void
      {
         var user:User;
         var e:NotifyServiceEvent = param1;
         if(e.params.type != MessageType.PET_FIGHT_CHALLENGE || !_canFight)
         {
            return;
         }
         user = SocketClient.instance.activeRoom.getUser(UserInfo.userName);
         if(user.getVariable("wenQuan") != 0 && user.getVariable("wenQuan") != undefined)
         {
            NewDialog.showSucceedMessage(HotSpringServiceInfo.FIGHT_TIPS);
            return;
         }
         if(this.functionPermitService)
         {
            this.checkPermitAndShowPanel(e.params.name,e.params.sw,e.params.ft,e.params);
         }
         else
         {
            ServiceContainer.instance.tryGetService(IPetRingFunctionPermit,function(param1:IPetRingFunctionPermit, param2:Object):*
            {
               functionPermitService = param1;
               checkPermitAndShowPanel(e.params.name,e.params.sw,e.params.ft,e.params);
            });
         }
      }
      
      private function checkPermitAndShowPanel(param1:String, param2:Boolean, param3:int, param4:Object) : void
      {
         var _loc5_:PermitInfo = this.functionPermitService.getPermitInfoByFunctionId(FunctionPermitConst.FriendBtn1);
         if(!_loc5_.isAllow)
         {
            NewDialog.showFailMessage(_loc5_.des);
            return;
         }
         this.showGotChallengePanel(param1,param2,param3,param4);
      }
      
      private function hasPlayer(param1:PlayerBattleInfo) : Boolean
      {
         var _loc2_:PlayerBattleInfo = null;
         for each(_loc2_ in this.playerInfos)
         {
            if(param1.PMMasterId == _loc2_.PMMasterId && _loc2_.slotId == param1.slotId)
            {
               return true;
            }
         }
         return false;
      }
      
      private function enterFight() : void
      {
         var _loc4_:Object = null;
         ProgressFullSprite.close();
         ModalDialogManager.getInstance().clearAll();
         FightController.isHandlePanel = true;
         FightController.isShowBattleEffectiveness = false;
         if(FightData.fightMode == FightMode.FIGHT_3V3 || FightData.fightMode == FightMode.NO_FIGHT_BONUS_PANEL)
         {
            FightController.isHandlePanel = false;
         }
         if(FightData.fightMode == FightMode.SHOW_BATTLE_EFFECTIVENESS)
         {
            FightController.isShowBattleEffectiveness = true;
         }
         var _loc1_:IFollowService = ServicePool.instance.getService(IFollowService);
         switch(FightData.fightMode)
         {
            case FightMode.NORMAL:
            case FightMode.NO_FIGHT_BONUS_PANEL:
            case FightMode.SHOW_BATTLE_EFFECTIVENESS:
               LayerManager.switchLayer(LayerManager.FIGHTING_LAYER);
               this.loadRoleIcon();
               break;
            case FightMode.FIGHT_3V3:
            case FightMode.FIGHT_3V3BOSS:
               new StartMovie3v3().show();
         }
         var _loc2_:String = "";
         var _loc3_:int = 0;
         while(_loc3_ < this.joinInfoArr.length)
         {
            _loc4_ = this.joinInfoArr[_loc3_];
            _loc2_ += _loc4_.type + "----\n" + _loc4_.des + "\n";
            _loc3_++;
         }
         FightData.instance.joinInfoStr = _loc2_;
         this.joinInfoArr = [];
      }
      
      private function loadRoleIcon() : void
      {
         var roleArr:Array = null;
         var clsArr:Array = null;
         var urlArr:Array = null;
         var lihuiMcList:Array = null;
         var fightSignInMcList:Array = null;
         var startLoad:Function = function():void
         {
            ResScheduler.getRes(ResParams.createTempByDomain(urlArr[0],function(param1:MovieClip, param2:ApplicationDomain):void
            {
               if(urlArr[0].indexOf("lihui") >= 0)
               {
                  lihuiMcList.push(param1);
               }
               else
               {
                  fightSignInMcList.push(param1);
               }
               urlArr.splice(0,1);
               clsArr.splice(0,1);
               if(urlArr.length == 0)
               {
                  loadSuc();
               }
               else
               {
                  startLoad();
               }
            },ResDomain.decorate(FightData.instance.applicationDomain),clsArr[0],ResPriority.NORMAL));
         };
         var loadSuc:Function = function():void
         {
            var _loc1_:int = int(roleArr[0]);
            var _loc2_:int = int(roleArr[1]);
            if(_loc1_ == 0)
            {
               lihuiMcList[0].scaleX = -1;
            }
            if(_loc2_ > 0)
            {
               lihuiMcList[1].scaleX = -1;
            }
            if(_loc1_ == 0)
            {
               lihuiMcList[0].gotoAndStop(1);
            }
            if(_loc2_ == 0)
            {
               if(FightData.instance.isPVE)
               {
                  lihuiMcList[1].gotoAndStop(3);
               }
               else
               {
                  lihuiMcList[1].gotoAndStop(2);
               }
            }
            playStartMv(lihuiMcList,fightSignInMcList);
         };
         roleArr = FightData.instance.getLiHui();
         var fightSignInArr:Array = FightData.instance.getFightSignIn();
         clsArr = ["mmo.lihui.view.LiHuiRole_" + roleArr[0],"mmo.lihui.view.LiHuiRole_" + roleArr[1],"mmo.fightsignin.FightSignInView_" + fightSignInArr[0],"mmo.fightsignin.FightSignInView_" + fightSignInArr[1]];
         urlArr = ["lihui/view/lihui_role_" + roleArr[0],"lihui/view/lihui_role_" + roleArr[1],"fightsignin/view/fightsigninview_" + fightSignInArr[0],"fightsignin/view/fightsigninview_" + fightSignInArr[1]];
         lihuiMcList = [];
         fightSignInMcList = [];
         startLoad();
      }
      
      private function playStartMv(param1:Array, param2:Array) : void
      {
         var lihuiMcList:Array = param1;
         var fightSignInMcList:Array = param2;
         ResScheduler.getResource("pet/petfightnew_startmv",function(param1:MovieClip):void
         {
            LayerManager.getFightingTop().addChild(new StartMovie(param1,lihuiMcList,fightSignInMcList));
         },"mmo.petfightnew.movie.StartMovie",null,null,ResPriority.HIGHEST,true,FightData.instance.applicationDomain);
      }
      
      private function loadSounds() : void
      {
         ServiceContainer.instance.addEventListener(ServiceContainerEvent.onGetService,this.musicxx);
         ServiceContainer.instance.tryGetService(IFightMusic);
      }
      
      private function musicxx(param1:ServiceContainerEvent) : void
      {
         if(param1.serviceName != "PetFightMusicService")
         {
            return;
         }
         ServiceContainer.instance.removeEventListener(ServiceContainerEvent.onGetService,this.musicxx);
         var _loc2_:IFightMusic = param1.service as IFightMusic;
         FightController.instance.ipetmusic = _loc2_;
         _loc2_.addEventListener(FightMusicEvent.LOADINIT_END,this.onLoadMusic);
         _loc2_.loadPetFightMusicInit();
      }
      
      private function onLoadMusic(param1:FightMusicEvent) : void
      {
         param1.currentTarget.removeEventListener(FightMusicEvent.LOADINIT_END,this.onLoadMusic);
         this.loadNpcIcon();
      }
      
      private function loadNpcIcon() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function battleFail(param1:Boolean) : void
      {
         this.playerInfos = [];
         ProgressFullSprite.close();
         FightController.instance.dispose();
         if(param1)
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.ENTER_FIGHT_FAIL));
         }
      }
      
      public function onJoinBattle(param1:SocketClientEvent) : void
      {
         var _loc7_:Object = null;
         var _loc8_:PlayerBattleInfo = null;
         if(this.petFightConfig.getIsFighting())
         {
            this.fightCmdCacher.cacheCmd(PetClient.RSPN_JOIN_BATTLE_JOINER,param1,true);
            return;
         }
         this.setSlotArr.length = 0;
         if(param1.params.msg != undefined)
         {
            if(FightController.instance.isAuto)
            {
               GatherClient.instance.switchItemConsumState(this._autoFightItemId,false);
            }
            if(param1.params.msg != "你不能够在离开一个战场之前，加入另外一个战场！")
            {
               if(param1.params.msg == "你的亚比很虚弱了，快去治疗它吧！\n点击亚比背包内的亚比恢复就可以治疗它哦！")
               {
                  this.showNoBloodPanel();
               }
               else
               {
                  NewDialog.showFailMessage(param1.params.msg);
               }
            }
            this.battleFail(true);
            return;
         }
         var _loc2_:Boolean = Boolean(param1.params.esc);
         var _loc3_:Boolean = Boolean(param1.params.sw);
         var _loc4_:Boolean = Boolean(param1.params.ch);
         FightController.instance.canEscape = _loc2_;
         FightController.instance.canSwitch = _loc3_;
         FightController.instance.canCatch = _loc4_;
         if(this.teamService.getMyTeam() != null && this.teamService.getMyTeam().leader != SocketClient.instance.myUserName)
         {
            FightController.instance.canEscape = false;
         }
         if(_loc4_)
         {
            if(!FightController.instance.isCatchablePet)
            {
               FightController.instance.canCatch = false;
            }
         }
         var _loc5_:Array = param1.params.pmmList as Array;
         if(_loc5_ == null)
         {
            return;
         }
         var _loc6_:String = "";
         for each(_loc7_ in _loc5_)
         {
            _loc8_ = new PlayerBattleInfo();
            _loc8_.parseInfo(_loc7_);
            _loc6_ += "player:" + _loc8_.PMMasterId + ";slotId:" + _loc8_.slotId + "#";
            if(!this.hasPlayer(_loc8_))
            {
               this.playerInfos.push(_loc8_);
            }
         }
         this.joinInfoArr.push({
            "type":"joinbattle",
            "des":_loc6_
         });
      }
      
      public function onOtherJoin(param1:SocketClientEvent) : void
      {
         var _loc4_:Object = null;
         var _loc5_:PlayerBattleInfo = null;
         if(this.petFightConfig.getIsFighting())
         {
            this.fightCmdCacher.cacheCmd(PetClient.RSPN_JOIN_BATTLE_OTHER,param1,false);
            return;
         }
         var _loc2_:Array = param1.params.b as Array;
         if(_loc2_ == null)
         {
            return;
         }
         var _loc3_:String = "";
         for each(_loc4_ in _loc2_)
         {
            _loc5_ = new PlayerBattleInfo();
            _loc5_.parseInfo(_loc4_);
            _loc3_ += "player:" + _loc5_.PMMasterId + ";slotId:" + _loc5_.slotId + "#";
            if(!this.hasPlayer(_loc5_))
            {
               this.playerInfos.push(_loc5_);
            }
         }
         this.joinInfoArr.push({
            "type":"otherjoin",
            "des":_loc3_
         });
      }
      
      public function onSlotId(param1:SocketClientEvent) : void
      {
         if(this.petFightConfig.getIsFighting())
         {
            this.fightCmdCacher.cacheCmd(PetClient.RSPN_SET_BATTLE_SLOT,param1,false);
            return;
         }
         this.setSlotArr.push(param1.params);
      }
      
      private function setSlot() : void
      {
         var _loc2_:Object = null;
         var _loc3_:int = 0;
         var _loc4_:PlayerBattleInfo = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.setSlotArr.length)
         {
            _loc2_ = this.setSlotArr[_loc1_] as Object;
            _loc3_ = 0;
            while(_loc3_ < this.playerInfos.length)
            {
               _loc4_ = this.playerInfos[_loc3_] as PlayerBattleInfo;
               if(_loc2_.pmmId == _loc4_.PMMasterId)
               {
                  _loc4_.slotId = _loc2_.newSlotId;
                  break;
               }
               _loc3_++;
            }
            _loc1_++;
         }
         this.setSlotArr.length = 0;
      }
      
      public function onFightStart(param1:SocketClientEvent) : void
      {
         var _loc16_:Array = null;
         var _loc17_:PlayerBattleInfo = null;
         var _loc18_:Object = null;
         var _loc19_:PlayerBattleInfo = null;
         if(this._replayCmdExtractor)
         {
            this._replayCmdExtractor.dispose();
         }
         if(this.petFightConfig.getIsFighting())
         {
            this.fightCmdCacher.cacheCmd(PetClient.RSPN_START_BATTLE,param1,false);
            return;
         }
         this.joinInfoArr.push({
            "type":"fightstart",
            "des":"zhandoukaishi"
         });
         ProgressFullSprite.show();
         this.setSlot();
         if(param1.params.bs != null)
         {
            _loc16_ = (param1.params.bs as String).split("||");
            FightData.instance.bs = BSUtil.parseBS(_loc16_[0]);
            FightData.instance.curBs = param1.params.bs;
         }
         var _loc2_:String = _loc16_ != null ? _loc16_[1] : "";
         var _loc3_:Boolean = Boolean(param1.params.video);
         var _loc4_:int = int(param1.params.id);
         var _loc5_:int = int(param1.params.vid);
         var _loc6_:int = int(param1.params.type);
         var _loc7_:Array = BitUtil.splitIntoIntArray(param1.params.srt,4);
         var _loc8_:* = _loc7_[1] == 1;
         var _loc9_:* = _loc7_[2] == 1;
         var _loc10_:* = _loc7_[3] == 1;
         var _loc11_:int = 1;
         if(param1.params.pt == 1)
         {
            _loc11_ = 2;
         }
         else if(param1.params.pt == 3)
         {
            _loc11_ = 4;
            FightData.instance.fetterEffect = FetterUtil.getAllActivedFetters(_loc2_);
         }
         else if(param1.params.pt == 4)
         {
            _loc11_ = 2;
         }
         else if(param1.params.pt == 7)
         {
            FightData.instance.isPFSShenHuanFight = true;
         }
         else if(param1.params.pt == 8)
         {
            FightData.instance.isPFS2v2 = true;
            _loc11_ = 2;
         }
         else if(param1.params.pt == 9)
         {
            FightData.instance.isPFS3KuangBao = true;
         }
         FightData.instance.fightType = param1.params.pt;
         FightData.instance.animationSpeedPercent = param1.params.asp ? int(param1.params.asp) : -1;
         FightData.instance.canControlPetNum = _loc11_;
         FightController.instance.isReplay = _loc3_;
         FightController.instance.isLive = param1.params.live;
         FightData.instance.replayId = _loc5_;
         FightData.instance.fightActId = _loc4_;
         FightData.instance.battleId = param1.params.br;
         FightData.instance.haveSummonPet = _loc8_;
         FightData.instance.haveXinghuiPet = _loc9_;
         FightData.instance.haveGQPet = _loc10_;
         FightData.instance.forceAutoCount = 0;
         if(param1.params.hasOwnProperty("spve"))
         {
            FightData.instance.isPVE = param1.params.spve;
         }
         else
         {
            FightData.instance.isPVE = false;
         }
         var _loc12_:int = int(param1.params.rci);
         var _loc13_:int = FightController.instance.isReplay ? 0 : -1;
         if(FightController.instance.isLive && _loc12_ > 0)
         {
            for each(_loc17_ in this.playerInfos)
            {
               if(_loc17_.PMMasterId == _loc12_)
               {
                  _loc13_ = int(_loc17_.slotId);
                  break;
               }
            }
         }
         FightData.instance.setFightData(this.playerInfos,_loc13_);
         if(Boolean(param1.params.useAiTypes) && param1.params.useAiTypes.length > 0)
         {
            FightController.instance.useAiType = FightData.instance.myInfo.isLocalIdAndSlotIdSame() ? int(param1.params.useAiTypes[0]) : int(param1.params.useAiTypes[11]);
         }
         if(FightController.instance.useAiType > 0)
         {
            FightController.isAutoUseSkill = FightController.instance.useAiType != 3;
         }
         FightData.instance.myInfo.updateExtensionInfo(param1.params);
         this.playerInfos = [];
         if(param1.params.pmmList != null && param1.params.pmmList.length != 0)
         {
            for each(_loc18_ in param1.params.pmmList)
            {
               _loc19_ = new PlayerBattleInfo();
               _loc19_.parseInfo(_loc18_);
               _loc19_ = FightData.instance.setLocaId(_loc19_);
               if(_loc19_.myPets != null && _loc19_.myPets.length > 0 && FightData.instance.playerInfo[_loc19_.slotId] != null)
               {
                  FightData.instance.playerInfo[_loc19_.slotId].myPets[0].updateInfo(_loc19_.myPets[0]);
               }
            }
         }
         this.petFightConfig.setIsFighting(true);
         var _loc14_:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
         if(FightData.instance.isFetterEffect)
         {
            _loc14_.fightSkillEffect = GameOptionConfig.NoFightSkillEffect;
         }
         FightData.instance.isLowQuality = _loc14_.isNoFightSkillEffect;
         FightData.instance.setLiHuiArr(param1.params.verp ? param1.params.verp : "");
         FightData.instance.setFightSignInArr(param1.params.luokuans ? param1.params.luokuans : "");
         var _loc15_:IPetTitleService = ServicePool.instance.getService(IPetTitleService);
         _loc15_.onGetPetTitleBeforeFight(param1.params.vtmp ? param1.params.vtmp : []);
         if(_loc3_)
         {
            this.dealReplay(_loc5_,_loc6_);
         }
         else
         {
            this.loadSounds();
         }
      }
      
      public function onSummonPet(param1:SocketClientEvent) : void
      {
         FightController.instance.add(PetClient.RSPN_USE_SUMMON_SKILL,param1.params);
      }
      
      private function dealReplay(param1:int, param2:int) : void
      {
         var replayId:int = param1;
         var replayType:int = param2;
         this._replayCmdExtractor = new ReplayCmdExtractor_Queue();
         this._replayCmdExtractor.startLoadReplayCmd(function():void
         {
            ProgressFullSprite.show();
            loadSounds();
         });
      }
      
      public function autoFight() : void
      {
         var _loc1_:ITaskService = null;
         if(!this.hasAvailableTime())
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.END_AUTO_FIGHT,{}));
            FightController.instance.dispose();
            GatherClient.instance.switchItemConsumState(this._autoFightItemId,false);
            return;
         }
         if(this.teamService.getMyTeam() != null)
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.END_AUTO_FIGHT,{}));
            FightController.instance.dispose();
            GatherClient.instance.switchItemConsumState(this._autoFightItemId,false);
            NewDialog.showFailMessage("组队状态不能自动战斗！");
            return;
         }
         if(SceneManager.getInstance().loadedSceneInfo.sceneName == "aixiscene5")
         {
            _loc1_ = ServicePool.instance.getService(ITaskService);
            if(!_loc1_.isUserTaskFinish(582))
            {
               return;
            }
         }
         SocketClient.instance.addEventListener(PetClient2.cmdAutoFight,this.onAutoFight);
         PetClient2.instance.autoFight();
      }
      
      private function onAutoFight(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(PetClient2.cmdAutoFight,this.onAutoFight);
         if(param1.params.canAuto)
         {
            FightController.instance.isAuto = true;
            FightController.isAutoUseSkill = true;
            FightController.instance.canUseAutoTimes = param1.params.num;
         }
         else if(param1.params.hasPet)
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.END_AUTO_FIGHT,{}));
            FightController.instance.dispose();
            GatherClient.instance.switchItemConsumState(this._autoFightItemId,false);
         }
      }
      
      private function checkAutoFightItem() : void
      {
         SocketClient.instance.addEventListener(GatherClient.cmdGetUsingItems,this.onGetItems);
         GatherClient.instance.getUsingItems();
      }
      
      private function onGetItems(param1:SocketClientEvent) : void
      {
         var _loc3_:Object = null;
         SocketClient.instance.removeEventListener(GatherClient.cmdGetUsingItems,this.onGetItems);
         var _loc2_:Array = param1.params.items;
         if(_loc2_ == null || _loc2_.length <= 0)
         {
            return;
         }
         for each(_loc3_ in _loc2_)
         {
            if(_loc3_.ii == this._autoFightItemId)
            {
               if(_loc3_.op)
               {
                  SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED,this.onSceneInited);
               }
               break;
            }
         }
      }
      
      public function enableAutoFight() : void
      {
         if(this.hasAvailableTime())
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.START_AUTO_FIGHT,{}));
         }
      }
      
      public function lookBossReplay(param1:int, param2:int, param3:String) : void
      {
      }
      
      public function lookReplay(param1:int, param2:int = 0) : void
      {
      }
      
      public function get autoFightItemId() : int
      {
         return this._autoFightItemId;
      }
      
      public function set autoFightItemId(param1:int) : void
      {
         this._autoFightItemId = param1;
      }
      
      public function disableAutoFight() : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.END_AUTO_FIGHT,{}));
      }
      
      public function isFighting() : Boolean
      {
         if(ConfigReader.instance.xmlDocument.fight.fdebug == "true" && Boolean(IFightController(ServiceContainer.getService(IFightController)).isFighting))
         {
            return true;
         }
         return this.petFightConfig.getIsFighting();
      }
      
      public function closeFightPanel() : void
      {
         FightController.instance.fightPanel.close();
         FightController.instance.dispose();
      }
      
      private function hasAvailableTime() : Boolean
      {
         var _loc1_:IAntiAddiction = ServicePool.instance.getService(IAntiAddiction);
         if(_loc1_.getRealAvailableTime() <= 0)
         {
            ProgressFullSprite.close();
            NewDialog.showFailMessage("小奥拉探险了很长时间，已经非常疲劳了，无法进行对战，请好好休息明天再来吧。");
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.ENTER_FIGHT_FAIL));
            return false;
         }
         return true;
      }
      
      public function ifSatisfyFightCondition() : Boolean
      {
         var _loc1_:ITaskService = ServicePool.instance.getService(ITaskService);
         if(!_loc1_.isUserTaskFinish(150))
         {
            return true;
         }
         if(!this.hasAvailableTime())
         {
            return false;
         }
         if(!this.hasAvailablePet())
         {
            return false;
         }
         return true;
      }
      
      public function changeBackgroundRes(param1:String, param2:String) : void
      {
         var _loc3_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         GetBackgroundUtil.changeBackgroundRes(_loc3_,param1,param2);
      }
      
      public function resetBackgroundRes() : void
      {
         GetBackgroundUtil.resetBackgroundRes();
      }
      
      public function switchFightMode(param1:int, param2:Object = null) : void
      {
         FightData.fightMode = param1;
         if(param2 == null)
         {
            FightData.startMovieInfo = {};
         }
         else
         {
            FightData.startMovieInfo = param2;
         }
      }
      
      public function handleNextFight() : void
      {
         var _loc3_:Object = null;
         var _loc1_:Array = this.fightCmdCacher.getOneCache();
         if(_loc1_ == null)
         {
            return;
         }
         if(this.haveFinishCmd(_loc1_))
         {
            this.handleNextFight();
            return;
         }
         var _loc2_:int = 0;
         while(_loc2_ < _loc1_.length)
         {
            _loc3_ = _loc1_[_loc2_] as Object;
            switch(_loc3_.cmd)
            {
               case PetClient.RSPN_JOIN_BATTLE_JOINER:
                  this.onJoinBattle(_loc3_.evt);
                  break;
               case PetClient.RSPN_JOIN_BATTLE_OTHER:
                  this.onOtherJoin(_loc3_.evt);
                  break;
               case PetClient.RSPN_SET_BATTLE_SLOT:
                  this.onSlotId(_loc3_.evt);
                  break;
               case PetClient.RSPN_START_BATTLE:
                  this.onFightStart(_loc3_.evt);
            }
            _loc2_++;
         }
      }
      
      private function haveFinishCmd(param1:Array) : Boolean
      {
         var _loc4_:Object = null;
         var _loc2_:Boolean = false;
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc4_ = param1[_loc3_] as Object;
            if(_loc4_.cmd == PetClient.RSPN_ESCAPE || _loc4_.cmd == PetClient.RSPN_FIN_BATTLE)
            {
               _loc2_ = true;
               break;
            }
            _loc3_++;
         }
         return _loc2_;
      }
      
      public function setFightTitleView(param1:DisplayObject) : void
      {
         FightData.instance.saveFightTitleView(param1);
      }
      
      public function changeAutoUseSkillState(param1:Boolean) : void
      {
         FightController.isAutoUseSkill = param1;
         if(!FightController.isAutoUseSkill)
         {
            PetClient.instance.changeAutoUseSkillState(false);
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.END_AUTO_FIGHT));
         }
         NewOrderlySkillStrategy.reset();
      }
      
      public function showXingHuiKillBig(param1:int, param2:Function = null) : void
      {
         var petSkinInfo:PetSkinInfo = null;
         var domain:ApplicationDomain = null;
         var raceId:int = param1;
         var onMovieEnd:Function = param2;
         var skinDataService:IPetSkinDataService = ServiceContainer.instance.getService(IPetSkinDataService) as IPetSkinDataService;
         petSkinInfo = skinDataService.getPetSkinInfoBySkinId(raceId);
         domain = new ApplicationDomain(ApplicationDomain.currentDomain);
         var loader:XingHuiKillBigMovieLoader = new XingHuiKillBigMovieLoader(domain);
         loader.loadMovie(raceId,1,function(param1:MovieClip, param2:MovieClip = null):*
         {
            /*
             * Decompilation error
             * Code may be obfuscated
             * Tip: You can try enabling "Deobfuscate code" option in Settings
             * Error type: ArrayIndexOutOfBoundsException (null)
             */
            throw new flash.errors.IllegalOperationError("Not decompiled due to error");
         });
      }
      
      public function showGQKillBig(param1:int, param2:int, param3:Function = null, param4:Boolean = false) : void
      {
         var petSkinInfo:PetSkinInfo = null;
         var domain:ApplicationDomain = null;
         var raceId:int = param1;
         var killBigMvType:int = param2;
         var onMovieEnd:Function = param3;
         var isStopFrameLabel:Boolean = param4;
         var skinDataService:IPetSkinDataService = ServiceContainer.instance.getService(IPetSkinDataService) as IPetSkinDataService;
         petSkinInfo = skinDataService.getPetSkinInfoBySkinId(raceId);
         domain = new ApplicationDomain(ApplicationDomain.currentDomain);
         var loader:GQKillBigMovieLoader = new GQKillBigMovieLoader(domain);
         loader.loadMovie(raceId,raceId,1,function(param1:MovieClip, param2:MovieClip = null):*
         {
            /*
             * Decompilation error
             * Code may be obfuscated
             * Tip: You can try enabling "Deobfuscate code" option in Settings
             * Error type: ArrayIndexOutOfBoundsException (null)
             */
            throw new flash.errors.IllegalOperationError("Not decompiled due to error");
         },killBigMvType,false);
      }
   }
}

