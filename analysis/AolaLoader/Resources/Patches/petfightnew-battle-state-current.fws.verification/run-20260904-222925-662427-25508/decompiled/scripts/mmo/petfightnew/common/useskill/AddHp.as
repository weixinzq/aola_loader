package mmo.petfightnew.common.useskill
{
   import flash.display.MovieClip;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2418")]
   public class AddHp extends HpChangeMovie
   {
      
      public var hp:MovieClip;
      
      public function AddHp()
      {
         super();
         _numMcStartFrame = 21;
      }
   }
}

