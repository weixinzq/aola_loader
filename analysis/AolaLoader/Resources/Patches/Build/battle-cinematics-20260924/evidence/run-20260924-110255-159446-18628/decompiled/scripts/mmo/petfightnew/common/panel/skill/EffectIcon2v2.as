package mmo.petfightnew.common.panel.skill
{
   import flash.display.MovieClip;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2729")]
   public class EffectIcon2v2 extends MovieClip
   {
      
      public var mc:MovieClip;
      
      public function EffectIcon2v2()
      {
         super();
         addFrameScript(0,this.frame1);
      }
      
      internal function frame1() : *
      {
         stop();
      }
   }
}

