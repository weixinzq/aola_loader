package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.play.activity.helper.Panel_Helper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2533")]
   public class PetHunKaIcon extends MovieClip
   {
      
      public var btnPetHunKa:SimpleButton;
      
      public function PetHunKaIcon()
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
         Panel_Helper.loadResAndShow("activityres/activity221125/hktujian/hktujian_code","mmo.activity221125.hktujian.panel.HKTuJian_MainPl");
      }
      
      public function dispose() : void
      {
      }
   }
}

