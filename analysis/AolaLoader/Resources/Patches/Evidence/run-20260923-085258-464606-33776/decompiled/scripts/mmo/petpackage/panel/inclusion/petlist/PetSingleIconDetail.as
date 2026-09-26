package mmo.petpackage.panel.inclusion.petlist
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.external.ExternalInterface;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.textscroll.TextHorizontalScrollComponent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.miraclepet.IMiraclePetDataService;
   import mmo.interfaces.miraclepet.MiraclePetInfo;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetRideInfo;
   import mmo.interfaces.pet.data.PetRideInfosMap;
   import mmo.interfaces.pet.peticon.IPetIcon;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.petcorps.IPetCorpsService;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.play.actthings.helper.ActPetLoader;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3010")]
   public class PetSingleIconDetail extends MovieClip implements IDispose
   {
      
      public var mccomplete:MovieClip;
      
      public var mcs0:MovieClip;
      
      public var mcs1:MovieClip;
      
      public var mcs2:MovieClip;
      
      public var mcs3:MovieClip;
      
      public var mcs4:MovieClip;
      
      public var petcontainer:MovieClip;
      
      public var rideLabel:MovieClip;
      
      public var txt_hp:TextField;
      
      public var txt_level:TextField;
      
      public var txt_name:TextField;
      
      private var _petCorpsSvr:IPetCorpsService = ServiceContainer.getService(IPetCorpsService) as IPetCorpsService;
      
      private var _petbi:PetBriefInfo = null;
      
      private var _objData:Object = null;
      
      private var petIconService:IPetIcon = null;
      
      private var txtName:TextField = null;
      
      private var txtHp:TextField = null;
      
      private var txtLevel:TextField = null;
      
      private var petContainer:Sprite = null;
      
      private var petIcon:PetIconContainer = null;
      
      private var _preViewId:int = -1;
      
      private var _scrollTxt:TextHorizontalScrollComponent = null;
      
      private var _actPetLoader:ActPetLoader;
      
      public function PetSingleIconDetail()
      {
         super();
         this.gotoAndStop(1);
         this.initPars();
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.ON_OPEN_HAI_BAO,this.onAolaMorphRefresh);
      }
      
      private static function getAolaMorphIconId(param1:int) : int
      {
         var _loc2_:* = null;
         var _loc3_:int = 0;
         try
         {
            if(!ExternalInterface.available)
            {
               return param1;
            }
            _loc2_ = ExternalInterface.call("aolaMorphResolveIconId",param1);
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
      
      private function initPars() : void
      {
         this.txtName = this.txt_name as TextField;
         if(this._scrollTxt == null)
         {
            this._scrollTxt = new TextHorizontalScrollComponent();
            this._scrollTxt.setText(this.txtName);
         }
         this.txtHp = this.txt_hp as TextField;
         this.txtLevel = this.txt_level as TextField;
         this.petContainer = this.petcontainer as Sprite;
         this.petIconService = ServiceContainer.getService("PetIconService") as IPetIcon;
      }
      
      public function setData(param1:Object, param2:PetBriefInfo) : void
      {
         var pmService:IPMService;
         var pmData:PMData;
         var frame:int = 0;
         var mcComplete:MovieClip = null;
         var completeFrame:int = 0;
         var errorInfo:String = null;
         var obj:Object = param1;
         var pbi:PetBriefInfo = param2;
         this._objData = obj;
         this._petbi = pbi;
         if(PetDetailDataMap.instance.checkCache(this._petbi.id))
         {
            this._petbi = PetDetailDataMap.instance.getPetDetailInfo(this._petbi.id);
         }
         this.setRideLabel(this._petbi.raceId);
         pmService = ServiceContainer.getService(IPMService) as IPMService;
         pmData = pmService.customData.pmDataMap.getPM(this._petbi.raceId);
         try
         {
            if(pmData.isGQPM())
            {
               this.gotoAndStop(11);
            }
            else if(pmData.isXinghuiPM())
            {
               frame = 6 + pmData.getXinghuiPetStarLevel();
               this.gotoAndStop(frame);
            }
            else if(pmData.isDegeneratorPM())
            {
               this.gotoAndStop(6);
            }
            else if(pmData.isLegendPM())
            {
               this.gotoAndStop(5);
            }
            else if(pmData.isCompletePM())
            {
               this.gotoAndStop(4);
               mcComplete = this.mccomplete;
               completeFrame = pmData.isMiraclePet() ? 1 : 2;
               mcComplete.gotoAndStop(completeFrame);
            }
            else if(this._petbi.isGetAoYiSkill)
            {
               this.gotoAndStop(2);
            }
            else if(pmData.isMiraclePet())
            {
               this.gotoAndStop(3);
               this.refreshGod();
            }
            else
            {
               this.gotoAndStop(1);
            }
         }
         catch(e:Error)
         {
            errorInfo = "亚比的raceId：" + _petbi.raceId + "\n亚比的pmId：" + _petbi.id + "\n";
         }
         this.initPars();
         this.updateUI();
      }
      
      private function setRideLabel(param1:int) : void
      {
         var _loc2_:PetRideInfo = PetRideInfosMap.instance.getPetRideInfo(param1);
         var _loc3_:* = _loc2_ != null;
         this.rideLabel.visible = _loc3_;
      }
      
      private function refreshGod() : void
      {
         var _loc5_:MovieClip = null;
         var _loc1_:IMiraclePetDataService = ServiceContainer.getService(IMiraclePetDataService) as IMiraclePetDataService;
         var _loc2_:MiraclePetInfo = _loc1_.getMiraclePetInfo(this._petbi.raceId);
         var _loc3_:int = int(_loc2_.breakLevel);
         var _loc4_:int = 0;
         while(_loc4_ < 5)
         {
            _loc5_ = this.getChildByName("mcs" + _loc4_) as MovieClip;
            _loc5_.visible = _loc4_ < _loc3_;
            _loc4_++;
         }
      }
      
      private function updateUI() : void
      {
         this.txtName.text = "" + this._petbi.nickname;
         var _loc1_:int = Math.ceil(this._petCorpsSvr.getTotalAddAbilitys()[0]);
         if(this._petbi.curHp < this._petbi.maxHp)
         {
            this.txtHp.text = "" + this._petbi.curHp + "/" + (this._petbi.maxHp + _loc1_);
         }
         else
         {
            this.txtHp.text = "" + (this._petbi.curHp + _loc1_) + "/" + (this._petbi.maxHp + _loc1_);
         }
         this.txtLevel.text = "等级" + this._petbi.level;
         if(this._preViewId == this._petbi.viewId)
         {
            return;
         }
         this._preViewId = this._petbi.viewId;
         this.loadYabiFightHead();
      }
      
      private function onLoaded(param1:PetIconEvent) : void
      {
         if(param1.raceId != this._petbi.viewId)
         {
            return;
         }
         var _loc2_:PetIconContainer = param1.currentTarget as PetIconContainer;
         _loc2_.removeEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoaded);
         this.petIcon.icon2BitmapWithScale(this.petContainer.width,this.petContainer.height);
         DisplayUtil.alignDisplay(this.petIcon,this.petContainer,"11",false);
         this.petContainer.addChild(this.petIcon);
      }
      
      private function tryDisposePetIcon() : void
      {
         if(null != this.petIcon)
         {
            this.petIcon.removeEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoaded);
            DisplayUtil.stopAndRemove(this.petIcon);
         }
      }
      
      public function dispose() : void
      {
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.ON_OPEN_HAI_BAO,this.onAolaMorphRefresh);
         this.tryDisposePetIcon();
         if(this._actPetLoader != null)
         {
            this._actPetLoader.dispose();
            this._actPetLoader = null;
         }
      }
      
      private function onAolaMorphRefresh(param1:Event) : void
      {
         if(this._petbi == null)
         {
            return;
         }
         if(this._actPetLoader != null)
         {
            this._actPetLoader.dispose();
            this._actPetLoader = null;
         }
         DisplayUtil.clearChildren(this.petContainer);
         this._preViewId = this._petbi.viewId;
         this.loadYabiFightHead();
      }
      
      private function loadYabiFightHead() : void
      {
         var _loc1_:PetSingleIconDetail = this;
         if(_loc1_._actPetLoader == null)
         {
            _loc1_._actPetLoader = new ActPetLoader();
         }
         _loc1_._actPetLoader.setPetViewWithCallback(_loc1_.petContainer as MovieClip,getAolaMorphIconId(_loc1_._petbi.viewId),PetIconType.FIGHT);
      }
   }
}

