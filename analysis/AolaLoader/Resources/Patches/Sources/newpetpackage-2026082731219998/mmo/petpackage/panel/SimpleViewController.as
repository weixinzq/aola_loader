package mmo.petpackage.panel
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.external.ExternalInterface;
   import flash.utils.setTimeout;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.sound.SoundManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.skin.IPetSkinDataService;
   import mmo.interfaces.pet.data.skin.PetSkinClassifyInfoConfig;
   import mmo.interfaces.pet.data.skin.PetSkinConfig;
   import mmo.interfaces.pet.data.skin.PetSkinInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petpackage.DocClass;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.skin.PackageSkinManager;
   import mmo.petpackage.controller.skin.constant.Classify;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetDetailBase;
   import mmo.petpackage.panel.other.SetLockStatePanel;
   import mmo.play.actthings.obj.ActArrHelper;
   import mmo.play.actthings.pet.ActPetHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol536")]
   public class SimpleViewController extends PetDetailBase
   {

      private static var _aolaMorphCallbackRegistered:Boolean = false;
      
      private static const SPECIAL_LABEL_POS:Object = {};
      
      SPECIAL_LABEL_POS[4023] = new Point(0,0);
      
      public var btnSetLock:SimpleButton;
      
      public var btnnofullscreen:SimpleButton;
      
      public var btnshowlegendview:SimpleButton;
      
      public var btnshownormal:SimpleButton;
      
      public var mcLockStyle:MovieClip;
      
      public var mclabelcontainer:MovieClip;
      
      private const SHOW_STATE_KEY:String = "Package_PET_Show_State";
      
      private var _bg:Sprite;
      
      private var _ips:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      private var _skinService:IPetSkinDataService = ServiceContainer.getService(IPetSkinDataService) as IPetSkinDataService;
      
      private var _prePetId:int = -1;
      
      private var _preSkinId:int = -1;
      
      private var _preSpecialSkinId:int = -1;
      
      private var _preDIYBgId:int = -1;
      
      private var _labelContainer:Sprite;
      
      private var _packageBG:Sprite;
      
      private var _hasBgSound:Boolean = !SoundManager.instance.isClose;

      private var _aolaMorphPreviousClassify:int = -1;
      
      public function SimpleViewController()
      {
         super();
         ensureAolaMorphBridge();
         DocClass.ensureAolaCommandBridge();
         this._labelContainer = this.mclabelcontainer;
         this.canUpdateUI = true;
         this.addEventListener(MouseEvent.CLICK,this.onClickMe);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.ON_OPEN_HUAN_DONG,this.onOpenHuandong);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.ON_CLOSE_HUAN_DONG,this.onCloseHuandong);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.ON_CLOSE_HAI_BAO,this.onCloseHaibao);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.ON_OPEN_HAI_BAO,this.onOpenHaibao);
         CommonEventDispatcher.instance.addEventListener(CommonEvent.ON_CAI_DAN_SKIN_OPEN_CONFIRM,this.onOpenConfirm);
      }
      
      private function onOpenConfirm(param1:CommonEvent) : void
      {
         this.changeStyle(Classify.FULL_SCRREN,false);
      }
      
      private function onCloseHaibao(param1:Event) : void
      {
         var e:Event = param1;
         this.showPreMovie(function():void
         {
            changeSkins(true);
         });
      }
      
      private function onOpenHaibao(param1:Event) : void
      {
         this.changeSkins(true);
      }
      
      private function onOpenHuandong(param1:Event) : void
      {
         this.tryOpenHuandong();
      }
      
      private function onCloseHuandong(param1:Event) : void
      {
         this.tryCloseHuandong();
      }
      
      private function isHuandong() : Boolean
      {
         var _loc1_:PetSkinInfo = this._skinService.getPetSkinInfoBySkinId(this.skinId);
         return _loc1_ != null && Boolean(_loc1_.isHuanDong);
      }
      
      private function tryOpenHuandong() : void
      {
         var _loc2_:MovieClip = null;
         if(!this.isHuandong())
         {
            return;
         }
         if(this._bg == null || this._bg.numChildren <= 0)
         {
            return;
         }
         var _loc1_:Sprite = this._bg.getChildAt(0) as Sprite;
         if(_loc1_ != null && _loc1_.numChildren > 0)
         {
            _loc2_ = _loc1_.getChildAt(0) as MovieClip;
            if(_loc2_ != null)
            {
               _loc2_.gotoAndPlay(1);
            }
         }
      }
      
      private function tryCloseHuandong() : void
      {
         var _loc2_:MovieClip = null;
         if(!this.isHuandong())
         {
            return;
         }
         if(this._bg == null || this._bg.numChildren <= 0)
         {
            return;
         }
         var _loc1_:Sprite = this._bg.getChildAt(0) as Sprite;
         if(this._bg.numChildren <= 0)
         {
            return;
         }
         if(_loc1_ != null && _loc1_.numChildren > 0)
         {
            _loc2_ = _loc1_.getChildAt(0) as MovieClip;
            if(_loc2_ != null)
            {
               _loc2_.gotoAndStop(1);
            }
         }
      }
      
      public function setPackageBackgroundContainer(param1:Sprite) : void
      {
         this._packageBG = param1;
         this._packageBG.mouseChildren = false;
         this._packageBG.mouseEnabled = false;
      }
      
      public function setBackgroundContainer(param1:Sprite) : void
      {
         this._bg = param1;
      }
      
      public function getLabelContainer() : Sprite
      {
         return this._labelContainer;
      }
      
      override protected function onOnlyUpdatePL(param1:Event) : void
      {
         super.onOnlyUpdatePL(param1);
         this.setButtonsState();
      }
      
      override protected function initUI() : void
      {
         this.refreshUI();
      }
      
      private function isNothingChange() : Boolean
      {
         return this._prePetId == this.pdi.id && this._preSkinId == this.pdi.viewId && this._preSpecialSkinId == this.pdi.specialSkinId && this._preDIYBgId == this.pdi.useDIYBgId;
      }
      
      override protected function refreshUI() : void
      {
         this._skinService.initDIYBgSkinData(this.pdi.raceId,this.refreshSkin);
      }
      
      private function refreshSkin() : void
      {
         var _loc2_:int = 0;
         if(this.isNothingChange())
         {
            return;
         }
         this.tryCloseHuandong();
         this._skinService.stopPetSkinBackgroundMusic();
         this._prePetId = this.pdi.id;
         this._preSkinId = this.pdi.viewId;
         this._preSpecialSkinId = this.pdi.specialSkinId;
         this._preDIYBgId = this.pdi.useDIYBgId;
         var _loc1_:PetSkinInfo = this._skinService.getPetSkinInfoBySkinId(this.skinId);
         if(LocalStore.getValue(this.SHOW_STATE_KEY))
         {
            _loc2_ = int(LocalStore.getValue(this.SHOW_STATE_KEY)["classify"]);
            if(_loc1_ == null || _loc2_ == Classify.FULL_SCRREN && !this.isHasBg())
            {
               if(_loc2_ == Classify.LEGENDARY && this.isGQPM())
               {
                  _loc2_ = Classify.LEGENDARY;
               }
               else
               {
                  _loc2_ = Classify.NORMAL;
               }
            }
         }
         else
         {
            _loc2_ = _loc1_ == null ? Classify.NORMAL : Classify.LEGENDARY;
            if(_loc1_ == null && PackageSkinManager.instance.classify == Classify.LEGENDARY)
            {
               _loc2_ = Classify.NORMAL;
            }
            else if(_loc1_ != null && PackageSkinManager.instance.classify == Classify.NORMAL)
            {
               _loc2_ = Classify.LEGENDARY;
            }
         }
         if(PackageSkinManager.instance.classify != _loc2_)
         {
            PackageSkinManager.instance.changeClassify(_loc2_);
         }
         this.showPreMovie(this.changeSkins);
      }
      
      private function showPreMovie(param1:Function) : void
      {
         var sp:Sprite = null;
         var cb:Function = param1;
         if(this.shouldRemoveOriginalBackground())
         {
            cb && cb();
            return;
         }
         var skInfo:PetSkinInfo = this._skinService.getPetSkinInfoBySkinId(this.skinId);
         if(skInfo == null || !skInfo.hasPreMovie || !this._skinService.canShowPreMovie(this.skinId) || Boolean(this._skinService.isOpenPetPackageState(this.skinId)))
         {
            cb && cb();
            return;
         }
         this.btnshownormal.visible = false;
         this.btnshowlegendview.visible = false;
         this.btnnofullscreen.visible = false;
         this.mcLockStyle.visible = false;
         this.btnSetLock.visible = false;
         sp = this._skinService.getAndShowPreMovie(this.skinId,function():void
         {
            PetPackageEventDispatcher.instance.onSkinPreMoviePlayFinish();
            _bg.removeChild(sp);
            cb && cb();
         });
         this._bg.addChild(sp);
      }
      
      override public function dispose() : void
      {
         super.dispose();
         this.clearBg();
         this.clearLabel();
         this._bg = null;
         if(this._hasBgSound && Boolean(SoundManager.instance.isClose))
         {
         }
         this._skinService.stopPetSkinBackgroundMusic();
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.ON_CLOSE_HAI_BAO,this.onCloseHaibao);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.ON_OPEN_HAI_BAO,this.onOpenHaibao);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.ON_OPEN_HUAN_DONG,this.onOpenHuandong);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.ON_CLOSE_HUAN_DONG,this.onCloseHuandong);
         CommonEventDispatcher.instance.removeEventListener(CommonEvent.ON_CAI_DAN_SKIN_OPEN_CONFIRM,this.onOpenConfirm);
      }
      
      private function onClickMe(param1:MouseEvent) : void
      {
         switch(param1.target.name)
         {
            case "btnshowlegendview":
               this.changeStyle(Classify.LEGENDARY,false);
               break;
            case "btnshownormal":
               this.changeStyle(Classify.FULL_SCRREN,false);
               break;
            case "btnnofullscreen":
               this.changeStyle(Classify.NORMAL,false);
               break;
            case "btnLockStyle":
               LocalStore.setValue(this.SHOW_STATE_KEY,{"classify":PackageSkinManager.instance.classify});
               this.refreshLockStyleBtn();
               break;
            case "btnSetLock":
               new SetLockStatePanel(this.isHasBg(),this.changeStyle,this).showPanel();
               this.refreshLockStyleBtn();
         }
      }
      
      private function changeStyle(param1:int = -1, param2:Boolean = true) : void
      {
         if(param1 >= 0)
         {
            PackageSkinManager.instance.changeClassify(param1);
            if(param1 == 0)
            {
               CommonEventDispatcher.instance.dispatchEvent(new CommonEvent(CommonEvent.ON_CAI_DAN_SKIN_RESET,{}));
            }
            this.changeSkins(param2);
         }
      }
      
      private function changeSkins(param1:Boolean = true) : void
      {
         if(param1)
         {
            this.changeBg();
         }
         this.changeLabel();
         this.setButtonsState();
      }
      
      private function changeBg() : void
      {
         var info:PetSkinInfo;
         var self:SimpleViewController = null;
         var bgParent:DisplayObjectContainer = null;
         var spb:Sprite = null;
         var loopTime:int = 0;
         var cc:* = undefined;
         self = this;
         bgParent = this._bg.parent as DisplayObjectContainer;
         this.clearBg();
         if(this.shouldRemoveOriginalBackground())
         {
            if(this._aolaMorphPreviousClassify < 0)
            {
               this._aolaMorphPreviousClassify = PackageSkinManager.instance.classify;
            }
            if(PackageSkinManager.instance.classify != Classify.NORMAL)
            {
               PackageSkinManager.instance.changeClassify(Classify.NORMAL);
            }
            this._skinService.stopPetSkinBackgroundMusic();
            return;
         }
         if(this._aolaMorphPreviousClassify >= 0)
         {
            if(PackageSkinManager.instance.classify != this._aolaMorphPreviousClassify)
            {
               PackageSkinManager.instance.changeClassify(this._aolaMorphPreviousClassify);
            }
            this._aolaMorphPreviousClassify = -1;
         }
         info = this._skinService.getPetSkinInfoBySkinId(this.skinId);
         if(Boolean(info) && Boolean(info.isSwitchPackageBG))
         {
            spb = this._skinService.getPackageBackground(this.skinId);
            if(info.isSwitchPackageBGNormalSize)
            {
               this._bg.addChild(spb);
            }
            else
            {
               spb.name = "skin" + this.skinId;
               this._packageBG.addChild(spb);
               spb.x = -200;
            }
         }
         if(info != null && Boolean(info.hasPackageSkinState) && !this._skinService.isOpenPetPackageState(this.skinId))
         {
            if(this.pdi.useDIYBgId > 0)
            {
               this.addDIYBg();
            }
            return;
         }
         if((!info || !info.hasPackageSkinState) && this.pdi.useDIYBgId > 0)
         {
            this.clearBg();
            this.addDIYBg();
            return;
         }
         if(Boolean(info) && Boolean(info.hasBackground))
         {
            loopTime = int.MAX_VALUE;
            cc = this._skinService.getPetSkinBackground(this.skinId,LoadingSpriteType.NONE,info.isCaiDanSkin,true,loopTime,this._skinService.isInMultiPetPackageState(info.skinId));
            this._bg.addChild(cc);
            if(info.isCaiDanSkin)
            {
               self.clearCommonLiZiMv();
            }
            else
            {
               this.onLoadCommonHaiBaoLiZiMv(function(param1:MovieClip):void
               {
                  self.clearCommonLiZiMv();
                  param1.mouseEnabled = false;
                  param1.mouseEnabled = false;
                  param1.name = "commonLiZiMv";
                  param1.visible = ActPetHelper.getPetName(skinId).indexOf("动效特写") < 0;
                  if(bgParent != null)
                  {
                     bgParent.addChildAt(param1,bgParent.getChildIndex(self._bg) + 1);
                  }
               });
            }
         }
      }
      
      private function addDIYBg() : void
      {
         this._skinService.getDIYBackgroundView(this._skinService.getDIYBgSkinDataByRaceId(this.pdi.raceId).getDataById(this.pdi.useDIYBgId),this.onGetDIYBg);
      }
      
      private function onGetDIYBg(param1:MovieClip) : void
      {
         this._bg.addChild(param1);
      }
      
      private function clearCommonLiZiMv() : void
      {
         if(this._bg == null || this._bg.parent == null)
         {
            return;
         }
         var _loc1_:DisplayObjectContainer = this._bg.parent as DisplayObjectContainer;
         var _loc2_:DisplayObjectContainer = _loc1_.getChildByName("commonLiZiMv") as DisplayObjectContainer;
         DisplayUtil.stopAndRemoveChild(_loc2_);
      }
      
      private function onLoadCommonHaiBaoLiZiMv(param1:Function) : void
      {
         var callback:Function = param1;
         var onGetViewRes:Function = function(param1:Array):void
         {
            var _loc2_:Sprite = param1[0];
            if(_loc2_ != null)
            {
               callback(_loc2_);
            }
         };
         var url:String = "pet/commonhaibaolvzimv";
         var cls:String = "mmo.petpackage.panel.CommonHaoBaoLiZiMv";
         var resParams:ResParams = ResParams.create(url,onGetViewRes,null,ResPriority.NORMAL,[cls],null);
         ResScheduler.getRes(resParams);
      }
      
      private function changeLabel() : void
      {
         this.clearLabel();
         var _loc1_:Sprite = this._skinService.getSkinLabelView(this.skinId);
         var _loc2_:Point = SPECIAL_LABEL_POS[this.skinId];
         if(_loc2_ == null)
         {
            _loc1_.x = 0;
            _loc1_.y = 0;
         }
         else
         {
            _loc1_.x = _loc2_.x;
            _loc1_.y = _loc2_.y;
         }
         var _loc3_:int = int(PetSkinConfig.getSkinType(this.skinId));
         var _loc4_:Array = [PetSkinClassifyInfoConfig.S_BG_ONE,PetSkinClassifyInfoConfig.S_BG_MULT,PetSkinClassifyInfoConfig.S_HAI_BAO];
         _loc1_.visible = !ActArrHelper.isContainerValue(_loc4_,_loc3_);
         this._labelContainer.addChild(_loc1_);
      }
      
      private function setButtonsState() : void
      {
         this.btnnofullscreen.visible = !this.isHasBg() && PackageSkinManager.instance.classify == Classify.LEGENDARY || PackageSkinManager.instance.classify == Classify.FULL_SCRREN;
         this.btnshownormal.visible = this.isHasBg() && PackageSkinManager.instance.classify == Classify.LEGENDARY;
         this.btnshowlegendview.visible = this.needShowBtn();
         this.refreshLockStyleBtn();
         TipsManager.getInstance().replaceTips(this.btnnofullscreen,"点击查看亚比详情");
         TipsManager.getInstance().replaceTips(this.btnshownormal,"点击查看全景海报");
         TipsManager.getInstance().replaceTips(this.btnshowlegendview,"点击查看海报形态");
      }
      
      private function refreshLockStyleBtn() : void
      {
         var _loc1_:int = 2;
         if(LocalStore.getValue(this.SHOW_STATE_KEY) == null || LocalStore.getValue(this.SHOW_STATE_KEY)["classify"] != PackageSkinManager.instance.classify)
         {
            _loc1_ = 1;
         }
         this.mcLockStyle.gotoAndStop(_loc1_);
         this.mcLockStyle.visible = this.btnnofullscreen.visible || this.btnshownormal.visible || this.btnshowlegendview.visible;
         this.btnSetLock.visible = this.mcLockStyle.visible;
      }
      
      private function clearBg() : void
      {
         DisplayUtil.stopAndRemoveChild(this._bg);
         var _loc1_:int = this._packageBG.numChildren - 1;
         while(_loc1_ >= 0)
         {
            if(this._packageBG.getChildAt(_loc1_).name.indexOf("skin") >= 0)
            {
               this._packageBG.removeChildAt(_loc1_);
            }
            _loc1_--;
         }
         this.clearCommonLiZiMv();
      }
      
      private function clearLabel() : void
      {
         DisplayUtil.clearChildren(this._labelContainer);
      }
      
      private function get skinId() : int
      {
         if(this.pdi.specialSkinId > 0)
         {
            return getAolaMorphSkinId(this.pdi.specialSkinId);
         }
         return getAolaMorphSkinId(this.pdi.viewId);
      }

      private static function ensureAolaMorphBridge() : void
      {
         if(_aolaMorphCallbackRegistered)
         {
            return;
         }
         try
         {
            if(ExternalInterface.available)
            {
               ExternalInterface.addCallback("aolaMorphRefresh",onAolaMorphRefresh);
               _aolaMorphCallbackRegistered = true;
               ExternalInterface.call("aolaMorphBridgeReady","2026082731219998");
            }
         }
         catch(error:Error)
         {
         }
      }

      private static function onAolaMorphRefresh(param1:Number = 0) : Boolean
      {
         try
         {
            setTimeout(dispatchAolaMorphRefresh,1);
            return true;
         }
         catch(error:Error)
         {
         }
         return false;
      }

      private static function dispatchAolaMorphRefresh() : void
      {
         PetPackageEventDispatcher.instance.openPackageHaiBao();
      }

      private static function getAolaMorphSkinId(param1:int) : int
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

      private function shouldRemoveOriginalBackground() : Boolean
      {
         var _loc1_:* = null;
         try
         {
            if(!ExternalInterface.available || this.pdi == null)
            {
               return false;
            }
            _loc1_ = ExternalInterface.call("aolaMorphShouldHideBackground",this.pdi.viewId);
            return _loc1_ === true;
         }
         catch(error:Error)
         {
         }
         return false;
      }
      
      private function needShowBtn() : Boolean
      {
         var _loc1_:PMData = this._ips.customData.pmDataMap.getPM(this.skinId);
         if(PackageSkinManager.instance.classify == Classify.LEGENDARY || PackageSkinManager.instance.classify == Classify.FULL_SCRREN)
         {
            return false;
         }
         return this._skinService.getPetSkinInfoBySkinId(this.skinId) != null || this.isGQPM();
      }
      
      private function isGQPM() : Boolean
      {
         var _loc1_:PMData = this._ips.customData.pmDataMap.getPM(this.skinId);
         return _loc1_.isGQPM();
      }
      
      private function isHasBg() : Boolean
      {
         if(this.shouldRemoveOriginalBackground())
         {
            return false;
         }
         if(this.pdi.useDIYBgId)
         {
            return true;
         }
         var _loc1_:PetSkinInfo = this._skinService.getPetSkinInfoBySkinId(this.skinId);
         if(_loc1_ == null)
         {
            return false;
         }
         if(Boolean(_loc1_.isNormalPet) && Boolean(_loc1_.hasPackageSkinState))
         {
            return this.isOpenHaiBao();
         }
         return Boolean(_loc1_.hasBackground) || Boolean(_loc1_.isSwitchPackageBG);
      }
      
      private function isOpenHaiBao() : Boolean
      {
         var _loc1_:PetSkinInfo = this._skinService.getPetSkinInfoBySkinId(this.skinId);
         return _loc1_ != null && Boolean(_loc1_.hasPackageSkinState) && Boolean(this._skinService.isOpenPetPackageState(this.skinId));
      }
   }
}

