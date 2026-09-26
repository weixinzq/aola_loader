package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.loader.scheduler.ResScheduler;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2825")]
   public class PetCard extends PetDetailBase
   {
      
      public var btnhowpetcard3:SimpleButton;
      
      private var area:Sprite = null;
      
      public function PetCard()
      {
         super();
         this.initPars();
      }
      
      private function initPars() : void
      {
      }
      
      override protected function initUI() : void
      {
         var thisObj:DisplayObjectContainer = null;
         thisObj = this;
         ResScheduler.getResource("petcardpanel/petcardnew",function(param1:DisplayObject):*
         {
            canUpdateUI = true;
            thisObj.addChild(param1);
         },"mmo.pet.petcardnew.PetCardPanelNew");
      }
      
      override protected function refreshUI() : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("petcard3_update_tab_click_bag",{}));
      }
   }
}

