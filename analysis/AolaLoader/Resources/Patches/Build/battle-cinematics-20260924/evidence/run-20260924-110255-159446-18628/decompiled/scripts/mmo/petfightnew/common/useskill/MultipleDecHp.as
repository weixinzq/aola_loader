package mmo.petfightnew.common.useskill
{
   import flash.display.MovieClip;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2376")]
   public class MultipleDecHp extends HpChangeMovie
   {
      
      public var hp:MovieClip;
      
      public function MultipleDecHp()
      {
         super();
         _numMcStartFrame = 1;
      }
   }
}

