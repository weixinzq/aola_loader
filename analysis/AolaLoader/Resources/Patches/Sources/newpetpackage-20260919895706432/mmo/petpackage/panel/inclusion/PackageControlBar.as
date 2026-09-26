package mmo.petpackage.panel.inclusion
{
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.external.ExternalInterface;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.act_operation.PetFunctionShortcut;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowDataPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.callback.FunCallInfo;
   import mmo.interfaces.commonpanel.ICommonPanelService;
   import mmo.interfaces.commonpanel.MessagePanelParam;
   import mmo.interfaces.degenerator.DegeneratorPetType;
   import mmo.interfaces.fly.IFlyService;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.material.fightflauntresource.IFightFlauntResourceService;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetClothesMap;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.pet.data.PetRideInfo;
   import mmo.interfaces.pet.data.PetRideInfosMap;
   import mmo.interfaces.pet.data.skin.IPetSkinDataService;
   import mmo.interfaces.pet.data.skin.PetSkinInfo;
   import mmo.interfaces.pet.follow.PetFollowEvent;
   import mmo.interfaces.pet.petword.PetWordConfig;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.pet.ride.IRideService;
   import mmo.interfaces.secondpwd.ISecondPwdService;
   import mmo.loader.common.datastructures.ResourceObject;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.helper.PetPackageHelper;
   import mmo.petpackage.controller.helper.SetPetBackStoreHelper;
   import mmo.petpackage.controller.helper.SetPetFollowHelper;
   import mmo.petpackage.controller.helper.SetPetHealthHelper;
   import mmo.petpackage.controller.helper.SetPetPrimaryHelper;
   import mmo.petpackage.controller.helper.SetPetRideHelper;
   import mmo.petpackage.controller.skin.PackageSkinManager;
   import mmo.petpackage.controller.skin.constant.Classify;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.service.PetPackageService;
   import mmo.play.activity.framework.util.LinkUtil;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.activity.helper.Pet_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActMaterialLoader;
   import mmo.play.actthings.helper.ActTipsMc;
   import mmo.play.actthings.obj.ActArrHelper;
   import mmo.play.guangqi.GuangQiIconHandler;
   import mmo.play.guangqi.GuangQiIconOpenType;
   import mmo.play.xinghui.XingHuiIconEvent;
   import mmo.play.xinghui.XingHuiIconHandler;
   import mmo.play.xinghui.XingHuiIconOpenType;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol845")]
   public class PackageControlBar extends Sprite implements IDispose
   {
      
      private static const XING_TAI_BIAN_HUA_BU_KE_JIAN_PETS:Array = [3996,4016,4220,4221,4222,4223,4224,4225];
      
      public var btnCaiDan:SimpleButton;
      
      public var btnChangeView:SimpleButton;
      
      public var btnDingzhi:SimpleButton;
      
      public var btnPetWord:SimpleButton;
      
      public var btn_backstore:SimpleButton;
      
      public var btn_health:SimpleButton;
      
      public var btn_setpri:SimpleButton;
      
      public var btn_shareexp:SimpleButton;
      
      public var btnchaowei:SimpleButton;
      
      public var btnjuejie:SimpleButton;
      
      public var btnmingyun:SimpleButton;
      
      public var btnpo:SimpleButton;
      
      public var btnshengti:SimpleButton;
      
      public var btnshoulie:SimpleButton;
      
      public var btnshuangsheng:SimpleButton;
      
      public var btnskinchange:SimpleButton;
      
      public var btnstorage:SimpleButton;
      
      public var btnsummon:SimpleButton;
      
      public var btntalk:SimpleButton;
      
      public var btnwangzhe:SimpleButton;
      
      public var btnyingxiong:SimpleButton;
      
      public var mcChangePre:MovieClip;
      
      public var mcChangeViewRedDot:MovieClip;
      
      public var mcDingzhiTips:MovieClip;
      
      public var mcQGShenBing:MovieClip;
      
      public var mc_follow:MovieClip;
      
      public var mc_ride:MovieClip;
      
      public var mchaibao:MovieClip;
      
      public var mchandtalk:MovieClip;
      
      public var mchuandong:MovieClip;
      
      public var newIconPos:MovieClip;
      
      private var petDataService:IPetDataService = null;
      
      private var petRideService:IRideService = null;
      
      private var _pmSvr:IPMService = null;
      
      private var curFollowPetId:int = -1;
      
      private var curRidePetId:int = -1;
      
      private var hasRideCard:Boolean = false;
      
      private var ridable:Boolean = false;
      
      private var btnSetpri:SimpleButton = null;
      
      private var mcFollow:MovieClip = null;
      
      private var mcRide:MovieClip = null;
      
      private var btnBackstore:SimpleButton = null;
      
      private var btnHealth:SimpleButton = null;
      
      private var btnShareExp:SimpleButton = null;
      
      private var _skinChangeBtn:SimpleButton = null;
      
      private var _summonBtn:SimpleButton = null;
      
      private var _shengtiBtn:SimpleButton = null;
      
      private var _shuangshengBtn:SimpleButton = null;
      
      private var _yingxiongBtn:SimpleButton = null;
      
      private var _wangzheBtn:SimpleButton = null;
      
      private var _chaoweiBtn:SimpleButton = null;
      
      private var _poBtn:SimpleButton = null;
      
      private var _juejieBtn:SimpleButton = null;
      
      private var _shoulieBtn:SimpleButton = null;
      
      private var _mingyunBtn:SimpleButton = null;
      
      private var _mcChangePre:MovieClip = null;
      
      private var _qiyuanTipsPanel:XinghuiQiyuanTipsPanel = null;
      
      private var _xinghuichaoweiMc:MovieClip = null;
      
      private var pbi:PetDetailedInfo = null;
      
      private var _isPri:Boolean = false;
      
      private var _index:int = -1;
      
      private var _totalLenght:int = -1;
      
      private var _skindataservice:IPetSkinDataService = ServiceContainer.getService(IPetSkinDataService) as IPetSkinDataService;
      
      private var _petSkillMesSvr:IPetSkillMesService = ServiceContainer.getService(IPetSkillMesService) as IPetSkillMesService;
      
      private var _petDataSvr:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
      
      private var _mcHuandong:MovieClip;
      
      private var _iconHandler:XingHuiIconHandler;
      
      private var _gqIconhandler:GuangQiIconHandler;
      
      private var _gqShenBingMc:MovieClip;
      
      private var _gqShenBingContainer:MovieClip;
      
      private var _firstTab:int = 0;
      
      private var _showCardList:Boolean = LocalStore.getValue(PetPackageEvent.EQUIP_SHOW_KEY) ? Boolean(LocalStore.getValue(PetPackageEvent.EQUIP_SHOW_KEY)["showCard"]) : true;
      
      public function PackageControlBar()
      {
         super();
         this.initPars();
         this.initFuns();
         this._iconHandler = new XingHuiIconHandler(XingHuiIconOpenType.type_petpackage,this.newIconPos as MovieClip);
         this._iconHandler.setMcPosVisible();
         this._gqIconhandler = new GuangQiIconHandler(GuangQiIconOpenType.type_petpackage,this.newIconPos as MovieClip);
         this._gqIconhandler.setMcPosVisible();
      }
      
      private function initPars() : void
      {
         this.petDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         this.petRideService = ServiceContainer.getService(IRideService) as IRideService;
         this._pmSvr = ServiceContainer.getService(IPMService) as IPMService;
         this.curFollowPetId = this.petDataService.getCurFollowPetId();
         this.curRidePetId = this.petRideService.getMyRidePetId;
         this.btnSetpri = this.btn_setpri as SimpleButton;
         this.mcFollow = this.mc_follow as MovieClip;
         this.mcFollow.gotoAndStop(1);
         this.btnHealth = this.btn_health as SimpleButton;
         TipsManager.getInstance().addTips(this.btnHealth,"治疗亚比",100);
         this.mcRide = this.mc_ride as MovieClip;
         this.mcRide.gotoAndStop(1);
         this.btnShareExp = this.btn_shareexp as SimpleButton;
         TipsManager.getInstance().addTips(this.btnShareExp,"分配经验",100);
         this.btnBackstore = this.btn_backstore as SimpleButton;
         TipsManager.getInstance().addTips(this.btnBackstore,"放回仓库",100);
         this._skinChangeBtn = this.btnskinchange as SimpleButton;
         TipsManager.getInstance().addTips(this._skinChangeBtn,"皮肤切换",100);
         this._summonBtn = this.btnsummon as SimpleButton;
         TipsManager.getInstance().addTips(this._summonBtn,"通灵召唤",100);
         this._shengtiBtn = this.btnshengti as SimpleButton;
         TipsManager.getInstance().addTips(this._shengtiBtn,"圣体",100);
         this._shuangshengBtn = this.btnshuangsheng as SimpleButton;
         TipsManager.getInstance().addTips(this._shuangshengBtn,"双生",100);
         this._yingxiongBtn = this.btnyingxiong as SimpleButton;
         TipsManager.getInstance().addTips(this._yingxiongBtn,"英雄",100);
         this._wangzheBtn = this.btnwangzhe as SimpleButton;
         TipsManager.getInstance().addTips(this._wangzheBtn,"王者",100);
         this._chaoweiBtn = this.btnchaowei as SimpleButton;
         TipsManager.getInstance().addTips(this._chaoweiBtn,"超维",100);
         this._poBtn = this.btnpo as SimpleButton;
         TipsManager.getInstance().addTips(this._poBtn,"破军",100);
         this._juejieBtn = this.btnjuejie as SimpleButton;
         TipsManager.getInstance().addTips(this._juejieBtn,"绝界",100);
         this._shoulieBtn = this.btnshoulie as SimpleButton;
         TipsManager.getInstance().addTips(this._shoulieBtn,"狩猎",100);
         this._mingyunBtn = this.btnmingyun as SimpleButton;
         TipsManager.getInstance().addTips(this._mingyunBtn,"命运",100);
         TipsManager.getInstance().addTips(this.mchandtalk,"鼠标点击皮肤互动，有动作+语音哦！");
         this._gqShenBingMc = this.mcQGShenBing as MovieClip;
         this._gqShenBingContainer = this._gqShenBingMc.getChildByName("mcShenBingContainer") as MovieClip;
         this._mcHuandong = this.mchuandong;
         this.refreshNewIconPos();
      }
      
      private function updateCaiDanBtn() : void
      {
         this.btnCaiDan.visible = this.isCaiDanSkin();
      }
      
      private function updatePreMvBtn() : void
      {
         var _loc1_:Boolean = false;
         this._mcChangePre = this.mcChangePre as MovieClip;
         this._mcChangePre.visible = this.isHasPreMv();
         if(this._mcChangePre.visible)
         {
            _loc1_ = Boolean(this._skindataservice.canShowPreMovie(this.skinId));
            this._mcChangePre.gotoAndStop(_loc1_ ? 2 : 1);
            TipsManager.getInstance().replaceTips(this._mcChangePre,_loc1_ ? "出场特效已开启。点击可关闭。" : "出场特效已关闭。点击可开启。");
         }
      }
      
      private function updateTalkBtn() : void
      {
         this.btntalk.visible = this._skindataservice.hasTalk(this.skinId);
         var _loc1_:PetSkinInfo = this._skindataservice.getPetSkinInfoBySkinId(this.skinId);
         if(_loc1_ && _loc1_.unlockTalkItemId > 0 && ActComHelper.getItemQuantity(_loc1_.unlockTalkItemId) <= 0)
         {
            this.btntalk.visible = false;
         }
         TipsManager.getInstance().addTips(this.btntalk,"亚比语音");
      }
      
      private function cancelPreMv() : void
      {
         this._skindataservice.setPreMoviePlayState(this.skinId,true);
         this.updatePreMvBtn();
      }
      
      private function surePreMv() : void
      {
         PackageSkinManager.instance.changeClassify(Classify.LEGENDARY);
         this._skindataservice.setPreMoviePlayState(this.skinId,false);
         this.updatePreMvBtn();
      }
      
      private function isHasPreMv() : Boolean
      {
         var _loc1_:PetSkinInfo = this._skindataservice.getPetSkinInfoBySkinId(this.skinId);
         return _loc1_ != null && Boolean(_loc1_.hasPreMovie);
      }
      
      private function isHuanDongSkin() : Boolean
      {
         var _loc1_:PetSkinInfo = this._skindataservice.getPetSkinInfoBySkinId(this.skinId);
         return _loc1_ != null && Boolean(_loc1_.isHuanDong);
      }
      
      private function isCaiDanSkin() : Boolean
      {
         var _loc1_:PetSkinInfo = this._skindataservice.getPetSkinInfoBySkinId(this.skinId);
         return _loc1_ != null && Boolean(_loc1_.isCaiDanSkin);
      }
      
      public function get classifyItems() : Array
      {
         return [this.btnsummon,this.btnshengti,this.btnshuangsheng,this.btnyingxiong,this.btnwangzhe,this.btnpo,this.btnchaowei,this.btnjuejie,this.btnshoulie,this.btnmingyun,this.newIconPos];
      }
      
      public function get LeftItems() : Array
      {
         return [this.btn_setpri,this.btn_backstore,this.mcChangePre,this.btn_health,this.btn_shareexp,this.mc_ride,this.mc_follow,this.btnChangeView,this.btnPetWord,this.btnskinchange,this.btntalk,this.btnDingzhi,this.mcQGShenBing,this.btnCaiDan,this.btnstorage,this.mcChangeViewRedDot];
      }
      
      private function onOpenHaiBao(param1:Object) : void
      {
         this.refreshSkinControls();
      }
      
      private function initFuns() : void
      {
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_RIDE_CHANGE,this.onRideChange);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_FOLLOW_CHANGE,this.onFollowChange);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onSelectedData);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.ON_OPEN_HAI_BAO,this.onOpenHaiBao);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.ON_CLOSE_HAI_BAO,this.onOpenHaiBao);
         CommonEventDispatcher.instance.addEventListener(PetFollowEvent.SET_FOLLOW,this.onSetPetFollow);
         CommonEventDispatcher.instance.addEventListener(PetFollowEvent.SET_UNFOLLOW,this.onSetPetUnFollow);
         this.mcFollow.addEventListener(MouseEvent.CLICK,this.onSetFollow);
         this.mcRide.addEventListener(MouseEvent.CLICK,this.onSetRide);
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         this.initChangePetView();
         CommonEventDispatcher.instance.addEventListener(XingHuiIconEvent.XingHuiIconEvent_CLOSE,this.onXingHuiIconEvent_CLOSE);
         CommonEventDispatcher.instance.addEventListener("GQPetChangeUseSkillType",this.onChangeUsingGQSkillType);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_INFO_TAB_CHANGED,this.onChangeFirstTab);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_CARD_SHOW_STATUS_CHANGED,this.onChangePetCardStatus);
         new ActTipsMc().init(this.btnDingzhi,this.mcDingzhiTips);
      }
      
      private function onChangePetCardStatus(param1:PetPackageEvent) : void
      {
         this._showCardList = param1.params.showCard;
         this.refreshNewIconPos();
      }
      
      private function onChangeFirstTab(param1:PetPackageEvent) : void
      {
         this._firstTab = param1.params.firstTab;
         this.refreshNewIconPos();
      }
      
      private function refreshNewIconPos() : void
      {
         var _loc1_:Number = NaN;
         if(PackageSkinManager.instance.classify != Classify.NORMAL)
         {
            return;
         }
         if(!this.pbi || !Pet_Helper.checkPetIsGQPet(this.pbi.raceId))
         {
            _loc1_ = 371.6;
         }
         else
         {
            _loc1_ = this._showCardList || this._firstTab == 2 ? 371.6 : 450.75;
         }
         this.newIconPos.x = _loc1_;
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc3_:IFightFlauntResourceService = null;
         var _loc4_:String = null;
         var _loc5_:String = null;
         var _loc2_:String = param1.target.name;
         switch(_loc2_)
         {
            case "btn_setpri":
               this.onSetPrimaryPet(param1);
               break;
            case "btn_backstore":
               this.onSetBackstore(param1);
               break;
            case "btn_health":
               this.onHealthPet(param1);
               break;
            case "btn_shareexp":
               this.onClickShareExp(param1);
               break;
            case "btntalk":
               this.onClickYuyin(param1);
               break;
            case "btnskinchange":
               this.onClickSkinChange(param1);
               break;
            case "btnsummon":
               this.onClickSummon(param1);
               break;
            case "btnshengti":
               this.onClickShengti(param1);
               break;
            case "btnshuangsheng":
               this.onClickShuangsheng(param1);
               break;
            case "btnyingxiong":
               this.onClickYingxiong(param1);
               break;
            case "btnwangzhe":
               this.onClickWangzhe(param1);
               break;
            case "btnchaowei":
               this.onClickChaowei(param1);
               break;
            case "btnpo":
               this.onClickPo(param1);
               break;
            case "btnjuejie":
               this.onClickJuejie(param1);
               break;
            case "btnshoulie":
               this.onClickShoulie(param1);
               break;
            case "btnmingyun":
               this.onclickMingyun();
               break;
            case "btnoffhuandong":
               this.tryCloseHuandong();
               break;
            case "btnopenhuandong":
               this.tryOpenHuandong();
               break;
            case "btnopenhaibao":
               this.tryOpenHaibao();
               break;
            case "btnoffhaibao":
               this.tryCloseHaibao();
               break;
            case "btnPetWord":
               LinkUtil.showPetWordPanel(this.pbi);
               break;
            case "btnSurePreMv":
               this.surePreMv();
               break;
            case "btnCancelPreMv":
               this.cancelPreMv();
               break;
            case "btnpetbigpic":
               LinkUtil.showPackagePetBigPicturePanel(this.pbi,null);
               break;
            case "btnFightflauntRes":
               _loc3_ = ServiceContainer.getService(IFightFlauntResourceService);
               _loc3_.showPanelByPetId(this.pbi.id);
               break;
            case "btnCaiDan":
               PetPackageEventDispatcher.instance.onOpenCaiDan();
               break;
            case "btnShenbing":
               _loc4_ = "gqpet/shenbing/shenbingshowpl";
               _loc5_ = "mmo.gqpet.shenbing.panel.GQ_SB_AllShenBingPl";
               Panel_Helper.loadResAndShow(_loc4_,_loc5_,{"raceId":this.pbi.shenBingRaceId});
               break;
            case "btnstorage":
               PetPackageService.currentPanel.closePanel();
               PetFunctionShortcut.tryOpenPetStore();
         }
      }
      
      private function tryOpenHaibao() : void
      {
         var _loc1_:PetSkinInfo = null;
         var _loc2_:ICommonPanelService = null;
         var _loc3_:MessagePanelParam = null;
         var _loc4_:String = null;
         var _loc5_:String = null;
         if(!this._skindataservice.canOpenPetPackageState(this.skinId,this.pbi))
         {
            _loc1_ = this._skindataservice.getPetSkinInfoBySkinId(this.skinId);
            if(_loc1_.packageSkinStateNeedPetIdArray == null)
            {
               if(_loc1_.needFullBattle)
               {
                  _loc2_ = ServiceContainer.getService(ICommonPanelService);
                  _loc3_ = new MessagePanelParam();
                  _loc3_.content = "\n需要将<font color=\'#FF0000\'>" + _loc1_.name + "</font>培养至满战才能开启海报形态哦！";
                  _loc2_.showMessagePanel(_loc3_);
               }
            }
            else
            {
               _loc4_ = "activityres/activity220218/packageskinstatetips/packageskinstatetips_doc";
               _loc5_ = "mmo.activity220218.packageskinstatetips.panel.PSST_MainPl";
               Panel_Helper.loadResAndShow(_loc4_,_loc5_,{"skinid":this.skinId});
            }
            return;
         }
         if(this._skindataservice.isOpenPetPackageState(this.skinId))
         {
            this._skindataservice.setPetPackageState(this.skinId,false);
         }
         else
         {
            this._skindataservice.setPetPackageState(this.skinId,true);
         }
         PetPackageEventDispatcher.instance.openPackageHaiBao();
         this.updateHaiBaoState();
      }
      
      private function tryCloseHaibao() : void
      {
         this._skindataservice.setPetPackageState(this.skinId,false);
         PetPackageEventDispatcher.instance.closePackageHaiBao();
         this.updateHaiBaoState();
      }
      
      private function tryCloseHuandong() : void
      {
         this._mcHuandong.gotoAndStop(2);
         PetPackageEventDispatcher.instance.closeHuanDong();
      }
      
      private function tryOpenHuandong() : void
      {
         this._mcHuandong.gotoAndStop(1);
         PetPackageEventDispatcher.instance.openHuanDong();
      }
      
      private function onRollOutQiyuan(param1:MouseEvent) : void
      {
         if(this._qiyuanTipsPanel != null)
         {
            DisplayUtil.stopAndRemove(this._qiyuanTipsPanel);
            this._qiyuanTipsPanel = null;
         }
      }
      
      private function onSetPetFollow(param1:PetFollowEvent) : void
      {
         this.curFollowPetId = param1.followPetId;
         this.updateFollowIcon();
      }
      
      private function onSetPetUnFollow(param1:PetFollowEvent) : void
      {
         this.curFollowPetId = -1;
         this.updateFollowIcon();
      }
      
      private function initChangePetView() : void
      {
         var _loc1_:SimpleButton = this.btnChangeView as SimpleButton;
         _loc1_.addEventListener(MouseEvent.CLICK,this.onClickChangePetView);
         this.mcChangeViewRedDot.visible = !LocalStore.getFlag("PackageControlBar_ClickChangeView");
      }
      
      private function onSelectedData(param1:PetPackageEvent) : void
      {
         var _loc2_:int = int(param1.params.id);
         var _loc3_:PetDetailedInfo = PetDetailDataMap.instance.getPetDetailInfo(param1.params.id);
         var _loc4_:SimpleButton = this.btnChangeView as SimpleButton;
         _loc4_.visible = this.isCanSeePetChangeViewBtn(_loc3_.raceId);
      }
      
      private function isCanSeePetChangeViewBtn(param1:int) : Boolean
      {
         return !ActArrHelper.isContainerValue(XING_TAI_BIAN_HUA_BU_KE_JIAN_PETS,param1);
      }
      
      private function onClickChangePetView(param1:MouseEvent) : void
      {
         var _loc2_:FunCallInfo = new FunCallInfo(this.afterCheck);
         var _loc3_:ISecondPwdService = ServiceContainer.getService(ISecondPwdService) as ISecondPwdService;
         LocalStore.getAndSetFlag("PackageControlBar_ClickChangeView");
         this.mcChangeViewRedDot.visible = false;
         _loc3_.verify(_loc2_);
      }
      
      private function afterCheck() : void
      {
         var _loc1_:String = "pet/petskin/petskin";
         var _loc2_:String = "mmo.petskin.PetSkinSwitchPl";
         Panel_Helper.loadResAndShow(_loc1_,_loc2_,{
            "petId":this.pbi.id,
            "pbiInfo":this.pbi
         });
      }
      
      private function closePackageEvent() : void
      {
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_PANEL_CLOSED,{}));
      }
      
      private function onClickYuyin(param1:MouseEvent) : void
      {
         var _loc3_:String = null;
         var _loc4_:String = null;
         var _loc2_:PetSkinInfo = this._skindataservice.getPetSkinInfoBySkinId(this.skinId);
         if(Boolean(_loc2_) && _loc2_.unlockTalkItemId > 0)
         {
            _loc3_ = "activityres/activity260814/specialskintalk/specialskintalk_code";
            _loc4_ = "mmo.activity260814.specialskintalk.panel.SSTalk_MainPl";
            Panel_Helper.loadResAndShow(_loc3_,_loc4_,{"raceId":this.skinId});
            return;
         }
         this._skindataservice.playTalk(this.skinId);
      }
      
      private function onClickShareExp(param1:MouseEvent) : void
      {
         var evt:MouseEvent = param1;
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_PANEL_CLOSED,{}));
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService("PetShareExp",function(param1:IShowDataPanel, param2:Object = null):void
         {
            ProgressFullSprite.close();
            param1.showPanelByData({"defaultSelectPetId":pbi.id});
         });
         SundriesClient.logButton(6749);
         SundriesClient.logEvent(15519);
      }
      
      private function onClickSkinChange(param1:MouseEvent) : void
      {
         var _loc2_:String = "pet/petskin/petskin";
         var _loc3_:String = "mmo.petskin.PetSkinSwitchPl";
         Panel_Helper.loadResAndShow(_loc2_,_loc3_,{"petId":this.pbi.id});
      }
      
      private function onClickSummon(param1:MouseEvent) : void
      {
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_PANEL_CLOSED,{}));
         var _loc2_:String = "activityres/activity180202/summonpetsystem/tlzcode";
         var _loc3_:String = "mmo.activity180202.summonpetsystem.panel.TLZMainPl";
         Panel_Helper.loadResAndShow(_loc2_,_loc3_,{"raceId":this.pbi.raceId});
      }
      
      private function onClickShengti(param1:MouseEvent) : void
      {
         var _loc2_:String = "degeneratorpet/jue/degeneratorjueshowpl";
         var _loc3_:String = "mmo.degeneratorpet.jue.DegeneratorJueShowPl";
         Panel_Helper.loadResAndShow(_loc2_,_loc3_,{"raceId":this.pbi.raceId});
      }
      
      private function onClickShuangsheng(param1:MouseEvent) : void
      {
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_PANEL_CLOSED,{}));
         var _loc2_:String = "degeneratorpet/guili/degeneratorguilishowpl";
         var _loc3_:String = "mmo.degeneratorpet.guili.DegeneratorGuiliShowPl";
         Panel_Helper.loadResAndShow(_loc2_,_loc3_,{"petId":this.pbi.id});
      }
      
      private function onClickYingxiong(param1:MouseEvent) : void
      {
         var _loc2_:String = "degeneratorpet/shen/degeneratorshenshowpl";
         var _loc3_:String = "mmo.degeneratorpet.shen.DegeneratorShenShowPl";
         Panel_Helper.loadResAndShow(_loc2_,_loc3_,{"raceId":this.pbi.raceId});
      }
      
      private function onClickWangzhe(param1:MouseEvent) : void
      {
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_PANEL_CLOSED,{}));
         var _loc2_:String = "degeneratorpet/yuling/degeneratoryulingshowpl";
         var _loc3_:String = "mmo.degeneratorpet.yuling.DegeneratorYulingShowPl";
         Panel_Helper.loadResAndShow(_loc2_,_loc3_,{"petId":this.pbi.id});
      }
      
      private function onClickChaowei(param1:MouseEvent) : void
      {
         var _loc2_:String = "degeneratorpet/chaowei/degeneratorchaoweishowpl";
         var _loc3_:String = "mmo.degeneratorpet.chaowei.DegeneratorChaoweiShowPl";
         Panel_Helper.loadResAndShow(_loc2_,_loc3_,{"raceId":this.pbi.raceId});
      }
      
      private function onClickPo(param1:MouseEvent) : void
      {
         var _loc2_:String = "degeneratorpet/po/degeneratorposhowpl";
         var _loc3_:String = "mmo.degeneratorpet.po.DegeneratorPoShowPl";
         Panel_Helper.loadResAndShow(_loc2_,_loc3_,{"raceId":this.pbi.raceId});
      }
      
      private function onClickJuejie(param1:MouseEvent) : void
      {
         var _loc2_:String = "degeneratorpet/xian/degeneratorxianshowpl";
         var _loc3_:String = "mmo.degeneratorpet.xian.DegeneratorXianShowPl";
         Panel_Helper.loadResAndShow(_loc2_,_loc3_,{"raceId":this.pbi.raceId});
      }
      
      private function onClickShoulie(param1:MouseEvent) : void
      {
         var _loc2_:String = "degeneratorpet/shou/degeneratorshoushowpl";
         var _loc3_:String = "mmo.degeneratorpet.shou.DegeneratorShouShowPl";
         Panel_Helper.loadResAndShow(_loc2_,_loc3_,{"petId":this.pbi.id});
      }
      
      private function onclickMingyun() : void
      {
         var _loc1_:String = "degeneratorpet/mingyun/degeneratormingyunshowpl";
         var _loc2_:String = "mmo.degeneratorpet.mingyun.DegeneratorMingyunShowPl";
         Panel_Helper.loadResAndShow(_loc1_,_loc2_,{"raceId":this.pbi.raceId});
      }
      
      public function updatePetInfo(param1:PetDetailedInfo, param2:Boolean, param3:int, param4:int) : void
      {
         this.pbi = param1;
         this.setIsPri(param2);
         this._index = param3;
         this._totalLenght = param4;
         this.ridable = this.petRideService.validateRideReady(this.pbi);
         this.hasRideCard = this.petRideService.hasRideCard(this.getChectPetId(this.pbi));
         this.updateFollowIcon();
         this.updateRideIcon();
         this.updateSkinIcon();
         this.updateSummonIcon();
         this.updateShengtiIcon();
         this.updateShuangshengIcon();
         this.updateYingxiongIcon();
         this.updateWangzheIcon();
         this.updateChaoweiIcon();
         this.updateJuejieIcon();
         this.updatePoIcon();
         this.updateShoulieIcon();
         this.updateMingyunIcon();
         this.refreshSkinControls();
         this.updatePetWord();
         this._iconHandler.setPet(this.pbi);
         this._gqIconhandler.setPet(this.pbi);
         this.updateGQShenBingIcon();
      }

      private function refreshSkinControls() : void
      {
         if(this.pbi == null)
         {
            return;
         }
         this.updatePreMvBtn();
         this.updateTalkBtn();
         this.mchandtalk.visible = this.isInterSkin();
         this._mcHuandong.visible = this.isHuanDongSkin() && this.pbi.useDIYBgId <= 0;
         if(this._mcHuandong.visible)
         {
            this.tryOpenHuandong();
         }
         else
         {
            this.tryCloseHuandong();
         }
         this.updateHaiBaoState();
         this.updateCaiDanBtn();
         this.refreshNewIconPos();
      }
      
      private function onChangeUsingGQSkillType(param1:CommonEvent) : void
      {
         this._gqIconhandler.setPet(this.pbi);
      }
      
      private function getChectPetId(param1:PetBriefInfo) : int
      {
         return param1.skinId > 0 ? int(param1.skinId) : int(param1.raceId);
      }
      
      private function updatePetWord() : void
      {
         this.btnPetWord.visible = PetWordConfig.isPetCanModifyWord(this.pbi.viewId);
      }
      
      private function updateHaiBaoState() : *
      {
         var _loc1_:PetSkinInfo = this._skindataservice.getPetSkinInfoBySkinId(this.skinId);
         var _loc2_:MovieClip = this.mchaibao;
         _loc2_.visible = _loc1_ != null && Boolean(_loc1_.hasPackageSkinState);
         if(_loc2_.visible)
         {
            _loc2_.gotoAndStop(this._skindataservice.isOpenPetPackageState(this.skinId) ? 2 : 1);
            if(Boolean(_loc1_.hasMultiHaiBao) && !this._skindataservice.isInMultiPetPackageState(this.skinId) && Boolean(this._skindataservice.isOpenPetPackageState(this.skinId)))
            {
               _loc2_.gotoAndStop(1);
            }
         }
      }
      
      private function updateGQShenBingIcon() : void
      {
         var shenbingBtn:SimpleButton;
         var shenBingId:int = 0;
         var iconResObj:ResourceObject = null;
         DisplayUtil.stopAndRemoveChild(this._gqShenBingContainer);
         shenbingBtn = this._gqShenBingMc.getChildByName("btnShenbing") as SimpleButton;
         if(this.pbi.isQiyueShenBing)
         {
            shenBingId = int(this.pbi.shenBingRaceId);
            iconResObj = new ResourceObject("gqpet/shenbing/effect/shenbingeffect_" + shenBingId,"mmo.gqpet.shenbing.view.ShenBingEffect_" + shenBingId + "_icon");
            PetPackageHelper.loadObject(iconResObj,function(param1:MovieClip):void
            {
               if(Boolean(_gqShenBingContainer) && Boolean(_gqShenBingContainer.parent))
               {
                  param1.scaleY = param1.scaleX = 0.8;
                  _gqShenBingContainer.addChild(param1);
                  _gqShenBingContainer.mouseChildren = _gqShenBingContainer.mouseEnabled = false;
               }
            });
         }
         this._gqShenBingMc.mouseEnabled = false;
         shenbingBtn.mouseEnabled = this.pbi.isQiyueShenBing;
      }
      
      private function isInterSkin() : Boolean
      {
         var _loc1_:PetSkinInfo = this._skindataservice.getPetSkinInfoBySkinId(this.skinId);
         return _loc1_ != null && Boolean(_loc1_.isInteractSkin);
      }
      
      private function get skinId() : int
      {
         if(this.pbi.specialSkinId > 0)
         {
            return getAolaMorphControlSkinId(this.pbi.specialSkinId);
         }
         return getAolaMorphControlSkinId(this.pbi.viewId);
      }

      private static function getAolaMorphControlSkinId(param1:int) : int
      {
         var _loc2_:* = null;
         var _loc3_:int = 0;
         try
         {
            if(!ExternalInterface.available)
            {
               return param1;
            }
            _loc2_ = ExternalInterface.call("aolaMorphResolveSkinId",param1);
            _loc3_ = int(_loc2_);
            if(_loc3_ > 0)
            {
               return _loc3_;
            }
         }
         catch(error:Error)
         {
         }
         return param1;
      }
      
      public function dispose() : void
      {
         TipsManager.getInstance().removeTips(this.btnBackstore);
         TipsManager.getInstance().removeTips(this.mcRide);
         TipsManager.getInstance().removeTips(this.mcFollow);
         TipsManager.getInstance().removeTips(this.btnHealth);
         TipsManager.getInstance().removeTips(this.btnSetpri);
         this.mcRide.removeEventListener(MouseEvent.CLICK,this.onSetRide);
         this.mcFollow.removeEventListener(MouseEvent.CLICK,this.onSetFollow);
         this.removeEventListener(MouseEvent.CLICK,this.onClick);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_FOLLOW_CHANGE,this.onFollowChange);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_RIDE_CHANGE,this.onRideChange);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onSelectedData);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.ON_OPEN_HAI_BAO,this.onOpenHaiBao);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.ON_CLOSE_HAI_BAO,this.onOpenHaiBao);
         CommonEventDispatcher.instance.removeEventListener(PetFollowEvent.SET_FOLLOW,this.onSetPetFollow);
         CommonEventDispatcher.instance.removeEventListener(PetFollowEvent.SET_UNFOLLOW,this.onSetPetUnFollow);
         CommonEventDispatcher.instance.removeEventListener("GQPetChangeUseSkillType",this.onChangeUsingGQSkillType);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_CARD_SHOW_STATUS_CHANGED,this.onChangePetCardStatus);
         if(this._iconHandler)
         {
            this._iconHandler.clear();
            this._iconHandler = null;
         }
         if(this._gqIconhandler)
         {
            this._gqIconhandler.clear();
            this._gqIconhandler = null;
         }
         CommonEventDispatcher.instance.removeEventListener(XingHuiIconEvent.XingHuiIconEvent_CLOSE,this.onXingHuiIconEvent_CLOSE);
      }
      
      private function onRideChange(param1:PetPackageEvent) : void
      {
         var _loc2_:int = int(param1.params.id);
         this.curRidePetId = _loc2_;
         this.updateRideIcon();
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_PANEL_CLOSED,{}));
      }
      
      private function onFollowChange(param1:PetPackageEvent) : void
      {
         var _loc2_:int = int(param1.params.id);
         this.curFollowPetId = _loc2_;
         this.updateFollowIcon();
      }
      
      private function setIsPri(param1:Boolean) : void
      {
         this._isPri = param1;
         TipsManager.getInstance().removeTips(this.btnSetpri);
         if(this._isPri)
         {
            DisplayUtil.applyGray(this.btnSetpri);
            TipsManager.getInstance().addTips(this.btnSetpri,"这只亚比已经是首宠啦！",100);
         }
         else
         {
            DisplayUtil.clearFilters(this.btnSetpri);
            TipsManager.getInstance().addTips(this.btnSetpri,"设为首宠",100);
         }
      }
      
      private function onSetPrimaryPet(param1:MouseEvent) : void
      {
         if(this.pbi == null)
         {
            return;
         }
         if(this._isPri)
         {
            return;
         }
         new SetPetPrimaryHelper().setPrimary(this.pbi.id,this._index);
         SundriesClient.logButton(6745);
         SundriesClient.logEvent(15515);
      }
      
      private function onHealthPet(param1:MouseEvent) : void
      {
         if(this.pbi == null)
         {
            return;
         }
         new SetPetHealthHelper().tryHealthPet(this.pbi,this._index);
         SundriesClient.logButton(6748);
         SundriesClient.logEvent(15518);
      }
      
      private function onSetFollow(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         if(null == this.pbi)
         {
            return;
         }
         if(PetClothesMap.getUnlockFollowItemId(this.pbi.viewId) > 0)
         {
            _loc2_ = int(PetClothesMap.getUnlockFollowItemId(this.pbi.viewId));
            if(ActComHelper.getItemQuantity(_loc2_) <= 0)
            {
               NewDialog.showFailMessage("拥有" + ActMaterialLoader.getMaterialName(MaterialTypes.ITEM,_loc2_) + "后才能解锁跟随功能喔");
               return;
            }
         }
         new SetPetFollowHelper().trySetFollow(this.pbi,this.curFollowPetId,this.curRidePetId);
         SundriesClient.logButton(6751);
         SundriesClient.logEvent(15521);
      }
      
      private function onSetRide(param1:MouseEvent) : void
      {
         if(null == this.pbi)
         {
            return;
         }
         var _loc2_:IFlyService = ServiceContainer.getService(IFlyService) as IFlyService;
         if(_loc2_.isFlying())
         {
            return;
         }
         var _loc3_:IRideService = ServiceContainer.getService(IRideService) as IRideService;
         if(!_loc3_.rideServieIsEffect)
         {
            return;
         }
         new SetPetRideHelper().trySetPetRide(this.pbi,this.curRidePetId,this.curFollowPetId,this.hasRideCard,this.ridable);
         SundriesClient.logButton(6750);
         SundriesClient.logEvent(15520);
      }
      
      private function onSetBackstore(param1:MouseEvent) : void
      {
         if(null == this.pbi)
         {
            return;
         }
         new SetPetBackStoreHelper().trySetPetBackStore(this.pbi,this._index,this._totalLenght,this.curFollowPetId,this.curRidePetId);
         SundriesClient.logButton(6746);
         SundriesClient.logEvent(15516);
      }
      
      private function updateFollowIcon() : void
      {
         TipsManager.getInstance().removeTips(this.mcFollow);
         var _loc1_:Boolean = Boolean(Pet_Helper.needDetailFollowByRaceId(this.pbi.viewId));
         this.mcFollow.visible = !_loc1_;
         if(_loc1_)
         {
            return;
         }
         var _loc2_:int = this.curFollowPetId != this.pbi.id ? 1 : 2;
         var _loc3_:String = 1 == _loc2_ ? "亚比跟随" : "取消跟随";
         TipsManager.getInstance().addTips(this.mcFollow,_loc3_,100);
         this.mcFollow.gotoAndStop(_loc2_);
      }
      
      private function updateRideIcon() : void
      {
         var _loc5_:IFlyService = null;
         TipsManager.getInstance().removeTips(this.mcRide);
         var _loc1_:int = this.curRidePetId != this.pbi.id ? 1 : 2;
         var _loc2_:String = 1 == _loc1_ ? "亚比坐骑" : "取消亚比坐骑";
         TipsManager.getInstance().addTips(this.mcRide,_loc2_,100);
         this.mcRide.gotoAndStop(_loc1_);
         var _loc3_:int = this.pbi.skinId > 0 ? int(this.pbi.skinId) : int(this.pbi.raceId);
         var _loc4_:PetRideInfo = PetRideInfosMap.instance.getPetRideInfo(_loc3_);
         this.mcRide.visible = true;
         if(null == _loc4_)
         {
            TipsManager.getInstance().removeTips(this.mcRide);
            TipsManager.getInstance().addTips(this.mcRide,"这只亚比无法成为坐骑哦！",0,50);
            this.mcRide.visible = false;
            this.mcRide.gotoAndStop(3);
            return;
         }
         if(!this.petRideService.rideServieIsEffect)
         {
            if(this.ridable)
            {
               TipsManager.getInstance().removeTips(this.mcRide);
               TipsManager.getInstance().addTips(this.mcRide,"这里不能乘坐坐骑哦，换个地方试试吧！",0,50);
            }
            else
            {
               TipsManager.getInstance().removeTips(this.mcRide);
               TipsManager.getInstance().addTips(this.mcRide,"这里不能训练坐骑哦，换个地方试试吧！",0,50);
            }
         }
         else
         {
            _loc5_ = ServiceContainer.getService(IFlyService) as IFlyService;
            if(_loc5_.isFlying())
            {
               if(this.ridable)
               {
                  TipsManager.getInstance().removeTips(this.mcRide);
                  TipsManager.getInstance().addTips(this.mcRide,"你正在飞行，不可以乘坐坐骑哦！",0,50);
               }
               else
               {
                  TipsManager.getInstance().removeTips(this.mcRide);
                  TipsManager.getInstance().addTips(this.mcRide,"你正在飞行，不可以训练坐骑哦！",0,50);
               }
            }
         }
      }
      
      private function updateSkinIcon() : void
      {
         this._skinChangeBtn.visible = this._skindataservice.getAllSkinIdsByRaceId(this.pbi.raceId).length != 0;
      }
      
      private function updateSummonIcon() : void
      {
         this._summonBtn.visible = Boolean(this._pmSvr.getOperationPM(this.pbi.raceId).pmData.isSummonPet) && Boolean(this._pmSvr.getOperationPM(this.pbi.raceId).pmData.isDegeneratorPM());
      }
      
      private function updateShengtiIcon() : void
      {
         this._shengtiBtn.visible = this._pmSvr.getOperationPM(this.pbi.raceId).pmData.getDegeneratorType() == DegeneratorPetType.JUE;
      }
      
      private function updateShuangshengIcon() : void
      {
         this._shuangshengBtn.visible = this._pmSvr.getOperationPM(this.pbi.raceId).pmData.getDegeneratorType() == DegeneratorPetType.GUILI;
      }
      
      private function updateYingxiongIcon() : void
      {
         this._yingxiongBtn.visible = this._pmSvr.getOperationPM(this.pbi.raceId).pmData.getDegeneratorType() == DegeneratorPetType.SHEN;
      }
      
      private function updateWangzheIcon() : void
      {
         this._wangzheBtn.visible = this._pmSvr.getOperationPM(this.pbi.raceId).pmData.getDegeneratorType() == DegeneratorPetType.YULING;
      }
      
      private function updateChaoweiIcon() : void
      {
         this._chaoweiBtn.visible = this._pmSvr.getOperationPM(this.pbi.raceId).pmData.getDegeneratorType() == DegeneratorPetType.CHAOWEI;
      }
      
      private function updateJuejieIcon() : void
      {
         this._juejieBtn.visible = this._pmSvr.getOperationPM(this.pbi.raceId).pmData.getDegeneratorType() == DegeneratorPetType.XIAN;
      }
      
      private function updatePoIcon() : void
      {
         this._poBtn.visible = this._pmSvr.getOperationPM(this.pbi.raceId).pmData.getDegeneratorType() == DegeneratorPetType.PO;
      }
      
      private function updateShoulieIcon() : void
      {
         this._shoulieBtn.visible = this._pmSvr.getOperationPM(this.pbi.raceId).pmData.getDegeneratorType() == DegeneratorPetType.SHOU;
      }
      
      private function updateMingyunIcon() : void
      {
         this._mingyunBtn.visible = this._pmSvr.getOperationPM(this.pbi.raceId).pmData.getDegeneratorType() == DegeneratorPetType.MINGYUN;
      }
      
      private function applyGrayAndTips(param1:InteractiveObject, param2:String = null) : void
      {
         DisplayUtil.applyGray(param1);
         if(null != param2)
         {
            TipsManager.getInstance().removeTips(param1);
            TipsManager.getInstance().addTips(param1,param2,100);
         }
      }
      
      private function onXingHuiIconEvent_CLOSE(param1:CommonEvent) : void
      {
         var _loc2_:int = int(param1.params.posType);
         if(_loc2_ != XingHuiIconOpenType.type_petpackage)
         {
            return;
         }
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_PANEL_CLOSED,{}));
      }
   }
}

