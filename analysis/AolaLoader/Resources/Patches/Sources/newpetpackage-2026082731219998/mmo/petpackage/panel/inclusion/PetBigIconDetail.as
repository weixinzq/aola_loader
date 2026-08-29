package mmo.petpackage.panel.inclusion
{
   import com.adobe.utils.ArrayUtil;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.external.ExternalInterface;
   import flash.utils.setTimeout;
   import flash.geom.Point;
   import flash.text.TextField;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.textscroll.TextHorizontalScrollComponent;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.Item;
   import mmo.interfaces.material.item.UserItem;
   import mmo.interfaces.material.petclothes.UserPetClothes;
   import mmo.interfaces.material.pettitle.IPetTitleService;
   import mmo.interfaces.material.pettitle.PetTitleConfig;
   import mmo.interfaces.material.pettitle.PetTitleIconParam;
   import mmo.interfaces.material.pettitle.UserPetTitle;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.pet.data.PetDressInfosMap;
   import mmo.interfaces.pet.data.skin.IPetSkinDataService;
   import mmo.interfaces.pet.data.skin.PetSkinInfo;
   import mmo.interfaces.pet.petdress.IPetDress;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.interfaces.pet.petpackage.IPetPackageService;
   import mmo.interfaces.pet.petpackage.PetPackageTabs;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.operation.IPMEvolutionInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.share.IShareService;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.petpackage.DocClass;
   import mmo.petpackage.config.MagicChangeConfig;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.helper.ViewIndexHelper;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.petpackage.pettips.MagicPetTipsPanel;
   import mmo.petpackage.pettips.NormalPetTipsPanel;
   import mmo.petpackage.pettips.PetTipsManager;
   import mmo.petpackage.pettips.TwoPetTipsPanel;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.activity.helper.PetUIHelper;
   import mmo.play.activity.peticon.PetIconHandler;
   import mmo.play.actthings.helper.ActMaterialLoader;
   import mmo.play.entrysystem.EntrySystemIconHelper;
   import mmo.play.pet.petlabel.PetLabelConfig;
   import mmo.play.pet.petlabel.PetLabelIconHelper;
   import mmo.play.pet.petsound.PetSoundManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3112")]
   public class PetBigIconDetail extends Sprite implements IDispose
   {

      private static var _aolaMorphCallbackRegistered:Boolean = false;
      
      private static const DRESSPANEL_POINT:Point = new Point(-72,-438);
      
      public var mcBargainIcon:BargainIcon;
      
      public var mcEntrySystem:MovieClip;
      
      public var mcGQLight:MovieClip;
      
      public var mcLight:MovieClip;
      
      public var mcMagicCard:MovieClip;
      
      public var mcPetIcon:MovieClip;
      
      public var mcPetLabel:MovieClip;
      
      public var mcPetTitle:MovieClip;
      
      public var mc_attrscontainer:MovieClip;
      
      public var mccompletetips:MovieClip;
      
      public var mcshare:MovieClip;
      
      public var txtname:TextField;
      
      private var txtName:TextField = null;
      
      private var _petlabelContainer:DisplayObjectContainer;
      
      private var petDressPanel:MovieClip = null;
      
      private var petIconSwitch:Boolean = true;
      
      private var pdi:PetDetailedInfo = null;
      
      private var attIconContainer:Sprite = null;
      
      private var attIcons:Array = [];
      
      private var psms:IPetSkillMesService = null;
      
      private var curPbi:PetBriefInfo;
      
      private var isHaveMagic:Boolean;
      
      private var _mcCompleteTips:MovieClip;
      
      private var _attriContainer:Sprite;
      
      private var _viewId:int;
      
      private var _preSkinId:int = -1;
      
      private var _skinDataService:IPetSkinDataService = ServiceContainer.getService(IPetSkinDataService) as IPetSkinDataService;
      
      private var _mcPetIconContainer:Sprite;
      
      private var _petIconHandler:PetIconHandler;
      
      private var ipts:IPetTitleService = ServiceContainer.getService(IPetTitleService) as IPetTitleService;
      
      public function PetBigIconDetail()
      {
         super();
         ensureAolaMorphBridge();
         DocClass.ensureAolaCommandBridge();
         this.initPars();
         this.initFuns();
         CommonEventDispatcher.instance.addEventListener("PetBigIconDetailmcPetIconIsPlay",this.setIsIconPlay);
      }
      
      private function initPars() : void
      {
         this._attriContainer = PetUIHelper.getPetAttriDecsPanel(1);
         this.parent.addChild(this._attriContainer);
         this._attriContainer.x += 2000;
         this.txtName = this.txtname as TextField;
         new TextHorizontalScrollComponent().setText(this.txtName);
         this._petlabelContainer = this.getChildByName("mcPetLabel") as DisplayObjectContainer;
         var _loc1_:Sprite = this._mcPetIconContainer = this.getChildByName("mcPetIcon") as Sprite;
         this._petIconHandler = new PetIconHandler(_loc1_);
         this._mcCompleteTips = this.mccompletetips;
         this._mcCompleteTips.gotoAndStop(1);
         this._mcCompleteTips.visible = false;
         this._mcCompleteTips.addEventListener(MouseEvent.MOUSE_OVER,this.onCOver);
         this._mcCompleteTips.addEventListener(MouseEvent.MOUSE_OUT,this.onCOut);
         this.stopLightMovie();
         this.attIconContainer = this.mc_attrscontainer as Sprite;
         this.psms = ServiceContainer.getService(IPetSkillMesService) as IPetSkillMesService;
         TipsManager.getInstance().addTips(this.mcshare,"点击跟小伙伴炫耀这只亚比吧！",0,100,0,0,false);
      }
      
      private function initFuns() : void
      {
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.ON_SKIN_PRE_MOVIE_FINISH,this.onPreMovieFinish);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.ON_OPEN_HAI_BAO,this.onUpdateHaibao);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.ON_CLOSE_HAI_BAO,this.onUpdateHaibao);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_CLOTHES_BIGVIEW,this.onClothesView);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onPMDetailUpdate);
         CommonEventDispatcher.instance.addEventListener("ClothView",this.onAddPetClothes);
         CommonEventDispatcher.instance.addEventListener(PetTitleConfig.PET_TITLE_CHANGE_EVENT,this.onPetTitleChange);
         this.mcshare.addEventListener(MouseEvent.CLICK,this.sharePet);
         this.mcPetTitle.addEventListener(MouseEvent.CLICK,this.changeToInfo);
      }
      
      private function onPetTitleChange(param1:CommonEvent) : void
      {
         this.setPetTitle(this.curPbi);
      }
      
      private function changeToInfo(param1:MouseEvent) : void
      {
         var e:MouseEvent = param1;
         ServiceContainer.instance.tryGetService(ServiceNames.PET_PACKAGE,function(param1:IPetPackageService, param2:Object):void
         {
            param1.changeToTargetTab(PetPackageTabs.TAB_DECS);
         });
      }
      
      private function onUpdateHaibao(param1:Event) : void
      {
         if(this.curPbi != null)
         {
            this.updatePetIcon(this.curPbi);
         }
      }
      
      private function onPreMovieFinish(param1:Event) : void
      {
         this.afterOtherOperate();
      }
      
      private function sharePet(param1:MouseEvent) : void
      {
         var _loc2_:IShareService = ServiceContainer.instance.getService(IShareService) as IShareService;
         _loc2_.showOnePetPackageSharePanel(this.curPbi);
      }
      
      private function onPMDetailUpdate(param1:PetPackageEvent) : void
      {
         var _loc13_:String = null;
         var _loc2_:int = int(param1.params.id);
         var _loc3_:PetBriefInfo = PetDetailDataMap.instance.getPetDetailInfo(_loc2_);
         var _loc4_:String = "";
         if(this.curPbi)
         {
            _loc4_ = this.curPbi.wordText;
         }
         this.curPbi = _loc3_;
         this.curPbi = _loc3_;
         this.txtName.text = _loc3_.name;
         var _loc5_:int = int(this.curPbi.specialSkinId);
         if(_loc5_ > 0)
         {
            _loc13_ = ActMaterialLoader.getMaterialName(MaterialTypes.PET_SKIN,_loc5_);
            this.txtName.text = _loc13_;
         }
         PetLabelIconHelper.loadIconByRaceId(_loc3_.raceId,this._petlabelContainer,PetLabelConfig.LevelType_All);
         var _loc6_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc7_:PMData = _loc6_.customData.pmDataMap.getPM(_loc3_.raceId);
         var _loc8_:Sprite = this.getChildByName("mcEntrySystem") as Sprite;
         if(_loc7_.isHaveEntry)
         {
            this.loadEntryIcon(_loc8_,_loc7_);
         }
         else
         {
            DisplayUtil.clearChildren(_loc8_);
         }
         this.updatePetIcon(_loc3_,_loc4_);
         this.addAtts(_loc3_);
         this._mcCompleteTips.visible = Boolean(_loc7_.isCompletePM()) && Boolean(_loc7_.isMiraclePet());
         this._mcCompleteTips.gotoAndStop(1);
         this.addMagicTips(_loc3_);
         var _loc9_:MovieClip = this.getChildByName("mcshare") as MovieClip;
         var _loc10_:MovieClip = this.getChildByName("mcMagicCard") as MovieClip;
         _loc9_.visible = !_loc7_.isGQPM();
         _loc10_.visible = !_loc7_.isGQPM();
         var _loc11_:MovieClip = this.getChildByName("mcGQLight") as MovieClip;
         _loc11_.visible = _loc7_.isGQPM();
         var _loc12_:PetSkinInfo = this._skinDataService.getPetSkinInfoBySkinId(this.getSkinId(_loc3_));
         if(_loc12_ != null && Boolean(_loc12_.hasBackground))
         {
            _loc11_.visible = false;
         }
         else if(_loc3_.useDIYBgId > 0)
         {
            _loc11_.visible = false;
         }
         this.setPetTitle(_loc3_);
      }
      
      private function setPetTitle(param1:PetBriefInfo) : void
      {
         var _loc2_:MovieClip = this.getChildByName("mcPetTitle") as MovieClip;
         var _loc3_:UserPetTitle = this.ipts.getUsingUserPetTitleByRaceId(param1.raceId);
         _loc2_.visible = _loc3_ != null;
         if(_loc3_ != null)
         {
            ActMaterialLoader.setView(_loc2_,MaterialTypes.PET_TITLE,_loc3_.materialId,true,null,new PetTitleIconParam(PetTitleIconParam.SIZE_SMALL,9999,_loc3_));
            _loc2_.buttonMode = true;
         }
      }
      
      private function loadEntryIcon(param1:Sprite, param2:PMData) : void
      {
         var _loc7_:Sprite = null;
         var _loc8_:Sprite = null;
         var _loc3_:Array = [];
         var _loc4_:int = 0;
         while(_loc4_ < param1.numChildren)
         {
            _loc7_ = param1.getChildAt(_loc4_) as Sprite;
            if((Boolean(_loc7_)) && _loc7_.name.indexOf("mcEntrySystem_") != -1)
            {
               _loc3_.push(int(_loc7_.name.split("_")[1]));
            }
            _loc4_++;
         }
         var _loc5_:Array = param2.entrySystemIndexArr;
         if(ArrayUtil.arraysAreEqual(_loc3_,_loc5_))
         {
            return;
         }
         DisplayUtil.clearChildren(param1);
         var _loc6_:int = 0;
         while(_loc6_ < _loc5_.length)
         {
            _loc8_ = new Sprite();
            _loc8_.x = _loc6_ * 30;
            _loc8_.y = 0;
            _loc8_.name = "mcEntrySystem_" + _loc5_[_loc6_];
            param1.addChild(_loc8_);
            EntrySystemIconHelper.loadIcon(_loc5_[_loc6_],_loc8_,25,25);
            _loc6_++;
         }
      }
      
      private function addMagicTips(param1:PetBriefInfo) : void
      {
         var _loc3_:int = 0;
         var _loc6_:Sprite = null;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         this.isHaveMagic = false;
         var _loc2_:MovieClip = this.getChildByName("mcMagicCard") as MovieClip;
         TipsManager.getInstance().removeTips(_loc2_);
         PetTipsManager.instance.removeTips(_loc2_);
         _loc2_.removeEventListener(MouseEvent.CLICK,this.onClickMagicChange);
         var _loc4_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc5_:Vector.<IPMEvolutionInfo> = _loc4_.getOperationPM(param1.raceId).getCommonEvolutionList();
         if(_loc5_ == null)
         {
            _loc3_ = int(param1.raceId);
         }
         else
         {
            _loc7_ = 0;
            while(_loc7_ < _loc5_.length)
            {
               if(_loc5_[_loc7_].raceId == param1.raceId)
               {
                  if(_loc5_.length <= _loc7_ + 1)
                  {
                     _loc3_ = int(param1.raceId);
                  }
                  else
                  {
                     _loc3_ = int(_loc5_[_loc7_ + 1].raceId);
                  }
               }
               _loc7_++;
            }
         }
         if(MagicChangeConfig.isHaveMagicCard(param1.raceId))
         {
            _loc2_.gotoAndStop(2);
            _loc2_.buttonMode = true;
            _loc2_.addEventListener(MouseEvent.CLICK,this.onClickMagicChange);
            _loc8_ = MagicChangeConfig.getMagicItemId(param1.raceId);
            this.loadItemIcon(_loc8_);
            _loc9_ = MagicChangeConfig.getMagicRaceId(param1.raceId);
            if(param1.viewId == _loc9_)
            {
               this.isHaveMagic = true;
               TipsManager.getInstance().addTips(_loc2_,"点击幻化卡可以还原亚比形态哦！",60);
            }
            else if(_loc3_ == param1.raceId)
            {
               _loc6_ = new MagicPetTipsPanel(_loc9_) as Sprite;
               PetTipsManager.instance.addTips(_loc2_,_loc6_);
            }
            else
            {
               _loc6_ = new TwoPetTipsPanel([_loc3_,_loc9_]) as Sprite;
               PetTipsManager.instance.addTips(_loc2_,_loc6_);
            }
         }
         else
         {
            _loc2_.gotoAndStop(1);
            _loc2_.buttonMode = false;
            _loc10_ = int(_loc4_.getOperationPM(param1.raceId).getMaxCommonEvlution().raceId);
            if(_loc10_ == param1.raceId)
            {
               TipsManager.getInstance().addTips(_loc2_,"亚比已经是最终形态了哦！",60);
            }
            else
            {
               _loc6_ = new NormalPetTipsPanel(_loc3_) as Sprite;
               PetTipsManager.instance.addTips(_loc2_,_loc6_);
            }
         }
      }
      
      private function loadItemIcon(param1:int) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function onClickMagicChange(param1:MouseEvent) : void
      {
         var itemId:int = 0;
         var magicRaceId:int = 0;
         var pmService:IPMService = null;
         var endName:String = null;
         var evt:MouseEvent = param1;
         itemId = MagicChangeConfig.getMagicItemId(this.curPbi.raceId);
         var itemService:IItemService = ServiceContainer.getService(IItemService) as IItemService;
         var userItem:UserItem = itemService.getMyItemById(itemId);
         var item:Item = itemService.getItemById(itemId);
         if(userItem == null || userItem.quantity == 0)
         {
            new NoMagicCardPanel(item.name).showPanel();
            return;
         }
         if(this.isHaveMagic)
         {
            this.becomeBackView(itemId);
         }
         else
         {
            magicRaceId = MagicChangeConfig.getMagicRaceId(this.curPbi.raceId);
            pmService = ServiceContainer.getService(IPMService) as IPMService;
            endName = pmService.customData.pmDataMap.getPM(magicRaceId).pmName;
            new MagicChangeConfirmPanel(this.curPbi.name,endName,function():void
            {
               goMagicChange(itemId);
            }).showPanel();
         }
      }
      
      private function goMagicChange(param1:int) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showLightMovie() : void
      {
         var mcLight:MovieClip = this.getChildByName("mcLight") as MovieClip;
         mcLight.visible = true;
         ProgressFullSprite.lockScreen();
         mcLight.addFrameScript(mcLight.totalFrames - 1,function():void
         {
            ProgressFullSprite.unlockScreen();
            stopLightMovie();
         });
         mcLight.gotoAndPlay(1);
      }
      
      private function stopLightMovie() : void
      {
         var _loc1_:MovieClip = this.getChildByName("mcLight") as MovieClip;
         _loc1_.visible = false;
         _loc1_.gotoAndStop(1);
      }
      
      private function becomeBackView(param1:int) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function updatePetIcon(param1:PetBriefInfo, param2:String = "") : void
      {
         var _loc3_:int = this.getSkinId(param1);
         if(this._skinDataService.isOpenPetPackageState(_loc3_))
         {
            PetSoundManager.instance.disposeLastSound();
            this.tryDisposePetIcon();
            return;
         }
         if(param1.useDIYBgId > 0)
         {
            PetSoundManager.instance.disposeLastSound();
            this.tryDisposePetIcon();
            this._mcPetIconContainer.visible = false;
            return;
         }
         if(this._preSkinId > 0 && this._preSkinId == _loc3_ && param2 == param1.wordText)
         {
            return;
         }
         PetSoundManager.instance.disposeLastSound();
         this.tryDisposePetIcon();
         this._preSkinId = _loc3_;
         this._viewId = param1.viewId;
         if(!this._skinDataService.needShowPetView(this.getSkinId(param1)))
         {
            this.skinPlayPetSound(this.getSkinId(param1));
            this._mcPetIconContainer.visible = false;
            return;
         }
         var _loc4_:PetSkinInfo = this._skinDataService.getPetSkinInfoBySkinId(this.getSkinId(param1));
         if(_loc4_ != null && Boolean(_loc4_.hasPreMovie) && Boolean(this._skinDataService.canShowPreMovie(param1.viewId)))
         {
            return;
         }
         this.afterOtherOperate();
      }
      
      private function afterOtherOperate() : void
      {
         this._mcPetIconContainer.visible = true;
         var _loc1_:int = PetIconContainer.isBitMapType(this.curPbi.viewId) ? int(PetIconType.BIT_MAP) : int(PetIconType.LARGE);
         this._petIconHandler.setIcon(this.curPbi.viewId,_loc1_,this.curPbi);
         this._petIconHandler.visible = this.petIconSwitch;
      }
      
      private function getSkinId(param1:PetBriefInfo) : int
      {
         if(param1.specialSkinId > 0)
         {
            return getAolaMorphSkinId(param1.specialSkinId);
         }
         return getAolaMorphSkinId(param1.viewId);
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
      
      private function onPetIconLoaded() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ArrayIndexOutOfBoundsException (-1)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function skinPlayPetSound(param1:int) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function tryDisposePetIcon() : void
      {
         if(this._petIconHandler)
         {
            this._petIconHandler.clearIcon();
         }
         this._viewId = -1;
         this._preSkinId = -1;
      }
      
      private function onClothesView(param1:PetPackageEvent) : void
      {
         var _loc2_:Boolean = Boolean(param1.params.isNew);
         var _loc3_:Boolean = Boolean(param1.params.visible);
         var _loc4_:PetDetailedInfo = param1.params.pdi;
         var _loc5_:Boolean = this.pdi == null ? true : this.pdi.id != _loc4_.id;
         this.pdi = param1.params.pdi;
         if(_loc2_ && null == this.petDressPanel)
         {
            this.initPetDressPanel();
            _loc5_ = false;
         }
         if(null != this.petDressPanel && null != this.pdi && _loc5_)
         {
            IPetDress(this.petDressPanel).freshDressPanelByPetId(this.pdi);
         }
         this.switchBigView(_loc3_,this.pdi);
      }
      
      private function initPetDressPanel() : void
      {
         var _loc1_:Class = getDefinitionByName("mmo.pet.petdress.view.dress.PetDressPanel") as Class;
         this.petDressPanel = new _loc1_() as MovieClip;
         this._mcPetIconContainer.addChild(this.petDressPanel);
         this.petDressPanel.x = DRESSPANEL_POINT.x;
         this.petDressPanel.y = DRESSPANEL_POINT.y;
         IPetDress(this.petDressPanel).freshDressPanelByPetId(this.pdi);
      }
      
      private function switchBigView(param1:Boolean, param2:PetBriefInfo) : void
      {
         var _loc3_:* = undefined;
         if(param1)
         {
            _loc3_ = null == param2 ? false : PetDressInfosMap.instance.isAbleToBeDress(param2.viewId);
         }
         this._petIconHandler.visible = !_loc3_;
         this.setVisable(this.petDressPanel,_loc3_);
         this.petIconSwitch = !_loc3_;
      }
      
      private function setVisable(param1:DisplayObject, param2:Boolean) : void
      {
         if(null != param1)
         {
            param1.visible = param2;
         }
      }
      
      private function onAddPetClothes(param1:CommonEvent) : void
      {
         var _loc2_:UserPetClothes = param1.params.UserClothes;
         var _loc3_:Object = PetDetailDataMap.instance.getPetInfo(this.pdi.id);
         var _loc4_:String = _loc3_.pmPView.drs;
         _loc4_ = null == _loc4_ ? "" : _loc4_;
         _loc4_ = _loc4_ + "," + _loc2_.materialId;
         _loc3_.pmPView.drs = _loc4_;
         PetDetailDataMap.instance.tryUpdateCachhe(this.pdi.id,true);
      }
      
      private function addAtts(param1:PetBriefInfo) : void
      {
         var _loc2_:Sprite = null;
         var _loc3_:Object = null;
         var _loc4_:Array = null;
         var _loc5_:Array = null;
         var _loc7_:MovieClip = null;
         var _loc8_:Sprite = null;
         var _loc9_:String = null;
         if(null == param1)
         {
            return;
         }
         for each(_loc2_ in this.attIcons)
         {
            DisplayUtil.stopAndRemove(_loc2_);
            _loc2_.removeEventListener(MouseEvent.CLICK,this.onAttrDetail);
            _loc2_.removeEventListener(MouseEvent.MOUSE_OUT,this.onOut);
         }
         this.attIcons = [];
         _loc3_ = this.psms.getPetMes(param1.raceId);
         _loc4_ = null;
         _loc5_ = null;
         if(int(_loc3_.attribute) == int(_loc3_.attribute2))
         {
            _loc4_ = [_loc3_.attribute];
            _loc5_ = ["01"];
         }
         else
         {
            _loc4_ = [_loc3_.attribute,_loc3_.attribute2];
            _loc5_ = ["10","12"];
         }
         var _loc6_:int = 0;
         while(_loc6_ < _loc4_.length)
         {
            _loc7_ = new PetDetailSkill_Attr() as MovieClip;
            _loc7_.name = "attribute_" + _loc4_[_loc6_];
            _loc7_.mouseChildren = false;
            _loc8_ = this.psms.getPetAttributeIconByRaceId(param1.raceId,_loc6_ + 1);
            DisplayUtil.scaleDisplay(_loc8_,_loc7_.width * 0.75,_loc7_.height * 0.75);
            DisplayUtil.alignDisplay(_loc8_,_loc7_,"11",false);
            _loc7_.addChild(_loc8_);
            DisplayUtil.scaleDisplay(_loc7_,this.attIconContainer.width,this.attIconContainer.height);
            DisplayUtil.alignDisplay(_loc7_,this.attIconContainer,_loc5_[_loc6_],false);
            this.attIconContainer.addChild(_loc7_);
            _loc7_.addEventListener(MouseEvent.MOUSE_OVER,this.onAttrDetail);
            _loc7_.addEventListener(MouseEvent.MOUSE_OUT,this.onOut);
            this.attIcons.push(_loc7_);
            MovieClip(_loc7_).buttonMode = true;
            _loc7_.addEventListener(MouseEvent.CLICK,this.onShowAtt);
            _loc9_ = this.psms.getPetAttributeTipsByattributeId(_loc4_[_loc6_]);
            TipsManager.getInstance().addTips(_loc7_,_loc9_ + "系",60);
            _loc6_++;
         }
      }
      
      private function onShowAtt(param1:MouseEvent) : void
      {
         var attId:int = 0;
         var e:MouseEvent = param1;
         var ct:InteractiveObject = e.currentTarget as InteractiveObject;
         attId = int(ct.name.split("_")[1]);
         SimpleCustomLoader.loadSingleResource("pet/petracecontinencepanel","mmo.pet.petracecontinence.RaceContinencePanel",LoadingSpriteType.DIALOG,"载入中",function(param1:Object):void
         {
            param1.showPanelByRaceId(attId);
         });
      }
      
      private function onAttrDetail(param1:MouseEvent) : void
      {
         var _loc2_:MovieClip = param1.target as MovieClip;
         _loc2_.gotoAndStop(2);
         var _loc3_:DisplayObject = DisplayObject(_loc2_.getChildAt(1));
         _loc3_.scaleX *= 1.17;
         _loc3_.scaleY *= 1.17;
         _loc3_.x -= 2;
         _loc3_.y -= 2;
         var _loc4_:int = int(_loc2_.name.split("_")[1]);
         if(this._attriContainer.numChildren <= 0)
         {
            return;
         }
         this._attriContainer.x = this.parent.x + this.attIconContainer.x + this.attIconContainer.width + 2;
         this._attriContainer.y = this.parent.y + 40;
         var _loc5_:MovieClip = this._attriContainer.getChildAt(0) as MovieClip;
         _loc5_.gotoAndStop(_loc4_);
         ViewIndexHelper.move2top(this._attriContainer);
      }
      
      private function onOut(param1:MouseEvent) : void
      {
         var _loc2_:MovieClip = param1.target as MovieClip;
         _loc2_.gotoAndStop(1);
         var _loc3_:DisplayObject = DisplayObject(_loc2_.getChildAt(1));
         _loc3_.scaleX /= 1.17;
         _loc3_.scaleY /= 1.17;
         _loc3_.x += 2;
         _loc3_.y += 2;
         this._attriContainer.x += 2000;
      }
      
      private function onCOver(param1:MouseEvent) : void
      {
         this._mcCompleteTips.gotoAndStop(2);
         var _loc2_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc3_:Array = _loc2_.getCompleteMiraclePMData(this.curPbi.raceId).addedAttribute;
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_.length)
         {
            Panel_Helper.setTextValue(this._mcCompleteTips,"txt" + _loc4_,"+" + _loc3_[_loc4_]);
            _loc4_++;
         }
      }
      
      private function onCOut(param1:MouseEvent) : void
      {
         this._mcCompleteTips.gotoAndStop(1);
      }
      
      public function dispose() : void
      {
         if(null != this.petDressPanel)
         {
            IPetDress(this.petDressPanel).closePetDress();
         }
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.ON_SKIN_PRE_MOVIE_FINISH,this.onPreMovieFinish);
         PetSoundManager.instance.disposeLastSound();
         if(this._petIconHandler)
         {
            this._petIconHandler.dispose();
         }
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.ON_OPEN_HAI_BAO,this.onUpdateHaibao);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.ON_CLOSE_HAI_BAO,this.onUpdateHaibao);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onPMDetailUpdate);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_CLOTHES_BIGVIEW,this.onClothesView);
         CommonEventDispatcher.instance.removeEventListener("ClothView",this.onAddPetClothes);
         CommonEventDispatcher.instance.removeEventListener(PetTitleConfig.PET_TITLE_CHANGE_EVENT,this.onPetTitleChange);
         BargainIcon(this.mcBargainIcon).dispose();
         CommonEventDispatcher.instance.removeEventListener("PetBigIconDetailmcPetIconIsPlay",this.setIsIconPlay);
         PetLabelIconHelper.clearLabelIcon(this._petlabelContainer);
      }
      
      private function setIsIconPlay(param1:CommonEvent) : void
      {
         this._petIconHandler && this._petIconHandler.setIsStatic(!param1.params.isPlay);
      }
   }
}

