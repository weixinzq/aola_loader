package mmo.petfightnew.common.fightcontroller.fightinfopanel.tab
{
   import fl.containers.ScrollPane;
   import fl.controls.ScrollPolicy;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_Info;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_StatusComponent;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.config.FIP_ResConfig;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.petfight.common.config.StampConfig;
   
   public class FIP_Tab2 extends FIP_TabBase
   {
      
      private var _pbi:PetBriefInfo;
      
      private var _scrollPane:ScrollPane;
      
      private var _statusContainer:Sprite;
      
      private var _statusComponents:Array = [];
      
      public function FIP_Tab2(param1:FIP_Info, param2:int, param3:Function = null)
      {
         super(param1,param2,param3);
      }
      
      override protected function initComponents() : void
      {
         super.initComponents();
         this._statusContainer = this.getChild("mcStatusContainer");
         this._scrollPane = new ScrollPane();
         this._scrollPane.x = this._statusContainer.x;
         this._scrollPane.y = this._statusContainer.y;
         this._scrollPane.width = 340;
         this._scrollPane.height = 350;
         this._scrollPane.source = this._statusContainer;
         this._scrollPane.horizontalScrollPolicy = ScrollPolicy.OFF;
         this._view.addChild(this._scrollPane);
         FIP_ResConfig.changeSkin(this._scrollPane);
      }
      
      override protected function refreshView() : void
      {
         super.refreshView();
         this._pbi = _info.currSelectPbi();
         this.refreshStatus();
      }
      
      private function refreshStatus() : void
      {
         var _loc4_:FIP_StatusComponent = null;
         var _loc5_:Array = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:Class = null;
         var _loc9_:MovieClip = null;
         var _loc10_:FIP_StatusComponent = null;
         var _loc1_:String = this._pbi.status;
         if(_loc1_ != null && _loc1_ != "")
         {
            _loc5_ = _loc1_.split(",");
            _loc6_ = int(_loc5_.length - 1);
            while(_loc6_ >= 0)
            {
               _loc7_ = StatusUtil.getFrame(_loc5_[_loc6_]);
               if(_loc7_ <= 0 || StatusUtil.SpecialStatusFrameArr.indexOf(_loc7_) != -1)
               {
                  _loc5_.splice(_loc6_,1);
               }
               else if(StatusUtil.getTips(_loc5_[_loc6_]) == null || StatusUtil.getTips(_loc5_[_loc6_]) == "")
               {
                  _loc5_.splice(_loc6_,1);
               }
               else if(StatusUtil.isToteStatus(_loc5_[_loc6_]) && _info.isSelectMe)
               {
                  _loc5_.splice(_loc6_,1);
               }
               else if(_loc5_[_loc6_].indexOf("suit_") != -1 && _info.isSelectMe)
               {
                  _loc5_.splice(_loc6_,1);
               }
               else if(Boolean(StampConfig.checkIsStampStatus(_loc5_[_loc6_])) && _info.isSelectMe)
               {
                  _loc5_.splice(_loc6_,1);
               }
               else if(StatusUtil.isGQTujian(_loc5_[_loc6_]) && _info.isSelectMe)
               {
                  _loc5_.splice(_loc6_,1);
               }
               else if(StatusUtil.isZhaoHuanShiStatus(_loc5_[_loc6_]) && _info.isSelectMe)
               {
                  _loc5_.splice(_loc6_,1);
               }
               _loc6_--;
            }
         }
         DisplayUtil.clearChildren(this._statusContainer);
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         while(_loc3_ < _loc5_.length)
         {
            _loc8_ = getDefinitionByName(FIP_ResConfig.StatusViewObj.clsName) as Class;
            _loc9_ = new _loc8_() as MovieClip;
            _loc9_.x = 0;
            _loc9_.y = _loc2_;
            _loc9_.name = "mcStatusView" + _loc3_;
            this._statusContainer.addChild(_loc9_);
            _loc10_ = this._statusComponents[_loc3_];
            if(_loc10_ == null)
            {
               _loc10_ = new FIP_StatusComponent();
               this._statusComponents[_loc3_] = _loc10_;
            }
            _loc10_.refresh(_loc9_,_loc5_[_loc3_]);
            _loc2_ += _loc10_.viewHeight + 5;
            _loc3_++;
         }
         this._scrollPane.refreshPane();
         for each(_loc4_ in this._statusComponents)
         {
            _loc4_.addTips();
         }
      }
      
      override public function dispose() : void
      {
         var _loc1_:FIP_StatusComponent = null;
         super.dispose();
         for each(_loc1_ in this._statusComponents)
         {
            _loc1_.dispose();
         }
         this._statusComponents = [];
      }
   }
}

