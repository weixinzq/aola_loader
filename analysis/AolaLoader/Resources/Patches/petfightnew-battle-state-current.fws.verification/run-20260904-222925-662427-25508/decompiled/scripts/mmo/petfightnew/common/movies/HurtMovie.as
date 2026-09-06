package mmo.petfightnew.common.movies
{
   import flash.display.MovieClip;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1376")]
   public class HurtMovie extends MovieClip
   {
      
      public function HurtMovie()
      {
         super();
         this.mouseChildren = this.mouseEnabled = false;
      }
   }
}

