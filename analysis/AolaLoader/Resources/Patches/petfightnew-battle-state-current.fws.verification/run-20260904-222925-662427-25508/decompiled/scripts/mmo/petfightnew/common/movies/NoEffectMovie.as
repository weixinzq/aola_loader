package mmo.petfightnew.common.movies
{
   import flash.display.MovieClip;
   import mmo.petfightnew.common.util.DisableUtil;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol323")]
   public class NoEffectMovie extends MovieClip
   {
      
      public function NoEffectMovie()
      {
         super();
         DisableUtil.disableAll(this);
      }
   }
}

