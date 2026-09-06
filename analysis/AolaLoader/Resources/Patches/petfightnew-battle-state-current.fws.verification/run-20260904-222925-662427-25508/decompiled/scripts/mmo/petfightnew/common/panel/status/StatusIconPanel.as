package mmo.petfightnew.common.panel.status
{
   import fl.containers.ScrollPane;
   import fl.controls.ScrollPolicy;
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.IDispose;
   import mmo.petfightnew.common.util.StatusUtil;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2283")]
   public class StatusIconPanel extends MovieClip implements IDispose
   {
      
      public var mcContainer:MovieClip;
      
      private var _scrollPane:ScrollPane;
      
      private var _mcContainer:MovieClip;
      
      public function StatusIconPanel()
      {
         super();
         this._mcContainer = this.getChildByName("mcContainer") as MovieClip;
         this.initScrollPane();
      }
      
      private function initScrollPane() : void
      {
         this._scrollPane = new ScrollPane();
         this._scrollPane.x = this._mcContainer.x;
         this._scrollPane.y = this._mcContainer.y;
         this._scrollPane.width = 230;
         this._scrollPane.height = 75;
         this._scrollPane.source = this._mcContainer;
         this._scrollPane.horizontalScrollPolicy = ScrollPolicy.OFF;
         this.addChild(this._scrollPane);
         this.changeSkin();
      }
      
      private function changeSkin() : void
      {
         this._scrollPane.setStyle("trackUpSkin",ScrollTrack_skin);
         this._scrollPane.setStyle("trackOverSkin",ScrollTrack_skin);
         this._scrollPane.setStyle("trackDownSkin",ScrollTrack_skin);
         this._scrollPane.setStyle("trackDisabledSkin",ScrollTrack_skin);
         this._scrollPane.setStyle("upArrowUpSkin",ScrollArrowUp_downSkin);
         this._scrollPane.setStyle("upArrowOverSkin",ScrollArrowUp_downSkin);
         this._scrollPane.setStyle("upArrowDownSkin",ScrollArrowUp_downSkin);
         this._scrollPane.setStyle("upArrowDisabledSkin",ScrollArrowUp_downSkin);
         this._scrollPane.setStyle("downArrowUpSkin",ScrollArrowDown_downSkin);
         this._scrollPane.setStyle("downArrowOverSkin",ScrollArrowDown_downSkin);
         this._scrollPane.setStyle("downArrowDownSkin",ScrollArrowDown_downSkin);
         this._scrollPane.setStyle("downArrowDisabledSkin",ScrollArrowDown_downSkin);
         this._scrollPane.setStyle("thumbDownSkin",ScrollThumb_upSkin);
         this._scrollPane.setStyle("thumbOverSkin",ScrollThumb_overSkin);
         this._scrollPane.setStyle("thumbUpSkin",ScrollThumb_upSkin);
      }
      
      public function refresh(param1:Array) : void
      {
         var _loc5_:StatusItem = null;
         var _loc6_:String = null;
         var _loc7_:int = 0;
         var _loc8_:StatusItem = null;
         DisplayUtil.clearChildren(this._mcContainer);
         var _loc2_:Array = [];
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         while(_loc4_ < param1.length)
         {
            _loc6_ = param1[_loc4_];
            _loc7_ = StatusUtil.getFrame(_loc6_);
            if(!(_loc7_ <= 0 || StatusUtil.SpecialStatusFrameArr.indexOf(_loc7_) != -1))
            {
               _loc8_ = new StatusItem();
               this._mcContainer.addChild(_loc8_);
               _loc8_.init(_loc6_);
               _loc8_.x = 0;
               _loc8_.y = _loc3_ * 25;
               _loc3_++;
               _loc2_.push(_loc8_);
            }
            _loc4_++;
         }
         this._scrollPane.refreshPane();
         for each(_loc5_ in _loc2_)
         {
            _loc5_.addTips();
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:int = 0;
         var _loc2_:* = undefined;
         if(Boolean(this._mcContainer) && Boolean(this._mcContainer.parent))
         {
            _loc1_ = 0;
            while(_loc1_ < this._mcContainer.numChildren)
            {
               _loc2_ = this._mcContainer.getChildAt(_loc1_);
               if(_loc2_ is StatusItem)
               {
                  _loc2_.dispose();
               }
               _loc1_++;
            }
            DisplayUtil.stopAndRemove(this._mcContainer);
         }
      }
   }
}

