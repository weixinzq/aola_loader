package mmo.petfightnew.common.panel.status
{
   import flash.display.MovieClip;
   import flash.filters.BitmapFilterQuality;
   import flash.filters.GlowFilter;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.IDispose;
   
   public class StatusIcon extends MovieClip implements IDispose
   {
      
      public static const ICON_WIDTH:Number = 22;
      
      public static const ICON_HEIGHT:Number = 20;
      
      private var _statusIconHandler:StatusIconHandler = null;
      
      public function StatusIcon()
      {
         super();
         this._statusIconHandler = new StatusIconHandler(this);
      }
      
      public function startLoad(param1:int, param2:int, param3:int) : void
      {
         this._statusIconHandler.startLoad(param1,param2);
         var _loc4_:TextField = this.getChildByName("txtResTurn") as TextField;
         if(param3 > 0 && param3 < 30)
         {
            if(_loc4_ == null)
            {
               _loc4_ = new TextField();
               _loc4_.name = "txtResTurn";
            }
            _loc4_.mouseEnabled = false;
            _loc4_.maxChars = 2;
            _loc4_.x = 6;
            _loc4_.y = 6;
            _loc4_.width = 14;
            _loc4_.filters = [new GlowFilter(1191268,1,2,2,4,BitmapFilterQuality.MEDIUM)];
            _loc4_.autoSize = TextFieldAutoSize.RIGHT;
            _loc4_.text = param3 + "";
            _loc4_.setTextFormat(this.getTF());
            this.addChild(_loc4_);
         }
         else
         {
            DisplayUtil.stopAndRemove(_loc4_);
         }
      }
      
      private function getTF() : TextFormat
      {
         var _loc1_:TextFormat = new TextFormat();
         _loc1_.size = 12;
         _loc1_.color = 16777215;
         _loc1_.bold = true;
         _loc1_.font = "宋体";
         return _loc1_;
      }
      
      public function clearIcon() : void
      {
         this._statusIconHandler && this._statusIconHandler.clearIcon();
         var _loc1_:TextField = this.getChildByName("txtResTurn") as TextField;
         if(_loc1_ != null)
         {
            DisplayUtil.stopAndRemove(_loc1_);
         }
      }
      
      public function dispose() : void
      {
         this._statusIconHandler && this._statusIconHandler.dispose();
         this._statusIconHandler = null;
      }
   }
}

