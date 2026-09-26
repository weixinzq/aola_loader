package mmo.petfightnew.common.startmovie
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import mmo.common.DisplayUtil;
   import mmo.common.event.EnterFrameManager;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.simplemoviehelper.ShowMovieOrCartoonHelper;
   import mmo.common.sound.SoundManager;
   import mmo.config.ConfigReader;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.material.pettitle.IPetTitleService;
   import mmo.interfaces.material.pettitle.PetTitleIconParam;
   import mmo.interfaces.material.pettitle.UserPetTitle;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.loader.layer.LayerManager;
   import mmo.petfightnew.DocPetFight;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.PreLoadAssetsUtil;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActMaterialLoader;
   
   public class StartMovie extends MovieClip
   {
      
      private static const MOVIE_X:Number = 775.7;
      
      private static const MIDDLE_Y:Number = 290.45;
      
      private static const SPACE:Number = 50;
      
      private static const ICON_HEIGHT:Number = 101.7;
      
      private static const SEND_CMD_INTERNVAL:int = 2000;
      
      private var myTeamInfo:Array = [];
      
      private var vsTeamInfo:Array = [];
      
      private var timer:Timer;
      
      private var loadingNum:int = 0;
      
      private var frameTaskList:Array = null;
      
      private var _mc:MovieClip;
      
      private var _mcRole:MovieClip;
      
      private var _otherRole:MovieClip;
      
      private var _fightSignInMcArr:Array;
      
      private var _ipts:IPetTitleService = ServicePool.instance.getService(IPetTitleService);
      
      public function StartMovie(param1:MovieClip, param2:Array, param3:Array)
      {
         super();
         this._mc = param1;
         this.addChild(this._mc);
         this._mcRole = param2[0];
         this._otherRole = param2[1];
         this._fightSignInMcArr = param3;
         this.mouseChildren = false;
         this.mouseEnabled = false;
         FightController.instance;
         this.frameTaskList = [this.initMcs,this.initSendLoading,this.initEvent,this.initMusic];
         EnterFrameManager.instance.registerNextFrame(this.runTask);
         DocPetFight.noteDiagnosticStartMovie(this);
      }
      
      private function runTask() : void
      {
         var _loc1_:Function = this.frameTaskList.shift();
         _loc1_.call(this);
         if(this.frameTaskList.length > 0)
         {
            EnterFrameManager.instance.registerNextFrame(this.runTask);
         }
      }
      
      private function initEvent() : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         if(FightData.instance.playerInfo[FightData.instance.vsSlot] != null)
         {
            _loc1_ = int(FightData.instance.playerInfo[FightData.instance.vsSlot].myPets[0].raceId);
            _loc2_ = FightController.instance.id;
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FIGHT_START,{
               "raceId":_loc1_,
               "id":_loc2_
            }));
         }
         SocketClient.instance.addEventListener(PetClient.RSPN_ESCAPE,this.onEscape);
      }
      
      private function initMusic() : void
      {
         SoundManager.instance.stopBackgroundMusic();
         FightController.instance.playSound("x7011",false,0.7);
      }
      
      private function onEscape(param1:SocketClientEvent) : void
      {
         if(param1.params.reqId > 0)
         {
            --this.loadingNum;
            this.checkLoad();
         }
      }
      
      private function initSendLoading() : void
      {
         PreLoadAssetsUtil.instance.loadAssets(FightData.instance.playerInfo,this.onMyLoadDone);
         if(this.loadingNum > 1 && Boolean(ConfigReader.instance.showOthersFightLoad))
         {
            this.timer = new Timer(SEND_CMD_INTERNVAL);
            this.timer.addEventListener(TimerEvent.TIMER,this.sendLoad);
            this.timer.start();
         }
      }
      
      private function onTimesup(param1:TimerEvent) : void
      {
         this.timer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onTimesup);
         this.timer.stop();
         this.enterFight();
      }
      
      private function onMyLoadDone() : void
      {
         SendLoadingHelper.sendLoadingInfo(1);
      }
      
      private function sendLoad(param1:TimerEvent) : void
      {
         SendLoadingHelper.sendLoadingInfo(PreLoadAssetsUtil.instance.progress);
      }
      
      private function initMcs() : void
      {
         var _loc1_:int = 0;
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:Boolean = false;
         if(FightData.instance.myInfo.isLocalIdAndSlotIdSame())
         {
            _loc3_ = true;
         }
         else
         {
            _loc3_ = false;
         }
         _loc1_ = 0;
         while(_loc1_ <= 5)
         {
            _loc2_ = FightData.instance.playerInfo[_loc1_] as PlayerBattleInfo;
            if(_loc2_ != null)
            {
               if(_loc3_)
               {
                  this.addPlayer(this.myTeamInfo,_loc2_);
               }
               else
               {
                  this.addPlayer(this.vsTeamInfo,_loc2_);
               }
            }
            _loc2_ = FightData.instance.playerInfo[11 - _loc1_] as PlayerBattleInfo;
            if(_loc2_ != null)
            {
               if(_loc3_)
               {
                  this.addPlayer(this.vsTeamInfo,_loc2_);
               }
               else
               {
                  this.addPlayer(this.myTeamInfo,_loc2_);
               }
            }
            _loc1_++;
         }
         CommonEventDispatcher.instance.addEventListener(PlayerInfoHandler.LOAD_DONE,this.onOthersLoadDone);
         this.addMySide();
         this.addVsSide();
      }
      
      private function addPlayer(param1:Array, param2:PlayerBattleInfo) : void
      {
         if(this.haveInfoInTeam(param1,param2))
         {
            return;
         }
         ++this.loadingNum;
         param1.push(param2);
      }
      
      private function haveInfoInTeam(param1:Array, param2:PlayerBattleInfo) : Boolean
      {
         var _loc3_:PlayerBattleInfo = null;
         for each(_loc3_ in param1)
         {
            if(_loc3_.PMMasterId == param2.PMMasterId)
            {
               return true;
            }
         }
         return false;
      }
      
      private function onOthersLoadDone(param1:Event) : void
      {
         --this.loadingNum;
         this.checkLoad();
      }
      
      private function checkLoad() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PlayerInfoHandler.LOAD_DONE,this.onOthersLoadDone);
         this.timer = new Timer(1000,1);
         this.timer.addEventListener(TimerEvent.TIMER_COMPLETE,this.onTimesup);
         this.timer.start();
      }
      
      private function enterFight() : void
      {
         var onEnterFight:Function = null;
         onEnterFight = function():void
         {
            var _loc1_:FightPanel = new FightPanel();
            LayerManager.getFightingTop().addChild(_loc1_);
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FIGHT_UI_START,{}));
         };
         this.dispose();
         if(FightData.instance.haveGQPet)
         {
            ShowMovieOrCartoonHelper.showMovieOrCartoon(true,"petfightbackground/common","mmo.petfight.GQcommonBackMv",onEnterFight);
         }
         else if(FightData.instance.haveXinghuiPet)
         {
            ShowMovieOrCartoonHelper.showMovieOrCartoon(true,"petfightbackground/common","mmo.petfight.XinghuicommonBackMv",onEnterFight);
         }
         else
         {
            onEnterFight();
         }
      }
      
      private function dispose() : void
      {
         if(this.timer != null)
         {
            this.timer.stop();
            this.timer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onTimesup);
            this.timer.removeEventListener(TimerEvent.TIMER,this.sendLoad);
            this.timer = null;
         }
         this.vsTeamInfo = null;
         this.myTeamInfo = null;
         this.frameTaskList = null;
         CommonEventDispatcher.instance.removeEventListener(PlayerInfoHandler.LOAD_DONE,this.onOthersLoadDone);
         SocketClient.instance.removeEventListener(PetClient.RSPN_ESCAPE,this.onEscape);
         DisplayUtil.stopAndRemove(this);
         PreLoadAssetsUtil.instance.dispose();
         DocPetFight.noteDiagnosticStartMovieDisposed(this);
      }
      
      private function addMovie(param1:Number, param2:Array) : void
      {
         var _loc4_:IconMovieBase = null;
         var _loc3_:int = 0;
         while(_loc3_ < param2.length)
         {
            _loc4_ = param2[_loc3_] as IconMovieBase;
            _loc4_.x = MOVIE_X;
            _loc4_.y = param1 + (ICON_HEIGHT + SPACE) * _loc3_;
            this.addChild(_loc4_);
            _loc4_.gotoAndPlay(1);
            _loc3_++;
         }
      }
      
      private function addMySide() : void
      {
         var _loc1_:MovieClip = ActComHelper.getChildNode(this._mc,"mcMyPlayer.mcView") as MovieClip;
         if(_loc1_)
         {
            _loc1_.addChild(this._mcRole);
         }
         var _loc2_:MovieClip = ActComHelper.getChildNode(this._mc,"mcMyPlayer.mcSignInView") as MovieClip;
         if(_loc2_)
         {
            _loc2_.addChild(this._fightSignInMcArr[0]);
         }
         var _loc3_:MovieClip = ActComHelper.getChildNode(this._mc,"mcMyPlayer.mcPetTitle") as MovieClip;
         var _loc4_:UserPetTitle = this._ipts.getRandomUserPetTitleForFight(true);
         if(_loc4_ != null && _loc3_ != null)
         {
            ActMaterialLoader.setView(_loc3_,MaterialTypes.PET_TITLE,_loc4_.materialId,true,null,new PetTitleIconParam(PetTitleIconParam.SIZE_BIG,1,_loc4_));
         }
         var _loc5_:Sprite = this._mc.getChildByName("spPlayer") as Sprite;
         if(_loc5_ == null)
         {
            return;
         }
         var _loc6_:MovieClip = _loc5_.getChildByName("mcMyTeam") as MovieClip;
         if(_loc6_ == null)
         {
            return;
         }
         new TeamInfoHandler().handleTeam(this.myTeamInfo,_loc6_,true);
      }
      
      private function addVsSide() : void
      {
         var _loc1_:MovieClip = ActComHelper.getChildNode(this._mc,"mcVsPlayer.mcView") as MovieClip;
         if(_loc1_)
         {
            _loc1_.addChild(this._otherRole);
         }
         var _loc2_:MovieClip = ActComHelper.getChildNode(this._mc,"mcVsPlayer.mcSignInView") as MovieClip;
         if(_loc2_)
         {
            _loc2_.addChild(this._fightSignInMcArr[1]);
         }
         var _loc3_:MovieClip = ActComHelper.getChildNode(this._mc,"mcVsPlayer.mcPetTitle") as MovieClip;
         var _loc4_:UserPetTitle = this._ipts.getRandomUserPetTitleForFight(false);
         if(_loc4_ != null && _loc3_ != null)
         {
            ActMaterialLoader.setView(_loc3_,MaterialTypes.PET_TITLE,_loc4_.materialId,true,null,new PetTitleIconParam(PetTitleIconParam.SIZE_BIG,1,_loc4_));
         }
         var _loc5_:Sprite = this._mc.getChildByName("spPlayer") as Sprite;
         if(_loc5_ == null)
         {
            return;
         }
         var _loc6_:MovieClip = _loc5_.getChildByName("mcVSTeam") as MovieClip;
         if(_loc6_ == null)
         {
            return;
         }
         new TeamInfoHandler().handleTeam(this.vsTeamInfo,_loc6_,false);
      }
   }
}

