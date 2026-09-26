package mmo.petpackage.panel.inclusion
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.ProgressFullSprite;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.PetClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.petpackage.config.PetPackageConfig;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2524")]
   public class YuSheList extends MovieClip implements IDispose
   {
      
      public var btnShowList_0:SimpleButton;
      
      public var btnShowList_1:SimpleButton;
      
      public var btnShowList_2:SimpleButton;
      
      public var btnYuShe_0:SimpleButton;
      
      public var btnYuShe_1:SimpleButton;
      
      public var btnYuShe_2:SimpleButton;
      
      public var mcListBottom:MovieClip;
      
      public var mcYuShe_0:MovieClip;
      
      public var mcYuShe_1:MovieClip;
      
      public var mcYuShe_2:MovieClip;
      
      private var _yuSheView:DisplayObject;
      
      private const url:String = "activityres/activity250523/petpackageyushe/petpackageyushe_code";
      
      private const cls:String = "mmo.activity250523.petpackageyushe.panel.PPYS_MainPl";
      
      private var _pmSelectIndex:int = -1;
      
      private var _pmListName:Array = [];
      
      private var _pmSelectArr:Array = [0,1,2];
      
      private const _listBtnNum:int = 8;
      
      private const _yuSheBtnNum:int = 3;
      
      private var _listBtnzrIndex0:Array = [0,3,4,5,6,15,16,17,18];
      
      private var _listBtnzrIndex1:Array = [1,7,8,9,10,19,20,21,22];
      
      private var _listBtnzrIndex2:Array = [2,11,12,13,14,23,24,25,26];
      
      private var _nowListzrIndexArr:Array = [0,0,0,0];
      
      private var _changeZrIndex:int = 0;
      
      private var _ipds:IPetDataService;
      
      public function YuSheList()
      {
         super();
         this._ipds = ServiceContainer.getService(IPetDataService) as IPetDataService;
         this.init();
      }
      
      private function init() : void
      {
         var _loc2_:SimpleButton = null;
         var _loc3_:SimpleButton = null;
         var _loc1_:int = 0;
         while(_loc1_ < this._yuSheBtnNum)
         {
            _loc2_ = this["btnYuShe_" + _loc1_];
            _loc3_ = this["btnShowList_" + _loc1_];
            _loc2_.addEventListener(MouseEvent.CLICK,this.onClick);
            _loc3_.addEventListener(MouseEvent.CLICK,this.onClick);
            _loc1_++;
         }
      }
      
      public function updateYuSheZhenRongView(param1:int, param2:Array) : void
      {
         var _loc3_:* = 0;
         while(_loc3_ < 3)
         {
            this.updateSingleYuSheZhenRongView(_loc3_);
            _loc3_++;
         }
      }
      
      private function getYuSheGroupIndex(param1:int) : int
      {
         return this._ipds.getZhenRongDataByIndex(param1).useUp - 1;
      }
      
      public function updateOne(param1:int, param2:Array) : void
      {
         var _loc3_:int = int(this._ipds.getNowZhenRongArr().indexOf(param1));
         this.updateSingleYuSheZhenRongView(_loc3_);
      }
      
      private function updateSingleYuSheZhenRongView(param1:int) : void
      {
         var _loc11_:String = null;
         if(param1 < 0)
         {
            return;
         }
         var _loc2_:* = this._ipds.getNowZhenRongArr().indexOf(this._ipds.getSelectZhenRongIndex()) == param1;
         var _loc3_:int = _loc2_ ? 2 : 1;
         var _loc4_:* = false;
         var _loc5_:MovieClip = this["mcYuShe_" + param1];
         var _loc6_:MovieClip = _loc5_["mcYuSheBg"];
         var _loc7_:MovieClip = _loc5_["mcYuSheName"];
         var _loc8_:int = int(this._ipds.getHighestBattleEff());
         var _loc9_:* = PetPackageConfig.openZhenRongNeedPower();
         if(param1 == 0)
         {
            _loc4_ = _loc8_ < _loc9_;
            _loc7_.gotoAndStop(_loc4_ ? 1 : _loc3_);
            _loc6_.gotoAndStop(_loc4_ ? 1 : _loc3_);
            _loc11_ = _loc4_ ? PetPackageConfig.openZhenRongNeedPowerTips() : "";
         }
         else
         {
            _loc7_.gotoAndStop(_loc3_);
            _loc6_.gotoAndStop(_loc3_);
         }
         var _loc10_:String = this._ipds.getZhenRongDataById(this._ipds.getNowZhenRongArr()[param1]).n;
         ActComHelper.setTxtValue(_loc7_,"txtYuSheName",_loc10_);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         param1.stopImmediatePropagation();
         var _loc3_:DisplayObject = param1.currentTarget as DisplayObject;
         var _loc4_:String = _loc3_.name;
         var _loc5_:Array = [];
         if(_loc4_.indexOf("btnYuShe_") > -1)
         {
            _loc5_ = _loc4_.split("_");
            _loc2_ = int(_loc5_[1]);
            _loc6_ = int(this._ipds.getNowZhenRongArr()[_loc2_]);
            if(_loc6_ == this._ipds.getSelectZhenRongIndex())
            {
               return;
            }
            _loc7_ = this.getYuSheGroupIndex(_loc6_) + 1;
            ProgressFullSprite.show();
            _loc8_ = int(this._ipds.getZhenRongDataByIndex(_loc6_).i);
            PetClient.instance.yuSheYaBiZhenRong(_loc8_,_loc7_);
            return;
         }
         if(_loc4_.indexOf("btnShowList_") > -1)
         {
            _loc5_ = _loc4_.split("_");
            _loc2_ = int(_loc5_[1]);
            this.onClickTipsShow(_loc2_);
            return;
         }
         if(_loc4_.indexOf("btnList_") > -1)
         {
            _loc5_ = _loc4_.split("_");
            _loc2_ = int(_loc5_[1]);
            this.onSetZY(_loc2_);
            return;
         }
      }
      
      private function onSetZY(param1:int) : void
      {
      }
      
      private function onClickTipsShow(param1:int) : void
      {
         this._changeZrIndex = param1;
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("PetPackage_ClickYuSheTipsShow",{"index":param1}));
         Panel_Helper.loadResAndShow(this.url,this.cls,{
            "groupIndex":param1,
            "editType":0
         });
      }
      
      private function onYuSheListOut(param1:MouseEvent) : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("PetPackage_ClickYuSheTipsShow",{"index":-1}));
      }
      
      private function onBtnListOver(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:DisplayObject = param1.currentTarget as DisplayObject;
         var _loc4_:String = _loc3_.name;
         var _loc5_:Array = _loc4_.split("_");
         _loc2_ = int(_loc5_[1]);
         var _loc6_:int = int(this._nowListzrIndexArr[_loc2_]);
         this.updatePetHead(_loc6_);
      }
      
      private function onBtnListOut(param1:MouseEvent) : void
      {
         var _loc2_:DisplayObject = param1.currentTarget as DisplayObject;
      }
      
      private function updatePetHead(param1:int) : void
      {
         var _loc4_:int = 0;
         var _loc5_:Object = null;
         var _loc2_:Object = this._ipds.getZhenRongDataById(param1);
         var _loc3_:Array = [-1,-1,-1,-1,-1,-1];
         if(Boolean(_loc2_) && Boolean(_loc2_.pl))
         {
            _loc4_ = 0;
            while(_loc4_ < _loc3_.length)
            {
               _loc5_ = _loc2_.pl[_loc4_] || null;
               if(_loc5_)
               {
                  _loc3_[_loc4_] = _loc5_.ri;
               }
               _loc4_++;
            }
         }
         if(_loc3_[0] == -1)
         {
            _loc3_[0] = PetBriefInfo(this._ipds.getMyPets()[0]).raceId;
         }
      }
      
      public function dispose() : void
      {
         var _loc2_:SimpleButton = null;
         var _loc3_:SimpleButton = null;
         var _loc1_:int = 0;
         while(_loc1_ < this._yuSheBtnNum)
         {
            _loc2_ = this["btnYuShe_" + _loc1_];
            _loc3_ = this["btnShowList_" + _loc1_];
            _loc2_.removeEventListener(MouseEvent.CLICK,this.onClick);
            _loc3_.removeEventListener(MouseEvent.CLICK,this.onClick);
            _loc1_++;
         }
      }
   }
}

