package mmo.petfightnew.common.fightcontroller
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol48")]
   public dynamic class TimerPanel extends MovieClip
   {
      
      public var txtLayer:TextField;
      
      public var txtMin:TextField;
      
      public var txtSec:TextField;
      
      public function TimerPanel()
      {
         super();
      }
   }
}

