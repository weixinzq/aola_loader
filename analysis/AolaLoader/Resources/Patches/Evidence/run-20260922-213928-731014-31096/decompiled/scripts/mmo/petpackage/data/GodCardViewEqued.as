package mmo.petpackage.data
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.godcard.GodCard;
   import mmo.interfaces.material.godcard.GodCardTipsHelper;
   import mmo.interfaces.material.godcard.IGodCardService;
   
   public class GodCardViewEqued extends Sprite
   {
      
      private var _cardId:int;
      
      private var _petId:int;
      
      private var _uniqueId:int;
      
      private var _viewId:int;
      
      private var svr:IGodCardService = ServiceContainer.getService(IGodCardService) as IGodCardService;
      
      public function GodCardViewEqued(param1:int, param2:int, param3:int, param4:int = 0)
      {
         super();
         this._cardId = param2;
         this._petId = param1;
         this._uniqueId = param3;
         this._viewId = param4;
         this.getView();
      }
      
      private function getView() : void
      {
         var _loc1_:DisplayObject = this.svr.getGodCardViewBySerial(this._uniqueId,this._viewId);
         TipsManager.getInstance().addComplexTips(this,GodCardTipsHelper.getNameBySerial(this._uniqueId),GodCardTipsHelper.getHtmlTipsBySerial(this._uniqueId));
         this.addChild(_loc1_);
      }
      
      public function get cardName() : String
      {
         var _loc1_:GodCard = this.svr.getGodCardById(this._cardId);
         return _loc1_.name;
      }
      
      public function get cardId() : int
      {
         return this._cardId;
      }
      
      public function get petId() : int
      {
         return this._petId;
      }
      
      public function get uniqueId() : int
      {
         return this._uniqueId;
      }
   }
}

