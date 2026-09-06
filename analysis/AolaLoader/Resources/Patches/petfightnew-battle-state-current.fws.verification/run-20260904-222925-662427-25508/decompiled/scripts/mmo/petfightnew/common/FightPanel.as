package mmo.petfightnew.common
{
   import com.greensock.TweenMax;
   import com.greensock.data.TweenLiteVars;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.DateUtil;
   import mmo.common.DisplayUtil;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.event.EnterFrameManager;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.utils.tips.NotifyQueue;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.GatherClient;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fighttalk.IFightTalk;
   import mmo.interfaces.follow.IFollowService;
   import mmo.interfaces.live.ILiveService;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.IPetBattleEffDataService;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.data.skin.IPetSkinDataService;
   import mmo.interfaces.pet.data.skin.PetSkinInfo;
   import mmo.interfaces.pet.fight.FightMode;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.fight.PetFightStateEvent;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.robot.IRobotService;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.team.TeamInfo;
   import mmo.interfaces.team.UserTeamInfo;
   import mmo.interfaces.title.ITitleService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.common.datastructures.ResourceObject;
   import mmo.loader.gc.GCManager;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.DocPetFight;
   import mmo.petfightnew.common.bossmovie.BossMovieConfig;
   import mmo.petfightnew.common.config.FightActUIConfig;
   import mmo.petfightnew.common.config.FightConfig;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.fightcontroller.AutoFightTimer;
   import mmo.petfightnew.common.fightcontroller.BargainSkillController;
   import mmo.petfightnew.common.fightcontroller.BattleSmallTurn;
   import mmo.petfightnew.common.fightcontroller.BossMovieHelper;
   import mmo.petfightnew.common.fightcontroller.CatchPm;
   import mmo.petfightnew.common.fightcontroller.Escape;
   import mmo.petfightnew.common.fightcontroller.FinBattle;
   import mmo.petfightnew.common.fightcontroller.HolySkillController;
   import mmo.petfightnew.common.fightcontroller.PMAutoTalk;
   import mmo.petfightnew.common.fightcontroller.SwitchPm;
   import mmo.petfightnew.common.fightcontroller.TerritoryRelive;
   import mmo.petfightnew.common.fightcontroller.TrainingTower;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.FIP_Controller;
   import mmo.petfightnew.common.handler.BackGroundViewHandler;
   import mmo.petfightnew.common.handler.SkillTargetSelecter;
   import mmo.petfightnew.common.handler.SkillUseValide;
   import mmo.petfightnew.common.manager.FightEnterFrameManager;
   import mmo.petfightnew.common.manager.FightFrameRateManager;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.petfightnew.common.manager.FightTweenMaxManager;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.movies.CanCatchMovie;
   import mmo.petfightnew.common.movies.CountMovie;
   import mmo.petfightnew.common.movies.ReadyBtn;
   import mmo.petfightnew.common.panel.ChangeMouse;
   import mmo.petfightnew.common.panel.GQMingYunBoYiChoosePanel;
   import mmo.petfightnew.common.panel.MyConfirmPanel;
   import mmo.petfightnew.common.panel.UIPanelBase;
   import mmo.petfightnew.common.panel.UIPanelFactory;
   import mmo.petfightnew.common.panel.UIPanelType;
   import mmo.petfightnew.common.panel.be.BEPanel;
   import mmo.petfightnew.common.panel.pet.CommonBuff1253PetInfoMC;
   import mmo.petfightnew.common.panel.pet.HunDunSumPetInfoMC;
   import mmo.petfightnew.common.panel.pet.PetInfoMCBase;
   import mmo.petfightnew.common.panel.pet.ShenLingPetInfoMC;
   import mmo.petfightnew.common.panel.pet.SmallPetInfoMC;
   import mmo.petfightnew.common.panel.pet.XingZhiCaiFight25PetInfoMc;
   import mmo.petfightnew.common.panel.skill.NewSkillPanel;
   import mmo.petfightnew.common.panel.skillwindword.SkillWindWordContainer;
   import mmo.petfightnew.common.panel.status.StatusEffectContainer;
   import mmo.petfightnew.common.skilleffect.GQXingZhiYuEffectHelper;
   import mmo.petfightnew.common.ui.FightLiveUI;
   import mmo.petfightnew.common.ui.FightTurnUIProxy;
   import mmo.petfightnew.common.ui.MyPetInfoPanel;
   import mmo.petfightnew.common.ui.PetFightSpaceLiveUI;
   import mmo.petfightnew.common.ui.ReplayUI;
   import mmo.petfightnew.common.ui.WaitTips;
   import mmo.petfightnew.common.ui.fetter.FetterUI;
   import mmo.petfightnew.common.ui.lingyufazhen.FaZhenSkillBtn;
   import mmo.petfightnew.common.useskill.IUseSkillStrategy;
   import mmo.petfightnew.common.useskill.NewOrderlySkillStrategy;
   import mmo.petfightnew.common.util.DeadZoneExploreEffectHelper;
   import mmo.petfightnew.common.util.DegeneratorPetHelper;
   import mmo.petfightnew.common.util.GQBuxiuLvtuEffecthelper;
   import mmo.petfightnew.common.util.GQFightFlauntStandEffectHelper;
   import mmo.petfightnew.common.util.GQMenghuanDiyueEffectHelper;
   import mmo.petfightnew.common.util.GQShenXuEffectHelper;
   import mmo.petfightnew.common.util.GQWanyuZhichaoEffectHelper;
   import mmo.petfightnew.common.util.GQWumangxingjiEffectHelper;
   import mmo.petfightnew.common.util.GQXingyueTongXingEffectHelper;
   import mmo.petfightnew.common.util.GQYingjieMengyueEffectHelper;
   import mmo.petfightnew.common.util.GQZhanYiEffectHelper;
   import mmo.petfightnew.common.util.GetStateMovieUtil;
   import mmo.petfightnew.common.util.HunDunLiLiangEffectHelper;
   import mmo.petfightnew.common.util.LegendPetHelper;
   import mmo.petfightnew.common.util.PositionUtil;
   import mmo.petfightnew.common.util.ScreenShaker;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.petfightnew.common.util.StringFormatUtil;
   import mmo.petfightnew.common.util.XingHuiFaHuanHelper;
   import mmo.petfightnew.common.util.XingHuiWangzheRealHelper;
   import mmo.petfightnew.common.util.ZhanYiEffectHelper;
   import mmo.play.activity.helper.StringUtil;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.gameoption.GameOptionMgr;
   import mmo.play.petfight.common.config.FightResConfig;
   import mmo.play.petfight.common.data.SkillType;
   import mmo.play.scene.Disposer;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3808")]
   public class FightPanel extends Sprite
   {
      
      private static const RelaxSkillId:int = 100001;
      
      private static const XingzhenSkillId:int = 100002;
      
      private static const UI_PANEL_NUM:int = 4;
      
      public var backgroundLayer:MovieClip;
      
      public var backgroundUpLayer:MovieClip;
      
      public var effectLayer:MovieClip;
      
      public var mcUIAndReplayLayer:MovieClip;
      
      public var mcUILayer:MovieClip;
      
      public var mclayertop:MovieClip;
      
      public var petLayer:MovieClip;
      
      public var petLayerDown:MovieClip;
      
      public var petLayerUp:MovieClip;
      
      public var platformLayer:MovieClip;
      
      private var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
      
      private var _titleSvr:ITitleService = ServicePool.instance.getService(ITitleService);
      
      private var _beforeIsShowTitleHonor:Boolean;
      
      private var _layerBackGround:Sprite;
      
      private var _layerBackGroundUp:Sprite;
      
      private var _layerPetUp:Sprite;
      
      private var _layerPet:Sprite;
      
      private var _layerPetDown:Sprite;
      
      private var _layerPlatform:Sprite;
      
      private var _layerEffect:Sprite;
      
      private var uiLayer:MovieClip;
      
      private var uIAndReplayLayer:MovieClip;
      
      private var _layerTop:Sprite;
      
      private var msgPanel:Sprite;
      
      private var _skillStrategy:IUseSkillStrategy;
      
      private var autoTxt:MovieClip;
      
      private var cancelBtn:SimpleButton;
      
      private var catchBtnIcon:MovieClip;
      
      private var catchBtnY:Number;
      
      private var iFightTalk:IFightTalk;
      
      private var statusEffectContainerList:Array = [];
      
      private var _skillWindWordContainerList:Array = [];
      
      private var smallPetInfoMCList:Array = [];
      
      private var hunDunSumPetInfoMCList:Array = [];
      
      private var _commonBuff1253PetInfoMCList:Array = [];
      
      private var _xingZhiCaiPetInfoMcList:Array = [];
      
      private var petDataService:IPetDataService;
      
      private var attributeHolder:Sprite;
      
      private var myBEPanel:Sprite;
      
      public var whoSwitch:int = 0;
      
      public var petLoadeNum:int = 0;
      
      public var canStart:Boolean = true;
      
      public var petMCList:Array = [];
      
      public var readyBtn:Array = [];
      
      public var team:TeamInfo;
      
      private var _canCatchMovies:Array = [];
      
      private var _titleView:DisplayObject = null;
      
      private var _fightActUI:DisplayObject = null;
      
      private var _replayUI:ReplayUI = null;
      
      private var _liveUI:FightLiveUI;
      
      private var _petFightSpaceliveUI:PetFightSpaceLiveUI;
      
      private var _isShaking:Boolean = false;
      
      private var _isClosed:Boolean = false;
      
      private var _isDisposed:Boolean = false;
      
      private var _escapeConfirmPanel:Sprite = null;
      
      private var _countMovie:CountMovie = null;
      
      private var _backGroundView:BackGroundViewHandler = null;
      
      private var _myPetInfoPanel:MyPetInfoPanel = null;
      
      private var _mcWait:WaitTips = null;
      
      private var _fetterUI:FetterUI = null;
      
      private var _uiPanelList:Array = [];
      
      private var _faZhenSkillBtn:FaZhenSkillBtn;
      
      private var _defaultFightUI:FightTurnUIProxy;
      
      private var _shakerList:Array = [];
      
      public function FightPanel()
      {
         super();
         this.tabChildren = false;
         this.tabEnabled = false;
         var _loc1_:ITeamService = ServiceContainer.instance.getService("TeamService") as ITeamService;
         this.team = _loc1_.getMyTeam();
         this._skillStrategy = new NewOrderlySkillStrategy();
         this.iFightTalk = ServicePool.instance.getService(IFightTalk);
         this.petDataService = ServicePool.instance.getService(IPetDataService);
         this.initLayers();
         FightController.instance.init(this);
         this.initView();
         this.initDefaultFightUI();
         this.initFightActUI();
         this.initFetterUI();
         this.initListener();
         GameOptionMgr.instance.setHudVisible(false);
         GameOptionMgr.instance.showOrHideControlBar(false);
         this._beforeIsShowTitleHonor = this._titleSvr.getIsShowTitleHonor();
         if(this._beforeIsShowTitleHonor)
         {
            this._titleSvr.setIsShowTitleHonor(false);
         }
      }
      
      private function initFetterUI() : void
      {
         if(FightData.instance.isFetterEffect)
         {
            this._fetterUI = new FetterUI();
            this._layerTop.addChild(this._fetterUI);
         }
      }
      
      public function get layerBackground() : Sprite
      {
         return this._layerBackGround;
      }
      
      public function get layerBackGroundUp() : Sprite
      {
         return this._layerBackGroundUp;
      }
      
      public function get layerTop() : Sprite
      {
         return this._layerTop;
      }
      
      public function get layerEffect() : Sprite
      {
         return this._layerEffect;
      }
      
      public function get layerPetDown() : Sprite
      {
         return this._layerPetDown;
      }
      
      public function get layerPet() : Sprite
      {
         return this._layerPet;
      }
      
      public function get layerPetUp() : Sprite
      {
         return this._layerPetUp;
      }
      
      public function get layerPlatform() : Sprite
      {
         return this._layerPlatform;
      }
      
      public function get layerUI() : Sprite
      {
         return this.uiLayer;
      }
      
      public function get layerUIAndReplay() : Sprite
      {
         return this.uIAndReplayLayer;
      }
      
      public function hidePetInfoMC(param1:int) : void
      {
         var _loc2_:PetInfoMCBase = this.smallPetInfoMCList[param1] as PetInfoMCBase;
         DisplayUtil.stopAndRemove(_loc2_);
      }
      
      public function petSay(param1:int, param2:String, param3:int = -1) : void
      {
         var _loc4_:MCPetContainer = this.petMCList[param1] as MCPetContainer;
         if(_loc4_)
         {
            _loc4_.say(param2,param3);
         }
      }
      
      private function addFightTitleView() : void
      {
         this._titleView = FightData.instance.popFightTitleView();
         if(null != this._titleView)
         {
            this.addEventListener(Event.ADDED_TO_STAGE,this.onAdd2Stage);
         }
      }
      
      private function onAdd2Stage(param1:Event) : void
      {
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onAdd2Stage);
         this._titleView.x = 345;
         this._titleView.y = 50;
         DisplayObjectContainer(this.uiLayer).addChild(this._titleView);
      }
      
      private function initListener() : void
      {
         MovieClip(this.uiLayer.mcCatch).addEventListener(MouseEvent.CLICK,this.onClickCatch);
         MovieClip(this.uiLayer.mcItem).addEventListener(MouseEvent.CLICK,this.onClickItem);
         MovieClip(this.uiLayer.mcPets).addEventListener(MouseEvent.CLICK,this.onClickPets);
         MovieClip(this.uiLayer.mcRelax).addEventListener(MouseEvent.CLICK,this.onClickRelax);
         SimpleButton(this.uiLayer.btnFightInfo).addEventListener(MouseEvent.CLICK,this.onClickFightInfo);
         this.addEscapeResponder();
         if(!FightController.instance.canCatch)
         {
            MovieClip(this.uiLayer.mcCatch).gotoAndStop(2);
         }
         FightController.instance.addEventListener(PetFightEvent.NEXT_TURN,this.onStartNextTurn);
         FightController.instance.addEventListener(PetFightEvent.NEXT_SMALL_TURN,this.onStartNextSmallTurn);
         this.addEventListener(Event.ADDED,this.onAdded);
         SceneManager.getInstance().addEventListener(SceneManagerEvent.ON_LOADING_SCENE,this.removeFromStage);
         CommonEventDispatcher.instance.addEventListener("PetFightNew_HideSomeThing",this.isHideSomething);
      }
      
      private function onRequireShakeScreen(param1:CommonEvent) : void
      {
         this.shake();
      }
      
      private function initLayers() : void
      {
         var _loc1_:Class = null;
         var _loc2_:Sprite = null;
         this._layerBackGround = this.getChild("backgroundLayer");
         this._layerBackGroundUp = this.getChild("backgroundUpLayer");
         this._layerEffect = this.getChild("effectLayer");
         this._layerPetUp = this.getChild("petLayerUp");
         this._layerPetUp.mouseChildren = this._layerPetUp.mouseEnabled = false;
         this._layerPet = this.getChild("petLayer");
         this._layerPetDown = this.getChild("petLayerDown");
         this._layerPlatform = this.getChild("platformLayer");
         this.uiLayer = this.getChildByName("mcUILayer") as MovieClip;
         this._layerTop = this.getChild("mclayertop");
         this.uIAndReplayLayer = this.getChildByName("mcUIAndReplayLayer") as MovieClip;
         this.uIAndReplayLayer.mouseChildren = this.uIAndReplayLayer.mouseEnabled = false;
         this.uiLayer.visible = !FightController.instance.isReplay;
         this._layerBackGround.cacheAsBitmap = true;
         this._layerBackGround.opaqueBackground = 16777215;
         if(FightData.instance.haveXinghuiPet && !FightData.instance.haveGQPet)
         {
            _loc1_ = FightData.instance.applicationDomain.getDefinition(FightResConfig.XH_PlatForm_ClsName) as Class;
            if(_loc1_)
            {
               _loc2_ = new _loc1_() as Sprite;
               this._layerPlatform.addChildAt(_loc2_,0);
            }
         }
      }
      
      private function getChild(param1:String) : *
      {
         return this.getChildByName(param1);
      }
      
      private function initDefaultFightUI() : void
      {
         this._defaultFightUI = new FightTurnUIProxy();
         this._defaultFightUI.init(this.uiLayer.mcDefaultFightUI);
      }
      
      private function initFightActUI() : void
      {
         var _loc1_:int = FightData.instance.fightActId;
         if(!FightActUIConfig.checkHaveUI(_loc1_))
         {
            return;
         }
         var _loc2_:String = FightActUIConfig.getActUICls(_loc1_);
         var _loc3_:Class = FightData.instance.applicationDomain.getDefinition(_loc2_) as Class;
         this._fightActUI = new _loc3_() as DisplayObject;
         if(!(this._fightActUI is IDispose))
         {
            throw new Error("战斗活动的UI要继承IDispose");
         }
         this._defaultFightUI.setVisible(false);
         this.addEventListener(Event.ADDED_TO_STAGE,this.onAddFightActUI);
      }
      
      private function onAddFightActUI(param1:Event) : void
      {
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onAddFightActUI);
         this._fightActUI.x = 345;
         this._fightActUI.y = 50;
         DisplayObjectContainer(this.uiLayer).addChild(this._fightActUI);
      }
      
      private function initView() : void
      {
         this._mcWait = this.uiLayer.getChildByName("mcWait") as WaitTips;
         this.hideWaitTips();
         this.catchBtnIcon = this.uiLayer.getChildByName("catchBtn") as MovieClip;
         this.catchBtnY = this.catchBtnIcon.y;
         this.catchBtnIcon.visible = false;
         this.catchBtnIcon.y -= 1000;
         this._myPetInfoPanel = this.uiLayer.getChildByName("mcMyPetInfo") as MyPetInfoPanel;
         this._myPetInfoPanel.setFightPanel(this);
         this.initFaZhenSkill();
         this.initBackGroundView();
         this.disableClick();
         this.setReady();
         this.checkBossMc();
         this.addFightTitleView();
         this._shakerList.push(new ScreenShaker(this._layerEffect,null,false));
         this._shakerList.push(new ScreenShaker(this._layerPet,null,false));
         this._shakerList.push(new ScreenShaker(this._layerPlatform,null,false));
         this._shakerList.push(new ScreenShaker(this._layerBackGroundUp,null,false));
         ActComHelper.setVisible(this.uiLayer,"mcItem",!FightData.instance.isPFS2v2);
         ActComHelper.setVisible(this.uiLayer,"mcRelax",FightData.instance.isPFS2v2);
         ActComHelper.setVisible(this.uiLayer,"btnFightInfo",FightController.instance.isShowFightInfo);
         var _loc1_:SimpleButton = ActComHelper.getChildNode(this.uiLayer,"btnFightInfo") as SimpleButton;
         if(_loc1_)
         {
            TipsManager.getInstance().replaceTips(_loc1_,"战斗信息");
         }
      }
      
      private function initBackGroundView() : void
      {
         var _loc1_:MovieClip = this.uiLayer.getChildByName("spBackName") as MovieClip;
         this._backGroundView = new BackGroundViewHandler(this._layerBackGround,_loc1_,this._layerPlatform,this._layerBackGroundUp,this._layerPetUp,this._layerPetDown);
         this._backGroundView.setSceneBackGround();
         if(FightData.instance.bs != "")
         {
            this._backGroundView.setBS(FightData.instance.bs);
         }
      }
      
      private function initFaZhenSkill() : void
      {
         var _loc1_:DisplayObject = this.uiLayer.getChildByName("mcFaZhenHolder");
         _loc1_.visible = false;
      }
      
      public function get backGroundView() : BackGroundViewHandler
      {
         return this._backGroundView;
      }
      
      public function setBS(param1:String) : void
      {
         this._backGroundView.setBS(param1);
      }
      
      public function setBackGroundUp(param1:Array) : *
      {
         this._backGroundView.setBackGroundUp(param1);
      }
      
      public function setPetUp(param1:Object) : *
      {
         this._backGroundView.setPetUp(param1);
      }
      
      private function initPetsLocationAndLoad() : void
      {
         var _loc1_:TextField = null;
         var _loc2_:int = 0;
         var _loc3_:Boolean = false;
         var _loc7_:PlayerBattleInfo = null;
         var _loc8_:* = undefined;
         var _loc9_:int = 0;
         var _loc10_:MCPetContainer = null;
         var _loc11_:Point = null;
         var _loc4_:Array = [];
         var _loc5_:Array = [];
         var _loc6_:Array = FightData.instance.playerInfo;
         for each(_loc7_ in _loc6_)
         {
            _loc2_ = int(_loc7_.locaId);
            if(FightData.instance.isMySide(_loc2_))
            {
               _loc3_ = false;
            }
            else
            {
               _loc3_ = true;
            }
            _loc10_ = new MCPetContainer(_loc7_.myPets[0],_loc3_,_loc2_,this.layerEffect);
            this.petMCList[_loc2_] = _loc10_;
            _loc11_ = PositionUtil.getDefaultPosition(_loc2_);
            _loc10_.x = _loc11_.x;
            _loc10_.y = _loc11_.y;
            _loc10_.addEventListener(PetFightEvent.GOT_PET,this.onGotPet);
            _loc10_.startLoad();
            if(FightData.instance.isMySide(_loc2_))
            {
               this.layerPet.addChild(_loc10_);
               _loc4_.push(_loc10_);
            }
            else
            {
               this.layerPet.addChildAt(_loc10_,0);
               _loc5_.push(_loc10_);
            }
         }
         _loc5_.sortOn(["y"],[Array.NUMERIC]);
         _loc4_.sortOn(["y"],[Array.NUMERIC]);
         _loc8_ = _loc5_.concat(_loc4_);
         _loc9_ = 0;
         while(_loc9_ < _loc8_.length)
         {
            this.layerPet.addChild(_loc8_[_loc9_]);
            _loc9_++;
         }
         _loc8_ = [];
         this.playGQSkinInbetweeningMv();
      }
      
      private function playGQSkinInbetweeningMv() : void
      {
         var _loc5_:int = 0;
         var _loc6_:PetSkinInfo = null;
         var _loc1_:Array = [];
         var _loc2_:IPetSkinDataService = ServicePool.instance.getService(IPetSkinDataService);
         var _loc3_:int = 0;
         while(_loc3_ < FightData.instance.teammates.length)
         {
            _loc5_ = int(PetAssetsMap.getPetFlaId(FightData.instance.teammates[_loc3_].myPets[0].viewId));
            _loc6_ = _loc2_.getPetSkinInfoBySkinId(_loc5_);
            if((Boolean(_loc6_)) && Boolean(_loc6_.hasInbetweening))
            {
               _loc1_.push({
                  "fladId":_loc5_,
                  "face":0
               });
            }
            _loc3_++;
         }
         var _loc4_:int = 0;
         while(_loc4_ < FightData.instance.opponents.length)
         {
            _loc5_ = int(PetAssetsMap.getPetFlaId(FightData.instance.opponents[_loc4_].myPets[0].viewId));
            _loc6_ = _loc2_.getPetSkinInfoBySkinId(_loc5_);
            if((Boolean(_loc6_)) && Boolean(_loc6_.hasInbetweening))
            {
               _loc1_.push({
                  "fladId":_loc5_,
                  "face":1
               });
            }
            _loc4_++;
         }
         this.showEnterFightInbetweeningMv(_loc1_);
      }
      
      private function showEnterFightInbetweeningMv(param1:Array) : void
      {
         var skinIdAndFaceObj:Object = null;
         var sp:Sprite = null;
         var playGQSkinIdAndFaceArr:Array = param1;
         var petSkinDataSvr:IPetSkinDataService = ServicePool.instance.getService(IPetSkinDataService);
         if(playGQSkinIdAndFaceArr.length > 0)
         {
            skinIdAndFaceObj = playGQSkinIdAndFaceArr.shift();
            sp = petSkinDataSvr.getAndShowEnterFightInbetweening(skinIdAndFaceObj.fladId,skinIdAndFaceObj.face,function():void
            {
               showEnterFightInbetweeningMv(playGQSkinIdAndFaceArr);
            });
            this._layerTop.addChild(sp);
         }
      }
      
      private function addAutoPanel() : void
      {
         var _loc1_:PlayerBattleInfo = null;
         this.autoTxt = new AutoPanel() as MovieClip;
         if(FightController.instance.isAuto && FightController.instance.isCatchablePet)
         {
            LayerManager.getFightingTop().addChild(this.autoTxt);
            this.autoTxt.y = 255.4;
            this.cancelBtn = this.autoTxt.getChildByName("btn") as SimpleButton;
            this.cancelBtn.addEventListener(MouseEvent.CLICK,this.onClickCancelAuto);
         }
      }
      
      private function onAdded(param1:Event) : void
      {
         var _loc3_:ILiveService = null;
         this.removeEventListener(Event.ADDED,this.onAdded);
         var _loc2_:Sprite = LayerManager.getFightingTop();
         if(FightController.instance.isPetFightSpaceLive)
         {
            _loc3_ = ServicePool.instance.getService(ILiveService);
            this.msgPanel = _loc3_.getLiveParams().commonTitleView;
         }
         else
         {
            this.msgPanel = this.iFightTalk.getTalkPanel();
         }
         this.msgPanel.x = TextField(this.uiLayer.msgHolder).x;
         this.msgPanel.y = TextField(this.uiLayer.msgHolder).y;
         _loc2_.addChild(this.msgPanel);
         this.addAutoPanel();
      }
      
      private function tryAddReplayUI() : void
      {
         if(FightController.instance.isReplay)
         {
            if(FightController.instance.isLive)
            {
               if(Boolean(this._liveUI) && Boolean(this._liveUI.parent))
               {
                  return;
               }
               this._liveUI = new FightLiveUI();
               this._liveUI.init(FightController.instance.replayTurnCount,this);
               this._layerTop.addChild(this._liveUI);
            }
            else if(FightController.instance.isPetFightSpaceLive)
            {
               if(Boolean(this._petFightSpaceliveUI) && Boolean(this._petFightSpaceliveUI.parent))
               {
                  return;
               }
               this._petFightSpaceliveUI = new PetFightSpaceLiveUI();
               this._petFightSpaceliveUI.init(this);
               this._layerTop.addChild(this._petFightSpaceliveUI);
            }
            else
            {
               if(Boolean(this._replayUI) && Boolean(this._replayUI.parent))
               {
                  return;
               }
               this._replayUI = new ReplayUI();
               this._replayUI.init(FightController.instance.replayTurnCount,this);
               this._layerTop.addChild(this._replayUI);
            }
         }
      }
      
      public function updatePetInfoMC(param1:PlayerBattleInfo, param2:Array = null) : void
      {
         var _loc6_:PetBriefInfo = null;
         if(param1 == null || param1.myPets[0] == null)
         {
            return;
         }
         var _loc3_:int = int(param1.locaId);
         var _loc4_:Point = PositionUtil.getDefaultPosition(_loc3_);
         var _loc5_:PetInfoMCBase = this.smallPetInfoMCList[_loc3_];
         if(param1.myPets[0].curHp > 0 || StatusUtil.getYirenShieldByPbi(param1.myPets[0])[0] > 0)
         {
            if(_loc5_ == null)
            {
               _loc6_ = param1.myPets[0];
               if(this.isShenLingShouHu(_loc6_.raceId))
               {
                  _loc5_ = this.smallPetInfoMCList[_loc3_] = FightMcPool.instance.getRes(ShenLingPetInfoMC,true);
               }
               else
               {
                  _loc5_ = this.smallPetInfoMCList[_loc3_] = FightMcPool.instance.getRes(SmallPetInfoMC,true);
               }
            }
            else
            {
               _loc5_.visible = true;
            }
            _loc5_.x = _loc4_.x - 28;
            _loc5_.y = Math.min(_loc4_.y + 10,950);
            this._layerPet.addChild(_loc5_);
         }
         if(_loc5_)
         {
            _loc5_.setPet(param1);
            this.updateStatusIcon(param1,param2);
         }
      }
      
      private function isShenLingShouHu(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:PMData = _loc2_.getOperationPM(param1).pmData;
         return XinghuiPetType.isShenLingGuard(_loc3_.getXinghuiType());
      }
      
      private function updatehunDunSumPetInfoMC(param1:PlayerBattleInfo) : void
      {
         if(param1 == null)
         {
            return;
         }
         var _loc2_:int = int(param1.locaId);
         var _loc3_:Point = PositionUtil.getDefaultPosition(_loc2_);
         var _loc4_:HunDunSumPetInfoMC = this.hunDunSumPetInfoMCList[_loc2_];
         if(_loc4_ == null)
         {
            _loc4_ = this.hunDunSumPetInfoMCList[_loc2_] = FightMcPool.instance.getRes(HunDunSumPetInfoMC,true);
            _loc4_.x = _loc3_.x - 28;
            _loc4_.y = _loc3_.y - 220;
         }
         if(_loc4_.setPet(param1))
         {
            this._layerPet.addChild(_loc4_);
         }
         else
         {
            DisplayUtil.stopAndRemove(_loc4_);
         }
      }
      
      private function updateCommonBuffPetInfoMC(param1:PlayerBattleInfo) : void
      {
         var _loc5_:Point = null;
         if(param1 == null)
         {
            return;
         }
         var _loc2_:int = int(param1.locaId);
         var _loc3_:Point = PositionUtil.getDefaultPosition(_loc2_);
         var _loc4_:CommonBuff1253PetInfoMC = this._commonBuff1253PetInfoMCList[_loc2_];
         if(_loc4_ == null)
         {
            _loc4_ = this._commonBuff1253PetInfoMCList[_loc2_] = FightMcPool.instance.getRes(CommonBuff1253PetInfoMC,true);
            _loc4_.x = _loc3_.x - 28;
            _loc4_.y = _loc3_.y - 240;
            _loc5_ = _loc4_.localToGlobal(new Point(_loc4_.x,_loc4_.y));
            if(_loc5_.y < 0)
            {
               _loc4_.y -= _loc5_.y;
            }
         }
         if(_loc4_.setPet(param1))
         {
            this._layerPet.addChild(_loc4_);
         }
         else
         {
            DisplayUtil.stopAndRemove(_loc4_);
         }
      }
      
      private function updateXingZhiCaiPetInfoMc(param1:PlayerBattleInfo) : void
      {
         if(param1 == null)
         {
            return;
         }
         var _loc2_:int = int(param1.locaId);
         var _loc3_:Point = PositionUtil.getDefaultPosition(_loc2_);
         var _loc4_:XingZhiCaiFight25PetInfoMc = this._xingZhiCaiPetInfoMcList[_loc2_];
         if(_loc4_ == null)
         {
            _loc4_ = this._xingZhiCaiPetInfoMcList[_loc2_] = FightMcPool.instance.getRes(XingZhiCaiFight25PetInfoMc,true);
            _loc4_.x = _loc3_.x;
            _loc4_.y = _loc3_.y - 190;
         }
         if(param1.myPets[0].curHp <= 0)
         {
            DisplayUtil.stopAndRemove(_loc4_);
         }
         else if(_loc4_.setPet(param1))
         {
            this._layerPet.addChild(_loc4_);
         }
         else
         {
            DisplayUtil.stopAndRemove(_loc4_);
         }
      }
      
      public function onGotPet(param1:PetFightEvent) : void
      {
         param1.currentTarget.removeEventListener(PetFightEvent.GOT_PET,this.onGotPet);
         ++this.petLoadeNum;
         this.showPetInfo(param1.params.locaId);
         if(this.petLoadeNum != FightData.instance.fightNum || !this.canStart)
         {
            return;
         }
         this.canStart = false;
         if(this.whoSwitch == 0)
         {
            this.initPet();
         }
         else if(this.whoSwitch == 1)
         {
            FightController.instance.startHandle();
         }
         FightController.instance.playSound("x7005");
      }
      
      private function checkBossMc() : void
      {
         var mcArray:Array = null;
         var player1:PlayerBattleInfo = null;
         var rId:int = 0;
         var raceId:int = 0;
         var mc:ResourceObject = null;
         mcArray = [];
         var raceIds:Array = [];
         for each(player1 in FightData.instance.playerInfo)
         {
            raceId = int(player1.myPets[0].raceId);
            if(raceIds.indexOf(raceId) == -1)
            {
               raceIds.push(raceId);
            }
         }
         for each(rId in raceIds)
         {
            mc = BossMovieConfig.getBossMcRes(rId);
            if(mc != null)
            {
               mcArray.push(mc);
            }
         }
         if(mcArray.length > 0)
         {
            PMAutoTalk.checkTalk(this,function():void
            {
               BossMovieHelper.instance.playMCs(mcArray,initPetsLocationAndLoad);
            });
         }
         else
         {
            PMAutoTalk.checkTalk(this,function():void
            {
               initPetsLocationAndLoad();
            });
         }
      }
      
      private function initPet() : void
      {
         this.setFightClicked();
         if(FightController.instance.isReplay)
         {
            this.tryAddReplayUI();
            this.enableClick();
            FightController.instance.startHandle();
            return;
         }
         this.timeAndAutoAtt();
         TrainingTower.instance.addTipsPanel();
         if(FightController.isAutoUseSkill)
         {
            AutoFightTimer.instance.registerTimer(this.onCheckauto);
         }
         else
         {
            EnterFrameManager.instance.register(this.onCheckauto);
         }
         if(FightController.instance.whoWon != -1)
         {
            this.stopTimer();
         }
         FightController.instance.startHandle();
      }
      
      public function pause() : void
      {
         FightMovieManager.instance.pause();
         FightEnterFrameManager.instance.pause();
         EnterFrameManager.instance.pause();
         FightTweenMaxManager.instance.pause();
      }
      
      public function resume() : void
      {
         FightMovieManager.instance.play();
         FightEnterFrameManager.instance.resume();
         EnterFrameManager.instance.play();
         FightTweenMaxManager.instance.play();
      }
      
      public function disposeManagers() : void
      {
         FightMovieManager.instance.dispose();
         FightEnterFrameManager.instance.dispose();
         FightTweenMaxManager.instance.dispose();
         FightFrameRateManager.instance.dispose();
      }
      
      private function showPetInfo(param1:int) : void
      {
         var _loc4_:MCPetContainer = null;
         var _loc2_:int = int(FightData.instance.myInfo.operatingPlayer.locaId);
         var _loc3_:PlayerBattleInfo = FightData.instance.getPlayerInfoByLocalId(param1);
         if(param1 == _loc2_ && !FightController.instance.isReplay)
         {
            this.setPetInfoMCVisible(param1,true);
            this._myPetInfoPanel.refreshOperatingPetInfoView();
            this.addEffectContainer(FightData.instance.myInfo.operatingPlayer);
            _loc4_ = this.petMCList[param1];
            _loc4_.showMyMark();
            this.updatePetInfoMC(_loc3_);
         }
         else if(FightData.instance.myInfo.isMyControlLocalId(param1) && !FightController.instance.isReplay)
         {
            this._myPetInfoPanel.refreshNoOperatingPetInfoView();
            this.updatePetInfoMC(_loc3_);
            this.setPetInfoMCVisible(param1,true);
         }
         else
         {
            this.updatePetInfoMC(_loc3_);
            this.setPetInfoMCVisible(param1,true);
         }
      }
      
      private function onClickCancelAuto(param1:MouseEvent) : void
      {
         FightController.instance.isAuto = false;
         FightController.isAutoUseSkill = false;
         PetClient.instance.changeAutoUseSkillState(false);
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.END_AUTO_FIGHT,{}));
         DisplayUtil.stopAndRemove(this.autoTxt);
         var _loc2_:IPetFight = ServicePool.instance.getService(IPetFight);
         GatherClient.instance.switchItemConsumState(_loc2_.autoFightItemId,false);
      }
      
      public function setFightClicked(param1:Boolean = false) : void
      {
         if(this.msgPanel)
         {
            this.msgPanel.visible = true;
         }
         this.openSkillPanel(param1);
         if(this.getIsInNoOperItemBuff())
         {
            MovieClip(this.uiLayer.mcItem).gotoAndStop(2);
         }
         else
         {
            MovieClip(this.uiLayer.mcItem).gotoAndStop(1);
         }
         MovieClip(this.uiLayer.mcRelax).gotoAndStop(1);
         this.setMcPetsFrame(1);
         this.setMcEscapeFrame(1);
         this.setUIPanelClickable(UIPanelType.SKILL,true);
         this.autoSetCatchMc();
         this.autoSetEscape();
         this.tryCancelUseItem();
      }
      
      private function autoSetEscape() : void
      {
         if(this.team != null && this.team.leader != SocketClient.instance.myUserName || !FightController.instance.canEscape)
         {
            this.setMcEscapeFrame(2);
         }
      }
      
      private function openSkillPanel(param1:Boolean) : void
      {
         this.openUIPanel(UIPanelType.SKILL,param1);
         this.updateStriction();
      }
      
      public function updateStriction() : void
      {
         if(this.attributeHolder != null)
         {
            DisplayUtil.clearChildren(this.attributeHolder);
         }
         else
         {
            this.attributeHolder = new Sprite();
         }
         this.uiLayer.addChild(this.attributeHolder);
         var _loc1_:PetBriefInfo = FightData.instance.myInfo.operatingPlayer.myPets[0];
         HolySkillController.addHolySkillIcon(_loc1_,this.attributeHolder);
         BargainSkillController.addBargainSkillIcon(_loc1_,this.attributeHolder);
      }
      
      private function onClickItem(param1:MouseEvent) : void
      {
         if(!this.checkControlTargetClickable(param1))
         {
            if((param1.currentTarget as MovieClip).currentFrame == 4)
            {
               this.setFightClicked();
            }
            return;
         }
         this.setItemClicked();
      }
      
      private function onClickFightInfo(param1:MouseEvent) : void
      {
         FIP_Controller.instance.showMainPl();
      }
      
      private function onClickRelax(param1:MouseEvent) : void
      {
         if(!this.checkControlTargetClickable(param1))
         {
            return;
         }
         var _loc2_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         FightController.instance.useSkill(RelaxSkillId,_loc2_.slotId,_loc2_.slotId,false);
      }
      
      private function checkControlTargetClickable(param1:MouseEvent) : Boolean
      {
         if((param1.currentTarget as MovieClip).name == "mcEscape")
         {
            return (param1.currentTarget as MovieClip).currentFrame == 1 || (param1.currentTarget as MovieClip).currentFrame == 3;
         }
         return (param1.currentTarget as MovieClip).currentFrame == 1;
      }
      
      private function setItemClicked() : void
      {
         this.msgPanel.visible = true;
         this.tryCancelUseSkill();
         this.openItemPanel();
         MovieClip(this.uiLayer.mcItem).gotoAndStop(4);
         this.setMcPetsFrame(1);
         this.setMcEscapeFrame(1);
         this.autoSetCatchMc();
      }
      
      private function openItemPanel() : void
      {
         this.openUIPanel(UIPanelType.ITEM);
      }
      
      private function onClickCatch(param1:MouseEvent) : void
      {
         var _loc4_:Object = null;
         if(!this.checkControlTargetClickable(param1))
         {
            if((param1.currentTarget as MovieClip).currentFrame == 4)
            {
               this.setFightClicked();
            }
            return;
         }
         var _loc2_:Boolean = false;
         var _loc3_:Array = FightItemData.instance.myCatchItems;
         for each(_loc4_ in _loc3_)
         {
            if(_loc4_.qt > 0)
            {
               _loc2_ = true;
               break;
            }
         }
         if(_loc2_)
         {
            this.setCatchClicked();
         }
         else
         {
            NewDialog.showFailMessage("你没有亚比球哦，快去流星购物街的道具店购买吧");
         }
      }
      
      private function setCatchClicked() : void
      {
         this.msgPanel.visible = true;
         this.openCatchPanel();
         MovieClip(this.uiLayer.mcCatch).gotoAndStop(4);
         if(this.getIsInNoOperItemBuff())
         {
            MovieClip(this.uiLayer.mcItem).gotoAndStop(2);
         }
         else
         {
            MovieClip(this.uiLayer.mcItem).gotoAndStop(1);
         }
         MovieClip(this.uiLayer.mcRelax).gotoAndStop(1);
         this.setMcPetsFrame(1);
         this.setMcEscapeFrame(1);
         this.cancelSelect();
      }
      
      public function openUIPanel(param1:int, param2:Boolean = false, param3:Boolean = true) : void
      {
         var _loc5_:UIPanelBase = null;
         var _loc6_:Sprite = null;
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FIGHT_UI_PANEL_OPEN_TYPE,{"type":param1}));
         var _loc4_:int = 0;
         while(_loc4_ < UI_PANEL_NUM)
         {
            _loc5_ = this._uiPanelList[_loc4_];
            if(_loc4_ == param1)
            {
               if(_loc5_ == null)
               {
                  this._uiPanelList[_loc4_] = _loc5_ = UIPanelFactory.getUIPanel(param1);
               }
               else
               {
                  _loc5_.update();
               }
               _loc5_.setClickable(true);
               if(!param3)
               {
                  _loc5_.setNoClickIntoHandle();
               }
               _loc6_ = this.uiLayer.panelHolder;
               _loc6_.addChild(_loc5_);
               if(param2)
               {
                  this.showOpenUIEffect(_loc5_);
               }
            }
            else if(Boolean(_loc5_) && Boolean(_loc5_.parent))
            {
               _loc5_.parent.removeChild(_loc5_);
            }
            _loc4_++;
         }
      }
      
      private function showOpenUIEffect(param1:UIPanelBase) : void
      {
         var tweenVars:TweenLiteVars;
         var tweenMax:TweenMax = null;
         var uiPanel:UIPanelBase = param1;
         uiPanel.y = -uiPanel.height;
         tweenVars = new TweenLiteVars();
         tweenVars.prop("y",0);
         tweenVars.useFrames(true);
         tweenVars.onComplete(function():void
         {
            FightTweenMaxManager.instance.removeTweenMax(tweenMax);
         });
         tweenMax = new TweenMax(uiPanel,12,tweenVars);
         FightTweenMaxManager.instance.addTweenMax(tweenMax);
      }
      
      private function openCatchPanel() : void
      {
         this.openUIPanel(UIPanelType.CATCH);
      }
      
      private function onClickPets(param1:MouseEvent) : void
      {
         var _loc3_:PetBriefInfo = null;
         if(!this.checkControlTargetClickable(param1))
         {
            if((param1.currentTarget as MovieClip).currentFrame == 4)
            {
               this.setFightClicked();
            }
            return;
         }
         var _loc2_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         if(_loc2_ && _loc2_.myPets && _loc2_.myPets.length > 0)
         {
            _loc3_ = _loc2_.myPets[0];
            if(StatusUtil.getIsInLiangziXinglianState(_loc3_) || StatusUtil.getIsInHunDunJueDouState(_loc3_))
            {
               NotifyQueue.getInstance().add("不能换宠！");
               return;
            }
         }
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent(PetFightEvent.CLICK_RIGHTTOP_SWITCH_PET,{}));
         this.setPetsClicked(true);
      }
      
      public function setPetsClicked(param1:Boolean = false) : void
      {
         this.msgPanel.visible = false;
         this.openPetsPanel(param1);
         this.setMcPetsFrame(4);
         if(this.getIsInNoOperItemBuff())
         {
            MovieClip(this.uiLayer.mcItem).gotoAndStop(2);
         }
         else
         {
            MovieClip(this.uiLayer.mcItem).gotoAndStop(1);
         }
         MovieClip(this.uiLayer.mcRelax).gotoAndStop(1);
         this.setMcEscapeFrame(1);
         this.autoSetCatchMc();
         this.cancelSelect();
      }
      
      private function autoSetCatchMc() : void
      {
         var _loc1_:MovieClip = this.uiLayer.getChildByName("mcCatch") as MovieClip;
         if(FightController.instance.canCatch)
         {
            _loc1_.gotoAndStop(1);
         }
         else
         {
            _loc1_.gotoAndStop(2);
         }
      }
      
      private function openPetsPanel(param1:Boolean) : void
      {
         this.openUIPanel(UIPanelType.PET,false,param1);
      }
      
      public function disableOperateBtnClick() : void
      {
         var _loc2_:PetBriefInfo = null;
         this.setMcPetsFrame(2);
         MovieClip(this.uiLayer.mcItem).gotoAndStop(2);
         MovieClip(this.uiLayer.mcRelax).gotoAndStop(2);
         MovieClip(this.uiLayer.mcCatch).gotoAndStop(2);
         this.setMcEscapeFrame(2);
         var _loc1_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         if(_loc1_ && _loc1_.myPets && _loc1_.myPets.length > 0)
         {
            _loc2_ = _loc1_.myPets[0];
            if(StatusUtil.getIsInWumangXingjiState(_loc2_))
            {
               this.setMcEscapeFrame(1);
            }
         }
      }
      
      private function removeUIPanel(param1:DisplayObject) : void
      {
         if(param1.parent)
         {
            param1.parent.removeChild(param1);
         }
      }
      
      private function setUIPanelsClickable(param1:Boolean) : void
      {
         var _loc2_:UIPanelBase = null;
         for each(_loc2_ in this._uiPanelList)
         {
            _loc2_.setClickable(param1);
         }
         if(this._faZhenSkillBtn)
         {
            this._faZhenSkillBtn.setClickable(param1);
         }
      }
      
      private function setUIPanelClickable(param1:int, param2:Boolean) : void
      {
         if(this._uiPanelList[param1])
         {
            (this._uiPanelList[param1] as UIPanelBase).setClickable(param2);
         }
      }
      
      public function enableClick() : void
      {
         this.mouseChildren = true;
         this.mouseEnabled = true;
         if(this.getIsInNoOperItemBuff())
         {
            MovieClip(this.uiLayer.mcItem).gotoAndStop(2);
         }
         else
         {
            MovieClip(this.uiLayer.mcItem).gotoAndStop(1);
         }
         MovieClip(this.uiLayer.mcRelax).gotoAndStop(1);
         this.setMcPetsFrame(1);
         this.setMcEscapeFrame(1);
         this.addEscapeResponder();
         this.autoSetCatchMc();
         this.autoSetEscape();
         this.setUIPanelsClickable(true);
         DocPetFight.noteInputReady();
      }
      
      public function disableClick(param1:Boolean = false) : void
      {
         var _loc3_:PetBriefInfo = null;
         if(!param1)
         {
            this.mouseEnabled = false;
         }
         this.catchBtnIcon.visible = false;
         if(this.catchBtnIcon.y > 0)
         {
            this.catchBtnIcon.y -= 1000;
         }
         this.hideAllCanCatchMovie();
         MovieClip(this.uiLayer.mcItem).gotoAndStop(2);
         MovieClip(this.uiLayer.mcRelax).gotoAndStop(2);
         MovieClip(this.uiLayer.mcCatch).gotoAndStop(2);
         this.setMcPetsFrame(2);
         var _loc2_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         if(_loc2_ && _loc2_.myPets && _loc2_.myPets.length > 0)
         {
            _loc3_ = _loc2_.myPets[0];
            if(StatusUtil.getIsInWumangXingjiState(_loc3_))
            {
               this.setMcEscapeFrame(1);
            }
         }
         this.setUIPanelsClickable(false);
      }
      
      public function hideAllCanCatchMovie() : void
      {
         var _loc1_:MovieClip = null;
         for each(_loc1_ in this._canCatchMovies)
         {
            _loc1_.stop();
            _loc1_.visible = false;
            if(_loc1_.parent != null)
            {
               _loc1_.parent.removeChild(_loc1_);
            }
         }
      }
      
      public function stopTimer() : void
      {
         this.hideCountMovie();
         this.enableWaitTips();
         EnterFrameManager.instance.remove(this.onCheckauto);
         AutoFightTimer.instance.disposeTimer();
         if(!FightController.instance.isReplay)
         {
            this.disableClick();
         }
      }
      
      private function hideCountMovie() : void
      {
         if(Boolean(this._countMovie) && Boolean(this._countMovie.parent))
         {
            this._countMovie.stop();
            this._countMovie.parent.removeChild(this._countMovie);
         }
      }
      
      private function enableWaitTips() : void
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc1_:int = WaitTips.VS_SELECTING_SKILL;
         for each(_loc2_ in FightData.instance.playerInfo)
         {
            if(FightData.instance.isMySide(_loc2_.locaId) && !FightData.instance.myInfo.isMyControlSlotId(_loc2_.slotId) && !FightData.instance.isSummonedPlayer(_loc2_))
            {
               _loc1_ = WaitTips.TEAMMATE_OPERATING;
               break;
            }
         }
         this.showWaitTips(_loc1_);
      }
      
      private function refreshWangzheRealState(param1:int, param2:PetBriefInfo) : void
      {
         var _loc3_:Point = PositionUtil.getDefaultPosition(param1);
         XingHuiWangzheRealHelper.setStandStatus(this.layerPetUp,param1,param2.hasBird,param2.raceId,_loc3_.x,_loc3_.y);
         XingHuiWangzheRealHelper.setRoundDownState(this.layerPetDown,param1,param2.beBirdList,_loc3_.x,_loc3_.y);
         XingHuiWangzheRealHelper.setRoundUpState(this.layerPetUp,param1,param2.beBirdList,_loc3_.x,_loc3_.y);
      }
      
      private function refreshFaHuanEffextState(param1:int, param2:PetBriefInfo) : void
      {
         var _loc3_:Point = PositionUtil.getDefaultPosition(param1);
         XingHuiFaHuanHelper.setEffectStatus_0(this.layerPetUp,param2,param1,param2.raceId,_loc3_.x,_loc3_.y);
         XingHuiFaHuanHelper.setEffectStatus_1(this.layerPetUp,param2,param1,param2.raceId,_loc3_.x,_loc3_.y);
      }
      
      public function refreshHunDunState(param1:int, param2:PetBriefInfo) : void
      {
         if(param2 == null)
         {
            return;
         }
         var _loc3_:Point = PositionUtil.getDefaultPosition(param1);
         HunDunLiLiangEffectHelper.setStandStatus(this.layerPetUp,param1,param2.status,param2.raceId,_loc3_.x,_loc3_.y);
         ZhanYiEffectHelper.setStandStatus(this.layerPetUp,param1,param2,_loc3_.x,_loc3_.y);
         GQZhanYiEffectHelper.setStandStatus(this.layerPetUp,param1,param2,_loc3_.x,_loc3_.y);
         GQShenXuEffectHelper.setStandStatus(this.layerPetUp,param1,param2,_loc3_.x,_loc3_.y);
         GQXingZhiYuEffectHelper.setStandStatus(this.layerPetUp,param1,param2,_loc3_.x,_loc3_.y);
         GQYingjieMengyueEffectHelper.setStandStatus(this.layerPetUp,param1,param2,_loc3_.x,_loc3_.y);
         GQXingyueTongXingEffectHelper.setStandStatus(this.layerPetUp,param1,param2,_loc3_.x,_loc3_.y);
         DeadZoneExploreEffectHelper.setStandStatus(this.layerPetUp,param1,param2,_loc3_.x,_loc3_.y);
         GQWumangxingjiEffectHelper.setStandStatus(this.layerPetUp,param1,param2,_loc3_.x,_loc3_.y);
         GQFightFlauntStandEffectHelper.setStandStatus(this.layerPetUp,param1,param2,_loc3_.x,_loc3_.y);
         GQMenghuanDiyueEffectHelper.setStandStatus(this.layerPetUp,param1,param2,_loc3_.x,_loc3_.y);
         GQBuxiuLvtuEffecthelper.setStandStatus(this.layerPetUp,this.layerPetDown,param1,param2,_loc3_.x,_loc3_.y);
         GQWanyuZhichaoEffectHelper.setStandStatus(this.layerPetUp,param1,param2,_loc3_.x,_loc3_.y);
      }
      
      public function closeWaitTips() : void
      {
         this.hideWaitTips();
      }
      
      public function refreshInfos(param1:Array) : void
      {
         if(param1.length == 0)
         {
            FightController.instance.startHandle();
            return;
         }
         this.refreshInfo(param1);
      }
      
      public function refreshInfosAfterSkill(param1:Array) : void
      {
         var _loc2_:Object = null;
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:Boolean = false;
         var _loc8_:int = 0;
         var _loc9_:Array = null;
         var _loc10_:String = null;
         var _loc11_:PetBriefInfo = null;
         var _loc12_:Array = null;
         var _loc13_:Array = null;
         for each(_loc2_ in param1)
         {
            _loc3_ = _loc2_.player;
            _loc4_ = int(_loc2_.hpInc);
            _loc5_ = int(_loc2_.srt);
            _loc6_ = int(_loc2_.aor);
            _loc7_ = Boolean(_loc2_.cri);
            _loc8_ = int(_loc3_.locaId);
            _loc9_ = _loc2_.hpIncList;
            _loc10_ = _loc2_.hpType == null ? "" : _loc2_.hpType;
            _loc11_ = _loc3_.myPets[0] as PetBriefInfo;
            _loc12_ = _loc2_.shp;
            _loc13_ = _loc2_.skillWindWordList;
            this.refreshWangzheRealState(_loc8_,_loc11_);
            this.refreshPetInfoOfPlayer(_loc4_,_loc5_,_loc6_,_loc7_,_loc3_,_loc2_.isSkill,_loc9_,_loc2_.skillEffect,_loc2_.isSuperEffect,_loc12_,_loc13_,_loc10_,true);
            this.refreshHunDunState(_loc8_,_loc11_);
            this.refreshFaHuanEffextState(_loc8_,_loc11_);
         }
      }
      
      private function refreshInfo(param1:Array) : void
      {
         var _loc2_:Object = null;
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:Boolean = false;
         var _loc8_:int = 0;
         var _loc9_:Array = null;
         var _loc10_:String = null;
         var _loc11_:Array = null;
         var _loc12_:int = 0;
         var _loc13_:Array = null;
         var _loc14_:PetBriefInfo = null;
         var _loc15_:* = null;
         var _loc16_:int = 0;
         for each(_loc2_ in param1)
         {
            _loc3_ = _loc2_.player;
            _loc4_ = int(_loc2_.hpInc);
            _loc5_ = int(_loc2_.srt);
            _loc6_ = int(_loc2_.aor);
            _loc7_ = Boolean(_loc2_.cri);
            _loc8_ = int(_loc3_.locaId);
            _loc9_ = _loc2_.hpIncList;
            _loc10_ = _loc2_.hpType;
            _loc11_ = _loc2_.shp;
            _loc12_ = _loc2_.hasOwnProperty("count") ? int(_loc2_.count) : 0;
            _loc13_ = _loc2_.skillWindWordList;
            if(_loc2_.isItem)
            {
               _loc16_ = int(_loc2_.itemId);
               this.showMcUseItem(_loc3_.locaId,_loc16_,_loc12_);
            }
            _loc14_ = _loc3_.myPets[0] as PetBriefInfo;
            this.refreshWangzheRealState(_loc8_,_loc14_);
            if(_loc14_.status2 == null || _loc14_.status2 == "")
            {
               _loc15_ = "";
            }
            else
            {
               _loc15_ = _loc14_.status2 + ",";
            }
            this.checkAttributeState(_loc15_,_loc3_.locaId,GetStateMovieUtil.roundEndEffectArr);
            this.refreshPetInfoOfPlayer(_loc4_,_loc5_,_loc6_,_loc7_,_loc3_,_loc2_.isSkill,_loc9_,_loc2_.skillEffect,_loc2_.isSuperEffect,_loc11_,_loc13_,_loc10_);
            this.checkReviveMovie(_loc15_,_loc3_);
            this.refreshHunDunState(_loc8_,_loc14_);
            this.refreshFaHuanEffextState(_loc8_,_loc14_);
         }
      }
      
      public function showSkillEffectMovie(param1:Array) : void
      {
         var _loc2_:Object = null;
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:PetBriefInfo = null;
         for each(_loc2_ in param1)
         {
            _loc3_ = _loc2_.player;
            _loc4_ = _loc3_.myPets[0] as PetBriefInfo;
            if(_loc2_.ifShowStateMovie)
            {
               this.checkAttributeState(_loc4_.status2,_loc3_.locaId,GetStateMovieUtil.skillEffectArr);
               this.checkReviveMovie(_loc4_.status2,_loc3_);
            }
         }
      }
      
      private function checkReviveMovie(param1:String, param2:PlayerBattleInfo) : void
      {
         var thePet:PetBriefInfo;
         var mc:MovieClip = null;
         var status:String = param1;
         var player:PlayerBattleInfo = param2;
         if(status == null || status.indexOf("44") == -1)
         {
            return;
         }
         thePet = player.myPets[0] as PetBriefInfo;
         mc = BossMovieConfig.checkBossMc(thePet.raceId,BossMovieConfig.REVIVE);
         if(mc == null)
         {
            return;
         }
         FightMovieManager.instance.addMovie(mc);
         mc.addFrameScript(mc.totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(mc);
            DisplayUtil.stopAndRemove(mc);
         });
         this.addChild(mc);
         mc.gotoAndPlay(1);
      }
      
      private function checkAttributeState(param1:String, param2:int, param3:Array) : void
      {
         var _loc10_:String = null;
         if(param1 == null || param1 == "" || param1 == "null")
         {
            return;
         }
         var _loc4_:Array = param1.split(",");
         var _loc5_:Array = GetStateMovieUtil.attributeUpEffectArr;
         var _loc6_:Array = GetStateMovieUtil.attributeDownEffectArr;
         var _loc7_:Array = [];
         var _loc8_:int = 0;
         var _loc9_:int = int(_loc4_.length - 1);
         while(_loc9_ >= 0)
         {
            if(_loc5_.indexOf(_loc4_[_loc9_]) != -1)
            {
               _loc8_ = _loc8_ < 2 ? 2 : _loc8_;
               _loc4_.splice(_loc9_,1);
            }
            else if(_loc6_.indexOf(_loc4_[_loc9_]) != -1)
            {
               _loc8_ = _loc8_ < 1 ? 1 : _loc8_;
               _loc4_.splice(_loc9_,1);
            }
            else if(param3.indexOf(_loc4_[_loc9_]) == -1)
            {
               _loc4_.splice(_loc9_,1);
            }
            else if(GetStateMovieUtil.checkIsSummonerSkillState(_loc4_[_loc9_]))
            {
               _loc10_ = _loc4_[_loc9_] + "_" + param2;
               if(_loc7_.indexOf(_loc10_) != -1)
               {
                  _loc4_.splice(_loc9_,1);
               }
               else
               {
                  _loc7_.push(_loc10_);
               }
            }
            _loc9_--;
         }
         if(_loc8_ == 1)
         {
            _loc4_.push("能力下降");
         }
         else if(_loc8_ == 2)
         {
            _loc4_.push("能力上升");
         }
         this.showMovieOneByOne(_loc4_,param2);
      }
      
      private function showMovieOneByOne(param1:Array, param2:int) : void
      {
         var state:String;
         var scaleRate:Number;
         var petPosition:Point = null;
         var isFullScreenSkill:Boolean = false;
         var isSummonerSkillState:Boolean = false;
         var isNengLiMv:Boolean = false;
         var movieArr:Array = param1;
         var locaId:int = param2;
         if(movieArr == null || movieArr.length == 0 || FightData.instance.isLowQuality)
         {
            return;
         }
         petPosition = PositionUtil.getDefaultPosition(locaId);
         state = movieArr.shift();
         isFullScreenSkill = GetStateMovieUtil.checkIsFullScreenSkill(state);
         scaleRate = isFullScreenSkill ? 1 : FightData.instance.teamScale;
         isSummonerSkillState = GetStateMovieUtil.checkIsSummonerSkillState(state);
         CommonEventDispatcher.instance.dispatchEvent(new PetFightStateEvent(PetFightStateEvent.STATUS_EFFECT,{
            "state":state,
            "locaId":locaId
         }));
         isNengLiMv = GetStateMovieUtil.isNengLiChangeMv(state);
         GetStateMovieUtil.getStateMovie(locaId,state,scaleRate,function(param1:MovieClip):void
         {
            var mcPet:MCPetContainer = null;
            var mc:MovieClip = param1;
            FightMovieManager.instance.addMovie(mc);
            if(isNengLiMv)
            {
               CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("mouse_over_mcpetcontainer",{"locaId":locaId}));
            }
            mc.addFrameScript(mc.totalFrames - 1,function():void
            {
               FightMovieManager.instance.removeMovie(mc);
               DisplayUtil.stopAndRemove(mc);
               if(isNengLiMv)
               {
                  CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("mouse_out_mcpetcontainer",{"locaId":locaId}));
               }
               showMovieOneByOne(movieArr,locaId);
            });
            if(!isFullScreenSkill)
            {
               mcPet = petMCList[locaId] as MCPetContainer;
               if(mcPet == null)
               {
                  mc.x = petPosition.x;
                  mc.y = petPosition.y;
               }
               else
               {
                  mc.x = mcPet.x;
                  mc.y = mcPet.y;
               }
            }
            if(isSummonerSkillState)
            {
               _layerTop.addChild(mc);
            }
            else
            {
               _layerPet.addChild(mc);
            }
            mc.gotoAndPlay(1);
         });
      }
      
      public function clearMyPetInfo() : void
      {
         if(this._myPetInfoPanel)
         {
            this._myPetInfoPanel.clearStatusSmallIcon();
            DisplayUtil.stopAndRemove(this.myBEPanel);
         }
      }
      
      private function addMyBEPanel() : void
      {
         var _loc1_:PlayerBattleInfo = null;
         if(!FightController.isShowBattleEffectiveness)
         {
            return;
         }
         if(this.myBEPanel == null)
         {
            this.myBEPanel = new BEPanel() as Sprite;
         }
         _loc1_ = FightData.instance.myInfo.operatingPlayer;
         var _loc2_:int = int(_loc1_.locaId);
         var _loc3_:Point = PositionUtil.getDefaultPosition(_loc2_);
         this.myBEPanel.x = _loc3_.x - 110;
         this.myBEPanel.y = _loc3_.y + 10;
         this.layerPet.addChildAt(this.myBEPanel,0);
         var _loc4_:TextField = this.myBEPanel.getChildByName("txtBE") as TextField;
         _loc4_.mouseEnabled = false;
         var _loc5_:IPetBattleEffDataService = ServicePool.instance.getService(IPetBattleEffDataService);
         var _loc6_:int = int(_loc5_.getPetBattleEffectiveness(_loc1_.myPets[0]));
         _loc4_.text = _loc6_.toString();
      }
      
      private function getIsInNoOperItemBuff() : Boolean
      {
         var _loc4_:String = null;
         var _loc1_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         if(!_loc1_.myPets[0])
         {
            return false;
         }
         var _loc2_:PetBriefInfo = _loc1_.myPets[0];
         var _loc3_:Array = _loc2_.status.split(",");
         for each(_loc4_ in _loc3_)
         {
            if(_loc4_.indexOf("cbf_1199") != -1 || _loc4_.indexOf("cbf_1243") != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      private function showMyStatusSmallIcon(param1:String, param2:PlayerBattleInfo) : void
      {
         this._myPetInfoPanel.refreshStatusIconView(param1,param2);
         this.addMyBEPanel();
      }
      
      private function updateStatusIcon(param1:PlayerBattleInfo, param2:Array = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         var _loc3_:PetBriefInfo = param1.myPets[0];
         var _loc4_:String = _loc3_.status;
         var _loc5_:int = int(param1.locaId);
         var _loc6_:Array = StatusUtil.parseStatusStr(_loc4_);
         this.addEffectContainer(param1,param2);
         var _loc7_:PetInfoMCBase = this.smallPetInfoMCList[_loc5_] as PetInfoMCBase;
         if(_loc7_ != null)
         {
            _loc7_.setStatus(_loc6_,param1);
         }
         if(FightData.instance.myInfo.operatingPlayer.locaId == _loc5_)
         {
            this.showMyStatusSmallIcon(_loc4_,param1);
         }
      }
      
      public function addEffectContainer(param1:PlayerBattleInfo, param2:Array = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         var _loc3_:PetBriefInfo = param1.myPets[0];
         var _loc4_:String = _loc3_.status;
         var _loc5_:int = int(param1.locaId);
         var _loc6_:Point = PositionUtil.getDefaultPosition(_loc5_);
         var _loc7_:StatusEffectContainer = this.statusEffectContainerList[_loc5_];
         if(_loc7_ == null)
         {
            this.statusEffectContainerList[_loc5_] = _loc7_ = FightMcPool.instance.getRes(StatusEffectContainer,true);
            _loc7_.x = _loc6_.x;
            _loc7_.y = _loc6_.y;
         }
         var _loc8_:Array = StatusUtil.parseStatusStr(_loc4_);
         _loc7_.update(_loc8_);
         if(_loc7_.isAtBack())
         {
            this._layerPet.addChildAt(_loc7_,0);
         }
         else
         {
            this._layerPet.addChild(_loc7_);
         }
         var _loc9_:SkillWindWordContainer = this._skillWindWordContainerList[_loc5_];
         if(_loc9_ == null)
         {
            this._skillWindWordContainerList[_loc5_] = _loc9_ = FightMcPool.instance.getRes(SkillWindWordContainer,true);
            _loc9_.x = _loc6_.x;
            _loc9_.y = _loc6_.y;
         }
         _loc9_.update(param2);
         this._layerPet.addChild(_loc9_);
      }
      
      public function setPlayerOperating(param1:int) : void
      {
         var _loc6_:PlayerBattleInfo = null;
         var _loc7_:PetBriefInfo = null;
         var _loc8_:MCPetContainer = null;
         FightData.instance.myInfo.setPlayerOperating(param1);
         this._myPetInfoPanel.refreshOperatingPetInfoView();
         this.addEffectContainer(FightData.instance.myInfo.operatingPlayer);
         this._myPetInfoPanel.refreshNoOperatingPetInfoView();
         var _loc2_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         var _loc3_:PetBriefInfo = _loc2_.myPets[0];
         _loc3_.getXingHuiChuangShuoParser().isUseSkillThisTurn = false;
         var _loc4_:MCPetContainer = this.petMCList[_loc2_.locaId];
         _loc4_.showMyMark();
         var _loc5_:Array = FightData.instance.myInfo.getNoOperatingPlayers();
         for each(_loc6_ in _loc5_)
         {
            _loc7_ = _loc6_.myPets[0];
            if((Boolean(_loc7_)) && _loc7_.curHp > 0)
            {
               this.setPetInfoMCVisible(_loc6_.locaId,true);
            }
            _loc8_ = this.petMCList[_loc6_.locaId];
            _loc8_.hideMyMark();
         }
         this.cancelSelect();
         this.setFightClicked(false);
      }
      
      public function setPetInfoMCVisible(param1:int, param2:Boolean) : void
      {
         var _loc3_:PetInfoMCBase = this.smallPetInfoMCList[param1];
         var _loc4_:PlayerBattleInfo = FightData.instance.getPlayerInfoByLocalId(param1);
         if(param2)
         {
            if(_loc3_)
            {
               _loc3_.visible = true;
               this._layerPet.addChild(_loc3_);
            }
            else if(_loc4_ && _loc4_.myPets && Boolean(_loc4_.myPets[0]) && _loc4_.lingshouRealitySlotId == -1)
            {
               this.updatePetInfoMC(_loc4_);
            }
         }
         else if(_loc3_)
         {
            _loc3_.visible = false;
         }
      }
      
      public function setPetVisible(param1:int, param2:Boolean) : void
      {
         if(this.statusEffectContainerList[param1])
         {
            this.statusEffectContainerList[param1].visible = param2;
         }
         var _loc3_:MCPetContainer = this.petMCList[param1];
         if(_loc3_)
         {
            _loc3_.visible = param2;
         }
      }
      
      private function showMcUseItem(param1:int, param2:int, param3:int = 0) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function refreshPetInfoOfPlayer(param1:int, param2:int, param3:int, param4:Boolean, param5:PlayerBattleInfo, param6:Boolean, param7:Array, param8:int, param9:Boolean, param10:Array, param11:Array = null, param12:String = "", param13:Boolean = false) : void
      {
         var _loc14_:Point = PositionUtil.getDefaultPosition(param5.locaId);
         new SkillResultHandler(this._layerEffect,param1,param2,param4,_loc14_,param6,param7,param8,param9,param10,param12,param13).start();
         this.updatehunDunSumPetInfoMC(param5);
         this.updateCommonBuffPetInfoMC(param5);
         this.updateXingZhiCaiPetInfoMc(param5);
         if(param5.PMMasterId == FightData.instance.myInfo.PMMasterId && !FightController.instance.isReplay)
         {
            if(param5.locaId == FightData.instance.myInfo.operatingPlayer.locaId)
            {
               this._myPetInfoPanel.refreshOperatingPetInfoView();
               this.updatePetInfoMC(param5,param11);
               this.addEffectContainer(FightData.instance.myInfo.operatingPlayer,param11);
            }
            else
            {
               this._myPetInfoPanel.refreshNoOperatingPetInfoView();
               this.updatePetInfoMC(param5,param11);
            }
         }
         else
         {
            this.updatePetInfoMC(param5,param11);
            if(!FightData.instance.isMySide(param5.locaId))
            {
               this.addHurt(param7);
            }
         }
      }
      
      private function addHurt(param1:Array) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            if(param1[_loc3_] < 0)
            {
               _loc2_ += Math.abs(param1[_loc3_]);
            }
            _loc3_++;
         }
         TrainingTower.instance.addHurt(_loc2_);
      }
      
      private function randomOffset() : int
      {
         return Math.random() * 100 - 50;
      }
      
      public function refreshTxt(param1:String) : void
      {
         if(this._gameOptionSvr.isHideFightSomething)
         {
            return;
         }
         if(FightController.instance.isPetFightSpaceLive)
         {
            return;
         }
         var _loc2_:String = StringFormatUtil.instance.formatStr(param1);
         this.iFightTalk.addFightMessage(_loc2_);
      }
      
      private function autoUseSkill() : void
      {
         if(FightController.instance.isReplay)
         {
            return;
         }
         this.operatingPlayerAutoUseSkill();
         this.noOperatingPlayerAutoUseSkill();
      }
      
      private function noOperatingPlayerAutoUseSkill() : void
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:PetBriefInfo = null;
         var _loc1_:Array = FightData.instance.myInfo.getNoOperatingPlayers();
         for each(_loc2_ in _loc1_)
         {
            if((_loc2_.myPets[0] as PetBriefInfo).curHp > 0)
            {
               if(!FightData.instance.myInfo.hasOperated(_loc2_.slotId))
               {
                  _loc3_ = _loc2_.myPets[0];
                  this.petAutoUseSkill(_loc2_.slotId,_loc3_);
                  FightData.instance.myInfo.setPlayerOperatedState(_loc2_.slotId,true);
               }
            }
         }
      }
      
      private function petAutoUseSkill(param1:int, param2:PetBriefInfo) : void
      {
         var _loc3_:SkillInfo = null;
         var _loc4_:int = 0;
         for each(_loc3_ in param2.skills)
         {
            if(SkillUseValide.canUseSkill(_loc3_.id,_loc3_.canUseTimes,param1))
            {
               _loc4_ = SkillTargetSelecter.getDefaultSkillTarget(_loc3_.id,param1);
               PetClient.instance.useSkill(_loc3_.id,_loc4_,FightController.instance.turnCount,false,0,param1);
               return;
            }
         }
         PetClient.instance.standby(FightController.instance.turnCount,true,param1);
      }
      
      private function operatingPlayerAutoUseSkill() : void
      {
         var _loc5_:PMSkill = null;
         var _loc6_:int = 0;
         var _loc7_:PMSkill = null;
         var _loc1_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         if(FightData.instance.myInfo.hasOperated(_loc1_.slotId))
         {
            return;
         }
         var _loc2_:PetBriefInfo = _loc1_.myPets[0];
         var _loc3_:int = this._skillStrategy.useSkill(_loc2_);
         var _loc4_:IPMService = ServicePool.instance.getService(IPMService);
         if(LegendPetHelper.checkIsLegendBig(_loc3_))
         {
            _loc5_ = _loc4_.customData.pmSkillMap.getSkill(_loc3_);
            _loc6_ = int(SkillType.getBigSkillType(_loc5_.getLegendBigSkillType()));
            UseBigSkillHandler.instance.handlerAutoUse(_loc2_,_loc3_,_loc6_);
         }
         else if(DegeneratorPetHelper.checkIsDegeneratorBig(_loc3_))
         {
            _loc7_ = _loc4_.customData.pmSkillMap.getSkill(_loc3_);
            UseBigSkillHandler.instance.handlerAutoUse(_loc2_,_loc3_,PMSkillTypes.DEGENERATOR_KILL_BIG);
         }
         else
         {
            this.skillPanel.autoUseSkill(_loc3_);
         }
         FightData.instance.myInfo.setPlayerOperatedState(_loc1_.slotId,true);
      }
      
      private function onClickEscape(param1:MouseEvent) : void
      {
         if(!this.checkControlTargetClickable(param1))
         {
            return;
         }
         if(!FightController.instance.canEscape || MovieClip(this.uiLayer.mcEscape).currentFrame == 2 || MovieClip(this.uiLayer.mcEscape).currentFrame == 4)
         {
            return;
         }
         if(this._escapeConfirmPanel != null && this._escapeConfirmPanel.parent != null)
         {
            DisplayUtil.stopAndRemove(this._escapeConfirmPanel);
         }
         MovieClip(this.uiLayer.mcEscape).removeEventListener(MouseEvent.CLICK,this.onClickEscape);
         var _loc2_:String = "是否选择逃跑?";
         this._escapeConfirmPanel = new MyConfirmPanel(_loc2_);
         this._escapeConfirmPanel.addEventListener(ModalDialogEvent.OK,this.onSureEscape);
         this._escapeConfirmPanel.addEventListener(ModalDialogEvent.CANCEL,this.onCancel);
         LayerManager.getFightingTop().addChild(this._escapeConfirmPanel);
         DisplayUtil.middleDisplay(this._escapeConfirmPanel,960,560);
         this.cancelSelect();
      }
      
      private function cancelSelect() : void
      {
         ChangeMouse.instance.revert();
         FightEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.CANCEL_USE_ITEM));
         if(this.skillPanel)
         {
            this.skillPanel.cancelUseSkill();
         }
      }
      
      private function tryCancelUseItem() : void
      {
         ChangeMouse.instance.revert();
         FightEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.CANCEL_USE_ITEM));
      }
      
      private function tryCancelUseSkill() : void
      {
         ChangeMouse.instance.revert();
         this.skillPanel.cancelUseSkill();
      }
      
      private function addEscapeResponder() : void
      {
         MovieClip(this.uiLayer.mcEscape).addEventListener(MouseEvent.CLICK,this.onClickEscape);
      }
      
      private function onSureEscape(param1:ModalDialogEvent) : void
      {
         var _loc3_:PetBriefInfo = null;
         if(FightData.instance.myInfo.havePlayerCanOperate())
         {
            this.addEscapeResponder();
         }
         var _loc2_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         if(_loc2_ && _loc2_.myPets && _loc2_.myPets.length > 0)
         {
            _loc3_ = _loc2_.myPets[0];
            if(StatusUtil.getIsInWumangXingjiState(_loc3_))
            {
               this.addEscapeResponder();
            }
         }
         FightController.instance.escape();
      }
      
      private function onCancel(param1:ModalDialogEvent) : void
      {
         this.addEscapeResponder();
      }
      
      private function onStartNextTurn(param1:PetFightEvent) : void
      {
         FightData.instance.myInfo.resetOperateRecord();
         this.canStart = true;
         if(this.petLoadeNum != FightData.instance.fightNum)
         {
            return;
         }
         if(FightController.instance.isReplay)
         {
            return;
         }
         var _loc2_:int = FightData.instance.myInfo.getCanOperateDefaultSlotId();
         if(_loc2_ >= 0)
         {
            this.setPlayerOperating(_loc2_);
         }
         if(FightController.isAutoUseSkill)
         {
            this.canStart = false;
            AutoFightTimer.instance.registerTimer(this.onCheckauto);
         }
         else
         {
            EnterFrameManager.instance.register(this.onCheckauto);
         }
         this.timeAndAutoAtt();
      }
      
      private function onStartNextSmallTurn(param1:PetFightEvent) : void
      {
         if(FightController.instance.isReplay)
         {
            return;
         }
         var _loc2_:int = FightData.instance.myInfo.getCanOperateDefaultSlotId();
         if(_loc2_ >= 0)
         {
            FightData.instance.myInfo.resetOperateRecord();
            this.setPlayerOperating(_loc2_);
            this.canStart = true;
            if(FightData.instance.myInfo.getNeedOnlySwitchPMs(_loc2_))
            {
               if(FightController.isAutoUseSkill || !FightData.instance.myInfo.haveCanSwitchUpPetOnDying())
               {
                  this.canStart = false;
                  this.handleAutoSwitchPM();
               }
               else
               {
                  this.startManualSwitch();
               }
            }
            else if(FightData.instance.myInfo.getNeedOnlyClickPanels(_loc2_))
            {
               this.startBattleGambling(FightController.isAutoUseSkill,_loc2_);
            }
            else
            {
               if(FightController.isAutoUseSkill)
               {
                  AutoFightTimer.instance.registerTimer(this.onCheckauto);
                  this.canStart = false;
               }
               else
               {
                  EnterFrameManager.instance.register(this.onCheckauto);
               }
               this.timeAndAutoAtt();
            }
         }
      }
      
      private function startBattleGambling(param1:Boolean = true, param2:int = -1) : void
      {
         var randomArr:Array = null;
         var startIndex:int = 0;
         var gameblingStr:String = null;
         var isAutoUseSkill:Boolean = param1;
         var reqSlotId:int = param2;
         if(isAutoUseSkill)
         {
            randomArr = [0,1,2,3];
            startIndex = Math.floor(Math.random() * randomArr.length);
            randomArr = randomArr.splice(startIndex,randomArr.length - startIndex).concat(randomArr);
            gameblingStr = StringUtil.initArrayToString(randomArr,":");
            this.battleGambling(gameblingStr,reqSlotId);
         }
         else
         {
            this.countDown(FightConfig.getTempSwitchOperateSeconds(),function():void
            {
               startBattleGambling(true,reqSlotId);
            });
            new GQMingYunBoYiChoosePanel().showPanelByCallback(function(param1:String):void
            {
               battleGambling(param1,reqSlotId);
            });
         }
      }
      
      private function battleGambling(param1:String, param2:int = -1) : void
      {
         PetClient.instance.battleGambling(param1,param2);
         FightData.instance.myInfo.setNeedOnlyClickPanels(param2,false);
         this.stopTimer();
         this.closeWaitTips();
         this.canStart = false;
         FightController.instance.handle();
      }
      
      private function handleAutoSwitchPM() : void
      {
         var _loc1_:Array = FightData.instance.myInfo.getDieForSwitchSlots();
         var _loc2_:Array = FightData.instance.myInfo.getCanSwitchUpPetsInDyingSwitch();
         var _loc3_:int = 0;
         while(_loc3_ < _loc1_.length)
         {
            if(_loc2_[_loc3_] > 0 && !FightData.instance.myInfo.hasOperated(_loc1_[_loc3_]))
            {
               PetClient.instance.switchPM(_loc2_[_loc3_],FightController.instance.turnCount,_loc1_[_loc3_]);
            }
            else
            {
               PetClient.instance.standby(FightController.instance.turnCount + 1,true,_loc1_[_loc3_]);
            }
            _loc3_++;
         }
         this.stopTimer();
         FightController.instance.handle();
      }
      
      private function startManualSwitch() : void
      {
         this.countDown(FightConfig.getTempSwitchOperateSeconds(),this.handleAutoSwitchPM);
         this.handleManualSwitch();
      }
      
      public function handleManualSwitch() : void
      {
         this.setPetsClicked();
         this.disableOperateBtnClick();
         FightController.instance.handle();
      }
      
      public function setReady() : void
      {
         var _loc1_:PlayerBattleInfo = null;
         var _loc2_:int = 0;
         var _loc3_:Point = null;
         var _loc4_:MovieClip = null;
         if(FightController.instance.isReplay)
         {
            return;
         }
         if(this.team == null || this.team.teamLength <= 1)
         {
            return;
         }
         for each(_loc1_ in FightData.instance.playerInfo)
         {
            if(!(_loc1_.PMMasterId <= 0 || _loc1_.myPets[0].curHp <= 0))
            {
               _loc2_ = int(_loc1_.locaId);
               _loc3_ = PositionUtil.getDefaultPosition(_loc2_);
               DisplayUtil.stopAndRemove(this.readyBtn[_loc2_]);
               _loc4_ = FightMcPool.instance.getRes(ReadyBtn,true);
               this.readyBtn[_loc1_.locaId] = _loc4_;
               this.readyBtn[_loc1_.locaId].x = _loc3_.x;
               this.readyBtn[_loc1_.locaId].y = _loc3_.y - 100;
               this.uiLayer.addChild(this.readyBtn[_loc1_.locaId]);
            }
         }
      }
      
      public function removeReady(param1:int) : void
      {
         if(this != null)
         {
            FightMcPool.instance.recycle(this.readyBtn[param1]);
            this.readyBtn[param1] = null;
         }
      }
      
      public function addStopMovie(param1:int, param2:int) : void
      {
         var _loc3_:MCPetContainer = this.petMCList[param1] as MCPetContainer;
         if(_loc3_ == null)
         {
            return;
         }
         _loc3_.addStopMovie(param2);
      }
      
      public function removeStopMovie(param1:int) : void
      {
         var _loc2_:MCPetContainer = this.petMCList[param1] as MCPetContainer;
         if(_loc2_ == null)
         {
            return;
         }
         _loc2_.removeStopMovie();
      }
      
      public function timeAndAutoAtt() : void
      {
         this.countDown(FightConfig.getTurnOperateSeconds(),this.onAttTimesUp);
      }
      
      private function onCheckauto() : void
      {
         if(FightController.isAutoUseSkill)
         {
            this.autoUseSkill();
         }
      }
      
      public function countDown(param1:int, param2:Function) : void
      {
         FightFrameRateManager.instance.correctFrameRate();
         if(FightController.instance.isReplay)
         {
            return;
         }
         this.tryShowCanCatchMovie();
         this.canStart = false;
         if(this._countMovie == null)
         {
            this._countMovie = new CountMovie();
            this._countMovie.x = 473;
            this._countMovie.y = 186;
         }
         if(this._countMovie.parent == null)
         {
            this.uiLayer.addChild(this._countMovie);
         }
         this._countMovie.startCount(param1,param2);
         this.enableClick();
      }
      
      private function tryShowCanCatchMovie() : void
      {
         var _loc2_:int = 0;
         var _loc3_:MovieClip = null;
         var _loc4_:Point = null;
         var _loc1_:Array = CatchPm.instance.getShowCatchableIconDatas();
         if(_loc1_.length > 0)
         {
            for each(_loc2_ in _loc1_)
            {
               _loc3_ = this._canCatchMovies[_loc2_];
               _loc4_ = PositionUtil.getDefaultPosition(_loc2_);
               if(_loc3_ == null)
               {
                  _loc3_ = new CanCatchMovie();
                  _loc3_.x = _loc4_.x;
                  _loc3_.y = _loc4_.y;
                  this._canCatchMovies[_loc2_] = _loc3_;
               }
               else
               {
                  _loc3_.visible = true;
                  _loc3_.play();
               }
               this._layerPet.addChild(_loc3_);
            }
            this.catchBtnIcon.visible = true;
            this.catchBtnIcon.y = this.catchBtnY;
         }
      }
      
      private function onAttTimesUp() : void
      {
         this.removeListen();
         this.cancelSelect();
         this.autoUseSkill();
      }
      
      private function removeListen() : void
      {
         var _loc1_:PlayerBattleInfo = null;
         for each(_loc1_ in FightData.instance.playerInfo)
         {
            if(FightController.instance.fightPanel.contains(FightController.instance.fightPanel.petMCList[_loc1_.locaId]))
            {
               FightController.instance.fightPanel.petMCList[_loc1_.locaId].removeListen();
            }
         }
      }
      
      private function onLeaver(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(PetClient.RSPN_LEAVE_BATTLE_LEAVER + "",this.onLeaver);
         if(param1.params.msg != undefined)
         {
            NewDialog.showFailMessage(param1.params.msg);
         }
      }
      
      public function close() : void
      {
         if(this._isClosed)
         {
            return;
         }
         this._isClosed = true;
         this.pause();
         if(this.msgPanel != null)
         {
            DisplayUtil.stopAndRemove(this.msgPanel);
            if(this.msgPanel as IDispose)
            {
               (this.msgPanel as IDispose).dispose();
            }
            this.msgPanel = null;
         }
         if(this.iFightTalk != null)
         {
            this.iFightTalk.dispose();
            this.iFightTalk = null;
         }
         TrainingTower.instance.closeTipsPanel();
         DisplayUtil.stopAndRemove(this);
         if(this._faZhenSkillBtn != null)
         {
            this._faZhenSkillBtn.dispose();
            this._faZhenSkillBtn = null;
         }
         this.dispose();
      }
      
      public function dispose() : void
      {
         var _loc1_:UIPanelBase = null;
         var _loc2_:ScreenShaker = null;
         var _loc4_:MCPetContainer = null;
         var _loc5_:StatusEffectContainer = null;
         var _loc12_:int = 0;
         var _loc15_:PlayerBattleInfo = null;
         var _loc16_:int = 0;
         var _loc17_:Boolean = false;
         var _loc18_:int = 0;
         var _loc19_:int = 0;
         var _loc20_:Boolean = false;
         var _loc21_:ITeamService = null;
         var _loc22_:UserTeamInfo = null;
         var _loc23_:String = null;
         var _loc24_:IPetFight = null;
         if(this._isDisposed)
         {
            return;
         }
         for each(_loc1_ in this._uiPanelList)
         {
            if(_loc1_)
            {
               _loc1_.dispose();
               DisplayUtil.stopAndRemove(_loc1_);
            }
         }
         this._uiPanelList.length = 0;
         this._uiPanelList = null;
         for each(_loc2_ in this._shakerList)
         {
            _loc2_.dispose();
         }
         this._shakerList.length = 0;
         this._shakerList = null;
         this._mcWait && this._mcWait.dispose();
         this._mcWait = null;
         this._countMovie && this._countMovie.dispose();
         this._countMovie = null;
         this._myPetInfoPanel && this._myPetInfoPanel.dispose();
         DisplayUtil.stopAndRemove(this._myPetInfoPanel);
         this._myPetInfoPanel = null;
         this._backGroundView && this._backGroundView.dispose();
         this._backGroundView = null;
         MovieClip(this.uiLayer.mcEscape).removeEventListener(MouseEvent.CLICK,this.onClickEscape);
         if(this._escapeConfirmPanel)
         {
            this._escapeConfirmPanel.removeEventListener(ModalDialogEvent.OK,this.onSureEscape);
            this._escapeConfirmPanel.removeEventListener(ModalDialogEvent.CANCEL,this.onCancel);
            this._escapeConfirmPanel = null;
         }
         MovieClip(this.uiLayer.mcCatch).removeEventListener(MouseEvent.CLICK,this.onClickCatch);
         MovieClip(this.uiLayer.mcItem).removeEventListener(MouseEvent.CLICK,this.onClickItem);
         MovieClip(this.uiLayer.mcRelax).removeEventListener(MouseEvent.CLICK,this.onClickRelax);
         MovieClip(this.uiLayer.mcPets).removeEventListener(MouseEvent.CLICK,this.onClickPets);
         CommonEventDispatcher.instance.removeEventListener("PetFightNew_HideSomeThing",this.isHideSomething);
         this._isDisposed = true;
         if(this._escapeConfirmPanel != null)
         {
            DisplayUtil.stopAndRemove(this._escapeConfirmPanel);
         }
         DisplayUtil.stopAndRemove(this.myBEPanel);
         this.myBEPanel = null;
         EnterFrameManager.instance.remove(this.onCheckauto);
         AutoFightTimer.dispose();
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onAdd2Stage);
         _loc21_ = ServicePool.instance.getService(ITeamService);
         var _loc3_:IFollowService = ServicePool.instance.getService(IFollowService);
         DisplayUtil.stopAndRemove(this.attributeHolder);
         StringFormatUtil.instance.dispose();
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.ON_LOADING_SCENE,this.removeFromStage);
         if(this._fetterUI)
         {
            this._fetterUI.dispose();
            DisplayUtil.stopAndRemove(this._fetterUI);
            this._fetterUI = null;
         }
         if(this._replayUI)
         {
            this._replayUI.dispose();
            DisplayUtil.stopAndRemove(this._replayUI);
            this._replayUI = null;
         }
         if(this._liveUI)
         {
            this._liveUI.dispose();
            DisplayUtil.stopAndRemove(this._liveUI);
            this._liveUI = null;
         }
         if(this._petFightSpaceliveUI)
         {
            this._petFightSpaceliveUI.dispose();
            DisplayUtil.stopAndRemove(this._petFightSpaceliveUI);
            this._petFightSpaceliveUI = null;
         }
         if(this._fightActUI != null)
         {
            (this._fightActUI as IDispose).dispose();
            this._fightActUI = null;
         }
         if(this.autoTxt != null)
         {
            DisplayUtil.stopAndRemove(this.autoTxt);
            if(this.cancelBtn != null)
            {
               this.cancelBtn.removeEventListener(MouseEvent.CLICK,this.onClickCancelAuto);
               this.cancelBtn = null;
            }
            this.autoTxt = null;
         }
         SwitchPm.instance.dispose();
         for each(_loc4_ in this.petMCList)
         {
            _loc4_.dispose();
            DisplayUtil.stopAndRemove(_loc4_);
         }
         this.petMCList.length = 0;
         ChangeMouse.instance.dispose();
         for each(_loc5_ in this.statusEffectContainerList)
         {
            _loc5_.dispose();
         }
         this.statusEffectContainerList = null;
         FightController.instance.removeEventListener(PetFightEvent.NEXT_TURN,this.onStartNextTurn);
         FightController.instance.removeEventListener(PetFightEvent.NEXT_SMALL_TURN,this.onStartNextSmallTurn);
         if(FightData.fightMode != FightMode.FIGHT_3V3 && !FightController.instance.isReplay)
         {
            PetClient.instance.leaveBattle(FightData.instance.battleId);
         }
         var _loc6_:Boolean = FinBattle.instance.isWin();
         var _loc7_:int = FightController.instance.whoWon;
         var _loc8_:Boolean = Escape.instance.isEscape;
         var _loc9_:Boolean = Escape.instance.isVsEscape;
         var _loc10_:Boolean = CatchPm.instance.isCatchLevelUp;
         var _loc11_:Boolean = CatchPm.instance.isCatched;
         var _loc13_:Array = [];
         var _loc14_:Array = FightData.instance.playerInfo;
         for each(_loc15_ in _loc14_)
         {
            if(FightData.instance.isMySide(_loc15_.locaId))
            {
               _loc13_.push(_loc15_.myPets[0].raceId);
            }
            else
            {
               _loc21_ = ServiceContainer.instance.getService("TeamService") as ITeamService;
               _loc22_ = _loc21_.getUserTeam(_loc15_.PMMasterId.toString());
               if(_loc22_ != null)
               {
                  _loc23_ = _loc22_.leaderName;
                  for each(_loc15_ in _loc14_)
                  {
                     if(_loc15_.PMMasterId.toString() == _loc23_)
                     {
                        _loc12_ = int(_loc15_.myPets[0].raceId);
                     }
                  }
               }
               else
               {
                  _loc12_ = int(_loc15_.myPets[0].raceId);
               }
            }
         }
         _loc16_ = int(FightData.instance.myInfo.operatingPlayer.myPets[0].raceId);
         _loc17_ = FightController.instance.isAuto;
         _loc18_ = FightController.instance.id;
         _loc19_ = int(TrainingTower.instance.hurt.getValue());
         LayerManager.switchLayer(LayerManager.BASE_LAYER);
         _loc20_ = FightController.instance.isReplay;
         Disposer.instance.tryDisposeResources();
         this.disposeTitleView();
         this.disposePetInfoMCs();
         this.disposeHunDunSumPetInfoMCs();
         this.disposeCommonBuff1253PetInfoMCs();
         this.disposeXingZhiCaiFightPetInfoMCs();
         this.disposeManagers();
         FightController.instance.dispose();
         BattleSmallTurn.instance.dispose();
         TerritoryRelive.instance.dispose();
         GCManager.instance.disposeSpecialResource();
         if(_loc20_)
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.REPLAY_END,{}));
         }
         else
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FIGHT_END,{
               "isWin":_loc6_,
               "raceId":_loc12_,
               "isEscape":_loc8_,
               "isCatchLevelUp":_loc10_,
               "id":_loc18_,
               "isCatched":_loc11_,
               "isVsEscape":_loc9_,
               "whoWon":_loc7_,
               "myFinalRaceId":_loc16_,
               "hurt":_loc19_,
               "myTeamRaceIdArr":_loc13_
            }));
            this.showHelloAction(_loc6_);
            if(!_loc6_)
            {
               this.showBattleEff();
            }
         }
         if(this._beforeIsShowTitleHonor != this._titleSvr.getIsShowTitleHonor())
         {
            this._titleSvr.setIsShowTitleHonor(this._beforeIsShowTitleHonor);
         }
         if(_loc17_ && !_loc20_)
         {
            SocketClient.instance.addEventListener(PetClient2.cmdAutoFight,this.onAutoFight);
            PetClient2.instance.autoFight();
         }
         else
         {
            _loc24_ = ServiceContainer.getService(IPetFight);
            _loc24_.handleNextFight();
         }
         if(!_loc6_)
         {
            PetClient.instance.viewAllPM();
         }
         Escape.instance.dispose();
         this._defaultFightUI && this._defaultFightUI.dispose();
         this._defaultFightUI = null;
         GameOptionMgr.instance.setHudVisible(true);
         GameOptionMgr.instance.showOrHideControlBar(true);
      }
      
      private function disposeTitleView() : void
      {
         if(null != this._titleView)
         {
            DisplayUtil.stopAndRemove(this._titleView);
            if(this._titleView is IDispose)
            {
               IDispose(this._titleView).dispose();
            }
            this._titleView = null;
         }
      }
      
      private function disposePetInfoMCs() : void
      {
         var _loc1_:PetInfoMCBase = null;
         if(this.smallPetInfoMCList)
         {
            for each(_loc1_ in this.smallPetInfoMCList)
            {
               _loc1_.dispose();
            }
            this.smallPetInfoMCList = null;
         }
      }
      
      private function disposeHunDunSumPetInfoMCs() : void
      {
         var _loc1_:HunDunSumPetInfoMC = null;
         if(this.hunDunSumPetInfoMCList)
         {
            for each(_loc1_ in this.hunDunSumPetInfoMCList)
            {
               _loc1_.dispose();
            }
            this.hunDunSumPetInfoMCList = null;
         }
      }
      
      private function disposeCommonBuff1253PetInfoMCs() : void
      {
         var _loc1_:CommonBuff1253PetInfoMC = null;
         if(this._commonBuff1253PetInfoMCList)
         {
            for each(_loc1_ in this._commonBuff1253PetInfoMCList)
            {
               _loc1_.dispose();
            }
            this._commonBuff1253PetInfoMCList = null;
         }
      }
      
      private function disposeXingZhiCaiFightPetInfoMCs() : void
      {
         var _loc1_:XingZhiCaiFight25PetInfoMc = null;
         if(this._xingZhiCaiPetInfoMcList)
         {
            for each(_loc1_ in this._xingZhiCaiPetInfoMcList)
            {
               _loc1_.dispose();
            }
            this._xingZhiCaiPetInfoMcList = null;
         }
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
      }
      
      private function get skillPanel() : NewSkillPanel
      {
         return this._uiPanelList[UIPanelType.SKILL];
      }
      
      public function switchSkill() : void
      {
         if(this.skillPanel)
         {
            this.skillPanel.switchSkill();
         }
      }
      
      private function showBattleEff() : void
      {
         var i:IRobotService = ServiceContainer.getService(IRobotService);
         var d:Date = DateUtil.getServerTime();
         var localKey:String = "battleeff_" + d.fullYear.toString() + d.month.toString() + d.date.toString();
         if((i.getMyDayLife() < 100 || this.getPackageEff() < 25000) && !LocalStore.getValue(localKey,SocketClient.instance.myUserName) && !this.isInIcesnowScene())
         {
            ResScheduler.getRes(ResParams.createTemp("pet/petdetect/fightendfail",function(param1:IShowPanel, param2:ApplicationDomain):void
            {
               param1.showPanel();
            },"mmo.pet.petdetect.panel.PDMFightFail"));
         }
      }
      
      private function isInIcesnowScene() : Boolean
      {
         var _loc1_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         return "icesnowtemple" == _loc1_ || "jinglingwangpalace" == _loc1_;
      }
      
      private function getPackageEff() : int
      {
         var _loc5_:int = 0;
         var _loc6_:PetBriefInfo = null;
         var _loc1_:IPetDataService = ServiceContainer.getService(IPetDataService);
         var _loc2_:IPetBattleEffDataService = ServiceContainer.getService(IPetBattleEffDataService);
         var _loc3_:Array = _loc1_.getMyPets();
         var _loc4_:* = 0;
         if(_loc3_ != null && _loc3_.length > 0)
         {
            _loc5_ = 0;
            while(_loc5_ < _loc3_.length)
            {
               _loc6_ = _loc3_[_loc5_] as PetBriefInfo;
               _loc4_ += _loc2_.getPetBattleEffectiveness(_loc6_);
               _loc5_++;
            }
         }
         return _loc4_;
      }
      
      private function showHelloAction(param1:Boolean) : void
      {
         var _loc2_:IRobotService = ServiceContainer.getService(IRobotService) as IRobotService;
         var _loc3_:Object = _loc2_.getRobotFollowingPlayer();
         if(_loc3_ == null)
         {
            return;
         }
         var _loc4_:String = "";
         if(param1)
         {
            _loc4_ = "gx";
         }
         else
         {
            _loc4_ = "sq";
         }
         if(!_loc2_.isHellobabyType())
         {
            _loc3_.action(_loc4_);
         }
      }
      
      private function removeFromStage(param1:SceneManagerEvent) : void
      {
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.ON_LOADING_SCENE,this.removeFromStage);
         this.dispose();
      }
      
      private function isHideSomething(param1:CommonEvent) : void
      {
         this.msgPanel.y = TextField(this.uiLayer.msgHolder).y + (this._gameOptionSvr.isHideFightSomething ? 560 : 0);
      }
      
      public function sayByLocalId(param1:int, param2:String) : void
      {
         var _loc3_:MCPetContainer = this.petMCList[param1] as MCPetContainer;
         if(_loc3_ == null)
         {
            return;
         }
         _loc3_.say(param2);
      }
      
      public function setPetVisibleByLocalId(param1:int, param2:Boolean) : void
      {
         var _loc3_:MCPetContainer = this.petMCList[param1] as MCPetContainer;
         _loc3_.visible = param2;
      }
      
      public function shake() : void
      {
         var shaker:ScreenShaker = null;
         var bitmapData:BitmapData = null;
         var bitmap:Bitmap = null;
         if(this._isShaking)
         {
            return;
         }
         this._isShaking = true;
         for each(shaker in this._shakerList)
         {
            shaker.shake();
         }
         bitmapData = new BitmapData(960,560);
         bitmapData.draw(this._layerBackGround);
         bitmap = new Bitmap(bitmapData);
         this._layerBackGround.addChild(bitmap);
         new ScreenShaker(bitmap,function():void
         {
            _isShaking = false;
            DisplayUtil.stopAndRemove(bitmap);
         }).shake();
      }
      
      private function hideWaitTips() : void
      {
         if(this._mcWait.parent)
         {
            this._mcWait.parent.removeChild(this._mcWait);
         }
      }
      
      public function showWaitTips(param1:int) : void
      {
         if(this._mcWait.parent == null)
         {
            this.uiLayer.addChild(this._mcWait);
         }
         this._mcWait.setTips(param1);
      }
      
      public function refreshFaZhenSkill() : void
      {
         if(this._faZhenSkillBtn != null)
         {
            this._faZhenSkillBtn.refreshView();
         }
      }
      
      private function setMcEscapeFrame(param1:int) : void
      {
         if(FightController.instance.isEscapeEvacuate)
         {
            if(param1 == 1)
            {
               param1 = 3;
            }
            if(param1 == 2)
            {
               param1 = 4;
            }
         }
         MovieClip(this.uiLayer.mcEscape).gotoAndStop(param1);
      }
      
      private function setMcPetsFrame(param1:int) : void
      {
         var _loc2_:PetBriefInfo = FightData.instance.myInfo.operatingPlayer.myPets[0];
         if(Boolean(_loc2_) && (StatusUtil.getIsDengShenChangJieSpiritSkillUsed(_loc2_) || StatusUtil.getIsInJiangShenState(_loc2_) || StatusUtil.getIsZhenLiFaDianSpiritSkillUsed(_loc2_)))
         {
            if(param1 == 1)
            {
               param1 = 2;
            }
         }
         MovieClip(this.uiLayer.mcPets).gotoAndStop(param1);
      }
      
      public function updateUIPanel(param1:int = -1) : void
      {
         var _loc2_:int = 0;
         var _loc3_:UIPanelBase = null;
         var _loc4_:UIPanelBase = null;
         if(!this._uiPanelList)
         {
            return;
         }
         if(param1 == -1)
         {
            _loc2_ = 0;
            while(_loc2_ < UI_PANEL_NUM)
            {
               if(this._uiPanelList.length > _loc2_)
               {
                  _loc3_ = this._uiPanelList[_loc2_];
                  if(Boolean(_loc3_) && Boolean(_loc3_.parent))
                  {
                     _loc3_.update();
                  }
               }
               _loc2_++;
            }
         }
         else if(this._uiPanelList.length > param1)
         {
            _loc4_ = this._uiPanelList[param1];
            if((Boolean(_loc4_)) && Boolean(_loc4_.parent))
            {
               _loc4_.update();
            }
         }
      }
   }
}

