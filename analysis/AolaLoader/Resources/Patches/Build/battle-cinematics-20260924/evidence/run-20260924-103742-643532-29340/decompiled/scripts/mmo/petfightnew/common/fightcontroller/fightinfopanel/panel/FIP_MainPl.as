package mmo.petfightnew.common.fightcontroller.fightinfopanel.panel
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.tabhead.TabHead;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_BasePl;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_Info;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_YinJiHelper;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.tab.FIP_TabBase;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.tab.FIP_TabFactory;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.tab.FIP_TabId;
   import mmo.petfightnew.common.handler.PetHeadIconHandler;
   import mmo.play.activity.framework.util.CallbackUtil;
   import mmo.play.activity.peticon.PetIconHandler;
   
   public class FIP_MainPl extends FIP_BasePl
   {
      
      private static const MaxPetNum:int = 6;
      
      private static const DefaultTabIndex:int = 0;
      
      private static const NoGQPmTabIndex:int = 4;
      
      private var _petIconHandlers:Array = [];
      
      private var _tabHead:TabHead;
      
      private var _tabs:Array = [];
      
      private var _currPetHandler:PetIconHandler;
      
      private var _isShow:Boolean = false;
      
      private var _pmSvr:IPMService = ServiceContainer.getService(IPMService);
      
      private var _isShowYinJi:Boolean;
      
      private var _yinjiHelper:FIP_YinJiHelper = null;
      
      public function FIP_MainPl(param1:FIP_Info = null)
      {
         super("FIP_MainPl",param1);
      }
      
      override protected function initComponents() : void
      {
         var _loc4_:MovieClip = null;
         super.initComponents();
         var _loc1_:MovieClip = this.getChild("mcTabContent");
         var _loc2_:int = 0;
         while(_loc2_ < _loc1_.numChildren)
         {
            _loc4_ = this.getChild(["mcTabContent","mcTab" + _loc2_]);
            _loc4_.visible = false;
            _loc2_++;
         }
         var _loc3_:MovieClip = this.getChild("mcTabHead");
         this._tabHead = new TabHead(_loc3_);
         this._tabHead.verifyHandler = this.verifyTab;
         this._tabHead.onTabChange = this.onTabChange;
         this._currPetHandler = new PetIconHandler(this.getChild(["mcPetContainer","mcPet"]),false,true);
         _info.initSelect();
         this._isShowYinJi = false;
         this._yinjiHelper = new FIP_YinJiHelper(_info,this.getChild("mcYinJi"));
      }
      
      override public function showPanel() : void
      {
         this._isShow = true;
         super.showPanel();
      }
      
      override protected function addListeners() : void
      {
         super.addListeners();
         this._info.addEventListener(FIP_Info.EVENT_CHANGE_TAB,this.onEventChangeTab);
         this._info.addEventListener(FIP_Info.EVENT_CHANGE_PET,this.onEventChangeTab);
      }
      
      override protected function onClickButton(param1:DisplayObject) : void
      {
         var _loc2_:String = param1.name;
         switch(_loc2_)
         {
            case "btnSelect":
               this._info.setIsSelectMe(!this._info.isSelectMe);
               this.refreshPanel();
               break;
            case "btnPet":
               this._info.selectPetIndex = this.intelligentlyGetIndex(param1);
               this.refreshPanel();
               break;
            case "btnYinji":
               this._isShowYinJi = true;
               this.refreshYinJi();
               break;
            case "btnCloseYinJi":
               this._isShowYinJi = false;
               this.refreshYinJi();
         }
      }
      
      override protected function refreshPanel(param1:Object = null) : void
      {
         var _loc5_:MovieClip = null;
         var _loc6_:MovieClip = null;
         var _loc7_:PetHeadIconHandler = null;
         var _loc8_:MovieClip = null;
         var _loc9_:int = 0;
         super.refreshPanel();
         this.refreshSecond();
         this.setFrame("mcSelect0",_info.isSelectMe ? 2 : 1);
         this.setFrame("mcSelect1",_info.isSelectMe ? 1 : 2);
         this.setVisible(["mcTabHead","mcTabHead3"],_info.isSelectMe);
         var _loc2_:Array = _info.pets;
         var _loc3_:int = 0;
         while(_loc3_ < MaxPetNum)
         {
            _loc5_ = this.getChild("mcPetIconContainer" + _loc3_) as MovieClip;
            _loc6_ = this.getChild([_loc5_,"mcPetIcon"]);
            _loc6_.mouseChildren = _loc6_.mouseEnabled = false;
            if(_loc3_ < _loc2_.length)
            {
               this.setVisible(_loc5_,true);
               _loc7_ = this._petIconHandlers[_loc3_];
               if(_loc7_ == null)
               {
                  _loc7_ = new PetHeadIconHandler(_loc6_,0.8);
                  this._petIconHandlers[_loc3_] = _loc7_;
               }
               _loc7_.setIcon(_loc2_[_loc3_].viewId);
               _loc8_ = this.getChild([_loc5_,"mcPetIconBG"]) as MovieClip;
               _loc8_.gotoAndStop(_info.selectPetIndex == _loc3_ ? 2 : 1);
            }
            else
            {
               this.setVisible(_loc5_,false);
            }
            _loc3_++;
         }
         var _loc4_:int = PetIconContainer.isBitMapType(_info.currSelectPbi().viewId) ? int(PetIconType.BIT_MAP) : int(PetIconType.LARGE);
         this._currPetHandler.setIcon(_info.currSelectPbi().viewId,_loc4_);
         if(_info.getIsSelectGQPm())
         {
            if(this._tabHead.selectIndex == FIP_TabId.TRAIN && !_info.isSelectMe)
            {
               this._tabHead.changeTab(DefaultTabIndex,true);
            }
            else
            {
               _loc9_ = this._tabHead.selectIndex < 0 || this._tabHead.selectIndex >= 4 ? DefaultTabIndex : int(this._tabHead.selectIndex);
               this._tabHead.changeTab(_loc9_,true);
            }
            this.setVisible("btnYinji",_info.isSelectMe);
         }
         else
         {
            this._tabHead.changeTab(NoGQPmTabIndex,true);
            this.setVisible("btnYinji",false);
         }
         this.refreshYinJi();
      }
      
      private function verifyTab(param1:int, param2:Function) : void
      {
         if(!_info.getIsSelectGQPm() && param1 != NoGQPmTabIndex)
         {
            return;
         }
         CallbackUtil.apply(param2);
      }
      
      private function onTabChange(param1:int) : void
      {
         this.initTab(param1,this.bindCaller(this.refreshSelectTab,this));
      }
      
      private function refreshSelectTab() : void
      {
         var _loc3_:FIP_TabBase = null;
         var _loc1_:int = int(this._tabHead.totalTab);
         var _loc2_:int = 0;
         while(_loc2_ < _loc1_)
         {
            _loc3_ = this._tabs[_loc2_];
            if(_loc3_ != null)
            {
               if(this._tabHead.selectIndex == _loc2_)
               {
                  _loc3_.show();
               }
               else
               {
                  _loc3_.hide();
               }
            }
            _loc2_++;
         }
      }
      
      private function initTab(param1:int, param2:Function) : void
      {
         var _loc3_:MovieClip = null;
         if(this._tabs[param1] == null)
         {
            _loc3_ = this.getChild(["mcTabContent","mcTab" + param1]);
            this.initTabView(_loc3_,param1,param2);
         }
         else
         {
            CallbackUtil.apply(param2);
         }
      }
      
      private function initTabView(param1:*, param2:int, param3:Function) : void
      {
         var _loc4_:FIP_TabBase = FIP_TabFactory.getTab(this._info,param2,this.bindCaller(this.refreshTabCommonView,this));
         this._tabs[param2] = _loc4_;
         _loc4_.registerView(param1);
         CallbackUtil.apply(param3);
      }
      
      private function refreshTabCommonView() : void
      {
      }
      
      public function refreshSecond() : void
      {
         this.setArtNum("mcNum",_info.leftSecond);
         this.setVisible("mcNum",_info.leftSecond > 0);
      }
      
      private function refreshYinJi() : void
      {
         if(this._isShowYinJi && _info.isSelectMe)
         {
            this.setVisible("mcYinJi",true);
            this._yinjiHelper.refreshView();
         }
         else
         {
            this.setVisible("mcYinJi",false);
         }
      }
      
      private function onEventChangeTab(param1:CommonEvent) : void
      {
         this._tabHead && this._tabHead.changeTab(param1.params.tab,true);
      }
      
      override public function dispose() : void
      {
         var _loc1_:PetHeadIconHandler = null;
         var _loc2_:int = 0;
         var _loc3_:FIP_TabBase = null;
         super.dispose();
         this._isShow = false;
         this._info.removeEventListener(FIP_Info.EVENT_CHANGE_TAB,this.onEventChangeTab);
         this._info.removeEventListener(FIP_Info.EVENT_CHANGE_PET,this.onEventChangeTab);
         this._currPetHandler && this._currPetHandler.dispose();
         for each(_loc1_ in this._petIconHandlers)
         {
            _loc1_.dispose();
         }
         this._petIconHandlers = [];
         _loc2_ = 0;
         while(_loc2_ < this._tabs.length)
         {
            _loc3_ = this._tabs[_loc2_];
            _loc3_ && _loc3_.dispose();
            _loc2_++;
         }
         this._tabs = [];
         this._yinjiHelper = null;
      }
      
      public function get isShow() : Boolean
      {
         return this._isShow;
      }
   }
}

