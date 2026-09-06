package mmo.petfightnew.common.useskill
{
   import flash.display.MovieClip;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2468")]
   public class ReallyDecHp extends HpChangeMovie
   {
      
      public var hp:MovieClip;
      
      public function ReallyDecHp()
      {
         super();
         this._numMcStartFrame = 1;
      }
   }
}

