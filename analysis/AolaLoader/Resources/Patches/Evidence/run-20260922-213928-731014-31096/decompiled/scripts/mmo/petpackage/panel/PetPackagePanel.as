package mmo.petpackage.panel
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.AlignType;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.display.DisplayIndexManager;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.*;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.*;
   import mmo.interfaces.newbie.*;
   import mmo.interfaces.pet.data.AoYiConfig;
   import mmo.interfaces.pet.data.BargainPetConfig;
   import mmo.interfaces.pet.data.IPetBattleEffDataService;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetChangeViewConfig;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.pet.petpackage.IPetPackageSort;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.uicomponent.UIComponentEvent;
   import mmo.interfaces.uicomponent.mutex.MutexAry;
   import mmo.interfaces.uicomponent.mutex.SelectableMovieClip;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.gc.GCManager;
   import mmo.petpackage.cache.PackageCacheManager;
   import mmo.petpackage.controller.event.*;
   import mmo.petpackage.controller.helper.PetArrayRefresher;
   import mmo.petpackage.controller.helper.PetPackageGQNewSkillHelper;
   import mmo.petpackage.controller.helper.PetPackageHelper;
   import mmo.petpackage.controller.helper.ViewIndexHelper;
   import mmo.petpackage.controller.reddot.ItemTabRedDotHandler;
   import mmo.petpackage.controller.skin.PackageSkinManager;
   import mmo.petpackage.controller.skin.constant.Classify;
   import mmo.petpackage.controller.skin.constant.StyleTypes;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.panel.inclusion.*;
   import mmo.petpackage.panel.inclusion.interfaces.IPetView;
   import mmo.petpackage.panel.inclusion.petdetailinfo.AoYiViewPanel;
   import mmo.petpackage.panel.inclusion.petdetailinfo.AstralSpirit;
   import mmo.petpackage.panel.inclusion.petdetailinfo.BargainPetPanel;
   import mmo.petpackage.panel.inclusion.petdetailinfo.CrystalKeyPanel;
   import mmo.petpackage.panel.inclusion.petdetailinfo.EntrySystemPanel;
   import mmo.petpackage.panel.inclusion.petdetailinfo.GodCard;
   import mmo.petpackage.panel.inclusion.petdetailinfo.HKPanel;
   import mmo.petpackage.panel.inclusion.petdetailinfo.Inscription;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetCard;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetCard2;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetChangeViewPanel;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetCharactorInfo;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetDetailAbility;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetDetailInfo;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetDetailSkill;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetGeniusInfo;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetHolySpace;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetItem;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetLevelInfo;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetStudyInfo;
   import mmo.petpackage.panel.inclusion.petdetailinfo.TotePanel;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.activity.helper.Pet_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3294")]
   public class PetPackagePanel extends Sprite implements IShowPanel, IDispose, IClosePanel
   {
      
      private static const LocalStoreKey:String = "act191129_first_open_petpackage";
      
      public var btn0_0:MovieClip;
      
      public var btn0_1:MovieClip;
      
      public var btn0_2:MovieClip;
      
      public var btn0_3:MovieClip;
      
      public var btn0_4:MovieClip;
      
      public var btn0_5:MovieClip;
      
      public var btn0_6:MovieClip;
      
      public var btn0_7:MovieClip;
      
      public var btn0_8:MovieClip;
      
      public var btn1_0:MovieClip;
      
      public var btn1_1:MovieClip;
      
      public var btn1_2:MovieClip;
      
      public var btn2_0:MovieClip;
      
      public var btn2_1:MovieClip;
      
      public var btn2_2:MovieClip;
      
      public var btn2_3:MovieClip;
      
      public var btn2_4:MovieClip;
      
      public var btn2_5:MovieClip;
      
      public var btn2_6:MovieClip;
      
      public var btn2_7:MovieClip;
      
      public var btn2_8:MovieClip;
      
      public var btnFaZhen:SimpleButton;
      
      public var btn_petsort:SimpleButton;
      
      public var btnclose:SimpleButton;
      
      public var mcEntrySystem:EntrySystemPanel;
      
      public var mcGQPetPreset:MovieClip;
      
      public var mcGqShenbingBtn:MovieClip;
      
      public var mcHKTips:HKTipsPanel;
      
      public var mcItemTabRedDot:MovieClip;
      
      public var mcPetCorpsIcon:PetCorpsIcon;
      
      public var mcPetHunKaIcon:PetHunKaIcon;
      
      public var mcPetIconFullScreen:MovieClip;
      
      public var mcPetShare:PetShareBar;
      
      public var mcPetToteIcon:PetToteIcon;
      
      public var mcTerritoryStoreIcon:TerritoryStoreIcon;
      
      public var mcYuSheList:YuSheList;
      
      public var mcZhanDouLiPingFen:MovieClip;
      
      public var mc_bigicon:PetBigIconDetail;
      
      public var mc_control:PackageControlBar;
      
      public var mc_godcard:GodCardList;
      
      public var mc_petcard2:PetCard2Panel;
      
      public var mc_pets:PetList;
      
      public var mcastralspirit:AstralSpiritPanel;
      
      public var mcastralspiritpanel:AstralSpirit;
      
      public var mcay:AoYiViewPanel;
      
      public var mcbgs:MovieClip;
      
      public var mccard_container:PetCardList;
      
      public var mccharactor:PetCharactorInfo;
      
      public var mcclassifyline:MovieClip;
      
      public var mcclassifyline2:MovieClip;
      
      public var mccrystalkey:CrystalKeyPanel;
      
      public var mcdegeneratorsoul:圣痕面板DegeneratorSoulPanel;
      
      public var mcfightgifticon:FightGiftIcon;
      
      public var mcfirsttab:MovieClip;
      
      public var mcgenius:PetGeniusInfo;
      
      public var mcgodcard:GodCard;
      
      public var mchk:HKPanel;
      
      public var mcinfo:PetDetailInfo;
      
      public var mcinscription:Inscription;
      
      public var mcitem:PetItem;
      
      public var mcjj:PetChangeViewPanel;
      
      public var mclegendsoul:LegendSoulPanel;
      
      public var mclevel:PetLevelInfo;
      
      public var mcpackagebg:MovieClip;
      
      public var mcpackagebgcontainer:MovieClip;
      
      public var mcpc2:PetCard2;
      
      public var mcpetcard:PetCard;
      
      public var mcpetstampicon:PetStampIcon;
      
      public var mcqy:BargainPetPanel;
      
      public var mcsimplebar:SimpleBar;
      
      public var mcskill:PetDetailSkill;
      
      public var mcstudy:PetStudyInfo;
      
      public var mcsummonericon:SummonerIcon;
      
      public var mcsy:PetHolySpace;
      
      public var mcsynthesis:PetDetailAbility;
      
      public var mctab2bg:MovieClip;
      
      public var mctote:TotePanel;
      
      public var mcviewcontroller:SimpleViewController;
      
      public var totalbattleeff:TotalBattleEff;
      
      private var btnClose:SimpleButton = null;
      
      private var btnOpenStudy:SimpleButton = null;
      
      private var btnViewDetail:SimpleButton = null;
      
      private var btnPetsort:SimpleButton = null;
      
      private var btnAttrs:SimpleButton = null;
      
      private var _objs:Array = null;
      
      private var _pmSelectIndex:int = -1;
      
      private var _pmListName:Array = [];
      
      private var mcActRes:PetActRes = null;
      
      private var mcPetList:PetList = null;
      
      private var mcBigicon:PetBigIconDetail = null;
      
      private var mcControlBar:PackageControlBar = null;
      
      private var mcPetcard2:PetCard2Panel = null;
      
      private var mcLegendSoul:LegendSoulPanel = null;
      
      private var _mcDegeneratorSoul:DegeneratorSoulPanel = null;
      
      private var _mcAstralSpirit:AstralSpiritPanel = null;
      
      private var totalBattleEff:TotalBattleEff = null;
      
      private var _mcPetCorpsIcon:PetCorpsIcon = null;
      
      private var _mcPetStampIcon:PetStampIcon = null;
      
      private var _mcSummonerIcon:SummonerIcon = null;
      
      private var _mcPetHunKaIcon:PetHunKaIcon = null;
      
      private var _mcPetToteIcon:PetToteIcon = null;
      
      private var _mcTerritoryStoreIcon:TerritoryStoreIcon = null;
      
      private var mutexTabGroup0:MutexAry = null;
      
      private var mutexTabGroup1Ary:Array;
      
      private var fourthTabIndex:int;
      
      private var mutexInfos:Array = null;
      
      private var mcPetCardList:PetCardList = null;
      
      private var mcGodCardList:GodCardList = null;
      
      private var indexManager:DisplayIndexManager = new DisplayIndexManager();
      
      private var mc_petShare:PetShareBar;
      
      private var mc_fightgifticon:FightGiftIcon;
      
      private var _petDataService:IPetDataService = null;
      
      private var _pmService:IPMService = null;
      
      private var _taskSvr:ITaskService = null;
      
      private var _mcHKPanel:HKTipsPanel = null;
      
      private var _mcYuSheList:YuSheList = null;
      
      private var _curTab1Map:Object = {
         0:0,
         1:0
      };
      
      private var _itemRedDotHandler:ItemTabRedDotHandler;
      
      private var _gqPetPresetIcon:GQPetPreset;
      
      private var _gqShenBingBtnMc:GQShenBingBtnMc;
      
      public function PetPackagePanel()
      {
         super();
         this.initPars();
         this.initFuns();
      }
      
      private function initPars() : void
      {
         var _loc1_:MutexAry = null;
         this._petDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         this._petDataService.addEventListener(PetDataServiceEvent.ON_HIGHTES_BATTLE_EFF_UPDATE,this.effChangeUpdate);
         this._pmService = ServiceContainer.getService(IPMService) as IPMService;
         this._taskSvr = ServiceContainer.getService(ITaskService) as ITaskService;
         this.btnClose = this.btnclose as SimpleButton;
         this.btnOpenStudy = this.mcstudy.btnOpenStudy;
         this.btnViewDetail = this.mcgenius.btnViewDetail;
         TipsManager.getInstance().addTips(this.btnClose,"关闭");
         this.btnPetsort = this.btn_petsort as SimpleButton;
         this.mc_petShare = this.mcPetShare as PetShareBar;
         this.mc_fightgifticon = this.mcfightgifticon as FightGiftIcon;
         this._mcPetCorpsIcon = this.mcPetCorpsIcon as PetCorpsIcon;
         this._mcPetStampIcon = this.mcpetstampicon as PetStampIcon;
         this._mcSummonerIcon = this.mcsummonericon as SummonerIcon;
         this._mcPetHunKaIcon = this.mcPetHunKaIcon as PetHunKaIcon;
         this._mcPetToteIcon = this.mcPetToteIcon as PetToteIcon;
         this._mcTerritoryStoreIcon = this.mcTerritoryStoreIcon as TerritoryStoreIcon;
         this.mcPetList = this.mc_pets as PetList;
         this.mcPetList.setMcPetIconFullScreen(this.mcPetIconFullScreen);
         this.mcBigicon = this.mc_bigicon as PetBigIconDetail;
         this.mcControlBar = this.mc_control as PackageControlBar;
         this.mcPetCardList = this.mccard_container as PetCardList;
         this.mcGodCardList = this.mc_godcard as GodCardList;
         this.mcPetcard2 = this.mc_petcard2 as PetCard2Panel;
         this.mcLegendSoul = this.mclegendsoul as LegendSoulPanel;
         this._mcAstralSpirit = this.mcastralspirit as AstralSpiritPanel;
         this._mcDegeneratorSoul = this.mcdegeneratorsoul as DegeneratorSoulPanel;
         this.totalBattleEff = this.totalbattleeff as TotalBattleEff;
         this._mcHKPanel = this.mcHKTips as HKTipsPanel;
         this._mcYuSheList = this.mcYuSheList as YuSheList;
         this._gqPetPresetIcon = new GQPetPreset(this.getChildByName("mcGQPetPreset") as MovieClip);
         this._gqShenBingBtnMc = new GQShenBingBtnMc(this.getChildByName("mcGqShenbingBtn") as MovieClip);
         this.mutexTabGroup0 = new MutexAry(new SelectableMovieClip(this.mcfirsttab.btn_0),new SelectableMovieClip(this.mcfirsttab.btn_1),new SelectableMovieClip(this.mcfirsttab.btn_2));
         this.mutexTabGroup0.setSelected(0);
         this.mutexTabGroup1Ary = [new MutexAry(new SelectableMovieClip(this.btn0_0),new SelectableMovieClip(this.btn0_1),new SelectableMovieClip(this.btn0_2),new SelectableMovieClip(this.btn0_3),new SelectableMovieClip(this.btn0_4),new SelectableMovieClip(this.btn0_5),new SelectableMovieClip(this.btn0_6),new SelectableMovieClip(this.btn0_7),new SelectableMovieClip(this.btn0_8)),new MutexAry(new SelectableMovieClip(this.btn1_0),new SelectableMovieClip(this.btn1_1),new SelectableMovieClip(this.btn1_2)),new MutexAry(new SelectableMovieClip(this.btn2_0),new SelectableMovieClip(this.btn2_1),new SelectableMovieClip(this.btn2_2),new SelectableMovieClip(this.btn2_3),new SelectableMovieClip(this.btn2_4),new SelectableMovieClip(this.btn2_5),new SelectableMovieClip(this.btn2_6),new SelectableMovieClip(this.btn2_7),new SelectableMovieClip(this.btn2_8))];
         for each(_loc1_ in this.mutexTabGroup1Ary)
         {
            _loc1_.setSelected(0);
         }
         this.mutexTabGroup1Ary[2].setSelected(6);
         this._mcDegeneratorSoul.initTabHandle(this.mutexTabGroup0);
         this._mcAstralSpirit.initTabHandle(this.mutexTabGroup0);
         this.mutexInfos = [[this.mcskill,this.mcsynthesis,this.mcinfo,this.mcsy,this.mcjj,this.mcqy,this.mcay,this.mcEntrySystem,this.mcitem],[this.mclevel,this.mcgenius,this.mccharactor],[this.mcstudy,this.mcpetcard,this.mcpc2,this.mcinscription,this.mcastralspiritpanel,this.mcgodcard,this.mchk,this.mctote,this.mccrystalkey]];
         this.updateTabGroupVisible();
         this.setTabInfoVisible();
         (this.mcviewcontroller as SimpleViewController).setBackgroundContainer(this.mcpackagebgcontainer);
         (this.mcviewcontroller as SimpleViewController).setPackageBackgroundContainer(this.mcpackagebg);
         this._itemRedDotHandler = new ItemTabRedDotHandler(this.getChildByName("mcItemTabRedDot"),this.mutexTabGroup0.getSelectedIndex());
      }
      
      private function initPackageSkin() : void
      {
         PackageSkinManager.instance.joinMultiTargets([this.mc_godcard,this.mccard_container,this.mcfirsttab,this.btn0_0,this.btn0_1,this.btn0_2,this.btn0_3,this.btn0_4,this.btn0_5,this.btn0_6,this.btn0_7,this.btn1_0,this.btn1_1,this.btn1_2,this.btn0_8,this.btn2_0,this.btn2_1,this.btn2_2,this.btn2_3,this.btn2_4,this.btn2_5,this.btn2_6,this.btn2_7,this.btn2_8,this.mcskill,this.mcsynthesis,this.mcinfo,this.mcay,this.mcsy,this.mcEntrySystem,this.mcjj,this.mcqy,this.mclevel,this.mcstudy,this.mcgenius,this.mcpetcard,this.mcgodcard,this.mcinscription,this.mcastralspiritpanel,this.mcpc2,this.mccharactor,this.mcitem,this.mcbgs,this.mctab2bg,this.mcclassifyline,this.mcclassifyline2,this.mcastralspirit,this.mcdegeneratorsoul,this.mclegendsoul,this.mc_petcard2,this.mchk,this.mctote,this.mcHKTips,this.mcYuSheList,this.mccrystalkey,this.mcItemTabRedDot,this.mcGQPetPreset,this.mcGqShenbingBtn],Classify.NORMAL,StyleTypes.RIGHT);
         PackageSkinManager.instance.joinMultiTargets(this.mcControlBar.classifyItems,Classify.NORMAL,StyleTypes.RIGHT);
         PackageSkinManager.instance.joinMultiTargets([this.btn_petsort,this.mcPetCorpsIcon,this.mcpetstampicon,this.mcsummonericon,this.mcPetHunKaIcon,this.mcTerritoryStoreIcon,this.mcfightgifticon,this.mcPetShare,this.totalbattleeff,this.mc_pets,this.mcZhanDouLiPingFen,this.mcPetToteIcon],-1,StyleTypes.RIGHT,[Classify.NORMAL,Classify.LEGENDARY]);
         PackageSkinManager.instance.joinMultiTargets(this.mcControlBar.LeftItems,-1,StyleTypes.LEFT,[Classify.NORMAL,Classify.LEGENDARY]);
         PackageSkinManager.instance.joinNormals(this.mcBigicon,Classify.NORMAL,StyleTypes.NORMAL,new Point(217,0));
         PackageSkinManager.instance.joinNormals(this.mcBigicon.getChildByName("mcPetIcon"),-1,StyleTypes.NORMAL,new Point(255.65,404.9),[Classify.NORMAL,Classify.LEGENDARY]);
         PackageSkinManager.instance.joinSimple(this.mc_control.getChildByName("mchaibao"),-1,StyleTypes.LEFT,[Classify.NORMAL,Classify.LEGENDARY]);
         PackageSkinManager.instance.joinSimple(this.mcPetIconFullScreen,Classify.FULL_SCRREN,StyleTypes.DOWN);
         PackageSkinManager.instance.joinSimple(this.mcsimplebar,Classify.LEGENDARY,StyleTypes.RIGHT);
         PackageSkinManager.instance.joinNormals((this.mcviewcontroller as SimpleViewController).getLabelContainer(),Classify.NORMAL,StyleTypes.NORMAL,new Point(285,20));
         PackageSkinManager.instance.joinNormals(this.mcpackagebg,Classify.NORMAL,StyleTypes.NORMAL,new Point(200,0));
         PackageSkinManager.instance.init();
      }
      
      private function initFuns() : void
      {
         var _loc1_:MutexAry = null;
         var _loc2_:Array = null;
         var _loc3_:SelectableMovieClip = null;
         var _loc4_:MutexAry = null;
         var _loc5_:SelectableMovieClip = null;
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_PANEL_CLOSED,this.onClose);
         CommonEventDispatcher.instance.addEventListener("PetPackageSortPanel_pmBattleList",this.onSort);
         CommonEventDispatcher.instance.addEventListener("PetPackageSortPanel_reNamePmList",this.onReNamePmList);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_BACK2STORE,this.onBack2Store);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onCurrentPetUpdate);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_SETPRI,this.onSetPri);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_SINGLE_HEALTH,this.onSingleHealth);
         NewbieEventDispatcher.getInstance().addEventListener(NewbieEvent.ON_CLICK_YABI_STRONG,this.onClickStrong);
         NewbieEventDispatcher.getInstance().addEventListener(NewbieEvent.ON_CLICK_YABI_STRONG_TAB,this.onClickStrongTab);
         NewbieEventDispatcher.getInstance().addEventListener(NewbieEvent.ON_SELECT_PET,this.onClickSelectPet);
         this.btnClose.addEventListener(MouseEvent.CLICK,this.onClose);
         this.btnOpenStudy.addEventListener(MouseEvent.CLICK,this.onOpenStudy);
         this.btnViewDetail.addEventListener(MouseEvent.CLICK,this.onOpenGennius);
         this.mutexTabGroup0.addEventListener(UIComponentEvent.MUTEX_CHANGE,this.onMutexTabGroup0Change);
         for each(_loc1_ in this.mutexTabGroup1Ary)
         {
            _loc1_.addEventListener(UIComponentEvent.MUTEX_CHANGE,this.onMutextTabGroup1Change);
         }
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_JUMP_FIRST_TAB,this.onFirstTab);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_JUMP_SECOND_TAB,this.onSecondTab);
         _loc2_ = [this.mcPetcard2,this.mcPetCardList,this.mcGodCardList,this.mcLegendSoul,this._mcDegeneratorSoul,this._mcAstralSpirit,this._mcHKPanel,this._mcYuSheList];
         this.indexManager.registerSome(_loc2_);
         for each(_loc3_ in this.mutexTabGroup0)
         {
            this.indexManager.register(_loc3_.mc);
         }
         for each(_loc4_ in this.mutexTabGroup1Ary)
         {
            for each(_loc5_ in _loc4_)
            {
               this.indexManager.register(_loc5_.mc);
            }
         }
         this.initPackageSkin();
         this.addEventListener(MouseEvent.CLICK,this.onClickPackage);
         this.updateSkillNeedBattle();
      }
      
      private function onClickPackage(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_.indexOf("btnFaZhen") > -1)
         {
            this.showFaZhen();
            return;
         }
         if(_loc2_ == "btnZhanDouLiPingFen")
         {
            this.showZhanDouLiPingFen();
            return;
         }
         if(_loc2_ == "btnChangeToNewSkill")
         {
            this.changeGQNewSkillState();
            return;
         }
      }
      
      private function changeGQNewSkillState() : void
      {
         PetPackageGQNewSkillHelper.getInstance().changeGQNewSkillState();
         PetDetailDataMap.instance.tryUpdateCachhe(this._petDataService.getSelectPetId(),false);
      }
      
      private function showZhanDouLiPingFen() : void
      {
         this.close();
         Panel_Helper.loadResAndShow("activityres/activity230602/zhandoulijianceqi/zhandoulijianceqi_code","mmo.activity230602.zhandoulijianceqi.panel.ZDLJCQ_MainPl");
      }
      
      private function showFaZhen() : void
      {
         this.close();
         Panel_Helper.loadResAndShow("activityres/activity210115/lingyufazhen/lingyufazhen_doc","mmo.activity210115.lingyufazhen.panel.LYFZ_MainPl");
      }
      
      private function initUI() : void
      {
         this.mcPetList.setData(this._objs);
         this.mcPetList.refresh2First();
         this.btnPetsort.addEventListener(MouseEvent.CLICK,this.onPetsort);
         TipsManager.getInstance().addTips(this.btnPetsort,"亚比排序");
         this.totalBattleEff.init();
      }
      
      public function showPanel() : void
      {
         if(null != this._objs)
         {
            this.initUI();
            NewbieEventDispatcher.getInstance().dispatchEvent(new NewbieEvent(NewbieEvent.ON_CLICK_YABI_PACKAGE,{
               "before":true,
               "panel":this
            }));
            ModalDialogManager.getInstance().addModalDialog(this,AlignType.NONE,PanelEffect.NONE,true,0,0,true);
            NewbieEventDispatcher.getInstance().dispatchEvent(new NewbieEvent(NewbieEvent.ON_CLICK_YABI_PACKAGE,{
               "before":false,
               "panel":this
            }));
            CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("PetPackagePanelOpen",{}));
         }
      }
      
      public function closePanel() : void
      {
         this.close();
      }
      
      public function dispose() : void
      {
         this.disposeEvent();
      }
      
      public function setData(param1:Array, param2:int, param3:Array) : void
      {
         this._objs = param1;
         this.setNewAddPmData(param2,param3);
      }
      
      public function setYuSheList(param1:Array) : void
      {
         this.setNewAddPmData(this._pmSelectIndex,param1);
      }
      
      private function setNewAddPmData(param1:int, param2:Array) : void
      {
         this._pmSelectIndex = param1;
         this._pmListName = param2;
         this.updateYuSheZhenRongView();
      }
      
      private function effChangeUpdate(param1:PetDataServiceEvent) : void
      {
         this.updateYuSheZhenRongView();
      }
      
      private function updateYuSheZhenRongView() : void
      {
         this._mcYuSheList.updateYuSheZhenRongView(this._pmSelectIndex,this._pmListName);
      }
      
      public function updateData(param1:Array, param2:int, param3:Array) : void
      {
         this._objs = param1;
         this.setNewAddPmData(param2,param3);
         this.mcPetList.setData(this._objs);
         this.mcPetList.refreshCurrent();
      }
      
      private function onClickStrong(param1:NewbieEvent) : void
      {
         var _loc2_:Function = param1.params.callback;
         NewbieEventDispatcher.getInstance().removeEventListener(NewbieEvent.ON_CLICK_YABI_STRONG,this.onClickStrong);
         this.mutexTabGroup0.setSelected(1);
         this.onMutexTabGroup0Change(new UIComponentEvent(UIComponentEvent.MUTEX_CHANGE,{"index":1}));
         _loc2_.apply();
      }
      
      private function onClickStrongTab(param1:NewbieEvent) : void
      {
         var _loc2_:Function = param1.params.callback;
         var _loc3_:int = int(param1.params.clickIndex);
         NewbieEventDispatcher.getInstance().removeEventListener(NewbieEvent.ON_CLICK_YABI_STRONG_TAB,this.onClickStrong);
         this.mutexTabGroup1Ary[this.mutexTabGroup1Ary.length - 1].setSelected(_loc3_);
         this.onMutextTabGroup1Change(new UIComponentEvent(UIComponentEvent.MUTEX_CHANGE,{"index":_loc3_}));
         _loc2_.apply();
      }
      
      private function onClickSelectPet(param1:NewbieEvent) : void
      {
         var _loc2_:Function = param1.params.callback;
         var _loc3_:int = int(param1.params.pId);
         NewbieEventDispatcher.getInstance().removeEventListener(NewbieEvent.ON_CLICK_YABI_STRONG_TAB,this.onClickStrong);
         this.mcPetList.setSelcectPetById(_loc3_);
         _loc2_.apply();
      }
      
      private function onSort(param1:Event) : void
      {
         this.mcPetList.refresh2First();
      }
      
      private function onReNamePmList(param1:CommonEvent) : void
      {
         var _loc2_:int = int(param1.params.index);
         this._mcYuSheList.updateOne(_loc2_,this._pmListName);
      }
      
      private function onBack2Store(param1:PetPackageEvent) : void
      {
         var _loc2_:int = int(param1.params.id);
         var _loc3_:int = int(param1.params.index);
         var _loc4_:int = this.getIndexById(_loc2_,_loc3_);
         if(-1 != _loc4_)
         {
            this._objs.splice(_loc4_,1);
            PetClient.instance.setPmBattleList(this.getPMBattleList());
            this.mcPetList.setData(this._objs);
            this.mcPetList.refresh2First();
         }
      }
      
      private function onSingleHealth(param1:PetPackageEvent) : void
      {
         var _loc5_:Object = null;
         var _loc2_:int = int(param1.params.pi);
         var _loc3_:int = int(param1.params.index);
         var _loc4_:int = this.getIndexById(_loc2_,_loc3_);
         if(-1 != _loc4_)
         {
            _loc5_ = this._objs[_loc4_];
            _loc5_.pmSView.c0 = _loc5_.pmSView.s0;
            this.mcPetList.refreshCurrent();
         }
      }
      
      private function onSetPri(param1:PetPackageEvent) : void
      {
         var _loc2_:int = int(param1.params.id);
         var _loc3_:int = int(param1.params.index);
         var _loc4_:int = this.getIndexById(_loc2_,_loc3_);
         if(-1 != _loc4_)
         {
            this.exchangeObjectArray(0,_loc4_);
         }
      }
      
      private function getPMBattleList() : String
      {
         var _loc3_:Object = null;
         var _loc1_:String = "";
         var _loc2_:PetBriefInfo = new PetBriefInfo();
         for each(_loc3_ in this._objs)
         {
            _loc2_.parseInfo(_loc3_);
            _loc1_ += _loc2_.id + "#";
         }
         return _loc1_.substr(0,_loc1_.length - 1);
      }
      
      private function getIndexById(param1:int, param2:int = 0) : int
      {
         var _loc4_:int = 0;
         var _loc5_:Object = null;
         var _loc3_:PetBriefInfo = new PetBriefInfo();
         _loc3_.parseInfo(this._objs[param2]);
         if(_loc3_.id == param1)
         {
            return param2;
         }
         _loc4_ = 0;
         while(_loc4_ < this._objs.length)
         {
            _loc5_ = this._objs[_loc4_];
            _loc3_.parseInfo(_loc5_);
            if(_loc3_.id == param1)
            {
               return _loc4_;
            }
            _loc4_++;
         }
         return -1;
      }
      
      private function exchangeObjectArray(param1:int, param2:int) : void
      {
         var _loc3_:Object = this._objs[param1];
         this._objs[param1] = this._objs[param2];
         this._objs[param2] = _loc3_;
         this.mcPetList.refresh2First();
      }
      
      private function onCurrentPetUpdate(param1:PetPackageEvent) : void
      {
         var _loc2_:int = int(param1.params.id);
         var _loc3_:PetDetailedInfo = PetDetailDataMap.instance.getPetDetailInfo(_loc2_);
         var _loc4_:int = this.getPetIndex(_loc2_);
         if(0 == _loc4_)
         {
            this.mcControlBar.updatePetInfo(_loc3_,true,_loc4_,this._objs.length);
         }
         else
         {
            this.mcControlBar.updatePetInfo(_loc3_,false,_loc4_,this._objs.length);
         }
         this.fourthTabIndex = this.getFourthTabIndex(_loc3_.raceId);
         this.setTabVisible();
         var _loc5_:MutexAry = this.mutexTabGroup1Ary[0] as MutexAry;
         var _loc6_:int = int(_loc5_.getSelectedIndex());
         if(_loc6_ > 2 && _loc6_ != this.fourthTabIndex)
         {
            _loc5_.setSelected(this.fourthTabIndex);
         }
         var _loc7_:MutexAry = this.mutexTabGroup1Ary[2] as MutexAry;
         var _loc8_:int = int(_loc7_.getSelectedIndex());
         if(_loc8_ == 2 && (this.isLegendPet(_loc3_.raceId) || this.isDegeneratorPet(_loc3_.raceId) || this.isXinghuiPet(_loc3_.raceId) || this.isCurHKCardPet()))
         {
            _loc7_.setSelected(1);
         }
         if(_loc8_ == 3 && !this.isDegeneratorPet(_loc3_.raceId))
         {
            _loc7_.setSelected(1);
         }
         if(_loc8_ == 4 && !this.isXinghuiPet(_loc3_.raceId))
         {
            _loc7_.setSelected(1);
         }
         if(_loc8_ == 0 && (this.isXinghuiPet(_loc3_.raceId) || this.isCurHKCardPet()))
         {
            _loc7_.setSelected(1);
         }
         if(_loc8_ == 5 && !this.isCurSelectShenbinPet())
         {
            _loc7_.setSelected(1);
         }
         if(_loc8_ == 4 && this.isCurSelectShenbinPet())
         {
            _loc7_.setSelected(1);
         }
         if(_loc8_ == 6 && !this.isCurHKCardPet())
         {
            _loc7_.setSelected(1);
         }
         if(_loc8_ == 7 && !this.isCurTotePet())
         {
            _loc7_.setSelected(1);
         }
         if(_loc8_ == 8 && !this.isCurTotePet())
         {
            _loc7_.setSelected(1);
         }
         this.setTabInfoVisible();
         this.updateSkillNeedBattle();
      }
      
      private function updateSkillNeedBattle() : void
      {
         var _loc1_:MovieClip = this.mcskill.mcSkillLevel;
         var _loc2_:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         var _loc3_:int = int(_loc2_.getSelectPetId());
         if(_loc3_ < 0 || PetPackageGQNewSkillHelper.getInstance().isShowingGQNewSkill())
         {
            _loc1_.visible = false;
            return;
         }
         var _loc4_:PetBriefInfo = _loc2_.getPetByPetId(_loc3_);
         if(_loc4_ == null)
         {
            _loc1_.visible = false;
            return;
         }
         var _loc5_:IPetBattleEffDataService = ServiceContainer.getService(IPetBattleEffDataService) as IPetBattleEffDataService;
         var _loc6_:int = int(_loc5_.getPetBattleEffectiveness(_loc4_));
         var _loc7_:int = int(Pet_Helper.getNextSkillLevelNeedBattle(_loc4_.raceId,_loc6_));
         if(_loc7_ < 0)
         {
            _loc1_.visible = false;
            return;
         }
         _loc1_.visible = true;
         _loc1_.gotoAndStop(_loc7_ > 0 ? 2 : 1);
         if(_loc7_ > 0)
         {
            ActComHelper.setTxtValue(_loc1_,"txtNeedBattle",_loc7_ + "");
         }
      }
      
      private function setTabVisible() : void
      {
         var _loc13_:MovieClip = null;
         var _loc1_:* = this.mutexTabGroup0.getSelectedIndex() == 0;
         var _loc2_:int = 3;
         while(_loc2_ < this.mutexInfos[0].length - 1)
         {
            _loc13_ = this.getChildByName("btn0_" + _loc2_.toString()) as MovieClip;
            _loc13_.visible = _loc1_ && this.fourthTabIndex == _loc2_;
            _loc2_++;
         }
         var _loc3_:* = this.mutexTabGroup0.getSelectedIndex() == 1;
         var _loc4_:* = this.mutexTabGroup0.getSelectedIndex() == 2;
         var _loc5_:MovieClip = this.getChildByName("btn2_0") as MovieClip;
         _loc5_.visible = _loc4_ && !this.isCurSelectXinghuiPet() && !this.isCurHKCardPet();
         var _loc6_:MovieClip = this.getChildByName("btn2_2") as MovieClip;
         _loc6_.visible = _loc4_ && !this.isCurSelectLegendPet() && !this.isCurSelectDeggeneratorPet() && !this.isCurSelectXinghuiPet() && !this.isCurHKCardPet();
         var _loc7_:MovieClip = this.getChildByName("btn2_3") as MovieClip;
         _loc7_.visible = _loc4_ && this.isCurSelectDeggeneratorPet();
         var _loc8_:MovieClip = this.getChildByName("btn2_4") as MovieClip;
         _loc8_.visible = _loc4_ && this.isCurSelectXinghuiPet() && !this.isCurSelectShenbinPet();
         var _loc9_:MovieClip = this.getChildByName("btn2_5") as MovieClip;
         _loc9_.visible = _loc4_ && this.isCurSelectShenbinPet();
         var _loc10_:MovieClip = this.getChildByName("btn2_6") as MovieClip;
         if(_loc10_)
         {
            _loc10_.visible = _loc4_ && this.isCurHKCardPet();
         }
         var _loc11_:MovieClip = this.getChildByName("btn2_7") as MovieClip;
         if(_loc11_)
         {
            _loc11_.visible = _loc4_ && this.isCurTotePet();
         }
         var _loc12_:MovieClip = this.getChildByName("btn2_8") as MovieClip;
         if(_loc12_)
         {
            _loc12_.visible = _loc4_ && this.isCurTotePet();
         }
      }
      
      public function getTab0Index() : int
      {
         return this.mutexTabGroup0.getSelectedIndex();
      }
      
      private function getTab1Index() : int
      {
         var _loc1_:int = this.getTab0Index();
         return int(this._curTab1Map[_loc1_]);
      }
      
      public function getSelectRaceId() : int
      {
         var _loc3_:PetBriefInfo = null;
         var _loc1_:int = -1;
         var _loc2_:int = int(this._petDataService.getSelectPetId());
         if(_loc2_ > 0)
         {
            _loc3_ = this._petDataService.getPetByPetId(_loc2_);
            _loc1_ = _loc3_ != null ? int(_loc3_.raceId) : _loc1_;
         }
         return _loc1_;
      }
      
      private function getPetIndex(param1:int) : int
      {
         var _loc2_:PetBriefInfo = new PetBriefInfo();
         var _loc3_:int = 0;
         while(_loc3_ < this._objs.length)
         {
            _loc2_.parseInfo(this._objs[_loc3_]);
            if(_loc2_.id == param1)
            {
               return _loc3_;
            }
            _loc3_++;
         }
         return -1;
      }
      
      private function getFourthTabIndex(param1:int) : int
      {
         var _loc2_:int = 0;
         var _loc3_:PMData = this._pmService.getOperationPM(param1).pmData;
         if(AoYiConfig.isAoYiPet(param1))
         {
            _loc2_ = 6;
         }
         else if(BargainPetConfig.isBargainPet(param1))
         {
            _loc2_ = 5;
         }
         else if(Boolean(PetChangeViewConfig.isChangeViewPet(param1)) && !_loc3_.isDegeneratorPM() && !_loc3_.isXinghuiPM())
         {
            _loc2_ = 4;
         }
         else if(PetPackageHelper.isHolyPet(param1))
         {
            _loc2_ = 3;
         }
         return _loc2_;
      }
      
      private function onPetsort(param1:MouseEvent) : void
      {
         var self:* = undefined;
         var e:MouseEvent = param1;
         if(null == this._objs || this._objs.length < 2)
         {
            NewDialog.showSucceedMessage("你的背包中的亚比少于2只，不能进行排序哦！");
            return;
         }
         PetArrayRefresher.updatePetsObj(this._objs);
         ProgressFullSprite.show();
         self = this;
         ServiceContainer.instance.tryGetService(IPetPackageSort,function(param1:IPetPackageSort, param2:Object):void
         {
            ProgressFullSprite.close();
            param1.showPanelByData({
               "data":self._objs,
               "index":self._pmSelectIndex,
               "listName":self._pmListName
            });
         });
         SundriesClient.logButton(6747);
         SundriesClient.logEvent(15517);
      }
      
      private function onMutexTabGroup0Change(param1:UIComponentEvent) : void
      {
         var _loc2_:int = int(param1.params.index);
         ViewIndexHelper.move2top(this.mutexTabGroup0.getSelected().mc);
         var _loc3_:MutexAry = this.mutexTabGroup1Ary[_loc2_] as MutexAry;
         this.updateTabGroupVisible();
         this.setTabInfoVisible();
         this.setTabVisible();
         SundriesClient.logButton(6736 + _loc2_);
         SundriesClient.logEvent(15510 + _loc2_);
         if(_loc2_ == 1)
         {
            CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("NewHeroLife_Click_Yabinengli",{}));
         }
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_INFO_TAB_CHANGED,{
            "firstTab":this.getTab0Index(),
            "secondTab":this.getTab1Index()
         }));
      }
      
      private function updateTabGroupVisible() : void
      {
         var _loc3_:MutexAry = null;
         var _loc1_:int = int(this.mutexTabGroup0.getSelectedIndex());
         var _loc2_:int = 0;
         while(_loc2_ < this.mutexTabGroup1Ary.length)
         {
            _loc3_ = this.mutexTabGroup1Ary[_loc2_] as MutexAry;
            _loc3_.setVisible(_loc1_ == _loc2_);
            _loc2_++;
         }
      }
      
      private function onMutextTabGroup1Change(param1:UIComponentEvent) : void
      {
         var _loc2_:int = int(param1.params.index);
         this._curTab1Map[this.getTab0Index()] = _loc2_;
         var _loc3_:MutexAry = param1.currentTarget as MutexAry;
         this.setTabInfoVisible();
         var _loc4_:int = int(this.mutexTabGroup0.getSelectedIndex());
         var _loc5_:int = 0 == _loc4_ ? 6738 : 6741;
         var _loc6_:int = 0 == _loc4_ ? 15512 : 15527;
         if(_loc2_ >= 3)
         {
            SundriesClient.logButton(_loc5_ + 3);
            SundriesClient.logEvent(_loc6_ + 3);
         }
         else
         {
            SundriesClient.logButton(_loc5_ + _loc2_);
            SundriesClient.logEvent(_loc6_ + _loc2_);
         }
         if(_loc4_ == 0 && _loc2_ == 1)
         {
            NewbieEventDispatcher.getInstance().dispatchEvent(new NewbieEvent(NewbieEvent.ON_CLICK_YABINENGLI,{}));
         }
         else if(_loc4_ == 1 && _loc2_ == 1)
         {
            NewbieEventDispatcher.getInstance().dispatchEvent(new NewbieEvent(NewbieEvent.ON_CLICK_YABIXUEXILI,{}));
         }
         else if(_loc4_ == 1 && _loc2_ == 2)
         {
            NewbieEventDispatcher.getInstance().dispatchEvent(new NewbieEvent(NewbieEvent.ON_CLICK_YABITIANFU,{}));
         }
         else if(_loc4_ == 1 && _loc2_ == 3)
         {
            NewbieEventDispatcher.getInstance().dispatchEvent(new NewbieEvent(NewbieEvent.ON_CLICK_YABIZHUANGBEI,{}));
         }
         else if(_loc4_ == 1 && _loc2_ == 4)
         {
            CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("NewHeroLife_Click_Yabitexing",{}));
         }
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_INFO_TAB_CHANGED,{
            "firstTab":this.getTab0Index(),
            "secondTab":this.getTab1Index()
         }));
      }
      
      private function onFirstTab(param1:PetPackageEvent) : void
      {
         var _loc2_:int = int(param1.params.index);
         if(this.mutexTabGroup0.getSelectedIndex() != _loc2_)
         {
            this.mutexTabGroup0.setSelected(_loc2_);
            this.updateTabGroupVisible();
            this.setTabInfoVisible();
            this.setTabVisible();
            PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_INFO_TAB_CHANGED,{
               "firstTab":this.getTab0Index(),
               "secondTab":this.getTab1Index()
            }));
         }
      }
      
      private function onSecondTab(param1:PetPackageEvent) : void
      {
         var _loc2_:int = int(this.mutexTabGroup0.getSelectedIndex());
         var _loc3_:MutexAry = this.mutexTabGroup1Ary[_loc2_] as MutexAry;
         var _loc4_:int = int(param1.params.index);
         if(_loc3_.getSelectedIndex() != _loc4_)
         {
            _loc3_.setSelected(_loc4_);
            this.setTabVisible();
            this.setTabInfoVisible();
            PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_INFO_TAB_CHANGED,{
               "firstTab":this.getTab0Index(),
               "secondTab":this.getTab1Index()
            }));
         }
      }
      
      private function setTabInfoVisible() : void
      {
         var _loc8_:Array = null;
         var _loc9_:int = 0;
         var _loc10_:Boolean = false;
         var _loc1_:int = int(this.mutexTabGroup0.getSelectedIndex());
         var _loc2_:int = int(MutexAry(this.mutexTabGroup1Ary[_loc1_]).getSelectedIndex());
         var _loc3_:int = 0;
         while(_loc3_ < this.mutexTabGroup1Ary.length)
         {
            _loc8_ = this.mutexInfos[_loc3_] as Array;
            _loc9_ = 0;
            while(_loc9_ < _loc8_.length)
            {
               _loc10_ = _loc3_ == _loc1_ && _loc9_ == _loc2_;
               if(_loc10_)
               {
                  IPetView(_loc8_[_loc9_]).updateUI();
                  DisplayObject(_loc8_[_loc9_]).visible = true;
               }
               else
               {
                  IPetView(_loc8_[_loc9_]).removeUI();
                  DisplayObject(_loc8_[_loc9_]).visible = false;
               }
               _loc9_++;
            }
            _loc3_++;
         }
         var _loc4_:* = _loc1_ == 0;
         var _loc5_:Boolean = this.isCurSelectLegendPet();
         var _loc6_:Boolean = this.isCurSelectDeggeneratorPet();
         var _loc7_:Boolean = this.isCurSelectXinghuiPet();
         this.mcPetcard2.visible = !(_loc5_ || _loc6_ || _loc7_ || this.isCurHKCardPet());
         this.mcLegendSoul.visible = _loc5_;
         this._mcDegeneratorSoul.visible = _loc6_;
         this._mcAstralSpirit.visible = _loc7_ && !this.isCurSelectShenbinPet() && !this.isCurHKCardPet();
         this.mcGodCardList.visible = this.isCurSelectShenbinPet();
      }
      
      private function isCurHKCardPet() : Boolean
      {
         var _loc2_:PetBriefInfo = null;
         var _loc1_:int = int(this._petDataService.getSelectPetId());
         if(_loc1_ > 0)
         {
            _loc2_ = this._petDataService.getPetByPetId(_loc1_);
            if(_loc2_)
            {
               return this._pmService.getOperationPM(_loc2_.raceId).pmData.isGQPM();
            }
            return false;
         }
         return false;
      }
      
      private function isCurTotePet() : Boolean
      {
         var _loc2_:PetBriefInfo = null;
         var _loc1_:int = int(this._petDataService.getSelectPetId());
         if(_loc1_ > 0)
         {
            _loc2_ = this._petDataService.getPetByPetId(_loc1_);
            if(_loc2_)
            {
               return Boolean(this._pmService.getOperationPM(_loc2_.raceId).pmData.isGQPM()) && _loc2_.usingGQSkillType == 1;
            }
            return false;
         }
         return false;
      }
      
      private function isCurSelectShenbinPet() : Boolean
      {
         var _loc2_:PetBriefInfo = null;
         var _loc1_:int = int(this._petDataService.getSelectPetId());
         if(_loc1_ > 0)
         {
            _loc2_ = this._petDataService.getPetByPetId(_loc1_);
            if(_loc2_)
            {
               return XinghuiPetType.isShenbinPet(_loc2_.raceId);
            }
            return false;
         }
         return false;
      }
      
      private function isCurSelectLegendPet() : Boolean
      {
         var _loc2_:PetBriefInfo = null;
         var _loc1_:int = int(this._petDataService.getSelectPetId());
         if(_loc1_ > 0)
         {
            _loc2_ = this._petDataService.getPetByPetId(_loc1_);
            if(_loc2_)
            {
               return this.isLegendPet(_loc2_.raceId);
            }
            return false;
         }
         return false;
      }
      
      private function isLegendPet(param1:int) : Boolean
      {
         return this._pmService.getOperationPM(param1).pmData.isLegendPM();
      }
      
      private function isCurSelectDeggeneratorPet() : Boolean
      {
         var _loc2_:PetBriefInfo = null;
         var _loc1_:int = int(this._petDataService.getSelectPetId());
         if(_loc1_ > 0)
         {
            _loc2_ = this._petDataService.getPetByPetId(_loc1_);
            if(_loc2_)
            {
               return this.isDegeneratorPet(_loc2_.raceId);
            }
            return false;
         }
         return false;
      }
      
      private function isDegeneratorPet(param1:int) : Boolean
      {
         return this._pmService.getOperationPM(param1).pmData.isDegeneratorPM();
      }
      
      private function isCurSelectXinghuiPet() : Boolean
      {
         var _loc2_:PetBriefInfo = null;
         var _loc1_:int = int(this._petDataService.getSelectPetId());
         if(_loc1_ > 0)
         {
            _loc2_ = this._petDataService.getPetByPetId(_loc1_);
            if(_loc2_)
            {
               return this.isXinghuiPet(_loc2_.raceId);
            }
            return false;
         }
         return false;
      }
      
      private function isXinghuiPet(param1:int) : Boolean
      {
         return this._pmService.getOperationPM(param1).pmData.isXinghuiPM();
      }
      
      private function onClose(param1:Event) : void
      {
         this.close();
      }
      
      private function onOpenStudy(param1:Event) : void
      {
         this.close();
         Panel_Helper.loadResAndShow("activityres/activity180914/newlearnbattlefield/newlearn_code","mmo.activity180914.newlearnbattlefield.panel.NewLearn_MainPanel");
      }
      
      private function onOpenGennius(param1:Event) : void
      {
         var _loc2_:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         var _loc3_:int = int(_loc2_.getSelectPetId());
         var _loc4_:int = this.getPetIndex(_loc3_);
         this.close();
         Panel_Helper.loadResAndShow("activityres/activity180929/petgenuis/petgenuis_doc","mmo.activity180929.petgenuis.PG_Shower",{"chooseIndex":_loc4_});
      }
      
      private function close() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
         this.disposeEvent();
      }
      
      private function disposeEvent() : void
      {
         var _loc1_:MutexAry = null;
         var _loc2_:Array = null;
         var _loc3_:IDispose = null;
         this.indexManager.dispose();
         if(this._petDataService != null)
         {
            this._petDataService.removeEventListener(PetDataServiceEvent.ON_HIGHTES_BATTLE_EFF_UPDATE,this.effChangeUpdate);
         }
         this.removeEventListener(MouseEvent.CLICK,this.onClickPackage);
         for each(_loc1_ in this.mutexTabGroup1Ary)
         {
            _loc1_.dispose();
            _loc1_.removeEventListener(UIComponentEvent.MUTEX_CHANGE,this.onMutextTabGroup1Change);
         }
         this.mutexTabGroup0.removeEventListener(UIComponentEvent.MUTEX_CHANGE,this.onMutexTabGroup0Change);
         this.btnClose.removeEventListener(MouseEvent.CLICK,this.onClose);
         this.btnOpenStudy.removeEventListener(MouseEvent.CLICK,this.onOpenStudy);
         this.btnViewDetail.removeEventListener(MouseEvent.CLICK,this.onOpenGennius);
         TipsManager.getInstance().removeTips(this.btnClose);
         this.btnPetsort.removeEventListener(MouseEvent.CLICK,this.onPetsort);
         this._objs = null;
         this.mcPetCardList.dispose();
         this.mcGodCardList.dispose();
         for each(_loc2_ in this.mutexInfos)
         {
            for each(_loc3_ in _loc2_)
            {
               _loc3_.dispose();
            }
         }
         (this.mcviewcontroller as SimpleViewController).dispose();
         this.totalBattleEff.dispose();
         this.mutexTabGroup0.dispose();
         this.mcBigicon.dispose();
         this.mcPetList.dispose();
         this.mcControlBar.dispose();
         this.mcPetcard2.dispose();
         this.mc_petShare.dispose();
         this.mc_fightgifticon.dispose();
         this.mcLegendSoul.dispose();
         this._mcDegeneratorSoul.dispose();
         this._mcAstralSpirit.dispose();
         this._mcPetCorpsIcon.dispose();
         this._mcPetStampIcon.dispose();
         this._mcSummonerIcon.dispose();
         this._mcPetHunKaIcon.dispose();
         this._mcPetToteIcon.dispose();
         this._mcTerritoryStoreIcon.dispose();
         this._mcYuSheList.dispose();
         this._itemRedDotHandler.dispose();
         this._gqPetPresetIcon.dispose();
         this._gqShenBingBtnMc.dispose();
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_JUMP_SECOND_TAB,this.onSecondTab);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_JUMP_FIRST_TAB,this.onFirstTab);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onCurrentPetUpdate);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_SETPRI,this.onSetPri);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_SINGLE_HEALTH,this.onSingleHealth);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_BACK2STORE,this.onBack2Store);
         CommonEventDispatcher.instance.removeEventListener("PetPackageSortPanel_pmBattleList",this.onSort);
         CommonEventDispatcher.instance.removeEventListener("PetPackageSortPanel_reNamePmList",this.onReNamePmList);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_PANEL_CLOSED,this.onClose);
         NewbieEventDispatcher.getInstance().removeEventListener(NewbieEvent.ON_CLICK_YABI_STRONG,this.onClickStrong);
         NewbieEventDispatcher.getInstance().removeEventListener(NewbieEvent.ON_CLICK_YABI_STRONG_TAB,this.onClickStrongTab);
         NewbieEventDispatcher.getInstance().removeEventListener(NewbieEvent.ON_SELECT_PET,this.onClickSelectPet);
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_SERVICE_DISPOSE,{}));
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("on_pet_package_disposed",{}));
         PackageSkinManager.instance.dispose();
         PackageCacheManager.instance.dispose();
         GCManager.instance.disposeSpecialResource();
      }
   }
}

