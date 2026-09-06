package mmo.petfightnew.common
{
   import flash.display.DisplayObject;
   import flash.events.Event;
   
   public class AssetsLoaderEvent extends Event
   {
      
      public static const LOAD_DONE:String = "loadDone";
      
      public static const ON_GET_PET:String = "onGetPet";
      
      public static const ON_GET_EFFECT:String = "onGetEffect";
      
      private var _petView:DisplayObject;
      
      private var _effectView:DisplayObject;
      
      private var _effectId:int = -1;
      
      private var _petId:int = -1;
      
      public function AssetsLoaderEvent(param1:String, param2:Object)
      {
         super(param1);
         this._petView = param2.petView;
         this._effectView = param2.effectView;
         this._effectId = param2.effectId;
         this._petId = param2.petId;
      }
      
      public function get petView() : DisplayObject
      {
         return this._petView;
      }
      
      public function get effectView() : DisplayObject
      {
         return this._effectView;
      }
      
      public function get effectId() : int
      {
         return this._effectId;
      }
      
      public function get petId() : int
      {
         return this._petId;
      }
   }
}

