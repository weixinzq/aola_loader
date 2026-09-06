package mmo.petfightnew.common.fightcontroller.fightinfopanel.common
{
   import fl.containers.ScrollPane;
   import fl.controls.ScrollPolicy;
   import flash.display.MovieClip;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.config.FIP_ResConfig;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.petfight.common.config.StampConfig;
   
   public class FIP_YinJiHelper
   {
      
      private var _info:FIP_Info;
      
      private var _view:MovieClip;
      
      private var _pbi:PetBriefInfo;
      
      private var _scrollPane:ScrollPane;
      
      private var _yinjiContainer:MovieClip;
      
      private var _yinjiComponents:Array = [];
      
      public function FIP_YinJiHelper(param1:FIP_Info, param2:MovieClip)
      {
         super();
         this._info = param1;
         this._view = param2;
         this.initComponents();
      }
      
      protected function initComponents() : void
      {
         this._yinjiContainer = this._view.mcYinJiContainer;
         this._scrollPane = new ScrollPane();
         this._scrollPane.x = this._yinjiContainer.x;
         this._scrollPane.y = this._yinjiContainer.y + 15;
         this._scrollPane.width = 355;
         this._scrollPane.height = 330;
         this._scrollPane.source = this._yinjiContainer;
         this._scrollPane.horizontalScrollPolicy = ScrollPolicy.OFF;
         this._view.addChild(this._scrollPane);
         FIP_ResConfig.changeSkin(this._scrollPane);
      }
      
      public function refreshView() : void
      {
         this._pbi = this._info.currSelectPbi();
         this.refreshYinJi();
      }
      
      private function refreshYinJi() : void
      {
         var _loc4_:FIP_YinJiComponent = null;
         var _loc5_:Array = null;
         var _loc6_:int = 0;
         var _loc7_:Class = null;
         var _loc8_:MovieClip = null;
         var _loc9_:FIP_YinJiComponent = null;
         var _loc1_:String = this._pbi.status;
         if(_loc1_ != null && _loc1_ != "")
         {
            _loc5_ = _loc1_.split(",");
            _loc6_ = int(_loc5_.length - 1);
            while(_loc6_ >= 0)
            {
               if(!StampConfig.checkIsStampStatus(_loc5_[_loc6_]) && !StatusUtil.isGQTujian(_loc5_[_loc6_]) && !StatusUtil.isZhaoHuanShiStatus(_loc5_[_loc6_]))
               {
                  _loc5_.splice(_loc6_,1);
               }
               _loc6_--;
            }
         }
         DisplayUtil.clearChildren(this._yinjiContainer);
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         while(_loc3_ < _loc5_.length)
         {
            _loc7_ = getDefinitionByName(FIP_ResConfig.YinJiViewObj.clsName) as Class;
            _loc8_ = new _loc7_() as MovieClip;
            _loc8_.x = 0;
            _loc8_.y = _loc2_;
            _loc8_.name = "mcYinJiView" + _loc3_;
            this._yinjiContainer.addChild(_loc8_);
            _loc9_ = this._yinjiComponents[_loc3_];
            if(_loc9_ == null)
            {
               _loc9_ = new FIP_YinJiComponent();
               this._yinjiComponents[_loc3_] = _loc9_;
            }
            _loc9_.refresh(_loc8_,_loc5_[_loc3_]);
            _loc2_ += _loc9_.viewHeight + 5;
            _loc3_++;
         }
         this._scrollPane.refreshPane();
         for each(_loc4_ in this._yinjiComponents)
         {
            _loc4_.addTips();
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:FIP_YinJiComponent = null;
         for each(_loc1_ in this._yinjiComponents)
         {
            _loc1_.dispose();
         }
         this._yinjiComponents = [];
      }
   }
}

