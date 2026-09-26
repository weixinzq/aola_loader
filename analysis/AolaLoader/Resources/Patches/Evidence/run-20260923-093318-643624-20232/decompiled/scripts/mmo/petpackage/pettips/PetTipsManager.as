package mmo.petpackage.pettips
{
   import flash.display.InteractiveObject;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.loader.LoaderContainer;
   import mmo.loader.layer.LayerManager;
   
   public class PetTipsManager
   {
      
      private static var _instance:PetTipsManager;
      
      private var petTipsArr:Array;
      
      public function PetTipsManager()
      {
         super();
      }
      
      public static function get instance() : PetTipsManager
      {
         if(_instance == null)
         {
            _instance = new PetTipsManager();
         }
         return _instance;
      }
      
      public function addTips(param1:InteractiveObject, param2:Sprite) : void
      {
         if(this.petTipsArr == null)
         {
            this.petTipsArr = [];
         }
         if(this.isHaveAddTips(param1))
         {
            return;
         }
         var _loc3_:Object = {};
         _loc3_.target = param1;
         _loc3_.tipsPanel = param2;
         this.petTipsArr.push(_loc3_);
         param1.addEventListener(MouseEvent.ROLL_OVER,this.onOver);
         param1.addEventListener(MouseEvent.ROLL_OUT,this.onOut);
         param1.addEventListener(MouseEvent.MOUSE_MOVE,this.onMove);
         param1.addEventListener(Event.REMOVED_FROM_STAGE,this.removeFromStage);
      }
      
      public function removeTips(param1:InteractiveObject) : void
      {
         var _loc3_:Object = null;
         var _loc4_:Sprite = null;
         if(this.petTipsArr == null)
         {
            return;
         }
         var _loc2_:int = 0;
         while(_loc2_ < this.petTipsArr.length)
         {
            _loc3_ = this.petTipsArr[_loc2_] as Object;
            if(_loc3_.target == param1)
            {
               this.petTipsArr.splice(_loc2_,1);
               param1.removeEventListener(MouseEvent.ROLL_OVER,this.onOver);
               param1.removeEventListener(MouseEvent.ROLL_OUT,this.onOut);
               param1.removeEventListener(MouseEvent.MOUSE_MOVE,this.onMove);
               param1.removeEventListener(Event.REMOVED_FROM_STAGE,this.removeFromStage);
               _loc4_ = _loc3_.tipsPanel as Sprite;
               DisplayUtil.stopAndRemove(_loc4_);
               break;
            }
            _loc2_++;
         }
      }
      
      private function onOver(param1:MouseEvent) : void
      {
         var _loc2_:InteractiveObject = param1.currentTarget as InteractiveObject;
         var _loc3_:Object = this.getTipsInfo(_loc2_);
         var _loc4_:Sprite = _loc3_.tipsPanel as Sprite;
         _loc4_.x = LoaderContainer.instance.stage.mouseX + 20;
         _loc4_.y = LoaderContainer.instance.stage.mouseY + 20;
         if(LayerManager.getCurrentLayer() == LayerManager.BASE_LAYER)
         {
            LayerManager.getBaseTips().addChild(_loc4_);
         }
         else
         {
            LayerManager.getFightingTips().addChild(_loc4_);
         }
      }
      
      private function onOut(param1:MouseEvent) : void
      {
         var _loc2_:InteractiveObject = param1.currentTarget as InteractiveObject;
         var _loc3_:Object = this.getTipsInfo(_loc2_);
         var _loc4_:Sprite = _loc3_.tipsPanel as Sprite;
         DisplayUtil.stopAndRemove(_loc4_);
      }
      
      private function onMove(param1:MouseEvent) : void
      {
         var _loc2_:InteractiveObject = param1.currentTarget as InteractiveObject;
         var _loc3_:Object = this.getTipsInfo(_loc2_);
         var _loc4_:Sprite = _loc3_.tipsPanel as Sprite;
         _loc4_.x = LoaderContainer.instance.stage.mouseX + 20;
         _loc4_.y = LoaderContainer.instance.stage.mouseY + 20;
      }
      
      private function removeFromStage(param1:Event) : void
      {
         var _loc2_:InteractiveObject = param1.currentTarget as InteractiveObject;
         this.removeTips(_loc2_);
      }
      
      private function isHaveAddTips(param1:InteractiveObject) : Boolean
      {
         var _loc4_:Object = null;
         var _loc2_:Boolean = false;
         var _loc3_:int = 0;
         while(_loc3_ < this.petTipsArr.length)
         {
            _loc4_ = this.petTipsArr[_loc3_] as Object;
            if(_loc4_.target == param1)
            {
               _loc2_ = true;
               break;
            }
            _loc3_++;
         }
         return _loc2_;
      }
      
      private function getTipsInfo(param1:InteractiveObject) : Object
      {
         var _loc2_:Object = null;
         var _loc3_:int = 0;
         while(_loc3_ < this.petTipsArr.length)
         {
            _loc2_ = this.petTipsArr[_loc3_] as Object;
            if(_loc2_.target == param1)
            {
               break;
            }
            _loc3_++;
         }
         return _loc2_;
      }
   }
}

