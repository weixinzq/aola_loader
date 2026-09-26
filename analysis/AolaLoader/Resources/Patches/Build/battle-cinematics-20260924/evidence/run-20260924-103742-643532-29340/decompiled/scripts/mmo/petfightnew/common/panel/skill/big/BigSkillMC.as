package mmo.petfightnew.common.panel.skill.big
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.petfightnew.common.component.CachedClip;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol898")]
   public class BigSkillMC extends MovieClip
   {
      
      private static const HANDLER_CLASS:Array = [BigSkillMCHandler_GQ,BigSkillMCHandler_XingHui,BigSkillMCHandler_Degenerator,BigSkillMCHandler_Legend,BigSkillMCHandler_Miracle,BigSkillMCHandler_ChangeView,BigSkillMCHandler_AoYi,BigSkillMCHandler_Bargain,BigSkillMCHandler_Default];
      
      public var mcView:MovieClip;
      
      private var _handlerChain:Array = [];
      
      private var _clickable:Boolean = true;
      
      private var _cachedView:CachedClip;
      
      public function BigSkillMC()
      {
         super();
         this.initCachedView();
         this.initHandlerLink();
         this.initEventListeners();
         this.update();
      }
      
      private function initCachedView() : void
      {
         var _loc1_:MovieClip = this.getChildByName("mcView") as MovieClip;
         this._cachedView = new CachedClip(_loc1_);
      }
      
      private function initHandlerLink() : void
      {
         var _loc1_:BigSkillMCHandler = null;
         var _loc2_:Class = null;
         for each(_loc2_ in HANDLER_CLASS)
         {
            _loc1_ = new _loc2_();
            _loc1_.initView(this._cachedView);
            this._handlerChain.push(_loc1_);
         }
      }
      
      private function initEventListeners() : void
      {
         this.addEventListener(MouseEvent.CLICK,this.onMouseClick);
         this.addEventListener(MouseEvent.ROLL_OVER,this.onMouseRollOver);
         this.addEventListener(MouseEvent.ROLL_OUT,this.onMouseRollOut);
      }
      
      private function onMouseClick(param1:MouseEvent) : void
      {
         if(!this._clickable)
         {
            return;
         }
         this.sendEvent(BigSkillMCEvent.CLICK,param1);
      }
      
      private function onMouseRollOver(param1:MouseEvent) : void
      {
         this.sendEvent(BigSkillMCEvent.ROLL_OVER,param1);
      }
      
      private function onMouseRollOut(param1:MouseEvent) : void
      {
         this.sendEvent(BigSkillMCEvent.ROLL_OUT);
      }
      
      public function setMouseRollOut() : void
      {
         this.onMouseRollOut(null);
      }
      
      public function update() : void
      {
         this.sendEvent(BigSkillMCEvent.UPDATE);
      }
      
      private function sendEvent(param1:String, param2:* = null) : void
      {
         var _loc3_:BigSkillMCHandler = null;
         for each(_loc3_ in this._handlerChain)
         {
            if(_loc3_.event(param1,param2))
            {
               break;
            }
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:BigSkillMCHandler = null;
         this.removeEventListener(MouseEvent.CLICK,this.onMouseClick);
         this.removeEventListener(MouseEvent.ROLL_OVER,this.onMouseRollOver);
         this.removeEventListener(MouseEvent.ROLL_OUT,this.onMouseRollOut);
         for each(_loc1_ in this._handlerChain)
         {
            _loc1_.dispose();
         }
         this._handlerChain.length = 0;
         this._handlerChain = null;
         DisplayUtil.stopAndRemove(this);
      }
      
      public function get clickable() : Boolean
      {
         return this._clickable;
      }
      
      public function set clickable(param1:Boolean) : void
      {
         this._clickable = param1;
      }
      
      public function get cachedView() : Sprite
      {
         return this._cachedView as Sprite;
      }
   }
}

