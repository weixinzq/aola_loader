package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol541")]
   public class TerritoryStoreIcon extends MovieClip
   {
      
      public var btnTerritoryStore:SimpleButton;
      
      public function TerritoryStoreIcon()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this.addEventListener(MouseEvent.CLICK,this.onClickIcon);
      }
      
      private function onClickIcon(param1:MouseEvent) : void
      {
         if(!this.mouseChildren)
         {
            return;
         }
         this.showHKTJPanel();
      }
      
      private function showHKTJPanel() : void
      {
      }
      
      public function dispose() : void
      {
      }
   }
}

