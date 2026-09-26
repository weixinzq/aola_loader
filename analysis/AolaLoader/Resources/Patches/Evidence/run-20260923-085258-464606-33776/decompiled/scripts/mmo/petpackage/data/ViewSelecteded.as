package mmo.petpackage.data
{
   import flash.display.Sprite;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.MaterialServiceEvent;
   import mmo.interfaces.material.petcard3.IPetCard3Service;
   
   public class ViewSelecteded extends Sprite
   {
      
      private var _cardId:int;
      
      private var _petId:int;
      
      private var _equipId:int;
      
      public function ViewSelecteded(param1:int, param2:int, param3:int)
      {
         super();
         this._cardId = param2;
         this._petId = param1;
         this._equipId = param3;
         this.getView();
      }
      
      private function getView() : void
      {
         var _loc1_:IPetCard3Service = ServiceContainer.getService(IPetCard3Service) as IPetCard3Service;
         _loc1_.addEventListener(MaterialServiceEvent.onGetView,this.onGetView);
         _loc1_.getView(this._equipId);
      }
      
      private function onGetView(param1:MaterialServiceEvent) : void
      {
         if(param1.params.id != this._equipId)
         {
            return;
         }
         var _loc2_:IPetCard3Service = param1.currentTarget as IPetCard3Service;
         _loc2_.removeEventListener(MaterialServiceEvent.onGetView,this.onGetView);
         this.addChild(param1.params.view);
      }
      
      public function get cardId() : int
      {
         return this._cardId;
      }
      
      public function get petId() : int
      {
         return this._petId;
      }
      
      public function get equipId() : int
      {
         return this._equipId;
      }
   }
}

