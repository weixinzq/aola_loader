package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.ui.Mouse;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.loader.LoaderContainer;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2482")]
   public class ChangeMouse extends MovieClip implements IDispose
   {
      
      private static var _instance:ChangeMouse;
      
      private var _isChangingMouse:Boolean = false;
      
      public function ChangeMouse()
      {
         super();
      }
      
      public static function get instance() : ChangeMouse
      {
         if(_instance == null)
         {
            _instance = new ChangeMouse();
         }
         return _instance;
      }
      
      public function change(param1:Boolean = false) : void
      {
         Mouse.hide();
         if(this._isChangingMouse)
         {
            return;
         }
         this._isChangingMouse = true;
         var _loc2_:int = int(LoaderContainer.instance.stage.mouseX);
         var _loc3_:int = int(LoaderContainer.instance.stage.mouseY);
         _instance.mouseEnabled = false;
         _instance.mouseChildren = false;
         _instance.cacheAsBitmap = true;
         _instance.x = _loc2_;
         _instance.y = _loc3_;
         LoaderContainer.instance.stage.addChild(_instance);
         _instance.gotoAndStop(param1 ? 2 : 1);
         LoaderContainer.instance.addEventListener(Event.ENTER_FRAME,this.onFrame_Cursor);
      }
      
      private function onFrame_Cursor(param1:Event) : void
      {
         var _loc2_:int = int(LoaderContainer.instance.stage.mouseX);
         var _loc3_:int = int(LoaderContainer.instance.stage.mouseY);
         _instance.x = _loc2_;
         _instance.y = _loc3_;
      }
      
      public function revert() : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent(PetFightEvent.Fight4v4StartSelectEvent,{"start":false}));
         Mouse.show();
         if(!this._isChangingMouse)
         {
            return;
         }
         this._isChangingMouse = false;
         if(_instance.parent != null)
         {
            LoaderContainer.instance.stage.removeChild(_instance);
         }
         LoaderContainer.instance.removeEventListener(Event.ENTER_FRAME,this.onFrame_Cursor);
      }
      
      public function dispose() : void
      {
         LoaderContainer.instance.removeEventListener(Event.ENTER_FRAME,this.onFrame_Cursor);
         this.revert();
         _instance = null;
      }
   }
}

