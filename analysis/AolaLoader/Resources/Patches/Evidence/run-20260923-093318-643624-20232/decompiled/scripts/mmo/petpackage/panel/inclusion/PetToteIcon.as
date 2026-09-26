package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.play.activity.helper.Panel_Helper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2529")]
   public class PetToteIcon extends MovieClip
   {
      
      public var btnPetTote:SimpleButton;
      
      public function PetToteIcon()
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
         Panel_Helper.loadResAndShow("activityres/activity240105/totetujian/totetujian_code","mmo.activity240105.totetujian.panel.ToteTuJian_MainPl");
      }
      
      public function dispose() : void
      {
      }
   }
}

