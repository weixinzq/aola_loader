package mmo.petfightnew.common.startmovie
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import mmo.common.DisplayUtil;
   import mmo.common.GlobalVariable;
   import mmo.common.ProgressFullSprite;
   import mmo.common.event.EnterFrameManager;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.simplemoviehelper.ShowMovieOrCartoonHelper;
   import mmo.common.sound.SoundManager;
   import mmo.common.user.UserInfo;
   import mmo.config.ConfigReader;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.headframe.HeadFrameFactory;
   import mmo.interfaces.material.headframe.HeadFrameSize;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.util.PreLoadAssetsUtil;
   
   public class StartMovie3v3
   {
      
      private var startMovie:MovieClip;
      
      private var loadingNum:int = 0;
      
      private var frameTaskList:Array = null;
      
      private var timer:Timer;
      
      private const SEND_CMD_INTERNVAL:int = 2000;
      
      private var _userNameArr:Array;
      
      public function StartMovie3v3()
      {
         super();
      }
      
      public function show() : void
      {
         var pathName:String = FightData.startMovieInfo.pathName;
         var className:String = FightData.startMovieInfo.className;
         ProgressFullSprite.show();
         ResScheduler.getResource(pathName,function(param1:MovieClip):void
         {
            ProgressFullSprite.close();
            startMovie = param1;
            initMovie();
         },className,null,null,ResPriority.NORMAL,true,FightData.instance.applicationDomain);
      }
      
      private function initMovie() : void
      {
         var _loc1_:PlayerBattleInfo = null;
         LayerManager.switchLayer(LayerManager.FIGHTING_LAYER);
         LayerManager.getFightingTop().addChild(this.startMovie);
         this.startMovie.mouseEnabled = false;
         this.startMovie.mouseChildren = false;
         this._userNameArr = [];
         for each(_loc1_ in FightData.instance.playerInfo)
         {
            if(_loc1_.PMMasterId > 0)
            {
               ++this.loadingNum;
               this._userNameArr.push(_loc1_.userName);
            }
         }
         FightController.instance;
         this.frameTaskList = [this.initMcs,this.initSendLoading,this.initEvent,this.initMusic];
         EnterFrameManager.instance.registerNextFrame(this.runTask);
         HeadFrameFactory.createHeadFrameByContainer(this._userNameArr,null,this.startMovie,HeadFrameSize.BIG,null,this.afterLoadPlayerHeadFrame,false,true,false);
      }
      
      private function afterLoadPlayerHeadFrame(param1:Array) : void
      {
      }
      
      private function initMcs() : void
      {
         var _loc1_:Boolean = false;
         var _loc9_:int = 0;
         var _loc10_:PlayerBattleInfo = null;
         var _loc11_:FightIconRegister = null;
         var _loc12_:int = 0;
         var _loc13_:int = 0;
         if(FightData.instance.myInfo.isLocalIdAndSlotIdSame())
         {
            _loc1_ = true;
         }
         else
         {
            _loc1_ = false;
         }
         var _loc2_:Array = GlobalVariable.instance.getVar(FightData.startMovieInfo.myInfo) as Array;
         var _loc3_:Array = GlobalVariable.instance.getVar(FightData.startMovieInfo.myPetInfo3v3) as Array;
         var _loc4_:Array = GlobalVariable.instance.getVar(FightData.startMovieInfo.vsInfo) as Array;
         var _loc5_:Array = GlobalVariable.instance.getVar(FightData.startMovieInfo.vsPetInfo) as Array;
         MovieClip(this.startMovie.getChildByName("roundMC")).gotoAndStop(_loc2_.length + 1);
         var _loc6_:int = 0;
         while(_loc6_ < _loc2_.length)
         {
            MovieClip(this.startMovie.getChildByName("myWin" + _loc6_.toString())).gotoAndStop(_loc2_[_loc6_] + 2);
            MovieClip(this.startMovie.getChildByName("vsWin" + _loc6_.toString())).gotoAndStop(_loc4_[_loc6_] + 2);
            this.addPetIcon(_loc5_[_loc6_],MovieClip(this.startMovie.getChildByName("mc" + _loc6_.toString())),"vsMC");
            _loc6_++;
         }
         var _loc7_:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         var _loc8_:int = 0;
         while(_loc8_ < 3)
         {
            this.addPetIcon(PetBriefInfo(_loc7_.getMyPets()[_loc8_]).viewId,MovieClip(this.startMovie.getChildByName("mc" + _loc8_.toString())),"myMC");
            _loc8_++;
         }
         _loc9_ = 0;
         while(_loc9_ <= 5)
         {
            _loc10_ = FightData.instance.playerInfo[_loc9_] as PlayerBattleInfo;
            if(_loc10_ != null)
            {
               if(_loc1_)
               {
                  _loc11_ = new FightIconRegister(_loc10_,Sprite(this.startMovie.getChildByName("myIcon")));
                  if(_loc10_.PMMasterId != UserInfo.userId)
                  {
                     _loc11_.addEventListener(FightIconRegister.LOAD_DONE,this.onOthersLoadDone);
                  }
               }
               else
               {
                  _loc11_ = new FightIconRegister(_loc10_,Sprite(this.startMovie.getChildByName("vsIcon")));
                  _loc12_ = int(PetBriefInfo(_loc10_.myPets[0]).viewId);
                  _loc5_.push(_loc12_);
                  this.addPetIcon(_loc12_,MovieClip(this.startMovie.getChildByName("mc" + _loc2_.length.toString())),"vsMC");
                  if(_loc10_.PMMasterId > 0)
                  {
                     _loc11_.addEventListener(FightIconRegister.LOAD_DONE,this.onOthersLoadDone);
                  }
               }
            }
            _loc10_ = FightData.instance.playerInfo[11 - _loc9_] as PlayerBattleInfo;
            if(_loc10_ != null)
            {
               if(_loc1_)
               {
                  _loc11_ = new FightIconRegister(_loc10_,Sprite(this.startMovie.getChildByName("vsIcon")));
                  _loc13_ = int(PetBriefInfo(_loc10_.myPets[0]).viewId);
                  _loc5_.push(_loc13_);
                  this.addPetIcon(_loc13_,MovieClip(this.startMovie.getChildByName("mc" + _loc2_.length.toString())),"vsMC");
                  if(_loc10_.PMMasterId > 0)
                  {
                     _loc11_.addEventListener(FightIconRegister.LOAD_DONE,this.onOthersLoadDone);
                  }
               }
               else
               {
                  _loc11_ = new FightIconRegister(_loc10_,Sprite(this.startMovie.getChildByName("myIcon")));
                  if(_loc10_.PMMasterId != UserInfo.userId)
                  {
                     _loc11_.addEventListener(FightIconRegister.LOAD_DONE,this.onOthersLoadDone);
                  }
               }
            }
            _loc9_++;
         }
         MovieClip(this.startMovie.getChildByName("mc" + _loc2_.length.toString())).gotoAndPlay(2);
      }
      
      private function addPetIcon(param1:int, param2:MovieClip, param3:String) : void
      {
         var _loc4_:MovieClip = param2.getChildByName(param3) as MovieClip;
         var _loc5_:Sprite = _loc4_.getChildByName("iconContainer") as Sprite;
         _loc5_.removeChildAt(0);
         var _loc6_:PetIconContainer = new PetIconContainer(param1,PetIconType.LARGE,false);
         _loc6_.addEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoadIcon);
         _loc5_.addChild(_loc6_);
         _loc6_.startLoad();
      }
      
      private function onLoadIcon(param1:PetIconEvent) : void
      {
         var _loc2_:PetIconContainer = param1.currentTarget as PetIconContainer;
         _loc2_.removeEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoadIcon);
         DisplayUtil.stop(_loc2_);
         DisplayUtil.scaleDisplay(_loc2_,64,64);
         DisplayUtil.middleDisplay(_loc2_,70,64);
      }
      
      private function onOthersLoadDone(param1:Event) : void
      {
         param1.currentTarget.removeEventListener(FightIconBase.LOAD_DONE,this.onOthersLoadDone);
         --this.loadingNum;
         this.checkLoad();
      }
      
      private function initSendLoading() : void
      {
         this.timer = new Timer(1000,2);
         this.timer.addEventListener(TimerEvent.TIMER_COMPLETE,this.onTimesup);
         this.timer.start();
      }
      
      private function onTimesup(param1:TimerEvent) : void
      {
         this.timer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onTimesup);
         this.timer.stop();
         PreLoadAssetsUtil.instance.loadAssets(FightData.instance.playerInfo,this.onMyLoadDone);
         if(this.loadingNum > 1 && Boolean(ConfigReader.instance.showOthersFightLoad))
         {
            this.timer = new Timer(this.SEND_CMD_INTERNVAL);
            this.timer.addEventListener(TimerEvent.TIMER,this.sendLoad);
            this.timer.start();
         }
      }
      
      private function sendLoad(param1:TimerEvent) : void
      {
         SendLoadingHelper.sendLoadingInfo(PreLoadAssetsUtil.instance.progress);
      }
      
      private function onMyLoadDone() : void
      {
         SendLoadingHelper.sendLoadingInfo(PreLoadAssetsUtil.instance.progress);
         --this.loadingNum;
         this.checkLoad();
      }
      
      private function checkLoad() : void
      {
         if(this.loadingNum <= 0)
         {
            this.enterFight();
         }
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
         if(FightData.instance.haveXinghuiPet)
         {
            ShowMovieOrCartoonHelper.showMovieOrCartoon(true,"petfightbackground/common","mmo.petfight.XinghuicommonBackMv",onEnterFight);
         }
         else
         {
            onEnterFight();
         }
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
      
      private function onEscape(param1:SocketClientEvent) : void
      {
         if(param1.params.reqId > 0)
         {
            --this.loadingNum;
            this.checkLoad();
         }
      }
      
      private function initMusic() : void
      {
         SoundManager.instance.stopBackgroundMusic();
         FightController.instance.playSound("x7011",false,0.7);
      }
      
      private function dispose() : void
      {
         this.timer.stop();
         this.timer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onTimesup);
         this.timer.removeEventListener(TimerEvent.TIMER,this.sendLoad);
         SocketClient.instance.removeEventListener(PetClient.RSPN_ESCAPE,this.onEscape);
         DisplayUtil.stopAndRemove(this.startMovie);
         PreLoadAssetsUtil.instance.dispose();
      }
   }
}

