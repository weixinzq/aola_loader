package mmo.petfightnew.common.useskill
{
   import flash.display.MovieClip;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2368")]
   public class ShieldHitHp extends HpChangeMovie
   {
      
      public var hp:MovieClip;
      
      public function ShieldHitHp()
      {
         super();
         this._numMcStartFrame = 1;
      }
   }
}

