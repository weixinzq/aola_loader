package mmo.petfightnew.common.panel.skill
{
   import flash.display.MovieClip;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol16")]
   public class EffectIcon extends MovieClip
   {
      
      public function EffectIcon()
      {
         addFrameScript(0,this.frame1);
         super();
      }
      
      internal function frame1() : *
      {
         stop();
      }
   }
}

