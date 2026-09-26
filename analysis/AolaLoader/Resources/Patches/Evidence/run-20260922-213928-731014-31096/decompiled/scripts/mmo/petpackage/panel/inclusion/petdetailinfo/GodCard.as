package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import mmo.loader.scheduler.ResScheduler;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2819")]
   public class GodCard extends PetDetailBase
   {
      
      private var area:Sprite = null;
      
      public function GodCard()
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
         ResScheduler.getResource("godcardpanel/godcardpanel",function(param1:DisplayObject):*
         {
            canUpdateUI = true;
            thisObj.addChild(param1);
         },"mmo.pet.godcard.GodCardPanel");
      }
   }
}

