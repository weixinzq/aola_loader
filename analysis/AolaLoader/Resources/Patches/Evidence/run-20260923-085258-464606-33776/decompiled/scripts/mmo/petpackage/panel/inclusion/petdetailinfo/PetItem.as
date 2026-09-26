package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;
   import mmo.interfaces.catalog.IBookClubService;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.helper.AddPetDetailInfoHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2918")]
   public class PetItem extends PetDetailBase
   {
      
      public var btnbuyitem:SimpleButton;
      
      private var area:Sprite = null;
      
      public function PetItem()
      {
         super();
         this.initPars();
      }
      
      private function initPars() : void
      {
         this.btnbuyitem.addEventListener(MouseEvent.CLICK,this.onClickBuyItem);
      }
      
      override protected function initUI() : void
      {
         AddPetDetailInfoHelper.addDetailInfoMC(4,this,this.setCanUpdate);
      }
      
      private function onClickBuyItem(param1:Event) : void
      {
         PetPackageEventDispatcher.instance.closePackagePanel();
         this.showCatalog("catalog201001");
      }
      
      private function showCatalog(param1:String) : void
      {
         var cataloNum:String = param1;
         var onGetCatalogService:Function = function(param1:IBookClubService, param2:Object):void
         {
            param1.showPage(cataloNum);
         };
         ServiceContainer.instance.tryGetService(ServiceNames.SellBookService,onGetCatalogService,this);
      }
   }
}

