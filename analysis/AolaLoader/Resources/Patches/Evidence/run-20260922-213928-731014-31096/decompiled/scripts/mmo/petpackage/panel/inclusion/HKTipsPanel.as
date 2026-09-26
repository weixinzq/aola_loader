package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.material.HKClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowDataPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.commonpanel.ICommonPanelService;
   import mmo.interfaces.commonpanel.MessagePanelParam;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.material.hk.HKConfig;
   import mmo.interfaces.material.hk.HKData;
   import mmo.interfaces.material.hk.HKIconOtherParam;
   import mmo.interfaces.material.hk.IHKService;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.helper.TabJumpHelper;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.activity.helper.Pet_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActMaterialLoader;
   import mmo.play.sencondpwd.SecondPwdHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol510")]
   public class HKTipsPanel extends MovieClip implements IDispose
   {
      
      public var mcAllTipsBox:MovieClip;
      
      public var mcCommonBg:MovieClip;
      
      public var mcHkBg_0:MovieClip;
      
      public var mcHkBg_1:MovieClip;
      
      public var mcHkBg_3:MovieClip;
      
      public var mcHkBg_4:MovieClip;
      
      public var mcStart_0:MovieClip;
      
      public var mcStart_1:MovieClip;
      
      public var mcStart_2:MovieClip;
      
      public var mcStart_3:MovieClip;
      
      public var mcStart_4:MovieClip;
      
      public var mcView:MovieClip;
      
      private var _petDataService:IPetDataService;
      
      private var _pmService:IPMService;
      
      private var _pbi:PetBriefInfo;
      
      private var _tipsPanel:MovieClip;
      
      private const url:String = "hk/panel/hk_panel";
      
      private const cls:String = "mmo.pet.hk.icon.HKBagAllCountIcon";
      
      private var _service:IHKService;
      
      private var _firstTab:int = 0;
      
      private var _showPetCard:Boolean;
      
      public function HKTipsPanel()
      {
         this._petDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         this._pmService = ServiceContainer.getService(IPMService) as IPMService;
         this._service = ServiceContainer.getService(IHKService) as IHKService;
         this._showPetCard = LocalStore.getValue(PetPackageEvent.EQUIP_SHOW_KEY) ? Boolean(LocalStore.getValue(PetPackageEvent.EQUIP_SHOW_KEY)["showCard"]) : true;
         super();
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
         if(!this._tipsPanel)
         {
            SimpleCustomLoader.loadSingleResource(this.url,this.cls,LoadingSpriteType.DIALOG_WITHOUT_CANCLE,"请稍候.........",function(param1:MovieClip):void
            {
               _tipsPanel = param1;
               init();
            });
         }
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_INFO_TAB_CHANGED,this.onChangeFirstTab);
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_CARD_SHOW_STATUS_CHANGED,this.onChangePetCardStatus);
         this.refreshView();
      }
      
      private function onChangeFirstTab(param1:PetPackageEvent) : void
      {
         this._firstTab = param1.params.firstTab;
         this.refreshView();
      }
      
      private function onChangePetCardStatus(param1:PetPackageEvent) : void
      {
         this._showPetCard = param1.params.showCard;
         this.refreshView();
      }
      
      private function refreshView() : void
      {
         if(!this._pbi || !Pet_Helper.checkPetIsGQPet(this._pbi.raceId))
         {
            this.visible = false;
            return;
         }
         this.visible = this._firstTab == 2 || this._showPetCard;
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnGoHK")
         {
            TabJumpHelper.changeFirstTab(2);
            TabJumpHelper.changeSecondTab(6);
         }
         if(_loc2_ == "btnRemoveHK")
         {
            Panel_Helper.loadResAndShow("hk/panel/hk_panel","mmo.pet.hk.panel.HKBagSureEquipPl",{
               "inputIdArr":this._pbi.getHKIdArr(),
               "nowIdArr":[0,0,0,0,0],
               "openSlotArr":this._pbi.getHKSlotLvArr(),
               "pid":this._pbi.id,
               "backFun":this.removeHkBack,
               "shengHunObj":null
            });
         }
         if(_loc2_ == "btnLockHK")
         {
            this.lockHKHandle(true);
         }
         if(_loc2_ == "btnUnLockHK")
         {
            this.lockHKHandle(false);
         }
      }
      
      private function lockHKHandle(param1:Boolean) : void
      {
         var self:HKTipsPanel = null;
         var backResult:Function = null;
         var isLock:Boolean = param1;
         backResult = function(param1:Object):void
         {
            if(param1.r == 1)
            {
               self._pbi.isLockHk = isLock;
               self.refleshHkLock();
               PetClient.instance.viewSinglePM(self._pbi.id);
            }
            else
            {
               NewDialog.showFailMessage("操作失败，请联系客服。" + param1.r);
            }
         };
         self = this;
         SecondPwdHelper.showVerify(function():void
         {
            HKClient.lockPetHk(self._pbi.id,isLock,backResult);
         });
      }
      
      private function removeHkBack() : void
      {
         var str:String;
         var param:MessagePanelParam = null;
         PetClient.instance.viewSinglePM(this._pbi.id);
         param = new MessagePanelParam();
         param.title = "卸下成功";
         str = "魂卡已卸下";
         param.content = str;
         ServiceContainer.tryGetService(ICommonPanelService,function(param1:ICommonPanelService, param2:Object = null):void
         {
            param1.showMessagePanel(param);
         });
      }
      
      private function init() : void
      {
         (this._tipsPanel as IShowDataPanel).showPanelByData({
            "holder":this.getChildByName("mcAllTipsBox"),
            "pbi":this._pbi,
            "x":-220,
            "y":-325
         });
      }
      
      private function onDetailUpdate(param1:PetPackageEvent) : void
      {
         var _loc2_:int = int(this._petDataService.getSelectPetId());
         if(param1.params.id == _loc2_)
         {
            this._pbi = PetDetailDataMap.instance.getPetDetailInfo(_loc2_);
            this.updatePanel(this._pbi);
         }
      }
      
      private function updatePanel(param1:PetBriefInfo) : void
      {
         this._pbi = param1;
         var _loc2_:Array = param1.getHKSlotLvArr();
         var _loc3_:Array = param1.getHKIdArr();
         this.hadleFiveData(_loc2_,_loc3_);
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         while(_loc5_ < HKConfig.CardSlotMaxLevelArr.length)
         {
            if(_loc5_ < _loc3_.length && _loc3_[_loc5_] > 0)
            {
               _loc4_++;
            }
            if(_loc5_ != HKConfig.FiveSlotPos)
            {
               this.handleBg(_loc5_,_loc2_,_loc3_);
            }
            _loc5_++;
         }
         ActComHelper.setVisible(this,"mcAllTipsBox.btnRemoveHK",_loc4_ > 0);
         if(this._tipsPanel)
         {
            this._tipsPanel["updateView"](param1);
         }
         this.refreshView();
         this.refleshHkLock();
      }
      
      private function refleshHkLock() : void
      {
         ActComHelper.setMcFrame(this,"mcAllTipsBox.mcLock",this._pbi.isLockHk ? 2 : 1);
         TipsManager.getInstance().replaceTips(ActComHelper.getChildNode(this,"mcAllTipsBox.mcLock") as MovieClip,"锁定后该亚比的魂卡不会受【一键拆卸】相关功能影响。");
      }
      
      private function hadleFiveData(param1:Array, param2:Array) : void
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc9_:MovieClip = null;
         if(HKConfig.FiveSlotPos >= param2.length || param2[HKConfig.FiveSlotPos] <= HKConfig.NoExistId)
         {
            _loc3_ = 0;
         }
         else if(param1.length > HKConfig.FiveSlotPos)
         {
            _loc3_ = int(param1[HKConfig.FiveSlotPos]);
         }
         else
         {
            _loc3_ = 1;
         }
         if(param2.length > HKConfig.FiveSlotPos)
         {
            _loc4_ = int(param2[HKConfig.FiveSlotPos]);
         }
         else
         {
            _loc4_ = int(HKConfig.NoExistId);
         }
         var _loc5_:HKData = this._service.getHKDataById(_loc4_);
         var _loc6_:int = _loc5_ ? int(_loc5_.wordDataAry.length) : 0;
         var _loc7_:int = Math.min(_loc3_,_loc6_);
         var _loc8_:int = 0;
         while(_loc8_ < HKConfig.SlotMaxNum)
         {
            ActComHelper.setVisible(this,"mcStart_" + _loc8_,_loc8_ < _loc3_);
            ActComHelper.setMcFrame(this,"mcStart_" + _loc8_,_loc8_ < _loc7_ ? 2 : 1);
            _loc8_++;
         }
         if(_loc5_)
         {
            ActComHelper.setVisible(this,"mcCommonBg",false);
            _loc9_ = ActComHelper.getChildNode(this,"mcView") as MovieClip;
            ActMaterialLoader.setView(_loc9_,MaterialTypes.HK_SOURCE,_loc4_,false,null,new HKIconOtherParam(HKIconOtherParam.SIZE_HEAD));
         }
         else
         {
            ActComHelper.setVisible(this,"mcCommonBg",true);
         }
      }
      
      private function handleBg(param1:int, param2:Array, param3:Array) : void
      {
         var _loc6_:int = 0;
         if(param3.length <= param1)
         {
            ActComHelper.setMcFrame(this,"mcHkBg_" + param1,1);
            return;
         }
         var _loc4_:int = int(param3[param1]);
         var _loc5_:HKData = this._service.getHKDataById(_loc4_);
         if(param2.length > param1)
         {
            _loc6_ = int(param2[param1]);
         }
         else
         {
            _loc6_ = 1;
         }
         var _loc7_:int = _loc5_ ? int(_loc5_.wordDataAry.length) : 0;
         var _loc8_:int = Math.min(_loc6_,_loc7_);
         ActComHelper.setMcFrame(this,"mcHkBg_" + param1,_loc8_ + 1);
      }
      
      public function dispose() : void
      {
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onDetailUpdate);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_INFO_TAB_CHANGED,this.onChangeFirstTab);
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_CARD_SHOW_STATUS_CHANGED,this.onChangePetCardStatus);
      }
   }
}

